import axi_pkg::*;

`define IN_ORDER
`define SIM

module axi_inorder_controller 
(
    input  wire ACLK,
    input  wire ARESETn,

    //==================================================
    // From Zynq PS M_AXI_GP0
    // Controller receives requests from PS
    //==================================================

    // AR Channel
    input  wire [ID_WIDTH-1:0]     M_AXI_GP0_ARID,
    input  wire [ADDR_WIDTH-1:0]   M_AXI_GP0_ARADDR,
    input  wire [LEN_WIDTH-1:0]    M_AXI_GP0_ARLEN,
    input  wire [2:0]              M_AXI_GP0_ARSIZE,
    input  wire [1:0]              M_AXI_GP0_ARBURST,
    input  wire                    M_AXI_GP0_ARVALID,
    output wire                    M_AXI_GP0_ARREADY,

    // AW Channel
    input  wire [ID_WIDTH-1:0]     M_AXI_GP0_AWID,
    input  wire [ADDR_WIDTH-1:0]   M_AXI_GP0_AWADDR,
    input  wire [LEN_WIDTH-1:0]    M_AXI_GP0_AWLEN,
    input  wire [2:0]              M_AXI_GP0_AWSIZE,
    input  wire [1:0]              M_AXI_GP0_AWBURST,
    input  wire                    M_AXI_GP0_AWVALID,
    output wire                    M_AXI_GP0_AWREADY,

    // W Channel
    input  wire [DATA_WIDTH-1:0]   M_AXI_GP0_WDATA,
    input  wire [DATA_WIDTH/8-1:0] M_AXI_GP0_WSTRB,
    input  wire                    M_AXI_GP0_WLAST,
    input  wire                    M_AXI_GP0_WVALID,
    output wire                    M_AXI_GP0_WREADY,

    // R Channel
    output wire [ID_WIDTH-1:0]     M_AXI_GP0_RID,
    output wire [DATA_WIDTH-1:0]   M_AXI_GP0_RDATA,
    output wire [1:0]              M_AXI_GP0_RRESP,
    output wire                    M_AXI_GP0_RLAST,
    output wire                    M_AXI_GP0_RVALID,
    input  wire                    M_AXI_GP0_RREADY,

    // B Channel
    output wire [ID_WIDTH-1:0]     M_AXI_GP0_BID,
    output wire [1:0]              M_AXI_GP0_BRESP,
    output wire                    M_AXI_GP0_BVALID,
    input  wire                    M_AXI_GP0_BREADY,

    //==================================================
    // To Zynq PS S_AXI_HP0
    // Controller issues requests to PS memory subsystem
    //==================================================

    // AR Channel
    output wire [ID_WIDTH-1:0]     S_AXI_HP0_ARID,
    output wire [ADDR_WIDTH-1:0]   S_AXI_HP0_ARADDR,
    output wire [LEN_WIDTH-1:0]    S_AXI_HP0_ARLEN,
    output wire [2:0]              S_AXI_HP0_ARSIZE,
    output wire [1:0]              S_AXI_HP0_ARBURST,
    output wire                    S_AXI_HP0_ARVALID,
    input  wire                    S_AXI_HP0_ARREADY,

    // AW Channel
    output wire [ID_WIDTH-1:0]     S_AXI_HP0_AWID,
    output wire [ADDR_WIDTH-1:0]   S_AXI_HP0_AWADDR,
    output wire [LEN_WIDTH-1:0]    S_AXI_HP0_AWLEN,
    output wire [2:0]              S_AXI_HP0_AWSIZE,
    output wire [1:0]              S_AXI_HP0_AWBURST,
    output wire                    S_AXI_HP0_AWVALID,
    input  wire                    S_AXI_HP0_AWREADY,

    // W Channel
    output wire [DATA_WIDTH-1:0]   S_AXI_HP0_WDATA,
    output wire [DATA_WIDTH/8-1:0] S_AXI_HP0_WSTRB,
    output wire                    S_AXI_HP0_WLAST,
    output wire                    S_AXI_HP0_WVALID,
    input  wire                    S_AXI_HP0_WREADY,

    // R Channel
    input  wire [ID_WIDTH-1:0]     S_AXI_HP0_RID,
    input  wire [DATA_WIDTH-1:0]   S_AXI_HP0_RDATA,
    input  wire [1:0]              S_AXI_HP0_RRESP,
    input  wire                    S_AXI_HP0_RLAST,
    input  wire                    S_AXI_HP0_RVALID,
    output wire                    S_AXI_HP0_RREADY,

    // B Channel
    input  wire [ID_WIDTH-1:0]     S_AXI_HP0_BID,
    input  wire [1:0]              S_AXI_HP0_BRESP,
    input  wire                    S_AXI_HP0_BVALID,
    output wire                    S_AXI_HP0_BREADY
);

    
    `ifdef IN_ORDER
        // Read Channel : In-Order Only vs Out-of-Order
        reg [ID_WIDTH-1:0]     ARID_reg[0:FIFO_NUM-1];
        reg [ADDR_WIDTH-1:0]   ARADDR_reg[0:FIFO_NUM-1];
        reg [LEN_WIDTH-1:0]    ARLEN_reg[0:FIFO_NUM-1];
        reg [2:0]              ARSIZE_reg[0:FIFO_NUM-1];
        reg [1:0]              ARBURST_reg[0:FIFO_NUM-1];

        

        reg [$clog2(FIFO_NUM):0] cnt;
        reg AR_en;
        wire ar_in_fire;
        assign ar_in_fire = M_AXI_GP0_ARVALID && M_AXI_GP0_ARREADY;

        wire ar_out_fire;
        assign ar_out_fire = S_AXI_HP0_ARVALID && S_AXI_HP0_ARREADY;

        // AR request FIFO
        always @(posedge ACLK or negedge ARESETn) begin
            if (!ARESETn) begin
                for (int i = 0; i < FIFO_NUM; i++) begin
                    ARADDR_reg[i]  <= 'h0000_0000;
                    ARID_reg[i]    <= 'b0000;
                    ARLEN_reg[i]   <= 'b00;
                    ARSIZE_reg[i]  <= 'b00;
                    ARBURST_reg[i] <= 'b00;
                end
                AR_en <= OFF;
            end
            else begin

                if (ar_in_fire) begin
                    ARADDR_reg[cnt]  <= M_AXI_GP0_ARADDR;
                    ARID_reg[cnt]    <= M_AXI_GP0_ARID;
                    ARLEN_reg[cnt]   <= M_AXI_GP0_ARLEN;
                    ARSIZE_reg[cnt]  <= M_AXI_GP0_ARSIZE;
                    ARBURST_reg[cnt] <= M_AXI_GP0_ARBURST;
                end
                else if (ar_out_fire) begin
                    for (int i = 1; i < FIFO_NUM; i++) begin
                        ARADDR_reg[i-1]  <= ARADDR_reg[i];
                        ARID_reg[i-1]    <= ARID_reg[i];
                        ARLEN_reg[i-1]   <= ARLEN_reg[i];
                        ARSIZE_reg[i-1]  <= ARSIZE_reg[i];
                        ARBURST_reg[i-1] <= ARBURST_reg[i];
                    end
                end
                else begin
                    ARADDR_reg[cnt]  <= ARADDR_reg[cnt];
                    ARID_reg[cnt]    <= ARID_reg[cnt];
                    ARLEN_reg[cnt]   <= ARLEN_reg[cnt];
                    ARSIZE_reg[cnt]  <= ARSIZE_reg[cnt];
                    ARBURST_reg[cnt] <= ARBURST_reg[cnt];
                    AR_en <= OFF;
                end
            end
        end

        // counter
        // AR FIFO occupancy counter
        always @(posedge ACLK or negedge ARESETn) begin
            if (!ARESETn) begin
                cnt <= '0;
            end
            else begin
                case ({ar_in_fire, ar_out_fire})
                    2'b10: begin
                        // push only
                        if (cnt < FIFO_NUM)
                            cnt <= cnt + 1'b1;
                        else
                            cnt <= cnt;
                    end

                    2'b01: begin
                        // pop only
                        if (cnt != 0)
                            cnt <= cnt - 1'b1;
                        else
                            cnt <= cnt;
                    end

                    2'b11: begin
                        // push + pop same cycle
                        cnt <= cnt;
                    end

                    default: begin
                        cnt <= cnt;
                    end
                endcase
            end
        end

        assign M_AXI_GP0_ARREADY = (cnt < FIFO_NUM) ? ON : OFF;

        reg start;
        // 수정점 1.
        assign S_AXI_HP0_ARVALID = (cnt != 0);
        assign S_AXI_HP0_ARADDR  = (cnt != 0) ? ARADDR_reg[0]  : '0;
        assign S_AXI_HP0_ARID    = (cnt != 0) ? ARID_reg[0]    : '0;
        assign S_AXI_HP0_ARLEN   = (cnt != 0) ? ARLEN_reg[0]   : '0;
        assign S_AXI_HP0_ARSIZE  = (cnt != 0) ? ARSIZE_reg[0]  : '0;
        assign S_AXI_HP0_ARBURST = (cnt != 0) ? ARBURST_reg[0] : '0;

        always @(posedge ACLK or negedge ARESETn) begin
            if (!ARESETn) start <= OFF;
            else begin
                if (S_AXI_HP0_ARREADY) start <= ON;
                else if (!S_AXI_HP0_ARREADY & cnt == 0) start <= OFF;
                else start <= start;
            end
        end

        // R Channel FIFO

        wire r_in_fire   = S_AXI_HP0_RVALID && S_AXI_HP0_RREADY;
        wire r_out_fire  = M_AXI_GP0_RVALID && M_AXI_GP0_RREADY;
        reg                  r_burst_active;
        reg [LEN_WIDTH:0]    r_beats_remain;
        reg [ID_WIDTH-1:0]   r_active_id;
        reg [DATA_WIDTH-1:0] RDATA_reg[0:FIFO_NUM-1];
        reg [ID_WIDTH-1:0]   RID_reg[0:FIFO_NUM-1];
        reg [1:0]            RRESP_reg[0:FIFO_NUM-1];
        reg                  RLAST_reg[0:FIFO_NUM-1];

        reg [$clog2(FIFO_NUM):0] d_cnt;

        assign M_AXI_GP0_RVALID = (d_cnt != 0);
        assign M_AXI_GP0_RID    = (M_AXI_GP0_RVALID) ? RID_reg[0]    : '0;
        assign M_AXI_GP0_RDATA  = (M_AXI_GP0_RVALID) ? RDATA_reg[0]  : '0;
        assign M_AXI_GP0_RRESP  = (M_AXI_GP0_RVALID) ? RRESP_reg[0]  : '0;
        assign M_AXI_GP0_RLAST  = (M_AXI_GP0_RVALID) ? RLAST_reg[0]  : '0;

        // Burst 관련. Beat는 transaction과 다르게 계산해야 하므로, 해당 방식으로 처리함.
        always @(posedge ACLK or negedge ARESETn) begin
            if (!ARESETn) begin
                r_burst_active <= OFF;
                r_beats_remain <= '0;
                r_active_id    <= '0;
            end
            else begin
                // ar 나오고 burst 꺼져 있을 때 LEN 값을 들고오는 방법임.
                if (ar_out_fire && !r_burst_active) begin
                    r_burst_active <= ON;
                    r_beats_remain <= S_AXI_HP0_ARLEN + 1'b1;
                    r_active_id    <= S_AXI_HP0_ARID;
                end
                else if (r_in_fire && r_burst_active) begin
                    r_beats_remain <= r_beats_remain - 1'b1;
                    if (S_AXI_HP0_RLAST) r_burst_active <= OFF;
                end
            end
        end

        // d_cnt : R FIFO cnt (beat 관련)
        always @(posedge ACLK or negedge ARESETn) begin
            if (!ARESETn) d_cnt <= '0;
            else begin
                case ({r_in_fire, r_out_fire})
                    2'b10: begin
                        if (d_cnt < FIFO_NUM)
                            d_cnt <= d_cnt + 1'b1;
                    end
                    2'b01: begin
                        if (d_cnt != 0)
                            d_cnt <= d_cnt - 1'b1;
                    end
                    2'b11: d_cnt <= d_cnt;   // push와 pop 동시 발생 → 개수 유지
                    default: d_cnt <= d_cnt;

                endcase
            end
        end

        // Data FIFO
        always @(posedge ACLK or negedge ARESETn) begin
            if (!ARESETn) begin
                for (int i = 0; i < FIFO_NUM; i++) begin
                    RDATA_reg[i] <= 0;
                    RID_reg[i]   <= 0;
                    RRESP_reg[i] <= 0;
                    RLAST_reg[i] <= 0;
                end
            end
            else begin
                if (r_in_fire) begin
                    RDATA_reg[d_cnt] <= S_AXI_HP0_RDATA;
                    RID_reg[d_cnt]   <= S_AXI_HP0_RID;
                    RRESP_reg[d_cnt] <= S_AXI_HP0_RRESP;
                    RLAST_reg[d_cnt] <= S_AXI_HP0_RLAST;
                end
                else if (r_out_fire) begin
                    for (int i = 1; i < FIFO_NUM; i++) begin
                        RDATA_reg[i-1] <= RDATA_reg[i];
                        RID_reg[i-1]   <= RID_reg[i];
                        RRESP_reg[i-1] <= RRESP_reg[i];
                        RLAST_reg[i-1] <= RLAST_reg[i];
                    end
                end
                else begin
                    RDATA_reg[d_cnt] <= RDATA_reg[d_cnt];
                    RID_reg[d_cnt]   <= RID_reg[d_cnt];
                    RRESP_reg[d_cnt] <= RRESP_reg[d_cnt];
                    RLAST_reg[d_cnt] <= RLAST_reg[d_cnt];
                end
            end
        end
        
        // 수정 2. FIFO cnt를 기준으로 더 받을 수 있는지 없는지 검사.
        assign S_AXI_HP0_RREADY = (d_cnt < FIFO_NUM);

        // Write : In_Order Only 
        // 해당 모듈은 OUT_ORDER에서 재활용할 수 있게 설계할 예정     

        // 미리 FIFO I/O 조건 및 FIFO reg 선언

        // I/O 조건
        wire aw_fifo_in = M_AXI_GP0_AWVALID && M_AXI_GP0_AWREADY;
        wire w_fifo_in = M_AXI_GP0_WVALID && M_AXI_GP0_WREADY;
        wire aw_fifo_out = S_AXI_GP0_AWVALID && S_AXI_GP0_AWREADY;
        wire w_fifo_out = S_AXI_GP0_WVALID && S_AXI_GP0_WREADY;

        // AW Channel reg
        reg [ID_WIDTH-1:0] AWID_reg[0:FIFO_NUM-1];
        reg [ADDR_WIDTH-1:0] AWADDR_reg[0:FIFO_NUM-1];
        reg [LEN_WIDTH-1:0] AWLEN_reg[0:FIFO_NUM-1];
        reg [2:0] AWSIZE_reg [0:FIFO_NUM-1];
        reg [1:0] AWBURST_reg[0:FIFO_NUM-1];
        
        // W Channel reg 
        reg [DATA_WIDTH-1:0] WDATA_reg[0:FIFO_NUM-1];
        reg [DATA_WIDTH/8-1:0] WSTRB_reg[0:FIFO_NUM-1];
        reg WLAST_reg[0:FIFO_NUM-1];

        // B Channel reg
        reg [ID_WIDTH-1:0] BID_reg[0:FIFO_NUM-1];
        reg [1:0] BRESP_reg[0:FIFO_NUM-1];   
        
        // cnt reg. aw = transaction, w = beat
        reg [$clog2(FIFO_NUM):0] aw_cnt, w_cnt, b_cnt;


        // AW Master
        always @(posedge ACLK or negedge ARESETn) begin
            if (!ARESETn) begin
                for (int i=0; i<FIFO_NUM; i++) begin
                    AWID_reg[i] <= 'h0;
                    AWADDR_reg[i] <= 'h0;
                    AWLEN_reg[i] <= 'h0;
                    AWSIZE_reg[i] <= 'h0;
                    AWBURST_reg[i] <= 'h0;
                end
            end
            else begin
                if (aw_fifo_in) begin
                    AWID_reg[aw_cnt] <= M_AXI_GP0_AWID;
                    AWADDR_reg[aw_cnt] <= M_AXI_GP0_AWADDR;
                    AWLEN_reg[aw_cnt] <= M_AXI_GP0_AWLEN;
                    AWSIZE_reg[aw_cnt] <= M_AXI_GP0_AWSIZE;
                    AWBURST_reg[aw_cnt] <= M_AXI_GP0_AWBURST;                    
                end

                else if (aw_fifo_out) begin
                    for (int i=1; i<FIFO_NUM; i++) begin
                        AWID_reg[i-1] <= AWID_reg[i];
                        AWADDR_reg[i-1] <= AWADDR_reg[i];
                        AWLEN_reg[i-1] <= AWLEN_reg[i];
                        AWSIZE_reg[i-1] <= AWSIZE_reg[i];
                        AWBURST_reg[i-1] <= AWBURST_reg[i];                        
                    end
                end

                else begin
                    AWID_reg[aw_cnt] <= AWID_reg[aw_cnt];
                    AWADDR_reg[aw_cnt] <= AWADDR_reg[aw_cnt];
                    AWLEN_reg[aw_cnt] <= AWLEN_reg[aw_cnt];
                    AWSIZE_reg[aw_cnt] <= AWSIZE_reg[aw_cnt];
                    AWBURST_reg[aw_cnt] <= AWBURST_reg[aw_cnt];  
                end
            end
        end

        // aw counter (transaction)
        always @(posedge ACLK or negedge ARESETn) begin
            if (!ARESETn) aw_cnt <= '0;
            else begin
                case({aw_fifo_in, aw_fifo_out}) 
                    2'b00 :  aw_cnt <= aw_cnt; // default
                    2'b01 : begin  // out이 발생했으므로 감소
                        if (aw_cnt>0) aw_cnt <= aw_cnt-1;
                    end
                    2'b10 : begin  // in이 발생했으므로 증가
                        if (aw_cnt<FIFO_NUM) aw_cnt <= aw_cnt+1;
                    end
                    2'b11 : aw_cnt <= aw_cnt; // in과 out이 동시에 발생했으므로 cnt 변화 X
                endcase
            end
        end               
        
        // AW Master output 관련 
        assign M_AXI_GP0_AWREADY = (aw_cnt<FIFO_NUM) ? ON : OFF;


        // AW Slave
                
        // AW Slave output 관련
        assign S_AXI_HP0_AWVALID = (aw_cnt!=0) ? ON : OFF;    

        assign S_AXI_HP0_AWID = (S_AXI_HP0_AWVALID) ? AWID_reg[0] : '0;
        assign S_AXI_HP0_AWADDR = (S_AXI_HP0_AWVALID) ? AWADDR_reg[0] : '0;
        assign S_AXI_HP0_AWLEN = (S_AXI_HP0_AWVALID) ? AWLEN_reg[0] : '0;
        assign S_AXI_HP0_AWSIZE = (S_AXI_HP0_AWVALID) ? AWSIZE_reg[0] : '0;
        assign S_AXI_HP0_AWBURST = (S_AXI_HP0_AWVALID) ? AWBURST_reg[0] : '0;

        // W Master
        reg w_burst_active;
        reg [LEN_WIDTH-1:0] w_beat_remain;
        reg w_beat_last;

        // aw_fifo_out이 터지고 난 이후, 미리 Burst하게 쓸 준비
        always @(posedge ACLK or negedge ARESETn) begin
            if (!ARESETn) begin
                w_burst_active <= OFF;
                w_beat_remain <= '0;
                w_beat_last <= OFF;
            end
            else begin
                if (aw_fifo_out&!w_burst_active) begin
                    w_burst_active <= ON;
                    w_beat_remain <= S_AXI_HP0_AWLEN + 1;
                    w_beat_last <= OFF;
                end
                else if (w_burst_active&w_beat_remain>1&w_fifo_out) w_beat_remain <= w_beat_remain - 1;
                else if (w_burst_active&w_beat_remain==1&w_fifo_out) begin
                    w_beat_remain <= 0;
                    w_beat_last <= ON;
                end
                else if (w_burst_active&w_beat_remain==0) begin
                    w_burst_active <= OFF;
                    w_beat_last <= OFF;
                end
                else begin
                    w_burst_active <= w_burst_active;
                    w_beat_remain <= w_beat_remain;
                    w_beat_last <= w_beat_last;
                end
            end
        end

        // I/O 관련해서 cnt 조절
        always @(posedge ACLK or negedge ARESETn) begin
            if (!ARESETn) w_cnt <= '0;
            else begin
                case({w_fifo_in, w_fifo_out}) 
                    2'b00 :  w_cnt <= w_cnt; // default
                    2'b01 : begin  // out이 발생했으므로 감소
                        if (w_cnt>0) w_cnt <= w_cnt-1;
                    end
                    2'b10 : begin  // in이 발생했으므로 증가
                        if (w_cnt<FIFO_NUM) w_cnt <= w_cnt+1;
                    end
                    2'b11 : w_cnt <= w_cnt; // in과 out이 동시에 발생했으므로 cnt 변화 X
                endcase
            end
        end

        // 데이터 받기 
        always @(posedge ACLK or negedge ARESETn) begin
            if (!ARESETn) begin
                for (int i=0; i<FIFO_NUM; i++) begin
                    WDATA_reg[i] <= '0;
                    WSTRB_reg[i] <= '0;
                    WLAST_reg[i] <= OFF;                       
                end
            end
            else begin
                if (w_fifo_in) begin
                    WDATA_reg[w_cnt] <= M_AXI_GP0_WDATA;
                    WSTRB_reg[w_cnt] <= M_AXI_GP0_WSTRB;
                    WLAST_reg[w_cnt] <= M_AXI_GP0_WLAST;
                 
                end

                else if (w_fifo_out) begin
                    for (int i=1; i<FIFO_NUM; i++) begin
                        WDATA_reg[i-1] <= WDATA_reg[i];
                        WSTRB_reg[i-1] <= WSTRB_reg[i];
                        WLAST_reg[i-1] <= WLAST_reg[i];                       
                    end
                end

                else begin
                    WDATA_reg[w_cnt] <= WDATA_reg[w_cnt];
                    WSTRB_reg[w_cnt] <= WSTRB_reg[w_cnt];
                    WLAST_reg[w_cnt] <= WLAST_reg[w_cnt];
                end
            end
        end

        assign M_AXI_GP0_WREADY = (w_cnt<FIFO_NUM) ? ON : OFF;


        // W Slave output 관련 
        assign S_AXI_HP0_WVALID = (w_cnt!=0) ? ON : OFF;

        assign S_AXI_HP0_WDATA = (S_AXI_HP0_WVALID) ? WDATA_reg[0] : '0; 
        assign S_AXI_HP0_WSTRB = (S_AXI_HP0_WVALID) ? WSTRB_reg[0] : '0; 
        assign S_AXI_HP0_WLAST = (S_AXI_HP0_WVALID) ? WLAST_reg[0] : '0; 


        // B Master
        wire b_fifo_in = S_AXI_HP0_BVALID & S_AXI_HP0_BREADY;
        wire b_fifo_out = M_AXI_GP0_BVALID & M_AXI_GP0_BREADY;

        assign M_AXI_GP0_BID = (M_AXI_GP0_BVALID) ? BID_reg[0] : 0;
        assign M_AXI_GP0_BRESP = (M_AXI_GP0_BVALID) ? BRESP_reg[0] : 0;
        assign M_AXI_GP0_BVALID = (b_cnt!=0)&(w_beat_remain==0)&(!w_beat_last);
        
        // B cnt
        always @(posedge ACLK or negedge ARESETn) begin
            if (!ARESETn) b_cnt <= '0;
            else begin
                if (S_AXI_HP0_WLAST) begin
                    case({w_fifo_in, w_fifo_out}) 
                        2'b00 :  b_cnt <= b_cnt; // default
                        2'b01 : begin  // out이 발생했으므로 감소
                            if (b_cnt>0) b_cnt <= b_cnt-1;
                        end
                        2'b10 : begin  // in이 발생했으므로 증가
                            if (b_cnt<FIFO_NUM) b_cnt <= b_cnt+1;
                        end
                        2'b11 : b_cnt <= b_cnt; // in과 out이 동시에 발생했으므로 cnt 변화 X
                    endcase
                end
                else b_cnt <= b_cnt;
            end
        end

        // B FIFO 데이터 이동
        always @(posedge ACLK or negedge ARESETn) begin
            if (!ARESETn) begin
                for (int i=0; i<FIFO_NUM; i++) begin
                    BID_reg[i] <= '0;
                    BRESP_reg[i] <= '0;                     
                end
            end
            else begin
                if (b_fifo_in) begin
                    BID_reg[b_cnt] <= M_AXI_GP0_BID;
                    BRESP_reg[b_cnt] <= M_AXI_GP0_BRESP;
                end

                else if (b_fifo_out) begin
                    for (int i=1; i<FIFO_NUM; i++) begin
                        BID_reg[i-1] <= BID_reg[i];
                        BRESP_reg[i-1] <= BRESP_reg[i];                   
                    end
                end

                else begin
                    BID_reg[b_cnt] <= BID_reg[b_cnt];
                    BRESP_reg[b_cnt] <= BRESP_reg[b_cnt];  
                end
            end
        end


        // B Slave
        assign S_AXI_HP0_BREADY = (w_beat_remain==0)&(!w_beat_last)&(b_cnt<FIFO_NUM);

        `ifdef SIM
            initial begin
                //==================================================
                // AR FIFO / Control init
                //==================================================
                for (int i = 0; i < FIFO_NUM; i++) begin
                    ARID_reg[i]    = '0;
                    ARADDR_reg[i]  = '0;
                    ARLEN_reg[i]   = '0;
                    ARSIZE_reg[i]  = '0;
                    ARBURST_reg[i] = '0;
                end

                cnt   = '0;
                AR_en = OFF;
                start = OFF;


                //==================================================
                // R FIFO / Burst tracker init
                //==================================================
                r_burst_active = OFF;
                r_beats_remain = '0;
                r_active_id    = '0;
                d_cnt          = '0;

                for (int i = 0; i < FIFO_NUM; i++) begin
                    RID_reg[i]   = '0;
                    RDATA_reg[i] = '0;
                    RRESP_reg[i] = '0;
                    RLAST_reg[i] = OFF;
                end


                //==================================================
                // AW FIFO init
                //==================================================
                for (int i = 0; i < FIFO_NUM; i++) begin
                    AWID_reg[i]    = '0;
                    AWADDR_reg[i]  = '0;
                    AWLEN_reg[i]   = '0;
                    AWSIZE_reg[i]  = '0;
                    AWBURST_reg[i] = '0;
                end

                aw_cnt = '0;


                //==================================================
                // W FIFO / Burst tracker init
                //==================================================
                w_burst_active = OFF;
                w_beat_remain  = '0;
                w_beat_last    = OFF;
                w_cnt          = '0;

                for (int i = 0; i < FIFO_NUM; i++) begin
                    WDATA_reg[i] = '0;
                    WSTRB_reg[i] = '0;
                    WLAST_reg[i] = OFF;
                end

                //==================================================
                // B FIFO init
                //==================================================

                for (int i = 0; i < FIFO_NUM; i++) begin
                    BID_reg[i] = '0;
                    BRESP_reg[i] = '0;

                end
                b_cnt = 0;

            end
        `endif
               

    // `elsif OUT_ORDER

    //     always @(posedge ACLK or negedge ARESETn) begin
    //         if (!ARESETn) begin
    //         end
    //         else begin
    //         end
    //     end

    //     always @(posedge ACLK or negedge ARESETn) begin
    //         if (!ARESETn) begin
    //         end
    //         else begin
    //         end
    //     end

    `endif


endmodule
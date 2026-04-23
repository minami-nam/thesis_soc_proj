
`define SIM
`include "axi_param.vh"

`define ON 1
`define OFF 0
module axi_read_master(
    // AR (Read Address) Channel
    output reg [31:0] ARADDR,   // 읽을 주소
    output reg [7:0]  ARLEN,    // burst length (beats - 1)
    output reg [2:0]  ARSIZE,   // beat당 byte 수 (2^ARSIZE)
    output reg [1:0]  ARBURST,  // burst type (INCR = 2'b01)
    output reg [3:0]  ARID,     // transaction ID
    output reg        ARVALID,  // master가 address 준비됨
    input             ARREADY,  // slave가 받을 준비됨

    // R (Read Data) Channel
    input  [31:0]   RDATA,    // 읽어온 데이터
    input  [3:0]    RID,      // transaction ID (AR과 매칭)
    input  [1:0]    RRESP,    // 응답 상태 (OKAY = 2'b00)
    input           RLAST,    // burst의 마지막 beat
    input           RVALID,   // slave가 data 준비됨
    output reg      RREADY,   // master가 받을 준비됨   

    input ACLK,     // AXI clock
    input ARESETn,  // active-low reset

    //========================
    // Write Address Channel
    //========================
    output reg [31:0]  AWADDR,    // write address
    output reg [7:0]   AWLEN,     // burst length = beats-1
    output reg [2:0]   AWSIZE,    // bytes per beat = 2^AWSIZE
    output reg [1:0]   AWBURST,   // FIXED/INCR/WRAP
    output reg [3:0]   AWID,
    output reg         AWLOCK,    // AXI4: 1-bit
    output reg [3:0]   AWCACHE,   // AXI4: 4-bit
    output reg [2:0]   AWPROT,    // AXI4: 3-bit
    output reg         AWVALID,
    input              AWREADY,

    //========================
    // Write Data Channel
    //========================
    output reg [31:0]  WDATA,
    output reg [3:0]   WSTRB,     
    output reg         WLAST,
    output reg         WVALID,
    input              WREADY,

    //========================
    // Write Response Channel
    //========================
    input      [3:0]   BID,
    input      [1:0]   BRESP,
    input              BVALID,
    output reg         BREADY
);  
    
    // State 정의
    localparam IDLE      = 2'd0;  // random 값 생성
    localparam AR_VALID  = 2'd1;  // ARVALID assert, ARREADY 대기
    localparam WAIT_LAST = 2'd2;  // RLAST 대기

    // Write State 
    localparam AW_VALID = 2'd1;

    // Read logic 
    reg [1:0] state;

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            state   <= IDLE;
            ARVALID <= 0;
            ARADDR  <= 0;
            ARID    <= 0;
            ARLEN   <= 0;
            ARSIZE  <= 0;
            ARBURST <= 0;
        end

        else begin
            case (state)
                IDLE: begin
                    ARADDR  <= $urandom;
                    ARID    <= $urandom % 16;
                    ARLEN   <= $urandom % 16;
                    ARSIZE  <= 3'b010;        // 4byte 고정 권장
                    ARBURST <= `INCR;
                    ARVALID <= 1;             // 다음 cycle에 assert
                    state   <= AR_VALID;
                end

                AR_VALID: begin
                    if (ARREADY) begin        // handshake 완료
                        ARVALID <= 0;
                        state   <= WAIT_LAST;
                    end
                    
                end

                WAIT_LAST: begin
                    if (RLAST & RVALID & RREADY) begin
                        state <= IDLE;
                    end
                end
            endcase
        end
    end

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) RREADY <= 0;
        else begin
            if (state == WAIT_LAST) RREADY <= 1;  // [FIXED] WAIT_LAST 구간에서 항상 HIGH
            else                    RREADY <= 0;
        end
    end

    // Write Logic 
    reg [1:0] w_state;

    
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            AWADDR <= 0;
            AWLEN <= 0;
            AWSIZE <= 3'b010;
            AWBURST <= `FIXED;
            AWID <= 0;
            AWLOCK <= 1'b0;
            AWCACHE <= 4'b0011;
            AWPROT <= 3'b000;
            AWVALID <= 0;
            w_state <= IDLE;           
        end

        else begin
            case(w_state)
                IDLE : begin
                    AWADDR <= $urandom;
                    AWLEN <= $urandom % 16;
                    AWSIZE <= 3'b010;
                    AWBURST <= `INCR;
                    AWID <= $urandom % 16;
                    AWLOCK <= 1'b0;
                    AWCACHE <= 4'b0011;
                    AWPROT <= 3'b000;
                    AWVALID <= 1;
                    w_state <= AW_VALID;
                end
                AW_VALID : begin
                    if (AWREADY) begin
                        AWVALID <= 0;
                        w_state <= WAIT_LAST;
                    end
                end
                WAIT_LAST : begin
                    if (WLAST & WVALID & WREADY) begin
                        w_state <= IDLE;
                    end
                end
            endcase
        end
    end

    reg [6:0] w_cnt;

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            WVALID <= `OFF;
            WDATA <= 'h0;
            WSTRB <= 4'b0000;      
            w_cnt <= 0;
            WLAST <= 0;             
        end
        else begin
            if (WREADY&(w_cnt<AWLEN)) begin
                WVALID <= `ON;
                WDATA <= $urandom;
                WSTRB <= 4'b1111;      
                w_cnt <= w_cnt + 1;
                WLAST <= 0;
            end

            else if (w_cnt==AWLEN) begin
                WDATA <= $urandom;
                WSTRB <= 4'b1111; 
                w_cnt <= w_cnt + 1;
                WLAST <= 1;
                WVALID <= `ON;
            end

            else if (WLAST) begin
                WVALID <= `OFF;
     
                w_cnt <= 0;
                WLAST <= 0;  
            end

            else begin
                WDATA <= WDATA;
                WSTRB <= WSTRB;
                w_cnt <= w_cnt;
                WLAST <= WLAST;
                WVALID <= WVALID;
            end               
        end
    end    

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) BREADY <= 0;
        else BREADY <= 1;
    end

    `ifdef SIM
        initial begin
            ARLEN = 0;
            ARBURST = 0;
            ARID = 0;
            ARSIZE = 0;
            ARADDR = 0;         
            ARVALID = 0;
            RREADY = 0;
        end
        initial begin
            AWADDR = 0;
            AWLEN = 0;
            AWSIZE = 3'b010;
            AWBURST = `FIXED;
            AWID = 0;
            AWLOCK = 1'b0;
            AWCACHE = 4'b0011;
            AWPROT = 3'b000;
            AWVALID = 0;
            w_state = IDLE;
            WDATA = 0;
            WSTRB = 0;
            w_cnt = 0;
            WLAST = 0;
            BREADY = 0;
        end

    `endif




endmodule 

`define SIM
`include "axi_param.vh"

`define ON 1
`define OFF 0

module axi_read_slave(
    input         ACLK,
    input         ARESETn,

    // AR Channel
    input  [31:0] ARADDR,
    input  [3:0]  ARID,
    input  [7:0]  ARLEN,
    input  [2:0]  ARSIZE,
    input  [1:0]  ARBURST,
    input         ARVALID,
    output       ARREADY,

    // R Channel
    output reg [31:0]   RDATA,
    output reg [3:0]     RID,
    output reg [1:0]    RRESP,
    output reg          RLAST,
    output reg          RVALID,
    input               RREADY,
    //========================
    // Write Address Channel
    //========================
    input      [31:0]  AWADDR,
    input      [7:0]   AWLEN,
    input      [2:0]   AWSIZE,
    input      [1:0]   AWBURST,
    input      [3:0]   AWID,
    input              AWLOCK,     // AXI4: 1-bit
    input      [3:0]   AWCACHE,
    input      [2:0]   AWPROT,
    input              AWVALID,
    output reg         AWREADY,

    //========================
    // Write Data Channel
    //========================
    input      [31:0]  WDATA,
    input      [3:0]   WSTRB,
    input              WLAST,
    input              WVALID,
    output reg         WREADY,

    //========================
    // Write Response Channel
    //========================
    output reg [3:0]   BID,
    output reg [1:0]   BRESP,
    output reg         BVALID,
    input              BREADY    
);

    // ARREADY 
    reg busy;

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            busy <= `OFF;
        end
        else begin
            if (ARVALID) busy <= `ON;
            else if (RLAST) busy <= `OFF;
            else busy <= busy;
        end
    end

    assign ARREADY = !busy;

    // input capture

    reg [31:0] ARADDR_reg;
    reg [3:0] ARID_reg;
    reg [7:0] ARLEN_reg;
    reg [2:0] ARSIZE_reg;
    reg [1:0] ARBURST_reg;

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            ARADDR_reg <= 0;
            ARID_reg   <= 0;
            ARLEN_reg  <= 0;
            ARSIZE_reg <= 0;
            ARBURST_reg<= 0;
            RID        <= 0;  
        end

        else begin
            if (ARVALID & ARREADY) begin
                ARADDR_reg <= ARADDR;
                ARID_reg   <= ARID;
                ARLEN_reg  <= ARLEN;
                ARSIZE_reg <= ARSIZE;
                ARBURST_reg<= ARBURST;
                RID        <= ARID;    // [FIXED] 캡처 시점에 미리 설정
            end

            else if (RLAST) begin
                ARADDR_reg <= 0;
                ARID_reg   <= 0;
                ARLEN_reg  <= 0;
                ARSIZE_reg <= 0;
                ARBURST_reg<= 0;
                RID        <= 0;
            end
        end
    end


    // RVALID

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            RVALID <= `OFF;
        end
        else begin
            if (busy&!RVALID) RVALID <= $urandom % 2;
            else if (RLAST) RVALID <= `OFF;
            else RVALID <= RVALID;
        end
    end

    // RDATA + cnt

    reg [9:0] cnt;

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            RDATA <= 'h0;
            RID <= 'h0;
            RRESP <= 2'b00;      
            cnt <= 0;
            RLAST <= 0;  
        end
        else begin
            if (RREADY&(cnt<ARLEN_reg)) begin
                RDATA <= $urandom;

                RRESP <= 2'b00;      // Good
                cnt <= cnt + 1;
                RLAST <= 0;
            end

            else if (cnt==ARLEN_reg) begin
                RDATA <= $urandom;

                RRESP <= 2'b00;      // Good
                cnt <= cnt + 1;
                RLAST <= 1;
            end

            else if (RLAST) begin
                RDATA <= 'h0;

                RRESP <= 2'b00;      
                cnt <= 0;
                RLAST <= 0;  
            end

            else begin
                RDATA <= RDATA;
                RRESP <= RRESP;
                cnt <= cnt;
                RLAST <= RLAST;
            end
        end
    end

    reg start;
    reg    [7:0] AWLEN_reg;
    reg    [2:0] AWSIZE_reg;
    reg    [1:0] AWBURST_reg;
    reg    [3:0] AWID_reg;
    reg    [2:0] AWLOCK_reg;
    reg    [3:0] AWPROT_reg;

    // Write Seq
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            AWLEN_reg <= 0;
            AWSIZE_reg <= 0;
            AWBURST_reg <= 0;
            AWID_reg <= 0;
            AWLOCK_reg <= 0;
            AWPROT_reg <= 0; 
            start <= `OFF;          
        end

        else begin
            if (AWVALID & AWREADY) begin
                AWLEN_reg <= AWLEN;
                AWSIZE_reg <= AWSIZE;
                AWBURST_reg <= AWBURST;
                AWID_reg <= AWID;
                AWLOCK_reg <= AWLOCK;
                AWPROT_reg <= AWPROT;
                start <= `ON;
            end

            else if (WLAST) begin
                AWLEN_reg <= 0;
                AWSIZE_reg <= 0;
                AWBURST_reg <= 0;
                AWID_reg <= 0;
                AWLOCK_reg <= 0;
                AWPROT_reg <= 0;
                start <= `OFF;
            end
        end
    end

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            WREADY <= `OFF;
        end
        else begin
            if (AWVALID&!WREADY) WREADY <= 1;
            else if (WLAST) WREADY <= `OFF;
            else WREADY <= WREADY;
        end
    end

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) AWREADY <= `OFF;
        else begin
            if (!AWREADY) AWREADY <= $urandom % 2;
            
            else if (AWVALID&AWREADY) AWREADY <= `OFF;

            else AWREADY <= AWREADY;
        end
    end

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            BID <= 0;
            BRESP <= 0;
            BVALID <= 0;
        end

        else begin
            if (WVALID && WREADY && WLAST) begin
                BID <= AWID_reg;
                BRESP <= 2'b00;
                BVALID <= `ON;
            end
            else if (BVALID && BREADY) begin
                BVALID <= `OFF;
            end
        end
    end

    `ifdef SIM
        initial begin
            cnt = 0;
            ARADDR_reg = 0;
            ARID_reg = 0;
            ARLEN_reg = 0;
            ARSIZE_reg = 0;
            ARBURST_reg = 0;

            RDATA = 0;
            RID = 0;
            RRESP = 0;
            RLAST = 0;
            RVALID = 0;
            busy = 0;
        end

        initial begin
            AWLEN_reg = 0;
            AWSIZE_reg = 0;
            AWBURST_reg = 0;
            AWID_reg = 0;
            AWLOCK_reg = 0;
            AWPROT_reg = 0;
            start = `OFF;

            AWREADY = `OFF;
            WREADY = `OFF;
            BID = 0;
            BRESP = 0;
            BVALID = 0;
        end
    `endif






endmodule
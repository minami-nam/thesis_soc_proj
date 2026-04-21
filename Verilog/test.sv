module tb_axi_read_master;
    // AR (Read Address) Channel
    wire [31:0] ARADDR;   // 읽을 주소
    wire [7:0]  ARLEN;    // burst length (beats - 1)
    wire [2:0]  ARSIZE;   // beat당 byte 수 (2^ARSIZE)
    wire [1:0]  ARBURST;  // burst type (INCR = 2'b01)
    wire [3:0]  ARID;     // transaction ID
    wire        ARVALID;  // master가 address 준비됨
    reg         ARREADY;  // slave가 받을 준비됨

    // R (Read Data) Channel
    reg  [31:0]   RDATA;    // 읽어온 데이터
    reg  [3:0]    RID;      // transaction ID (AR과 매칭)
    reg  [1:0]    RRESP;    // 응답 상태 (OKAY = 2'b00)
    reg           RLAST;    // burst의 마지막 beat
    reg           RVALID;   // slave가 data 준비됨
    wire        RREADY;   // master가 받을 준비됨   

    reg ACLK;     // AXI clock
    reg ARESETn;  // active-low reset


    

endmodule
















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
    output reg      RREADY   // master가 받을 준비됨   

    input ACLK,     // AXI clock
    input ARESETn  // active-low reset
);  
    
    // Handshake Rule 1. Vaild Assert 이후, READY가 올 때까지 절대 Deassert 금지
    reg wait_last;

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            ARVALID <= 0;
            wait_last <= `OFF;
        end

        else begin
            if (!ARVALID&!wait_last) begin
                ARVALID <= $urandom % 2; // modulo 연산으로 0과 1만 생성함.
                wait_last <= `OFF;
            end
            else begin
                if ((ARVALID&ARREADY)&!wait_last) begin
                    ARVALID <= 0;
                    wait_last <= `ON;
                end
                else if (RLAST&wait_last) begin
                    ARVALID <= 0;
                    wait_last <= `OFF;
                end
                else if ((!wait_last)&(ARVAILD&!ARREADY)) begin
                    ARVALID <= 1;
                    wait_last <= `OFF;
                end
                else begin
                    ARVALID <= 0;
                    wait_last <= `ON;                    
                end
            end
        end
    end


    
    
    // 2. Handshake output 설정
    reg stay;
    reg [3:0] reg_ARID;

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) reg_ARID <= 0;
        else begin
            if (stay&(ARVALID&!ARREADY)) reg_ARID <= ARID;
            else if (RLAST&wait_last) reg_ARID <= 0;
            else reg_ARID <= reg_ARID;
        end
    end

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            ARLEN <= 0;
            ARBURST <= 0;
            ARID <= 0;
            ARSIZE <= 0;
            ARADDR <= 0;         
            stay <= `OFF;       
        end

        else begin
            if (!stay&(ARVALID&!ARREADY)) begin
                ARLEN <= $urandom % 16;
                ARBURST <= $urandom % 4;
                ARID <= $urandom % 16;
                ARSIZE <= $urandom % 4;
                ARADDR <= $urandom;
                stay <= `ON;
            end

            else if (stay&(ARVALID&!ARREADY)) begin
                ARLEN <= ARLEN;
                ARBURST <= ARBURST;
                ARID <= ARID;
                ARSIZE <= ARSIZE;
                ARADDR <= ARADDR;   
                stay <= `ON;          
            end

            else if (stay&(ARVALID&ARREADY)) begin
                ARLEN <= 0;
                ARBURST <= 0;
                ARID <= 0;
                ARSIZE <= 0;
                ARADDR <= 0;
                stay <= `OFF;
            end

            else begin
                ARLEN <= 0;
                ARBURST <= 0;
                ARID <= 0;
                ARSIZE <= 0;
                ARADDR <= 0;
                stay <= `OFF;                
            end
        end
    end       



    // 3. Handshake Data 검증

    always @(posedge ACLK) begin
        if (RVALID && RREADY) begin
            if (RID!=reg_ARID) $display("ERROR : ID Mismatch! , expected %0d, but got %0d", reg_ARID, RID);
        end
    end

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            RREADY <= `OFF;
        end
        else begin
            if (ARVALID&ARREADY) RREADY <= `ON;
            else if (RLAST) RREADY <= `OFF;
            else RREADY <= RREADY;
        end
    end

    `ifdef SIM
        initial begin
            ARLEN = 0;
            ARBURST = 0;
            ARID = 0;
            ARSIZE = 0;
            ARADDR = 0;         
            stay = `OFF;    
            reg_ARID = 0;
            wait_last = 0;
            ARVALID = 0;
            RREADY = 0;
        end
    `endif




endmodule 
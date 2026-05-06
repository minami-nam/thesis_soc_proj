`include "axi_include_top.vh"
import axi_pkg::*;

module axi_ooo_read_queue_cache #(
    parameter int ADDR_WIDTH = 32,
    parameter int ID_WIDTH = 4,
    parameter int LEN_WIDTH = 8,
    parameter int NUM_READ_IDTABLE = 4
) (
    input [ID_WIDTH-1:0] i_id,
    input [ADDR_WIDTH-1:0] i_addr,
    input [LEN_WIDTH-1:0] i_len,
    input [2:0] i_size,
    input [1:0] i_burst,

    input ACLK,
    input ARESETn,
    input data_in_valid,
    input data_out_ready,

    output [ID_WIDTH-1:0] o_id,
    output [ADDR_WIDTH-1:0] o_addr,
    output [LEN_WIDTH-1:0] o_len,
    output [2:0] o_size,
    output [1:0] o_burst,
    output data_in_ready,
    output data_out_valid
);
    // reg 정의

    reg [ID_WIDTH-1:0] reg_id[0:NUM_READ_IDTABLE-1];
    reg [ADDR_WIDTH-1:0] reg_addr[0:NUM_READ_IDTABLE-1];
    reg [LEN_WIDTH-1:0] reg_len[0:NUM_READ_IDTABLE-1];
    reg [2:0] reg_size[0:NUM_READ_IDTABLE-1];
    reg [1:0] reg_burst[0:NUM_READ_IDTABLE-1];
    reg [$clog2(NUM_READ_IDTABLE)-1:0] cnt, wr_ptr, rd_ptr;

    // 데이터 입출력 조건
    wire data_in = data_in_valid&data_in_ready;
    wire data_out = data_out_valid&data_out_ready;

    assign data_in_ready = (cnt<NUM_READ_IDTABLE) ? ON : OFF;
    assign data_out_valid = (cnt!=0) ? ON : OFF;

    // cnt 관련
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) cnt <= '0;
        
        else begin
            case({data_in, data_out})
                2'b00 : cnt <= cnt; // data in out 발생 X 
                2'b01 : begin   // data out만 발생
                    if (cnt!=0) cnt <= cnt-1;
                end
                2'b10 : begin   // data in만 발생
                    if (cnt<NUM_READ_IDTABLE) cnt <= cnt+1;
                end
                2'b11 : cnt <= cnt; // data in out 동시 발생
            endcase
        end
    end

    // ptr 관련

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            wr_ptr <= '0;
            rd_ptr <= '0;
        end
        else begin
            if (data_in) begin
               if (wr_ptr==NUM_READ_IDTABLE-1) wr_ptr <= '0;
               else wr_ptr <= wr_ptr + 1; 
            end
            else if (data_out) begin
                if (rd_ptr==NUM_READ_IDTABLE-1) rd_ptr <= '0;
                else rd_ptr <= rd_ptr + 1;
            end
            else begin
                rd_ptr <= rd_ptr;
                wr_ptr <= wr_ptr;
            end
        end
    end

    // data write 관련 

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            for (int i=0; i<NUM_READ_IDTABLE; i++) begin
                reg_id[i] <= '0;
                reg_addr[i] <= '0;
                reg_len[i] <= '0;
                reg_size[i] <= '0;
                reg_burst[i] <= '0;
            end
        end
        else begin
            if (data_in) begin
                reg_addr[wr_ptr] <= i_addr;
                reg_id[wr_ptr] <= i_id;
                reg_len[wr_ptr] <= i_len;
                reg_size[wr_ptr] <= i_size;
                reg_burst[wr_ptr] <= i_burst;
            end
        end
    end

    assign o_id = (data_out_valid) ? reg_id[rd_ptr] : '0;
    assign o_addr = (data_out_valid) ? reg_addr[rd_ptr] : '0;
    assign o_len = (data_out_valid) ? reg_len[rd_ptr] : '0;
    assign o_size = (data_out_valid) ? reg_size[rd_ptr] : '0;
    assign o_burst = (data_out_valid) ? reg_burst[rd_ptr] : '0;

    

    `ifdef INITIAL_REG_RESET
        initial begin
            for (int i=0; i<NUM_READ_IDTABLE; i++) begin
                reg_id[i] = '0;
                reg_addr[i] = '0;
                reg_burst[i] = '0;
                reg_len[i] = '0;
                reg_size[i] = '0;
            end  
            cnt = '0;
            wr_ptr = 0;
            rd_ptr = '0;
        end
    `endif

endmodule

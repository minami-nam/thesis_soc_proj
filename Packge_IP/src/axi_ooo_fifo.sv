`include "axi_include_top.vh"
import axi_pkg::*;

module fifo_small #(
    parameter int per_id = 8,
    parameter int DATA_WIDTH = 32,
    parameter int ID_WIDTH = 4
)(    
    input  wire ACLK,
    input  wire ARESETn,

    input  wire [ID_WIDTH-1:0]   in_rid,
    input  wire [DATA_WIDTH-1:0] in_rdata,
    input  wire [1:0]            in_rresp,
    input  wire                  in_rlast,
    input  wire                  in_rvalid,
    output wire                  in_rready,

    // To M_AXI_GP0 R channel
    output wire [ID_WIDTH-1:0]   out_rid,
    output wire [DATA_WIDTH-1:0] out_rdata,
    output wire [1:0]            out_rresp,
    output wire                  out_rlast,
    output wire                  out_rvalid,
    input  wire                  out_rready

);
    localparam PTR_WIDTH = (per_id <= 1) ? 1 : $clog2(per_id);
    localparam CNT_WIDTH = $clog2(per_id+1);
    localparam [PTR_WIDTH-1:0] LAST_PTR = per_id-1;
    localparam [CNT_WIDTH-1:0] FIFO_DEPTH = per_id;

    reg [ID_WIDTH-1:0]   rid_cache[0:per_id-1];
    reg [DATA_WIDTH-1:0] rdata_cache[0:per_id-1];
    reg [1:0]            rresp_cache[0:per_id-1];
    reg                  rlast_cache[0:per_id-1];

    reg [PTR_WIDTH-1:0] rd_ptr;
    reg [PTR_WIDTH-1:0] wr_ptr;
    reg [CNT_WIDTH-1:0] cnt;

    wire data_in;
    wire data_out;
    wire full;
    wire empty;

    assign full = (cnt == FIFO_DEPTH);
    assign empty = (cnt == '0);

    assign out_rvalid = !empty;
    assign in_rready = !full || data_out;

    assign data_in = in_rvalid && in_rready;
    assign data_out = out_rvalid && out_rready;

    assign out_rid = rid_cache[rd_ptr];
    assign out_rdata = rdata_cache[rd_ptr];
    assign out_rresp = rresp_cache[rd_ptr];
    assign out_rlast = rlast_cache[rd_ptr];

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            rd_ptr <= '0;
            wr_ptr <= '0;
            cnt <= '0;
        end
        else begin
            case ({data_in, data_out})
                2'b00: cnt <= cnt;
                2'b01: cnt <= cnt - 1'b1;
                2'b10: cnt <= cnt + 1'b1;
                2'b11: cnt <= cnt;
            endcase

            if (data_out) begin
                if (rd_ptr == LAST_PTR) rd_ptr <= '0;
                else rd_ptr <= rd_ptr + 1'b1;
            end

            if (data_in) begin
                if (wr_ptr == LAST_PTR) wr_ptr <= '0;
                else wr_ptr <= wr_ptr + 1'b1;
            end
        end
    end

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            for (int i=0; i<per_id; i++) begin
                rid_cache[i] <= '0;
                rdata_cache[i] <= '0;
                rresp_cache[i] <= '0;
                rlast_cache[i] <= '0;
            end
        end
        else begin
            if (data_in) begin
                rid_cache[wr_ptr] <= in_rid;
                rdata_cache[wr_ptr] <= in_rdata;
                rresp_cache[wr_ptr] <= in_rresp;
                rlast_cache[wr_ptr] <= in_rlast;
            end
        end
    end

    `ifdef INITIAL_REG_RESET
        initial begin
            rd_ptr = '0;
            wr_ptr = '0;
            cnt = '0;

            for (int i=0; i<per_id; i++) begin
                rid_cache[i] = '0;
                rdata_cache[i] = '0;
                rresp_cache[i] = '0;
                rlast_cache[i] = '0;
            end
        end
    `endif

endmodule

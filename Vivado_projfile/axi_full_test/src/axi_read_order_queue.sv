`include "axi_include_top.vh"
import axi_pkg::*;

module axi_read_order_queue #(
    parameter int DATA_WIDTH = 32,
    parameter int ID_WIDTH = 4,
    parameter int NUM_READ_IDTABLE = 16,
    parameter int LEN_WIDTH = 8,
    parameter int NUM_READ_REORDER = 4
)(
    input  wire ACLK,
    input  wire ARESETn,

    //==================================================
    // AR order input
    //==================================================
    input  wire                in_arvalid,
    output wire                in_arready,
    input  wire [LEN_WIDTH:0]  in_arlen,
    input  wire [ID_WIDTH-1:0] in_arid,

    //==================================================
    // R channel input
    //==================================================
    input  wire                  in_rvalid,
    output wire                  in_rready,

    input  wire [ID_WIDTH-1:0]   in_rid,
    input  wire [DATA_WIDTH-1:0] in_rdata,
    input  wire [1:0]            in_rresp,
    input  wire                  in_rlast,

    //==================================================
    // Ordered R channel output
    //==================================================
    output wire                  out_valid,
    output wire [ID_WIDTH-1:0]   out_rid,
    output wire [DATA_WIDTH-1:0] out_rdata,
    output wire [1:0]            out_rresp,
    output wire                  out_rlast,
    input  wire                  out_ready
);

    // ============================================================
    // Local parameters
    // ============================================================
    localparam int RID_INDEX_WIDTH =
        (NUM_READ_IDTABLE <= 1) ? 1 : $clog2(NUM_READ_IDTABLE);

    localparam int ORDER_DEPTH = NUM_READ_IDTABLE;

    localparam int ORDER_PTR_WIDTH =
        (ORDER_DEPTH <= 1) ? 1 : $clog2(ORDER_DEPTH);

    localparam int ORDER_CNT_WIDTH =
        (ORDER_DEPTH <= 1) ? 1 : $clog2(ORDER_DEPTH + 1);

    localparam int BEAT_CNT_WIDTH = LEN_WIDTH + 1;

    // ============================================================
    // Per-RID FIFO wires
    // ============================================================
    wire [ID_WIDTH-1:0]   integ_in_rid    [0:NUM_READ_IDTABLE-1];
    wire [DATA_WIDTH-1:0] integ_in_rdata  [0:NUM_READ_IDTABLE-1];
    wire [1:0]            integ_in_rresp  [0:NUM_READ_IDTABLE-1];
    wire                  integ_in_rlast  [0:NUM_READ_IDTABLE-1];
    wire                  integ_in_rvalid [0:NUM_READ_IDTABLE-1];
    wire                  integ_in_rready [0:NUM_READ_IDTABLE-1];

    wire [ID_WIDTH-1:0]   integ_out_rid    [0:NUM_READ_IDTABLE-1];
    wire [DATA_WIDTH-1:0] integ_out_rdata  [0:NUM_READ_IDTABLE-1];
    wire [1:0]            integ_out_rresp  [0:NUM_READ_IDTABLE-1];
    wire                  integ_out_rlast  [0:NUM_READ_IDTABLE-1];
    wire                  integ_out_rvalid [0:NUM_READ_IDTABLE-1];
    wire                  integ_out_rready [0:NUM_READ_IDTABLE-1];

    // ============================================================
    // AR order queue
    // Stores ARID and ARLEN in the order accepted from original master.
    // ============================================================
    reg [ID_WIDTH-1:0]       order_rid_q   [0:ORDER_DEPTH-1];
    reg [BEAT_CNT_WIDTH-1:0] order_len_q   [0:ORDER_DEPTH-1];

    reg [ORDER_PTR_WIDTH-1:0] order_wr_ptr;
    reg [ORDER_PTR_WIDTH-1:0] order_rd_ptr;
    reg [ORDER_CNT_WIDTH-1:0] order_count;

    wire order_empty = (order_count == '0);
    wire order_full  = (order_count == ORDER_DEPTH[ORDER_CNT_WIDTH-1:0]);

    wire [ID_WIDTH-1:0] head_rid =
        order_empty ? '0 : order_rid_q[order_rd_ptr];

    wire [BEAT_CNT_WIDTH-1:0] head_len =
        order_empty ? '0 : order_len_q[order_rd_ptr];

    wire head_rid_in_range = (head_rid < NUM_READ_IDTABLE);

    wire [RID_INDEX_WIDTH-1:0] head_idx =
        head_rid[RID_INDEX_WIDTH-1:0];

    // ============================================================
    // Handshake
    // ============================================================
    wire out_fire = out_valid && out_ready;

    // 실제 RLAST가 출력 handshake된 순간에 해당 AR order pop
    wire order_pop = out_fire && out_rlast;

    // pop과 push가 같은 cycle에 일어날 수 있으므로,
    // pop이 있으면 full 상태에서도 push 허용
    assign in_arready = (!order_full) || order_pop;

    wire order_push = in_arvalid && in_arready;

    // ============================================================
    // Incoming R routing by RID
    // ============================================================
    wire in_rid_in_range = (in_rid < NUM_READ_IDTABLE);

    assign in_rready =
        in_rid_in_range ? integ_in_rready[in_rid[RID_INDEX_WIDTH-1:0]] : 1'b0;

    // ============================================================
    // Output selection
    // Only the FIFO corresponding to order queue head can drive output.
    // ============================================================
    assign out_valid =
        (!order_empty && head_rid_in_range) ?
        integ_out_rvalid[head_idx] : 1'b0;

    assign out_rid =
        (!order_empty && head_rid_in_range) ?
        integ_out_rid[head_idx] : '0;

    assign out_rdata =
        (!order_empty && head_rid_in_range) ?
        integ_out_rdata[head_idx] : '0;

    assign out_rresp =
        (!order_empty && head_rid_in_range) ?
        integ_out_rresp[head_idx] : 2'b00;

    assign out_rlast =
        (!order_empty && head_rid_in_range) ?
        integ_out_rlast[head_idx] : 1'b0;

    // ============================================================
    // Generate per-RID FIFOs
    // ============================================================
    genvar a;
    genvar i;

    generate
        for (a = 0; a < NUM_READ_IDTABLE; a = a + 1) begin : input_assign_wires

            assign integ_in_rid[a] =
                (in_rid_in_range &&
                 (in_rid[RID_INDEX_WIDTH-1:0] == RID_INDEX_WIDTH'(a))) ?
                in_rid : '0;

            assign integ_in_rdata[a] =
                (in_rid_in_range &&
                 (in_rid[RID_INDEX_WIDTH-1:0] == RID_INDEX_WIDTH'(a))) ?
                in_rdata : '0;

            assign integ_in_rresp[a] =
                (in_rid_in_range &&
                 (in_rid[RID_INDEX_WIDTH-1:0] == RID_INDEX_WIDTH'(a))) ?
                in_rresp : 2'b00;

            assign integ_in_rlast[a] =
                (in_rid_in_range &&
                 (in_rid[RID_INDEX_WIDTH-1:0] == RID_INDEX_WIDTH'(a))) ?
                in_rlast : 1'b0;

            assign integ_in_rvalid[a] =
                (in_rid_in_range &&
                 (in_rid[RID_INDEX_WIDTH-1:0] == RID_INDEX_WIDTH'(a))) ?
                in_rvalid : 1'b0;
        end

        for (i = 0; i < NUM_READ_IDTABLE; i = i + 1) begin : instantiate_fifo_cache

            // order queue head RID에 해당하는 FIFO만 pop 허용
            assign integ_out_rready[i] =
                (!order_empty &&
                 head_rid_in_range &&
                 (head_idx == RID_INDEX_WIDTH'(i))) ?
                out_ready : 1'b0;

            fifo_small #(
                .per_id(NUM_READ_REORDER),
                .DATA_WIDTH(DATA_WIDTH),
                .ID_WIDTH(ID_WIDTH)
            ) fifo_integ (
                .ACLK(ACLK),
                .ARESETn(ARESETn),

                .in_rid(integ_in_rid[i]),
                .in_rdata(integ_in_rdata[i]),
                .in_rresp(integ_in_rresp[i]),
                .in_rlast(integ_in_rlast[i]),
                .in_rvalid(integ_in_rvalid[i]),
                .in_rready(integ_in_rready[i]),

                .out_rid(integ_out_rid[i]),
                .out_rdata(integ_out_rdata[i]),
                .out_rresp(integ_out_rresp[i]),
                .out_rlast(integ_out_rlast[i]),
                .out_rvalid(integ_out_rvalid[i]),
                .out_rready(integ_out_rready[i])
            );
        end
    endgenerate

    // ============================================================
    // Order queue sequential logic
    // ============================================================
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            order_wr_ptr <= '0;
            order_rd_ptr <= '0;
            order_count  <= '0;

            for (int q = 0; q < ORDER_DEPTH; q = q + 1) begin
                order_rid_q[q] <= '0;
                order_len_q[q] <= '0;
            end
        end
        else begin
            // ----------------------------------------------------
            // Push AR order
            // in_arlen은 AXI ARLEN = beats - 1로 가정
            // order_len_q는 debug/check용으로 beats 수 저장
            // 현재 pop 자체는 out_rlast 기준
            // ----------------------------------------------------
            if (order_push) begin
                order_rid_q[order_wr_ptr] <= in_arid;
                order_len_q[order_wr_ptr] <= in_arlen[BEAT_CNT_WIDTH-1:0] + BEAT_CNT_WIDTH'(1);

                if (order_wr_ptr == ORDER_PTR_WIDTH'(ORDER_DEPTH - 1))
                    order_wr_ptr <= '0;
                else
                    order_wr_ptr <= order_wr_ptr + 1'b1;
            end

            // ----------------------------------------------------
            // Pop AR order when ordered RLAST beat is accepted.
            // ----------------------------------------------------
            if (order_pop) begin
                if (order_rd_ptr == ORDER_PTR_WIDTH'(ORDER_DEPTH - 1))
                    order_rd_ptr <= '0;
                else
                    order_rd_ptr <= order_rd_ptr + 1'b1;
            end

            // ----------------------------------------------------
            // Queue count update
            // push와 pop이 동시에 발생하면 count 유지
            // ----------------------------------------------------
            case ({order_push, order_pop})
                2'b10: order_count <= order_count + 1'b1;
                2'b01: order_count <= order_count - 1'b1;
                default: order_count <= order_count;
            endcase
        end
    end

    `ifdef INITIAL_REG_RESET
        initial begin
            order_wr_ptr = '0;
            order_rd_ptr = '0;
            order_count  = '0;

            for (int q = 0; q < ORDER_DEPTH; q = q + 1) begin
                order_rid_q[q] = '0;
                order_len_q[q] = '0;
            end
        end
    `endif

endmodule
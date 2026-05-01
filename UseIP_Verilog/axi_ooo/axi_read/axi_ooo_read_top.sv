`include "axi_include_top.vh"
import axi_pkg::*;

module axi_read_ooo(
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
    // R Channel
    output wire [ID_WIDTH-1:0]     M_AXI_GP0_RID,
    output wire [DATA_WIDTH-1:0]   M_AXI_GP0_RDATA,
    output wire [1:0]              M_AXI_GP0_RRESP,
    output wire                    M_AXI_GP0_RLAST,
    output wire                    M_AXI_GP0_RVALID,
    input  wire                    M_AXI_GP0_RREADY,

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

    // R Channel
    input  wire [ID_WIDTH-1:0]     S_AXI_HP0_RID,
    input  wire [DATA_WIDTH-1:0]   S_AXI_HP0_RDATA,
    input  wire [1:0]              S_AXI_HP0_RRESP,
    input  wire                    S_AXI_HP0_RLAST,
    input  wire                    S_AXI_HP0_RVALID,
    output wire                    S_AXI_HP0_RREADY

);

    // AR request path: M_AXI_GP0 -> queue cache -> scheduler -> S_AXI_HP0
    wire [ID_WIDTH-1:0]   queue_o_id;
    wire [ADDR_WIDTH-1:0] queue_o_addr;
    wire [LEN_WIDTH-1:0]  queue_o_len;
    wire [2:0]            queue_o_size;
    wire [1:0]            queue_o_burst;
    wire                  queue_o_valid;

    wire [ID_WIDTH-1:0]   sched_o_id;
    wire [ADDR_WIDTH-1:0] sched_o_addr;
    wire [LEN_WIDTH-1:0]  sched_o_len;
    wire [2:0]            sched_o_size;
    wire [1:0]            sched_o_burst;
    wire                  sched_o_valid;
    wire                  sched_o_ready;

    axi_ooo_read_queue_cache u_read_queue_cache (
        .i_id(M_AXI_GP0_ARID),
        .i_addr(M_AXI_GP0_ARADDR),
        .i_len(M_AXI_GP0_ARLEN),
        .i_size(M_AXI_GP0_ARSIZE),
        .i_burst(M_AXI_GP0_ARBURST),

        .ACLK(ACLK),
        .ARESETn(ARESETn),
        .data_in_valid(M_AXI_GP0_ARVALID),
        .data_out_ready(sched_o_ready),

        .o_id(queue_o_id),
        .o_addr(queue_o_addr),
        .o_len(queue_o_len),
        .o_size(queue_o_size),
        .o_burst(queue_o_burst),
        .data_in_ready(M_AXI_GP0_ARREADY),
        .data_out_valid(queue_o_valid)
    );

    axi_ooo_read_scheduler u_read_scheduler (
        .i_id(queue_o_id),
        .i_addr(queue_o_addr),
        .i_len(queue_o_len),
        .i_size(queue_o_size),
        .i_burst(queue_o_burst),
        .i_valid(queue_o_valid),
        .o_ready(sched_o_ready),

        .ACLK(ACLK),
        .ARESETn(ARESETn),
        .i_ready(S_AXI_HP0_ARREADY),

        .o_id(sched_o_id),
        .o_addr(sched_o_addr),
        .o_len(sched_o_len),
        .o_size(sched_o_size),
        .o_burst(sched_o_burst),
        .o_valid(sched_o_valid)
    );

    assign S_AXI_HP0_ARID = sched_o_id;
    assign S_AXI_HP0_ARADDR = sched_o_addr;
    assign S_AXI_HP0_ARLEN = sched_o_len;
    assign S_AXI_HP0_ARSIZE = sched_o_size;
    assign S_AXI_HP0_ARBURST = sched_o_burst;
    assign S_AXI_HP0_ARVALID = sched_o_valid;

    // R response path: S_AXI_HP0 -> reorder buffer -> M_AXI_GP0
    axi_ooo_read_reorder_buff u_read_reorder_buff (
        .ACLK(ACLK),
        .ARESETn(ARESETn),

        .in_rid(S_AXI_HP0_RID),
        .in_rdata(S_AXI_HP0_RDATA),
        .in_rresp(S_AXI_HP0_RRESP),
        .in_rlast(S_AXI_HP0_RLAST),
        .in_rvalid(S_AXI_HP0_RVALID),
        .in_rready(S_AXI_HP0_RREADY),

        .out_rid(M_AXI_GP0_RID),
        .out_rdata(M_AXI_GP0_RDATA),
        .out_rresp(M_AXI_GP0_RRESP),
        .out_rlast(M_AXI_GP0_RLAST),
        .out_rvalid(M_AXI_GP0_RVALID),
        .out_rready(M_AXI_GP0_RREADY)
    );

    
    `ifdef SIM

    `endif

endmodule

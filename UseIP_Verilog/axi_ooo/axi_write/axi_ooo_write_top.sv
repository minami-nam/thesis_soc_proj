`include "axi_include_top.vh"
import axi_pkg::*;

module axi_write_ooo(
    input  wire ACLK,
    input  wire ARESETn,

    //==================================================
    // From Zynq PS M_AXI_GP0
    // Controller receives requests from PS
    //==================================================

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

    // B Channel
    output wire [ID_WIDTH-1:0]     M_AXI_GP0_BID,
    output wire [1:0]              M_AXI_GP0_BRESP,
    output wire                    M_AXI_GP0_BVALID,
    input  wire                    M_AXI_GP0_BREADY,

    //==================================================
    // To Zynq PS S_AXI_HP0
    // Controller issues requests to PS memory subsystem
    //==================================================

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

    // B Channel
    input  wire [ID_WIDTH-1:0]     S_AXI_HP0_BID,
    input  wire [1:0]              S_AXI_HP0_BRESP,
    input  wire                    S_AXI_HP0_BVALID,
    output wire                    S_AXI_HP0_BREADY
);

    // AW request path: M_AXI_GP0 -> aw_queue -> scheduler -> S_AXI_HP0
    wire [ID_WIDTH-1:0]   queue_o_awid;
    wire [ADDR_WIDTH-1:0] queue_o_awaddr;
    wire [LEN_WIDTH-1:0]  queue_o_awlen;
    wire [2:0]            queue_o_awsize;
    wire [1:0]            queue_o_awburst;
    wire                  queue_o_awvalid;
    wire                  queue_o_awready;
    wire                  sched_i_awready;

    wire [ID_WIDTH-1:0]   sched_o_awid;
    wire [ADDR_WIDTH-1:0] sched_o_awaddr;
    wire [LEN_WIDTH-1:0]  sched_o_awlen;
    wire [2:0]            sched_o_awsize;
    wire [1:0]            sched_o_awburst;
    wire                  sched_o_awvalid;
    wire                  sched_o_awready;

    wire                  order_aw_queue_ready;
    wire                  order_aw_scheduler_ready;
    wire                  b_aw_scheduler_ready;
    wire                  aw_queue_fire;
    wire                  aw_scheduler_fire;

    // W order path: M_AXI_GP0 -> order_queue -> S_AXI_HP0
    wire [DATA_WIDTH-1:0]   order_o_wdata;
    wire [DATA_WIDTH/8-1:0] order_o_wstrb;
    wire                    order_o_wlast;
    wire                    order_o_wvalid;
    wire                    order_o_wready;
    wire                    b_wready;

    assign queue_o_awready = sched_i_awready && order_aw_queue_ready;
    assign sched_o_awready = S_AXI_HP0_AWREADY && order_aw_scheduler_ready && b_aw_scheduler_ready;
    assign aw_queue_fire = queue_o_awvalid && queue_o_awready;
    assign aw_scheduler_fire = sched_o_awvalid && sched_o_awready;

    assign S_AXI_HP0_AWID = sched_o_awid;
    assign S_AXI_HP0_AWADDR = sched_o_awaddr;
    assign S_AXI_HP0_AWLEN = sched_o_awlen;
    assign S_AXI_HP0_AWSIZE = sched_o_awsize;
    assign S_AXI_HP0_AWBURST = sched_o_awburst;
    assign S_AXI_HP0_AWVALID = sched_o_awvalid && order_aw_scheduler_ready && b_aw_scheduler_ready;

    assign order_o_wready = S_AXI_HP0_WREADY && b_wready;
    assign S_AXI_HP0_WDATA = order_o_wdata;
    assign S_AXI_HP0_WSTRB = order_o_wstrb;
    assign S_AXI_HP0_WLAST = order_o_wlast;
    assign S_AXI_HP0_WVALID = order_o_wvalid && b_wready;

    axi_ooo_aw_queue u_write_aw_queue (
        .i_AWID(M_AXI_GP0_AWID),
        .i_AWADDR(M_AXI_GP0_AWADDR),
        .i_AWLEN(M_AXI_GP0_AWLEN),
        .i_AWSIZE(M_AXI_GP0_AWSIZE),
        .i_AWBURST(M_AXI_GP0_AWBURST),

        .i_AWVALID(M_AXI_GP0_AWVALID),
        .i_AWREADY(M_AXI_GP0_AWREADY),

        .ACLK(ACLK),
        .ARESETn(ARESETn),

        .o_AWID(queue_o_awid),
        .o_AWADDR(queue_o_awaddr),
        .o_AWLEN(queue_o_awlen),
        .o_AWSIZE(queue_o_awsize),
        .o_AWBURST(queue_o_awburst),

        .o_AWREADY(queue_o_awready),
        .o_AWVALID(queue_o_awvalid)
    );

    axi_ooo_aw_scheduler u_write_aw_scheduler (
        .ACLK(ACLK),
        .ARESETn(ARESETn),

        .i_AWID(queue_o_awid),
        .i_AWADDR(queue_o_awaddr),
        .i_AWLEN(queue_o_awlen),
        .i_AWSIZE(queue_o_awsize),
        .i_AWBURST(queue_o_awburst),

        .i_AWVALID(queue_o_awvalid && order_aw_queue_ready),
        .i_AWREADY(sched_i_awready),

        .o_AWID(sched_o_awid),
        .o_AWADDR(sched_o_awaddr),
        .o_AWLEN(sched_o_awlen),
        .o_AWSIZE(sched_o_awsize),
        .o_AWBURST(sched_o_awburst),

        .o_AWREADY(sched_o_awready),
        .o_AWVALID(sched_o_awvalid)
    );

    axi_ooo_aw_write_order_queue u_write_order_queue (
        .ACLK(ACLK),
        .ARESETn(ARESETn),

        .aw_queue_fire(aw_queue_fire),
        .aw_queue_ready(order_aw_queue_ready),
        .i_queue_AWID(queue_o_awid),
        .i_queue_AWLEN(queue_o_awlen),
        .i_queue_AWSIZE(queue_o_awsize),
        .i_queue_AWBURST(queue_o_awburst),

        .i_WVALID(M_AXI_GP0_WVALID),
        .i_WREADY(M_AXI_GP0_WREADY),
        .i_WDATA(M_AXI_GP0_WDATA),
        .i_WSTRB(M_AXI_GP0_WSTRB),
        .i_WLAST(M_AXI_GP0_WLAST),

        .aw_scheduler_fire(aw_scheduler_fire),
        .aw_scheduler_ready(order_aw_scheduler_ready),
        .i_AWID(sched_o_awid),
        .i_AWLEN(sched_o_awlen),
        .i_AWSIZE(sched_o_awsize),
        .i_AWBURST(sched_o_awburst),

        .o_WDATA(order_o_wdata),
        .o_WSTRB(order_o_wstrb),
        .o_WLAST(order_o_wlast),
        .o_WVALID(order_o_wvalid),
        .o_WREADY(order_o_wready)
    );

    axi_ooo_write_b_router u_write_b_router (
        .i_AWID(sched_o_awid),
        .i_WSTRB(order_o_wstrb),
        .i_WLAST(order_o_wlast),
        .i_WVALID(order_o_wvalid && S_AXI_HP0_WREADY),
        .i_WREADY(b_wready),

        .i_BID(S_AXI_HP0_BID),
        .i_BRESP(S_AXI_HP0_BRESP),
        .i_BVALID(S_AXI_HP0_BVALID),
        .i_BREADY(S_AXI_HP0_BREADY),

        .aw_scheduler_fire(aw_scheduler_fire),
        .aw_scheduler_ready(b_aw_scheduler_ready),

        .ACLK(ACLK),
        .ARESETn(ARESETn),

        .o_BID(M_AXI_GP0_BID),
        .o_BRESP(M_AXI_GP0_BRESP),
        .o_BVALID(M_AXI_GP0_BVALID),
        .o_BREADY(M_AXI_GP0_BREADY)
    );

endmodule

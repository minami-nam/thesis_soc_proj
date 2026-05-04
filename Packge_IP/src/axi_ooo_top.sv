
`include "axi_include_top.vh"
import axi_pkg::*;

module axi_ooo_controller #(
    parameter int FIFO_NUM = 8,
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int ID_WIDTH = 4,
    parameter int LEN_WIDTH = 8,
    parameter int NUM_READ_IDTABLE = 4,
    parameter int NUM_READ_SCHEDULER = 4,
    parameter int NUM_READ_REORDER = 4,
    parameter int NUM_BANK = 4,
    parameter int NUM_WRITE_AWQUEUE = 4,
    parameter int NUM_WRITE_SCHEDULER = 4,
    parameter int NUM_WRITE_ORDER_QUEUE_AW = 4,
    parameter int READ_BANK_BIT_START = 6,
    parameter int READ_REORDER_KEEP_OUT_TIMES = 8,
    parameter int WRITE_KEEP_MAX_LENGTH = 8,
    parameter int WRITE_MAX_BURST_BEATS = 8,
    parameter int WRITE_SEQ_WIDTH = 16
)
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
    // Synthesis + Implementation 목적 BUFG Instance.
    wire filtered_clk = ACLK;

//    BUFG filter_clk (
//        .I(ACLK),
//        .O(filtered_clk)
//    );

    axi_read_ooo #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ID_WIDTH(ID_WIDTH),
        .LEN_WIDTH(LEN_WIDTH),
        .NUM_READ_IDTABLE(NUM_READ_IDTABLE),
        .NUM_READ_SCHEDULER(NUM_READ_SCHEDULER),
        .NUM_READ_REORDER(NUM_READ_REORDER),
        .NUM_BANK(NUM_BANK),
        .READ_BANK_BIT_START(READ_BANK_BIT_START),
        .READ_REORDER_KEEP_OUT_TIMES(READ_REORDER_KEEP_OUT_TIMES)
    ) u_axi_read_ooo (
        .ACLK(filtered_clk),
        .ARESETn(ARESETn),

        .M_AXI_GP0_ARID(M_AXI_GP0_ARID),
        .M_AXI_GP0_ARADDR(M_AXI_GP0_ARADDR),
        .M_AXI_GP0_ARLEN(M_AXI_GP0_ARLEN),
        .M_AXI_GP0_ARSIZE(M_AXI_GP0_ARSIZE),
        .M_AXI_GP0_ARBURST(M_AXI_GP0_ARBURST),
        .M_AXI_GP0_ARVALID(M_AXI_GP0_ARVALID),
        .M_AXI_GP0_ARREADY(M_AXI_GP0_ARREADY),

        .M_AXI_GP0_RID(M_AXI_GP0_RID),
        .M_AXI_GP0_RDATA(M_AXI_GP0_RDATA),
        .M_AXI_GP0_RRESP(M_AXI_GP0_RRESP),
        .M_AXI_GP0_RLAST(M_AXI_GP0_RLAST),
        .M_AXI_GP0_RVALID(M_AXI_GP0_RVALID),
        .M_AXI_GP0_RREADY(M_AXI_GP0_RREADY),

        .S_AXI_HP0_ARID(S_AXI_HP0_ARID),
        .S_AXI_HP0_ARADDR(S_AXI_HP0_ARADDR),
        .S_AXI_HP0_ARLEN(S_AXI_HP0_ARLEN),
        .S_AXI_HP0_ARSIZE(S_AXI_HP0_ARSIZE),
        .S_AXI_HP0_ARBURST(S_AXI_HP0_ARBURST),
        .S_AXI_HP0_ARVALID(S_AXI_HP0_ARVALID),
        .S_AXI_HP0_ARREADY(S_AXI_HP0_ARREADY),

        .S_AXI_HP0_RID(S_AXI_HP0_RID),
        .S_AXI_HP0_RDATA(S_AXI_HP0_RDATA),
        .S_AXI_HP0_RRESP(S_AXI_HP0_RRESP),
        .S_AXI_HP0_RLAST(S_AXI_HP0_RLAST),
        .S_AXI_HP0_RVALID(S_AXI_HP0_RVALID),
        .S_AXI_HP0_RREADY(S_AXI_HP0_RREADY)
    );

    axi_write_ooo #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ID_WIDTH(ID_WIDTH),
        .LEN_WIDTH(LEN_WIDTH),
        .NUM_WRITE_AWQUEUE(NUM_WRITE_AWQUEUE),
        .NUM_WRITE_SCHEDULER(NUM_WRITE_SCHEDULER),
        .NUM_WRITE_ORDER_QUEUE_AW(NUM_WRITE_ORDER_QUEUE_AW),
        .WRITE_KEEP_MAX_LENGTH(WRITE_KEEP_MAX_LENGTH),
        .WRITE_MAX_BURST_BEATS(WRITE_MAX_BURST_BEATS),
        .WRITE_SEQ_WIDTH(WRITE_SEQ_WIDTH)
    ) u_axi_write_ooo (
        .ACLK(filtered_clk),
        .ARESETn(ARESETn),

        .M_AXI_GP0_AWID(M_AXI_GP0_AWID),
        .M_AXI_GP0_AWADDR(M_AXI_GP0_AWADDR),
        .M_AXI_GP0_AWLEN(M_AXI_GP0_AWLEN),
        .M_AXI_GP0_AWSIZE(M_AXI_GP0_AWSIZE),
        .M_AXI_GP0_AWBURST(M_AXI_GP0_AWBURST),
        .M_AXI_GP0_AWVALID(M_AXI_GP0_AWVALID),
        .M_AXI_GP0_AWREADY(M_AXI_GP0_AWREADY),

        .M_AXI_GP0_WDATA(M_AXI_GP0_WDATA),
        .M_AXI_GP0_WSTRB(M_AXI_GP0_WSTRB),
        .M_AXI_GP0_WLAST(M_AXI_GP0_WLAST),
        .M_AXI_GP0_WVALID(M_AXI_GP0_WVALID),
        .M_AXI_GP0_WREADY(M_AXI_GP0_WREADY),

        .M_AXI_GP0_BID(M_AXI_GP0_BID),
        .M_AXI_GP0_BRESP(M_AXI_GP0_BRESP),
        .M_AXI_GP0_BVALID(M_AXI_GP0_BVALID),
        .M_AXI_GP0_BREADY(M_AXI_GP0_BREADY),

        .S_AXI_HP0_AWID(S_AXI_HP0_AWID),
        .S_AXI_HP0_AWADDR(S_AXI_HP0_AWADDR),
        .S_AXI_HP0_AWLEN(S_AXI_HP0_AWLEN),
        .S_AXI_HP0_AWSIZE(S_AXI_HP0_AWSIZE),
        .S_AXI_HP0_AWBURST(S_AXI_HP0_AWBURST),
        .S_AXI_HP0_AWVALID(S_AXI_HP0_AWVALID),
        .S_AXI_HP0_AWREADY(S_AXI_HP0_AWREADY),

        .S_AXI_HP0_WDATA(S_AXI_HP0_WDATA),
        .S_AXI_HP0_WSTRB(S_AXI_HP0_WSTRB),
        .S_AXI_HP0_WLAST(S_AXI_HP0_WLAST),
        .S_AXI_HP0_WVALID(S_AXI_HP0_WVALID),
        .S_AXI_HP0_WREADY(S_AXI_HP0_WREADY),

        .S_AXI_HP0_BID(S_AXI_HP0_BID),
        .S_AXI_HP0_BRESP(S_AXI_HP0_BRESP),
        .S_AXI_HP0_BVALID(S_AXI_HP0_BVALID),
        .S_AXI_HP0_BREADY(S_AXI_HP0_BREADY)
    );

endmodule

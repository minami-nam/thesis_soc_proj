
`include "axi_include_top.vh"
import axi_pkg::*;

module axi_ooo_controller 
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

    

endmodule
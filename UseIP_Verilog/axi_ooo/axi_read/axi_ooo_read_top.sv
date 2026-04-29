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

    // Table 관련 
    
    
    `ifdef SIM

    `endif

endmodule
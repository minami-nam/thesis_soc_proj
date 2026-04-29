`import "axi_include_top.vh"

package axi_pkg;
    // Common
    localparam OFF = 1'b0;
    localparam ON = 1'b1;
    localparam int FIFO_NUM = 16;
    localparam ADDR_WIDTH = 32;
    localparam DATA_WIDTH = 32;
    localparam ID_WIDTH   = 4;
    localparam LEN_WIDTH  = 8;

    // For OoO Only

    
    `ifdef OUT_ORDER
        // Read
        localparam int NUM_READ_IDTABLE = 2 ** (ID_WIDTH);
        localparam int NUM_READ_CACHE = 2 ** (LEN_WIDTH);
        localparam int NUM_READ_BUFFERZSIZE = 16;

        // Common
        localparam int NUM_BANK = 8; 
    `endif
    
    // Testbench
    `ifdef USE_SYSTEMVERILOG_FEATURES
        typedef struct packed {
            //==================================================
            // From Zynq PS M_AXI_GP0
            // Controller receives requests from PS
            //==================================================

            // AR Channel
            logic  [ID_WIDTH-1:0]     M_AXI_GP0_ARID;
            logic  [ADDR_WIDTH-1:0]   M_AXI_GP0_ARADDR;
            logic  [LEN_WIDTH-1:0]    M_AXI_GP0_ARLEN;
            logic  [2:0]              M_AXI_GP0_ARSIZE;
            logic  [1:0]              M_AXI_GP0_ARBURST;
            logic                     M_AXI_GP0_ARVALID;
            logic                     M_AXI_GP0_ARREADY;
            // R Channel
            logic  [ID_WIDTH-1:0]     M_AXI_GP0_RID;
            logic  [DATA_WIDTH-1:0]   M_AXI_GP0_RDATA;
            logic  [1:0]              M_AXI_GP0_RRESP;
            logic                     M_AXI_GP0_RLAST;
            logic                     M_AXI_GP0_RVALID;
            logic                     M_AXI_GP0_RREADY;

            //==================================================
            // To Zynq PS S_AXI_HP0
            // Controller issues requests to PS memory subsystem
            //==================================================

            // AR Channel
            logic  [ID_WIDTH-1:0]     S_AXI_HP0_ARID;
            logic  [ADDR_WIDTH-1:0]   S_AXI_HP0_ARADDR;
            logic  [LEN_WIDTH-1:0]    S_AXI_HP0_ARLEN;
            logic  [2:0]              S_AXI_HP0_ARSIZE;
            logic  [1:0]              S_AXI_HP0_ARBURST;
            logic                     S_AXI_HP0_ARVALID;
            logic                     S_AXI_HP0_ARREADY;

            // R Channel
            logic  [ID_WIDTH-1:0]     S_AXI_HP0_RID;
            logic  [DATA_WIDTH-1:0]   S_AXI_HP0_RDATA;
            logic  [1:0]              S_AXI_HP0_RRESP;
            logic                     S_AXI_HP0_RLAST;
            logic                     S_AXI_HP0_RVALID;
            logic                     S_AXI_HP0_RREADY;
        } axi_readports;

        // Burst Type 관련
        typedef enum logic [1:0] { 
            FIXED = 2'b00,
            INCR = 2'b01,
            WRAP = 2'b10,
            RESERVED = 2'b11
        } burst_type;

        // 이후 여기에 TB에서 사용할 것들 추가할 것.

    `endif

endpackage
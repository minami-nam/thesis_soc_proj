module axi_write_master #(
    parameter ADDR_W = 32,
    parameter DATA_W = 32,
    parameter ID_W = 4
)(
    input              ACLK,
    input              ARESETn,

    //========================
    // Write Address Channel
    //========================
    output reg [(ADDR_W-1):0]  AWADDR,    // write address
    output reg [7:0]   AWLEN,     // burst length = beats-1
    output reg [2:0]   AWSIZE,    // bytes per beat = 2^AWSIZE
    output reg [1:0]   AWBURST,   // FIXED/INCR/WRAP
    output reg [(ID_W-1):0]   AWID,
    output reg         AWLOCK,    // AXI4: 1-bit
    output reg [3:0]   AWCACHE,   // AXI4: 4-bit
    output reg [2:0]   AWPROT,    // AXI4: 3-bit
    output reg         AWVALID,
    input              AWREADY,

    //========================
    // Write Data Channel
    //========================
    output reg [(ADDR_W-1):0]  WDATA,
    output reg [3:0]   WSTRB,     
    output reg         WLAST,
    output reg         WVALID,
    input              WREADY,

    //========================
    // Write Response Channel
    //========================
    input      [(ID_W-1):0]   BID,
    input      [1:0]   BRESP,
    input              BVALID,
    output reg         BREADY

);
    localparam STRB_W = DATA_W / 8;

    // state 관련 정의
    localparam IDLE = 1;
    localparam GOT_AWREADY = 2;
    localparam RECEVING = 3;
    
endmodule
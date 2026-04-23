`timescale 1ps/1ps

module tb;

    //==================================================
    // Global
    //==================================================
    reg         ACLK;
    reg         ARESETn;

    //==================================================
    // Read Address Channel (AR)
    //==================================================
    wire [31:0] ARADDR;     // Master output
    wire [7:0]  ARLEN;      // Master output
    wire [2:0]  ARSIZE;     // Master output
    wire [1:0]  ARBURST;    // Master output
    wire [3:0]  ARID;       // Master output
    wire        ARVALID;    // Master output
    wire        ARREADY;    // Slave output

    //==================================================
    // Read Data Channel (R)
    //==================================================
    wire [31:0] RDATA;      // Slave output
    wire [3:0]  RID;        // Slave output
    wire [1:0]  RRESP;      // Slave output
    wire        RLAST;      // Slave output
    wire        RVALID;     // Slave output
    wire        RREADY;     // Master output

    //==================================================
    // Write Address Channel (AW)
    //==================================================
    wire [31:0] AWADDR;     // Master output
    wire [7:0]  AWLEN;      // Master output
    wire [2:0]  AWSIZE;     // Master output
    wire [1:0]  AWBURST;    // Master output
    wire [3:0]  AWID;       // Master output
    wire        AWLOCK;     // Master output
    wire [3:0]  AWCACHE;    // Master output
    wire [2:0]  AWPROT;     // Master output
    wire        AWVALID;    // Master output
    wire        AWREADY;    // Slave output

    //==================================================
    // Write Data Channel (W)
    //==================================================
    wire [31:0] WDATA;      // Master output
    wire [3:0]  WSTRB;      // Master output
    wire        WLAST;      // Master output
    wire        WVALID;     // Master output
    wire        WREADY;     // Slave output

    //==================================================
    // Write Response Channel (B)
    //==================================================
    wire [3:0]  BID;        // Slave output
    wire [1:0]  BRESP;      // Slave output
    wire        BVALID;     // Slave output
    wire        BREADY;     // Master output

    //==================================================
    // Master instantiation
    //==================================================
    axi_read_master u_master (
        .ACLK    (ACLK),
        .ARESETn (ARESETn),

        // Read
        .ARADDR  (ARADDR),
        .ARLEN   (ARLEN),
        .ARSIZE  (ARSIZE),
        .ARBURST (ARBURST),
        .ARID    (ARID),
        .ARVALID (ARVALID),
        .ARREADY (ARREADY),

        .RDATA   (RDATA),
        .RID     (RID),
        .RRESP   (RRESP),
        .RLAST   (RLAST),
        .RVALID  (RVALID),
        .RREADY  (RREADY),

        // Write
        .AWADDR  (AWADDR),
        .AWLEN   (AWLEN),
        .AWSIZE  (AWSIZE),
        .AWBURST (AWBURST),
        .AWID    (AWID),
        .AWLOCK  (AWLOCK),
        .AWCACHE (AWCACHE),
        .AWPROT  (AWPROT),
        .AWVALID (AWVALID),
        .AWREADY (AWREADY),

        .WDATA   (WDATA),
        .WSTRB   (WSTRB),
        .WLAST   (WLAST),
        .WVALID  (WVALID),
        .WREADY  (WREADY),

        .BID     (BID),
        .BRESP   (BRESP),
        .BVALID  (BVALID),
        .BREADY  (BREADY)
    );

    //==================================================
    // Slave instantiation
    //==================================================
    axi_read_slave u_slave (
        .ACLK    (ACLK),
        .ARESETn (ARESETn),

        // Read
        .ARADDR  (ARADDR),
        .ARID    (ARID),
        .ARLEN   (ARLEN),
        .ARSIZE  (ARSIZE),
        .ARBURST (ARBURST),
        .ARVALID (ARVALID),
        .ARREADY (ARREADY),

        .RDATA   (RDATA),
        .RID     (RID),
        .RRESP   (RRESP),
        .RLAST   (RLAST),
        .RVALID  (RVALID),
        .RREADY  (RREADY),

        // Write
        .AWADDR  (AWADDR),
        .AWLEN   (AWLEN),
        .AWSIZE  (AWSIZE),
        .AWBURST (AWBURST),
        .AWID    (AWID),
        .AWLOCK  (AWLOCK),
        .AWCACHE (AWCACHE),
        .AWPROT  (AWPROT),
        .AWVALID (AWVALID),
        .AWREADY (AWREADY),

        .WDATA   (WDATA),
        .WSTRB   (WSTRB),
        .WLAST   (WLAST),
        .WVALID  (WVALID),
        .WREADY  (WREADY),

        .BID     (BID),
        .BRESP   (BRESP),
        .BVALID  (BVALID),
        .BREADY  (BREADY)
    );

    //==================================================
    // Clock
    //==================================================
    initial ACLK = 0;
    always #5 ACLK = ~ACLK;

    //==================================================
    // Reset / Simulation end
    //==================================================
    initial begin
        ARESETn = 0;
        #20;
        ARESETn = 1;

        #10000;
        $display("Simulation Done!");
        $finish;
    end

    //==================================================
    // Read-side error check
    //==================================================
    always @(posedge ACLK) begin
        if (RVALID && RREADY) begin
            if ((RRESP == 2'b10) || (RRESP == 2'b11))
                $display("[%0t] RRESP Error DETECTED : RRESP=%b", $time, RRESP);

            if (RID != ARID)
                $display("[%0t] ERROR : Read ID Mismatch! expected=%0d, got=%0d",
                         $time, ARID, RID);
        end
    end

    //==================================================
    // Write-side error check
    //==================================================
    always @(posedge ACLK) begin
        if (BVALID && BREADY) begin
            if ((BRESP == 2'b10) || (BRESP == 2'b11))
                $display("[%0t] BRESP Error DETECTED : BRESP=%b", $time, BRESP);

            if (BID != AWID)
                $display("[%0t] ERROR : Write ID Mismatch! expected=%0d, got=%0d",
                         $time, AWID, BID);
        end
    end

    //==================================================
    // Cycle counter
    //==================================================
    integer cycle_cnt;
    integer issue_cycle_r [0:15];
    integer issue_cycle_w [0:15];
    integer i;

    initial begin
        cycle_cnt = 0;
        for (i = 0; i < 16; i = i + 1) begin
            issue_cycle_r[i] = 0;
            issue_cycle_w[i] = 0;
        end
    end

    always @(posedge ACLK) begin
        if (!ARESETn)
            cycle_cnt <= 0;
        else
            cycle_cnt <= cycle_cnt + 1;
    end

    //==================================================
    // Read request log
    //==================================================
    always @(posedge ACLK) begin
        if (ARVALID && ARREADY) begin
            issue_cycle_r[ARID] = cycle_cnt;
            $display("[%0t] [AR] ARID=%0d ARADDR=0x%08h ARLEN=%0d logged at cycle %0d",
                     $time, ARID, ARADDR, ARLEN, cycle_cnt);
        end
    end

    //==================================================
    // Read latency
    //==================================================
    always @(posedge ACLK) begin
        if (RVALID && RREADY && RLAST) begin
            $display("[%0t] [RLAT] RID=%0d | Latency=%0d cycles",
                     $time, RID, cycle_cnt - issue_cycle_r[RID]);
        end
    end

    //==================================================
    // Write request log
    //==================================================
    always @(posedge ACLK) begin
        if (AWVALID && AWREADY) begin
            issue_cycle_w[AWID] = cycle_cnt;
            $display("[%0t] [AW] AWID=%0d AWADDR=0x%08h AWLEN=%0d logged at cycle %0d",
                     $time, AWID, AWADDR, AWLEN, cycle_cnt);
        end
    end

    //==================================================
    // Write data beat log
    //==================================================
    always @(posedge ACLK) begin
        if (WVALID && WREADY) begin
            $display("[%0t] [W] WDATA=0x%08h WSTRB=0x%0h WLAST=%0b",
                     $time, WDATA, WSTRB, WLAST);
        end
    end

    //==================================================
    // Write latency
    //==================================================
    always @(posedge ACLK) begin
        if (BVALID && BREADY) begin
            $display("[%0t] [WLAT] BID=%0d | Latency=%0d cycles | BRESP=%b",
                     $time, BID, cycle_cnt - issue_cycle_w[BID], BRESP);
        end
    end

endmodule
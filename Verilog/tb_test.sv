`timescale 1ps/1ps

module tb;

    // Global
    reg         ACLK;
    reg         ARESETn;

    // AR Channel
    wire [31:0] ARADDR;     // Master output
    wire [7:0]  ARLEN;      // Master output
    wire [2:0]  ARSIZE;     // Master output
    wire [1:0]  ARBURST;    // Master output
    wire [3:0]  ARID;       // Master output
    wire        ARVALID;    // Master output
    wire        ARREADY;    // Slave output

    // R Channel
    wire [31:0] RDATA;      // Slave output
    wire [3:0]  RID;        // Slave output
    wire [1:0]  RRESP;      // Slave output
    wire        RLAST;      // Slave output
    wire        RVALID;     // Slave output
    wire        RREADY;     // Master output

    // Master instantiation
    axi_read_master u_master (
        .ACLK    (ACLK),
        .ARESETn (ARESETn),
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
        .RREADY  (RREADY)
    );

    // Slave instantiation
    axi_read_slave u_slave (
        .ACLK    (ACLK),
        .ARESETn (ARESETn),
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
        .RREADY  (RREADY)
    );

    // Clock
    initial ACLK = 0;
    always #5 ACLK = ~ACLK;

    // Reset
    initial begin
        ARESETn = 0;
        #20;
        ARESETn = 1;

        #10000;
        $display("Simulation Done!");
        $finish;
    end

    // Error Disp
    always @(posedge ACLK) begin
        if ((RRESP==2'b10) | (RRESP==2'b11)) begin
            $display("RRESP Error DETECTED");
        end

        if (RVALID && RREADY) begin
            if (RID!=ARID) $display("ERROR : ID Mismatch! , expected %0d, but got %0d", ARID, RID);
        end
    end 

    // cycle counter 선언
    integer cycle_cnt;
    integer issue_cycle [16];

    // [FIXED] 초기화 추가
    initial begin
        cycle_cnt = 0;
        for (int i = 0; i < 16; i++)
            issue_cycle[i] = 0;
    end

    always @(posedge ACLK) begin
        cycle_cnt <= cycle_cnt + 1;
    end

    // AR handshake 시 cycle 기록
    always @(posedge ACLK) begin
        if (ARVALID && ARREADY) begin
            issue_cycle[ARID] = cycle_cnt;
            $display("[AR] ARID=%0d logged at cycle %0d", ARID, cycle_cnt);
        end
    end

    // Latency 출력
    always @(posedge ACLK) begin
        if (RVALID && RREADY && RLAST) begin
            $display("[LAT] ID=%0d | Latency=%0d cycles",
                    RID, cycle_cnt - issue_cycle[RID]);
        end
    end

endmodule
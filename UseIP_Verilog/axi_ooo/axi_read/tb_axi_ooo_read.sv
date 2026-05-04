`timescale 1ns/1ps
`ifndef OPTION
    `define OPTION
`endif
`ifndef BANK_AWARE
    `define BANK_AWARE
`endif
`include "axi_include_top.vh"
import axi_pkg::*;

module tb_axi_ooo_read;
    localparam CLK_PERIOD = 10;
    localparam int NUM_REQ = 8;

    logic ACLK;
    logic ARESETn;

    logic [ID_WIDTH-1:0]   S_AXI_ARID;
    logic [ADDR_WIDTH-1:0] S_AXI_ARADDR;
    logic [LEN_WIDTH-1:0]  S_AXI_ARLEN;
    logic [2:0]            S_AXI_ARSIZE;
    logic [1:0]            S_AXI_ARBURST;
    logic                  S_AXI_ARVALID;
    wire                   S_AXI_ARREADY;

    wire [ID_WIDTH-1:0]    S_AXI_RID;
    wire [DATA_WIDTH-1:0]  S_AXI_RDATA;
    wire [1:0]             S_AXI_RRESP;
    wire                   S_AXI_RLAST;
    wire                   S_AXI_RVALID;
    logic                  S_AXI_RREADY;

    wire [ID_WIDTH-1:0]    M_AXI_ARID;
    wire [ADDR_WIDTH-1:0]  M_AXI_ARADDR;
    wire [LEN_WIDTH-1:0]   M_AXI_ARLEN;
    wire [2:0]             M_AXI_ARSIZE;
    wire [1:0]             M_AXI_ARBURST;
    wire                   M_AXI_ARVALID;
    logic                  M_AXI_ARREADY;

    logic [ID_WIDTH-1:0]   M_AXI_RID;
    logic [DATA_WIDTH-1:0] M_AXI_RDATA;
    logic [1:0]            M_AXI_RRESP;
    logic                  M_AXI_RLAST;
    logic                  M_AXI_RVALID;
    wire                   M_AXI_RREADY;

    typedef struct packed {
        logic [ID_WIDTH-1:0]   id;
        logic [ADDR_WIDTH-1:0] addr;
        logic [LEN_WIDTH-1:0]  len;
        logic [2:0]            size;
        logic [1:0]            burst;
    } ar_req_t;

    ar_req_t issued_req_q[$];
    ar_req_t hp_req_q[$];
    int unsigned expected_beats;
    int unsigned observed_beats;
    int unsigned observed_reqs;
    int unsigned ar_timeout_cnt;
    int unsigned r_timeout_cnt;
    int unsigned cycle_cnt;

    axi_read_ooo dut (
        .ACLK(ACLK),
        .ARESETn(ARESETn),

        .S_AXI_ARID(S_AXI_ARID),
        .S_AXI_ARADDR(S_AXI_ARADDR),
        .S_AXI_ARLEN(S_AXI_ARLEN),
        .S_AXI_ARSIZE(S_AXI_ARSIZE),
        .S_AXI_ARBURST(S_AXI_ARBURST),
        .S_AXI_ARVALID(S_AXI_ARVALID),
        .S_AXI_ARREADY(S_AXI_ARREADY),

        .S_AXI_RID(S_AXI_RID),
        .S_AXI_RDATA(S_AXI_RDATA),
        .S_AXI_RRESP(S_AXI_RRESP),
        .S_AXI_RLAST(S_AXI_RLAST),
        .S_AXI_RVALID(S_AXI_RVALID),
        .S_AXI_RREADY(S_AXI_RREADY),

        .M_AXI_ARID(M_AXI_ARID),
        .M_AXI_ARADDR(M_AXI_ARADDR),
        .M_AXI_ARLEN(M_AXI_ARLEN),
        .M_AXI_ARSIZE(M_AXI_ARSIZE),
        .M_AXI_ARBURST(M_AXI_ARBURST),
        .M_AXI_ARVALID(M_AXI_ARVALID),
        .M_AXI_ARREADY(M_AXI_ARREADY),

        .M_AXI_RID(M_AXI_RID),
        .M_AXI_RDATA(M_AXI_RDATA),
        .M_AXI_RRESP(M_AXI_RRESP),
        .M_AXI_RLAST(M_AXI_RLAST),
        .M_AXI_RVALID(M_AXI_RVALID),
        .M_AXI_RREADY(M_AXI_RREADY)
    );

    initial begin
        ACLK = 1'b0;
        forever #(CLK_PERIOD/2) ACLK = ~ACLK;
    end
    

    task automatic init_signals;
        begin
            ARESETn = 1'b0;

            S_AXI_ARID = '0;
            S_AXI_ARADDR = '0;
            S_AXI_ARLEN = '0;
            S_AXI_ARSIZE = 3'b010;
            S_AXI_ARBURST = 2'b01;
            S_AXI_ARVALID = 1'b0;
            S_AXI_RREADY = 1'b1;

            M_AXI_ARREADY = 1'b1;
            M_AXI_RID = '0;
            M_AXI_RDATA = '0;
            M_AXI_RRESP = 2'b00;
            M_AXI_RLAST = 1'b0;
            M_AXI_RVALID = 1'b0;

            expected_beats = 0;
            observed_beats = 0;
            observed_reqs = 0;
            ar_timeout_cnt = 0;
            r_timeout_cnt = 0;
            cycle_cnt = 0;
        end
    endtask

    always @(posedge ACLK) begin
        if (!ARESETn) cycle_cnt <= 0;
        else cycle_cnt <= cycle_cnt + 1;
    end

    task automatic apply_reset;
        begin
            repeat (5) @(posedge ACLK);
            ARESETn <= 1'b1;
            repeat (2) @(posedge ACLK);
        end
    endtask

    task automatic send_ar(
        input logic [ID_WIDTH-1:0]   id,
        input logic [ADDR_WIDTH-1:0] addr,
        input logic [LEN_WIDTH-1:0]  len
    );
        ar_req_t req;
        begin
            req.id = id;
            req.addr = addr;
            req.len = len;
            req.size = 3'b010;
            req.burst = 2'b01;

            @(posedge ACLK);
            S_AXI_ARID <= req.id;
            S_AXI_ARADDR <= req.addr;
            S_AXI_ARLEN <= req.len;
            S_AXI_ARSIZE <= req.size;
            S_AXI_ARBURST <= req.burst;
            S_AXI_ARVALID <= 1'b1;

            while (!S_AXI_ARREADY) @(posedge ACLK);
            @(posedge ACLK);
            S_AXI_ARVALID <= 1'b0;
            issued_req_q.push_back(req);
            expected_beats += len + 1;
        end
    endtask

    task automatic send_r_burst(input ar_req_t req);
        int unsigned beat;
        begin
            for (beat=0; beat<=req.len; beat++) begin
                @(posedge ACLK);
                M_AXI_RID <= req.id;
                M_AXI_RDATA <= {req.id, req.addr[DATA_WIDTH-ID_WIDTH-1:0]} + beat;
                M_AXI_RRESP <= 2'b00;
                M_AXI_RLAST <= (beat == req.len);
                M_AXI_RVALID <= 1'b1;

                while (!M_AXI_RREADY) @(posedge ACLK);
            end

            @(posedge ACLK);
            M_AXI_RVALID <= 1'b0;
            M_AXI_RLAST <= 1'b0;
            M_AXI_RDATA <= '0;
            M_AXI_RID <= '0;
        end
    endtask

    initial begin : ar_slave_model
        ar_req_t req;
        forever begin
            @(posedge ACLK);
            if (!ARESETn) begin
                hp_req_q.delete();
                M_AXI_ARREADY <= 1'b1;
            end
            else begin
                M_AXI_ARREADY <= (cycle_cnt[3:2] != 2'b10);

                if (M_AXI_ARVALID && M_AXI_ARREADY) begin
                    req.id = M_AXI_ARID;
                    req.addr = M_AXI_ARADDR;
                    req.len = M_AXI_ARLEN;
                    req.size = M_AXI_ARSIZE;
                    req.burst = M_AXI_ARBURST;
                    hp_req_q.push_back(req);
                    observed_reqs++;
                end
            end
        end
    end

    initial begin : r_slave_model
        ar_req_t req;
        wait (ARESETn);
        forever begin
            @(posedge ACLK);
            if (hp_req_q.size() != 0 && !M_AXI_RVALID) begin
                req = hp_req_q.pop_back();
                repeat (2) @(posedge ACLK);
                send_r_burst(req);
            end
        end
    end

    always @(posedge ACLK) begin
        if (ARESETn && S_AXI_RVALID && S_AXI_RREADY) begin
            observed_beats++;

            if (S_AXI_RRESP != 2'b00) begin
                $error("Unexpected RRESP: %0b at time %0t", S_AXI_RRESP, $time);
            end
        end
    end

    initial begin : main_test
        init_signals();

        `ifdef DISPLAY_ALL_SIGNALS
            $dumpfile("tb_axi_ooo_read.vcd");
            $dumpvars(0, tb_axi_ooo_read);
        `endif

        apply_reset();

        fork
            begin
                send_ar(4'h1, 32'h0000_1000, 8'd1);
                send_ar(4'h2, 32'h0000_2000, 8'd2);
                send_ar(4'h3, 32'h0000_3000, 8'd0);
                send_ar(4'h1, 32'h0000_1040, 8'd3);
                send_ar(4'h4, 32'h0000_4000, 8'd1);
                send_ar(4'h5, 32'h0000_5000, 8'd0);
                send_ar(4'h2, 32'h0000_2040, 8'd1);
                send_ar(4'h6, 32'h0000_6000, 8'd2);
            end

            begin
                forever begin
                    @(posedge ACLK);
                    if (ARESETn) begin
                        S_AXI_RREADY <= (cycle_cnt[4:2] != 3'b101);
                    end
                end
            end
        join_any

        while (observed_reqs < NUM_REQ) begin
            @(posedge ACLK);
            ar_timeout_cnt++;
            if (ar_timeout_cnt > 500) begin
                $fatal(1, "Timeout waiting for M_AXI AR requests. observed=%0d expected=%0d", observed_reqs, NUM_REQ);
            end
        end

        while (observed_beats < expected_beats) begin
            @(posedge ACLK);
            r_timeout_cnt++;
            if (r_timeout_cnt > 1000) begin
                $fatal(1, "Timeout waiting for S_AXI R beats. observed=%0d expected=%0d", observed_beats, expected_beats);
            end
        end

        repeat (10) @(posedge ACLK);
        $display("PASS: axi_read_ooo test completed. requests=%0d beats=%0d", observed_reqs, observed_beats);
        $finish;
    end

endmodule

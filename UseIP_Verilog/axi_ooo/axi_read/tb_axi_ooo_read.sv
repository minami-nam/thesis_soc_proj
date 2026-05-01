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

    logic [ID_WIDTH-1:0]   M_AXI_GP0_ARID;
    logic [ADDR_WIDTH-1:0] M_AXI_GP0_ARADDR;
    logic [LEN_WIDTH-1:0]  M_AXI_GP0_ARLEN;
    logic [2:0]            M_AXI_GP0_ARSIZE;
    logic [1:0]            M_AXI_GP0_ARBURST;
    logic                  M_AXI_GP0_ARVALID;
    wire                   M_AXI_GP0_ARREADY;

    wire [ID_WIDTH-1:0]    M_AXI_GP0_RID;
    wire [DATA_WIDTH-1:0]  M_AXI_GP0_RDATA;
    wire [1:0]             M_AXI_GP0_RRESP;
    wire                   M_AXI_GP0_RLAST;
    wire                   M_AXI_GP0_RVALID;
    logic                  M_AXI_GP0_RREADY;

    wire [ID_WIDTH-1:0]    S_AXI_HP0_ARID;
    wire [ADDR_WIDTH-1:0]  S_AXI_HP0_ARADDR;
    wire [LEN_WIDTH-1:0]   S_AXI_HP0_ARLEN;
    wire [2:0]             S_AXI_HP0_ARSIZE;
    wire [1:0]             S_AXI_HP0_ARBURST;
    wire                   S_AXI_HP0_ARVALID;
    logic                  S_AXI_HP0_ARREADY;

    logic [ID_WIDTH-1:0]   S_AXI_HP0_RID;
    logic [DATA_WIDTH-1:0] S_AXI_HP0_RDATA;
    logic [1:0]            S_AXI_HP0_RRESP;
    logic                  S_AXI_HP0_RLAST;
    logic                  S_AXI_HP0_RVALID;
    wire                   S_AXI_HP0_RREADY;

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

    initial begin
        ACLK = 1'b0;
        forever #(CLK_PERIOD/2) ACLK = ~ACLK;
    end
    

    task automatic init_signals;
        begin
            ARESETn = 1'b0;

            M_AXI_GP0_ARID = '0;
            M_AXI_GP0_ARADDR = '0;
            M_AXI_GP0_ARLEN = '0;
            M_AXI_GP0_ARSIZE = 3'b010;
            M_AXI_GP0_ARBURST = 2'b01;
            M_AXI_GP0_ARVALID = 1'b0;
            M_AXI_GP0_RREADY = 1'b1;

            S_AXI_HP0_ARREADY = 1'b1;
            S_AXI_HP0_RID = '0;
            S_AXI_HP0_RDATA = '0;
            S_AXI_HP0_RRESP = 2'b00;
            S_AXI_HP0_RLAST = 1'b0;
            S_AXI_HP0_RVALID = 1'b0;

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
            M_AXI_GP0_ARID <= req.id;
            M_AXI_GP0_ARADDR <= req.addr;
            M_AXI_GP0_ARLEN <= req.len;
            M_AXI_GP0_ARSIZE <= req.size;
            M_AXI_GP0_ARBURST <= req.burst;
            M_AXI_GP0_ARVALID <= 1'b1;

            while (!M_AXI_GP0_ARREADY) @(posedge ACLK);
            @(posedge ACLK);
            M_AXI_GP0_ARVALID <= 1'b0;
            issued_req_q.push_back(req);
            expected_beats += len + 1;
        end
    endtask

    task automatic send_r_burst(input ar_req_t req);
        int unsigned beat;
        begin
            for (beat=0; beat<=req.len; beat++) begin
                @(posedge ACLK);
                S_AXI_HP0_RID <= req.id;
                S_AXI_HP0_RDATA <= {req.id, req.addr[DATA_WIDTH-ID_WIDTH-1:0]} + beat;
                S_AXI_HP0_RRESP <= 2'b00;
                S_AXI_HP0_RLAST <= (beat == req.len);
                S_AXI_HP0_RVALID <= 1'b1;

                while (!S_AXI_HP0_RREADY) @(posedge ACLK);
            end

            @(posedge ACLK);
            S_AXI_HP0_RVALID <= 1'b0;
            S_AXI_HP0_RLAST <= 1'b0;
            S_AXI_HP0_RDATA <= '0;
            S_AXI_HP0_RID <= '0;
        end
    endtask

    initial begin : ar_slave_model
        ar_req_t req;
        forever begin
            @(posedge ACLK);
            if (!ARESETn) begin
                hp_req_q.delete();
                S_AXI_HP0_ARREADY <= 1'b1;
            end
            else begin
                S_AXI_HP0_ARREADY <= (cycle_cnt[3:2] != 2'b10);

                if (S_AXI_HP0_ARVALID && S_AXI_HP0_ARREADY) begin
                    req.id = S_AXI_HP0_ARID;
                    req.addr = S_AXI_HP0_ARADDR;
                    req.len = S_AXI_HP0_ARLEN;
                    req.size = S_AXI_HP0_ARSIZE;
                    req.burst = S_AXI_HP0_ARBURST;
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
            if (hp_req_q.size() != 0 && !S_AXI_HP0_RVALID) begin
                req = hp_req_q.pop_back();
                repeat (2) @(posedge ACLK);
                send_r_burst(req);
            end
        end
    end

    always @(posedge ACLK) begin
        if (ARESETn && M_AXI_GP0_RVALID && M_AXI_GP0_RREADY) begin
            observed_beats++;

            if (M_AXI_GP0_RRESP != 2'b00) begin
                $error("Unexpected RRESP: %0b at time %0t", M_AXI_GP0_RRESP, $time);
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
                        M_AXI_GP0_RREADY <= (cycle_cnt[4:2] != 3'b101);
                    end
                end
            end
        join_any

        while (observed_reqs < NUM_REQ) begin
            @(posedge ACLK);
            ar_timeout_cnt++;
            if (ar_timeout_cnt > 500) begin
                $fatal(1, "Timeout waiting for HP0 AR requests. observed=%0d expected=%0d", observed_reqs, NUM_REQ);
            end
        end

        while (observed_beats < expected_beats) begin
            @(posedge ACLK);
            r_timeout_cnt++;
            if (r_timeout_cnt > 1000) begin
                $fatal(1, "Timeout waiting for GP0 R beats. observed=%0d expected=%0d", observed_beats, expected_beats);
            end
        end

        repeat (10) @(posedge ACLK);
        $display("PASS: axi_read_ooo test completed. requests=%0d beats=%0d", observed_reqs, observed_beats);
        $finish;
    end

endmodule

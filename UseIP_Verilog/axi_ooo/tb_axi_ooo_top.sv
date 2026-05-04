`timescale 1ns/1ps
`include "axi_include_top.vh"

import axi_pkg::*;


module tb_axi_ooo_top;
    localparam CLK_PERIOD = 10;
    localparam int NUM_READ_REQ = 40;
    localparam int NUM_WRITE_REQ = 40;

    logic ACLK;
    logic ARESETn;

    logic [ID_WIDTH-1:0]     S_AXI_ARID;
    logic [ADDR_WIDTH-1:0]   S_AXI_ARADDR;
    logic [LEN_WIDTH-1:0]    S_AXI_ARLEN;
    logic [2:0]              S_AXI_ARSIZE;
    logic [1:0]              S_AXI_ARBURST;
    logic                    S_AXI_ARVALID;
    wire                     S_AXI_ARREADY;

    logic [ID_WIDTH-1:0]     S_AXI_AWID;
    logic [ADDR_WIDTH-1:0]   S_AXI_AWADDR;
    logic [LEN_WIDTH-1:0]    S_AXI_AWLEN;
    logic [2:0]              S_AXI_AWSIZE;
    logic [1:0]              S_AXI_AWBURST;
    logic                    S_AXI_AWVALID;
    wire                     S_AXI_AWREADY;

    logic [DATA_WIDTH-1:0]   S_AXI_WDATA;
    logic [DATA_WIDTH/8-1:0] S_AXI_WSTRB;
    logic                    S_AXI_WLAST;
    logic                    S_AXI_WVALID;
    wire                     S_AXI_WREADY;

    wire [ID_WIDTH-1:0]      S_AXI_RID;
    wire [DATA_WIDTH-1:0]    S_AXI_RDATA;
    wire [1:0]               S_AXI_RRESP;
    wire                     S_AXI_RLAST;
    wire                     S_AXI_RVALID;
    logic                    S_AXI_RREADY;

    wire [ID_WIDTH-1:0]      S_AXI_BID;
    wire [1:0]               S_AXI_BRESP;
    wire                     S_AXI_BVALID;
    logic                    S_AXI_BREADY;

    wire [ID_WIDTH-1:0]      M_AXI_ARID;
    wire [ADDR_WIDTH-1:0]    M_AXI_ARADDR;
    wire [LEN_WIDTH-1:0]     M_AXI_ARLEN;
    wire [2:0]               M_AXI_ARSIZE;
    wire [1:0]               M_AXI_ARBURST;
    wire                     M_AXI_ARVALID;
    logic                    M_AXI_ARREADY;

    wire [ID_WIDTH-1:0]      M_AXI_AWID;
    wire [ADDR_WIDTH-1:0]    M_AXI_AWADDR;
    wire [LEN_WIDTH-1:0]     M_AXI_AWLEN;
    wire [2:0]               M_AXI_AWSIZE;
    wire [1:0]               M_AXI_AWBURST;
    wire                     M_AXI_AWVALID;
    logic                    M_AXI_AWREADY;

    wire [DATA_WIDTH-1:0]    M_AXI_WDATA;
    wire [DATA_WIDTH/8-1:0]  M_AXI_WSTRB;
    wire                     M_AXI_WLAST;
    wire                     M_AXI_WVALID;
    logic                    M_AXI_WREADY;

    logic [ID_WIDTH-1:0]     M_AXI_RID;
    logic [DATA_WIDTH-1:0]   M_AXI_RDATA;
    logic [1:0]              M_AXI_RRESP;
    logic                    M_AXI_RLAST;
    logic                    M_AXI_RVALID;
    wire                     M_AXI_RREADY;

    logic [ID_WIDTH-1:0]     M_AXI_BID;
    logic [1:0]              M_AXI_BRESP;
    logic                    M_AXI_BVALID;
    wire                     M_AXI_BREADY;

    // typedef struct 사용해서 해당 값들을 모아 사전 def.
    typedef struct packed {
        logic [ID_WIDTH-1:0]   id;
        logic [ADDR_WIDTH-1:0] addr;
        logic [LEN_WIDTH-1:0]  len;
        logic [2:0]            size;
        logic [1:0]            burst;
    } req_t;

    // SYSTEMVERILOG push_back / pop_front 내장 함수 사용.
    req_t read_req_q[$];
    req_t hp_read_q[$];
    req_t write_req_q[$];
    req_t hp_write_q[$];
    int unsigned expected_read_beats;
    int unsigned observed_read_beats;
    int unsigned observed_ar;
    int unsigned observed_aw;
    int unsigned observed_w_beats;
    int unsigned observed_b;
    int unsigned expected_w_beats;
    int unsigned cycle_cnt;

    // module instantiate 
    axi_ooo_controller dut (
        .ACLK(ACLK),
        .ARESETn(ARESETn),

        .S_AXI_ARID(S_AXI_ARID),
        .S_AXI_ARADDR(S_AXI_ARADDR),
        .S_AXI_ARLEN(S_AXI_ARLEN),
        .S_AXI_ARSIZE(S_AXI_ARSIZE),
        .S_AXI_ARBURST(S_AXI_ARBURST),
        .S_AXI_ARVALID(S_AXI_ARVALID),
        .S_AXI_ARREADY(S_AXI_ARREADY),

        .S_AXI_AWID(S_AXI_AWID),
        .S_AXI_AWADDR(S_AXI_AWADDR),
        .S_AXI_AWLEN(S_AXI_AWLEN),
        .S_AXI_AWSIZE(S_AXI_AWSIZE),
        .S_AXI_AWBURST(S_AXI_AWBURST),
        .S_AXI_AWVALID(S_AXI_AWVALID),
        .S_AXI_AWREADY(S_AXI_AWREADY),

        .S_AXI_WDATA(S_AXI_WDATA),
        .S_AXI_WSTRB(S_AXI_WSTRB),
        .S_AXI_WLAST(S_AXI_WLAST),
        .S_AXI_WVALID(S_AXI_WVALID),
        .S_AXI_WREADY(S_AXI_WREADY),

        .S_AXI_RID(S_AXI_RID),
        .S_AXI_RDATA(S_AXI_RDATA),
        .S_AXI_RRESP(S_AXI_RRESP),
        .S_AXI_RLAST(S_AXI_RLAST),
        .S_AXI_RVALID(S_AXI_RVALID),
        .S_AXI_RREADY(S_AXI_RREADY),

        .S_AXI_BID(S_AXI_BID),
        .S_AXI_BRESP(S_AXI_BRESP),
        .S_AXI_BVALID(S_AXI_BVALID),
        .S_AXI_BREADY(S_AXI_BREADY),

        .M_AXI_ARID(M_AXI_ARID),
        .M_AXI_ARADDR(M_AXI_ARADDR),
        .M_AXI_ARLEN(M_AXI_ARLEN),
        .M_AXI_ARSIZE(M_AXI_ARSIZE),
        .M_AXI_ARBURST(M_AXI_ARBURST),
        .M_AXI_ARVALID(M_AXI_ARVALID),
        .M_AXI_ARREADY(M_AXI_ARREADY),

        .M_AXI_AWID(M_AXI_AWID),
        .M_AXI_AWADDR(M_AXI_AWADDR),
        .M_AXI_AWLEN(M_AXI_AWLEN),
        .M_AXI_AWSIZE(M_AXI_AWSIZE),
        .M_AXI_AWBURST(M_AXI_AWBURST),
        .M_AXI_AWVALID(M_AXI_AWVALID),
        .M_AXI_AWREADY(M_AXI_AWREADY),

        .M_AXI_WDATA(M_AXI_WDATA),
        .M_AXI_WSTRB(M_AXI_WSTRB),
        .M_AXI_WLAST(M_AXI_WLAST),
        .M_AXI_WVALID(M_AXI_WVALID),
        .M_AXI_WREADY(M_AXI_WREADY),

        .M_AXI_RID(M_AXI_RID),
        .M_AXI_RDATA(M_AXI_RDATA),
        .M_AXI_RRESP(M_AXI_RRESP),
        .M_AXI_RLAST(M_AXI_RLAST),
        .M_AXI_RVALID(M_AXI_RVALID),
        .M_AXI_RREADY(M_AXI_RREADY),

        .M_AXI_BID(M_AXI_BID),
        .M_AXI_BRESP(M_AXI_BRESP),
        .M_AXI_BVALID(M_AXI_BVALID),
        .M_AXI_BREADY(M_AXI_BREADY)
    );

    // ACLK
    initial begin
        ACLK = 1'b0;
        forever #(CLK_PERIOD/2) ACLK = ~ACLK;
    end

    // cycle_cnt 관련
    always @(posedge ACLK) begin
        if (!ARESETn) cycle_cnt <= 0;
        else cycle_cnt <= cycle_cnt + 1;
    end

    // TASK 모음
    task automatic init_signals;
        begin
            ARESETn = 1'b0;

            S_AXI_ARID = '0;
            S_AXI_ARADDR = '0;
            S_AXI_ARLEN = '0;
            S_AXI_ARSIZE = 3'b010;
            S_AXI_ARBURST = 2'b01;
            S_AXI_ARVALID = 1'b0;

            S_AXI_AWID = '0;
            S_AXI_AWADDR = '0;
            S_AXI_AWLEN = '0;
            S_AXI_AWSIZE = 3'b010;
            S_AXI_AWBURST = 2'b01;
            S_AXI_AWVALID = 1'b0;

            S_AXI_WDATA = '0;
            S_AXI_WSTRB = '1;
            S_AXI_WLAST = 1'b0;
            S_AXI_WVALID = 1'b0;
            S_AXI_RREADY = 1'b1;
            S_AXI_BREADY = 1'b1;

            M_AXI_ARREADY = 1'b1;
            M_AXI_AWREADY = 1'b1;
            M_AXI_WREADY = 1'b1;
            M_AXI_RID = '0;
            M_AXI_RDATA = '0;
            M_AXI_RRESP = 2'b00;
            M_AXI_RLAST = 1'b0;
            M_AXI_RVALID = 1'b0;
            M_AXI_BID = '0;
            M_AXI_BRESP = 2'b00;
            M_AXI_BVALID = 1'b0;

            expected_read_beats = 0;
            observed_read_beats = 0;
            observed_ar = 0;
            observed_aw = 0;
            observed_w_beats = 0;
            observed_b = 0;
            expected_w_beats = 0;
            cycle_cnt = 0;
        end
    endtask

    task automatic apply_reset;
        begin
            repeat (5) @(posedge ACLK);
            ARESETn <= 1'b1;
            repeat (2) @(posedge ACLK);
        end
    endtask

    task automatic send_ar(
        input logic [ID_WIDTH-1:0] id,
        input logic [ADDR_WIDTH-1:0] addr,
        input logic [LEN_WIDTH-1:0] len
    );
        axi_ar_rand ar_tr;
        logic [ID_WIDTH-1:0] target_id;
        logic [ADDR_WIDTH-1:0] target_addr;
        logic [LEN_WIDTH-1:0] target_len;
        begin
            target_id = id;
            target_addr = addr;
            target_len = len;

            ar_tr = new();
            ar_tr.set_fixed(target_id, target_addr, target_len);

            @(posedge ACLK);
            S_AXI_ARID <= ar_tr.id;
            S_AXI_ARADDR <= ar_tr.addr;
            S_AXI_ARLEN <= ar_tr.len;
            S_AXI_ARSIZE <= ar_tr.size;
            S_AXI_ARBURST <= ar_tr.burst;
            S_AXI_ARVALID <= ar_tr.valid;
            while (!S_AXI_ARREADY) @(posedge ACLK);
            @(posedge ACLK);
            S_AXI_ARVALID <= 1'b0;
            expected_read_beats += ar_tr.len + 1;
        end
    endtask

    task automatic send_aw(
        input logic [ID_WIDTH-1:0] id,
        input logic [ADDR_WIDTH-1:0] addr,
        input logic [LEN_WIDTH-1:0] len
    );
        req_t req;
        axi_aw_rand aw_tr;
        logic [ID_WIDTH-1:0] target_id;
        logic [ADDR_WIDTH-1:0] target_addr;
        logic [LEN_WIDTH-1:0] target_len;
        begin
            target_id = id;
            target_addr = addr;
            target_len = len;

            aw_tr = new();
            aw_tr.set_fixed(target_id, target_addr, target_len);

            req.id = aw_tr.id;
            req.addr = aw_tr.addr;
            req.len = aw_tr.len;
            req.size = aw_tr.size;
            req.burst = aw_tr.burst;

            @(posedge ACLK);
            S_AXI_AWID <= req.id;
            S_AXI_AWADDR <= req.addr;
            S_AXI_AWLEN <= req.len;
            S_AXI_AWSIZE <= req.size;
            S_AXI_AWBURST <= req.burst;
            S_AXI_AWVALID <= 1'b1;
            while (!S_AXI_AWREADY) @(posedge ACLK);
            @(posedge ACLK);
            S_AXI_AWVALID <= 1'b0;
            // 여기서 push_back 함수를 통해 (SYSTEMVERILOG ONLY) req를 담는거임.
            write_req_q.push_back(req);
            expected_w_beats += req.len + 1;
        end
    endtask

    task automatic send_w_burst(input logic [LEN_WIDTH-1:0] len, input logic [DATA_WIDTH-1:0] base_data);
        int unsigned beat;
        axi_w_rand w_tr;
        logic [DATA_WIDTH-1:0] target_data;
        bit target_last;
        begin
            for (beat=0; beat<=len; beat++) begin
                target_data = base_data + beat;
                target_last = (beat == len);

                w_tr = new();
                w_tr.set_fixed(target_data, target_last);

                @(posedge ACLK);
                S_AXI_WDATA <= w_tr.data;
                S_AXI_WSTRB <= w_tr.strb;
                S_AXI_WLAST <= w_tr.last;
                S_AXI_WVALID <= w_tr.valid;
                while (!S_AXI_WREADY) @(posedge ACLK);
            end

            @(posedge ACLK);
            S_AXI_WVALID <= 1'b0;
            S_AXI_WLAST <= 1'b0;
            S_AXI_WDATA <= '0;
        end
    endtask

    task automatic send_r_burst(input req_t req);
        int unsigned beat;
        axi_r_rand r_tr;
        logic [ID_WIDTH-1:0] target_id;
        logic [DATA_WIDTH-1:0] target_data;
        bit target_last;
        begin
            for (beat=0; beat<=req.len; beat++) begin
                target_id = req.id;
                target_data = {req.id, req.addr[DATA_WIDTH-ID_WIDTH-1:0]} + beat;
                target_last = (beat == req.len);

                r_tr = new();
                r_tr.set_fixed(target_id, target_data, target_last);

                @(posedge ACLK);
                M_AXI_RID <= r_tr.id;
                M_AXI_RDATA <= r_tr.data;
                M_AXI_RRESP <= r_tr.resp;
                M_AXI_RLAST <= r_tr.last;
                M_AXI_RVALID <= r_tr.valid;
                while (!M_AXI_RREADY) @(posedge ACLK);
            end

            @(posedge ACLK);
            M_AXI_RVALID <= 1'b0;
            M_AXI_RLAST <= 1'b0;
            M_AXI_RDATA <= '0;
            M_AXI_RID <= '0;
        end
    endtask

    // 상단에서 사전 typedef 한 req_t에게 값 지정해주는 것.
    initial begin : hp_read_addr_model
        req_t req;
        forever begin
            @(posedge ACLK);
            if (!ARESETn) begin
                hp_read_q.delete();
                M_AXI_ARREADY <= 1'b1;
            end
            else begin
                M_AXI_ARREADY <= (cycle_cnt[3:2] != 2'b10); // cycle_cnt 값 참조하여 지정
                if (M_AXI_ARVALID && M_AXI_ARREADY) begin
                    req.id = M_AXI_ARID;
                    req.addr = M_AXI_ARADDR;
                    req.len = M_AXI_ARLEN;
                    req.size = M_AXI_ARSIZE;
                    req.burst = M_AXI_ARBURST;
                    hp_read_q.push_back(req);
                    observed_ar++;
                end
            end
        end
    end

    initial begin : hp_read_data_model  // 데이터 읽기 모델임.
        req_t req;
        wait (ARESETn);
        forever begin
            @(posedge ACLK);
            if (hp_read_q.size() != 0 && !M_AXI_RVALID) begin
                req = hp_read_q.pop_front();
                repeat (2) @(posedge ACLK); // 2 CLK 지나고
                send_r_burst(req);  // 값을 보내줌.
            end
        end
    end

    initial begin : hp_write_resp_model
        req_t req;
        wait (ARESETn);

        forever begin
            @(posedge ACLK);

            if (!ARESETn) begin
                hp_write_q.delete();
                M_AXI_BID <= '0;
                M_AXI_BRESP <= 2'b00;
                M_AXI_BVALID <= 1'b0;
            end
            else begin
                if (M_AXI_BVALID) begin
                    if (M_AXI_BREADY) begin
                        M_AXI_BID <= '0;
                        M_AXI_BRESP <= 2'b00;
                        M_AXI_BVALID <= 1'b0;
                    end
                end
                else if (M_AXI_WVALID && M_AXI_WREADY && M_AXI_WLAST && (hp_write_q.size() != 0)) begin
                    req = hp_write_q.pop_front();
                    M_AXI_BID <= req.id;
                    M_AXI_BRESP <= 2'b00;
                    M_AXI_BVALID <= 1'b1;
                end
            end
        end
    end

    always @(posedge ACLK) begin
        req_t aw_req;

        if (ARESETn) begin
            M_AXI_AWREADY <= (cycle_cnt[2:1] != 2'b11);
            M_AXI_WREADY <= (cycle_cnt[3:1] != 3'b101);

            if (M_AXI_AWVALID && M_AXI_AWREADY) begin
                aw_req.id = M_AXI_AWID;
                aw_req.addr = M_AXI_AWADDR;
                aw_req.len = M_AXI_AWLEN;
                aw_req.size = M_AXI_AWSIZE;
                aw_req.burst = M_AXI_AWBURST;
                hp_write_q.push_back(aw_req);
                observed_aw++;
            end

            if (M_AXI_WVALID && M_AXI_WREADY) begin
                observed_w_beats++;
            end

            if (S_AXI_RVALID && S_AXI_RREADY) begin
                observed_read_beats++;
                if (S_AXI_RRESP != 2'b00) begin
                    $error("Unexpected RRESP %0b at time %0t", S_AXI_RRESP, $time);
                end
            end

            if (S_AXI_BVALID && S_AXI_BREADY) begin
                observed_b++;
                if (S_AXI_BRESP != 2'b00) begin
                    $error("Unexpected BRESP %0b at time %0t", S_AXI_BRESP, $time);
                end
            end
        end
    end

    initial begin : main_test
        int unsigned timeout;
        int i;
        axi_ar_rand ar_tr;
        axi_aw_rand aw_tr;

        init_signals();

        `ifdef DISPLAY_ALL_SIGNALS
            $dumpfile("tb_axi_ooo_top.vcd");
            $dumpvars(0, tb_axi_ooo_top);
        `endif

        apply_reset();

        fork
            // 원래라면 .randomize()라는 방법이 있으나, 여기서는 $urandom()을 class 내부에서 사용하였기 때문에 set_random()이라는 function을 호출하는 방식으로 설계
            // 복잡하게 이런 방식을 채택한 이유는 :  Vivado에서 Crash 나서.
            begin : send_ar_random
                // send_ar(4'h1, 32'h0000_1000, 8'd1);
                // send_ar(4'h2, 32'h0000_2000, 8'd0);
                // send_ar(4'h3, 32'h0000_3000, 8'd2);
                // send_ar(4'h1, 32'h0000_1040, 8'd1);
                for (i=0; i<NUM_READ_REQ; i++) begin
                    ar_tr = new();
                    ar_tr.set_random();
                    send_ar(ar_tr.id, ar_tr.addr, ar_tr.len);
                end
            end

            begin : send_aw_random
                // send_aw(4'h2, 32'h0000_8000, 8'd1);
                // send_aw(4'h1, 32'h0000_9000, 8'd2);
                // send_aw(4'h2, 32'h0000_8040, 8'd0);
                // send_aw(4'h3, 32'h0000_A000, 8'd1);
                for (i=0; i<NUM_WRITE_REQ; i++) begin
                    aw_tr = new();
                    aw_tr.set_random(); 
                    send_aw(aw_tr.id, aw_tr.addr, aw_tr.len);
                end
            end

            begin : send_w_random
                // repeat (4) @(posedge ACLK);
                // send_w_burst(8'd1, 32'hA000_0000);
                // send_w_burst(8'd2, 32'hB000_0000);
                // send_w_burst(8'd0, 32'hC000_0000);
                // send_w_burst(8'd1, 32'hD000_0000);
                
                // pop_front 내장 함수를 사용하여 AW가 나왔을 때 W를 보내도록 보장.

                req_t w_req;
                int unsigned sent_w;

                sent_w = 0;

                while (sent_w < NUM_WRITE_REQ) begin
                    wait (write_req_q.size() != 0); // Size가 0이 아니라면 값이 들어간 것일테니.
                    w_req = write_req_q.pop_front();
                    send_w_burst(w_req.len, 32'hA000_0000 + sent_w*32'h0100);
                    sent_w++;
                end
            end
        join

        timeout = 0;
        while ((observed_ar < NUM_READ_REQ) ||
               (observed_read_beats < expected_read_beats) ||
               (observed_aw < NUM_WRITE_REQ) ||
               (observed_w_beats < expected_w_beats) ||
               (observed_b < NUM_WRITE_REQ)) begin
            @(posedge ACLK);
            timeout++;
            if (timeout > 2000) begin
                $fatal(1,
                    "Timeout: ar=%0d/%0d rbeats=%0d/%0d aw=%0d/%0d wbeats=%0d/%0d b=%0d/%0d",
                    observed_ar, NUM_READ_REQ,
                    observed_read_beats, expected_read_beats,
                    observed_aw, NUM_WRITE_REQ,
                    observed_w_beats, expected_w_beats,
                    observed_b, NUM_WRITE_REQ);
            end
        end

        repeat (10) @(posedge ACLK);
        $display("PASS: axi_ooo_controller top test completed. ar=%0d rbeats=%0d aw=%0d wbeats=%0d b=%0d",
                 observed_ar, observed_read_beats, observed_aw, observed_w_beats, observed_b);
        $finish;
    end

endmodule

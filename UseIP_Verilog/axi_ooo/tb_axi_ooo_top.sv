`timescale 1ns/1ps
`include "axi_include_top.vh"

import axi_pkg::*;
`include "tb_axi_ooo_top_pkg.sv"
import tb_axi_ooo_top_pkg::*;


module tb_axi_ooo_top;
    localparam CLK_PERIOD = 10;
    localparam logic [LEN_WIDTH-1:0] FIXED_BURST_LEN = 8'd15;
    localparam int PERF_LOG_INTERVAL = 500;
    localparam int SCENARIO_TIMEOUT = 10000;
    localparam int MIN_RECOMMENDED_RUN_NS = 100000;
    localparam int TB_READ_BANK_BIT_START = 6;
    localparam int TB_READ_BANK_BITS = (NUM_BANK <= 1) ? 1 : $clog2(NUM_BANK);

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

    // SYSTEMVERILOG push_back / pop_front 내장 함수 사용.
    tb_axi_req_t read_req_q[$];
    tb_axi_req_t hp_read_q[$];
    tb_axi_req_t write_req_q[$];
    tb_axi_req_t hp_write_q[$];
    int unsigned read_accept_cycle_q[$];
    int unsigned write_accept_cycle_q[$];
    int unsigned expected_read_beats;
    int unsigned observed_read_beats;
    int unsigned observed_ar;
    int unsigned observed_aw;
    int unsigned observed_w_beats;
    int unsigned observed_b;
    int unsigned expected_w_beats;
    int unsigned cycle_cnt;
    int unsigned scenario_start_cycle;
    int unsigned ar_burst_count;
    int unsigned aw_burst_count;
    int unsigned r_burst_count;
    int unsigned w_burst_count;
    int unsigned b_resp_count;
    int unsigned reorder_stall_count;
    int unsigned ar_ready_stall_count;
    int unsigned aw_ready_stall_count;
    int unsigned read_policy_hit_count;
    int unsigned read_policy_miss_count;
    int unsigned read_issue_count;
    int unsigned write_same_id_hit_count;
    int unsigned write_same_id_miss_count;
    int unsigned write_issue_count;
    int unsigned read_bank_issue_count[0:NUM_BANK-1];
    int unsigned write_id_issue_count[0:NUM_READ_IDTABLE-1];
    int unsigned read_same_bank_streak;
    int unsigned read_same_bank_streak_sum;
    int unsigned read_same_bank_streak_samples;
    int unsigned read_same_bank_streak_max;
    int unsigned write_same_id_streak;
    int unsigned write_same_id_streak_sum;
    int unsigned write_same_id_streak_samples;
    int unsigned write_same_id_streak_max;
    int unsigned read_latency_sum;
    int unsigned read_latency_max;
    int unsigned read_latency_count;
    int unsigned write_latency_sum;
    int unsigned write_latency_max;
    int unsigned write_latency_count;
    int unsigned dbg_awq_backpressure_count;
    int unsigned dbg_aw_sched_input_stall_count;
    int unsigned dbg_aw_sched_output_stall_count;
    int unsigned dbg_order_aw_queue_stall_count;
    int unsigned dbg_order_aw_sched_wait_count;
    int unsigned dbg_b_aw_sched_stall_count;
    int unsigned dbg_w_input_stall_count;
    int unsigned dbg_m_aw_ready_stall_count;
    logic [TB_READ_BANK_BITS-1:0] last_read_issue_bank;
    logic [ID_WIDTH-1:0] last_write_issue_id;
    bit have_last_read_issue_bank;
    bit have_last_write_issue_id;
    bit perf_log_enable;
    integer perf_log_fd;
    string active_scenario_name;
    string active_write_case_name;
    int unsigned active_num_read_req;
    int unsigned active_num_write_req;

    // module instantiate 
    axi_ooo_controller #(
        .FIFO_NUM(FIFO_NUM),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ID_WIDTH(ID_WIDTH),
        .LEN_WIDTH(LEN_WIDTH),
        .NUM_READ_IDTABLE(NUM_READ_IDTABLE),
        .NUM_READ_SCHEDULER(NUM_READ_SCHEDULER),
        .NUM_READ_REORDER(NUM_READ_REORDER),
        .NUM_BANK(NUM_BANK),
        .NUM_WRITE_AWQUEUE(NUM_WRITE_AWQUEUE),
        .NUM_WRITE_SCHEDULER(NUM_WRITE_SCHEDULER),
        .NUM_WRITE_ORDER_QUEUE_AW(NUM_WRITE_ORDER_QUEUE_AW),
        .WRITE_MAX_BURST_BEATS(FIXED_BURST_LEN + 1)
    ) dut (
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
            perf_log_enable = 1'b0;
            active_write_case_name = "idle";
            active_num_read_req = 0;
            active_num_write_req = 0;

            read_req_q.delete();
            hp_read_q.delete();
            write_req_q.delete();
            read_accept_cycle_q.delete();
            write_accept_cycle_q.delete();
            hp_write_q.delete();

            expected_read_beats = 0;
            observed_read_beats = 0;
            observed_ar = 0;
            observed_aw = 0;
            observed_w_beats = 0;
            observed_b = 0;
            expected_w_beats = 0;
            cycle_cnt = 0;
            reset_perf_counters("idle");
        end
    endtask

    task automatic reset_perf_counters(input string scenario_name);
        begin
            active_scenario_name = scenario_name;
            scenario_start_cycle = cycle_cnt;
            read_accept_cycle_q.delete();
            write_accept_cycle_q.delete();
            expected_read_beats = 0;
            observed_read_beats = 0;
            observed_ar = 0;
            observed_aw = 0;
            observed_w_beats = 0;
            observed_b = 0;
            expected_w_beats = 0;
            ar_burst_count = 0;
            aw_burst_count = 0;
            r_burst_count = 0;
            w_burst_count = 0;
            b_resp_count = 0;
            reorder_stall_count = 0;
            ar_ready_stall_count = 0;
            aw_ready_stall_count = 0;
            read_policy_hit_count = 0;
            read_policy_miss_count = 0;
            read_issue_count = 0;
            write_same_id_hit_count = 0;
            write_same_id_miss_count = 0;
            write_issue_count = 0;
            for (int i=0; i<NUM_BANK; i++) begin
                read_bank_issue_count[i] = 0;
            end
            for (int i=0; i<NUM_READ_IDTABLE; i++) begin
                write_id_issue_count[i] = 0;
            end
            read_same_bank_streak = 0;
            read_same_bank_streak_sum = 0;
            read_same_bank_streak_samples = 0;
            read_same_bank_streak_max = 0;
            write_same_id_streak = 0;
            write_same_id_streak_sum = 0;
            write_same_id_streak_samples = 0;
            write_same_id_streak_max = 0;
            read_latency_sum = 0;
            read_latency_max = 0;
            read_latency_count = 0;
            write_latency_sum = 0;
            write_latency_max = 0;
            write_latency_count = 0;
            dbg_awq_backpressure_count = 0;
            dbg_aw_sched_input_stall_count = 0;
            dbg_aw_sched_output_stall_count = 0;
            dbg_order_aw_queue_stall_count = 0;
            dbg_order_aw_sched_wait_count = 0;
            dbg_b_aw_sched_stall_count = 0;
            dbg_w_input_stall_count = 0;
            dbg_m_aw_ready_stall_count = 0;
            last_read_issue_bank = '0;
            last_write_issue_id = '0;
            have_last_read_issue_bank = 1'b0;
            have_last_write_issue_id = 1'b0;
        end
    endtask

    task automatic apply_reset;
        begin
            ARESETn <= 1'b0;
            repeat (5) @(posedge ACLK);
            ARESETn <= 1'b1;
            repeat (2) @(posedge ACLK);
        end
    endtask

    task automatic display_perf_snapshot(input string tag);
        int unsigned elapsed_cycles;
        int unsigned write_streak_avg_x100;
        int unsigned write_streak_sum_snapshot;
        int unsigned write_streak_samples_snapshot;
        int unsigned read_latency_avg;
        int unsigned write_latency_avg;
        int unsigned ar_stall_per_req_x100;
        int unsigned aw_stall_per_req_x100;
        begin
            elapsed_cycles = cycle_cnt - scenario_start_cycle;
            write_streak_sum_snapshot = write_same_id_streak_sum;
            write_streak_samples_snapshot = write_same_id_streak_samples;
            if (have_last_write_issue_id) begin
                write_streak_sum_snapshot += write_same_id_streak;
                write_streak_samples_snapshot++;
            end

            write_streak_avg_x100 =
                (write_streak_samples_snapshot == 0) ? 0 :
                ((write_streak_sum_snapshot * 100) / write_streak_samples_snapshot);
            read_latency_avg =
                (read_latency_count == 0) ? 0 : (read_latency_sum / read_latency_count);
            write_latency_avg =
                (write_latency_count == 0) ? 0 : (write_latency_sum / write_latency_count);
            ar_stall_per_req_x100 =
                (ar_burst_count == 0) ? 0 : ((ar_ready_stall_count * 100) / ar_burst_count);
            aw_stall_per_req_x100 =
                (aw_burst_count == 0) ? 0 : ((aw_ready_stall_count * 100) / aw_burst_count);

            if (tag == "progress") begin
                $display("[%0t][%s][progress] cycle=%0d elapsed=%0d aw=%0d/%0d wbeats=%0d/%0d b=%0d/%0d aw_stall=%0d w_stall=%0d m_aw_stall=%0d write_lat_avg=%0d",
                         $time, active_scenario_name,
                         cycle_cnt, elapsed_cycles,
                         aw_burst_count, active_num_write_req,
                         observed_w_beats, expected_w_beats,
                         observed_b, active_num_write_req,
                         aw_ready_stall_count, dbg_w_input_stall_count,
                         dbg_m_aw_ready_stall_count, write_latency_avg);
            end
            else if (tag == "summary") begin
                $display("============================================================");
                $display("[%0t][%s][summary] case=%s elapsed=%0d cycle=%0d",
                         $time, active_scenario_name, active_write_case_name,
                         elapsed_cycles, cycle_cnt);
                $display("  progress : ar=%0d/%0d rbeats=%0d/%0d aw=%0d/%0d wbeats=%0d/%0d b=%0d/%0d",
                         observed_ar, active_num_read_req,
                         observed_read_beats, expected_read_beats,
                         aw_burst_count, active_num_write_req,
                         observed_w_beats, expected_w_beats,
                         observed_b, active_num_write_req);
                $display("  latency  : read_avg=%0d read_max=%0d write_avg=%0d write_max=%0d",
                         read_latency_avg, read_latency_max,
                         write_latency_avg, write_latency_max);
                $display("  stalls   : ar=%0d(%0d/req x100) aw=%0d(%0d/req x100) w_input=%0d m_aw_ready=%0d reorder=%0d",
                         ar_ready_stall_count, ar_stall_per_req_x100,
                         aw_ready_stall_count, aw_stall_per_req_x100,
                         dbg_w_input_stall_count, dbg_m_aw_ready_stall_count,
                         reorder_stall_count);
                $display("  policy   : write_issue=%0d same_id_hit=%0d miss=%0d streak_avg_x100=%0d streak_max=%0d",
                         write_issue_count, write_same_id_hit_count,
                         write_same_id_miss_count, write_streak_avg_x100,
                         write_same_id_streak_max);
                $display("============================================================");
            end
            else begin
                $display("[%0t][%s][%s] case=%s cycle=%0d elapsed=%0d ar=%0d/%0d aw=%0d/%0d rbeats=%0d/%0d wbeats=%0d/%0d b=%0d/%0d aw_stall=%0d w_stall=%0d write_lat_avg=%0d write_lat_max=%0d",
                         $time, active_scenario_name, tag, active_write_case_name,
                         cycle_cnt, elapsed_cycles,
                         observed_ar, active_num_read_req,
                         aw_burst_count, active_num_write_req,
                         observed_read_beats, expected_read_beats,
                         observed_w_beats, expected_w_beats,
                         observed_b, active_num_write_req,
                         aw_ready_stall_count, dbg_w_input_stall_count,
                         write_latency_avg, write_latency_max);
            end

            if (perf_log_fd != 0) begin
                $fdisplay(perf_log_fd,
                          "time=%0t scenario=%s tag=%s case=%s cycle=%0d elapsed=%0d ar=%0d/%0d rbeats=%0d/%0d aw=%0d/%0d wbeats=%0d/%0d b=%0d/%0d ar_stall=%0d aw_stall=%0d w_stall=%0d m_aw_stall=%0d reorder_stall=%0d read_lat_avg=%0d read_lat_max=%0d write_lat_avg=%0d write_lat_max=%0d same_id_hit=%0d same_id_miss=%0d write_streak_avg_x100=%0d write_streak_max=%0d",
                          $time, active_scenario_name, tag, active_write_case_name,
                          cycle_cnt, elapsed_cycles,
                          observed_ar, active_num_read_req,
                          observed_read_beats, expected_read_beats,
                          aw_burst_count, active_num_write_req,
                          observed_w_beats, expected_w_beats,
                          observed_b, active_num_write_req,
                          ar_ready_stall_count, aw_ready_stall_count,
                          dbg_w_input_stall_count, dbg_m_aw_ready_stall_count,
                          reorder_stall_count,
                          read_latency_avg, read_latency_max,
                          write_latency_avg, write_latency_max,
                          write_same_id_hit_count, write_same_id_miss_count,
                          write_streak_avg_x100, write_same_id_streak_max);
                $fflush(perf_log_fd);
            end
        end
    endtask

    task automatic display_transaction_log(input string event_name,
                                           input logic [ID_WIDTH-1:0] id,
                                           input logic [ADDR_WIDTH-1:0] addr,
                                           input logic [LEN_WIDTH-1:0] len);
        begin
            if (perf_log_fd != 0) begin
                $fdisplay(perf_log_fd,
                          "[%0t][%s][%s] cycle=%0d id=0x%0h addr=0x%0h len=%0d beats=%0d",
                          $time, active_scenario_name, event_name,
                          cycle_cnt, id, addr, len, len + 1);
                $fflush(perf_log_fd);
            end
        end
    endtask

    task automatic display_scenario_config(input tb_axi_ooo_scenario_cfg_t cfg);
        begin
            $display("[%0t][%s][config] case=%s read_req=%0d write_req=%0d fixed_len_mode=%0b fixed_len=%0d max_random_len=%0d same_id=%0h addr_base=0x%0h addr_stride=0x%0h",
                     $time, cfg.name, write_case_name(cfg.write_case),
                     cfg.num_read_req, cfg.num_write_req,
                     cfg.fixed_len_mode, cfg.fixed_len, cfg.max_random_len,
                     cfg.same_write_id, cfg.write_addr_base, cfg.write_addr_stride);

            if (perf_log_fd != 0) begin
                $fdisplay(perf_log_fd,
                          "time=%0t scenario=%s tag=config case=%s read_req=%0d write_req=%0d fixed_len_mode=%0b fixed_len=%0d max_random_len=%0d same_id=%0h addr_base=0x%0h addr_stride=0x%0h data_base=0x%0h data_stride=0x%0h",
                          $time, cfg.name, write_case_name(cfg.write_case),
                          cfg.num_read_req, cfg.num_write_req,
                          cfg.fixed_len_mode, cfg.fixed_len, cfg.max_random_len,
                          cfg.same_write_id, cfg.write_addr_base, cfg.write_addr_stride,
                          cfg.write_data_base, cfg.write_data_stride);
                $fflush(perf_log_fd);
            end
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
            @(posedge ACLK);
            while (!S_AXI_ARREADY) @(posedge ACLK);
            S_AXI_ARVALID <= 1'b0;
            expected_read_beats += ar_tr.len + 1;
        end
    endtask

    task automatic send_aw(
        input logic [ID_WIDTH-1:0] id,
        input logic [ADDR_WIDTH-1:0] addr,
        input logic [LEN_WIDTH-1:0] len
    );
        tb_axi_req_t req;
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
            @(posedge ACLK);
            while (!S_AXI_AWREADY) @(posedge ACLK);
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
                @(posedge ACLK);
                while (!S_AXI_WREADY) @(posedge ACLK);
                S_AXI_WVALID <= 1'b0;
                S_AXI_WLAST <= 1'b0;
                S_AXI_WDATA <= '0;
            end

            S_AXI_WVALID <= 1'b0;
            S_AXI_WLAST <= 1'b0;
            S_AXI_WDATA <= '0;
        end
    endtask

    task automatic send_r_burst(input tb_axi_req_t req);
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
                @(posedge ACLK);
                while (!M_AXI_RREADY) @(posedge ACLK);
                M_AXI_RVALID <= 1'b0;
                M_AXI_RLAST <= 1'b0;
                M_AXI_RDATA <= '0;
                M_AXI_RID <= '0;
            end

            M_AXI_RVALID <= 1'b0;
            M_AXI_RLAST <= 1'b0;
            M_AXI_RDATA <= '0;
            M_AXI_RID <= '0;
        end
    endtask

    // 상단에서 사전 typedef 한 tb_axi_req_t에게 값 지정해주는 것.
    initial begin : hp_read_addr_model
        tb_axi_req_t req;
        logic [TB_READ_BANK_BITS-1:0] issue_bank;
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
                    read_issue_count++;
                    issue_bank = M_AXI_ARADDR[TB_READ_BANK_BIT_START -: TB_READ_BANK_BITS];
                    read_bank_issue_count[issue_bank]++;
                    if (have_last_read_issue_bank) begin
                        if (issue_bank == last_read_issue_bank) begin
                            read_policy_hit_count++;
                            read_same_bank_streak++;
                        end
                        else begin
                            read_policy_miss_count++;
                            read_same_bank_streak_sum += read_same_bank_streak;
                            read_same_bank_streak_samples++;
                            read_same_bank_streak = 1;
                        end
                    end
                    else begin
                        read_same_bank_streak = 1;
                    end
                    if (read_same_bank_streak > read_same_bank_streak_max)
                        read_same_bank_streak_max = read_same_bank_streak;
                    last_read_issue_bank = issue_bank;
                    have_last_read_issue_bank = 1'b1;
                    display_transaction_log("M_AR_ISSUE", M_AXI_ARID, M_AXI_ARADDR, M_AXI_ARLEN);
                end
            end
        end
    end

    initial begin : hp_read_data_model  // 데이터 읽기 모델임.
        tb_axi_req_t req;
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
        tb_axi_req_t req;
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
        tb_axi_req_t aw_req;
        int unsigned latency;

        if (ARESETn) begin
            if ((cycle_cnt > 2) &&
                ($isunknown(dut.u_axi_write_ooo.sched_o_awvalid) ||
                 $isunknown(dut.u_axi_write_ooo.sched_i_awready) ||
                 $isunknown(S_AXI_WREADY))) begin
                display_perf_snapshot("unknown_write_handshake");
                $fatal(1,
                    "Unknown write handshake(%s): sched_valid=%b sched_i_ready=%b s_wready=%b. Check write scheduler policy macro/source selection.",
                    active_scenario_name,
                    dut.u_axi_write_ooo.sched_o_awvalid,
                    dut.u_axi_write_ooo.sched_i_awready,
                    S_AXI_WREADY);
            end

            M_AXI_AWREADY <= (cycle_cnt[2:1] != 2'b11);
            M_AXI_WREADY <= (cycle_cnt[3:1] != 3'b101);

            if (S_AXI_ARVALID && S_AXI_ARREADY) begin
                ar_burst_count++;
                read_accept_cycle_q.push_back(cycle_cnt);
            end

            if (S_AXI_ARVALID && !S_AXI_ARREADY) begin
                ar_ready_stall_count++;
            end

            if (S_AXI_AWVALID && S_AXI_AWREADY) begin
                aw_burst_count++;
                write_accept_cycle_q.push_back(cycle_cnt);
            end

            if (S_AXI_AWVALID && !S_AXI_AWREADY) begin
                aw_ready_stall_count++;
            end

            if (S_AXI_AWVALID && !dut.u_axi_write_ooo.u_write_aw_queue.i_AWREADY) begin
                dbg_awq_backpressure_count++;
            end

            if (dut.u_axi_write_ooo.queue_o_awvalid &&
                !dut.u_axi_write_ooo.sched_i_awready) begin
                dbg_aw_sched_input_stall_count++;
            end

            if (dut.u_axi_write_ooo.sched_o_awvalid &&
                !dut.u_axi_write_ooo.sched_o_awready) begin
                dbg_aw_sched_output_stall_count++;
            end

            if (dut.u_axi_write_ooo.queue_o_awvalid &&
                !dut.u_axi_write_ooo.order_aw_queue_ready) begin
                dbg_order_aw_queue_stall_count++;
            end

            if (dut.u_axi_write_ooo.sched_o_awvalid &&
                !dut.u_axi_write_ooo.order_aw_scheduler_ready) begin
                dbg_order_aw_sched_wait_count++;
            end

            if (dut.u_axi_write_ooo.sched_o_awvalid &&
                !dut.u_axi_write_ooo.b_aw_scheduler_ready) begin
                dbg_b_aw_sched_stall_count++;
            end

            if (S_AXI_WVALID && !S_AXI_WREADY) begin
                dbg_w_input_stall_count++;
            end

            if (dut.u_axi_write_ooo.sched_o_awvalid && !M_AXI_AWREADY) begin
                dbg_m_aw_ready_stall_count++;
            end

            if (M_AXI_RVALID && !M_AXI_RREADY) begin
                reorder_stall_count++;
            end

            if (M_AXI_AWVALID && M_AXI_AWREADY) begin
                aw_req.id = M_AXI_AWID;
                aw_req.addr = M_AXI_AWADDR;
                aw_req.len = M_AXI_AWLEN;
                aw_req.size = M_AXI_AWSIZE;
                aw_req.burst = M_AXI_AWBURST;
                hp_write_q.push_back(aw_req);
                observed_aw++;
                write_issue_count++;
                write_id_issue_count[M_AXI_AWID]++;
                if (have_last_write_issue_id) begin
                    if (M_AXI_AWID == last_write_issue_id) begin
                        write_same_id_hit_count++;
                        write_same_id_streak++;
                    end
                    else begin
                        write_same_id_miss_count++;
                        write_same_id_streak_sum += write_same_id_streak;
                        write_same_id_streak_samples++;
                        write_same_id_streak = 1;
                    end
                end
                else begin
                    write_same_id_streak = 1;
                end
                if (write_same_id_streak > write_same_id_streak_max)
                    write_same_id_streak_max = write_same_id_streak;
                last_write_issue_id = M_AXI_AWID;
                have_last_write_issue_id = 1'b1;
                display_transaction_log("M_AW_ISSUE", M_AXI_AWID, M_AXI_AWADDR, M_AXI_AWLEN);
            end

            if (M_AXI_WVALID && M_AXI_WREADY) begin
                observed_w_beats++;
                if (M_AXI_WLAST) begin
                    w_burst_count++;
                end
            end

            if (S_AXI_RVALID && S_AXI_RREADY) begin
                observed_read_beats++;
                if (S_AXI_RLAST) begin
                    r_burst_count++;
                    if (read_accept_cycle_q.size() != 0) begin
                        latency = cycle_cnt - read_accept_cycle_q.pop_front();
                        read_latency_sum += latency;
                        read_latency_count++;
                        if (latency > read_latency_max)
                            read_latency_max = latency;
                    end
                end
                if (S_AXI_RRESP != 2'b00) begin
                    $error("Unexpected RRESP %0b at time %0t", S_AXI_RRESP, $time);
                end
            end

            if (S_AXI_BVALID && S_AXI_BREADY) begin
                observed_b++;
                b_resp_count++;
                if (write_accept_cycle_q.size() != 0) begin
                    latency = cycle_cnt - write_accept_cycle_q.pop_front();
                    write_latency_sum += latency;
                    write_latency_count++;
                    if (latency > write_latency_max)
                        write_latency_max = latency;
                end
                if (S_AXI_BRESP != 2'b00) begin
                    $error("Unexpected BRESP %0b at time %0t", S_AXI_BRESP, $time);
                end
            end
        end
    end

    initial begin : perf_periodic_logger
        wait (ARESETn);
        forever begin
            repeat (PERF_LOG_INTERVAL) @(posedge ACLK);
            if (ARESETn && perf_log_enable) begin
                display_perf_snapshot("progress");
            end
        end
    end

    task automatic run_scenario(input tb_axi_ooo_scenario_cfg_t cfg);
        int unsigned timeout;
        begin
            active_num_read_req = cfg.num_read_req;
            active_num_write_req = cfg.num_write_req;
            active_write_case_name = write_case_name(cfg.write_case);
            reset_perf_counters(cfg.name);
            perf_log_enable = 1'b1;
            display_scenario_config(cfg);
            display_perf_snapshot("start");

            fork : stimulus_phase
                begin : stimulus_threads
                    fork
                        begin : send_ar_random
                            tb_axi_req_t ar_req;
                            bit has_ar_req;

                            for (int i=0; i<cfg.num_read_req; i++) begin
                                build_scenario_read_req(cfg, has_ar_req, ar_req);
                                if (has_ar_req) begin
                                    send_ar(ar_req.id, ar_req.addr, ar_req.len);
                                end
                            end
                        end

                        begin : send_aw_random
                            tb_axi_req_t aw_req;

                            for (int i=0; i<cfg.num_write_req; i++) begin
                                build_scenario_write_req(cfg, cfg.write_case, i, aw_req);
                                send_aw(aw_req.id, aw_req.addr, aw_req.len);
                            end
                        end

                        begin : send_w_random
                            tb_axi_req_t w_req;
                            int unsigned sent_w;

                            sent_w = 0;

                            while (sent_w < cfg.num_write_req) begin
                                wait (write_req_q.size() != 0);
                                w_req = write_req_q.pop_front();
                                send_w_burst(w_req.len, scenario_write_data_base(cfg.write_case, cfg, sent_w));
                                sent_w++;
                            end
                        end
                    join
                end

                begin : stimulus_watchdog
                    repeat (SCENARIO_TIMEOUT) @(posedge ACLK);
                    display_perf_snapshot("stimulus_timeout");
                    $fatal(1,
                        "Stimulus timeout(%s): s_ar=%0d/%0d s_aw=%0d/%0d m_aw=%0d/%0d write_req_q=%0d s_wready=%b m_wbeats=%0d/%0d b=%0d/%0d",
                        active_scenario_name,
                        observed_ar, cfg.num_read_req,
                        aw_burst_count, cfg.num_write_req,
                        observed_aw, cfg.num_write_req,
                        write_req_q.size(),
                        S_AXI_WREADY,
                        observed_w_beats, expected_w_beats,
                        observed_b, cfg.num_write_req);
                end
            join_any
            disable stimulus_phase;

            timeout = 0;
            while ((observed_ar < cfg.num_read_req) ||
                   (observed_read_beats < expected_read_beats) ||
                   (observed_aw < cfg.num_write_req) ||
                   (observed_w_beats < expected_w_beats) ||
                   (observed_b < cfg.num_write_req)) begin
                @(posedge ACLK);
                timeout++;
                if (timeout > SCENARIO_TIMEOUT) begin
                    display_perf_snapshot("timeout");
                    $fatal(1,
                        "Timeout(%s): m_ar=%0d/%0d rbeats=%0d/%0d m_aw=%0d/%0d m_wbeats=%0d/%0d b=%0d/%0d",
                        active_scenario_name,
                        observed_ar, cfg.num_read_req,
                        observed_read_beats, expected_read_beats,
                        observed_aw, cfg.num_write_req,
                        observed_w_beats, expected_w_beats,
                        observed_b, cfg.num_write_req);
                end
            end

            repeat (10) @(posedge ACLK);
            display_perf_snapshot("summary");
            perf_log_enable = 1'b0;
        end
    endtask

    initial begin : main_test
        tb_axi_ooo_scenario_cfg_t scenarios[$];
        int scenario_idx;

        init_signals();
        build_default_write_perf_scenarios(scenarios);

        perf_log_fd = $fopen("tb_axi_ooo_top_perf.log", "w");
        if (perf_log_fd == 0) begin
            $error("Failed to open tb_axi_ooo_top_perf.log");
        end
        else begin
            $display("[%0t][TB] Performance log file: tb_axi_ooo_top_perf.log", $time);
            $display("[%0t][TB] Vivado default run 1000ns is too short for this TB. Use run all or at least run %0dns.", $time, MIN_RECOMMENDED_RUN_NS);
            $fdisplay(perf_log_fd, "Performance log file: tb_axi_ooo_top_perf.log");
            $fdisplay(perf_log_fd, "Vivado default run 1000ns is too short for this TB. Use run all or at least run %0dns.", MIN_RECOMMENDED_RUN_NS);
            $fflush(perf_log_fd);
        end

        `ifdef DISPLAY_ALL_SIGNALS
            $dumpfile("tb_axi_ooo_top.vcd");
            $dumpvars(0, tb_axi_ooo_top);
        `endif

        foreach (scenarios[scenario_idx]) begin
            init_signals();
            apply_reset();
            run_scenario(scenarios[scenario_idx]);
        end

        $display("PASS: axi_ooo_controller top performance scenarios completed.");
        if (perf_log_fd != 0) begin
            $fclose(perf_log_fd);
        end
        $finish;
    end

endmodule

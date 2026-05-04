`include "axi_include_top.vh"
import axi_pkg::*;

module axi_ooo_aw_write_order_queue #(
    parameter int DATA_WIDTH = 32,
    parameter int ID_WIDTH = 4,
    parameter int LEN_WIDTH = 8,
    parameter int NUM_WRITE_ORDER_QUEUE_AW = 4,
    parameter int WRITE_MAX_BURST_BEATS = 8,
    parameter int WRITE_SEQ_WIDTH = 16
) (
    input ACLK,
    input ARESETn,


    input aw_queue_fire,
    output aw_queue_ready,
    input [ID_WIDTH-1:0] i_queue_AWID,
    input [LEN_WIDTH-1:0] i_queue_AWLEN,
    input [2:0] i_queue_AWSIZE,
    input [1:0] i_queue_AWBURST,

    input i_WVALID,
    output i_WREADY,

    input [DATA_WIDTH-1:0] i_WDATA,
    input [DATA_WIDTH/8-1:0] i_WSTRB,
    input i_WLAST,

    input aw_scheduler_fire,
    output aw_scheduler_ready,
    input [ID_WIDTH-1:0] i_AWID,
    input [LEN_WIDTH-1:0] i_AWLEN,
    input [2:0] i_AWSIZE,
    input [1:0] i_AWBURST,


    output reg [DATA_WIDTH-1:0] o_WDATA,
    output reg [DATA_WIDTH/8-1:0] o_WSTRB,
    output reg o_WLAST,

    output reg o_WVALID,
    input o_WREADY
);
    localparam int MAX_BURST_BEATS = WRITE_MAX_BURST_BEATS;
    localparam int NUM_WRITE_ORDER_QUEUE_W = NUM_WRITE_ORDER_QUEUE_AW * MAX_BURST_BEATS;
    localparam int AW_INDEX_WIDTH = (NUM_WRITE_ORDER_QUEUE_AW <= 1) ? 1 : $clog2(NUM_WRITE_ORDER_QUEUE_AW);
    localparam int W_INDEX_WIDTH = (NUM_WRITE_ORDER_QUEUE_W <= 1) ? 1 : $clog2(NUM_WRITE_ORDER_QUEUE_W);
    localparam int BEAT_CNT_WIDTH = LEN_WIDTH + 1;
    localparam int SEQ_WIDTH = WRITE_SEQ_WIDTH;  // SEQ : WID 대신 순서대로 SEQ 번호를 붙임.

    // 실제 queue와 scheduler 출력을 비교하여 계산함.

    // reg 선언
    reg [ID_WIDTH-1:0] reg_queue_AWID[0:NUM_WRITE_ORDER_QUEUE_AW-1];
    reg [LEN_WIDTH-1:0] reg_queue_AWLEN[0:NUM_WRITE_ORDER_QUEUE_AW-1];
    reg [2:0] reg_queue_AWSIZE[0:NUM_WRITE_ORDER_QUEUE_AW-1];
    reg [1:0] reg_queue_AWBURST[0:NUM_WRITE_ORDER_QUEUE_AW-1];

    // 추가 1 : 해당 queue가 valid 한지, w가 끝났는지 표기
    reg reg_queue_valid[0:NUM_WRITE_ORDER_QUEUE_AW-1];
    reg reg_w_done[0:NUM_WRITE_ORDER_QUEUE_AW-1];
    reg [BEAT_CNT_WIDTH-1:0] reg_w_count[0:NUM_WRITE_ORDER_QUEUE_AW-1];

    // 추가 2 : 해당 queue가 얼마나 오래되었는지 seq로 표기함.
    reg [SEQ_WIDTH-1:0] reg_queue_seq[0:NUM_WRITE_ORDER_QUEUE_AW-1];

    reg [DATA_WIDTH-1:0] reg_WDATA[0:NUM_WRITE_ORDER_QUEUE_W-1];
    reg [DATA_WIDTH/8-1:0] reg_WSTRB[0:NUM_WRITE_ORDER_QUEUE_W-1];
    reg reg_WLAST[0:NUM_WRITE_ORDER_QUEUE_W-1];

    // 상태 관련 서술 
    reg has_empty;
    reg has_w_target;
    reg has_sched_target;
    reg has_seq_min;

    reg [AW_INDEX_WIDTH-1:0] empty_index;
    reg [AW_INDEX_WIDTH-1:0] w_target_index;
    reg [AW_INDEX_WIDTH-1:0] sched_target_index;
    reg [SEQ_WIDTH-1:0] min_w_seq;
    reg [SEQ_WIDTH-1:0] min_sched_seq;

    reg send_active;
    reg [AW_INDEX_WIDTH-1:0] send_index;
    reg [BEAT_CNT_WIDTH-1:0] send_beat;
    reg [BEAT_CNT_WIDTH-1:0] send_total;
    reg [SEQ_WIDTH-1:0] next_seq;

    reg [W_INDEX_WIDTH-1:0] output_read_index_reg;
    reg [W_INDEX_WIDTH-1:0] output_read_index_next;

    reg has_empty_next;
    reg has_w_target_next;
    reg has_sched_target_next;
    reg has_seq_min_next;
    reg entry_is_new_aw;
    reg entry_valid_next;
    reg entry_w_done_next;
    reg [BEAT_CNT_WIDTH-1:0] entry_w_count_next;
    reg [AW_INDEX_WIDTH-1:0] empty_index_next;
    reg [AW_INDEX_WIDTH-1:0] w_target_index_next;
    reg [AW_INDEX_WIDTH-1:0] sched_target_index_next;
    reg [SEQ_WIDTH-1:0] min_w_seq_next;
    reg [SEQ_WIDTH-1:0] min_sched_seq_next;

    // AW / W I/O 관련 추가.
    wire aw_queue_in = aw_queue_fire && aw_queue_ready;
    wire aw_scheduler_in = aw_scheduler_fire && aw_scheduler_ready;
    wire w_in = i_WVALID && i_WREADY;
    wire w_out = o_WVALID && o_WREADY;

    // 추가 3 : 
    wire [BEAT_CNT_WIDTH-1:0] w_target_total = {1'b0, reg_queue_AWLEN[w_target_index]} + 1'b1;  // 실제 보내야 하는 BEAT 수
    wire expected_wlast = (reg_w_count[w_target_index] == reg_queue_AWLEN[w_target_index]);
    wire [W_INDEX_WIDTH-1:0] w_write_index =
        W_INDEX_WIDTH'(w_target_index * MAX_BURST_BEATS) + W_INDEX_WIDTH'(reg_w_count[w_target_index]);
    wire [W_INDEX_WIDTH-1:0] w_read_index =
        W_INDEX_WIDTH'(send_index * MAX_BURST_BEATS) + W_INDEX_WIDTH'(send_beat);

    // 출력 관련 서술
    assign aw_queue_ready = has_empty;
    assign aw_scheduler_ready = !send_active && has_sched_target;
    assign i_WREADY = has_w_target && (reg_w_count[w_target_index] < w_target_total);

    // 수정, 마진 개선
    always @(*) begin
        output_read_index_next = output_read_index_reg;

        if (aw_scheduler_in) begin
            output_read_index_next = W_INDEX_WIDTH'(sched_target_index<<$clog2(MAX_BURST_BEATS));
        end
        else if (send_active && w_out && (send_beat != (send_total - 1'b1))) begin
            output_read_index_next =
                W_INDEX_WIDTH'(send_index<<$clog2(MAX_BURST_BEATS)) +
                W_INDEX_WIDTH'(send_beat + 1'b1);
        end
    end

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            output_read_index_reg <= '0;
        end
        else begin
            output_read_index_reg <= output_read_index_next;
        end
    end

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            o_WDATA <= '0;
            o_WSTRB <= '0;
            o_WLAST <= OFF;
            o_WVALID <= OFF;
        end
        else begin
            if (o_WREADY || !o_WVALID) begin
                if (aw_scheduler_in) begin
                    o_WDATA <= reg_WDATA[output_read_index_reg];
                    o_WSTRB <= reg_WSTRB[output_read_index_reg];
                    o_WLAST <= reg_WLAST[output_read_index_reg];
                    o_WVALID <= ON;
                end
                else if (send_active) begin
                    if (w_out) begin
                        if (send_beat == (send_total - 1'b1)) begin
                            o_WDATA <= '0;
                            o_WSTRB <= '0;
                            o_WLAST <= OFF;
                            o_WVALID <= OFF;
                        end
                        else begin
                            o_WDATA <= reg_WDATA[output_read_index_reg];
                            o_WSTRB <= reg_WSTRB[output_read_index_reg];
                            o_WLAST <= reg_WLAST[output_read_index_reg];
                            o_WVALID <= ON;
                        end
                    end
                    else begin
                        o_WDATA <= reg_WDATA[w_read_index];
                        o_WSTRB <= reg_WSTRB[w_read_index];
                        o_WLAST <= reg_WLAST[w_read_index];
                        o_WVALID <= ON;
                    end
                end
                else begin
                    o_WDATA <= '0;
                    o_WSTRB <= '0;
                    o_WLAST <= OFF;
                    o_WVALID <= OFF;
                end
            end
        end
    end


    // 현재 상태 출력하는 combinational logic
    always @(*) begin
        has_empty_next = OFF;
        has_w_target_next = OFF;
        has_sched_target_next = OFF;
        has_seq_min_next = OFF;
        empty_index_next = '0;
        w_target_index_next = '0;
        sched_target_index_next = '0;
        min_w_seq_next = '1;
        min_sched_seq_next = '1;
        entry_is_new_aw = OFF;
        entry_valid_next = OFF;
        entry_w_done_next = OFF;
        entry_w_count_next = '0;

        for (int i = 0; i < NUM_WRITE_ORDER_QUEUE_AW; i++) begin
            entry_is_new_aw = aw_queue_in && (AW_INDEX_WIDTH'(i) == empty_index);
            entry_valid_next = reg_queue_valid[i];
            entry_w_done_next = reg_w_done[i];
            entry_w_count_next = reg_w_count[i];

            if (entry_is_new_aw) begin
                entry_valid_next = ON;
                entry_w_done_next = OFF;
                entry_w_count_next = '0;
            end

            if (w_in && (AW_INDEX_WIDTH'(i) == w_target_index)) begin
                entry_w_count_next = reg_w_count[i] + 1'b1;
                if (i_WLAST || (reg_w_count[i] == reg_queue_AWLEN[i])) begin
                    entry_w_done_next = ON;
                end
            end

            if (w_out && (AW_INDEX_WIDTH'(i) == send_index) &&
                (send_beat == (send_total - 1'b1))) begin
                entry_valid_next = OFF;
                entry_w_done_next = OFF;
                entry_w_count_next = '0;
            end

            if (!entry_valid_next && !has_empty_next) begin
                has_empty_next = ON;
                empty_index_next = AW_INDEX_WIDTH'(i);
            end

            if (entry_valid_next && !entry_w_done_next && !entry_is_new_aw) begin
                if (!has_w_target_next || (reg_queue_seq[i] < min_w_seq_next)) begin
                    has_seq_min_next = ON;
                    has_w_target_next = ON;
                    min_w_seq_next = reg_queue_seq[i];
                    w_target_index_next = AW_INDEX_WIDTH'(i);
                end
            end

            if (entry_valid_next && entry_w_done_next &&
                !entry_is_new_aw &&
                (reg_queue_AWID[i] == i_AWID) &&
                (reg_queue_AWLEN[i] == i_AWLEN) &&
                (reg_queue_AWSIZE[i] == i_AWSIZE) &&
                (reg_queue_AWBURST[i] == i_AWBURST)) begin
                if (!has_sched_target_next || (reg_queue_seq[i] < min_sched_seq_next)) begin
                    has_sched_target_next = ON;
                    min_sched_seq_next = reg_queue_seq[i];
                    sched_target_index_next = AW_INDEX_WIDTH'(i);
                end
            end
        end
    end

    // state 전이 (FSM)
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            has_empty <= OFF;
            has_w_target <= OFF;
            has_sched_target <= OFF;
            has_seq_min <= OFF;
            empty_index <= '0;
            w_target_index <= '0;
            sched_target_index <= '0;
            min_w_seq <= '0;
            min_sched_seq <= '0;
        end
        else begin
            has_empty <= has_empty_next;
            has_w_target <= has_w_target_next;
            has_sched_target <= has_sched_target_next;
            has_seq_min <= has_seq_min_next;
            empty_index <= empty_index_next;
            w_target_index <= w_target_index_next;
            sched_target_index <= sched_target_index_next;
            min_w_seq <= min_w_seq_next;
            min_sched_seq <= min_sched_seq_next;
        end
    end

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            next_seq <= '0;
            send_active <= OFF;
            send_index <= '0;
            send_beat <= '0;
            send_total <= '0;

            for (int i=0; i<NUM_WRITE_ORDER_QUEUE_AW; i++) begin
                reg_queue_AWID[i] <= '0;
                reg_queue_AWLEN[i] <= '0;
                reg_queue_AWSIZE[i] <= '0;
                reg_queue_AWBURST[i] <= '0;
                reg_queue_valid[i] <= OFF;
                reg_w_done[i] <= OFF;
                reg_w_count[i] <= '0;
                reg_queue_seq[i] <= '0;
            end

            for (int i=0; i<NUM_WRITE_ORDER_QUEUE_W; i++) begin
                reg_WDATA[i] <= '0;
                reg_WSTRB[i] <= '0;
                reg_WLAST[i] <= OFF;
            end
        end
        else begin
            if (aw_queue_in&&has_empty) begin
                reg_queue_AWID[empty_index] <= i_queue_AWID;
                reg_queue_AWLEN[empty_index] <= i_queue_AWLEN;
                reg_queue_AWSIZE[empty_index] <= i_queue_AWSIZE;
                reg_queue_AWBURST[empty_index] <= i_queue_AWBURST;
                reg_queue_valid[empty_index] <= ON;
                reg_w_done[empty_index] <= OFF;
                reg_w_count[empty_index] <= '0;
                reg_queue_seq[empty_index] <= next_seq;
                next_seq <= next_seq + 1'b1;
            end

            if (w_in&&has_w_target) begin
                reg_WDATA[w_write_index] <= i_WDATA;
                reg_WSTRB[w_write_index] <= i_WSTRB;
                reg_WLAST[w_write_index] <= i_WLAST || expected_wlast;
                reg_w_count[w_target_index] <= reg_w_count[w_target_index] + 1'b1;

                if (i_WLAST || expected_wlast) begin
                    reg_w_done[w_target_index] <= ON;
                end
            end

            if (aw_scheduler_in) begin  // 스케줄러가 보내도 된다고 해야 보낼 수 있다는 점 기억하기.
                send_active <= ON;
                send_index <= sched_target_index;
                send_beat <= '0;
                send_total <= {1'b0, i_AWLEN} + 1'b1;
            end
            else if (w_out) begin
                if (send_beat == (send_total - 1'b1)) begin
                    send_active <= OFF;
                    send_beat <= '0;
                    send_total <= '0;
                    reg_queue_valid[send_index] <= OFF;
                    reg_w_done[send_index] <= OFF;
                    reg_w_count[send_index] <= '0;
                end
                else begin
                    send_beat <= send_beat + 1'b1;
                end
            end
        end
    end

    `ifdef INITIAL_REG_RESET
        initial begin
            next_seq = '0;
            send_active = OFF;
            send_index = '0;
            send_beat = '0;
            send_total = '0;
            o_WDATA = '0;
            o_WSTRB = '0;
            o_WLAST = OFF;
            o_WVALID = OFF;
            output_read_index_reg = '0;
            output_read_index_next = '0;
            for (int i=0; i<NUM_WRITE_ORDER_QUEUE_AW; i++) begin
                reg_queue_AWID[i] = '0;
                reg_queue_AWLEN[i] = '0;
                reg_queue_AWSIZE[i] = '0;
                reg_queue_AWBURST[i] = '0;
                reg_queue_valid[i] = OFF;
                reg_w_done[i] = OFF;
                reg_w_count[i] = '0;
                reg_queue_seq[i] = '0;
            end

            for (int i=0; i<NUM_WRITE_ORDER_QUEUE_W; i++) begin
                reg_WDATA[i] = '0;
                reg_WSTRB[i] = '0;
                reg_WLAST[i] = OFF;
            end

            has_empty = OFF;
            has_w_target = OFF;
            has_sched_target = OFF;
            has_seq_min = OFF;
            has_empty_next = OFF;
            has_w_target_next = OFF;
            has_sched_target_next = OFF;
            has_seq_min_next = OFF;
            entry_is_new_aw = OFF;
            entry_valid_next = OFF;
            entry_w_done_next = OFF;
            entry_w_count_next = '0;
            empty_index = '0;
            w_target_index = '0;
            sched_target_index = '0;
            empty_index_next = '0;
            w_target_index_next = '0;
            sched_target_index_next = '0;
            min_w_seq = '0;
            min_sched_seq = '0;
            min_w_seq_next = '0;
            min_sched_seq_next = '0;
        end
    `endif








endmodule

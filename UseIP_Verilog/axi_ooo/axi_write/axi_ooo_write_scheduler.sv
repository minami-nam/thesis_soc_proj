`include "axi_include_top.vh"
import axi_pkg::*;

module axi_ooo_aw_scheduler #(
    parameter int ADDR_WIDTH = 32,
    parameter int ID_WIDTH = 4,
    parameter int LEN_WIDTH = 8,
    parameter int NUM_WRITE_SCHEDULER = 4,
    parameter int WRITE_KEEP_MAX_LENGTH = 8
) (
    input ACLK,
    input ARESETn,
    
    input [ID_WIDTH-1:0] i_AWID,
    input [ADDR_WIDTH-1:0] i_AWADDR,
    input [LEN_WIDTH-1:0] i_AWLEN,
    input [2:0] i_AWSIZE,
    input [1:0] i_AWBURST,

    input i_AWVALID,
    output i_AWREADY,

    output [ID_WIDTH-1:0] o_AWID,
    output [ADDR_WIDTH-1:0] o_AWADDR,
    output [LEN_WIDTH-1:0] o_AWLEN,
    output [2:0] o_AWSIZE,
    output [1:0] o_AWBURST,
   

    input o_AWREADY,
    output o_AWVALID
);

    `ifdef WRITE_MINAMI_CUSTOM_PRIORITY_ADAPTIVE_CUSTOM
        `define WRITE_MINAMI_PRIORITY_ADAPTIVE_CUSTOM
    `endif

    `ifdef WRITE_MINAMI_CUSTOM
        localparam KEEP_MAX_LENGTH = WRITE_KEEP_MAX_LENGTH;
        localparam CNT_WIDTH = $clog2(KEEP_MAX_LENGTH);
        localparam ID_MAX = (1<<ID_WIDTH);
        localparam INDEX_WIDTH = (NUM_WRITE_SCHEDULER <= 1) ? 1 : $clog2(NUM_WRITE_SCHEDULER);


        wire aw_in = i_AWVALID & i_AWREADY;
        wire aw_out = o_AWREADY & o_AWVALID;
        

        reg [CNT_WIDTH:0] cnt_awid_ocheck[0:ID_MAX-1];
        reg [CNT_WIDTH:0] cnt_awid_icheck[0:ID_MAX-1];
        reg [ID_WIDTH-1:0] previous_o_awid;

        reg [ID_WIDTH-1:0] reg_AWID[0:NUM_WRITE_SCHEDULER-1];
        reg [ADDR_WIDTH-1:0] reg_AWADDR[0:NUM_WRITE_SCHEDULER-1];
        reg [LEN_WIDTH-1:0] reg_AWLEN[0:NUM_WRITE_SCHEDULER-1];
        reg [2:0] reg_AWSIZE[0:NUM_WRITE_SCHEDULER-1];
        reg [1:0] reg_AWBURST[0:NUM_WRITE_SCHEDULER-1];
        reg reg_valid[0:NUM_WRITE_SCHEDULER-1];

        reg cache_has_empty;
        reg cache_has_valid;
        reg has_same_id;
        reg has_other_id;
        reg max_count_found;
        reg [INDEX_WIDTH-1:0] fill_index;
        reg [INDEX_WIDTH-1:0] same_id_index;
        reg [INDEX_WIDTH-1:0] max_count_index;
        reg [CNT_WIDTH:0] max_count_value;

        wire [INDEX_WIDTH-1:0] issue_index;
        wire [INDEX_WIDTH-1:0] write_index;

        wire limit_reached = (cnt_awid_ocheck[previous_o_awid] >= KEEP_MAX_LENGTH);
        wire is_ocnt_max = (cnt_awid_ocheck[o_AWID]==KEEP_MAX_LENGTH) ? ON : OFF;
        
        // 각 ID 별로 몇 번 Data Out이 진행되었는지 체크 + previous 값도 체크

        assign i_AWREADY = (cache_has_empty || aw_out) && (!o_AWVALID || o_AWREADY);
        assign o_AWVALID = cache_has_valid;
        assign o_AWID = (o_AWVALID) ? reg_AWID[issue_index] : '0;
        assign o_AWADDR = (o_AWVALID) ? reg_AWADDR[issue_index] : '0;
        assign o_AWLEN = (o_AWVALID) ? reg_AWLEN[issue_index] : '0;
        assign o_AWSIZE = (o_AWVALID) ? reg_AWSIZE[issue_index] : '0;
        assign o_AWBURST = (o_AWVALID) ? reg_AWBURST[issue_index] : '0;
        assign issue_index = (limit_reached && has_other_id) ? max_count_index :
                             (has_same_id) ? same_id_index : max_count_index;
        assign write_index = (!cache_has_empty && aw_out) ? issue_index : fill_index;

        // state 판별을 위한 logic
        always @(*) begin
            cache_has_empty = OFF;
            cache_has_valid = OFF;
            has_same_id = OFF;
            has_other_id = OFF;
            max_count_found = OFF;
            fill_index = '0;
            same_id_index = '0;
            max_count_index = '0;
            max_count_value = '0;

            for (int i=0; i<NUM_WRITE_SCHEDULER; i++) begin
                if (!reg_valid[i] && !cache_has_empty) begin
                    cache_has_empty = ON;
                    fill_index = INDEX_WIDTH'(i);
                end

                if (reg_valid[i]) begin
                    cache_has_valid = ON;

                    if ((reg_AWID[i] == previous_o_awid) && !has_same_id) begin
                        has_same_id = ON;
                        same_id_index = INDEX_WIDTH'(i);
                    end

                    if (reg_AWID[i] != previous_o_awid) begin
                        has_other_id = ON;
                    end

                    if (!max_count_found ||
                        (cnt_awid_icheck[reg_AWID[i]] > max_count_value)) begin
                        max_count_found = ON;
                        max_count_value = cnt_awid_icheck[reg_AWID[i]];
                        max_count_index = INDEX_WIDTH'(i);
                    end
                end
            end
        end


        // Previous AWID Checker
        always @(posedge ACLK or negedge ARESETn) begin
            if (!ARESETn) previous_o_awid <= '0;
            else if (aw_out) previous_o_awid <= o_AWID;
        end

        // Data out Counter
        

        always @(posedge ACLK or negedge ARESETn) begin
            if (!ARESETn) begin
                for (int i=0; i<ID_MAX; i++) begin : reset_reg_ocheck
                    cnt_awid_ocheck[i] <= '0;
                end
            end
            else begin
                if (aw_out && (previous_o_awid != o_AWID)) begin
                    cnt_awid_ocheck[o_AWID] <= 1'b1;
                end
                else if ((aw_out)&(!is_ocnt_max)) begin   // 아직 cnt가 KEEP_MAX_LENGTH 값에 도달하지 않았을 경우
                    cnt_awid_ocheck[o_AWID] <= cnt_awid_ocheck[o_AWID] + 1'b1;
                end
                else if ((aw_out)&is_ocnt_max) begin  // cnt가 KEEP_MAX_LENGTH 값에 도달한 경우
                    cnt_awid_ocheck[o_AWID] <= '0;
                end
            end
        end

        // Current Data Counter
        always @(posedge ACLK or negedge ARESETn) begin
            if (!ARESETn) begin
                for (int i=0; i<ID_MAX; i++) begin : reset_reg_icheck
                    cnt_awid_icheck[i] <= '0;
                end
            end
            else begin
                case({aw_in, aw_out})
                    2'b00 : begin
                        cnt_awid_icheck[i_AWID] <= cnt_awid_icheck[i_AWID];
                        cnt_awid_icheck[o_AWID] <= cnt_awid_icheck[o_AWID];
                    end
                    2'b01 : begin
                        if (cnt_awid_icheck[o_AWID]!=0) begin
                            cnt_awid_icheck[o_AWID] <= cnt_awid_icheck[o_AWID] - 1;
                        end
                    end
                    2'b10 : begin
                        if (cnt_awid_icheck[i_AWID]<KEEP_MAX_LENGTH) begin
                            cnt_awid_icheck[i_AWID] <= cnt_awid_icheck[i_AWID] + 1'b1;
                        end
                    end
                    2'b11 : begin
                        if (i_AWID==o_AWID) begin
                            cnt_awid_icheck[o_AWID] <= cnt_awid_icheck[o_AWID];
                        end
                        else begin
                            if (cnt_awid_icheck[o_AWID]!=0) cnt_awid_icheck[o_AWID] <= cnt_awid_icheck[o_AWID] - 1;
                            else cnt_awid_icheck[o_AWID] <= '0;
                            if (cnt_awid_icheck[i_AWID]<KEEP_MAX_LENGTH) cnt_awid_icheck[i_AWID] <= cnt_awid_icheck[i_AWID] + 1'b1;
                            else cnt_awid_icheck[i_AWID] <= KEEP_MAX_LENGTH;
                        end
                    end
                endcase
            end
        end

        // 해당 조건들을 사용하여 Starvation 방지를 위한 Policy Logic 설계. 

        always @(posedge ACLK or negedge ARESETn) begin
            if (!ARESETn) begin
                for (int i=0; i<NUM_WRITE_SCHEDULER; i++) begin : reset_aw_cache
                    reg_AWID[i] <= '0;
                    reg_AWADDR[i] <= '0;
                    reg_AWLEN[i] <= '0;
                    reg_AWSIZE[i] <= '0;
                    reg_AWBURST[i] <= '0;
                    reg_valid[i] <= OFF;
                end
            end
            else begin
                if (aw_out) begin
                    reg_valid[issue_index] <= OFF;
                end

                if (aw_in) begin
                    reg_AWID[write_index] <= i_AWID;
                    reg_AWADDR[write_index] <= i_AWADDR;
                    reg_AWLEN[write_index] <= i_AWLEN;
                    reg_AWSIZE[write_index] <= i_AWSIZE;
                    reg_AWBURST[write_index] <= i_AWBURST;
                    reg_valid[write_index] <= ON;
                end
            end
        end



        `ifdef INITIAL_REG_RESET
            initial begin
                for (int i=0; i<ID_MAX; i++) begin
                    cnt_awid_ocheck[i] = '0;
                    cnt_awid_icheck[i] = '0;
                end

                for (int i=0; i<NUM_WRITE_SCHEDULER; i++) begin
                    reg_AWID[i] = '0;
                    reg_AWADDR[i] = '0;
                    reg_AWLEN[i] = '0;
                    reg_AWSIZE[i] = '0;
                    reg_AWBURST[i] = '0;
                    reg_valid[i] = OFF;
                end

                previous_o_awid = '0;
                cache_has_empty = OFF;
                cache_has_valid = OFF;
                has_same_id = OFF;
                has_other_id = OFF;
                max_count_found = OFF;
                fill_index = '0;
                same_id_index = '0;
                max_count_index = '0;
                max_count_value = '0;
            end
        `endif

    `elsif WRITE_MINAMI_AGING
        localparam KEEP_MAX_LENGTH = WRITE_KEEP_MAX_LENGTH;
        localparam CNT_WIDTH = $clog2(KEEP_MAX_LENGTH);
        localparam ID_MAX = (1<<ID_WIDTH);
        localparam INDEX_WIDTH = (NUM_WRITE_SCHEDULER <= 1) ? 1 : $clog2(NUM_WRITE_SCHEDULER);
        localparam AGE_THRESHOLD = WRITE_KEEP_MAX_LENGTH;

        wire aw_in = i_AWVALID & i_AWREADY;
        wire aw_out = o_AWREADY & o_AWVALID;

        reg [CNT_WIDTH:0] cnt_awid_ocheck[0:ID_MAX-1];
        reg [CNT_WIDTH:0] cnt_awid_icheck[0:ID_MAX-1];
        reg [ID_WIDTH-1:0] previous_o_awid;

        reg [ID_WIDTH-1:0] reg_AWID[0:NUM_WRITE_SCHEDULER-1];
        reg [ADDR_WIDTH-1:0] reg_AWADDR[0:NUM_WRITE_SCHEDULER-1];
        reg [LEN_WIDTH-1:0] reg_AWLEN[0:NUM_WRITE_SCHEDULER-1];
        reg [2:0] reg_AWSIZE[0:NUM_WRITE_SCHEDULER-1];
        reg [1:0] reg_AWBURST[0:NUM_WRITE_SCHEDULER-1];
        reg [CNT_WIDTH:0] reg_age[0:NUM_WRITE_SCHEDULER-1];
        reg reg_valid[0:NUM_WRITE_SCHEDULER-1];

        reg cache_has_empty;
        reg cache_has_valid;
        reg has_aging_same_id;
        reg has_aging_other_id;
        reg has_nonaging_same_id;
        reg has_nonaging_other_id;
        reg [INDEX_WIDTH-1:0] fill_index;
        reg [INDEX_WIDTH-1:0] aging_same_id_index;
        reg [INDEX_WIDTH-1:0] aging_other_id_index;
        reg [INDEX_WIDTH-1:0] nonaging_same_id_index;
        reg [INDEX_WIDTH-1:0] nonaging_other_id_index;
        reg [CNT_WIDTH:0] aging_same_age_value;
        reg [CNT_WIDTH:0] aging_other_age_value;
        reg [CNT_WIDTH:0] nonaging_same_age_value;
        reg [CNT_WIDTH:0] nonaging_other_count_value;

        wire [INDEX_WIDTH-1:0] aging_issue_index;
        wire [INDEX_WIDTH-1:0] nonaging_issue_index;
        wire [INDEX_WIDTH-1:0] issue_index;
        wire [INDEX_WIDTH-1:0] write_index;

        wire limit_reached = (cnt_awid_ocheck[previous_o_awid] >= KEEP_MAX_LENGTH);
        wire is_ocnt_max = (cnt_awid_ocheck[o_AWID] == KEEP_MAX_LENGTH) ? ON : OFF;
        wire has_aging_candidate = has_aging_same_id || has_aging_other_id;

        assign i_AWREADY = (cache_has_empty || aw_out) && (!o_AWVALID || o_AWREADY);
        assign o_AWVALID = cache_has_valid;
        assign o_AWID = (o_AWVALID) ? reg_AWID[issue_index] : '0;
        assign o_AWADDR = (o_AWVALID) ? reg_AWADDR[issue_index] : '0;
        assign o_AWLEN = (o_AWVALID) ? reg_AWLEN[issue_index] : '0;
        assign o_AWSIZE = (o_AWVALID) ? reg_AWSIZE[issue_index] : '0;
        assign o_AWBURST = (o_AWVALID) ? reg_AWBURST[issue_index] : '0;

        assign aging_issue_index =
            (!limit_reached && has_aging_same_id) ? aging_same_id_index :
            (has_aging_other_id) ? aging_other_id_index : aging_same_id_index;
        assign nonaging_issue_index =
            (!limit_reached && has_nonaging_same_id) ? nonaging_same_id_index :
            (has_nonaging_other_id) ? nonaging_other_id_index : nonaging_same_id_index;
        assign issue_index = (has_aging_candidate) ? aging_issue_index : nonaging_issue_index;
        assign write_index = (!cache_has_empty && aw_out) ? issue_index : fill_index;

        always @(*) begin
            cache_has_empty = OFF;
            cache_has_valid = OFF;
            has_aging_same_id = OFF;
            has_aging_other_id = OFF;
            has_nonaging_same_id = OFF;
            has_nonaging_other_id = OFF;
            fill_index = '0;
            aging_same_id_index = '0;
            aging_other_id_index = '0;
            nonaging_same_id_index = '0;
            nonaging_other_id_index = '0;
            aging_same_age_value = '0;
            aging_other_age_value = '0;
            nonaging_same_age_value = '0;
            nonaging_other_count_value = '0;

            for (int i=0; i<NUM_WRITE_SCHEDULER; i++) begin
                if (!reg_valid[i] && !cache_has_empty) begin
                    cache_has_empty = ON;
                    fill_index = INDEX_WIDTH'(i);
                end

                if (reg_valid[i]) begin
                    cache_has_valid = ON;

                    if (reg_age[i] >= AGE_THRESHOLD) begin
                        if (reg_AWID[i] == previous_o_awid) begin
                            if (!has_aging_same_id || (reg_age[i] > aging_same_age_value)) begin
                                has_aging_same_id = ON;
                                aging_same_age_value = reg_age[i];
                                aging_same_id_index = INDEX_WIDTH'(i);
                            end
                        end
                        else begin
                            if (!has_aging_other_id || (reg_age[i] > aging_other_age_value)) begin
                                has_aging_other_id = ON;
                                aging_other_age_value = reg_age[i];
                                aging_other_id_index = INDEX_WIDTH'(i);
                            end
                        end
                    end
                    else begin
                        if (reg_AWID[i] == previous_o_awid) begin
                            if (!has_nonaging_same_id || (reg_age[i] > nonaging_same_age_value)) begin
                                has_nonaging_same_id = ON;
                                nonaging_same_age_value = reg_age[i];
                                nonaging_same_id_index = INDEX_WIDTH'(i);
                            end
                        end
                        else begin
                            if (!has_nonaging_other_id ||
                                (cnt_awid_icheck[reg_AWID[i]] > nonaging_other_count_value)) begin
                                has_nonaging_other_id = ON;
                                nonaging_other_count_value = cnt_awid_icheck[reg_AWID[i]];
                                nonaging_other_id_index = INDEX_WIDTH'(i);
                            end
                        end
                    end
                end
            end
        end

        always @(posedge ACLK or negedge ARESETn) begin
            if (!ARESETn) previous_o_awid <= '0;
            else if (aw_out) previous_o_awid <= o_AWID;
        end

        always @(posedge ACLK or negedge ARESETn) begin
            if (!ARESETn) begin
                for (int i=0; i<ID_MAX; i++) begin : aging_reset_reg_ocheck
                    cnt_awid_ocheck[i] <= '0;
                end
            end
            else begin
                if (aw_out && (previous_o_awid != o_AWID)) begin
                    cnt_awid_ocheck[o_AWID] <= 1'b1;
                end
                else if ((aw_out) && (!is_ocnt_max)) begin
                    cnt_awid_ocheck[o_AWID] <= cnt_awid_ocheck[o_AWID] + 1'b1;
                end
                else if ((aw_out) && is_ocnt_max) begin
                    cnt_awid_ocheck[o_AWID] <= '0;
                end
            end
        end

        always @(posedge ACLK or negedge ARESETn) begin
            if (!ARESETn) begin
                for (int i=0; i<ID_MAX; i++) begin : aging_reset_reg_icheck
                    cnt_awid_icheck[i] <= '0;
                end
            end
            else begin
                case({aw_in, aw_out})
                    2'b00 : begin
                        cnt_awid_icheck[i_AWID] <= cnt_awid_icheck[i_AWID];
                        cnt_awid_icheck[o_AWID] <= cnt_awid_icheck[o_AWID];
                    end
                    2'b01 : begin
                        if (cnt_awid_icheck[o_AWID] != 0) begin
                            cnt_awid_icheck[o_AWID] <= cnt_awid_icheck[o_AWID] - 1'b1;
                        end
                    end
                    2'b10 : begin
                        if (cnt_awid_icheck[i_AWID] < KEEP_MAX_LENGTH) begin
                            cnt_awid_icheck[i_AWID] <= cnt_awid_icheck[i_AWID] + 1'b1;
                        end
                    end
                    2'b11 : begin
                        if (i_AWID == o_AWID) begin
                            cnt_awid_icheck[o_AWID] <= cnt_awid_icheck[o_AWID];
                        end
                        else begin
                            if (cnt_awid_icheck[o_AWID] != 0) cnt_awid_icheck[o_AWID] <= cnt_awid_icheck[o_AWID] - 1'b1;
                            else cnt_awid_icheck[o_AWID] <= '0;
                            if (cnt_awid_icheck[i_AWID] < KEEP_MAX_LENGTH) cnt_awid_icheck[i_AWID] <= cnt_awid_icheck[i_AWID] + 1'b1;
                            else cnt_awid_icheck[i_AWID] <= KEEP_MAX_LENGTH;
                        end
                    end
                endcase
            end
        end

        always @(posedge ACLK or negedge ARESETn) begin
            if (!ARESETn) begin
                for (int i=0; i<NUM_WRITE_SCHEDULER; i++) begin : aging_reset_aw_cache
                    reg_AWID[i] <= '0;
                    reg_AWADDR[i] <= '0;
                    reg_AWLEN[i] <= '0;
                    reg_AWSIZE[i] <= '0;
                    reg_AWBURST[i] <= '0;
                    reg_age[i] <= '0;
                    reg_valid[i] <= OFF;
                end
            end
            else begin
                for (int i=0; i<NUM_WRITE_SCHEDULER; i++) begin
                    if (reg_valid[i]) begin
                        if (aw_out && (INDEX_WIDTH'(i) == issue_index)) begin
                            reg_age[i] <= '0;
                        end
                        else if (reg_age[i] < AGE_THRESHOLD) begin
                            reg_age[i] <= reg_age[i] + 1'b1;
                        end
                    end
                end

                if (aw_out) begin
                    reg_valid[issue_index] <= OFF;
                end

                if (aw_in) begin
                    reg_AWID[write_index] <= i_AWID;
                    reg_AWADDR[write_index] <= i_AWADDR;
                    reg_AWLEN[write_index] <= i_AWLEN;
                    reg_AWSIZE[write_index] <= i_AWSIZE;
                    reg_AWBURST[write_index] <= i_AWBURST;
                    reg_age[write_index] <= '0;
                    reg_valid[write_index] <= ON;
                end
            end
        end

        `ifdef INITIAL_REG_RESET
            initial begin
                for (int i=0; i<ID_MAX; i++) begin
                    cnt_awid_ocheck[i] = '0;
                    cnt_awid_icheck[i] = '0;
                end

                for (int i=0; i<NUM_WRITE_SCHEDULER; i++) begin
                    reg_AWID[i] = '0;
                    reg_AWADDR[i] = '0;
                    reg_AWLEN[i] = '0;
                    reg_AWSIZE[i] = '0;
                    reg_AWBURST[i] = '0;
                    reg_age[i] = '0;
                    reg_valid[i] = OFF;
                end

                previous_o_awid = '0;
                cache_has_empty = OFF;
                cache_has_valid = OFF;
                has_aging_same_id = OFF;
                has_aging_other_id = OFF;
                has_nonaging_same_id = OFF;
                has_nonaging_other_id = OFF;
                fill_index = '0;
                aging_same_id_index = '0;
                aging_other_id_index = '0;
                nonaging_same_id_index = '0;
                nonaging_other_id_index = '0;
                aging_same_age_value = '0;
                aging_other_age_value = '0;
                nonaging_same_age_value = '0;
                nonaging_other_count_value = '0;
            end
        `endif

    `elsif FIFO_ORDERING
        wire aw_in = i_AWVALID & i_AWREADY;
        wire aw_out = o_AWREADY & o_AWVALID;

        reg [ID_WIDTH-1:0] reg_AWID;
        reg [ADDR_WIDTH-1:0] reg_AWADDR;
        reg [LEN_WIDTH-1:0] reg_AWLEN;
        reg [2:0] reg_AWSIZE;
        reg [1:0] reg_AWBURST;
        reg reg_valid;

        assign i_AWREADY = !reg_valid || aw_out;
        assign o_AWVALID = reg_valid;
        assign o_AWID    = reg_valid ? reg_AWID    : '0;
        assign o_AWADDR  = reg_valid ? reg_AWADDR  : '0;
        assign o_AWLEN   = reg_valid ? reg_AWLEN   : '0;
        assign o_AWSIZE  = reg_valid ? reg_AWSIZE  : '0;
        assign o_AWBURST = reg_valid ? reg_AWBURST : '0;

        always @(posedge ACLK or negedge ARESETn) begin
            if (!ARESETn) begin
                reg_AWID <= '0;
                reg_AWADDR <= '0;
                reg_AWLEN <= '0;
                reg_AWSIZE <= '0;
                reg_AWBURST <= '0;
                reg_valid <= OFF;
            end
            else begin
                if (aw_in) begin
                    reg_AWID <= i_AWID;
                    reg_AWADDR <= i_AWADDR;
                    reg_AWLEN <= i_AWLEN;
                    reg_AWSIZE <= i_AWSIZE;
                    reg_AWBURST <= i_AWBURST;
                    reg_valid <= ON;
                end
                else if (aw_out) begin
                    reg_valid <= OFF;
                end
            end
        end

        `ifdef INITIAL_REG_RESET
            initial begin
                reg_AWID = '0;
                reg_AWADDR = '0;
                reg_AWLEN = '0;
                reg_AWSIZE = '0;
                reg_AWBURST = '0;
                reg_valid = OFF;
            end
        `endif
    `elsif WRITE_MINAMI_PRIORITY_ADAPTIVE_CUSTOM    // Priority Adaptive Custom
        localparam KEEP_MAX_LENGTH = WRITE_KEEP_MAX_LENGTH;
        localparam CNT_WIDTH = $clog2(KEEP_MAX_LENGTH);
        localparam ID_MAX = (1<<ID_WIDTH);
        localparam INDEX_WIDTH = (NUM_WRITE_SCHEDULER <= 1) ? 1 : $clog2(NUM_WRITE_SCHEDULER);

        localparam [2:0] BASED_AWID_WITH_AGE = 3'b001;
        localparam [2:0] BASED_DATASTREAM_HIT = 3'b010;
        localparam [2:0] BASED_SHORT_BURST = 3'b011;
        localparam [2:0] BASED_FIFO = 3'b100;
        localparam [2:0] BASED_AGING = 3'b101;

        localparam STREAM_LENGTH = WRITE_KEEP_MAX_LENGTH;
        localparam AGE_THRESHOLD = WRITE_KEEP_MAX_LENGTH;
        localparam BURST_LENGTH_AWARE = 4;
        localparam [LEN_WIDTH-1:0] SHORT_BURST_LIMIT = BURST_LENGTH_AWARE;

        wire aw_in = i_AWVALID & i_AWREADY;
        wire aw_out = o_AWREADY & o_AWVALID;

        reg [CNT_WIDTH:0] cnt_awid_ocheck[0:ID_MAX-1];
        reg [CNT_WIDTH:0] cnt_awid_icheck[0:ID_MAX-1];
        reg [CNT_WIDTH:0] cnt_stream_keep;
        reg [ID_WIDTH-1:0] previous_o_awid;
        reg [ADDR_WIDTH-1:0] previous_o_awaddr;
        reg [LEN_WIDTH-1:0] previous_o_awlen;
        reg [2:0] previous_o_awsize;
        reg [1:0] previous_o_awburst;
        reg [ADDR_WIDTH-1:0] expected_stream_addr;
        reg has_previous_aw;

        reg [ID_WIDTH-1:0] reg_AWID[0:NUM_WRITE_SCHEDULER-1];
        reg [ADDR_WIDTH-1:0] reg_AWADDR[0:NUM_WRITE_SCHEDULER-1];
        reg [LEN_WIDTH-1:0] reg_AWLEN[0:NUM_WRITE_SCHEDULER-1];
        reg [2:0] reg_AWSIZE[0:NUM_WRITE_SCHEDULER-1];
        reg [1:0] reg_AWBURST[0:NUM_WRITE_SCHEDULER-1];
        reg [CNT_WIDTH:0] reg_age[0:NUM_WRITE_SCHEDULER-1];
        reg reg_valid[0:NUM_WRITE_SCHEDULER-1];

        reg cache_has_empty;
        reg cache_has_valid;
        reg has_aged;
        reg has_stream;
        reg has_awid_match;
        reg has_short_burst;
        reg has_fifo;
        reg [INDEX_WIDTH-1:0] fill_index;
        reg [INDEX_WIDTH-1:0] aged_index;
        reg [INDEX_WIDTH-1:0] stream_index;
        reg [INDEX_WIDTH-1:0] awid_match_index;
        reg [INDEX_WIDTH-1:0] short_burst_index;
        reg [INDEX_WIDTH-1:0] fifo_index;
        reg [CNT_WIDTH:0] aged_age_value;
        reg [CNT_WIDTH:0] stream_age_value;
        reg [CNT_WIDTH:0] awid_match_age_value;
        reg [CNT_WIDTH:0] short_burst_age_value;
        reg [CNT_WIDTH:0] fifo_age_value;
        reg [LEN_WIDTH-1:0] short_burst_len_value;
        reg [2:0] selected_policy;
        reg [2:0] selected_policy_next;

        reg issue_valid;
        reg [INDEX_WIDTH-1:0] issue_index;
        reg [INDEX_WIDTH-1:0] issue_index_next;
        wire [INDEX_WIDTH-1:0] write_index;
        wire [ADDR_WIDTH-1:0] previous_transfer_beats;
        wire [ADDR_WIDTH-1:0] previous_transfer_bytes;
        wire [ADDR_WIDTH-1:0] next_expected_stream_addr;
        wire limit_reached = (cnt_awid_ocheck[previous_o_awid] >= KEEP_MAX_LENGTH);
        wire stream_limit_reached = (cnt_stream_keep >= STREAM_LENGTH);
        wire is_ocnt_max = (cnt_awid_ocheck[o_AWID] == KEEP_MAX_LENGTH) ? ON : OFF;
        wire selected_is_stream = (selected_policy == BASED_DATASTREAM_HIT);

        assign previous_transfer_beats = {{(ADDR_WIDTH-LEN_WIDTH){1'b0}}, o_AWLEN} + {{(ADDR_WIDTH-1){1'b0}}, 1'b1};
        assign previous_transfer_bytes = previous_transfer_beats << o_AWSIZE;
        assign next_expected_stream_addr = o_AWADDR + previous_transfer_bytes;

        assign i_AWREADY = (cache_has_empty || aw_out) && (!o_AWVALID || o_AWREADY);
        assign o_AWVALID = issue_valid && reg_valid[issue_index];
        assign o_AWID = (o_AWVALID) ? reg_AWID[issue_index] : '0;
        assign o_AWADDR = (o_AWVALID) ? reg_AWADDR[issue_index] : '0;
        assign o_AWLEN = (o_AWVALID) ? reg_AWLEN[issue_index] : '0;
        assign o_AWSIZE = (o_AWVALID) ? reg_AWSIZE[issue_index] : '0;
        assign o_AWBURST = (o_AWVALID) ? reg_AWBURST[issue_index] : '0;

        assign write_index = (!cache_has_empty && aw_out) ? issue_index : fill_index;

        always @(*) begin
            cache_has_empty = OFF;
            cache_has_valid = OFF;
            fill_index = '0;

            for (int i=0; i<NUM_WRITE_SCHEDULER; i++) begin
                if (!reg_valid[i] && !cache_has_empty) begin
                    cache_has_empty = ON;
                    fill_index = INDEX_WIDTH'(i);
                end

                if (reg_valid[i]) begin
                    cache_has_valid = ON;
                end
            end
        end

        always @(*) begin
            has_aged = OFF;
            has_stream = OFF;
            has_awid_match = OFF;
            has_short_burst = OFF;
            has_fifo = OFF;
            aged_index = '0;
            stream_index = '0;
            awid_match_index = '0;
            short_burst_index = '0;
            fifo_index = '0;
            aged_age_value = '0;
            stream_age_value = '0;
            awid_match_age_value = '0;
            short_burst_age_value = '0;
            fifo_age_value = '0;
            short_burst_len_value = {LEN_WIDTH{1'b1}};
            selected_policy_next = BASED_FIFO;
            issue_index_next = '0;

            for (int i=0; i<NUM_WRITE_SCHEDULER; i++) begin
                if (reg_valid[i] && !(aw_out && (INDEX_WIDTH'(i) == issue_index))) begin
                    if (reg_age[i] >= AGE_THRESHOLD) begin
                        if (!has_aged || (reg_age[i] > aged_age_value)) begin
                            has_aged = ON;
                            aged_age_value = reg_age[i];
                            aged_index = INDEX_WIDTH'(i);
                        end
                    end

                    if (has_previous_aw &&
                        (previous_o_awburst == 2'b01) &&
                        (reg_AWBURST[i] == 2'b01) &&
                        (reg_AWADDR[i] == expected_stream_addr)) begin
                        if (!has_stream || (reg_age[i] > stream_age_value)) begin
                            has_stream = ON;
                            stream_age_value = reg_age[i];
                            stream_index = INDEX_WIDTH'(i);
                        end
                    end

                    if (reg_AWID[i] == previous_o_awid) begin
                        if (!has_awid_match || (reg_age[i] > awid_match_age_value)) begin
                            has_awid_match = ON;
                            awid_match_age_value = reg_age[i];
                            awid_match_index = INDEX_WIDTH'(i);
                        end
                    end

                    if ((reg_AWLEN[i] <= SHORT_BURST_LIMIT) &&
                        (!has_short_burst ||
                         (reg_AWLEN[i] < short_burst_len_value) ||
                         ((reg_AWLEN[i] == short_burst_len_value) && (reg_age[i] > short_burst_age_value)))) begin
                        has_short_burst = ON;
                        short_burst_len_value = reg_AWLEN[i];
                        short_burst_age_value = reg_age[i];
                        short_burst_index = INDEX_WIDTH'(i);
                    end

                    if (!has_fifo || (reg_age[i] > fifo_age_value)) begin
                        has_fifo = ON;
                        fifo_age_value = reg_age[i];
                        fifo_index = INDEX_WIDTH'(i);
                    end
                end
            end

            if (has_aged) begin
                selected_policy_next = BASED_AGING;
                issue_index_next = aged_index;
            end
            else if (has_stream && !stream_limit_reached) begin
                selected_policy_next = BASED_DATASTREAM_HIT;
                issue_index_next = stream_index;
            end
            else if (has_awid_match && !limit_reached) begin
                selected_policy_next = BASED_AWID_WITH_AGE;
                issue_index_next = awid_match_index;
            end
            else if (has_short_burst) begin
                selected_policy_next = BASED_SHORT_BURST;
                issue_index_next = short_burst_index;
            end
            else begin
                selected_policy_next = BASED_FIFO;
                issue_index_next = fifo_index;
            end
        end

        always @(posedge ACLK or negedge ARESETn) begin
            if (!ARESETn) begin
                issue_valid <= OFF;
                issue_index <= '0;
                selected_policy <= BASED_FIFO;
            end
            else if (aw_out || aw_in || !issue_valid || !reg_valid[issue_index]) begin
                issue_valid <= has_aged || has_stream || has_awid_match || has_short_burst || has_fifo;
                issue_index <= issue_index_next;
                selected_policy <= selected_policy_next;
            end
        end

        always @(posedge ACLK or negedge ARESETn) begin
            if (!ARESETn) begin
                previous_o_awid <= '0;
                previous_o_awaddr <= '0;
                previous_o_awlen <= '0;
                previous_o_awsize <= '0;
                previous_o_awburst <= '0;
                expected_stream_addr <= '0;
                has_previous_aw <= OFF;
                cnt_stream_keep <= '0;
            end
            else if (aw_out) begin
                previous_o_awid <= o_AWID;
                previous_o_awaddr <= o_AWADDR;
                previous_o_awlen <= o_AWLEN;
                previous_o_awsize <= o_AWSIZE;
                previous_o_awburst <= o_AWBURST;
                expected_stream_addr <= next_expected_stream_addr;
                has_previous_aw <= ON;

                if (selected_is_stream && (cnt_stream_keep < STREAM_LENGTH)) begin
                    cnt_stream_keep <= cnt_stream_keep + 1'b1;
                end
                else if (selected_is_stream) begin
                    cnt_stream_keep <= '0;
                end
                else begin
                    cnt_stream_keep <= '0;
                end
            end
        end

        always @(posedge ACLK or negedge ARESETn) begin
            if (!ARESETn) begin
                for (int i=0; i<ID_MAX; i++) begin : adaptive_reset_reg_ocheck
                    cnt_awid_ocheck[i] <= '0;
                end
            end
            else begin
                if (aw_out && (previous_o_awid != o_AWID)) begin
                    cnt_awid_ocheck[o_AWID] <= 1'b1;
                end
                else if ((aw_out) && (!is_ocnt_max)) begin
                    cnt_awid_ocheck[o_AWID] <= cnt_awid_ocheck[o_AWID] + 1'b1;
                end
                else if ((aw_out) && is_ocnt_max) begin
                    cnt_awid_ocheck[o_AWID] <= '0;
                end
            end
        end

        always @(posedge ACLK or negedge ARESETn) begin
            if (!ARESETn) begin
                for (int i=0; i<ID_MAX; i++) begin : adaptive_reset_reg_icheck
                    cnt_awid_icheck[i] <= '0;
                end
            end
            else begin
                case({aw_in, aw_out})
                    2'b00 : begin
                        cnt_awid_icheck[i_AWID] <= cnt_awid_icheck[i_AWID];
                        cnt_awid_icheck[o_AWID] <= cnt_awid_icheck[o_AWID];
                    end
                    2'b01 : begin
                        if (cnt_awid_icheck[o_AWID] != 0) begin
                            cnt_awid_icheck[o_AWID] <= cnt_awid_icheck[o_AWID] - 1'b1;
                        end
                    end
                    2'b10 : begin
                        if (cnt_awid_icheck[i_AWID] < KEEP_MAX_LENGTH) begin
                            cnt_awid_icheck[i_AWID] <= cnt_awid_icheck[i_AWID] + 1'b1;
                        end
                    end
                    2'b11 : begin
                        if (i_AWID == o_AWID) begin
                            cnt_awid_icheck[o_AWID] <= cnt_awid_icheck[o_AWID];
                        end
                        else begin
                            if (cnt_awid_icheck[o_AWID] != 0) cnt_awid_icheck[o_AWID] <= cnt_awid_icheck[o_AWID] - 1'b1;
                            else cnt_awid_icheck[o_AWID] <= '0;
                            if (cnt_awid_icheck[i_AWID] < KEEP_MAX_LENGTH) cnt_awid_icheck[i_AWID] <= cnt_awid_icheck[i_AWID] + 1'b1;
                            else cnt_awid_icheck[i_AWID] <= KEEP_MAX_LENGTH;
                        end
                    end
                endcase
            end
        end

        always @(posedge ACLK or negedge ARESETn) begin
            if (!ARESETn) begin
                for (int i=0; i<NUM_WRITE_SCHEDULER; i++) begin : adaptive_reset_aw_cache
                    reg_AWID[i] <= '0;
                    reg_AWADDR[i] <= '0;
                    reg_AWLEN[i] <= '0;
                    reg_AWSIZE[i] <= '0;
                    reg_AWBURST[i] <= '0;
                    reg_age[i] <= '0;
                    reg_valid[i] <= OFF;
                end
            end
            else begin
                for (int i=0; i<NUM_WRITE_SCHEDULER; i++) begin
                    if (reg_valid[i]) begin
                        if (aw_out && (INDEX_WIDTH'(i) == issue_index)) begin
                            reg_age[i] <= '0;
                        end
                        else if (reg_age[i] < AGE_THRESHOLD) begin
                            reg_age[i] <= reg_age[i] + 1'b1;
                        end
                    end
                end

                if (aw_out) begin
                    reg_valid[issue_index] <= OFF;
                end

                if (aw_in) begin
                    reg_AWID[write_index] <= i_AWID;
                    reg_AWADDR[write_index] <= i_AWADDR;
                    reg_AWLEN[write_index] <= i_AWLEN;
                    reg_AWSIZE[write_index] <= i_AWSIZE;
                    reg_AWBURST[write_index] <= i_AWBURST;
                    reg_age[write_index] <= '0;
                    reg_valid[write_index] <= ON;
                end
            end
        end


        `ifdef INITIAL_REG_RESET
            initial begin
                for (int i=0; i<ID_MAX; i++) begin
                    cnt_awid_ocheck[i] = '0;
                    cnt_awid_icheck[i] = '0;
                end

                for (int i=0; i<NUM_WRITE_SCHEDULER; i++) begin
                    reg_AWID[i] = '0;
                    reg_AWADDR[i] = '0;
                    reg_AWLEN[i] = '0;
                    reg_AWSIZE[i] = '0;
                    reg_AWBURST[i] = '0;
                    reg_age[i] = '0;
                    reg_valid[i] = OFF;
                end

                cnt_stream_keep = '0;
                previous_o_awid = '0;
                previous_o_awaddr = '0;
                previous_o_awlen = '0;
                previous_o_awsize = '0;
                previous_o_awburst = '0;
                expected_stream_addr = '0;
                has_previous_aw = OFF;
                issue_valid = OFF;
                issue_index = '0;
                issue_index_next = '0;
                cache_has_empty = OFF;
                cache_has_valid = OFF;
                has_aged = OFF;
                has_stream = OFF;
                has_awid_match = OFF;
                has_short_burst = OFF;
                has_fifo = OFF;
                fill_index = '0;
                aged_index = '0;
                stream_index = '0;
                awid_match_index = '0;
                short_burst_index = '0;
                fifo_index = '0;
                aged_age_value = '0;
                stream_age_value = '0;
                awid_match_age_value = '0;
                short_burst_age_value = '0;
                fifo_age_value = '0;
                short_burst_len_value = {LEN_WIDTH{1'b1}};
                selected_policy = BASED_FIFO;
                selected_policy_next = BASED_FIFO;
            end
        `endif

    `else
        `error "No write scheduler policy selected. Define WRITE_MINAMI_CUSTOM, WRITE_MINAMI_AGING, WRITE_MINAMI_PRIORITY_ADAPTIVE_CUSTOM or FIFO_ORDERING."
    `endif

endmodule

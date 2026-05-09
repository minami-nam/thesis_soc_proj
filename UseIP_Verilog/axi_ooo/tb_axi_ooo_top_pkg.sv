`ifndef TB_AXI_OOO_TOP_PKG_SV
`define TB_AXI_OOO_TOP_PKG_SV

package tb_axi_ooo_top_pkg;
    import axi_pkg::*;

    typedef struct {
        logic [ID_WIDTH-1:0]   id;
        logic [ADDR_WIDTH-1:0] addr;
        logic [LEN_WIDTH-1:0]  len;
        logic [2:0]            size;
        logic [1:0]            burst;
    } tb_axi_req_t;

    // Write Test Case
    typedef enum logic [3:0] {
        ALL_FIXED_SEQ_ONLY = 4'b0001,
        ALL_FIXED_STREAM_ONLY = 4'b0010,
        ALL_FIXED_AWID_ONLY = 4'b0011,
        ALL_FIXED_RANDOM_CASE = 4'b0100,

        BL_RANDOM_SEQ_ONLY = 4'b0101,
        BL_RANDOM_STREAM_ONLY = 4'b0110,
        BL_RANDOM_AWID_ONLY = 4'b0111,
        BL_RANDOM_RANDOM_CASE = 4'b1000,

        STARVATION_LONG_BURST = 4'b1001,
        STARVATION_NONLOCAL_ID = 4'b1010,
        STARVATION_STREAM_DOMINANT = 4'b1011
    } tb_axi_write_stimulus_case;

    typedef struct {
        string                 name;
        int unsigned           num_read_req;
        int unsigned           num_write_req;
        bit                    enable_read;
        bit                    fixed_len_mode;
        logic [LEN_WIDTH-1:0]  fixed_len;
        logic [LEN_WIDTH-1:0]  max_random_len;
        bit                    force_same_write_id;
        tb_axi_write_stimulus_case write_case;
        logic [ID_WIDTH-1:0]   same_write_id;
        logic [ADDR_WIDTH-1:0] write_addr_base;
        logic [ADDR_WIDTH-1:0] write_addr_stride;
        logic [DATA_WIDTH-1:0] write_data_base;
        logic [DATA_WIDTH-1:0] write_data_stride;
    } tb_axi_ooo_scenario_cfg_t;

    localparam int TB_DEFAULT_NUM_READ_REQ = 60;
    localparam int TB_DEFAULT_NUM_WRITE_REQ = 60;
    localparam logic [LEN_WIDTH-1:0] TB_DEFAULT_FIXED_BURST_LEN = 8'd15;
    localparam logic [LEN_WIDTH-1:0] TB_DEFAULT_MAX_RANDOM_BURST_LEN = 8'd15;

    function automatic string write_case_name(
        input tb_axi_write_stimulus_case write_case
    );
        begin
            case (write_case)
                ALL_FIXED_SEQ_ONLY: write_case_name = "ALL_FIXED_SEQ_ONLY";
                ALL_FIXED_STREAM_ONLY: write_case_name = "ALL_FIXED_STREAM_ONLY";
                ALL_FIXED_AWID_ONLY: write_case_name = "ALL_FIXED_AWID_ONLY";
                ALL_FIXED_RANDOM_CASE: write_case_name = "ALL_FIXED_RANDOM_CASE";
                BL_RANDOM_SEQ_ONLY: write_case_name = "BL_RANDOM_SEQ_ONLY";
                BL_RANDOM_STREAM_ONLY: write_case_name = "BL_RANDOM_STREAM_ONLY";
                BL_RANDOM_AWID_ONLY: write_case_name = "BL_RANDOM_AWID_ONLY";
                BL_RANDOM_RANDOM_CASE: write_case_name = "BL_RANDOM_RANDOM_CASE";
                STARVATION_LONG_BURST: write_case_name = "STARVATION_LONG_BURST";
                STARVATION_NONLOCAL_ID: write_case_name = "STARVATION_NONLOCAL_ID";
                STARVATION_STREAM_DOMINANT: write_case_name = "STARVATION_STREAM_DOMINANT";
                default: write_case_name = "UNKNOWN_WRITE_CASE";
            endcase
        end
    endfunction

    function automatic tb_axi_ooo_scenario_cfg_t make_scenario(
        input string                 name,
        input int unsigned           num_read_req,
        input int unsigned           num_write_req,
        input bit                    enable_read,
        input bit                    fixed_len_mode,
        input bit                    force_same_write_id,
        input tb_axi_write_stimulus_case write_case,
        input logic [ID_WIDTH-1:0]   same_write_id,
        input logic [ADDR_WIDTH-1:0] write_addr_base,
        input logic [ADDR_WIDTH-1:0] write_addr_stride
    );
        begin
            make_scenario.name = name;
            make_scenario.num_read_req = num_read_req;
            make_scenario.num_write_req = num_write_req;
            make_scenario.enable_read = enable_read;
            make_scenario.fixed_len_mode = fixed_len_mode;
            make_scenario.fixed_len = TB_DEFAULT_FIXED_BURST_LEN;
            make_scenario.max_random_len = TB_DEFAULT_MAX_RANDOM_BURST_LEN;
            make_scenario.force_same_write_id = force_same_write_id;
            make_scenario.write_case = write_case;
            make_scenario.same_write_id = same_write_id;
            make_scenario.write_addr_base = write_addr_base;
            make_scenario.write_addr_stride = write_addr_stride;
            make_scenario.write_data_base = 32'hA000_0000;
            make_scenario.write_data_stride = 32'h0000_0100;
        end
    endfunction

    function automatic logic [LEN_WIDTH-1:0] scenario_len(
        input tb_axi_ooo_scenario_cfg_t cfg
    );
        int unsigned rand_len;
        begin
            if (cfg.fixed_len_mode) begin
                scenario_len = cfg.fixed_len;
            end
            else begin
                rand_len = $urandom_range(0, cfg.max_random_len);
                scenario_len = rand_len[LEN_WIDTH-1:0];
            end
        end
    endfunction

    // Write stimulus case policy: edit these helpers when a case needs
    // custom AWLEN/AWID/AWADDR/WDATA generation behavior.
    function automatic logic [LEN_WIDTH-1:0] write_case_len(
        input tb_axi_write_stimulus_case write_case,
        input tb_axi_ooo_scenario_cfg_t cfg
    );
        int unsigned rand_len;
        begin
            case (write_case)
                ALL_FIXED_SEQ_ONLY,
                ALL_FIXED_STREAM_ONLY,
                ALL_FIXED_AWID_ONLY,
                ALL_FIXED_RANDOM_CASE: begin
                    write_case_len = cfg.fixed_len;
                end

                BL_RANDOM_SEQ_ONLY,
                BL_RANDOM_STREAM_ONLY,
                BL_RANDOM_AWID_ONLY,
                BL_RANDOM_RANDOM_CASE: begin
                    rand_len = $urandom_range(0, cfg.max_random_len);
                    write_case_len = rand_len[LEN_WIDTH-1:0];
                end

                STARVATION_LONG_BURST: begin
                    write_case_len = cfg.max_random_len;
                end

                STARVATION_NONLOCAL_ID,
                STARVATION_STREAM_DOMINANT: begin
                    write_case_len = cfg.fixed_len;
                end

                default: begin
                    write_case_len = scenario_len(cfg);
                end
            endcase
        end
    endfunction

    function automatic logic [ID_WIDTH-1:0] scenario_write_id(
        input tb_axi_ooo_scenario_cfg_t cfg,
        input logic [ID_WIDTH-1:0] random_id
    );
        begin
            scenario_write_id = cfg.force_same_write_id ? cfg.same_write_id : random_id;
        end
    endfunction

    function automatic logic [ID_WIDTH-1:0] write_case_id(
        input tb_axi_write_stimulus_case write_case,
        input tb_axi_ooo_scenario_cfg_t cfg,
        input int unsigned req_index,
        input logic [ID_WIDTH-1:0] random_id
    );
        logic [ID_WIDTH-1:0] max_table_id;
        begin
            max_table_id = NUM_READ_IDTABLE - 1;

            case (write_case)
                ALL_FIXED_STREAM_ONLY,
                ALL_FIXED_AWID_ONLY,
                BL_RANDOM_STREAM_ONLY,
                BL_RANDOM_AWID_ONLY,
                STARVATION_LONG_BURST,
                STARVATION_STREAM_DOMINANT: begin
                    write_case_id = cfg.same_write_id;
                end

                STARVATION_NONLOCAL_ID: begin
                    write_case_id = req_index[0] ? max_table_id : '0;
                end

                default: begin
                    write_case_id = scenario_write_id(cfg, random_id);
                end
            endcase
        end
    endfunction

    function automatic logic [ADDR_WIDTH-1:0] scenario_write_addr(
        input tb_axi_ooo_scenario_cfg_t cfg,
        input int unsigned req_index,
        input logic [ADDR_WIDTH-1:0] random_addr
    );
        begin
            if (cfg.write_addr_stride == '0) begin
                scenario_write_addr = random_addr;
            end
            else begin
                scenario_write_addr = cfg.write_addr_base + (req_index * cfg.write_addr_stride);
            end
        end
    endfunction

    function automatic logic [ADDR_WIDTH-1:0] write_case_addr(
        input tb_axi_write_stimulus_case write_case,
        input tb_axi_ooo_scenario_cfg_t cfg,
        input int unsigned req_index,
        input logic [ADDR_WIDTH-1:0] random_addr
    );
        begin
            case (write_case)
                ALL_FIXED_SEQ_ONLY,
                ALL_FIXED_STREAM_ONLY,
                BL_RANDOM_SEQ_ONLY,
                BL_RANDOM_STREAM_ONLY,
                STARVATION_LONG_BURST,
                STARVATION_STREAM_DOMINANT: begin
                    write_case_addr = cfg.write_addr_base + (req_index * cfg.write_addr_stride);
                end

                STARVATION_NONLOCAL_ID: begin
                    write_case_addr = cfg.write_addr_base + (req_index[0] ? 32'h0001_0000 : 32'h0000_0000);
                end

                default: begin
                    write_case_addr = scenario_write_addr(cfg, req_index, random_addr);
                end
            endcase
        end
    endfunction

    function automatic logic [DATA_WIDTH-1:0] scenario_write_data_base(
        input tb_axi_write_stimulus_case write_case,
        input tb_axi_ooo_scenario_cfg_t cfg,
        input int unsigned req_index
    );
        begin
            case (write_case)
                STARVATION_STREAM_DOMINANT: begin
                    scenario_write_data_base = cfg.write_data_base;
                end

                default: begin
                    scenario_write_data_base = cfg.write_data_base + (req_index * cfg.write_data_stride);
                end
            endcase
        end
    endfunction

    task automatic build_scenario_read_req(
        input tb_axi_ooo_scenario_cfg_t cfg,
        output bit has_req,
        output tb_axi_req_t req
    );
        axi_ar_rand ar_tr;
        begin
            has_req = cfg.enable_read;
            req.id = '0;
            req.addr = '0;
            req.len = '0;
            req.size = '0;
            req.burst = '0;

            if (has_req) begin
                ar_tr = new();
                ar_tr.set_random();
                req.id = ar_tr.id;
                req.addr = ar_tr.addr;
                req.len = scenario_len(cfg);
                req.size = ar_tr.size;
                req.burst = ar_tr.burst;
            end
        end
    endtask

    task automatic build_scenario_write_req(
        input tb_axi_ooo_scenario_cfg_t cfg,
        input tb_axi_write_stimulus_case write_case,
        input int unsigned req_index,
        output tb_axi_req_t req
    );
        axi_aw_rand aw_tr;
        begin
            aw_tr = new();
            aw_tr.set_random();
            req.id = write_case_id(write_case, cfg, req_index, aw_tr.id);
            req.addr = write_case_addr(write_case, cfg, req_index, aw_tr.addr);
            req.len = write_case_len(write_case, cfg);
            req.size = aw_tr.size;
            req.burst = aw_tr.burst;
        end
    endtask

    task automatic build_default_write_perf_scenarios(
        ref tb_axi_ooo_scenario_cfg_t scenarios[$]
    );
        begin
            scenarios.delete();
            scenarios.push_back(make_scenario("fixed_len15_random_access", TB_DEFAULT_NUM_READ_REQ, TB_DEFAULT_NUM_WRITE_REQ, 1'b1, 1'b1, 1'b0, ALL_FIXED_RANDOM_CASE, '0, '0, '0));
            scenarios.push_back(make_scenario("variable_len_random_access", TB_DEFAULT_NUM_READ_REQ, TB_DEFAULT_NUM_WRITE_REQ, 1'b1, 1'b0, 1'b0, BL_RANDOM_RANDOM_CASE, '0, '0, '0));

            scenarios.push_back(make_scenario("write_all_fixed_seq_only", 0, TB_DEFAULT_NUM_WRITE_REQ, 1'b0, 1'b1, 1'b0, ALL_FIXED_SEQ_ONLY, '0, 32'h0000_4000, 32'h0000_0040));
            scenarios.push_back(make_scenario("write_all_fixed_stream_only", 0, TB_DEFAULT_NUM_WRITE_REQ, 1'b0, 1'b1, 1'b1, ALL_FIXED_STREAM_ONLY, 4'h0, 32'h0000_5000, 32'h0000_0040));
            scenarios.push_back(make_scenario("write_all_fixed_awid_only", 0, TB_DEFAULT_NUM_WRITE_REQ, 1'b0, 1'b1, 1'b1, ALL_FIXED_AWID_ONLY, 4'h1, '0, '0));
            scenarios.push_back(make_scenario("write_all_fixed_random_case", 0, TB_DEFAULT_NUM_WRITE_REQ, 1'b0, 1'b1, 1'b0, ALL_FIXED_RANDOM_CASE, '0, '0, '0));

            scenarios.push_back(make_scenario("write_bl_random_seq_only", 0, TB_DEFAULT_NUM_WRITE_REQ, 1'b0, 1'b0, 1'b0, BL_RANDOM_SEQ_ONLY, '0, 32'h0000_8000, 32'h0000_0040));
            scenarios.push_back(make_scenario("write_bl_random_stream_only", 0, TB_DEFAULT_NUM_WRITE_REQ, 1'b0, 1'b0, 1'b1, BL_RANDOM_STREAM_ONLY, 4'h2, 32'h0000_9000, 32'h0000_0040));
            scenarios.push_back(make_scenario("write_bl_random_awid_only", 0, TB_DEFAULT_NUM_WRITE_REQ, 1'b0, 1'b0, 1'b1, BL_RANDOM_AWID_ONLY, 4'h3, '0, '0));
            scenarios.push_back(make_scenario("write_bl_random_random_case", 0, TB_DEFAULT_NUM_WRITE_REQ, 1'b0, 1'b0, 1'b0, BL_RANDOM_RANDOM_CASE, '0, '0, '0));

            scenarios.push_back(make_scenario("write_starvation_long_burst", 0, TB_DEFAULT_NUM_WRITE_REQ, 1'b0, 1'b0, 1'b1, STARVATION_LONG_BURST, 4'h4, 32'h0000_C000, 32'h0000_0080));
            scenarios.push_back(make_scenario("write_starvation_nonlocal_id", 0, TB_DEFAULT_NUM_WRITE_REQ, 1'b0, 1'b1, 1'b0, STARVATION_NONLOCAL_ID, '0, 32'h0001_0000, '0));
            scenarios.push_back(make_scenario("write_starvation_stream_dominant", 0, TB_DEFAULT_NUM_WRITE_REQ, 1'b0, 1'b1, 1'b1, STARVATION_STREAM_DOMINANT, 4'h5, 32'h0002_0000, 32'h0000_0020));
        end
    endtask
endpackage

`endif

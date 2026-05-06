`timescale 1ns/1ps

import axi_vip_pkg::*;
import testdesign1_axi_vip_0_0_pkg::*;

module tb_axi_vip;

    // ============================================================
    // Clock / Reset
    // ============================================================
    logic reset_rtl_0;     // Processor System Reset ext_reset_in, active-high
    logic clk_100MHz;

    // ============================================================
    // AXI VIP Master Agent
    // ============================================================
    testdesign1_axi_vip_0_0_mst_t mst_vip;

    // ============================================================
    // AXI Transaction Variables
    // ============================================================
    xil_axi_uint      mtestID;
    xil_axi_ulong     mtestADDR;
    xil_axi_len_t     mtestBurstLength;
    xil_axi_size_t    mtestDataSize;
    xil_axi_burst_t   mtestBurstType;
    xil_axi_lock_t    mtestLOCK;
    xil_axi_cache_t   mtestCacheType;
    xil_axi_prot_t    mtestProtectionType;
    xil_axi_region_t  mtestRegion;
    xil_axi_qos_t     mtestQOS;

    xil_axi_user_beat mtestAWUSER;
    xil_axi_user_beat mtestARUSER;

    xil_axi_resp_t    mtestBresp;

    // 중요:
    // AXI VIP API는 아래를 packed array로 요구함.
    // mtestRresp [255:0] 처럼 identifier 뒤에 두면 unpacked array가 되어 에러 발생.
    xil_axi_resp_t      [255:0] mtestRresp;
    xil_axi_data_beat   [255:0] mtestWUSER;
    xil_axi_data_beat   [255:0] mtestRUSER;

    // AXI VIP 2025.1 API 기준 data는 4096-byte packed vector
    bit [8*4096-1:0] mtestWData;
    bit [8*4096-1:0] mtestRData;

    // ============================================================
    // Address Map
    // Address Editor에서 BRAM Controller에 할당한 base address와 맞추세요.
    // ============================================================
    localparam xil_axi_ulong BASE_ADDR = 32'h4000_0000;

    // DATA_WIDTH = 32 기준
    localparam int DATA_WIDTH = 32;

    // Random multi-request test knobs
    localparam int unsigned RANDOM_REQ_COUNT       = 16;
    localparam int unsigned RANDOM_MAX_BURST_BEATS = 8;
    localparam int unsigned RANDOM_ADDR_WINDOW     = 32'h0000_1000;
    localparam xil_axi_ulong RANDOM_BASE_ADDR      = BASE_ADDR + 32'h0000_0100;

    // Waveform-friendly debug state. AXI VIP task arguments can change in
    // zero-time, so keep explicit registered-looking markers for analysis.
    localparam int unsigned DBG_IDLE       = 0;
    localparam int unsigned DBG_PRE_WRITE  = 1;
    localparam int unsigned DBG_POST_WRITE = 2;
    localparam int unsigned DBG_PRE_READ   = 3;
    localparam int unsigned DBG_POST_READ  = 4;

    logic [31:0] tb_dbg_state;
    logic [31:0] tb_dbg_req_index;
    logic [31:0] tb_dbg_beats;
    logic [31:0] tb_dbg_addr;
    logic [31:0] tb_dbg_id;
    logic [31:0] tb_dbg_awlen;
    logic [31:0] tb_dbg_qos;
    logic [31:0] tb_dbg_wdata [0:RANDOM_MAX_BURST_BEATS-1];
    logic [31:0] tb_dbg_rdata [0:RANDOM_MAX_BURST_BEATS-1];
    logic [31:0] tb_dbg_expected [0:RANDOM_MAX_BURST_BEATS-1];
    logic [31:0] tb_dbg_bresp;
    logic [31:0] tb_dbg_rresp0;
    logic        tb_dbg_pass;

    // ============================================================
    // DUT
    // wrapper port 이름은 실제 testdesign1_wrapper와 일치해야 합니다.
    // ============================================================
    testdesign1_wrapper dut (
        .clk_100MHz  (clk_100MHz),
        .reset_rtl_0 (reset_rtl_0)
    );

    // ============================================================
    // Clock Generation
    // ============================================================
    initial begin
        clk_100MHz = 1'b0;
        forever #5 clk_100MHz = ~clk_100MHz;   // 100 MHz
    end

    // ============================================================
    // Reset Generation
    // Processor System Reset의 ext_reset_in은 active-high
    // ============================================================
    initial begin
        reset_rtl_0 = 1'b0;   // reset assert
        repeat (20) @(posedge clk_100MHz);
        reset_rtl_0 = 1'b1;   // reset release
    end

    // ============================================================
    // Common AXI Field Init
    // ============================================================
    task automatic init_axi_common_fields(
        input xil_axi_ulong addr,
        input xil_axi_len_t burst_len
    );
    begin
        mtestID             = 0;
        mtestADDR           = addr;
        mtestBurstLength    = burst_len;                   // AXI LEN = beats - 1
        mtestDataSize       = xil_axi_size_t'(3'd2);        // 4 bytes = 32-bit
        mtestBurstType      = xil_axi_burst_t'(2'b01);     // INCR burst
        mtestLOCK           = xil_axi_lock_t'(0);
        mtestCacheType      = xil_axi_cache_t'(0);
        mtestProtectionType = xil_axi_prot_t'(0);
        mtestRegion         = xil_axi_region_t'(0);
        mtestQOS            = xil_axi_qos_t'(0);

        mtestAWUSER         = '0;
        mtestARUSER         = '0;
        mtestBresp          = xil_axi_resp_t'(0);
    end
    endtask

    // ============================================================
    // Clear AXI Data/User/Resp Buffers
    // ============================================================
    task automatic clear_axi_buffers;
    begin
        mtestWData = '0;
        mtestRData = '0;

        mtestWUSER = '0;
        mtestRUSER = '0;
        mtestRresp = '0;
    end
    endtask

    task automatic clear_axi_read_buffers;
    begin
        mtestRData = '0;
        mtestRUSER = '0;
        mtestRresp = '0;
    end
    endtask

    task automatic clear_debug_signals;
    begin
        tb_dbg_state     = DBG_IDLE;
        tb_dbg_req_index = '0;
        tb_dbg_beats     = '0;
        tb_dbg_addr      = '0;
        tb_dbg_id        = '0;
        tb_dbg_awlen     = '0;
        tb_dbg_qos       = '0;
        tb_dbg_bresp     = '0;
        tb_dbg_rresp0    = '0;
        tb_dbg_pass      = 1'b0;

        for (int unsigned beat = 0; beat < RANDOM_MAX_BURST_BEATS; beat++) begin
            tb_dbg_wdata[beat]    = '0;
            tb_dbg_rdata[beat]    = '0;
            tb_dbg_expected[beat] = '0;
        end
    end
    endtask

    // ============================================================
    // Set/Get 32-bit Beat Data
    // DATA_WIDTH = 32 기준
    // ============================================================
    task automatic set_wdata_beat(
        input int unsigned beat,
        input logic [31:0] data
    );
    begin
        mtestWData[beat*DATA_WIDTH +: DATA_WIDTH] = data;
    end
    endtask

    function automatic logic [31:0] get_wdata_beat(
        input int unsigned beat
    );
    begin
        get_wdata_beat = mtestWData[beat*DATA_WIDTH +: DATA_WIDTH];
    end
    endfunction

    function automatic logic [31:0] get_rdata_beat(
        input int unsigned beat
    );
    begin
        get_rdata_beat = mtestRData[beat*DATA_WIDTH +: DATA_WIDTH];
    end
    endfunction

    // ============================================================
    // AXI4 Single-beat Write/Read Test
    // ============================================================
    task automatic axi4_single_write_read_test;
        logic [31:0] wr0;
        logic [31:0] rd0;
    begin
        $display("[%0t] AXI4 single-beat test start", $time);

        init_axi_common_fields(BASE_ADDR, xil_axi_len_t'(0));  // 1 beat
        clear_axi_buffers();

        wr0 = 32'hDEAD_BEEF;
        set_wdata_beat(0, wr0);

        $display("[%0t] AXI4 WRITE start: addr=0x%08h data=0x%08h",
                 $time, mtestADDR, wr0);

        mst_vip.AXI4_WRITE_BURST(
            mtestID,
            mtestADDR,
            mtestBurstLength,
            mtestDataSize,
            mtestBurstType,
            mtestLOCK,
            mtestCacheType,
            mtestProtectionType,
            mtestRegion,
            mtestQOS,
            mtestAWUSER,
            mtestWData,
            mtestWUSER,
            mtestBresp
        );

        $display("[%0t] AXI4 WRITE done: BRESP=%0d", $time, mtestBresp);

        clear_axi_read_buffers();

        $display("[%0t] AXI4 READ start: addr=0x%08h", $time, mtestADDR);

        mst_vip.AXI4_READ_BURST(
            mtestID,
            mtestADDR,
            mtestBurstLength,
            mtestDataSize,
            mtestBurstType,
            mtestLOCK,
            mtestCacheType,
            mtestProtectionType,
            mtestRegion,
            mtestQOS,
            mtestARUSER,
            mtestRData,
            mtestRresp,
            mtestRUSER
        );

        rd0 = get_rdata_beat(0);

        $display("[%0t] AXI4 READ done: RDATA=0x%08h RRESP=%0d",
                 $time, rd0, mtestRresp[0]);

        if (rd0 !== wr0) begin
            $error("AXI4 single-beat test FAIL: expected=0x%08h got=0x%08h",
                   wr0, rd0);
        end
        else begin
            $display("[%0t] AXI4 single-beat write/read PASS", $time);
        end
    end
    endtask

    // ============================================================
    // AXI4 4-beat Burst Write/Read Test
    // ============================================================
    task automatic axi4_4beat_burst_write_read_test;
        logic [31:0] expected [0:3];
        logic [31:0] actual;
        bit pass;
    begin
        $display("[%0t] AXI4 4-beat burst test start", $time);

        init_axi_common_fields(BASE_ADDR + 32'h0000_0010, xil_axi_len_t'(3)); // 4 beats
        clear_axi_buffers();

        expected[0] = 32'h1111_0000;
        expected[1] = 32'h2222_0001;
        expected[2] = 32'h3333_0002;
        expected[3] = 32'h4444_0003;

        for (int i = 0; i < 4; i++) begin
            set_wdata_beat(i, expected[i]);
        end

        $display("[%0t] AXI4 BURST WRITE start: addr=0x%08h beats=4",
                 $time, mtestADDR);

        mst_vip.AXI4_WRITE_BURST(
            mtestID,
            mtestADDR,
            mtestBurstLength,
            mtestDataSize,
            mtestBurstType,
            mtestLOCK,
            mtestCacheType,
            mtestProtectionType,
            mtestRegion,
            mtestQOS,
            mtestAWUSER,
            mtestWData,
            mtestWUSER,
            mtestBresp
        );

        $display("[%0t] AXI4 BURST WRITE done: BRESP=%0d", $time, mtestBresp);

        clear_axi_read_buffers();

        $display("[%0t] AXI4 BURST READ start: addr=0x%08h beats=4",
                 $time, mtestADDR);

        mst_vip.AXI4_READ_BURST(
            mtestID,
            mtestADDR,
            mtestBurstLength,
            mtestDataSize,
            mtestBurstType,
            mtestLOCK,
            mtestCacheType,
            mtestProtectionType,
            mtestRegion,
            mtestQOS,
            mtestARUSER,
            mtestRData,
            mtestRresp,
            mtestRUSER
        );

        pass = 1'b1;

        for (int i = 0; i < 4; i++) begin
            actual = get_rdata_beat(i);

            $display("[%0t] beat %0d: expected=0x%08h actual=0x%08h RRESP=%0d",
                     $time, i, expected[i], actual, mtestRresp[i]);

            if (actual !== expected[i]) begin
                pass = 1'b0;
                $error("AXI4 burst mismatch beat %0d: expected=0x%08h got=0x%08h",
                       i, expected[i], actual);
            end
        end

        if (pass) begin
            $display("[%0t] AXI4 4-beat burst write/read PASS", $time);
        end
        else begin
            $error("[%0t] AXI4 4-beat burst write/read FAIL", $time);
        end
    end
    endtask

    // ============================================================
    // AXI4 Random Multi-request Write/Read Test
    // 각 request마다 address, burst length, data를 randomize해서
    // write 후 같은 address를 readback 검증한다.
    // ============================================================
    task automatic axi4_random_multi_write_read_test(
        input int unsigned num_requests
    );
        logic [31:0] expected [0:255];
        logic [31:0] actual;
        xil_axi_ulong req_addr;
        int unsigned beats;
        int unsigned addr_word_offset;
        bit pass;
    begin
        $display("[%0t] AXI4 random multi-request test start: requests=%0d max_beats=%0d",
                 $time, num_requests, RANDOM_MAX_BURST_BEATS);

        for (int unsigned req = 0; req < num_requests; req++) begin
            beats = $urandom_range(1, RANDOM_MAX_BURST_BEATS);
            addr_word_offset = $urandom_range(
                0,
                (RANDOM_ADDR_WINDOW / (DATA_WIDTH / 8)) - RANDOM_MAX_BURST_BEATS
            );
            req_addr = RANDOM_BASE_ADDR + xil_axi_ulong'(addr_word_offset * (DATA_WIDTH / 8));

            init_axi_common_fields(req_addr, xil_axi_len_t'(beats - 1));
            mtestID             = xil_axi_uint'($urandom_range(0, 1));
            mtestCacheType      = xil_axi_cache_t'($urandom_range(0, 15));
            mtestProtectionType = xil_axi_prot_t'($urandom_range(0, 7));
            mtestQOS            = xil_axi_qos_t'($urandom_range(0, 15));
            clear_axi_buffers();

            tb_dbg_state     = DBG_PRE_WRITE;
            tb_dbg_req_index = req;
            tb_dbg_beats     = beats;
            tb_dbg_addr      = req_addr[31:0];
            tb_dbg_id        = mtestID;
            tb_dbg_awlen     = mtestBurstLength;
            tb_dbg_qos       = mtestQOS;
            tb_dbg_bresp     = '0;
            tb_dbg_rresp0    = '0;
            tb_dbg_pass      = 1'b0;

            for (int unsigned beat = 0; beat < RANDOM_MAX_BURST_BEATS; beat++) begin
                tb_dbg_wdata[beat]    = '0;
                tb_dbg_rdata[beat]    = '0;
                tb_dbg_expected[beat] = '0;
            end

            for (int unsigned beat = 0; beat < beats; beat++) begin
                expected[beat] = $urandom();
                set_wdata_beat(beat, expected[beat]);
                tb_dbg_wdata[beat]    = expected[beat];
                tb_dbg_expected[beat] = expected[beat];
            end

            $display("[%0t] AXI4 RANDOM WRITE start: req=%0d addr=0x%08h beats=%0d",
                     $time, req, mtestADDR, beats);

            repeat (2) @(posedge clk_100MHz);

            mst_vip.AXI4_WRITE_BURST(
                mtestID,
                mtestADDR,
                mtestBurstLength,
                mtestDataSize,
                mtestBurstType,
                mtestLOCK,
                mtestCacheType,
                mtestProtectionType,
                mtestRegion,
                mtestQOS,
                mtestAWUSER,
                mtestWData,
                mtestWUSER,
                mtestBresp
            );

            tb_dbg_state = DBG_POST_WRITE;
            tb_dbg_bresp = mtestBresp;

            if (mtestBresp != xil_axi_resp_t'(0)) begin
                $error("[%0t] AXI4 RANDOM WRITE bad BRESP: req=%0d BRESP=%0d",
                       $time, req, mtestBresp);
            end

            repeat (1) @(posedge clk_100MHz);

            clear_axi_read_buffers();
            tb_dbg_state = DBG_PRE_READ;

            $display("[%0t] AXI4 RANDOM READ start: req=%0d addr=0x%08h beats=%0d",
                     $time, req, mtestADDR, beats);

            repeat (2) @(posedge clk_100MHz);

            mst_vip.AXI4_READ_BURST(
                mtestID,
                mtestADDR,
                mtestBurstLength,
                mtestDataSize,
                mtestBurstType,
                mtestLOCK,
                mtestCacheType,
                mtestProtectionType,
                mtestRegion,
                mtestQOS,
                mtestARUSER,
                mtestRData,
                mtestRresp,
                mtestRUSER
            );

            pass = 1'b1;
            tb_dbg_state = DBG_POST_READ;
            tb_dbg_rresp0 = mtestRresp[0];

            for (int unsigned beat = 0; beat < beats; beat++) begin
                actual = get_rdata_beat(beat);
                tb_dbg_rdata[beat] = actual;

                $display("[%0t] req %0d beat %0d: expected=0x%08h actual=0x%08h RRESP=%0d",
                         $time, req, beat, expected[beat], actual, mtestRresp[beat]);

                if ((actual !== expected[beat]) || (mtestRresp[beat] != xil_axi_resp_t'(0))) begin
                    pass = 1'b0;
                    $error("AXI4 random request mismatch: req=%0d beat=%0d expected=0x%08h got=0x%08h RRESP=%0d",
                           req, beat, expected[beat], actual, mtestRresp[beat]);
                end
            end

            tb_dbg_pass = pass;

            if (pass) begin
                $display("[%0t] AXI4 random request PASS: req=%0d addr=0x%08h beats=%0d",
                         $time, req, req_addr, beats);
            end
            else begin
                $error("[%0t] AXI4 random request FAIL: req=%0d addr=0x%08h beats=%0d",
                       $time, req, req_addr, beats);
            end

            repeat ($urandom_range(0, 5)) @(posedge clk_100MHz);
        end

        $display("[%0t] AXI4 random multi-request test done", $time);
    end
    endtask

    // ============================================================
    // Main Stimulus
    // ============================================================
    initial begin
        clear_debug_signals();

        // Processor System Reset ext_reset_in 기준:
        // reset_rtl_0 = 1이면 reset asserted
        // reset_rtl_0 = 0이면 reset released
        wait (reset_rtl_0 === 1'b0);

        // proc_sys_reset 내부 동기화 margin
        repeat (30) @(posedge clk_100MHz);

        // --------------------------------------------------------
        // AXI VIP hierarchy path
        // 실제 xsim hierarchy에서 확인한 path와 맞아야 합니다.
        // --------------------------------------------------------
        mst_vip = new(
            "mst_vip",
            dut.testdesign1_i.axi_vip_0.inst.IF
        );

        mst_vip.start_master();

        $display("[%0t] AXI VIP Master started", $time);

        repeat (10) @(posedge clk_100MHz);

        axi4_single_write_read_test();

        repeat (20) @(posedge clk_100MHz);

        axi4_4beat_burst_write_read_test();

        repeat (20) @(posedge clk_100MHz);

        axi4_random_multi_write_read_test(RANDOM_REQ_COUNT);

        repeat (100) @(posedge clk_100MHz);

        $display("[%0t] Simulation finished", $time);
        $finish;
    end

endmodule

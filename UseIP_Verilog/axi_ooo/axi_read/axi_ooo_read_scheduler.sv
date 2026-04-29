// axi_features.vh 파일 내부에 정책 선택하는 define 있으니 확인.
`include "axi_include_top.vh"
import axi_pkg::*;

module axi_ooo_read_scheduler(
    input [(NUM_READ_IDTABLE)*(ID_WIDTH)-1:0] id_list,
    input [(NUM_READ_IDTABLE)*(ADDR_WIDTH)-1:0] addr_list,
    input [(NUM_READ_IDTABLE)*(LEN_WIDTH)-1:0] len_list,
    input [2*(NUM_READ_IDTABLE)-1:0] burst_type_list,
    input [3*(NUM_READ_IDTABLE)-1:0] size_list,

    input ACLK,
    input ARESETn,
    input i_data_in,
    input i_data_out,

    output [ID_WIDTH-1:0] o_id,
    output [ADDR_WIDTH-1:0] o_addr,
    output [LEN_WIDTH-1:0] o_len,
    output [2:0] o_size,
    output [1:0] o_burst
   
);
    // 정책에 따라 scheduler 구성 변경. 정책에 맞게 세팅하기.

    `ifdef BANK_AWARE   // Bank 기반 Policy 결정
        localparam BANK_BITS = $clog2(NUM_BANK);
        localparam WHERE_BIT_START = 6; // Bank BIT MSB가 어느 자리인가?
        localparam CNT_WIDTH = $clog2(NUM_READ_IDTABLE);

        // min 구하는 function 만들기
        function automatic [BANK_BITS-1:0] min_calc;
            input [BANK_BITS-1:0] a;
            input [BANK_BITS-1:0] b;
            begin
                min_calc = (a > b) ? b : a;
            end

        endfunction

        genvar i;
        wire [BANK_BITS-1:0] bank_value[0:NUM_READ_IDTABLE-1];
        wire [BANK_BITS-1:0] bank_diff[0:NUM_READ_IDTABLE-1];
        wire [NUM_READ_IDTABLE-1:0] diff_is_zero; 

        reg [CNT_WIDTH-1:0] cnt;
        reg [NUM_READ_IDTABLE-1:0] index;
        reg vaild;

        generate
            for (i=0; i<NUM_READ_IDTABLE; i++) begin : ADDR_BASED_BANK
                assign bank_value[i] = addr_list[((ADDR_WIDTH)*i+WHERE_BIT_START) :- BANK_BITS];
                assign bank_diff[i] = reg_addr[WHERE_BIT_START :- BANK_BITS] - bank_value[i];
                assign diff_is_zero[i] = (bank_diff=='0) ? ON : OFF;        
            end
        endgenerate

        reg [ID_WIDTH-1:0] reg_id;
        reg [ADDR_WIDTH-1:0] reg_addr;
        reg [LEN_WIDTH-1:0] reg_len;
        reg [2:0] reg_size;
        reg [1:0] reg_burst;
        
        // 출력 logic 작성
        always @(posedge ACLK or negedge ARESETn) begin
            if (!ARESETn) begin
                reg_id <= '0;
                reg_addr <= '0;
                reg_len <= '0;
                reg_size <= '0;
                reg_burst <= '0;
            end

            else begin
                // 여기서 신호 들어올 때 값 비교하는 것 진행
                if (i_data_in&i_data_out) begin
                    if (cnt=='1) begin
                                        reg_id <= '0;
                reg_addr <= '0;
                reg_len <= '0;
                reg_size <= '0;
                reg_burst <= '0;
                    end
                end
            end
        end

        // comb logic cnt
        always @(*) begin
            vaild = OFF;
            index ='0;

            for (int j=0; j<NUM_READ_IDTABLE; j++) begin
                cnt += diff_is_zero[j];
                if (!vaild&diff_is_zero) begin
                    vaild = ON;
                    index = j[NUM_READ_IDTABLE-1:0];
                end
            end
        end
        
       



    `elsif OOO_CUSTOM_POLICY1

    `elsif OOO_CUSTOM_POLICY2

    `endif


    `ifdef INITIAL_REG_RESET
        initial begin
        end
    `endif




endmodule
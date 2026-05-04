// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2025.1 (lin64) Build 6140274 Wed May 21 22:58:25 MDT 2025
// Date        : Mon May  4 11:32:15 2026
// Host        : minamidev running 64-bit Ubuntu 24.04.4 LTS
// Command     : write_verilog -force -mode funcsim
//               /home/minami/Coding_IPDesign/thesis_soc_proj/Vivado_projfile/axifix1/axifix1.gen/sources_1/bd/design_fix1/ip/design_fix1_blk_mem_gen_0_1/design_fix1_blk_mem_gen_0_1_sim_netlist.v
// Design      : design_fix1_blk_mem_gen_0_1
// Purpose     : This verilog netlist is a functional simulation representation of the design and should not be modified
//               or synthesized. This netlist cannot be used for SDF annotated simulation.
// Device      : xc7z015clg485-3
// --------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CHECK_LICENSE_TYPE = "design_fix1_blk_mem_gen_0_1,blk_mem_gen_v8_4_11,{}" *) (* downgradeipidentifiedwarnings = "yes" *) (* x_core_info = "blk_mem_gen_v8_4_11,Vivado 2025.1" *) 
(* NotValidForBitStream *)
module design_fix1_blk_mem_gen_0_1
   (clka,
    rsta,
    ena,
    wea,
    addra,
    dina,
    douta,
    clkb,
    rstb,
    enb,
    web,
    addrb,
    dinb,
    doutb,
    rsta_busy,
    rstb_busy);
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA CLK" *) (* x_interface_mode = "slave BRAM_PORTA" *) (* x_interface_parameter = "XIL_INTERFACENAME BRAM_PORTA, MEM_ADDRESS_MODE BYTE_ADDRESS, MEM_SIZE 8192, MEM_WIDTH 32, MEM_ECC NONE, MASTER_TYPE BRAM_CTRL, READ_WRITE_MODE READ_WRITE, READ_LATENCY 1" *) input clka;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA RST" *) input rsta;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA EN" *) input ena;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA WE" *) input [3:0]wea;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA ADDR" *) input [31:0]addra;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA DIN" *) input [31:0]dina;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA DOUT" *) output [31:0]douta;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTB CLK" *) (* x_interface_mode = "slave BRAM_PORTB" *) (* x_interface_parameter = "XIL_INTERFACENAME BRAM_PORTB, MEM_ADDRESS_MODE BYTE_ADDRESS, MEM_SIZE 8192, MEM_WIDTH 32, MEM_ECC NONE, MASTER_TYPE BRAM_CTRL, READ_WRITE_MODE READ_WRITE, READ_LATENCY 1" *) input clkb;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTB RST" *) input rstb;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTB EN" *) input enb;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTB WE" *) input [3:0]web;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTB ADDR" *) input [31:0]addrb;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTB DIN" *) input [31:0]dinb;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTB DOUT" *) output [31:0]doutb;
  output rsta_busy;
  output rstb_busy;

  wire [31:0]addra;
  wire [31:0]addrb;
  wire clka;
  wire clkb;
  wire [31:0]dina;
  wire [31:0]dinb;
  wire [31:0]douta;
  wire [31:0]doutb;
  wire ena;
  wire enb;
  wire rsta;
  wire rsta_busy;
  wire rstb;
  wire rstb_busy;
  wire [3:0]wea;
  wire [3:0]web;
  wire NLW_U0_dbiterr_UNCONNECTED;
  wire NLW_U0_s_axi_arready_UNCONNECTED;
  wire NLW_U0_s_axi_awready_UNCONNECTED;
  wire NLW_U0_s_axi_bvalid_UNCONNECTED;
  wire NLW_U0_s_axi_dbiterr_UNCONNECTED;
  wire NLW_U0_s_axi_rlast_UNCONNECTED;
  wire NLW_U0_s_axi_rvalid_UNCONNECTED;
  wire NLW_U0_s_axi_sbiterr_UNCONNECTED;
  wire NLW_U0_s_axi_wready_UNCONNECTED;
  wire NLW_U0_sbiterr_UNCONNECTED;
  wire [31:0]NLW_U0_rdaddrecc_UNCONNECTED;
  wire [3:0]NLW_U0_s_axi_bid_UNCONNECTED;
  wire [1:0]NLW_U0_s_axi_bresp_UNCONNECTED;
  wire [31:0]NLW_U0_s_axi_rdaddrecc_UNCONNECTED;
  wire [31:0]NLW_U0_s_axi_rdata_UNCONNECTED;
  wire [3:0]NLW_U0_s_axi_rid_UNCONNECTED;
  wire [1:0]NLW_U0_s_axi_rresp_UNCONNECTED;

  (* C_ADDRA_WIDTH = "32" *) 
  (* C_ADDRB_WIDTH = "32" *) 
  (* C_ALGORITHM = "1" *) 
  (* C_AXI_ID_WIDTH = "4" *) 
  (* C_AXI_SLAVE_TYPE = "0" *) 
  (* C_AXI_TYPE = "1" *) 
  (* C_BYTE_SIZE = "8" *) 
  (* C_COMMON_CLK = "0" *) 
  (* C_COUNT_18K_BRAM = "0" *) 
  (* C_COUNT_36K_BRAM = "2" *) 
  (* C_CTRL_ECC_ALGO = "NONE" *) 
  (* C_DEFAULT_DATA = "0" *) 
  (* C_DISABLE_WARN_BHV_COLL = "0" *) 
  (* C_DISABLE_WARN_BHV_RANGE = "0" *) 
  (* C_ELABORATION_DIR = "./" *) 
  (* C_ENABLE_32BIT_ADDRESS = "1" *) 
  (* C_EN_DEEPSLEEP_PIN = "0" *) 
  (* C_EN_ECC_PIPE = "0" *) 
  (* C_EN_RDADDRA_CHG = "0" *) 
  (* C_EN_RDADDRB_CHG = "0" *) 
  (* C_EN_SAFETY_CKT = "1" *) 
  (* C_EN_SHUTDOWN_PIN = "0" *) 
  (* C_EN_SLEEP_PIN = "0" *) 
  (* C_EST_POWER_SUMMARY = "Estimated Power for IP     :     10.7492 mW" *) 
  (* C_FAMILY = "zynq" *) 
  (* C_HAS_AXI_ID = "0" *) 
  (* C_HAS_ENA = "1" *) 
  (* C_HAS_ENB = "1" *) 
  (* C_HAS_INJECTERR = "0" *) 
  (* C_HAS_MEM_OUTPUT_REGS_A = "0" *) 
  (* C_HAS_MEM_OUTPUT_REGS_B = "0" *) 
  (* C_HAS_MUX_OUTPUT_REGS_A = "0" *) 
  (* C_HAS_MUX_OUTPUT_REGS_B = "0" *) 
  (* C_HAS_REGCEA = "0" *) 
  (* C_HAS_REGCEB = "0" *) 
  (* C_HAS_RSTA = "1" *) 
  (* C_HAS_RSTB = "1" *) 
  (* C_HAS_SOFTECC_INPUT_REGS_A = "0" *) 
  (* C_HAS_SOFTECC_OUTPUT_REGS_B = "0" *) 
  (* C_INITA_VAL = "0" *) 
  (* C_INITB_VAL = "0" *) 
  (* C_INIT_FILE = "NONE" *) 
  (* C_INIT_FILE_NAME = "no_coe_file_loaded" *) 
  (* C_INTERFACE_TYPE = "0" *) 
  (* C_LOAD_INIT_FILE = "0" *) 
  (* C_MEM_TYPE = "2" *) 
  (* C_MUX_PIPELINE_STAGES = "0" *) 
  (* C_PRIM_TYPE = "1" *) 
  (* C_READ_DEPTH_A = "2048" *) 
  (* C_READ_DEPTH_B = "2048" *) 
  (* C_READ_LATENCY_A = "1" *) 
  (* C_READ_LATENCY_B = "1" *) 
  (* C_READ_WIDTH_A = "32" *) 
  (* C_READ_WIDTH_B = "32" *) 
  (* C_RSTRAM_A = "0" *) 
  (* C_RSTRAM_B = "0" *) 
  (* C_RST_PRIORITY_A = "CE" *) 
  (* C_RST_PRIORITY_B = "CE" *) 
  (* C_SIM_COLLISION_CHECK = "ALL" *) 
  (* C_USE_BRAM_BLOCK = "1" *) 
  (* C_USE_BYTE_WEA = "1" *) 
  (* C_USE_BYTE_WEB = "1" *) 
  (* C_USE_DEFAULT_DATA = "0" *) 
  (* C_USE_ECC = "0" *) 
  (* C_USE_SOFTECC = "0" *) 
  (* C_USE_URAM = "0" *) 
  (* C_WEA_WIDTH = "4" *) 
  (* C_WEB_WIDTH = "4" *) 
  (* C_WRITE_DEPTH_A = "2048" *) 
  (* C_WRITE_DEPTH_B = "2048" *) 
  (* C_WRITE_MODE_A = "WRITE_FIRST" *) 
  (* C_WRITE_MODE_B = "WRITE_FIRST" *) 
  (* C_WRITE_WIDTH_A = "32" *) 
  (* C_WRITE_WIDTH_B = "32" *) 
  (* C_XDEVICEFAMILY = "zynq" *) 
  (* downgradeipidentifiedwarnings = "yes" *) 
  (* is_du_within_envelope = "true" *) 
  design_fix1_blk_mem_gen_0_1_blk_mem_gen_v8_4_11 U0
       (.addra({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,addra[12:2],1'b0,1'b0}),
        .addrb({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,addrb[12:2],1'b0,1'b0}),
        .clka(clka),
        .clkb(clkb),
        .dbiterr(NLW_U0_dbiterr_UNCONNECTED),
        .deepsleep(1'b0),
        .dina(dina),
        .dinb(dinb),
        .douta(douta),
        .doutb(doutb),
        .eccpipece(1'b0),
        .ena(ena),
        .enb(enb),
        .injectdbiterr(1'b0),
        .injectsbiterr(1'b0),
        .rdaddrecc(NLW_U0_rdaddrecc_UNCONNECTED[31:0]),
        .regcea(1'b1),
        .regceb(1'b1),
        .rsta(rsta),
        .rsta_busy(rsta_busy),
        .rstb(rstb),
        .rstb_busy(rstb_busy),
        .s_aclk(1'b0),
        .s_aresetn(1'b0),
        .s_axi_araddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arburst({1'b0,1'b0}),
        .s_axi_arid({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arlen({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arready(NLW_U0_s_axi_arready_UNCONNECTED),
        .s_axi_arsize({1'b0,1'b0,1'b0}),
        .s_axi_arvalid(1'b0),
        .s_axi_awaddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awburst({1'b0,1'b0}),
        .s_axi_awid({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awlen({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awready(NLW_U0_s_axi_awready_UNCONNECTED),
        .s_axi_awsize({1'b0,1'b0,1'b0}),
        .s_axi_awvalid(1'b0),
        .s_axi_bid(NLW_U0_s_axi_bid_UNCONNECTED[3:0]),
        .s_axi_bready(1'b0),
        .s_axi_bresp(NLW_U0_s_axi_bresp_UNCONNECTED[1:0]),
        .s_axi_bvalid(NLW_U0_s_axi_bvalid_UNCONNECTED),
        .s_axi_dbiterr(NLW_U0_s_axi_dbiterr_UNCONNECTED),
        .s_axi_injectdbiterr(1'b0),
        .s_axi_injectsbiterr(1'b0),
        .s_axi_rdaddrecc(NLW_U0_s_axi_rdaddrecc_UNCONNECTED[31:0]),
        .s_axi_rdata(NLW_U0_s_axi_rdata_UNCONNECTED[31:0]),
        .s_axi_rid(NLW_U0_s_axi_rid_UNCONNECTED[3:0]),
        .s_axi_rlast(NLW_U0_s_axi_rlast_UNCONNECTED),
        .s_axi_rready(1'b0),
        .s_axi_rresp(NLW_U0_s_axi_rresp_UNCONNECTED[1:0]),
        .s_axi_rvalid(NLW_U0_s_axi_rvalid_UNCONNECTED),
        .s_axi_sbiterr(NLW_U0_s_axi_sbiterr_UNCONNECTED),
        .s_axi_wdata({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_wlast(1'b0),
        .s_axi_wready(NLW_U0_s_axi_wready_UNCONNECTED),
        .s_axi_wstrb({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_wvalid(1'b0),
        .sbiterr(NLW_U0_sbiterr_UNCONNECTED),
        .shutdown(1'b0),
        .sleep(1'b0),
        .wea(wea),
        .web(web));
endmodule
`pragma protect begin_protected
`pragma protect version = 1
`pragma protect encrypt_agent = "XILINX"
`pragma protect encrypt_agent_info = "Xilinx Encryption Tool 2025.1"
`pragma protect key_keyowner="Synopsys", key_keyname="SNPS-VCS-RSA-2", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=128)
`pragma protect key_block
gydSV72FvW4hnoyUt6yZFJHfJqjRQWPUfYIuDKP0fpjrPOkLRbJGBr4Z9msYTvoIHRlYtXJ2YMY0
d1TIQb+FK4gKsTRru9wr397OxuFBsTRf4e+ZjpYZEdsnqYWcgMSzhN4yhPvO06GyZO15y/LKBxa8
3OKwxVlOLYXhv+sxdXg=

`pragma protect key_keyowner="Aldec", key_keyname="ALDEC15_001", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
WHB6Zbfa5Qi47krP9T4L8UnPOlr881dWx7UcYaZfNGIQQM0gadcoXbhucIpRaUuyOKxv6yhKveRN
h0l+N9+KX6rbZ6+TRhP9JAMuPhlpI7T42QtRv5zx9+m3ct5S0NMszbFaK8zeTAYra5BGP7BHmtkr
MpKfLK5sFyaTE/A7ACtAace9MwFTHDZdl9uUs4aY6KJlm6GaypKduiqkNugukJp5vlFPX/ZapJqG
KMtMhI6grhcuYb1FJrwRZ4jW7hs9HxddSdGLzsZ0HsBcO/qaCPTst+ZA0YIQfd5ULlFmPqq39FfO
p1P+2hEH2n+LycbMj5cn4Dxfqv2R8eucM78R3w==

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-VELOCE-RSA", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=128)
`pragma protect key_block
SmAzQA1VEuJXtJi5vXa2Jg7YvRqAJs6PX9HTZ1YqrJw4VfonBW3726gJ81BjlizpMkcf/Uk5sFIK
aPedVhEs4xCIZylz7gXYDshtytOA/pXUID2qV9nXr8qfI+FydSADUF3ScYDZmlkclFqlZrGq6DQ7
da3lJAzt2h/iR+cczrA=

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-VERIF-SIM-RSA-2", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
iAph5JWb/chMQpLPX1UoLjQDxN5l2I8McM/k2xN5wRht7HXoE6F5yV8luDjn3zkI6vnfUYo7BaI1
mogRRx+R3XcwxvhHr+lngh4+/YLVex1TFncl+kiUMAsu3M/FjFSiqGMVMdKTNLDqr35DuZJVyuiF
lTwXob/KkbQDJiJjBEoxbt+968rKRKRyJGcqIjm4mqRBdqMcgo3HOJFG74SFsWAQrxvXfBhdLSG3
OfoLfls9XDojBjp7G83k0h82g1eeWgBfydm/OcX9o48Pst93NvI4ua8WShZL8MCvRWYqWZrrjrWi
cfUjXAF5SDACjq1/OU6arz/Idz6/a7AP/jmexw==

`pragma protect key_keyowner="Real Intent", key_keyname="RI-RSA-KEY-1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
BY49GZBxBT/gjZDPyaSWlti/sctckoR7jK6NuWdhnF9tiyNfVU7BqjjwxSnyMi0Uucv1BKHXC18h
8hQbFWnNtrq71ilURotXux7sssHlVJ2i1CsJWU18DOcBWxm2ai89uwvxDJh3TJkBJixB5KPvsDhL
lWOjTvZWPoR+Ixy+Tzo+U5Vx7z7SOakRwTrn3u7+c3vmCEBphE+HKeJExhBAoOEd0SXK5iwXaByW
D7Wb7zq6NNUmnCyaJ2BG9kGxLVsf+md7SlocuaFsYyaRZhwPyTucxIlz1tLYwcytKzx0ovoax3no
nYgzlzP/F0/PDWk9BqXgr/tuclc4EZYX0cf4ng==

`pragma protect key_keyowner="Xilinx", key_keyname="xilinxt_2025.1-2029.x", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
qGnCvL35qO7cbUEKCL50yDv1UvezcqBz601zctKop1954QlcjemzZWZHg1zJ00nJaToNdH2S8AKX
n8hNJvbQ+x5HEGL5DoSU9m5qjXd8xxocnZ0yzuZX/dGCT8kDn3gWJR2Gz13pT+w2LQUno1fX+MsC
ehgwvjBBT6GeYjdxHi+aybQUP9AblSxX/z3vh857SGCPohEWvghOgORCHAe45YD+ZWnL62FLxMM2
c+Ozq/Au/Q4q1Yzlzcfv8Mnsvg7OqOeEamQHbuYOfdkJUuYqOwsskEWW348u7FXtsf8m7P3pZyyz
IWyTDAW4igGguMPLHfbtK/twZx8ScJQmOKzglg==

`pragma protect key_keyowner="Metrics Technologies Inc.", key_keyname="DSim", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
Hz+6K8+wh5/fukU4ZWNDXGsq6hreSVCSPP67nA6kUz9Vpjy4TtTnOrrl1BWY0ivEC7Ldyw8VI60A
VO/WPlt409LdAZdMZGsEZ1JuTZ0m9LPcgu9CPCyoMECctmd8LHE+otY6etTmYABB9syY61rk2hrv
RgbcyT/HCK9TzWxSm+XMqvx2nvagCLkMDPh/JZv51fj2zcKaBPnxsz8rnDipaeo0fEyVRC3Y1F/V
U3RmXojBjIumPHSJkQ537dENJEIA0Ra65u8EM/+ItUn1bcryLcIbKy1xGadrHmHdHRUoRcAodO2C
B48bNVeL0VnGg8P9ACIB04lMNzn5p6A1tPOb4Q==

`pragma protect key_keyowner="Atrenta", key_keyname="ATR-SG-RSA-1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=384)
`pragma protect key_block
YDpb+UeT0rJ543Q8wCo2xSS3gpVAT+JoStgBlV5IMjJoUOWkiOPn691FGChmDi3BTq5NxC73KHHR
1galACCjeTGq6cv+0Zc2Ocm1oobdrnSPHp7TMDr5Zle8FX6WywJCiGdoWBODggZSlbOASIK/PVfY
cZM2z60M6RSvzsi3TnYHiKYHpju8THVoSgRd6r31GcbiSy9TjjARERXan0OVc79jGuAg90mmDEEq
91eqmn6NZ9yLI2fgBjFUZbtFCpmJ8WGxOL1h39niWnRK3ZXnk8jcpnZUlxLbYTPO0Z3vVr1zrvcn
RVQloU0OLqg7M95zSs7NtX5Vzvb6jGbMehWV+WMMyxWmxL2XOwsAwPSeX2dI2r77pioY7X6VzH7f
/JxMAnq9udra3WGPsUkD1G0CvPkCC3zdxjpVaflY37ztX9UONhKtzMQa8lJc1IL8GhXRY3R9Lg2c
HIeXSGkpNNuFDqKT6Khe/6Casq+SjFJq+IH9IUtz6RUZTkbFb0Xhgm2P

`pragma protect key_keyowner="Cadence Design Systems.", key_keyname="CDS_RSA_KEY_VER_1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
Q+63zFEYw/LeMgxa7g8g79GGvSyIKDKD8RvvC4DHDQuGObf6n9OGZX4e17v/E/+EDEwUhsWQHFDI
Lp/aH+6fNRmhu9BEWVjxq2WRrQSl4eQjfIaSOXu2dlYh3JjRJwiUp4LteVh8RFAf5t5sRQO4dRIK
x+h28yliSgibaWEAv5FaJQ1EFbNwmgedAaSYjgf2A3afBUcBh5Uy9VHbW/zRzdhhJdsVNBjZYcFy
CVLOcf1toCRp8J4U5FlnFMOzFegUbdXFQhq2VmIhPRxWjrfTk6iR4BcMEN9UMij/5IHRAeBdksyD
CqEKsyFxosbI5KVMRZ1Ln75Zipn0JdsGekHkxg==

`pragma protect key_keyowner="Synplicity", key_keyname="SYNP15_1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
DPUa5DLPYRWvbPnX0U412yoWvvvHyuq43DrYmDJGTK0cR5U4U6th8icYgizC1/hUAEzt19kM/hVa
zZh7bXSWACYLpcfhPY8dRTVGDZVjpbkraw0ceBryLP7jc6Jt5JdNw88tZtZpprCB7nQ25lUL82Hf
WTwL1ZqgGIvtfHhxO0JF5L5ES5giedwQ6u5ffXG3UB6ELcpQD1NvpW5lAz4mfXyvVDCAPZN581TF
tlAy79iKbPKlJ2zFn1BS2cuRIHHe2JRxwPo+0n5VD5CXVgg+lCYxTnCxI8CdyFaTumbs4IfAKwVI
wSN/btbwDUhW9hAHWHIRo+BpdJ4qeGcTDPKtsA==

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-PREC-RSA", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
mf5hcf6JE6yLm0jNCQnHMVmogjLlPz6re0FwG67yvOJ3FuEorru0emIeAKEwgOoxjUYNWvcM7QAH
/UEeB2EIdjLl6glPAUda0HjtaCU2rdncVdM8k6DSMBggc4yo18Qx5F+1TD/RoBgoo0jNkMdDy6wJ
JHjqlN+R01z3yYIMQ9f2z6ZaYncbBYEp4+YAb7g1D7CSMxP5cFRpQznRpYp0JwqJfT9CHzlKgdab
8B288NxeLM66iYodiTS+GSRGLGtDWXpz9yeiuiPe6kJxae2GJyHIMSfluO/0Slc3m24DQNdbojf8
jdc0G2UnrDe5mCUTfYiDmpOWTUJOdYo0FK0N2g==

`pragma protect data_method = "AES128-CBC"
`pragma protect encoding = (enctype = "BASE64", line_length = 76, bytes = 61312)
`pragma protect data_block
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
`pragma protect end_protected
`ifndef GLBL
`define GLBL
`timescale  1 ps / 1 ps

module glbl ();

    parameter ROC_WIDTH = 100000;
    parameter TOC_WIDTH = 0;
    parameter GRES_WIDTH = 10000;
    parameter GRES_START = 10000;

//--------   STARTUP Globals --------------
    wire GSR;
    wire GTS;
    wire GWE;
    wire PRLD;
    wire GRESTORE;
    tri1 p_up_tmp;
    tri (weak1, strong0) PLL_LOCKG = p_up_tmp;

    wire PROGB_GLBL;
    wire CCLKO_GLBL;
    wire FCSBO_GLBL;
    wire [3:0] DO_GLBL;
    wire [3:0] DI_GLBL;
   
    reg GSR_int;
    reg GTS_int;
    reg PRLD_int;
    reg GRESTORE_int;

//--------   JTAG Globals --------------
    wire JTAG_TDO_GLBL;
    wire JTAG_TCK_GLBL;
    wire JTAG_TDI_GLBL;
    wire JTAG_TMS_GLBL;
    wire JTAG_TRST_GLBL;

    reg JTAG_CAPTURE_GLBL;
    reg JTAG_RESET_GLBL;
    reg JTAG_SHIFT_GLBL;
    reg JTAG_UPDATE_GLBL;
    reg JTAG_RUNTEST_GLBL;

    reg JTAG_SEL1_GLBL = 0;
    reg JTAG_SEL2_GLBL = 0 ;
    reg JTAG_SEL3_GLBL = 0;
    reg JTAG_SEL4_GLBL = 0;

    reg JTAG_USER_TDO1_GLBL = 1'bz;
    reg JTAG_USER_TDO2_GLBL = 1'bz;
    reg JTAG_USER_TDO3_GLBL = 1'bz;
    reg JTAG_USER_TDO4_GLBL = 1'bz;

    assign (strong1, weak0) GSR = GSR_int;
    assign (strong1, weak0) GTS = GTS_int;
    assign (weak1, weak0) PRLD = PRLD_int;
    assign (strong1, weak0) GRESTORE = GRESTORE_int;

    initial begin
	GSR_int = 1'b1;
	PRLD_int = 1'b1;
	#(ROC_WIDTH)
	GSR_int = 1'b0;
	PRLD_int = 1'b0;
    end

    initial begin
	GTS_int = 1'b1;
	#(TOC_WIDTH)
	GTS_int = 1'b0;
    end

    initial begin 
	GRESTORE_int = 1'b0;
	#(GRES_START);
	GRESTORE_int = 1'b1;
	#(GRES_WIDTH);
	GRESTORE_int = 1'b0;
    end

endmodule
`endif

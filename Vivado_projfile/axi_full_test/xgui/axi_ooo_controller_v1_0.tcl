# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "ADDR_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "DATA_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "FIFO_NUM" -parent ${Page_0}
  ipgui::add_param $IPINST -name "ID_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "LEN_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "NUM_BANK" -parent ${Page_0}
  ipgui::add_param $IPINST -name "NUM_READ_IDTABLE" -parent ${Page_0}
  ipgui::add_param $IPINST -name "NUM_READ_REORDER" -parent ${Page_0}
  ipgui::add_param $IPINST -name "NUM_READ_SCHEDULER" -parent ${Page_0}
  ipgui::add_param $IPINST -name "NUM_WRITE_AWQUEUE" -parent ${Page_0}
  ipgui::add_param $IPINST -name "NUM_WRITE_ORDER_QUEUE_AW" -parent ${Page_0}
  ipgui::add_param $IPINST -name "NUM_WRITE_SCHEDULER" -parent ${Page_0}
  ipgui::add_param $IPINST -name "READ_BANK_BIT_START" -parent ${Page_0}
  ipgui::add_param $IPINST -name "READ_REORDER_KEEP_OUT_TIMES" -parent ${Page_0}
  ipgui::add_param $IPINST -name "WRITE_KEEP_MAX_LENGTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "WRITE_MAX_BURST_BEATS" -parent ${Page_0}
  ipgui::add_param $IPINST -name "WRITE_SEQ_WIDTH" -parent ${Page_0}


}

proc update_PARAM_VALUE.ADDR_WIDTH { PARAM_VALUE.ADDR_WIDTH } {
	# Procedure called to update ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ADDR_WIDTH { PARAM_VALUE.ADDR_WIDTH } {
	# Procedure called to validate ADDR_WIDTH
	return true
}

proc update_PARAM_VALUE.DATA_WIDTH { PARAM_VALUE.DATA_WIDTH } {
	# Procedure called to update DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DATA_WIDTH { PARAM_VALUE.DATA_WIDTH } {
	# Procedure called to validate DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.FIFO_NUM { PARAM_VALUE.FIFO_NUM } {
	# Procedure called to update FIFO_NUM when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.FIFO_NUM { PARAM_VALUE.FIFO_NUM } {
	# Procedure called to validate FIFO_NUM
	return true
}

proc update_PARAM_VALUE.ID_WIDTH { PARAM_VALUE.ID_WIDTH } {
	# Procedure called to update ID_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ID_WIDTH { PARAM_VALUE.ID_WIDTH } {
	# Procedure called to validate ID_WIDTH
	return true
}

proc update_PARAM_VALUE.LEN_WIDTH { PARAM_VALUE.LEN_WIDTH } {
	# Procedure called to update LEN_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.LEN_WIDTH { PARAM_VALUE.LEN_WIDTH } {
	# Procedure called to validate LEN_WIDTH
	return true
}

proc update_PARAM_VALUE.NUM_BANK { PARAM_VALUE.NUM_BANK } {
	# Procedure called to update NUM_BANK when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.NUM_BANK { PARAM_VALUE.NUM_BANK } {
	# Procedure called to validate NUM_BANK
	return true
}

proc update_PARAM_VALUE.NUM_READ_IDTABLE { PARAM_VALUE.NUM_READ_IDTABLE } {
	# Procedure called to update NUM_READ_IDTABLE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.NUM_READ_IDTABLE { PARAM_VALUE.NUM_READ_IDTABLE } {
	# Procedure called to validate NUM_READ_IDTABLE
	return true
}

proc update_PARAM_VALUE.NUM_READ_REORDER { PARAM_VALUE.NUM_READ_REORDER } {
	# Procedure called to update NUM_READ_REORDER when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.NUM_READ_REORDER { PARAM_VALUE.NUM_READ_REORDER } {
	# Procedure called to validate NUM_READ_REORDER
	return true
}

proc update_PARAM_VALUE.NUM_READ_SCHEDULER { PARAM_VALUE.NUM_READ_SCHEDULER } {
	# Procedure called to update NUM_READ_SCHEDULER when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.NUM_READ_SCHEDULER { PARAM_VALUE.NUM_READ_SCHEDULER } {
	# Procedure called to validate NUM_READ_SCHEDULER
	return true
}

proc update_PARAM_VALUE.NUM_WRITE_AWQUEUE { PARAM_VALUE.NUM_WRITE_AWQUEUE } {
	# Procedure called to update NUM_WRITE_AWQUEUE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.NUM_WRITE_AWQUEUE { PARAM_VALUE.NUM_WRITE_AWQUEUE } {
	# Procedure called to validate NUM_WRITE_AWQUEUE
	return true
}

proc update_PARAM_VALUE.NUM_WRITE_ORDER_QUEUE_AW { PARAM_VALUE.NUM_WRITE_ORDER_QUEUE_AW } {
	# Procedure called to update NUM_WRITE_ORDER_QUEUE_AW when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.NUM_WRITE_ORDER_QUEUE_AW { PARAM_VALUE.NUM_WRITE_ORDER_QUEUE_AW } {
	# Procedure called to validate NUM_WRITE_ORDER_QUEUE_AW
	return true
}

proc update_PARAM_VALUE.NUM_WRITE_SCHEDULER { PARAM_VALUE.NUM_WRITE_SCHEDULER } {
	# Procedure called to update NUM_WRITE_SCHEDULER when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.NUM_WRITE_SCHEDULER { PARAM_VALUE.NUM_WRITE_SCHEDULER } {
	# Procedure called to validate NUM_WRITE_SCHEDULER
	return true
}

proc update_PARAM_VALUE.READ_BANK_BIT_START { PARAM_VALUE.READ_BANK_BIT_START } {
	# Procedure called to update READ_BANK_BIT_START when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.READ_BANK_BIT_START { PARAM_VALUE.READ_BANK_BIT_START } {
	# Procedure called to validate READ_BANK_BIT_START
	return true
}

proc update_PARAM_VALUE.READ_REORDER_KEEP_OUT_TIMES { PARAM_VALUE.READ_REORDER_KEEP_OUT_TIMES } {
	# Procedure called to update READ_REORDER_KEEP_OUT_TIMES when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.READ_REORDER_KEEP_OUT_TIMES { PARAM_VALUE.READ_REORDER_KEEP_OUT_TIMES } {
	# Procedure called to validate READ_REORDER_KEEP_OUT_TIMES
	return true
}

proc update_PARAM_VALUE.WRITE_KEEP_MAX_LENGTH { PARAM_VALUE.WRITE_KEEP_MAX_LENGTH } {
	# Procedure called to update WRITE_KEEP_MAX_LENGTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.WRITE_KEEP_MAX_LENGTH { PARAM_VALUE.WRITE_KEEP_MAX_LENGTH } {
	# Procedure called to validate WRITE_KEEP_MAX_LENGTH
	return true
}

proc update_PARAM_VALUE.WRITE_MAX_BURST_BEATS { PARAM_VALUE.WRITE_MAX_BURST_BEATS } {
	# Procedure called to update WRITE_MAX_BURST_BEATS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.WRITE_MAX_BURST_BEATS { PARAM_VALUE.WRITE_MAX_BURST_BEATS } {
	# Procedure called to validate WRITE_MAX_BURST_BEATS
	return true
}

proc update_PARAM_VALUE.WRITE_SEQ_WIDTH { PARAM_VALUE.WRITE_SEQ_WIDTH } {
	# Procedure called to update WRITE_SEQ_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.WRITE_SEQ_WIDTH { PARAM_VALUE.WRITE_SEQ_WIDTH } {
	# Procedure called to validate WRITE_SEQ_WIDTH
	return true
}


proc update_MODELPARAM_VALUE.FIFO_NUM { MODELPARAM_VALUE.FIFO_NUM PARAM_VALUE.FIFO_NUM } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.FIFO_NUM}] ${MODELPARAM_VALUE.FIFO_NUM}
}

proc update_MODELPARAM_VALUE.ADDR_WIDTH { MODELPARAM_VALUE.ADDR_WIDTH PARAM_VALUE.ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ADDR_WIDTH}] ${MODELPARAM_VALUE.ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.DATA_WIDTH { MODELPARAM_VALUE.DATA_WIDTH PARAM_VALUE.DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DATA_WIDTH}] ${MODELPARAM_VALUE.DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.ID_WIDTH { MODELPARAM_VALUE.ID_WIDTH PARAM_VALUE.ID_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ID_WIDTH}] ${MODELPARAM_VALUE.ID_WIDTH}
}

proc update_MODELPARAM_VALUE.LEN_WIDTH { MODELPARAM_VALUE.LEN_WIDTH PARAM_VALUE.LEN_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.LEN_WIDTH}] ${MODELPARAM_VALUE.LEN_WIDTH}
}

proc update_MODELPARAM_VALUE.NUM_READ_IDTABLE { MODELPARAM_VALUE.NUM_READ_IDTABLE PARAM_VALUE.NUM_READ_IDTABLE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.NUM_READ_IDTABLE}] ${MODELPARAM_VALUE.NUM_READ_IDTABLE}
}

proc update_MODELPARAM_VALUE.NUM_READ_SCHEDULER { MODELPARAM_VALUE.NUM_READ_SCHEDULER PARAM_VALUE.NUM_READ_SCHEDULER } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.NUM_READ_SCHEDULER}] ${MODELPARAM_VALUE.NUM_READ_SCHEDULER}
}

proc update_MODELPARAM_VALUE.NUM_READ_REORDER { MODELPARAM_VALUE.NUM_READ_REORDER PARAM_VALUE.NUM_READ_REORDER } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.NUM_READ_REORDER}] ${MODELPARAM_VALUE.NUM_READ_REORDER}
}

proc update_MODELPARAM_VALUE.NUM_BANK { MODELPARAM_VALUE.NUM_BANK PARAM_VALUE.NUM_BANK } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.NUM_BANK}] ${MODELPARAM_VALUE.NUM_BANK}
}

proc update_MODELPARAM_VALUE.NUM_WRITE_AWQUEUE { MODELPARAM_VALUE.NUM_WRITE_AWQUEUE PARAM_VALUE.NUM_WRITE_AWQUEUE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.NUM_WRITE_AWQUEUE}] ${MODELPARAM_VALUE.NUM_WRITE_AWQUEUE}
}

proc update_MODELPARAM_VALUE.NUM_WRITE_SCHEDULER { MODELPARAM_VALUE.NUM_WRITE_SCHEDULER PARAM_VALUE.NUM_WRITE_SCHEDULER } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.NUM_WRITE_SCHEDULER}] ${MODELPARAM_VALUE.NUM_WRITE_SCHEDULER}
}

proc update_MODELPARAM_VALUE.NUM_WRITE_ORDER_QUEUE_AW { MODELPARAM_VALUE.NUM_WRITE_ORDER_QUEUE_AW PARAM_VALUE.NUM_WRITE_ORDER_QUEUE_AW } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.NUM_WRITE_ORDER_QUEUE_AW}] ${MODELPARAM_VALUE.NUM_WRITE_ORDER_QUEUE_AW}
}

proc update_MODELPARAM_VALUE.READ_BANK_BIT_START { MODELPARAM_VALUE.READ_BANK_BIT_START PARAM_VALUE.READ_BANK_BIT_START } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.READ_BANK_BIT_START}] ${MODELPARAM_VALUE.READ_BANK_BIT_START}
}

proc update_MODELPARAM_VALUE.READ_REORDER_KEEP_OUT_TIMES { MODELPARAM_VALUE.READ_REORDER_KEEP_OUT_TIMES PARAM_VALUE.READ_REORDER_KEEP_OUT_TIMES } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.READ_REORDER_KEEP_OUT_TIMES}] ${MODELPARAM_VALUE.READ_REORDER_KEEP_OUT_TIMES}
}

proc update_MODELPARAM_VALUE.WRITE_KEEP_MAX_LENGTH { MODELPARAM_VALUE.WRITE_KEEP_MAX_LENGTH PARAM_VALUE.WRITE_KEEP_MAX_LENGTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.WRITE_KEEP_MAX_LENGTH}] ${MODELPARAM_VALUE.WRITE_KEEP_MAX_LENGTH}
}

proc update_MODELPARAM_VALUE.WRITE_MAX_BURST_BEATS { MODELPARAM_VALUE.WRITE_MAX_BURST_BEATS PARAM_VALUE.WRITE_MAX_BURST_BEATS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.WRITE_MAX_BURST_BEATS}] ${MODELPARAM_VALUE.WRITE_MAX_BURST_BEATS}
}

proc update_MODELPARAM_VALUE.WRITE_SEQ_WIDTH { MODELPARAM_VALUE.WRITE_SEQ_WIDTH PARAM_VALUE.WRITE_SEQ_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.WRITE_SEQ_WIDTH}] ${MODELPARAM_VALUE.WRITE_SEQ_WIDTH}
}


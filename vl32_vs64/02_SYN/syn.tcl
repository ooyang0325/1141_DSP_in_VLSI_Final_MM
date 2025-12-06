# Setting environment
sh mkdir -p Netlist
sh mkdir -p Report

suppress_message PWR-806
suppress_message LINT-32 
suppress_message OPT-1215 
suppress_message OPT-1207

# Import Design
set DESIGN "MM"
set_host_options -max_cores 16

analyze -format sverilog "./flist.sv"
elaborate $DESIGN
current_design [get_designs $DESIGN]
link

source -echo -verbose ./MM_dc.sdc

# Compile Design
current_design [get_designs ${DESIGN}]

check_design > Report/check_design.txt
check_timing > Report/check_timing.txt

uniquify
set_fix_multiple_port_nets -all -buffer_constants [get_designs *]
set_max_area 0  -ignore_tns

set_clock_gating_style \
	-max_fanout 64 \
	-pos integrated \
	-control_point before \
	-control_signal scan_enable

set_leakage_optimization true
set_dynamic_optimization true

compile_ultra -gate_clock -no_autoungroup
optimize_netlist -area

# Report Output
current_design [get_designs ${DESIGN}]
report_timing > "./Report/${DESIGN}.timing"
report_area > "./Report/${DESIGN}.area"

# Output Design
current_design [get_designs ${DESIGN}]

remove_unconnected_ports -blast_buses [get_cells -hierarchical *]
set verilogout_higher_designs_first true
write -format ddc     -hierarchy -output "./Netlist/${DESIGN}_syn.ddc"
write -format verilog -hierarchy -output "./Netlist/${DESIGN}_syn.v"
write_sdf -version 2.1  -context verilog -load_delay cell ./Netlist/${DESIGN}_syn.sdf
write_sdc  ./Netlist/${DESIGN}_syn.sdc -version 1.8


report_timing
report_area
check_design

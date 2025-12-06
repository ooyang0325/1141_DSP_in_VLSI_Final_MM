#PrimeTime Script
set power_enable_analysis TRUE
set power_analysis_mode time_based

read_file -format verilog  ../02_SYN/Netlist/MM_syn.v
current_design IOTDF
link

read_sdf -load_delay net ../02_SYN/Netlist/MM_syn.sdf


## Measure  power
#report_switching_activity -list_not_annotated -show_pin

read_vcd  -strip_path testbench/u_mm ../03_GATE/MM.fsdb
update_power
report_power 
report_power > MM.power





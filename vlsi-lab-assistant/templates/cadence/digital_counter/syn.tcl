# Genus synthesis script (run: vlab genus -w syn.tcl)
# Set the two paths below to your standard-cell kit (ask Claude to find them in the PDK).
set LIB_PATH  "/path/to/stdcells/lib"
set LIB_FILES "slow.lib"

set_db init_lib_search_path $LIB_PATH
set_db library $LIB_FILES

read_hdl counter.v
elaborate counter

create_clock -name clk -period 2.0 [get_ports clk]
set_input_delay  0.2 -clock clk [remove_from_collection [all_inputs] [get_ports clk]]
set_output_delay 0.2 -clock clk [all_outputs]

syn_generic
syn_map
syn_opt

file mkdir reports outputs
report_timing > reports/timing.rpt
report_area   > reports/area.rpt
report_power  > reports/power.rpt
write_hdl > outputs/counter_netlist.v
write_sdc > outputs/counter.sdc
exit

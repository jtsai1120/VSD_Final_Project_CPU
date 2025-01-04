##############################################

#	Read in top module

##############################################

##############################################

#	Set the clock rate

##############################################
current_design top
set_fix_multiple_port_nets -all -buffer_constants
create_clock -name "CLK" -period 100 -waveform  { 50 100 }  { clk  }
set_dont_touch_network  [ find clock CLK ]
set_fix_hold  [ find clock CLK]

##############################################

#       Set Design Environment 

##############################################

set_operating_condition -max slow -max_library slow\
                        -min fast -min_library fast
set_clock_latency 2 CLK
set_drive [drive_of "slow/DFFX1/Q"] [all_inputs]
set_load [load_of "slow/DFFX1/D"] [all_outputs]
set_input_delay -clock CLK -max 1 [remove_from_collection [all_inputs] [get_ports clk]]
set_input_delay -clock CLK -min 0.2 [remove_from_collection [all_inputs] [get_ports clk]]
set_output_delay -clock CLK -max 0.8 [all_outputs]
set_output_delay -clock CLK -min 0.3 [all_outputs]

set_wire_load_model -name tsmc18_wl10 -library slow




#set_fix_multiple_port_nets -all -buffer_constants

##############################################

#       Synthesize circuit

##############################################

compile -exact_map 
#compile -exact_map -map_effort high -area_effort high -power_effort high

#change_names -rule verilog -verbose -hierarchy

##############################################

#       Create Report

##############################################
change_names -rule verilog -verbose -hierarchy
report_timing -path full -delay max -nworst 1 -max_paths 1 -significant_digits 2 -sort_by group > ./timing_max_rpt.txt
report_timing -path full -delay min -nworst 1 -max_paths 1 -significant_digits 2 -sort_by group > ./timing_min_rpt.txt
report_area -nosplit > ./area_rpt.txt
report_power -analysis_effort low > ./power_rpt.txt


##############################################

#       Save syntheized file

##############################################

write -hierarchy -format verilog -output {./top_syn.v}
write_sdf -version 1.0 -context verilog {./top_syn.sdf}
write_sdc -version 1.5 {./top_syn.sdc}
write_script > {./top_syn.dc}


#exit

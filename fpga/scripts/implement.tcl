# Vivado Implementation Script
# Usage: vivado -mode batch -source implement.tcl -tclargs <project_name> <build_dir>

set project_name [lindex $argv 0]
set build_dir [lindex $argv 1]

# Open synthesized checkpoint
open_checkpoint $build_dir/$project_name.synth.dcp

# Optimize design
opt_design

# Place design
place_design

# Route design
route_design

# Save checkpoint
write_checkpoint -force $build_dir/$project_name.routed.dcp

# Generate timing report
report_timing_summary -file $build_dir/timing_summary.rpt

# Generate utilization report
report_utilization -file $build_dir/utilization.rpt

# Close project
close_project

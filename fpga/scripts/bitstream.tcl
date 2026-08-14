# Vivado Bitstream Generation Script
# Usage: vivado -mode batch -source bitstream.tcl -tclargs <project_name> <build_dir>

set project_name [lindex $argv 0]
set build_dir [lindex $argv 1]

# Open routed checkpoint
open_checkpoint $build_dir/$project_name.routed.dcp

# Generate bitstream
write_bitstream -force $build_dir/$project_name.bit

# Close project
close_project

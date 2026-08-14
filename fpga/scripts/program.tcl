# Vivado FPGA Programming Script
# Usage: vivado -mode batch -source program.tcl -tclargs <bitstream_file>

set bitstream_file [lindex $argv 0]

# Open hardware manager
open_hw_manager

# Connect to hardware server
connect_hw_server

# Open target (assumes single device)
open_hw_target

# Program device
set device [get_hw_devices -of_objects [get_hw_targets] -filter {PART_TYPE == "xc7a35tcpg236-1"}]
current_hw_device $device
program_hw_devices $bitstream_file

# Close hardware manager
close_hw_target
close_hw_manager

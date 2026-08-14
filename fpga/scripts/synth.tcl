# Vivado Synthesis Script
# Usage: vivado -mode batch -source synth.tcl -tclargs <project_name> "<rtl_sources>" "<constraints>" <build_dir>

set project_name [lindex $argv 0]
set rtl_sources [lindex $argv 1]
set constraints [lindex $argv 2]
set build_dir [lindex $argv 3]

# Create project
create_project -force $project_name $build_dir -part xc7a35tcpg236-1

# Add RTL sources
foreach rtl_file $rtl_sources {
    add_files $rtl_file
}

# Add constraints
foreach constr_file $constraints {
    add_files -fileset constrs_1 $constr_file
}

# Set top module
set_property top $project_name [current_fileset]

# Update IP catalog (if needed)
update_ip_catalog

# Run synthesis
synth_design -top $project_name -part xc7a35tcpg236-1

# Save checkpoint
write_checkpoint -force $build_dir/$project_name.synth.dcp

# Close project
close_project

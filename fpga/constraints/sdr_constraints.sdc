# SDR Project Constraints for Intel Quartus
# Adjust pin assignments based on your specific board

# Create clock
create_clock -name clk -period 20.0 [get_ports clk]

# ADC Clock constraint
create_clock -name adc_clk -period 20.0 [get_ports adc_clk]

# DAC Clock constraint
create_clock -name dac_clk -period 20.0 [get_ports dac_clk]

# Input delay constraints for ADC
set_input_delay -clock adc_clk -max 2.0 [get_ports {adc_data[*]}]
set_input_delay -clock adc_clk -min 0.5 [get_ports {adc_data[*]}]

# Output delay constraints for DAC
set_output_delay -clock dac_clk -max 2.0 [get_ports {dac_data[*]}]
set_output_delay -clock dac_clk -min 0.5 [get_ports {dac_data[*]}]

# False path for asynchronous signals
set_false_path -from [get_ports reset_n]
set_false_path -from [get_ports {spi_*}]

# Multicycle paths for complex DSP operations
set_multicycle_path -setup 2 -from [get_cells -hierarchical -filter {REF_NAME == ddc}]
set_multicycle_path -hold 1 -from [get_cells -hierarchical -filter {REF_NAME == ddc}]

# Derate for process variation
set_timing_derate -early 0.95
set_timing_derate -late 1.05

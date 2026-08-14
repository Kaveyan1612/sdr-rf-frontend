# SDR Project Constraints for Xilinx Artix-7
# Adjust pin assignments based on your specific board

# Clock constraints
set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33} [get_ports clk]
create_clock -period 20.000 -name clk -waveform {0 10} [get_ports clk]

# ADC Clock
set_property -dict {PACKAGE_PIN J19 IOSTANDARD LVCMOS33} [get_ports adc_clk]

# DAC Clock  
set_property -dict {PACKAGE_PIN H16 IOSTANDARD LVCMOS33} [get_ports dac_clk]

# ADC Data Interface (LVDS for high-speed)
set_property -dict {PACKAGE_PIN K2 IOSTANDARD LVDS_25} [get_ports {adc_data[0]}]
set_property -dict {PACKAGE_PIN K1 IOSTANDARD LVDS_25} [get_ports {adc_data[1]}]
set_property -dict {PACKAGE_PIN L2 IOSTANDARD LVDS_25} [get_ports {adc_data[2]}]
set_property -dict {PACKAGE_PIN L1 IOSTANDARD LVDS_25} [get_ports {adc_data[3]}]
set_property -dict {PACKAGE_PIN M2 IOSTANDARD LVDS_25} [get_ports {adc_data[4]}]
set_property -dict {PACKAGE_PIN M1 IOSTANDARD LVDS_25} [get_ports {adc_data[5]}]
set_property -dict {PACKAGE_PIN N2 IOSTANDARD LVDS_25} [get_ports {adc_data[6]}]
set_property -dict {PACKAGE_PIN N1 IOSTANDARD LVDS_25} [get_ports {adc_data[7]}]
set_property -dict {PACKAGE_PIN P2 IOSTANDARD LVDS_25} [get_ports {adc_data[8]}]
set_property -dict {PACKAGE_PIN P1 IOSTANDARD LVDS_25} [get_ports {adc_data[9]}]
set_property -dict {PACKAGE_PIN R2 IOSTANDARD LVDS_25} [get_ports {adc_data[10]}]
set_property -dict {PACKAGE_PIN R1 IOSTANDARD LVDS_25} [get_ports {adc_data[11]}]
set_property -dict {PACKAGE_PIN T2 IOSTANDARD LVDS_25} [get_ports {adc_data[12]}]
set_property -dict {PACKAGE_PIN T1 IOSTANDARD LVDS_25} [get_ports {adc_data[13]}]

set_property -dict {PACKAGE_PIN U16 IOSTANDARD LVCMOS33} [get_ports adc_data_valid]
set_property -dict {PACKAGE_PIN V16 IOSTANDARD LVCMOS33} [get_ports adc_overflow]

# DAC Data Interface
set_property -dict {PACKAGE_PIN U2 IOSTANDARD LVDS_25} [get_ports {dac_data[0]}]
set_property -dict {PACKAGE_PIN U1 IOSTANDARD LVDS_25} [get_ports {dac_data[1]}]
set_property -dict {PACKAGE_PIN V2 IOSTANDARD LVDS_25} [get_ports {dac_data[2]}]
set_property -dict {PACKAGE_PIN V1 IOSTANDARD LVDS_25} [get_ports {dac_data[3]}]
set_property -dict {PACKAGE_PIN W2 IOSTANDARD LVDS_25} [get_ports {dac_data[4]}]
set_property -dict {PACKAGE_PIN W1 IOSTANDARD LVDS_25} [get_ports {dac_data[5]}]
set_property -dict {PACKAGE_PIN Y2 IOSTANDARD LVDS_25} [get_ports {dac_data[6]}]
set_property -dict {PACKAGE_PIN Y1 IOSTANDARD LVDS_25} [get_ports {dac_data[7]}]
set_property -dict {PACKAGE_PIN AA2 IOSTANDARD LVDS_25} [get_ports {dac_data[8]}]
set_property -dict {PACKAGE_PIN AA1 IOSTANDARD LVDS_25} [get_ports {dac_data[9]}]
set_property -dict {PACKAGE_PIN AB2 IOSTANDARD LVDS_25} [get_ports {dac_data[10]}]
set_property -dict {PACKAGE_PIN AB1 IOSTANDARD LVDS_25} [get_ports {dac_data[11]}]
set_property -dict {PACKAGE_PIN AC2 IOSTANDARD LVDS_25} [get_ports {dac_data[12]}]
set_property -dict {PACKAGE_PIN AC1 IOSTANDARD LVDS_25} [get_ports {dac_data[13]}]

set_property -dict {PACKAGE_PIN AB17 IOSTANDARD LVCMOS33} [get_ports dac_data_valid]
set_property -dict {PACKAGE_PIN AC17 IOSTANDARD LVCMOS33} [get_ports dac_enable]

# SPI Interface
set_property -dict {PACKAGE_PIN E15 IOSTANDARD LVCMOS33} [get_ports spi_clk]
set_property -dict {PACKAGE_PIN E16 IOSTANDARD LVCMOS33} [get_ports spi_mosi]
set_property -dict {PACKAGE_PIN F15 IOSTANDARD LVCMOS33} [get_ports spi_miso]
set_property -dict {PACKAGE_PIN F16 IOSTANDARD LVCMOS33} [get_ports spi_cs_n]

# Status LEDs
set_property -dict {PACKAGE_PIN H17 IOSTANDARD LVCMOS33} [get_ports {status_leds[0]}]
set_property -dict {PACKAGE_PIN K15 IOSTANDARD LVCMOS33} [get_ports {status_leds[1]}]
set_property -dict {PACKAGE_PIN J13 IOSTANDARD LVCMOS33} [get_ports {status_leds[2]}]
set_property -dict {PACKAGE_PIN N14 IOSTANDARD LVCMOS33} [get_ports {status_leds[3]}]
set_property -dict {PACKAGE_PIN L14 IOSTANDARD LVCMOS33} [get_ports {status_leds[4]}]
set_property -dict {PACKAGE_PIN M14 IOSTANDARD LVCMOS33} [get_ports {status_leds[5]}]
set_property -dict {PACKAGE_PIN N14 IOSTANDARD LVCMOS33} [get_ports {status_leds[6]}]
set_property -dict {PACKAGE_PIN P14 IOSTANDARD LVCMOS33} [get_ports {status_leds[7]}]

# Reset
set_property -dict {PACKAGE_PIN C12 IOSTANDARD LVCMOS33} [get_ports reset_n]

# Timing constraints for high-speed interfaces
set_input_delay -clock adc_clk -max 2.0 [get_ports {adc_data[*]}]
set_input_delay -clock adc_clk -min 0.5 [get_ports {adc_data[*]}]
set_output_delay -clock dac_clk -max 2.0 [get_ports {dac_data[*]}]
set_output_delay -clock dac_clk -min 0.5 [get_ports {dac_data[*]}]

# False path for asynchronous control signals
set_false_path -from [get_ports reset_n]
set_false_path -from [get_ports {spi_*}]

# Placement constraints for critical timing paths
# (Add specific placement directives if needed)

# Makefile for FPGA SDR Project
# Supports both Xilinx Vivado and Intel Quartus flows

# Project settings
PROJECT_NAME = sdr_rf_frontend
TOP_MODULE = sdr_top

# Tool selection (VIVADO or QUARTUS)
FPGA_TOOL = VIVADO

# Directories
RTL_DIR = rtl
IP_DIR = ip
CONSTRAINTS_DIR = constraints
SIM_DIR = sim
BUILD_DIR = build
SRC_DIR = src

# Source files
RTL_SOURCES = $(RTL_DIR)/adc_interface.v \
              $(RTL_DIR)/ddc.v \
              $(RTL_DIR)/fir_filter.v \
              $(RTL_DIR)/dac_interface.v \
              $(RTL_DIR)/control_logic.v \
              $(RTL_DIR)/sdr_top.v \
              $(RTL_DIR)/fft_module.v \
              $(RTL_DIR)/iir_filter.v \
              $(RTL_DIR)/uart_interface.v \
              $(RTL_DIR)/i2c_interface.v

# Constraint files
XDC_CONSTRAINTS = $(CONSTRAINTS_DIR)/sdr_constraints.xdc
SDC_CONSTRAINTS = $(CONSTRAINTS_DIR)/sdr_constraints.sdc

# Simulation files
SIM_SOURCES = $(SIM_DIR)/tb_adc_interface.v \
              $(SIM_DIR)/tb_ddc.v \
              $(SIM_DIR)/tb_fir_filter.v \
              $(SIM_DIR)/tb_sdr_top.v

# Build targets
.PHONY: all clean sim synth implement program help

# Default target
all: synth

# Help target
help:
	@echo "SDR FPGA Build System"
	@echo "===================="
	@echo "Available targets:"
	@echo "  all       - Default target (synthesis)"
	@echo "  synth     - Run synthesis only"
	@echo "  implement - Run synthesis and implementation"
	@echo "  bitstream - Generate programming bitstream"
	@echo "  sim       - Run simulation"
	@echo "  program   - Program FPGA device"
	@echo "  clean     - Clean build artifacts"
	@echo "  help      - Show this help message"
	@echo ""
	@echo "Set FPGA_TOOL=VIVADO or FPGA_TOOL=QUARTUS to select toolchain"

# Xilinx Vivado targets
ifeq ($(FPGA_TOOL), VIVADO)
synth: $(BUILD_DIR)/$(PROJECT_NAME).synth.dcp

implement: $(BUILD_DIR)/$(PROJECT_NAME).routed.dcp

bitstream: $(BUILD_DIR)/$(PROJECT_NAME).bit

program: bitstream
	vivado -mode batch -source scripts/program.tcl -tclargs $(BUILD_DIR)/$(PROJECT_NAME).bit

$(BUILD_DIR)/$(PROJECT_NAME).synth.dcp: $(RTL_SOURCES) $(XDC_CONSTRAINTS)
	mkdir -p $(BUILD_DIR)
	vivado -mode batch -source scripts/synth.tcl -tclargs $(PROJECT_NAME) "$(RTL_SOURCES)" "$(XDC_CONSTRAINTS)" $(BUILD_DIR)

$(BUILD_DIR)/$(PROJECT_NAME).routed.dcp: $(BUILD_DIR)/$(PROJECT_NAME).synth.dcp
	vivado -mode batch -source scripts/implement.tcl -tclargs $(PROJECT_NAME) $(BUILD_DIR)

$(BUILD_DIR)/$(PROJECT_NAME).bit: $(BUILD_DIR)/$(PROJECT_NAME).routed.dcp
	vivado -mode batch -source scripts/bitstream.tcl -tclargs $(PROJECT_NAME) $(BUILD_DIR)

# Intel Quartus targets
else ifeq ($(FPGA_TOOL), QUARTUS)
synth: $(BUILD_DIR)/$(PROJECT_NAME).qpf

implement: $(BUILD_DIR)/$(PROJECT_NAME).sof

bitstream: $(BUILD_DIR)/$(PROJECT_NAME).sof

program: bitstream
	quartus_pgm -m jtag -o "p;$(BUILD_DIR)/$(PROJECT_NAME).sof"

$(BUILD_DIR)/$(PROJECT_NAME).qpf: $(RTL_SOURCES) $(SDC_CONSTRAINTS)
	mkdir -p $(BUILD_DIR)
	quartus_sh --flow compile $(PROJECT_NAME) -c $(PROJECT_NAME)

$(BUILD_DIR)/$(PROJECT_NAME).sof: $(BUILD_DIR)/$(PROJECT_NAME).qpf
	quartus_sh --flow compile $(PROJECT_NAME) -c $(PROJECT_NAME)
endif

# Simulation targets
sim: $(SIM_SOURCES)
	@echo "Running simulation..."
	@echo "Simulation tool depends on your preferred simulator"
	@echo "Add simulation scripts for ModelSim, Vivado Simulator, etc."

# Clean build artifacts
clean:
	rm -rf $(BUILD_DIR)
	rm -rf vivado.log vivado.jou
	rm -rf .Xil
	rm -rf *.log *.jou
ifeq ($(FPGA_TOOL), QUARTUS)
	rm -rf db incremental_db simulation
	rm -rf *.rpt *.smsg *.summary
endif

# Create directories
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

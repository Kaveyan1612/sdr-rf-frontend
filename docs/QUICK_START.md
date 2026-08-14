# Quick Start Guide - SDR Project

## Project Overview
This is a complete Software-Defined Radio implementation with FPGA RF front-end and embedded control system.

## Quick Setup Instructions

### 1. FPGA Development
```bash
cd fpga
make help              # See available commands
make synth            # Synthesize design (requires Vivado/Quartus)
make bitstream        # Generate programming file
```

### 2. Embedded System
```bash
cd embedded
make                  # Build for ARM microcontroller
# Flash to your microcontroller using appropriate tool
```

### 3. PC Software
```bash
cd software
make requirements     # Install Python dependencies
make gui              # Launch GUI application
```

## File Structure
```
sdr_project/
├── fpga/              # FPGA design files
│   ├── rtl/          # Verilog source code
│   ├── constraints/  # Timing and pin constraints
│   ├── scripts/     # Build scripts
│   └── sim/          # Testbenches
├── embedded/          # Microcontroller code
│   ├── src/          # C source files
│   ├── inc/          # Header files
│   └── Makefile      # Build system
├── software/          # PC applications
│   ├── src/          # Python source
│   └── requirements.txt
└── docs/              # Documentation
```

## Key Components

### FPGA Modules
- `adc_interface.v` - High-speed ADC data capture
- `ddc.v` - Digital down conversion (mixing, filtering, decimation)
- `fir_filter.v` - Configurable FIR filter
- `fft_module.v` - FFT processing
- `control_logic.v` - SPI register interface

### Embedded Software
- `sdr_control.c/h` - FPGA communication API
- `main.c` - Main control loop

### PC Software
- `sdr_controller.py` - Serial communication library
- `sdr_gui.py` - PyQt5 graphical interface

## Hardware Requirements
- FPGA board (Xilinx Artix-7 or Intel Cyclone V)
- RF front-end with ADC/DAC
- ARM microcontroller
- Development PC with appropriate tools

## Next Steps
1. Review hardware requirements in `docs/HARDWARE_REQUIREMENTS.md`
2. Study architecture in `README.md`
3. Run simulations: `cd fpga && make sim`
4. Set up development environment
5. Begin hardware integration

## Getting Help
- Check `docs/PROJECT_SUMMARY.md` for complete overview
- Review testbenches in `fpga/sim/` for examples
- Examine `docs/` directory for detailed documentation

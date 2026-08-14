# Software-Defined Radio (SDR) Project
FPGA RF Front-end with Embedded Control

## Project Overview
This project implements a complete Software-Defined Radio system with:
- FPGA-based RF front-end for digital signal processing
- Embedded microcontroller for system control and configuration
- Software interface for user interaction and signal analysis

## Hardware Architecture
```
┌─────────────────────────────────────────────────────────────┐
│                      FPGA (RF Front-end)                    │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │   ADC    │→ │  DDC     │→ │  Filter  │→ │  DAC     │    │
│  │ Interface│  │ (Digital │  │ (FIR/IIR)│  │ Interface│    │
│  └──────────┘  │ Down     │  └──────────┘  └──────────┘    │
│       ↑        │ Conv.)   │       ↑                         │
│       │        └──────────┘       │                         │
│  RF Front-end          ↑           │                         │
│  (LNA/Mixer)    ┌──────────┐      │                         │
│                 │  FFT/    │      │                         │
│                 │  DSP     │──────┘                         │
│                 └──────────┘                                │
│                      ↑                                       │
│                 ┌──────────┐                                │
│                 │ Control  │                                │
│                 │ Logic    │                                │
│                 └──────────┘                                │
└──────────────────────┼──────────────────────────────────────┘
                       │ SPI/I2C/UART
┌──────────────────────┼──────────────────────────────────────┐
│          Embedded MCU (Control & Processing)               │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │  SPI     │  │  UART    │  │  GPIO    │  │  Timer   │    │
│  │ Driver   │  │ Driver   │  │ Control  │  │ PWM      │    │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘    │
│       │            │              │              │            │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │ FPGA     │  │ USB/PC   │  │ LEDs/    │  │ RF       │    │
│  │ Config   │  │ Interface│  │ Buttons  │  │ Switches │    │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘    │
└──────────────────────┼──────────────────────────────────────┘
                       │ USB/Serial
┌──────────────────────┼──────────────────────────────────────┐
│                  PC Software (GUI)                          │
│  - Spectrum Analyzer                                         │
│  - Signal Generation                                         │
│  - Configuration Interface                                   │
│  - Data Logging & Analysis                                  │
└─────────────────────────────────────────────────────────────┘
```

## Project Structure
```
sdr_project/
├── fpga/
│   ├── rtl/          # Verilog/VHDL RTL code
│   ├── ip/           # IP cores and generated blocks
│   ├── constraints/  # Timing and pin constraints
│   └── sim/          # Testbenches and simulation scripts
├── embedded/
│   ├── src/          # Embedded C/C++ source
│   ├── inc/          # Header files
│   └── drivers/      # Hardware drivers
├── software/
│   ├── src/          # PC software source
│   └── gui/          # GUI components
├── docs/             # Documentation
└── tests/            # Test scripts and verification
```

## Key Components

### FPGA RF Front-end
- **ADC Interface**: High-speed data capture from RF front-end
- **Digital Down Converter (DDC)**: Mixing, filtering, decimation
- **DSP Processing**: FFT, filtering, demodulation
- **DAC Interface**: Output to transmitter chain
- **Control Logic**: Register map, configuration interface

### Embedded Control
- **FPGA Configuration**: SPI programming and register access
- **User Interface**: Buttons, LEDs, display
- **Communication**: USB/UART to PC
- **Signal Processing**: Additional DSP algorithms
- **System Management**: Power sequencing, monitoring

### PC Software
- **GUI Interface**: Control panel and visualization
- **Signal Analysis**: Spectrum display, waterfall plots
- **Data Processing**: Demodulation, decoding
- **Configuration**: FPGA parameter tuning

## Hardware Requirements
- FPGA Board (Xilinx/Altera) with:
  - High-speed ADC/DAC interfaces
  - Sufficient DSP slices
  - Memory blocks
- RF Front-end Board:
  - LNA, Mixer, Filters
  - Local Oscillator
  - Variable Gain Amplifiers
- Microcontroller (ARM Cortex-M or similar)
- RF Shield and connectors

## Software Requirements
- FPGA Tools: Vivado/Quartus
- Embedded: GCC ARM, OpenOCD
- PC: Python/Qt or similar for GUI
- Signal Processing: NumPy, SciPy, GNU Radio

## Build Instructions
See individual component READMEs for detailed build instructions.

## License
MIT License - See LICENSE file for details

## Authors
SDR Project Team

# SDR System Architecture

## System Overview

The Software-Defined Radio system implements a complete RF signal processing chain using FPGA digital signal processing, embedded microcontroller control, and PC software interface.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         PC Software Layer                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │  GUI         │  │  Controller  │  │  Signal      │          │
│  │  Interface   │  │  Library     │  │  Processing  │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└──────────────────────────────┬──────────────────────────────────┘
                               │ USB/Serial
┌──────────────────────────────┴──────────────────────────────────┐
│                      Embedded Control Layer                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │  SPI         │  │  Control     │  │  System      │          │
│  │  Master      │  │  Logic       │  │  Monitor     │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└──────────────────────────────┬──────────────────────────────────┘
                               │ SPI
┌──────────────────────────────┴──────────────────────────────────┐
│                        FPGA Processing Layer                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │  ADC         │  │  DSP         │  │  DAC         │          │
│  │  Interface   │  │  Pipeline    │  │  Interface   │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└──────────────────────────────┬──────────────────────────────────┘
                               │ LVDS
┌──────────────────────────────┴──────────────────────────────────┐
│                         RF Front-end Layer                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │  LNA         │  │  Mixer       │  │  VGA         │          │
│  │  Amplifier   │  │  Frequency   │  │  Control     │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└─────────────────────────────────────────────────────────────────┘
```

## FPGA Architecture

### Signal Processing Pipeline

```
RF Input → LNA → Mixer → ADC → FPGA Processing → DAC → Mixer → VGA → RF Output
              ↑           ↓       ↓                           ↓
            LO         LVDS   DSP Pipeline                 RF Out
                            ↓
                    ┌───────────────┐
                    │  ADC Interface│
                    └───────┬───────┘
                            ↓
                    ┌───────────────┐
                    │  DDC Module   │
                    │  - NCO        │
                    │  - Mixer      │
                    │  - CIC Filter │
                    │  - Decimation │
                    └───────┬───────┘
                            ↓
                    ┌───────────────┐
                    │  FIR Filter   │
                    │  - Coeffs     │
                    │  - Pipeline    │
                    └───────┬───────┘
                            ↓
                    ┌───────────────┐
                    │  FFT Module   │
                    │  - Bit-rev    │
                    │  - Butterflies │
                    │  - Twiddle    │
                    └───────┬───────┘
                            ↓
                    ┌───────────────┐
                    │  DAC Interface│
                    └───────┬───────┘
                            ↓
                          RF Output
```

### FPGA Module Hierarchy

```
sdr_top (Top Level)
├── adc_interface
│   ├── Clock domain crossing
│   ├── Data capture
│   └── Memory interface
├── ddc (Digital Down Converter)
│   ├── NCO (Numerically Controlled Oscillator)
│   ├── Complex mixer
│   ├── CIC filter (4 stages)
│   └── Decimation logic
├── fir_filter
│   ├── Coefficient storage
│   ├── MAC pipeline
│   └── Accumulator
├── fft_module
│   ├── Bit-reverse addressing
│   ├── Butterfly units
│   ├── Twiddle ROM
│   └── Stage control
├── dac_interface
│   ├── Data formatting
│   ├── Timing control
│   └── Clock generation
├── control_logic
│   ├── SPI slave interface
│   ├── Register map
│   └── Status monitoring
├── uart_interface
│   ├── Transmitter
│   ├── Receiver
│   └── Baud rate generator
└── i2c_interface
    ├── I2C master
    ├── State machine
    └── Clock stretching
```

## Embedded System Architecture

### Software Stack

```
Application Layer
├── Main Control Loop
├── System Monitor
└── Error Handler

Middleware Layer
├── SPI Driver
├── UART Driver
├── GPIO Driver
└── Timer Driver

Hardware Abstraction Layer
├── Register Access
├── Memory Management
└── Interrupt Handling

Hardware Layer
├── ARM Cortex-M4/M7
├── SPI/I2C/UART Peripherals
├── GPIO Ports
└── Timers
```

### Control Flow

```
┌──────────────┐
│  Initialize  │
└──────┬───────┘
       ↓
┌──────────────┐
│  Configure   │
│  FPGA        │
└──────┬───────┘
       ↓
┌──────────────┐
│  Start       │
│  System      │
└──────┬───────┘
       ↓
┌──────────────┐
│  Main Loop   │◄────┐
│  - Status    │     │
│  - Monitor   │     │
│  - Commands  │     │
└──────┬───────┘     │
       ↓             │
┌──────────────┐     │
│  Process     │     │
│  Commands    │─────┘
└──────┬───────┘
       ↓
┌──────────────┐
│  Handle     │
│  Errors     │
└──────┬───────┘
       ↓
┌──────────────┐
│  Shutdown    │
└──────────────┘
```

## PC Software Architecture

### Module Structure

```
SDR Controller Library
├── Serial Communication
│   ├── Port management
│   ├── Protocol handling
│   └── Error recovery
├── Command Processing
│   ├── Frequency control
│   ├── Sample configuration
│   └── Component enable/disable
├── Data Processing
│   ├── Buffer management
│   ├── Format conversion
│   └── Callback handling
└── Status Monitoring
    ├── Error detection
    ├── Performance metrics
    └── System health

GUI Application
├── Control Panel
│   ├── Connection settings
│   ├── Frequency control
│   ├── Sample configuration
│   └── Component toggles
├── Visualization
│   ├── Spectrum plot
│   ├── Time domain plot
│   └── Waterfall display
├── Status Display
│   ├── System status
│   ├── Error logging
│   └── Performance metrics
└── Menu System
    ├── File operations
    ├── View options
    └── Help system
```

### Data Flow

```
User Input → GUI → Controller → Serial → MCU → SPI → FPGA → RF Processing
                                               ↓
                                        Status/Telemetry
                                               ↓
                                        SPI → MCU → Serial → Controller → GUI → Display
```

## Communication Protocols

### SPI Protocol (MCU ↔ FPGA)

```
Frame Format:
┌────────┬──────────┬──────────┬──────────┐
│ Address│ Data Len │  Data    │  CRC     │
│ 8 bits │ 16 bits  │ 0-32 bits│ 8 bits  │
└────────┴──────────┴──────────┴──────────┘

Transaction Types:
- Write: Register configuration
- Read: Status and telemetry
- Command: System control
```

### Serial Protocol (PC ↔ MCU)

```
Packet Format:
┌──────────┬──────────┬──────────┬──────────┬────────┐
│ Command  │ Data Len │  Data    │ Error    │ CRC    │
│ 8 bits  │ 16 bits  │ Variable │ 8 bits  │ 8 bits │
└──────────┴──────────┴──────────┴──────────┴────────┘

Command Set:
- 0x01: Set frequency
- 0x02: Set sample count
- 0x03: Set decimation
- 0x04-0x07: Enable components
- 0x08-0x09: Get status/error
- 0x0A-0x0C: System control
- 0x0D-0x0E: Data transfer
```

## Memory Architecture

### FPGA Memory Map

```
Register Map (SPI Access):
0x00: Frequency Word (NCO)
0x04: Sample Count
0x08: Enable Flags
0x0C: Decimation Factor
0x10: Filter Taps
0x14: Status Register
0x18: Error Register
0x1C: Phase Accumulator

Memory Buffers:
0x1000-0x1FFF: ADC Data Buffer (4KB)
0x2000-0x2FFF: FFT Output Buffer (4KB)
0x3000-0x3FFF: Filter Coefficients (4KB)
```

### Embedded Memory Map

```
Flash Memory:
0x0800-0000: Application Code
0x0801-0000: Configuration Data
0x0802-0000: Calibration Data

SRAM:
0x2000-0000: Data Stack
0x2000-2000: SPI Buffers
0x2000-4000: UART Buffers
0x2000-6000: Application Data
```

## Timing Architecture

### Clock Domains

```
Primary Clock: 50 MHz (FPGA)
├── ADC Clock: 50 MHz (synchronous)
├── DAC Clock: 50 MHz (synchronous)
├── Processing Clock: 50 MHz (synchronous)
└── SPI Clock: 1 MHz (asynchronous)

MCU Clock: 100 MHz
├── System Clock: 100 MHz
├── Peripheral Clock: 50 MHz
└── Timer Clock: 100 MHz

PC System: Variable
├── GUI Update: 20 Hz
├── Status Poll: 1 Hz
└── Data Stream: As needed
```

### Timing Budget

```
End-to-End Latency:
ADC Capture: 20 ns (1 cycle)
DDC Processing: 120 ns (6 cycles)
FIR Filtering: 80 ns (4 cycles)
FFT Processing: 2048 ns (1024 cycles)
DAC Output: 20 ns (1 cycle)
Total FPGA: 180 ns

MCU Processing:
SPI Transaction: 42 μs
Command Processing: 8 μs
Total MCU: 50 μs

PC Processing:
GUI Update: 45 ms
Data Processing: 12 ms
Total PC: 57 ms

System Total: ~57 ms (dominated by PC)
```

## Error Handling Architecture

### Error Detection

```
FPGA Level:
- Overflow detection (ADC/DAC)
- Timeout detection (SPI)
- Parity checking (Memory)
- Status monitoring

MCU Level:
- CRC validation (Communication)
- Timeout handling (SPI/UART)
- Range checking (Parameters)
- System monitoring (Watchdog)

PC Level:
- Connection checking (Serial)
- Protocol validation (Packets)
- Data validation (Ranges)
- Exception handling (GUI)
```

### Error Recovery

```
FPGA Recovery:
- Automatic reset on critical errors
- Graceful degradation
- Status flagging

MCU Recovery:
- Retry mechanisms
- Fallback defaults
- System reset (last resort)

PC Recovery:
- Reconnection attempts
- State restoration
- User notification
```

## Security Architecture

### Access Control

```
FPGA Level:
- Register access permissions
- Write protection for critical registers
- Operation mode restrictions

MCU Level:
- Command authentication
- Parameter validation
- Operation limits

PC Level:
- User authentication (optional)
- Access logging
- Operation auditing
```

### Data Protection

```
Communication:
- CRC error detection
- Acknowledgment protocols
- Retry mechanisms

Storage:
- Configuration backup
- State preservation
- Recovery procedures
```

## Scalability Architecture

### Modular Design

```
Add New FPGA Module:
1. Create module with standard interface
2. Add to top-level integration
3. Update control registers
4. Add testbench
5. Update documentation

Add New Embedded Feature:
1. Extend control library
2. Add command protocol
3. Update GUI interface
4. Add error handling
5. Test integration

Add New PC Feature:
1. Extend controller library
2. Add GUI components
3. Update visualization
4. Add documentation
5. Test user workflow
```

### Performance Scaling

```
FPGA Scaling:
- Increase clock frequency
- Add parallel processing
- Optimize memory bandwidth
- Use pipelining

MCU Scaling:
- Upgrade to faster MCU
- Use DMA for data transfer
- Optimize algorithms
- Add caching

PC Scaling:
- Multi-threading
- GPU acceleration
- Optimized libraries
- Network distribution
```

This architecture provides a solid foundation for current implementation and future enhancements of the SDR system.

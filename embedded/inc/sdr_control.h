#ifndef SDR_CONTROL_H
#define SDR_CONTROL_H

#include <stdint.h>
#include <stdbool.h>
#ifndef bool
#define bool int
#define true 1
#define false 0
#endif

// Register addresses (must match FPGA)
#define REG_FREQ_WORD        0x00
#define REG_SAMPLE_COUNT     0x04
#define REG_ENABLE           0x08
#define REG_DECIMATION       0x0C
#define REG_FILTER_TAPS      0x10
#define REG_STATUS           0x14
#define REG_ERROR            0x18
#define REG_PHASE_ACC        0x1C

// Control bit masks
#define ENABLE_ADC_MASK      0x01
#define ENABLE_DAC_MASK      0x02
#define ENABLE_DDC_MASK      0x04
#define ENABLE_FILTER_MASK   0x08

// System configuration
#define SPI_CLOCK_SPEED      1000000  // 1 MHz
#define TIMEOUT_MS           1000

// Error codes
typedef enum {
    SDR_OK = 0,
    SDR_SPI_ERROR,
    SDR_TIMEOUT,
    SDR_INVALID_PARAM,
    SDR_HARDWARE_ERROR
} sdr_error_t;

// SDR control structure
typedef struct {
    // Hardware interface
    int spi_fd;
    int uart_fd;
    
    // Current configuration
    uint32_t frequency_word;
    uint32_t sample_count;
    uint8_t enable_flags;
    uint32_t decimation_factor;
    uint32_t filter_taps;
    
    // Status
    uint32_t status_reg;
    uint32_t error_reg;
    uint32_t phase_acc;
    
    // Callback functions
    void (*data_callback)(uint8_t* data, size_t len);
    void (*error_callback)(sdr_error_t error);
} sdr_control_t;

// Function prototypes
sdr_error_t sdr_init(sdr_control_t* ctrl);
sdr_error_t sdr_deinit(sdr_control_t* ctrl);

// Register access
sdr_error_t sdr_write_register(sdr_control_t* ctrl, uint8_t addr, uint32_t value);
sdr_error_t sdr_read_register(sdr_control_t* ctrl, uint8_t addr, uint32_t* value);

// Configuration functions
sdr_error_t sdr_set_frequency(sdr_control_t* ctrl, uint32_t freq_hz);
sdr_error_t sdr_set_sample_count(sdr_control_t* ctrl, uint32_t count);
sdr_error_t sdr_set_decimation(sdr_control_t* ctrl, uint32_t decimation);
sdr_error_t sdr_enable_adc(sdr_control_t* ctrl, int enable);
sdr_error_t sdr_enable_dac(sdr_control_t* ctrl, int enable);
sdr_error_t sdr_enable_ddc(sdr_control_t* ctrl, int enable);
sdr_error_t sdr_enable_filter(sdr_control_t* ctrl, int enable);

// Status functions
sdr_error_t sdr_get_status(sdr_control_t* ctrl, uint32_t* status);
sdr_error_t sdr_get_error(sdr_control_t* ctrl, uint32_t* error);
sdr_error_t sdr_get_phase(sdr_control_t* ctrl, uint32_t* phase);

// System control
sdr_error_t sdr_start(sdr_control_t* ctrl);
sdr_error_t sdr_stop(sdr_control_t* ctrl);
sdr_error_t sdr_reset(sdr_control_t* ctrl);

// Data transfer
sdr_error_t sdr_read_data(sdr_control_t* ctrl, uint8_t* buffer, size_t len);
sdr_error_t sdr_write_data(sdr_control_t* ctrl, uint8_t* data, size_t len);

#endif // SDR_CONTROL_H

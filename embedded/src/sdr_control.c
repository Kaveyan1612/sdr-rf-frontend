#include "sdr_control.h"
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <linux/spi/spidev.h>

// SPI transfer helper function
static sdr_error_t spi_transfer(sdr_control_t* ctrl, uint8_t* tx, uint8_t* rx, size_t len) {
    struct spi_ioc_transfer tr = {
        .tx_buf = (unsigned long)tx,
        .rx_buf = (unsigned long)rx,
        .len = len,
        .speed_hz = SPI_CLOCK_SPEED,
        .bits_per_word = 8,
    };

    if (ioctl(ctrl->spi_fd, SPI_IOC_MESSAGE(1), &tr) < 0) {
        return SDR_SPI_ERROR;
    }

    return SDR_OK;
}

// Initialize SDR control
sdr_error_t sdr_init(sdr_control_t* ctrl) {
    if (!ctrl) {
        return SDR_INVALID_PARAM;
    }

    // Open SPI device
    ctrl->spi_fd = open("/dev/spidev0.0", O_RDWR);
    if (ctrl->spi_fd < 0) {
        return SDR_SPI_ERROR;
    }

    // Configure SPI
    uint32_t mode = SPI_MODE_0;
    if (ioctl(ctrl->spi_fd, SPI_IOC_WR_MODE, &mode) < 0) {
        close(ctrl->spi_fd);
        return SDR_SPI_ERROR;
    }

    uint8_t bits = 8;
    if (ioctl(ctrl->spi_fd, SPI_IOC_WR_BITS_PER_WORD, &bits) < 0) {
        close(ctrl->spi_fd);
        return SDR_SPI_ERROR;
    }

    // Initialize default values
    ctrl->frequency_word = 0x10000000;
    ctrl->sample_count = 1024;
    ctrl->enable_flags = 0;
    ctrl->decimation_factor = 16;
    ctrl->filter_taps = 16;
    ctrl->status_reg = 0;
    ctrl->error_reg = 0;
    ctrl->phase_acc = 0;
    ctrl->data_callback = NULL;
    ctrl->error_callback = NULL;

    return SDR_OK;
}

// Deinitialize SDR control
sdr_error_t sdr_deinit(sdr_control_t* ctrl) {
    if (!ctrl) {
        return SDR_INVALID_PARAM;
    }

    if (ctrl->spi_fd >= 0) {
        close(ctrl->spi_fd);
        ctrl->spi_fd = -1;
    }

    if (ctrl->uart_fd >= 0) {
        close(ctrl->uart_fd);
        ctrl->uart_fd = -1;
    }

    return SDR_OK;
}

// Write to FPGA register
sdr_error_t sdr_write_register(sdr_control_t* ctrl, uint8_t addr, uint32_t value) {
    if (!ctrl || ctrl->spi_fd < 0) {
        return SDR_INVALID_PARAM;
    }

    uint8_t tx_buffer[5];
    uint8_t rx_buffer[5];

    tx_buffer[0] = addr;
    tx_buffer[1] = (value >> 24) & 0xFF;
    tx_buffer[2] = (value >> 16) & 0xFF;
    tx_buffer[3] = (value >> 8) & 0xFF;
    tx_buffer[4] = value & 0xFF;

    sdr_error_t result = spi_transfer(ctrl, tx_buffer, rx_buffer, 5);
    if (result != SDR_OK) {
        return result;
    }

    return SDR_OK;
}

// Read from FPGA register
sdr_error_t sdr_read_register(sdr_control_t* ctrl, uint8_t addr, uint32_t* value) {
    if (!ctrl || !value || ctrl->spi_fd < 0) {
        return SDR_INVALID_PARAM;
    }

    uint8_t tx_buffer[5];
    uint8_t rx_buffer[5];

    tx_buffer[0] = addr | 0x80; // Set read bit
    tx_buffer[1] = 0;
    tx_buffer[2] = 0;
    tx_buffer[3] = 0;
    tx_buffer[4] = 0;

    sdr_error_t result = spi_transfer(ctrl, tx_buffer, rx_buffer, 5);
    if (result != SDR_OK) {
        return result;
    }

    *value = (rx_buffer[1] << 24) | (rx_buffer[2] << 16) | 
             (rx_buffer[3] << 8) | rx_buffer[4];

    return SDR_OK;
}

// Set frequency (convert Hz to frequency word)
sdr_error_t sdr_set_frequency(sdr_control_t* ctrl, uint32_t freq_hz) {
    if (!ctrl) {
        return SDR_INVALID_PARAM;
    }

    // Convert frequency to NCO word (assuming 50 MHz sample rate)
    // frequency_word = (freq_hz / sample_rate) * 2^32
    uint64_t freq_word = ((uint64_t)freq_hz << 32) / 50000000;
    ctrl->frequency_word = (uint32_t)freq_word;

    return sdr_write_register(ctrl, REG_FREQ_WORD, ctrl->frequency_word);
}

// Set sample count
sdr_error_t sdr_set_sample_count(sdr_control_t* ctrl, uint32_t count) {
    if (!ctrl || count == 0) {
        return SDR_INVALID_PARAM;
    }

    ctrl->sample_count = count;
    return sdr_write_register(ctrl, REG_SAMPLE_COUNT, count);
}

// Set decimation factor
sdr_error_t sdr_set_decimation(sdr_control_t* ctrl, uint32_t decimation) {
    if (!ctrl || decimation == 0) {
        return SDR_INVALID_PARAM;
    }

    ctrl->decimation_factor = decimation;
    return sdr_write_register(ctrl, REG_DECIMATION, decimation);
}

// Enable/disable ADC
sdr_error_t sdr_enable_adc(sdr_control_t* ctrl, int enable) {
    if (!ctrl) {
        return SDR_INVALID_PARAM;
    }

    if (enable) {
        ctrl->enable_flags |= ENABLE_ADC_MASK;
    } else {
        ctrl->enable_flags &= ~ENABLE_ADC_MASK;
    }

    return sdr_write_register(ctrl, REG_ENABLE, ctrl->enable_flags);
}

// Enable/disable DAC
sdr_error_t sdr_enable_dac(sdr_control_t* ctrl, int enable) {
    if (!ctrl) {
        return SDR_INVALID_PARAM;
    }

    if (enable) {
        ctrl->enable_flags |= ENABLE_DAC_MASK;
    } else {
        ctrl->enable_flags &= ~ENABLE_DAC_MASK;
    }

    return sdr_write_register(ctrl, REG_ENABLE, ctrl->enable_flags);
}

// Enable/disable DDC
sdr_error_t sdr_enable_ddc(sdr_control_t* ctrl, int enable) {
    if (!ctrl) {
        return SDR_INVALID_PARAM;
    }

    if (enable) {
        ctrl->enable_flags |= ENABLE_DDC_MASK;
    } else {
        ctrl->enable_flags &= ~ENABLE_DDC_MASK;
    }

    return sdr_write_register(ctrl, REG_ENABLE, ctrl->enable_flags);
}

// Enable/disable filter
sdr_error_t sdr_enable_filter(sdr_control_t* ctrl, int enable) {
    if (!ctrl) {
        return SDR_INVALID_PARAM;
    }

    if (enable) {
        ctrl->enable_flags |= ENABLE_FILTER_MASK;
    } else {
        ctrl->enable_flags &= ~ENABLE_FILTER_MASK;
    }

    return sdr_write_register(ctrl, REG_ENABLE, ctrl->enable_flags);
}

// Get status register
sdr_error_t sdr_get_status(sdr_control_t* ctrl, uint32_t* status) {
    if (!ctrl || !status) {
        return SDR_INVALID_PARAM;
    }

    sdr_error_t result = sdr_read_register(ctrl, REG_STATUS, &ctrl->status_reg);
    if (result == SDR_OK) {
        *status = ctrl->status_reg;
    }

    return result;
}

// Get error register
sdr_error_t sdr_get_error(sdr_control_t* ctrl, uint32_t* error) {
    if (!ctrl || !error) {
        return SDR_INVALID_PARAM;
    }

    sdr_error_t result = sdr_read_register(ctrl, REG_ERROR, &ctrl->error_reg);
    if (result == SDR_OK) {
        *error = ctrl->error_reg;
    }

    return result;
}

// Get phase accumulator
sdr_error_t sdr_get_phase(sdr_control_t* ctrl, uint32_t* phase) {
    if (!ctrl || !phase) {
        return SDR_INVALID_PARAM;
    }

    sdr_error_t result = sdr_read_register(ctrl, REG_PHASE_ACC, &ctrl->phase_acc);
    if (result == SDR_OK) {
        *phase = ctrl->phase_acc;
    }

    return result;
}

// Start SDR system
sdr_error_t sdr_start(sdr_control_t* ctrl) {
    if (!ctrl) {
        return SDR_INVALID_PARAM;
    }

    // Enable all components
    sdr_error_t result = sdr_enable_adc(ctrl, 1);
    if (result != SDR_OK) return result;

    result = sdr_enable_ddc(ctrl, 1);
    if (result != SDR_OK) return result;

    result = sdr_enable_filter(ctrl, 1);
    if (result != SDR_OK) return result;

    return sdr_enable_dac(ctrl, 1);
}

// Stop SDR system
sdr_error_t sdr_stop(sdr_control_t* ctrl) {
    if (!ctrl) {
        return SDR_INVALID_PARAM;
    }

    // Disable all components
    sdr_error_t result = sdr_enable_adc(ctrl, 0);
    if (result != SDR_OK) return result;

    result = sdr_enable_dac(ctrl, 0);
    if (result != SDR_OK) return result;

    result = sdr_enable_ddc(ctrl, 0);
    if (result != SDR_OK) return result;

    return sdr_enable_filter(ctrl, 0);
}

// Reset SDR system
sdr_error_t sdr_reset(sdr_control_t* ctrl) {
    if (!ctrl) {
        return SDR_INVALID_PARAM;
    }

    sdr_error_t result = sdr_stop(ctrl);
    if (result != SDR_OK) return result;

    // Reset configuration to defaults
    ctrl->frequency_word = 0x10000000;
    ctrl->sample_count = 1024;
    ctrl->decimation_factor = 16;
    ctrl->filter_taps = 16;

    // Write default values
    result = sdr_write_register(ctrl, REG_FREQ_WORD, ctrl->frequency_word);
    if (result != SDR_OK) return result;

    result = sdr_write_register(ctrl, REG_SAMPLE_COUNT, ctrl->sample_count);
    if (result != SDR_OK) return result;

    result = sdr_write_register(ctrl, REG_DECIMATION, ctrl->decimation_factor);
    if (result != SDR_OK) return result;

    return sdr_write_register(ctrl, REG_FILTER_TAPS, ctrl->filter_taps);
}

// Read data from FPGA
sdr_error_t sdr_read_data(sdr_control_t* ctrl, uint8_t* buffer, size_t len) {
    if (!ctrl || !buffer || len == 0) {
        return SDR_INVALID_PARAM;
    }

    // This would typically read from a memory-mapped region or DMA buffer
    // For now, this is a placeholder for the actual implementation
    memset(buffer, 0, len);
    
    return SDR_OK;
}

// Write data to FPGA
sdr_error_t sdr_write_data(sdr_control_t* ctrl, uint8_t* data, size_t len) {
    if (!ctrl || !data || len == 0) {
        return SDR_INVALID_PARAM;
    }

    // This would typically write to a memory-mapped region or DMA buffer
    // For now, this is a placeholder for the actual implementation
    
    return SDR_OK;
}

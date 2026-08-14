#include "sdr_control.h"
#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <unistd.h>

static volatile int running = 1;

// Signal handler for graceful shutdown
void signal_handler(int signum) {
    (void)signum; // Unused parameter
    running = 0;
}

// Data callback function
void data_received_callback(uint8_t* data, size_t len) {
    printf("Received %lu bytes of data\n", (unsigned long)len);
    // Process data here
}

// Error callback function
void error_callback(sdr_error_t error) {
    const char* error_str;
    switch (error) {
        case SDR_OK:
            error_str = "No error";
            break;
        case SDR_SPI_ERROR:
            error_str = "SPI communication error";
            break;
        case SDR_TIMEOUT:
            error_str = "Operation timeout";
            break;
        case SDR_INVALID_PARAM:
            error_str = "Invalid parameter";
            break;
        case SDR_HARDWARE_ERROR:
            error_str = "Hardware error";
            break;
        default:
            error_str = "Unknown error";
    }
    printf("Error: %s\n", error_str);
}

int main(int argc, char* argv[]) {
    sdr_control_t sdr_ctrl;
    sdr_error_t result;
    
    printf("SDR Embedded Control Application\n");
    printf("================================\n\n");
    
    // Set up signal handling
    signal(SIGINT, signal_handler);
    signal(SIGTERM, signal_handler);
    
    // Initialize SDR control
    printf("Initializing SDR control...\n");
    result = sdr_init(&sdr_ctrl);
    if (result != SDR_OK) {
        printf("Failed to initialize SDR control: %d\n", result);
        return 1;
    }
    
    // Set up callbacks
    sdr_ctrl.data_callback = data_received_callback;
    sdr_ctrl.error_callback = error_callback;
    
    // Configure SDR parameters
    printf("Configuring SDR parameters...\n");
    
    // Set frequency to 1 MHz
    result = sdr_set_frequency(&sdr_ctrl, 1000000);
    if (result != SDR_OK) {
        printf("Failed to set frequency: %d\n", result);
        sdr_deinit(&sdr_ctrl);
        return 1;
    }
    printf("Frequency set to 1 MHz\n");
    
    // Set sample count
    result = sdr_set_sample_count(&sdr_ctrl, 2048);
    if (result != SDR_OK) {
        printf("Failed to set sample count: %d\n", result);
        sdr_deinit(&sdr_ctrl);
        return 1;
    }
    printf("Sample count set to 2048\n");
    
    // Set decimation factor
    result = sdr_set_decimation(&sdr_ctrl, 16);
    if (result != SDR_OK) {
        printf("Failed to set decimation: %d\n", result);
        sdr_deinit(&sdr_ctrl);
        return 1;
    }
    printf("Decimation factor set to 16\n");
    
    // Start SDR system
    printf("Starting SDR system...\n");
    result = sdr_start(&sdr_ctrl);
    if (result != SDR_OK) {
        printf("Failed to start SDR system: %d\n", result);
        sdr_deinit(&sdr_ctrl);
        return 1;
    }
    printf("SDR system started\n\n");
    
    // Main loop
    printf("Entering main loop (press Ctrl+C to stop)...\n");
    uint32_t status, error, phase;
    int loop_count = 0;
    
    while (running) {
        usleep(100000); // 100ms delay
        
        // Read status every second
        if (loop_count % 10 == 0) {
            result = sdr_get_status(&sdr_ctrl, &status);
            if (result == SDR_OK) {
                printf("Status: 0x%08X\n", status);
            }
            
            result = sdr_get_error(&sdr_ctrl, &error);
            if (result == SDR_OK && error != 0) {
                printf("Error: 0x%08X\n", error);
            }
            
            result = sdr_get_phase(&sdr_ctrl, &phase);
            if (result == SDR_OK) {
                printf("Phase: 0x%08X\n", phase);
            }
        }
        
        loop_count++;
    }
    
    // Stop SDR system
    printf("\nStopping SDR system...\n");
    result = sdr_stop(&sdr_ctrl);
    if (result != SDR_OK) {
        printf("Failed to stop SDR system: %d\n", result);
    }
    
    // Deinitialize SDR control
    printf("Deinitializing SDR control...\n");
    result = sdr_deinit(&sdr_ctrl);
    if (result != SDR_OK) {
        printf("Failed to deinitialize SDR control: %d\n", result);
        return 1;
    }
    
    printf("SDR control deinitialized\n");
    printf("Exiting...\n");
    
    return 0;
}

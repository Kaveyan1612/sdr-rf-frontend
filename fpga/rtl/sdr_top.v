// SDR Top-Level Module
// Integrates all RF front-end components
// Complete SDR system with ADC, DDC, Filter, and DAC

module sdr_top #(
    parameter DATA_WIDTH = 14,
    parameter ADC_DATA_WIDTH = 14,
    parameter DAC_DATA_WIDTH = 14,
    parameter MIXER_WIDTH = 16,
    parameter CIC_STAGES = 4,
    parameter DECIMATION = 16,
    parameter FILTER_TAPS = 16,
    parameter COEFF_WIDTH = 16,
    parameter OUTPUT_WIDTH = 24
)(
    // Clock and reset
    input wire clk,
    input wire reset_n,
    input wire adc_clk,
    input wire dac_clk,
    
    // ADC interface
    input wire [ADC_DATA_WIDTH-1:0] adc_data,
    input wire adc_data_valid,
    input wire adc_overflow,
    
    // DAC interface
    output wire [DAC_DATA_WIDTH-1:0] dac_data,
    output wire dac_data_valid,
    output wire dac_enable,
    
    // SPI control interface
    input wire spi_clk,
    input wire spi_mosi,
    output wire spi_miso,
    input wire spi_cs_n,
    
    // Status LEDs
    output wire [7:0] status_leds,
    
    // Memory interface (optional external memory)
    output wire [31:0] mem_addr,
    inout wire [DATA_WIDTH-1:0] mem_data,
    output wire mem_write,
    output wire mem_read,
    input wire mem_ready
);

    // Control signals
    wire [31:0] frequency_word;
    wire [31:0] sample_count;
    wire enable_adc;
    wire enable_dac;
    wire enable_ddc;
    wire enable_filter;
    wire [31:0] decimation_factor;
    wire [31:0] filter_taps_config;
    
    // Status signals
    wire [31:0] adc_sample_count;
    wire [31:0] dac_sample_count;
    wire adc_overflow_flag;
    wire dac_underflow_flag;
    wire [31:0] phase_acc;
    
    // Internal data paths
    wire [DATA_WIDTH-1:0] adc_interface_data;
    wire adc_interface_valid;
    wire [DATA_WIDTH-1:0] ddc_i_data;
    wire [DATA_WIDTH-1:0] ddc_q_data;
    wire ddc_valid;
    wire signed [DATA_WIDTH-1:0] filter_data_in;
    wire filter_data_valid_in;
    wire signed [OUTPUT_WIDTH-1:0] filter_data_out;
    wire filter_data_valid_out;
    wire [DATA_WIDTH-1:0] dac_data_in;
    wire dac_data_valid_in;
    
    // Filter coefficients (default low-pass filter)
    wire [COEFF_WIDTH-1:0] filter_coefficients [0:FILTER_TAPS-1];
    
    // Generate filter coefficients (example Hamming window)
    assign filter_coefficients[0] = 16'h0010;
    assign filter_coefficients[1] = 16'h0020;
    assign filter_coefficients[2] = 16'h0040;
    assign filter_coefficients[3] = 16'h0080;
    assign filter_coefficients[4] = 16'h0100;
    assign filter_coefficients[5] = 16'h0200;
    assign filter_coefficients[6] = 16'h0400;
    assign filter_coefficients[7] = 16'h0800;
    assign filter_coefficients[8] = 16'h0800;
    assign filter_coefficients[9] = 16'h0400;
    assign filter_coefficients[10] = 16'h0200;
    assign filter_coefficients[11] = 16'h0100;
    assign filter_coefficients[12] = 16'h0080;
    assign filter_coefficients[13] = 16'h0040;
    assign filter_coefficients[14] = 16'h0020;
    assign filter_coefficients[15] = 16'h0010;
    
    // Control Logic Module
    control_logic control_logic_inst (
        .clk(clk),
        .reset_n(reset_n),
        .spi_clk(spi_clk),
        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso),
        .spi_cs_n(spi_cs_n),
        .frequency_word(frequency_word),
        .sample_count(sample_count),
        .enable_adc(enable_adc),
        .enable_dac(enable_dac),
        .enable_ddc(enable_ddc),
        .enable_filter(enable_filter),
        .decimation_factor(decimation_factor),
        .filter_taps(filter_taps_config),
        .adc_sample_count(adc_sample_count),
        .dac_sample_count(dac_sample_count),
        .adc_overflow(adc_overflow_flag),
        .dac_underflow(dac_underflow_flag),
        .phase_acc(phase_acc)
    );
    
    // ADC Interface Module
    adc_interface #(
        .DATA_WIDTH(ADC_DATA_WIDTH),
        .SAMPLE_RATE(50_000_000),
        .BUFFER_SIZE(1024)
    ) adc_interface_inst (
        .clk(clk),
        .reset_n(reset_n),
        .adc_clk(adc_clk),
        .adc_data(adc_data),
        .adc_data_valid(adc_data_valid),
        .adc_overflow(adc_overflow),
        .enable(enable_adc),
        .sample_count(sample_count),
        .data_out(adc_interface_data),
        .data_valid(adc_interface_valid),
        .sample_counter(adc_sample_count),
        .overflow_flag(adc_overflow_flag),
        .mem_addr(mem_addr),
        .mem_data(mem_data),
        .mem_write(mem_write),
        .mem_ready(mem_ready)
    );
    
    // Digital Down Converter Module
    ddc #(
        .DATA_WIDTH(DATA_WIDTH),
        .MIXER_WIDTH(MIXER_WIDTH),
        .CIC_STAGES(CIC_STAGES),
        .DECIMATION(DECIMATION),
        .PHASE_WIDTH(32)
    ) ddc_inst (
        .clk(clk),
        .reset_n(reset_n),
        .data_in(adc_interface_data),
        .data_valid_in(adc_interface_valid && enable_ddc),
        .frequency_word(frequency_word),
        .enable(enable_ddc),
        .i_out(ddc_i_data),
        .q_out(ddc_q_data),
        .data_valid_out(ddc_valid),
        .phase_accumulator(phase_acc)
    );
    
    // FIR Filter Module
    fir_filter #(
        .DATA_WIDTH(DATA_WIDTH),
        .COEFF_WIDTH(COEFF_WIDTH),
        .TAPS(FILTER_TAPS),
        .OUTPUT_WIDTH(OUTPUT_WIDTH)
    ) fir_filter_inst (
        .clk(clk),
        .reset_n(reset_n),
        .data_in(filter_data_in),
        .data_valid_in(filter_data_valid_in && enable_filter),
        .coefficients(filter_coefficients),
        .coeff_load(1'b0),
        .enable(enable_filter),
        .data_out(filter_data_out),
        .data_valid_out(filter_data_valid_out)
    );
    
    // Select I channel for filtering (can be modified for I/Q processing)
    assign filter_data_in = $signed(ddc_i_data);
    assign filter_data_valid_in = ddc_valid;
    
    // DAC Interface Module
    dac_interface #(
        .DATA_WIDTH(DAC_DATA_WIDTH),
        .SAMPLE_RATE(50_000_000),
        .BUFFER_SIZE(1024)
    ) dac_interface_inst (
        .clk(clk),
        .reset_n(reset_n),
        .dac_clk(dac_clk),
        .data_in(dac_data_in),
        .data_valid_in(dac_data_valid_in),
        .sample_count(sample_count),
        .enable(enable_dac),
        .dac_data(dac_data),
        .dac_data_valid(dac_data_valid),
        .dac_enable(dac_enable),
        .mem_addr(),
        .mem_data(),
        .mem_read(),
        .mem_ready(1'b1),
        .sample_counter(dac_sample_count),
        .underflow_flag(dac_underflow_flag)
    );
    
    // Connect filtered output to DAC (scale down to DAC width)
    assign dac_data_in = filter_data_out[OUTPUT_WIDTH-1:OUTPUT_WIDTH-DAC_DATA_WIDTH];
    assign dac_data_valid_in = filter_data_valid_out;
    
    // Status LEDs
    assign status_leds = {
        enable_adc,
        enable_dac,
        enable_ddc,
        enable_filter,
        adc_overflow_flag,
        dac_underflow_flag,
        ddc_valid,
        filter_data_valid_out
    };

endmodule

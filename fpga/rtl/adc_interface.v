// ADC Interface Module
// Handles high-speed data capture from ADC
// Supports parallel and serial interfaces

module adc_interface #(
    parameter DATA_WIDTH = 14,
    parameter SAMPLE_RATE = 50_000_000, // 50 MHz
    parameter BUFFER_SIZE = 1024
)(
    input wire clk,
    input wire reset_n,
    input wire adc_clk,
    input wire [DATA_WIDTH-1:0] adc_data,
    input wire adc_data_valid,
    input wire adc_overflow,
    
    // Control interface
    input wire enable,
    input wire [31:0] sample_count,
    
    // Output interface
    output reg [DATA_WIDTH-1:0] data_out,
    output reg data_valid,
    output reg [31:0] sample_counter,
    output reg overflow_flag,
    
    // Memory interface
    output wire [31:0] mem_addr,
    output wire [DATA_WIDTH-1:0] mem_data,
    output wire mem_write,
    input wire mem_ready
);

    // Internal registers
    reg [31:0] address_counter;
    reg [2:0] state;
    reg [DATA_WIDTH-1:0] data_buffer;
    
    // State machine states
    localparam IDLE = 0;
    localparam CAPTURE = 1;
    localparam WRITE = 2;
    localparam WAIT = 3;
    
    // Clock domain crossing (CDC)
    reg [DATA_WIDTH-1:0] adc_data_sync1, adc_data_sync2;
    reg adc_valid_sync1, adc_valid_sync2;
    
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            adc_data_sync1 <= 0;
            adc_data_sync2 <= 0;
            adc_valid_sync1 <= 0;
            adc_valid_sync2 <= 0;
        end else begin
            // Double-flop synchronizer
            adc_data_sync1 <= adc_data;
            adc_data_sync2 <= adc_data_sync1;
            adc_valid_sync1 <= adc_data_valid;
            adc_valid_sync2 <= adc_valid_sync1;
        end
    end
    
    // Main control logic
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= IDLE;
            data_out <= 0;
            data_valid <= 0;
            sample_counter <= 0;
            address_counter <= 0;
            overflow_flag <= 0;
            data_buffer <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (enable) begin
                        state <= CAPTURE;
                        sample_counter <= 0;
                        address_counter <= 0;
                        overflow_flag <= 0;
                    end
                    data_valid <= 0;
                end
                
                CAPTURE: begin
                    if (adc_valid_sync2) begin
                        data_buffer <= adc_data_sync2;
                        state <= WRITE;
                        
                        if (adc_overflow) begin
                            overflow_flag <= 1;
                        end
                    end
                end
                
                WRITE: begin
                    if (mem_ready) begin
                        data_out <= data_buffer;
                        data_valid <= 1;
                        sample_counter <= sample_counter + 1;
                        address_counter <= address_counter + 1;
                        
                        if (sample_counter >= sample_count) begin
                            state <= IDLE;
                        end else begin
                            state <= WAIT;
                        end
                    end
                end
                
                WAIT: begin
                    data_valid <= 0;
                    if (adc_valid_sync2) begin
                        data_buffer <= adc_data_sync2;
                        state <= WRITE;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
    
    // Memory interface
    assign mem_addr = address_counter;
    assign mem_data = data_buffer;
    assign mem_write = (state == WRITE) && mem_ready;

endmodule

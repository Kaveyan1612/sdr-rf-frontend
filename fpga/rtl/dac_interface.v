// DAC Interface Module
// Handles high-speed data output to DAC
// Supports parallel and serial interfaces

module dac_interface #(
    parameter DATA_WIDTH = 14,
    parameter SAMPLE_RATE = 50_000_000, // 50 MHz
    parameter BUFFER_SIZE = 1024
)(
    input wire clk,
    input wire reset_n,
    input wire dac_clk,
    
    // Input interface
    input wire [DATA_WIDTH-1:0] data_in,
    input wire data_valid_in,
    input wire [31:0] sample_count,
    
    // Control interface
    input wire enable,
    
    // DAC output
    output reg [DATA_WIDTH-1:0] dac_data,
    output reg dac_data_valid,
    output reg dac_enable,
    
    // Memory interface
    output wire [31:0] mem_addr,
    input wire [DATA_WIDTH-1:0] mem_data,
    output wire mem_read,
    input wire mem_ready,
    
    // Status
    output reg [31:0] sample_counter,
    output reg underflow_flag
);

    // Internal registers
    reg [31:0] address_counter;
    reg [2:0] state;
    reg [DATA_WIDTH-1:0] data_buffer;
    reg empty_flag;
    
    // State machine states
    localparam IDLE = 0;
    localparam READ = 1;
    localparam OUTPUT = 2;
    localparam WAIT = 3;
    
    // Main control logic
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= IDLE;
            dac_data <= 0;
            dac_data_valid <= 0;
            dac_enable <= 0;
            sample_counter <= 0;
            address_counter <= 0;
            underflow_flag <= 0;
            data_buffer <= 0;
            empty_flag <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (enable) begin
                        state <= READ;
                        sample_counter <= 0;
                        address_counter <= 0;
                        underflow_flag <= 0;
                        dac_enable <= 1;
                    end
                    dac_data_valid <= 0;
                end
                
                READ: begin
                    if (mem_ready) begin
                        data_buffer <= mem_data;
                        state <= OUTPUT;
                    end
                end
                
                OUTPUT: begin
                    dac_data <= data_buffer;
                    dac_data_valid <= 1;
                    sample_counter <= sample_counter + 1;
                    address_counter <= address_counter + 1;
                    
                    if (sample_counter >= sample_count) begin
                        state <= IDLE;
                        dac_enable <= 0;
                    end else begin
                        state <= WAIT;
                    end
                end
                
                WAIT: begin
                    dac_data_valid <= 0;
                    if (data_valid_in) begin
                        data_buffer <= data_in;
                        state <= OUTPUT;
                    end else if (mem_ready) begin
                        data_buffer <= mem_data;
                        state <= OUTPUT;
                    end else begin
                        underflow_flag <= 1;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
    
    // Memory interface
    assign mem_addr = address_counter;
    assign mem_read = (state == READ);

endmodule

// FFT Module
// Implements radix-2 FFT for frequency domain analysis
// Configurable size and data width

module fft_module #(
    parameter DATA_WIDTH = 16,
    parameter FFT_SIZE = 1024,
    parameter TWIDDLE_WIDTH = 16,
    parameter STAGE_WIDTH = 10
)(
    input wire clk,
    input wire reset_n,
    
    // Input interface
    input wire signed [DATA_WIDTH-1:0] data_in,
    input wire data_valid_in,
    input wire [STAGE_WIDTH-1:0] fft_size_config,
    
    // Control
    input wire enable,
    input wire start_fft,
    
    // Output interface
    output reg signed [DATA_WIDTH-1:0] real_out,
    output reg signed [DATA_WIDTH-1:0] imag_out,
    output reg data_valid_out,
    output reg [STAGE_WIDTH-1:0] bin_index,
    
    // Status
    output reg fft_busy,
    output reg fft_done
);

    // Internal registers
    reg signed [DATA_WIDTH-1:0] real_buffer [0:FFT_SIZE-1];
    reg signed [DATA_WIDTH-1:0] imag_buffer [0:FFT_SIZE-1];
    reg [STAGE_WIDTH-1:0] write_addr;
    reg [STAGE_WIDTH-1:0] read_addr;
    reg [STAGE_WIDTH-1:0] stage_counter;
    reg [STAGE_WIDTH-1:0] butterfly_counter;
    
    // State machine
    reg [3:0] state;
    localparam IDLE = 0;
    localparam INPUT = 1;
    localparam PROCESS = 2;
    localparam BUTTERFLY = 3;
    localparam OUTPUT = 4;
    localparam DONE = 5;
    
    // Twiddle factor ROM (simplified - would normally be larger)
    function signed [TWIDDLE_WIDTH-1:0] get_twiddle;
        input [STAGE_WIDTH-1:0] stage;
        input [STAGE_WIDTH-1:0] index;
        begin
            // Simplified twiddle factors for demonstration
            // In real implementation, this would be a ROM with actual twiddle factors
            case (stage)
                0: get_twiddle = 16'h4000; // 1.0
                1: get_twiddle = 16'h4000; // 1.0
                2: get_twiddle = 16'h2D41; // 0.707
                3: get_twiddle = 16'h184D; // 0.382
                default: get_twiddle = 16'h4000;
            endcase
        end
    endfunction
    
    // Bit-reverse addressing
    function [STAGE_WIDTH-1:0] bit_reverse;
        input [STAGE_WIDTH-1:0] addr;
        integer i;
        begin
            for (i = 0; i < STAGE_WIDTH; i = i + 1) begin
                bit_reverse[i] = addr[STAGE_WIDTH-1-i];
            end
        end
    endfunction
    
    // Main state machine
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= IDLE;
            write_addr <= 0;
            read_addr <= 0;
            stage_counter <= 0;
            butterfly_counter <= 0;
            real_out <= 0;
            imag_out <= 0;
            data_valid_out <= 0;
            bin_index <= 0;
            fft_busy <= 0;
            fft_done <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (start_fft && enable) begin
                        state <= INPUT;
                        write_addr <= 0;
                        fft_busy <= 1;
                        fft_done <= 0;
                    end
                end
                
                INPUT: begin
                    if (data_valid_in) begin
                        real_buffer[write_addr] <= data_in;
                        imag_buffer[write_addr] <= 0; // Real input only
                        write_addr <= write_addr + 1;
                        
                        if (write_addr >= fft_size_config - 1) begin
                            state <= PROCESS;
                            stage_counter <= 0;
                            butterfly_counter <= 0;
                        end
                    end
                end
                
                PROCESS: begin
                    if (stage_counter < STAGE_WIDTH) begin
                        state <= BUTTERFLY;
                    end else begin
                        state <= OUTPUT;
                        read_addr <= 0;
                    end
                end
                
                BUTTERFLY: begin
                    // Simplified butterfly operation
                    // In real implementation, this would perform actual FFT butterflies
                    reg signed [DATA_WIDTH-1:0] temp_real, temp_imag;
                    reg signed [TWIDDLE_WIDTH-1:0] twiddle;
                    
                    twiddle = get_twiddle(stage_counter, butterfly_counter);
                    
                    // Butterfly computation (simplified)
                    temp_real = real_buffer[butterfly_counter] + real_buffer[butterfly_counter + (1 << stage_counter)];
                    temp_imag = imag_buffer[butterfly_counter] + imag_buffer[butterfly_counter + (1 << stage_counter)];
                    
                    real_buffer[butterfly_counter] <= temp_real;
                    imag_buffer[butterfly_counter] <= temp_imag;
                    
                    butterfly_counter <= butterfly_counter + 1;
                    
                    if (butterfly_counter >= fft_size_config - 1) begin
                        butterfly_counter <= 0;
                        stage_counter <= stage_counter + 1;
                        state <= PROCESS;
                    end
                end
                
                OUTPUT: begin
                    real_out <= real_buffer[bit_reverse(read_addr)];
                    imag_out <= imag_buffer[bit_reverse(read_addr)];
                    bin_index <= read_addr;
                    data_valid_out <= 1;
                    read_addr <= read_addr + 1;
                    
                    if (read_addr >= fft_size_config - 1) begin
                        state <= DONE;
                        data_valid_out <= 0;
                    end
                end
                
                DONE: begin
                    fft_busy <= 0;
                    fft_done <= 1;
                    state <= IDLE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule

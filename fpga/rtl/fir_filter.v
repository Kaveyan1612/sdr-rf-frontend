// FIR Filter Module
// Configurable finite impulse response filter
// Supports symmetric and asymmetric coefficients

module fir_filter #(
    parameter DATA_WIDTH = 14,
    parameter COEFF_WIDTH = 16,
    parameter TAPS = 16,
    parameter OUTPUT_WIDTH = 24
)(
    input wire clk,
    input wire reset_n,
    input wire signed [DATA_WIDTH-1:0] data_in,
    input wire data_valid_in,
    
    // Coefficient interface
    input wire [COEFF_WIDTH-1:0] coefficients [0:TAPS-1],
    input wire coeff_load,
    
    // Control
    input wire enable,
    
    // Output
    output reg signed [OUTPUT_WIDTH-1:0] data_out,
    output reg data_valid_out
);

    // Delay line for input samples
    reg signed [DATA_WIDTH-1:0] delay_line [0:TAPS-1];
    
    // MAC (Multiply-Accumulate) pipeline
    reg signed [DATA_WIDTH+COEFF_WIDTH-1:0] products [0:TAPS-1];
    reg signed [OUTPUT_WIDTH-1:0] accumulator;
    
    // Pipeline registers
    reg [3:0] pipeline_stage;
    
    integer i;
    
    // Shift register for delay line
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            for (i = 0; i < TAPS; i = i + 1) begin
                delay_line[i] <= 0;
            end
        end else if (enable && data_valid_in) begin
            delay_line[0] <= data_in;
            for (i = 1; i < TAPS; i = i + 1) begin
                delay_line[i] <= delay_line[i-1];
            end
        end
    end
    
    // Parallel multiplication
    always @(posedge clk) begin
        if (enable) begin
            for (i = 0; i < TAPS; i = i + 1) begin
                products[i] <= delay_line[i] * $signed(coefficients[i]);
            end
        end
    end
    
    // Accumulation
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            accumulator <= 0;
            pipeline_stage <= 0;
        end else if (enable) begin
            case (pipeline_stage)
                0: begin
                    accumulator <= products[0][OUTPUT_WIDTH-1:0];
                    pipeline_stage <= 1;
                end
                1: begin
                    accumulator <= accumulator + products[1][OUTPUT_WIDTH-1:0];
                    pipeline_stage <= 2;
                end
                2: begin
                    accumulator <= accumulator + products[2][OUTPUT_WIDTH-1:0];
                    pipeline_stage <= 3;
                end
                3: begin
                    accumulator <= accumulator + products[3][OUTPUT_WIDTH-1:0];
                    pipeline_stage <= 4;
                end
                4: begin
                    accumulator <= accumulator + products[4][OUTPUT_WIDTH-1:0];
                    pipeline_stage <= 5;
                end
                5: begin
                    accumulator <= accumulator + products[5][OUTPUT_WIDTH-1:0];
                    pipeline_stage <= 6;
                end
                6: begin
                    accumulator <= accumulator + products[6][OUTPUT_WIDTH-1:0];
                    pipeline_stage <= 7;
                end
                7: begin
                    accumulator <= accumulator + products[7][OUTPUT_WIDTH-1:0];
                    pipeline_stage <= 8;
                end
                8: begin
                    accumulator <= accumulator + products[8][OUTPUT_WIDTH-1:0];
                    pipeline_stage <= 9;
                end
                9: begin
                    accumulator <= accumulator + products[9][OUTPUT_WIDTH-1:0];
                    pipeline_stage <= 10;
                end
                10: begin
                    accumulator <= accumulator + products[10][OUTPUT_WIDTH-1:0];
                    pipeline_stage <= 11;
                end
                11: begin
                    accumulator <= accumulator + products[11][OUTPUT_WIDTH-1:0];
                    pipeline_stage <= 12;
                end
                12: begin
                    accumulator <= accumulator + products[12][OUTPUT_WIDTH-1:0];
                    pipeline_stage <= 13;
                end
                13: begin
                    accumulator <= accumulator + products[13][OUTPUT_WIDTH-1:0];
                    pipeline_stage <= 14;
                end
                14: begin
                    accumulator <= accumulator + products[14][OUTPUT_WIDTH-1:0];
                    pipeline_stage <= 15;
                end
                15: begin
                    accumulator <= accumulator + products[15][OUTPUT_WIDTH-1:0];
                    pipeline_stage <= 0;
                end
            endcase
        end
    end
    
    // Output assignment
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            data_out <= 0;
            data_valid_out <= 0;
        end else if (enable && (pipeline_stage == 0)) begin
            data_out <= accumulator;
            data_valid_out <= 1;
        end else begin
            data_valid_out <= 0;
        end
    end

endmodule

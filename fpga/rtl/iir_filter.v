// IIR Filter Module
// Infinite Impulse Response filter implementation
// Supports biquad structure for efficient implementation

module iir_filter #(
    parameter DATA_WIDTH = 16,
    parameter COEFF_WIDTH = 16,
    parameter ACCUM_WIDTH = 32,
    parameter SECTIONS = 4
)(
    input wire clk,
    input wire reset_n,
    
    // Input interface
    input wire signed [DATA_WIDTH-1:0] data_in,
    input wire data_valid_in,
    
    // Coefficient interface
    input wire signed [COEFF_WIDTH-1:0] b0 [0:SECTIONS-1],
    input wire signed [COEFF_WIDTH-1:0] b1 [0:SECTIONS-1],
    input wire signed [COEFF_WIDTH-1:0] b2 [0:SECTIONS-1],
    input wire signed [COEFF_WIDTH-1:0] a1 [0:SECTIONS-1],
    input wire signed [COEFF_WIDTH-1:0] a2 [0:SECTIONS-1],
    input wire coeff_load,
    
    // Control
    input wire enable,
    
    // Output interface
    output reg signed [DATA_WIDTH-1:0] data_out,
    output reg data_valid_out
);

    // Biquad sections (Second-order sections)
    reg signed [DATA_WIDTH-1:0] x1 [0:SECTIONS-1]; // Input delays
    reg signed [DATA_WIDTH-1:0] x2 [0:SECTIONS-1]; // Input delays
    reg signed [DATA_WIDTH-1:0] y1 [0:SECTIONS-1]; // Output delays
    reg signed [DATA_WIDTH-1:0] y2 [0:SECTIONS-1]; // Output delays
    
    // Intermediate values
    reg signed [ACCUM_WIDTH-1:0] accum [0:SECTIONS-1];
    reg signed [DATA_WIDTH-1:0] section_out [0:SECTIONS-1];
    
    // Pipeline stage
    reg [2:0] pipeline_stage;
    integer i;
    
    // Biquad filter computation for each section
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            for (i = 0; i < SECTIONS; i = i + 1) begin
                x1[i] <= 0;
                x2[i] <= 0;
                y1[i] <= 0;
                y2[i] <= 0;
                accum[i] <= 0;
                section_out[i] <= 0;
            end
            pipeline_stage <= 0;
            data_out <= 0;
            data_valid_out <= 0;
        end else if (enable && data_valid_in) begin
            case (pipeline_stage)
                0: begin
                    // First biquad section
                    accum[0] <= ($signed(data_in) * $signed(b0[0])) + 
                              ($signed(x1[0]) * $signed(b1[0])) + 
                              ($signed(x2[0]) * $signed(b2[0])) -
                              ($signed(y1[0]) * $signed(a1[0])) - 
                              ($signed(y2[0]) * $signed(a2[0]));
                    pipeline_stage <= 1;
                end
                
                1: begin
                    section_out[0] <= accum[0][ACCUM_WIDTH-1:ACCUM_WIDTH-DATA_WIDTH];
                    x2[0] <= x1[0];
                    x1[0] <= data_in;
                    y2[0] <= y1[0];
                    y1[0] <= section_out[0];
                    
                    // Second biquad section
                    if (SECTIONS > 1) begin
                        accum[1] <= ($signed(section_out[0]) * $signed(b0[1])) + 
                                  ($signed(x1[1]) * $signed(b1[1])) + 
                                  ($signed(x2[1]) * $signed(b2[1])) -
                                  ($signed(y1[1]) * $signed(a1[1])) - 
                                  ($signed(y2[1]) * $signed(a2[1]));
                    end
                    pipeline_stage <= 2;
                end
                
                2: begin
                    if (SECTIONS > 1) begin
                        section_out[1] <= accum[1][ACCUM_WIDTH-1:ACCUM_WIDTH-DATA_WIDTH];
                        x2[1] <= x1[1];
                        x1[1] <= section_out[0];
                        y2[1] <= y1[1];
                        y1[1] <= section_out[1];
                        
                        // Third biquad section
                        if (SECTIONS > 2) begin
                            accum[2] <= ($signed(section_out[1]) * $signed(b0[2])) + 
                                      ($signed(x1[2]) * $signed(b1[2])) + 
                                      ($signed(x2[2]) * $signed(b2[2])) -
                                      ($signed(y1[2]) * $signed(a1[2])) - 
                                      ($signed(y2[2]) * $signed(a2[2]));
                        end
                    end
                    pipeline_stage <= 3;
                end
                
                3: begin
                    if (SECTIONS > 2) begin
                        section_out[2] <= accum[2][ACCUM_WIDTH-1:ACCUM_WIDTH-DATA_WIDTH];
                        x2[2] <= x1[2];
                        x1[2] <= section_out[1];
                        y2[2] <= y1[2];
                        y1[2] <= section_out[2];
                        
                        // Fourth biquad section
                        if (SECTIONS > 3) begin
                            accum[3] <= ($signed(section_out[2]) * $signed(b0[3])) + 
                                      ($signed(x1[3]) * $signed(b1[3])) + 
                                      ($signed(x2[3]) * $signed(b2[3])) -
                                      ($signed(y1[3]) * $signed(a1[3])) - 
                                      ($signed(y2[3]) * $signed(a2[3]));
                        end
                    end
                    pipeline_stage <= 4;
                end
                
                4: begin
                    if (SECTIONS > 3) begin
                        section_out[3] <= accum[3][ACCUM_WIDTH-1:ACCUM_WIDTH-DATA_WIDTH];
                        x2[3] <= x1[3];
                        x1[3] <= section_out[2];
                        y2[3] <= y1[3];
                        y1[3] <= section_out[3];
                    end
                    
                    // Output final result
                    if (SECTIONS == 1) begin
                        data_out <= section_out[0];
                    end else if (SECTIONS == 2) begin
                        data_out <= section_out[1];
                    end else if (SECTIONS == 3) begin
                        data_out <= section_out[2];
                    end else begin
                        data_out <= section_out[3];
                    end
                    
                    data_valid_out <= 1;
                    pipeline_stage <= 0;
                end
                
                default: pipeline_stage <= 0;
            endcase
        end else begin
            data_valid_out <= 0;
        end
    end

endmodule

// Digital Down Converter (DDC)
// Performs mixing, filtering, and decimation
// Implements NCO (Numerically Controlled Oscillator) + CIC Filter

module ddc #(
    parameter DATA_WIDTH = 14,
    parameter MIXER_WIDTH = 16,
    parameter CIC_STAGES = 4,
    parameter DECIMATION = 16,
    parameter PHASE_WIDTH = 32
)(
    input wire clk,
    input wire reset_n,
    input wire [DATA_WIDTH-1:0] data_in,
    input wire data_valid_in,
    
    // Control interface
    input wire [31:0] frequency_word, // NCO frequency control
    input wire enable,
    
    // Output interface
    output reg signed [DATA_WIDTH-1:0] i_out,
    output reg signed [DATA_WIDTH-1:0] q_out,
    output reg data_valid_out,
    
    // Status
    output wire [31:0] phase_accumulator
);

    // NCO (Numerically Controlled Oscillator)
    reg [PHASE_WIDTH-1:0] phase_acc;
    reg signed [MIXER_WIDTH-1:0] sine_lut;
    reg signed [MIXER_WIDTH-1:0] cosine_lut;
    
    // Mixer outputs
    wire signed [MIXER_WIDTH+DATA_WIDTH-1:0] i_mixed;
    wire signed [MIXER_WIDTH+DATA_WIDTH-1:0] q_mixed;
    
    // CIC Filter stages
    reg signed [DATA_WIDTH+11:0] cic_integrator [0:CIC_STAGES-1];
    reg signed [DATA_WIDTH+11:0] cic_comb [0:CIC_STAGES-1];
    reg signed [DATA_WIDTH+11:0] cic_delay [0:CIC_STAGES-1];
    
    // Decimation counter
    reg [31:0] decim_counter;
    
    // Phase accumulator for NCO
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            phase_acc <= 0;
        end else if (enable && data_valid_in) begin
            phase_acc <= phase_acc + frequency_word;
        end
    end
    
    assign phase_accumulator = phase_acc;
    
    // Simple sine/cosine LUT (can be expanded with ROM)
    // For demonstration, using simple approximation
    always @(posedge clk) begin
        if (enable) begin
            // Quadrature outputs based on phase
            cosine_lut <= $signed(phase_acc[PHASE_WIDTH-1:PHASE_WIDTH-16]);
            sine_lut <= $signed({phase_acc[PHASE_WIDTH-3:PHASE_WIDTH-16], 2'b00});
        end
    end
    
    // Mixers (I = data*cos, Q = data*sin)
    assign i_mixed = $signed(data_in) * cosine_lut;
    assign q_mixed = $signed(data_in) * sine_lut;
    
    // CIC Integrator stages
    integer i;
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            for (i = 0; i < CIC_STAGES; i = i + 1) begin
                cic_integrator[i] <= 0;
            end
        end else if (enable && data_valid_in) begin
            cic_integrator[0] <= cic_integrator[0] + i_mixed[MIXER_WIDTH+DATA_WIDTH-1:DATA_WIDTH];
            for (i = 1; i < CIC_STAGES; i = i + 1) begin
                cic_integrator[i] <= cic_integrator[i] + cic_integrator[i-1];
            end
        end
    end
    
    // Decimation logic
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            decim_counter <= 0;
        end else if (enable) begin
            if (decim_counter >= DECIMATION - 1) begin
                decim_counter <= 0;
            end else begin
                decim_counter <= decim_counter + 1;
            end
        end
    end
    
    // CIC Comb stages (decimated)
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            for (i = 0; i < CIC_STAGES; i = i + 1) begin
                cic_comb[i] <= 0;
                cic_delay[i] <= 0;
            end
        end else if (enable && (decim_counter == DECIMATION - 1)) begin
            cic_delay[0] <= cic_integrator[CIC_STAGES-1];
            cic_comb[0] <= cic_integrator[CIC_STAGES-1] - cic_delay[0];
            
            for (i = 1; i < CIC_STAGES; i = i + 1) begin
                cic_delay[i] <= cic_comb[i-1];
                cic_comb[i] <= cic_comb[i-1] - cic_delay[i];
            end
        end
    end
    
    // Output assignment with scaling
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            i_out <= 0;
            q_out <= 0;
            data_valid_out <= 0;
        end else if (enable && (decim_counter == DECIMATION - 1)) begin
            // Scale and truncate output
            i_out <= cic_comb[CIC_STAGES-1][DATA_WIDTH+11:DATA_WIDTH-1];
            q_out <= cic_comb[CIC_STAGES-1][DATA_WIDTH+11:DATA_WIDTH-1];
            data_valid_out <= 1;
        end else begin
            data_valid_out <= 0;
        end
    end

endmodule

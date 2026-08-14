// I2C Interface Module
// Handles I2C communication for sensors and control ICs
// Supports standard and fast mode

module i2c_interface #(
    parameter CLK_FREQ = 50_000_000,
    parameter I2C_FREQ = 100_000, // 100 kHz standard mode
    parameter DATA_WIDTH = 8
)(
    input wire clk,
    input wire reset_n,
    
    // I2C signals
    inout wire i2c_sda,
    inout wire i2c_scl,
    
    // Control interface
    input wire start,
    input wire stop,
    input wire read_write, // 0 = write, 1 = read
    input wire [DATA_WIDTH-1:0] data_in,
    input wire data_valid,
    
    // Output interface
    output reg [DATA_WIDTH-1:0] data_out,
    output reg data_valid_out,
    output reg ack_error,
    output reg busy
);

    // Clock divider for I2C
    localparam CLK_DIV = CLK_FREQ / (I2C_FREQ * 4);
    reg [31:0] clk_div_counter;
    reg [1:0] clk_phase;
    wire sclk_en = (clk_div_counter == 0);
    
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            clk_div_counter <= 0;
            clk_phase <= 0;
        end else begin
            if (clk_div_counter >= CLK_DIV - 1) begin
                clk_div_counter <= 0;
                clk_phase <= clk_phase + 1;
            end else begin
                clk_div_counter <= clk_div_counter + 1;
            end
        end
    end
    
    // I2C state machine
    reg [3:0] state;
    reg [DATA_WIDTH-1:0] shift_reg;
    reg [3:0] bit_count;
    reg sda_out, scl_out;
    reg sda_oe; // Output enable for SDA
    
    localparam IDLE = 0;
    localparam START = 1;
    localparam ADDR = 2;
    localparam DATA = 3;
    localparam ACK = 4;
    localparam STOP = 5;
    
    // I2C signal generation
    assign i2c_sda = sda_oe ? sda_out : 1'bz;
    assign i2c_scl = (state == IDLE) ? 1'bz : scl_out;
    
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= IDLE;
            shift_reg <= 0;
            bit_count <= 0;
            sda_out <= 1;
            scl_out <= 1;
            sda_oe <= 0;
            data_out <= 0;
            data_valid_out <= 0;
            ack_error <= 0;
            busy <= 0;
        end else if (sclk_en) begin
            case (state)
                IDLE: begin
                    sda_oe <= 0;
                    scl_out <= 1;
                    data_valid_out <= 0;
                    ack_error <= 0;
                    
                    if (start) begin
                        state <= START;
                        busy <= 1;
                        sda_oe <= 1;
                        sda_out <= 0; // Start condition
                    end
                end
                
                START: begin
                    case (clk_phase)
                        0: begin
                            scl_out <= 0; // Clock low
                        end
                        1: begin
                            // Setup first bit
                            shift_reg <= {read_write, 7'hA0}; // Default address
                            bit_count <= 7;
                            state <= ADDR;
                        end
                    endcase
                end
                
                ADDR: begin
                    case (clk_phase)
                        0: begin
                            sda_out <= shift_reg[bit_count];
                        end
                        1: begin
                            scl_out <= 1; // Clock high
                        end
                        2: begin
                            scl_out <= 0; // Clock low
                        end
                        3: begin
                            if (bit_count == 0) begin
                                state <= ACK;
                            end else begin
                                bit_count <= bit_count - 1;
                            end
                        end
                    endcase
                end
                
                DATA: begin
                    if (data_valid) begin
                        shift_reg <= data_in;
                        bit_count <= 7;
                    end
                    
                    case (clk_phase)
                        0: begin
                            if (read_write) begin
                                sda_oe <= 0; // Release SDA for read
                            end else begin
                                sda_out <= shift_reg[bit_count];
                                sda_oe <= 1;
                            end
                        end
                        1: begin
                            scl_out <= 1; // Clock high
                            if (read_write) begin
                                shift_reg[bit_count] <= i2c_sda; // Sample data
                            end
                        end
                        2: begin
                            scl_out <= 0; // Clock low
                        end
                        3: begin
                            if (bit_count == 0) begin
                                state <= ACK;
                            end else begin
                                bit_count <= bit_count - 1;
                            end
                        end
                    endcase
                end
                
                ACK: begin
                    case (clk_phase)
                        0: begin
                            sda_oe <= 0; // Release SDA for ACK
                        end
                        1: begin
                            scl_out <= 1; // Clock high
                        end
                        2: begin
                            if (i2c_sda) begin
                                ack_error <= 1; // NACK received
                            end
                            scl_out <= 0; // Clock low
                        end
                        3: begin
                            if (stop) begin
                                state <= STOP;
                            end else if (data_valid) begin
                                state <= DATA;
                            end else begin
                                state <= IDLE;
                                busy <= 0;
                                data_out <= shift_reg;
                                data_valid_out <= 1;
                            end
                        end
                    endcase
                end
                
                STOP: begin
                    case (clk_phase)
                        0: begin
                            sda_oe <= 1;
                            sda_out <= 0;
                        end
                        1: begin
                            scl_out <= 1;
                        end
                        2: begin
                            sda_out <= 1; // Stop condition
                        end
                        3: begin
                            state <= IDLE;
                            busy <= 0;
                            sda_oe <= 0;
                        end
                    endcase
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule

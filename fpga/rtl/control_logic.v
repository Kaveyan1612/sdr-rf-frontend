// Control Logic Module
// Provides register map and configuration interface
// Handles SPI/I2C communication with embedded controller

module control_logic #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32
)(
    input wire clk,
    input wire reset_n,
    
    // SPI interface
    input wire spi_clk,
    input wire spi_mosi,
    output wire spi_miso,
    input wire spi_cs_n,
    
    // Register outputs
    output reg [DATA_WIDTH-1:0] frequency_word,
    output reg [DATA_WIDTH-1:0] sample_count,
    output reg enable_adc,
    output reg enable_dac,
    output reg enable_ddc,
    output reg enable_filter,
    output reg [31:0] decimation_factor,
    output reg [31:0] filter_taps,
    
    // Status inputs
    input wire [31:0] adc_sample_count,
    input wire [31:0] dac_sample_count,
    input wire adc_overflow,
    input wire dac_underflow,
    input wire [31:0] phase_acc,
    
    // Status outputs (readable via SPI)
    output reg [DATA_WIDTH-1:0] status_reg,
    output reg [DATA_WIDTH-1:0] error_reg
);

    // Register addresses
    localparam REG_FREQ_WORD = 8'h00;
    localparam REG_SAMPLE_COUNT = 8'h04;
    localparam REG_ENABLE = 8'h08;
    localparam REG_DECIMATION = 8'h0C;
    localparam REG_FILTER_TAPS = 8'h10;
    localparam REG_STATUS = 8'h14;
    localparam REG_ERROR = 8'h18;
    localparam REG_PHASE_ACC = 8'h1C;
    
    // Internal registers
    reg [ADDR_WIDTH-1:0] reg_addr;
    reg [DATA_WIDTH-1:0] reg_data_in;
    reg [DATA_WIDTH-1:0] reg_data_out;
    reg reg_write;
    reg reg_read;
    
    // SPI state machine
    reg [3:0] spi_state;
    reg [7:0] spi_bit_count;
    reg [DATA_WIDTH-1:0] spi_shift_reg;
    reg [ADDR_WIDTH-1:0] addr_shift_reg;
    
    localparam SPI_IDLE = 0;
    localparam SPI_ADDR = 1;
    localparam SPI_DATA = 2;
    localparam SPI_WAIT = 3;
    
    // SPI interface logic
    always @(posedge spi_clk or negedge reset_n) begin
        if (!reset_n) begin
            spi_state <= SPI_IDLE;
            spi_bit_count <= 0;
            spi_shift_reg <= 0;
            addr_shift_reg <= 0;
            reg_write <= 0;
            reg_read <= 0;
        end else begin
            case (spi_state)
                SPI_IDLE: begin
                    if (spi_cs_n == 0) begin
                        spi_state <= SPI_ADDR;
                        spi_bit_count <= 0;
                        addr_shift_reg <= 0;
                    end
                end
                
                SPI_ADDR: begin
                    addr_shift_reg <= {addr_shift_reg[6:0], spi_mosi};
                    spi_bit_count <= spi_bit_count + 1;
                    if (spi_bit_count == 7) begin
                        reg_addr <= {addr_shift_reg[6:0], spi_mosi};
                        spi_bit_count <= 0;
                        spi_shift_reg <= 0;
                        spi_state <= SPI_DATA;
                    end
                end
                
                SPI_DATA: begin
                    spi_shift_reg <= {spi_shift_reg[30:0], spi_mosi};
                    spi_bit_count <= spi_bit_count + 1;
                    if (spi_bit_count == 31) begin
                        reg_data_in <= {spi_shift_reg[30:0], spi_mosi};
                        reg_write <= 1;
                        spi_state <= SPI_WAIT;
                    end
                end
                
                SPI_WAIT: begin
                    reg_write <= 0;
                    if (spi_cs_n == 1) begin
                        spi_state <= SPI_IDLE;
                    end
                end
                
                default: spi_state <= SPI_IDLE;
            endcase
        end
    end
    
    // Register read/write logic
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            frequency_word <= 32'h10000000; // Default frequency
            sample_count <= 32'd1024;
            enable_adc <= 0;
            enable_dac <= 0;
            enable_ddc <= 0;
            enable_filter <= 0;
            decimation_factor <= 32'd16;
            filter_taps <= 32'd16;
            status_reg <= 0;
            error_reg <= 0;
        end else begin
            // Update status register
            status_reg <= {adc_sample_count, dac_sample_count[15:0]};
            
            // Update error register
            error_reg <= {28'h0, dac_underflow, adc_overflow, 2'b00};
            
            // Handle register writes
            if (reg_write) begin
                case (reg_addr)
                    REG_FREQ_WORD: frequency_word <= reg_data_in;
                    REG_SAMPLE_COUNT: sample_count <= reg_data_in;
                    REG_ENABLE: begin
                        enable_adc <= reg_data_in[0];
                        enable_dac <= reg_data_in[1];
                        enable_ddc <= reg_data_in[2];
                        enable_filter <= reg_data_in[3];
                    end
                    REG_DECIMATION: decimation_factor <= reg_data_in;
                    REG_FILTER_TAPS: filter_taps <= reg_data_in;
                endcase
            end
            
            // Handle register reads
            case (reg_addr)
                REG_FREQ_WORD: reg_data_out <= frequency_word;
                REG_SAMPLE_COUNT: reg_data_out <= sample_count;
                REG_ENABLE: reg_data_out <= {28'h0, enable_filter, enable_ddc, enable_dac, enable_adc};
                REG_DECIMATION: reg_data_out <= decimation_factor;
                REG_FILTER_TAPS: reg_data_out <= filter_taps;
                REG_STATUS: reg_data_out <= status_reg;
                REG_ERROR: reg_data_out <= error_reg;
                REG_PHASE_ACC: reg_data_out <= phase_acc;
                default: reg_data_out <= 32'h0;
            endcase
        end
    end
    
    // SPI MISO output
    assign spi_miso = (spi_state == SPI_DATA) ? spi_shift_reg[31] : 1'bz;
    
    // Update shift register for read operations
    always @(posedge spi_clk) begin
        if (spi_state == SPI_DATA) begin
            spi_shift_reg <= {spi_shift_reg[30:0], spi_miso};
        end
    end

endmodule

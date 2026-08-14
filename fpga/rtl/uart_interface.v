// UART Interface Module
// Handles UART communication for configuration and data transfer
// Configurable baud rate and data format

module uart_interface #(
    parameter DATA_WIDTH = 8,
    parameter BAUD_RATE = 115200,
    parameter CLK_FREQ = 50_000_000
)(
    input wire clk,
    input wire reset_n,
    
    // UART signals
    input wire uart_rx,
    output reg uart_tx,
    
    // Transmit interface
    input wire [DATA_WIDTH-1:0] tx_data,
    input wire tx_start,
    output reg tx_busy,
    output reg tx_done,
    
    // Receive interface
    output reg [DATA_WIDTH-1:0] rx_data,
    output reg rx_valid,
    output reg rx_error,
    
    // Status
    output wire [31:0] tx_count,
    output wire [31:0] rx_count
);

    // Baud rate generator
    localparam BAUD_DIV = CLK_FREQ / BAUD_RATE;
    reg [31:0] baud_counter;
    reg baud_tick;
    
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            baud_counter <= 0;
            baud_tick <= 0;
        end else begin
            if (baud_counter >= BAUD_DIV - 1) begin
                baud_counter <= 0;
                baud_tick <= 1;
            end else begin
                baud_counter <= baud_counter + 1;
                baud_tick <= 0;
            end
        end
    end
    
    // UART transmitter
    reg [3:0] tx_state;
    reg [DATA_WIDTH-1:0] tx_shift_reg;
    reg [3:0] tx_bit_count;
    
    localparam TX_IDLE = 0;
    localparam TX_START = 1;
    localparam TX_DATA = 2;
    localparam TX_STOP = 3;
    
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            tx_state <= TX_IDLE;
            tx_shift_reg <= 0;
            tx_bit_count <= 0;
            uart_tx <= 1;
            tx_busy <= 0;
            tx_done <= 0;
        end else begin
            case (tx_state)
                TX_IDLE: begin
                    uart_tx <= 1;
                    tx_done <= 0;
                    if (tx_start) begin
                        tx_shift_reg <= tx_data;
                        tx_bit_count <= 0;
                        tx_state <= TX_START;
                        tx_busy <= 1;
                    end
                end
                
                TX_START: begin
                    if (baud_tick) begin
                        uart_tx <= 0; // Start bit
                        tx_state <= TX_DATA;
                    end
                end
                
                TX_DATA: begin
                    if (baud_tick) begin
                        uart_tx <= tx_shift_reg[0];
                        tx_shift_reg <= {1'b0, tx_shift_reg[DATA_WIDTH-1:1]};
                        tx_bit_count <= tx_bit_count + 1;
                        
                        if (tx_bit_count >= DATA_WIDTH - 1) begin
                            tx_state <= TX_STOP;
                        end
                    end
                end
                
                TX_STOP: begin
                    if (baud_tick) begin
                        uart_tx <= 1; // Stop bit
                        tx_state <= TX_IDLE;
                        tx_busy <= 0;
                        tx_done <= 1;
                    end
                end
                
                default: tx_state <= TX_IDLE;
            endcase
        end
    end
    
    // UART receiver
    reg [3:0] rx_state;
    reg [DATA_WIDTH-1:0] rx_shift_reg;
    reg [3:0] rx_bit_count;
    reg uart_rx_sync1, uart_rx_sync2;
    
    localparam RX_IDLE = 0;
    localparam RX_START = 1;
    localparam RX_DATA = 2;
    localparam RX_STOP = 3;
    
    // Synchronize UART RX
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            uart_rx_sync1 <= 1;
            uart_rx_sync2 <= 1;
        end else begin
            uart_rx_sync1 <= uart_rx;
            uart_rx_sync2 <= uart_rx_sync1;
        end
    end
    
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            rx_state <= RX_IDLE;
            rx_shift_reg <= 0;
            rx_bit_count <= 0;
            rx_data <= 0;
            rx_valid <= 0;
            rx_error <= 0;
        end else begin
            rx_valid <= 0;
            rx_error <= 0;
            
            case (rx_state)
                RX_IDLE: begin
                    if (!uart_rx_sync2) begin // Start bit detected
                        rx_state <= RX_START;
                        rx_bit_count <= 0;
                    end
                end
                
                RX_START: begin
                    if (baud_tick) begin
                        rx_state <= RX_DATA;
                    end
                end
                
                RX_DATA: begin
                    if (baud_tick) begin
                        rx_shift_reg <= {uart_rx_sync2, rx_shift_reg[DATA_WIDTH-1:1]};
                        rx_bit_count <= rx_bit_count + 1;
                        
                        if (rx_bit_count >= DATA_WIDTH - 1) begin
                            rx_state <= RX_STOP;
                        end
                    end
                end
                
                RX_STOP: begin
                    if (baud_tick) begin
                        if (uart_rx_sync2) begin // Valid stop bit
                            rx_data <= rx_shift_reg;
                            rx_valid <= 1;
                        end else begin
                            rx_error <= 1; // Framing error
                        end
                        rx_state <= RX_IDLE;
                    end
                end
                
                default: rx_state <= RX_IDLE;
            endcase
        end
    end
    
    // Counters
    reg [31:0] tx_counter;
    reg [31:0] rx_counter;
    
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            tx_counter <= 0;
            rx_counter <= 0;
        end else begin
            if (tx_done) begin
                tx_counter <= tx_counter + 1;
            end
            if (rx_valid) begin
                rx_counter <= rx_counter + 1;
            end
        end
    end
    
    assign tx_count = tx_counter;
    assign rx_count = rx_counter;

endmodule

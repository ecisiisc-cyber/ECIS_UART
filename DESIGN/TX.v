`timescale 1ns / 1ps

module uart_tx (
    input wire clk,
    input wire rst,
    input wire tick_16x,
    input wire [7:0] tx_data,
    input wire tx_start,      // "FIFO is not empty" signal
    input wire i_cts_n,       // Active Low Clear-To-Send from FTDI
    output reg tx_out,        // Serial Output
    output reg tx_busy,       // "I am busy sending"
    output reg tx_done_tick   // "I finished one byte, read next"
);

    localparam IDLE=0, START=1, DATA=2, STOP=3;
    reg [1:0] state;
    reg [3:0] tick_count;
    reg [2:0] bit_index;
    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            tx_out <= 1'b1; // UART Idle is High
            tx_busy <= 0;
            tx_done_tick <= 0;
        end else begin
            tx_done_tick <= 0; // Default low
            
            if (tick_16x) begin
                case (state)
                    IDLE: begin
                        // Only start if: 1. We have data, 2. CTS is LOW (Go)
                        if (tx_start && (i_cts_n == 0)) begin
                            state <= START;
                            data_reg <= tx_data;
                            tx_busy <= 1;
                            tick_count <= 0;
                        end else begin
                             tx_busy <= 0; // Not busy
                        end
                    end

                    START: begin
                        tx_out <= 1'b0; // Start bit
                        if (tick_count == 15) begin
                            state <= DATA;
                            tick_count <= 0;
                            bit_index <= 0;
                        end else tick_count <= tick_count + 1;
                    end

                    DATA: begin
                        tx_out <= data_reg[bit_index]; // LSB First
                        if (tick_count == 15) begin
                            tick_count <= 0;
                            if (bit_index == 7) state <= STOP;
                            else bit_index <= bit_index + 1;
                        end else tick_count <= tick_count + 1;
                    end

                    STOP: begin
                        tx_out <= 1'b1; // Stop bit
                        if (tick_count == 15) begin
                            state <= IDLE;
                            tx_done_tick <= 1; // Signal to pop FIFO
                            tx_busy <= 0;
                        end else tick_count <= tick_count + 1;
                    end
                endcase
            end
        end
    end
endmodule
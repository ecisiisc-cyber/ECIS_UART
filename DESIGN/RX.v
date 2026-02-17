`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/17/2026 12:44:29 PM
// Design Name: 
// Module Name: RX
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module uart_rx (
    input wire clk,
    input wire rst,
    input wire rx_in,         // Serial Input (Physically connected to FTDI TX)
    input wire tick_16x,      // 16x Oversampling pulse
    output reg [7:0] rx_data, // Byte received
    output reg rx_done        // Pulse when byte is ready
);

    localparam IDLE=0, START=1, DATA=2, STOP=3;
    reg [1:0] state;
    
    reg [3:0] tick_count; // Counts 0 to 15
    reg [2:0] bit_index;  // 0 to 7
    reg [7:0] shift_reg;

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            rx_done <= 0;
            tick_count <= 0;
            bit_index <= 0;
            rx_data <= 0;
        end else if (tick_16x) begin
            case (state)
                IDLE: begin
                    rx_done <= 0;
                    if (rx_in == 0) begin // Start bit detected
                        state <= START;
                        tick_count <= 0;
                    end
                end
                
                START: begin
                    // Wait for middle of start bit (Tick 7)
                    if (tick_count == 7) begin
                        state <= DATA;
                        tick_count <= 0;
                        bit_index <= 0;
                    end else begin
                        tick_count <= tick_count + 1;
                    end
                end
                
                DATA: begin
                    // Sample at middle (Tick 7)
                    if (tick_count == 7) begin
                        shift_reg[bit_index] <= rx_in; // LSB First
                        tick_count <= tick_count + 1;
                    end else if (tick_count == 15) begin
                        tick_count <= 0;
                        if (bit_index == 7)
                            state <= STOP;
                        else
                            bit_index <= bit_index + 1;
                    end else begin
                        tick_count <= tick_count + 1;
                    end
                end
                
                STOP: begin
                    // Wait for middle of stop bit
                    if (tick_count == 7) begin
                        state <= IDLE;
                        rx_data <= shift_reg;
                        rx_done <= 1; // Valid Pulse
                    end else begin
                        tick_count <= tick_count + 1;
                    end
                end
            endcase
        end else begin
             rx_done <= 0; // Clear pulse if not tick
        end
    end
endmodule
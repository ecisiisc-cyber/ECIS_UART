`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/17/2026 12:46:32 PM
// Design Name: 
// Module Name: Baudrate_gen
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

module baud_gen #(
    parameter CLK_FREQ = 100000000,
    parameter BAUD_RATE = 921600,
    parameter OVERSAMPLE = 16
)(
    input wire clk,
    input wire rst,
    output reg tick_16x
);
    // Calculate divider: 100MHz / (921600 * 16) = ~7 clocks
    localparam MAX_COUNT = CLK_FREQ / (BAUD_RATE * OVERSAMPLE);
    
    reg [$clog2(MAX_COUNT)-1:0] count;

    always @(posedge clk) begin
        if (rst) begin
            count <= 0;
            tick_16x <= 0;
        end else begin
            if (count == MAX_COUNT - 1) begin
                count <= 0;
                tick_16x <= 1'b1;
            end else begin
                count <= count + 1;
                tick_16x <= 1'b0;
            end
        end
    end
endmodule
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/16/2026 02:33:25 PM
// Design Name: 
// Module Name: uart_rtl
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


module uart_top (
    input wire clk_100mhz,  // System Clock
    input wire sys_rst_n,   // Active Low Reset (Button)
    
    // Physical UART Pins (Neso A7)
    input  wire uart_rxd,   // Input from FTDI TX
    output wire uart_txd,   // Output to FTDI RX
    input  wire uart_cts,   // Input from FTDI RTS (Active Low)
    output wire uart_rts    // Output to FTDI CTS (Active Low)
);

    // Active High Reset
    wire rst = ~sys_rst_n;

    // Internal Signals
    wire tick_16x;
    
    // --- RX Signals ---
    wire [7:0] rx_byte_out;
    wire rx_valid_pulse;
    wire rx_fifo_full;
    wire rx_fifo_empty;
    wire [7:0] rx_fifo_dout; // Data available for User Logic to read
    wire rx_prog_full;       // Hysteresis flag for RTS
    
    // --- TX Signals ---
    wire [7:0] tx_byte_in;   // Data User Logic wants to send
    wire tx_fifo_wr_en;      // User Logic write enable
    wire tx_fifo_full;
    wire [7:0] tx_fifo_dout;
    wire tx_fifo_empty;
    wire tx_fifo_rd_en;
    wire tx_busy;
    
    // ---------------------------------------------------------
    // 1. Baud Rate Generator
    // ---------------------------------------------------------
    baud_gen #(
        .CLK_FREQ(100000000), 
        .BAUD_RATE(921600), 
        .OVERSAMPLE(16)
    ) u_baud (
        .clk(clk_100mhz), 
        .rst(rst), 
        .tick_16x(tick_16x)
    );

    // ---------------------------------------------------------
    // 2. RX Path (PC -> FPGA)
    // ---------------------------------------------------------
    uart_rx u_rx (
        .clk(clk_100mhz), .rst(rst),
        .rx_in(uart_rxd), .tick_16x(tick_16x),
        .rx_data(rx_byte_out), .rx_done(rx_valid_pulse)
    );

    // XPM FIFO for RX Buffer
    xpm_fifo_sync #(
        .FIFO_WRITE_DEPTH(2048),
        .WRITE_DATA_WIDTH(8),
        .READ_MODE("fwft"),         // First-Word-Fall-Through (Easier to read)
        .PROG_FULL_THRESH(1800)     // Assert RTS when ~88% full
    ) u_rx_fifo (
        .wr_clk(clk_100mhz),
        .rst(rst),
        .din(rx_byte_out),
        .wr_en(rx_valid_pulse),     // Write when RX module finishes a byte
        .dout(rx_fifo_dout),
        .rd_en(1'b0),               // USER LOGIC controls this to read data!
        .full(rx_fifo_full),
        .empty(rx_fifo_empty),
        .prog_full(rx_prog_full)    // Connects to RTS
    );
    
    // *** RTS FLOW CONTROL LOGIC ***
    // If FIFO is "Program full" (High), we drive RTS High (Stop)
    // If FIFO is OK, we drive RTS Low (Go)
    assign uart_rts = rx_prog_full; 

    // ---------------------------------------------------------
    // 3. TX Path (FPGA -> PC)
    // ---------------------------------------------------------
    
    // Example: Loopback (Connect RX FIFO output to TX FIFO input)
    // In real app, "tx_byte_in" comes from your logic.
    assign tx_byte_in = rx_fifo_dout;
    assign tx_fifo_wr_en = !rx_fifo_empty; // Write if RX has data
    // Note: You also need to pop the RX fifo!
    // assign rx_fifo_rd_en = !tx_fifo_full && !rx_fifo_empty; (Simple Loopback logic)
     assign rx_fifo_rd_en = !tx_fifo_full && !rx_fifo_empty;

    // XPM FIFO for TX Buffer
    xpm_fifo_sync #(
        .FIFO_WRITE_DEPTH(2048),
        .WRITE_DATA_WIDTH(8),
        .READ_MODE("fwft")
    ) u_tx_fifo (
        .wr_clk(clk_100mhz),
        .rst(rst),
        .din(tx_byte_in),
        .wr_en(tx_fifo_wr_en),
        .dout(tx_fifo_dout),
        .rd_en(tx_fifo_rd_en),
        .full(tx_fifo_full),
        .empty(tx_fifo_empty)
    );

    uart_tx u_tx (
        .clk(clk_100mhz), .rst(rst),
        .tick_16x(tick_16x),
        .tx_data(tx_fifo_dout),
        .tx_start(~tx_fifo_empty), // Start if FIFO has data
        .i_cts_n(uart_cts),        // Hardware Flow Control Input
        .tx_out(uart_txd),
        .tx_busy(tx_busy),
        .tx_done_tick(tx_fifo_rd_en) // Pop FIFO when byte is sent
    );

endmodule
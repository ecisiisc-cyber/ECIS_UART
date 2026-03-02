`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/16/2026 02:34:22 PM
// Design Name: 
// Module Name: uart_tb
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


module uart_top_tb;

    reg clk_100mhz_tb;
    reg sys_rst_n_tb;
    wire uart_rx_tb;
    reg uart_tx_tb;
    reg uart_rts_tb;
    wire uart_cts_tb;
    
    reg [7:0] data_to_send = 8'b0011_0100;
    integer i;

    // 115,200 Baud = ~8.68us per bit
    localparam BIT_PERIOD = 8680; 

    // Instantiate DUT
    uart_top dut (
        .clk_100mhz(clk_100mhz_tb),
        .sys_rst_n(sys_rst_n_tb),
        .uart_rxd(uart_tx_tb),
        .uart_txd(uart_rx_tb),
        .uart_cts(uart_rts_tb),
        .uart_rts(uart_cts_tb)
    );

    // Clock Generation
    initial clk_100mhz_tb = 0;
    always #5 clk_100mhz_tb = ~clk_100mhz_tb; // 100MHz
    
    //hr debug internals
    
    
    wire [7:0]recived_data ;
    assign recived_data=dut.rx_byte_out;
    
    wire [3:0]tickcount_rx;
    assign tickcount_rx =dut.u_rx.tick_count;
    
    wire [7:0] rx_shift_reg;
    assign rx_shift_reg=dut.u_rx.shift_reg; 
    
    wire [1:0] rx_state;
    assign rx_state=dut.u_rx.state;
    
    
    
    
    
    
    


    initial begin
        // Initialize
        sys_rst_n_tb = 0;
        uart_tx_tb = 1;
        uart_rts_tb = 1; 
        
        #100 sys_rst_n_tb  = 1;
        #200;
        uart_tx_tb = 1;
         
        #(BIT_PERIOD * 5);
        //start bit 
         uart_tx_tb=0;
        #(BIT_PERIOD)
        for(i=0;i<8;i=i+1)
        begin
        uart_tx_tb=data_to_send[i];
        #(BIT_PERIOD);
        end
        uart_tx_tb=1;
        #(BIT_PERIOD*20);
        uart_rts_tb = 0;
        #(BIT_PERIOD*20);
        $finish;
    end

endmodule
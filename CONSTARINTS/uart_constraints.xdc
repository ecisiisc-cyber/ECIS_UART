set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

## Clock signal
set_property -dict {PACKAGE_PIN F4 IOSTANDARD LVCMOS33} [get_ports clk_100mhz]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} -add [get_ports clk_100mhz]

## Reset (User Button 1 usually)
set_property -dict {PACKAGE_PIN R17 IOSTANDARD LVCMOS33} [get_ports sys_rst_n]


set_property -dict {PACKAGE_PIN B18 IOSTANDARD LVCMOS33} [get_ports uart_txd]
set_property -dict {PACKAGE_PIN A18 IOSTANDARD LVCMOS33} [get_ports uart_rxd]

# Flow Control Pins (Verify on schematic!)
set_property -dict {PACKAGE_PIN E18 IOSTANDARD LVCMOS33} [get_ports uart_rts]
set_property -dict {PACKAGE_PIN D18 IOSTANDARD LVCMOS33} [get_ports uart_cts]

## =========================================================
## EDGE Spartan-7 XC7S15FTGB196-1
## RISC-V 3-STAGE PIPELINE + 16x2 LCD
## =========================================================

## 50 MHz oscillator
set_property -dict {PACKAGE_PIN H11 IOSTANDARD LVCMOS33} [get_ports clk50]

create_clock -period 20.000 -name sys_clk [get_ports clk50]


## Center push button
## J12 = PB[4]
set_property PACKAGE_PIN J12 [get_ports reset]
set_property IOSTANDARD LVCMOS33 [get_ports reset]
set_property PULLDOWN true [get_ports reset]


## =========================================================
## 16x2 LCD
## J2 connector
## =========================================================

set_property -dict {PACKAGE_PIN M5 IOSTANDARD LVCMOS33} [get_ports lcd_rs]
set_property -dict {PACKAGE_PIN P5 IOSTANDARD LVCMOS33} [get_ports lcd_en]

set_property -dict {PACKAGE_PIN M4 IOSTANDARD LVCMOS33} [get_ports {lcd_d[0]}]
set_property -dict {PACKAGE_PIN L5 IOSTANDARD LVCMOS33} [get_ports {lcd_d[1]}]
set_property -dict {PACKAGE_PIN P11 IOSTANDARD LVCMOS33} [get_ports {lcd_d[2]}]
set_property -dict {PACKAGE_PIN N11 IOSTANDARD LVCMOS33} [get_ports {lcd_d[3]}]
set_property -dict {PACKAGE_PIN P13 IOSTANDARD LVCMOS33} [get_ports {lcd_d[4]}]
set_property -dict {PACKAGE_PIN M14 IOSTANDARD LVCMOS33} [get_ports {lcd_d[5]}]
set_property -dict {PACKAGE_PIN M12 IOSTANDARD LVCMOS33} [get_ports {lcd_d[6]}]
set_property -dict {PACKAGE_PIN K12 IOSTANDARD LVCMOS33} [get_ports {lcd_d[7]}]

set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]

##===================================================================================================##
##========================= Xilinx design constraints (XDC) information =============================##
##======================================  FLOORPLANNING  ============================================##
##===================================================================================================##

set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]

##===================================================================================================##
##=========================================  CLOCKS  ================================================##
##===================================================================================================##

##==============##
## FABRIC CLOCK ##
##==============##

## Bank 33:
set_property -dict {PACKAGE_PIN AD11 IOSTANDARD LVDS} [get_ports clk_in_n]
set_property -dict {PACKAGE_PIN AD12 IOSTANDARD LVDS} [get_ports clk_in_p]
##create_clock -period 5.000 [get_ports clk_in_p]
##set_input_jitter clk_in_p 0.050

set_clock_groups -asynchronous -group [get_clocks clk_out2_clk_wiz_4] -group [get_clocks clkout0]


##===========##
## MGT CLOCK ##
##===========##

# Bank 117:
#160 MHz external clock:
set_property PACKAGE_PIN J7 [get_ports refclk_mgt_n]
set_property PACKAGE_PIN J8 [get_ports refclk_mgt_p]
create_clock -period 6.250 [get_ports refclk_mgt_p]

#######################################################
# I/O constraints                                     #
#######################################################

# These inputs can be connected to dip switches or push buttons on an
# appropriate board.

##===================================================================================================##
##========================================  I/O PINS  ===============================================##
##===================================================================================================##

##====================##
## Configuration pins ##
##====================##

set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 2.5 [current_design]


##======##
## UART ##
##======##

set_property PACKAGE_PIN K24 [get_ports uart_tx]
set_property PACKAGE_PIN M19 [get_ports uart_rx]
set_property IOSTANDARD LVCMOS25 [get_ports uart_tx]
set_property IOSTANDARD LVCMOS25 [get_ports uart_rx]


##=======##
## RESET ##
##=======##

# IO_25_VRP_34
set_false_path -from [get_ports btn_reset]
## Bank 34:
set_property PACKAGE_PIN AB7 [get_ports btn_reset]
set_property IOSTANDARD LVCMOS15 [get_ports btn_reset]


##==========##
## FMC(HPC) ##
##==========##

set_property -dict {PACKAGE_PIN F11 IOSTANDARD LVDS_25} [get_ports BCLK_IN_P[0] ]
set_property -dict {PACKAGE_PIN E11 IOSTANDARD LVDS_25} [get_ports BCLK_IN_N[0] ]
set_property -dict {PACKAGE_PIN G22 IOSTANDARD LVDS_25} [get_ports BCLK_IN_P[1] ]
set_property -dict {PACKAGE_PIN F22 IOSTANDARD LVDS_25} [get_ports BCLK_IN_N[1] ]
set_property -dict {PACKAGE_PIN G18 IOSTANDARD LVDS_25} [get_ports BCLK_IN_P[2] ]
set_property -dict {PACKAGE_PIN F18 IOSTANDARD LVDS_25} [get_ports BCLK_IN_N[2] ]
set_property -dict {PACKAGE_PIN G28 IOSTANDARD LVDS_25} [get_ports BCLK_IN_P[3] ]
set_property -dict {PACKAGE_PIN F28 IOSTANDARD LVDS_25} [get_ports BCLK_IN_N[3] ]

set_property -dict {PACKAGE_PIN C25 IOSTANDARD LVDS_25} [get_ports DOWNLINK_IN_P[0] ]
set_property -dict {PACKAGE_PIN B25 IOSTANDARD LVDS_25} [get_ports DOWNLINK_IN_N[0] ]
set_property -dict {PACKAGE_PIN D11 IOSTANDARD LVDS_25} [get_ports DOWNLINK_IN_P[1] ]
set_property -dict {PACKAGE_PIN C11 IOSTANDARD LVDS_25} [get_ports DOWNLINK_IN_N[1] ]
set_property -dict {PACKAGE_PIN E19 IOSTANDARD LVDS_25} [get_ports DOWNLINK_IN_P[2] ]
set_property -dict {PACKAGE_PIN D19 IOSTANDARD LVDS_25} [get_ports DOWNLINK_IN_N[2] ]
set_property -dict {PACKAGE_PIN C20 IOSTANDARD LVDS_25} [get_ports DOWNLINK_IN_P[3] ]
set_property -dict {PACKAGE_PIN B20 IOSTANDARD LVDS_25} [get_ports DOWNLINK_IN_N[3] ]
set_property -dict {PACKAGE_PIN C17 IOSTANDARD LVDS_25} [get_ports DOWNLINK_IN_P[4] ]
set_property -dict {PACKAGE_PIN B17 IOSTANDARD LVDS_25} [get_ports DOWNLINK_IN_N[4] ]
set_property -dict {PACKAGE_PIN H21 IOSTANDARD LVDS_25} [get_ports DOWNLINK_IN_P[5] ]
set_property -dict {PACKAGE_PIN H22 IOSTANDARD LVDS_25} [get_ports DOWNLINK_IN_N[5] ]
set_property -dict {PACKAGE_PIN B14 IOSTANDARD LVDS_25} [get_ports DOWNLINK_IN_P[6] ]
set_property -dict {PACKAGE_PIN A15 IOSTANDARD LVDS_25} [get_ports DOWNLINK_IN_N[6] ]
set_property -dict {PACKAGE_PIN G29 IOSTANDARD LVDS_25} [get_ports DOWNLINK_IN_P[7] ]
set_property -dict {PACKAGE_PIN F30 IOSTANDARD LVDS_25} [get_ports DOWNLINK_IN_N[7] ]
set_property -dict {PACKAGE_PIN J11 IOSTANDARD LVDS_25} [get_ports DOWNLINK_IN_P[8] ]
set_property -dict {PACKAGE_PIN J12 IOSTANDARD LVDS_25} [get_ports DOWNLINK_IN_N[8] ]
set_property -dict {PACKAGE_PIN D12 IOSTANDARD LVDS_25} [get_ports DOWNLINK_IN_P[9] ]
set_property -dict {PACKAGE_PIN D13 IOSTANDARD LVDS_25} [get_ports DOWNLINK_IN_N[9] ]
set_property -dict {PACKAGE_PIN F12 IOSTANDARD LVDS_25} [get_ports DOWNLINK_IN_P[10] ]
set_property -dict {PACKAGE_PIN E13 IOSTANDARD LVDS_25} [get_ports DOWNLINK_IN_N[10] ]

set_property -dict {PACKAGE_PIN G17 IOSTANDARD LVDS_25} [get_ports EC_IN_P ]
set_property -dict {PACKAGE_PIN F17 IOSTANDARD LVDS_25} [get_ports EC_IN_N ]
set_property -dict {PACKAGE_PIN D21 IOSTANDARD LVDS_25} [get_ports EC_OUT_P ]
set_property -dict {PACKAGE_PIN C21 IOSTANDARD LVDS_25} [get_ports EC_OUT_N ]

set_property -dict {PACKAGE_PIN D29 IOSTANDARD LVCMOS25} [get_ports GPIO[0] ]
set_property -dict {PACKAGE_PIN C30 IOSTANDARD LVCMOS25} [get_ports GPIO[1] ]
set_property -dict {PACKAGE_PIN A25 IOSTANDARD LVCMOS25} [get_ports GPIO[2] ]
set_property -dict {PACKAGE_PIN A26 IOSTANDARD LVCMOS25} [get_ports GPIO[3] ]
set_property -dict {PACKAGE_PIN B28 IOSTANDARD LVCMOS25} [get_ports GPIO[4] ]
set_property -dict {PACKAGE_PIN A28 IOSTANDARD LVCMOS25} [get_ports GPIO[5] ]
set_property -dict {PACKAGE_PIN H30 IOSTANDARD LVCMOS25} [get_ports GPIO[6] ]
set_property -dict {PACKAGE_PIN G30 IOSTANDARD LVCMOS25} [get_ports GPIO[7] ]
set_property -dict {PACKAGE_PIN F20 IOSTANDARD LVCMOS25} [get_ports GPIO[8] ]
set_property -dict {PACKAGE_PIN E20 IOSTANDARD LVCMOS25} [get_ports GPIO[9] ]
set_property -dict {PACKAGE_PIN F21 IOSTANDARD LVCMOS25} [get_ports GPIO[10] ]
set_property -dict {PACKAGE_PIN E21 IOSTANDARD LVCMOS25} [get_ports GPIO[11] ]
set_property -dict {PACKAGE_PIN B18 IOSTANDARD LVCMOS25} [get_ports GPIO[12] ]
set_property -dict {PACKAGE_PIN A18 IOSTANDARD LVCMOS25} [get_ports GPIO[13] ]
set_property -dict {PACKAGE_PIN C19 IOSTANDARD LVCMOS25} [get_ports GPIO[14] ]
set_property -dict {PACKAGE_PIN B19 IOSTANDARD LVCMOS25} [get_ports GPIO[15] ]

set_property -dict {PACKAGE_PIN A30 IOSTANDARD LVCMOS25} [get_ports SCL0 ]
set_property -dict {PACKAGE_PIN A22 IOSTANDARD LVCMOS25} [get_ports SCL1 ]
set_property -dict {PACKAGE_PIN B30 IOSTANDARD LVCMOS25} [get_ports SDA0 ]
set_property -dict {PACKAGE_PIN B22 IOSTANDARD LVCMOS25} [get_ports SDA1 ]

set_property -dict {PACKAGE_PIN D16 IOSTANDARD LVDS_25} [get_ports UPLINK1_OUT_P[0] ]
set_property -dict {PACKAGE_PIN C16 IOSTANDARD LVDS_25} [get_ports UPLINK1_OUT_N[0] ]
set_property -dict {PACKAGE_PIN F15 IOSTANDARD LVDS_25} [get_ports UPLINK1_OUT_P[1] ]
set_property -dict {PACKAGE_PIN E16 IOSTANDARD LVDS_25} [get_ports UPLINK1_OUT_N[1] ]
set_property -dict {PACKAGE_PIN D14 IOSTANDARD LVDS_25} [get_ports UPLINK1_OUT_P[2] ]
set_property -dict {PACKAGE_PIN C14 IOSTANDARD LVDS_25} [get_ports UPLINK1_OUT_N[2] ]
set_property -dict {PACKAGE_PIN E14 IOSTANDARD LVDS_25} [get_ports UPLINK1_OUT_P[3] ]
set_property -dict {PACKAGE_PIN E15 IOSTANDARD LVDS_25} [get_ports UPLINK1_OUT_N[3] ]
set_property -dict {PACKAGE_PIN J16 IOSTANDARD LVDS_25} [get_ports UPLINK1_OUT_P[4] ]
set_property -dict {PACKAGE_PIN H16 IOSTANDARD LVDS_25} [get_ports UPLINK1_OUT_N[4] ]
set_property -dict {PACKAGE_PIN H15 IOSTANDARD LVDS_25} [get_ports UPLINK1_OUT_P[5] ]
set_property -dict {PACKAGE_PIN G15 IOSTANDARD LVDS_25} [get_ports UPLINK1_OUT_N[5] ]
set_property -dict {PACKAGE_PIN G13 IOSTANDARD LVDS_25} [get_ports UPLINK1_OUT_P[6] ]
set_property -dict {PACKAGE_PIN F13 IOSTANDARD LVDS_25} [get_ports UPLINK1_OUT_N[6] ]
set_property -dict {PACKAGE_PIN K14 IOSTANDARD LVDS_25} [get_ports UPLINK1_OUT_P[7] ]
set_property -dict {PACKAGE_PIN J14 IOSTANDARD LVDS_25} [get_ports UPLINK1_OUT_N[7] ]
set_property -dict {PACKAGE_PIN H11 IOSTANDARD LVDS_25} [get_ports UPLINK1_OUT_P[8] ]
set_property -dict {PACKAGE_PIN H12 IOSTANDARD LVDS_25} [get_ports UPLINK1_OUT_N[8] ]
set_property -dict {PACKAGE_PIN K13 IOSTANDARD LVDS_25} [get_ports UPLINK1_OUT_P[9] ]
set_property -dict {PACKAGE_PIN J13 IOSTANDARD LVDS_25} [get_ports UPLINK1_OUT_N[9] ]
set_property -dict {PACKAGE_PIN D26 IOSTANDARD LVDS_25} [get_ports UPLINK1_OUT_P[10] ]
set_property -dict {PACKAGE_PIN C26 IOSTANDARD LVDS_25} [get_ports UPLINK1_OUT_N[10] ]
set_property -dict {PACKAGE_PIN H24 IOSTANDARD LVDS_25} [get_ports UPLINK1_OUT_P[11] ]
set_property -dict {PACKAGE_PIN H25 IOSTANDARD LVDS_25} [get_ports UPLINK1_OUT_N[11] ]
set_property -dict {PACKAGE_PIN H26 IOSTANDARD LVDS_25} [get_ports UPLINK1_OUT_P[12] ]
set_property -dict {PACKAGE_PIN H27 IOSTANDARD LVDS_25} [get_ports UPLINK1_OUT_N[12] ]
set_property -dict {PACKAGE_PIN G27 IOSTANDARD LVDS_25} [get_ports UPLINK1_OUT_P[13] ]
set_property -dict {PACKAGE_PIN F27 IOSTANDARD LVDS_25} [get_ports UPLINK1_OUT_N[13] ]
set_property -dict {PACKAGE_PIN C24 IOSTANDARD LVDS_25} [get_ports UPLINK1_OUT_P[14] ]
set_property -dict {PACKAGE_PIN B24 IOSTANDARD LVDS_25} [get_ports UPLINK1_OUT_N[14] ]

set_property -dict {PACKAGE_PIN H14 IOSTANDARD LVDS_25} [get_ports UPLINK2_OUT_P[0] ]
set_property -dict {PACKAGE_PIN G14 IOSTANDARD LVDS_25} [get_ports UPLINK2_OUT_N[0] ]
set_property -dict {PACKAGE_PIN C12 IOSTANDARD LVDS_25} [get_ports UPLINK2_OUT_P[1] ]
set_property -dict {PACKAGE_PIN B12 IOSTANDARD LVDS_25} [get_ports UPLINK2_OUT_N[1] ]
set_property -dict {PACKAGE_PIN A11 IOSTANDARD LVDS_25} [get_ports UPLINK2_OUT_P[2] ]
set_property -dict {PACKAGE_PIN A12 IOSTANDARD LVDS_25} [get_ports UPLINK2_OUT_N[2] ]
set_property -dict {PACKAGE_PIN B13 IOSTANDARD LVDS_25} [get_ports UPLINK2_OUT_P[3] ]
set_property -dict {PACKAGE_PIN A13 IOSTANDARD LVDS_25} [get_ports UPLINK2_OUT_N[3] ]
set_property -dict {PACKAGE_PIN C15 IOSTANDARD LVDS_25} [get_ports UPLINK2_OUT_P[4] ]
set_property -dict {PACKAGE_PIN B15 IOSTANDARD LVDS_25} [get_ports UPLINK2_OUT_N[4] ]
set_property -dict {PACKAGE_PIN L16 IOSTANDARD LVDS_25} [get_ports UPLINK2_OUT_P[5] ]
set_property -dict {PACKAGE_PIN K16 IOSTANDARD LVDS_25} [get_ports UPLINK2_OUT_N[5] ]
set_property -dict {PACKAGE_PIN L15 IOSTANDARD LVDS_25} [get_ports UPLINK2_OUT_P[6] ]
set_property -dict {PACKAGE_PIN K15 IOSTANDARD LVDS_25} [get_ports UPLINK2_OUT_N[6] ]
set_property -dict {PACKAGE_PIN L11 IOSTANDARD LVDS_25} [get_ports UPLINK2_OUT_P[7] ]
set_property -dict {PACKAGE_PIN K11 IOSTANDARD LVDS_25} [get_ports UPLINK2_OUT_N[7] ]
set_property -dict {PACKAGE_PIN L12 IOSTANDARD LVDS_25} [get_ports UPLINK2_OUT_P[8] ]
set_property -dict {PACKAGE_PIN L13 IOSTANDARD LVDS_25} [get_ports UPLINK2_OUT_N[8] ]
set_property -dict {PACKAGE_PIN E28 IOSTANDARD LVDS_25} [get_ports UPLINK2_OUT_P[9] ]
set_property -dict {PACKAGE_PIN D28 IOSTANDARD LVDS_25} [get_ports UPLINK2_OUT_N[9] ]
set_property -dict {PACKAGE_PIN E29 IOSTANDARD LVDS_25} [get_ports UPLINK2_OUT_P[10] ]
set_property -dict {PACKAGE_PIN E30 IOSTANDARD LVDS_25} [get_ports UPLINK2_OUT_N[10] ]
set_property -dict {PACKAGE_PIN C29 IOSTANDARD LVDS_25} [get_ports UPLINK2_OUT_P[11] ]
set_property -dict {PACKAGE_PIN B29 IOSTANDARD LVDS_25} [get_ports UPLINK2_OUT_N[11] ]
set_property -dict {PACKAGE_PIN B27 IOSTANDARD LVDS_25} [get_ports UPLINK2_OUT_P[12] ]
set_property -dict {PACKAGE_PIN A27 IOSTANDARD LVDS_25} [get_ports UPLINK2_OUT_N[12] ]
set_property -dict {PACKAGE_PIN A20 IOSTANDARD LVDS_25} [get_ports UPLINK2_OUT_P[13] ]
set_property -dict {PACKAGE_PIN A21 IOSTANDARD LVDS_25} [get_ports UPLINK2_OUT_N[13] ]
set_property -dict {PACKAGE_PIN A16 IOSTANDARD LVDS_25} [get_ports UPLINK2_OUT_P[14] ]
set_property -dict {PACKAGE_PIN A17 IOSTANDARD LVDS_25} [get_ports UPLINK2_OUT_N[14] ]
set_property -dict {PACKAGE_PIN D22 IOSTANDARD LVDS_25} [get_ports UPLINK2_OUT_P[15] ]
set_property -dict {PACKAGE_PIN C22 IOSTANDARD LVDS_25} [get_ports UPLINK2_OUT_N[15] ]

set_property DIFF_TERM true [get_ports BCLK_IN_P[0] ]
set_property DIFF_TERM true [get_ports BCLK_IN_P[1] ]
set_property DIFF_TERM true [get_ports BCLK_IN_P[2] ]
set_property DIFF_TERM true [get_ports BCLK_IN_P[3] ]

set_property DIFF_TERM true [get_ports DOWNLINK_IN_P[0] ]
set_property DIFF_TERM true [get_ports DOWNLINK_IN_P[1] ]
set_property DIFF_TERM true [get_ports DOWNLINK_IN_P[2] ]
set_property DIFF_TERM true [get_ports DOWNLINK_IN_P[3] ]
set_property DIFF_TERM true [get_ports DOWNLINK_IN_P[4] ]
set_property DIFF_TERM true [get_ports DOWNLINK_IN_P[5] ]
set_property DIFF_TERM true [get_ports DOWNLINK_IN_P[6] ]
set_property DIFF_TERM true [get_ports DOWNLINK_IN_P[7] ]
set_property DIFF_TERM true [get_ports DOWNLINK_IN_P[8] ]
set_property DIFF_TERM true [get_ports DOWNLINK_IN_P[9] ]
set_property DIFF_TERM true [get_ports DOWNLINK_IN_P[10] ]

set_property DIFF_TERM true [get_ports EC_IN_P ]

##==========##
## MGT(GTX) ##
##==========##

## SERIAL LANES:
##--------------

# Bank 117:
set_property PACKAGE_PIN G3 [get_ports SFP_RX_N_1]
set_property PACKAGE_PIN G4 [get_ports SFP_RX_P_1]
set_property PACKAGE_PIN H1 [get_ports SFP_TX_N_1]
set_property PACKAGE_PIN H2 [get_ports SFP_TX_P_1]

set_property PACKAGE_PIN F5 [get_ports SFP_RX_N_2]
set_property PACKAGE_PIN F6 [get_ports SFP_RX_P_2]
set_property PACKAGE_PIN F1 [get_ports SFP_TX_N_2]
set_property PACKAGE_PIN F2 [get_ports SFP_TX_P_2]

## SFP CONTROL:
##-------------

# IO_0_12
# Bank 12:
set_property PACKAGE_PIN Y20 [get_ports tx_disable]
set_property IOSTANDARD LVCMOS25 [get_ports tx_disable]

set_property PACKAGE_PIN AK21 [get_ports tx_disable_2]
set_property IOSTANDARD LVCMOS25 [get_ports tx_disable_2]


##===============##
## ON-BOARD LEDS ##
##===============##

# IO_L2N_T0_33
set_property PACKAGE_PIN AB8 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS15 [get_ports {led[0]}]
# IO_L2P_T0_33
set_property PACKAGE_PIN AA8 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS15 [get_ports {led[1]}]
# IO_L3N_T0_DQS_33
set_property PACKAGE_PIN AC9 [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS15 [get_ports {led[2]}]
# IO_L3P_T0_DQS_33
set_property PACKAGE_PIN AB9 [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS15 [get_ports {led[3]}]
# IO_25_13
set_property PACKAGE_PIN AE26 [get_ports {led[4]}]
set_property IOSTANDARD LVCMOS15 [get_ports {led[4]}]
# IO_0_17
set_property PACKAGE_PIN G19 [get_ports {led[5]}]
set_property IOSTANDARD LVCMOS25 [get_ports {led[5]}]
# IO_25_17
set_property PACKAGE_PIN E18 [get_ports {led[6]}]
set_property IOSTANDARD LVCMOS25 [get_ports {led[6]}]
# IO_25_18
set_property PACKAGE_PIN F16 [get_ports {led[7]}]
set_property IOSTANDARD LVCMOS25 [get_ports {led[7]}]


##==============##
##      LCD     ##
##==============##

# LCD (Bank 33):
set_property PACKAGE_PIN AB10 [get_ports LCD_E]
set_property PACKAGE_PIN AB13 [get_ports LCD_RW]
set_property PACKAGE_PIN Y11 [get_ports LCD_RS]
set_property PACKAGE_PIN AA13 [get_ports {LCD_DB[0]}]
set_property PACKAGE_PIN AA10 [get_ports {LCD_DB[1]}]
set_property PACKAGE_PIN AA11 [get_ports {LCD_DB[2]}]
set_property PACKAGE_PIN Y10 [get_ports {LCD_DB[3]}]

set_property IOSTANDARD LVCMOS15 [get_ports LCD_E]
set_property IOSTANDARD LVCMOS15 [get_ports LCD_RW]
set_property IOSTANDARD LVCMOS15 [get_ports LCD_RS]
set_property IOSTANDARD LVCMOS15 [get_ports {LCD_DB[0]}]
set_property IOSTANDARD LVCMOS15 [get_ports {LCD_DB[1]}]
set_property IOSTANDARD LVCMOS15 [get_ports {LCD_DB[2]}]
set_property IOSTANDARD LVCMOS15 [get_ports {LCD_DB[3]}]


##====================##
## SIGNALS FORWARDING ##
##====================##

## SMA OUTPUT:
##------------

# Bank 15:
set_property PACKAGE_PIN K25 [get_ports USER_SMA_CLOCK_N]
set_property PACKAGE_PIN L25 [get_ports USER_SMA_CLOCK_P]
set_property IOSTANDARD LVDS_25 [get_ports USER_SMA_CLOCK_N]
set_property IOSTANDARD LVDS_25 [get_ports USER_SMA_CLOCK_P]

# Bank 12:
set_property PACKAGE_PIN Y24 [get_ports USER_SMA_GPIO_N]
set_property PACKAGE_PIN Y23 [get_ports USER_SMA_GPIO_P]
set_property IOSTANDARD LVDS_25 [get_ports USER_SMA_GPIO_N]
set_property IOSTANDARD LVDS_25 [get_ports USER_SMA_GPIO_P]

##===================================================================================================##
##====================##
## EyeScan constraints ##
##====================##
set_property PMA_RSV2 16'h2070 [get_cells lpGBT_HighSpeedLink_inst/gtx_rxtx_dual_inst/gtwizard_0_inst/U0/gtwizard_0_init_i/gtwizard_0_i/gt0_gtwizard_0_i/gtxe2_i]
set_property ES_ERRDET_EN TRUE [get_cells lpGBT_HighSpeedLink_inst/gtx_rxtx_dual_inst/gtwizard_0_inst/U0/gtwizard_0_init_i/gtwizard_0_i/gt0_gtwizard_0_i/gtxe2_i]
set_property ES_SDATA_MASK 80'hFFFFFFFFFF00000000FF [get_cells lpGBT_HighSpeedLink_inst/gtx_rxtx_dual_inst/gtwizard_0_inst/U0/gtwizard_0_init_i/gtwizard_0_i/gt0_gtwizard_0_i/gtxe2_i]
set_property ES_QUAL_MASK 80'hFFFFFFFFFFFFFFFFFFFF [get_cells lpGBT_HighSpeedLink_inst/gtx_rxtx_dual_inst/gtwizard_0_inst/U0/gtwizard_0_init_i/gtwizard_0_i/gt0_gtwizard_0_i/gtxe2_i]
----------------------------------------------------------------------------------
-- Company: DESY 
-- Engineer: Artur Boebel
-- 
-- Create Date: 27/05/2019
-- Description: "Blank" GTX Transmitter. Needs a stable 160 MHz Source at REFCLK_MGT in (J15 / J16 Differential)  
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

--use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VComponents.all;

entity GTX_RxTx is
    Port ( SYSCLK_IN : in STD_LOGIC;
           REFCLK_MGT_P : in STD_LOGIC;
           REFCLK_MGT_N : in STD_LOGIC;
           RESET_IN : in STD_LOGIC;
           TXDATA : in std_logic_vector (63 downto 0);
           RXDATA : out std_logic_vector (63 downto 0);
           TXUSRCLK2 : out STD_LOGIC;
           RXUSRCLK2 : out STD_LOGIC;
           RESETDONE : out STD_LOGIC;
           RX_P : in STD_LOGIC;
           RX_N : in STD_LOGIC;
           TX_P : out STD_LOGIC;
           TX_N : out STD_LOGIC);
end GTX_RxTx;

architecture Behavioral of GTX_RxTx is
    component gtwizard_0 port (
        SOFT_RESET_TX_IN                        : in   std_logic;
        SOFT_RESET_RX_IN                        : in   std_logic;
        DONT_RESET_ON_DATA_ERROR_IN             : in   std_logic;
        Q0_CLK1_GTREFCLK_PAD_N_IN               : in   std_logic;
        Q0_CLK1_GTREFCLK_PAD_P_IN               : in   std_logic;

        GT0_TX_FSM_RESET_DONE_OUT               : out  std_logic;
        GT0_RX_FSM_RESET_DONE_OUT               : out  std_logic;
        GT0_DATA_VALID_IN                       : in   std_logic;
        GT0_TX_MMCM_LOCK_OUT                    : out  std_logic;
        GT0_RX_MMCM_LOCK_OUT                    : out  std_logic;
 
        GT0_TXUSRCLK_OUT                        : out  std_logic;
        GT0_TXUSRCLK2_OUT                       : out  std_logic;
        GT0_RXUSRCLK_OUT                        : out  std_logic;
        GT0_RXUSRCLK2_OUT                       : out  std_logic;

        gt0_drpaddr_in                          : in   std_logic_vector(8 downto 0);
        gt0_drpdi_in                            : in   std_logic_vector(15 downto 0);
        gt0_drpdo_out                           : out  std_logic_vector(15 downto 0);
        gt0_drpen_in                            : in   std_logic;
        gt0_drprdy_out                          : out  std_logic;
        gt0_drpwe_in                            : in   std_logic;

        gt0_dmonitorout_out                     : out  std_logic_vector(7 downto 0);
        gt0_eyescanreset_in                     : in   std_logic;
        gt0_rxuserrdy_in                        : in   std_logic;
        gt0_eyescandataerror_out                : out  std_logic;
        gt0_eyescantrigger_in                   : in   std_logic;
        gt0_rxdata_out                          : out  std_logic_vector(63 downto 0);
        gt0_gtxrxp_in                           : in   std_logic;
        gt0_gtxrxn_in                           : in   std_logic;
        gt0_rxdfelpmreset_in                    : in   std_logic;
        gt0_rxmonitorout_out                    : out  std_logic_vector(6 downto 0);
        gt0_rxmonitorsel_in                     : in   std_logic_vector(1 downto 0);
        gt0_rxoutclkfabric_out                  : out  std_logic;
        gt0_gtrxreset_in                        : in   std_logic;
        gt0_rxpmareset_in                       : in   std_logic;
        gt0_rxresetdone_out                     : out  std_logic;
        gt0_gttxreset_in                        : in   std_logic;
        gt0_txuserrdy_in                        : in   std_logic;
        gt0_txdata_in                           : in   std_logic_vector(63 downto 0);
        gt0_gtxtxn_out                          : out  std_logic;
        gt0_gtxtxp_out                          : out  std_logic;
        gt0_txoutclkfabric_out                  : out  std_logic;
        gt0_txoutclkpcs_out                     : out  std_logic;
        gt0_txresetdone_out                     : out  std_logic;
        GT0_QPLLLOCK_OUT                        : out  std_logic;
        GT0_QPLLREFCLKLOST_OUT                  : out  std_logic;
        GT0_QPLLOUTCLK_OUT                      : out  std_logic;
        GT0_QPLLOUTREFCLK_OUT                   : out  std_logic;
        sysclk_in                               : in   std_logic
    ); end component;
    signal RX_RESETDONE, TX_RESETDONE, TX_FSM_RESETDONE, RX_FSM_RESETDONE : std_logic := '0';
    
begin
    RESETDONE <= RX_RESETDONE and TX_RESETDONE and TX_FSM_RESETDONE and RX_FSM_RESETDONE;

    gtwizard_0_inst: gtwizard_0 port map(
        -- Transceiver clock input (160 MHz):
        Q0_CLK1_GTREFCLK_PAD_N_IN => REFCLK_MGT_N,
        Q0_CLK1_GTREFCLK_PAD_P_IN => REFCLK_MGT_P,
        -- System clock input (100 MHz):
        sysclk_in => SYSCLK_IN,
        -- Reference clock outputs:
        GT0_TXUSRCLK2_OUT => TXUSRCLK2,                 -- reference clock for gt0_txdata_in 
        GT0_RXUSRCLK2_OUT => RXUSRCLK2,                 -- reference clock for gt0_rxdata_out
        -- RX / TX Data Bus in / out:
        gt0_rxdata_out => RXDATA,
        gt0_txdata_in => TXDATA,
        -- Reset Input / Done Output
        SOFT_RESET_TX_IN => RESET_IN,                   -- } (seems to have no influence)
        SOFT_RESET_RX_IN => RESET_IN,                   -- } (seems to have no influence)
        gt0_rxpmareset_in => RESET_IN,                  --   (a kind of reset function)
        gt0_eyescanreset_in => RESET_IN,                --   (affects alignment)
        gt0_rxresetdone_out => RX_RESETDONE,
        gt0_txresetdone_out => TX_RESETDONE,
        GT0_TX_FSM_RESET_DONE_OUT => TX_FSM_RESETDONE,
        GT0_RX_FSM_RESET_DONE_OUT => RX_FSM_RESETDONE,
        -- Serial Signal input / outputs:
        gt0_gtxrxp_in => RX_P,
        gt0_gtxrxn_in => RX_N,
        gt0_gtxtxp_out => TX_P,
        gt0_gtxtxn_out => TX_N,
        -- Other inputs, that doesn't really matter:
        gt0_rxuserrdy_in => '1',                        -- (seems to have no influence)
        gt0_txuserrdy_in => '1',                        -- (seems to have no influence)
        gt0_gtrxreset_in => '0',                        -- (seems to have no influence)
        gt0_gttxreset_in => '0',                        -- (seems to have no influence)
        gt0_eyescantrigger_in => '0',
        gt0_rxdfelpmreset_in => '0',
        gt0_rxmonitorsel_in => B"00",
        gt0_drpaddr_in => B"000000000",
        gt0_drpdi_in => B"0000000000000000",
        gt0_drpen_in => '0',
        gt0_drpwe_in => '0',
        GT0_DATA_VALID_IN => '1',                        -- '1' (sets GT0_RX_FSM_RESET_DONE_OUT, no other influence)
        DONT_RESET_ON_DATA_ERROR_IN => '1'
    );
end Behavioral;

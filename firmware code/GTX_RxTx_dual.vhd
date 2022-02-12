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

entity GTX_RxTx_dual is
    Port ( SYSCLK_IN : in STD_LOGIC;
           REFCLK_MGT_P : in STD_LOGIC;
           REFCLK_MGT_N : in STD_LOGIC;
           RESET_IN : in STD_LOGIC;
           RESETDONE : out STD_LOGIC;
           -- First transceiver:
           TXDATA : in std_logic_vector (63 downto 0);
           RXDATA : out std_logic_vector (63 downto 0);
           TXUSRCLK2 : out STD_LOGIC;
           RXUSRCLK2 : out STD_LOGIC;
           RX_P : in STD_LOGIC;
           RX_N : in STD_LOGIC;
           TX_P : out STD_LOGIC;
           TX_N : out STD_LOGIC;
           -- Second transceiver:
           TXDATA_2 : in std_logic_vector (63 downto 0);
           RXDATA_2 : out std_logic_vector (63 downto 0);
           TXUSRCLK2_2 : out STD_LOGIC;
           RXUSRCLK2_2 : out STD_LOGIC;
           RX_P_2 : in STD_LOGIC;
           RX_N_2 : in STD_LOGIC;
           TX_P_2 : out STD_LOGIC;
           TX_N_2 : out STD_LOGIC;
           -- EyeScan module:
           RunScan : in std_logic;
           ScanComplete : out std_logic;
           GetData_eye_req : in std_logic;
           GetData_eye_rdy : out std_logic;
           GetData_eye_nxt : in std_logic;
           GetData_eye_cmplt : out std_logic;
           Max_Prescale : in std_logic_vector(4 downto 0);
           GetData_eye_vertical : out std_logic_vector(991 downto 0);
           GetData_eye_horizontal : out std_logic_vector(991 downto 0);
           GetData_eye_samples : out std_logic_vector(991 downto 0);
           GetData_eye_errors : out std_logic_vector(991 downto 0)
           );
end GTX_RxTx_dual;

architecture Behavioral of GTX_RxTx_dual is
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

    component gtwizard_1 port (
        SYSCLK_IN                               : in   std_logic;
        SOFT_RESET_TX_IN                        : in   std_logic;
        SOFT_RESET_RX_IN                        : in   std_logic;
        DONT_RESET_ON_DATA_ERROR_IN             : in   std_logic;
        GT0_TX_FSM_RESET_DONE_OUT               : out  std_logic;
        GT0_RX_FSM_RESET_DONE_OUT               : out  std_logic;
        GT0_DATA_VALID_IN                       : in   std_logic;
        GT0_TX_MMCM_LOCK_IN                     : in   std_logic;
        GT0_TX_MMCM_RESET_OUT                   : out  std_logic;
        GT0_RX_MMCM_LOCK_IN                     : in   std_logic;
        GT0_RX_MMCM_RESET_OUT                   : out  std_logic;

        --_________________________________________________________________________
        --GT0  (X1Y0)
        --____________________________CHANNEL PORTS________________________________
        ---------------------------- Channel - DRP Ports  --------------------------
        gt0_drpaddr_in                          : in   std_logic_vector(8 downto 0);
        gt0_drpclk_in                           : in   std_logic;
        gt0_drpdi_in                            : in   std_logic_vector(15 downto 0);
        gt0_drpdo_out                           : out  std_logic_vector(15 downto 0);
        gt0_drpen_in                            : in   std_logic;
        gt0_drprdy_out                          : out  std_logic;
        gt0_drpwe_in                            : in   std_logic;
        --------------------------- Digital Monitor Ports --------------------------
        gt0_dmonitorout_out                     : out  std_logic_vector(7 downto 0);
        --------------------- RX Initialization and Reset Ports --------------------
        gt0_eyescanreset_in                     : in   std_logic;
        gt0_rxuserrdy_in                        : in   std_logic;
        -------------------------- RX Margin Analysis Ports ------------------------
        gt0_eyescandataerror_out                : out  std_logic;
        gt0_eyescantrigger_in                   : in   std_logic;
        ------------------ Receive Ports - FPGA RX Interface Ports -----------------
        gt0_rxusrclk_in                         : in   std_logic;
        gt0_rxusrclk2_in                        : in   std_logic;
        ------------------ Receive Ports - FPGA RX interface Ports -----------------
        gt0_rxdata_out                          : out  std_logic_vector(63 downto 0);
        --------------------------- Receive Ports - RX AFE -------------------------
        gt0_gtxrxp_in                           : in   std_logic;
        ------------------------ Receive Ports - RX AFE Ports ----------------------
        gt0_gtxrxn_in                           : in   std_logic;
        --------------------- Receive Ports - RX Equalizer Ports -------------------
        gt0_rxdfelpmreset_in                    : in   std_logic;
        gt0_rxmonitorout_out                    : out  std_logic_vector(6 downto 0);
        gt0_rxmonitorsel_in                     : in   std_logic_vector(1 downto 0);
        --------------- Receive Ports - RX Fabric Output Control Ports -------------
        gt0_rxoutclkfabric_out                  : out  std_logic;
        ------------- Receive Ports - RX Initialization and Reset Ports ------------
        gt0_gtrxreset_in                        : in   std_logic;
        gt0_rxpmareset_in                       : in   std_logic;
        -------------- Receive Ports -RX Initialization and Reset Ports ------------
        gt0_rxresetdone_out                     : out  std_logic;
        --------------------- TX Initialization and Reset Ports --------------------
        gt0_gttxreset_in                        : in   std_logic;
        gt0_txuserrdy_in                        : in   std_logic;
        ------------------ Transmit Ports - FPGA TX Interface Ports ----------------
        gt0_txusrclk_in                         : in   std_logic;
        gt0_txusrclk2_in                        : in   std_logic;
        ------------------ Transmit Ports - TX Data Path interface -----------------
        gt0_txdata_in                           : in   std_logic_vector(63 downto 0);
        ---------------- Transmit Ports - TX Driver and OOB signaling --------------
        gt0_gtxtxn_out                          : out  std_logic;
        gt0_gtxtxp_out                          : out  std_logic;
        ----------- Transmit Ports - TX Fabric Clock Output Control Ports ----------
        gt0_txoutclk_out                        : out  std_logic;
        gt0_txoutclkfabric_out                  : out  std_logic;
        gt0_txoutclkpcs_out                     : out  std_logic;
        ------------- Transmit Ports - TX Initialization and Reset Ports -----------
        gt0_txresetdone_out                     : out  std_logic;
        --____________________________COMMON PORTS________________________________
        GT0_QPLLLOCK_IN : in std_logic;
        GT0_QPLLREFCLKLOST_IN  : in std_logic;
        GT0_QPLLRESET_OUT  : out std_logic;
        GT0_QPLLOUTCLK_IN  : in std_logic;
        GT0_QPLLOUTREFCLK_IN : in std_logic
    ); end component;
    
    component eyeScan port(
        CLK                         : in   std_logic;
        SOFRST                      : in  std_logic;
        DRPDO                       : in std_logic_vector(15 downto 0);
        DRPDI                       : out std_logic_vector(15 downto 0);
        DRPWE                       : out  std_logic;
        DRPEN                       : out  std_logic;
        DRPRDY                      : in std_logic;
        DRPADDR                     : out std_logic_vector(8 downto 0);
        RunScan                     : in std_logic;
        ScanComplete                : out std_logic;
        GetData_eye_req             : in std_logic;
        GetData_eye_rdy             : out std_logic;
        GetData_eye_nxt             : in std_logic;
        GetData_eye_cmplt           : out std_logic;
        Max_Prescale                : in std_logic_vector(4 downto 0);
        GetData_eye_vertical        : out std_logic_vector(991 downto 0);
        GetData_eye_horizontal      : out std_logic_vector(991 downto 0);
        GetData_eye_samples         : out std_logic_vector(991 downto 0);
        GetData_eye_errors          : out std_logic_vector(991 downto 0)
    ); end component;

    signal RX_RESETDONE, TX_RESETDONE, RX_RESETDONE2, TX_RESETDONE2 : std_logic := '0';
    signal TX_FSM_RESETDONE, RX_FSM_RESETDONE, TX_FSM_RESETDONE2, RX_FSM_RESETDONE2 : std_logic := '0';
    signal TXUSRCLK, RXUSRCLK, TXUSRCLK2_INT, RXUSRCLK2_INT : std_logic;
    signal GT0_QPLLLOCK_OUT, GT0_QPLLREFCLKLOST_OUT, GT0_QPLLOUTCLK_OUT, GT0_QPLLOUTREFCLK_OUT : std_logic;
    signal GT0_TX_MMCM_LOCK_OUT, GT0_RX_MMCM_LOCK_OUT : std_logic;

    signal gt0_drpdo_i, gt0_drpdi_i : std_logic_vector (15 downto 0);
    signal gt0_drpaddr_i : std_logic_vector (8 downto 0);
    signal gt0_drpen_i, gt0_drprdy_i, gt0_drpwe_i : std_logic;
        
begin

    RXUSRCLK2 <= RXUSRCLK2_INT;
    TXUSRCLK2 <= TXUSRCLK2_INT;
    
    RXUSRCLK2_2 <= RXUSRCLK2_INT;
    TXUSRCLK2_2 <= TXUSRCLK2_INT;
    
    RESETDONE <= RX_RESETDONE and TX_RESETDONE and RX_RESETDONE2 and TX_RESETDONE2 and TX_FSM_RESETDONE and RX_FSM_RESETDONE and TX_FSM_RESETDONE2 and RX_FSM_RESETDONE2;

    gtwizard_0_inst: gtwizard_0 port map(
        -- Transceiver clock input (160 MHz):
        Q0_CLK1_GTREFCLK_PAD_N_IN => REFCLK_MGT_N,
        Q0_CLK1_GTREFCLK_PAD_P_IN => REFCLK_MGT_P,
        -- System clock input (100 MHz):
        sysclk_in => SYSCLK_IN,
        -- Reference clock outputs:
        GT0_TXUSRCLK_OUT => TXUSRCLK, 
        GT0_TXUSRCLK2_OUT => TXUSRCLK2_INT,                 -- reference clock for gt0_txdata_in 
        GT0_RXUSRCLK_OUT => RXUSRCLK, 
        GT0_RXUSRCLK2_OUT => RXUSRCLK2_INT,                 -- reference clock for gt0_rxdata_out
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
        gt0_drpaddr_in => gt0_drpaddr_i,
        gt0_drpdi_in => gt0_drpdi_i,
        gt0_drpdo_out => gt0_drpdo_i,
        gt0_drpen_in => gt0_drpen_i,
        gt0_drpwe_in => gt0_drpwe_i,
        gt0_drprdy_out => gt0_drprdy_i,
        GT0_DATA_VALID_IN => '1',                        -- '1' (sets GT0_RX_FSM_RESET_DONE_OUT, no other influence)
        DONT_RESET_ON_DATA_ERROR_IN => '1',
        -- QPLL outputs to connect to second transceiver:        
        GT0_QPLLLOCK_OUT => GT0_QPLLLOCK_OUT,
        GT0_QPLLREFCLKLOST_OUT => GT0_QPLLREFCLKLOST_OUT,
        GT0_QPLLOUTCLK_OUT => GT0_QPLLOUTCLK_OUT,
        GT0_QPLLOUTREFCLK_OUT => GT0_QPLLOUTREFCLK_OUT,
        -- Other outputs to connect to second transceiver:        
        GT0_TX_MMCM_LOCK_OUT => GT0_TX_MMCM_LOCK_OUT,
        GT0_RX_MMCM_LOCK_OUT => GT0_RX_MMCM_LOCK_OUT
    );

    gtwizard_1_inst: gtwizard_1 port map (
        SYSCLK_IN => SYSCLK_IN,
        SOFT_RESET_TX_IN => RESET_IN,
        SOFT_RESET_RX_IN => RESET_IN,
        DONT_RESET_ON_DATA_ERROR_IN => '1',
        GT0_TX_FSM_RESET_DONE_OUT => TX_FSM_RESETDONE2,
        GT0_RX_FSM_RESET_DONE_OUT => RX_FSM_RESETDONE2,
        GT0_DATA_VALID_IN => '1',                        -- '1' (sets GT0_RX_FSM_RESET_DONE_OUT, no other influence)
        GT0_TX_MMCM_LOCK_IN => GT0_TX_MMCM_LOCK_OUT,
        --GT0_TX_MMCM_RESET_OUT => ,
        GT0_RX_MMCM_LOCK_IN => GT0_RX_MMCM_LOCK_OUT,
        --GT0_RX_MMCM_RESET_OUT => ,
        --GT0  (X1Y0)--------------- Channel - DRP Ports  --------------------------
        gt0_drpaddr_in => B"000000000",
        gt0_drpclk_in => '0',
        gt0_drpdi_in => B"0000000000000000",
        gt0_drpen_in => '0',
        gt0_drpwe_in => '0',
        --------------------- RX Initialization and Reset Ports --------------------
        gt0_eyescanreset_in => RESET_IN,
        gt0_rxuserrdy_in => '1',                        -- (seems to have no influence)
        -------------------------- RX Margin Analysis Ports ------------------------
        gt0_eyescantrigger_in => '0',
        ------------------ Receive Ports - FPGA RX Interface Ports -----------------
        gt0_rxusrclk_in => RXUSRCLK,
        gt0_rxusrclk2_in => RXUSRCLK2_INT,
        ------------------ Receive Ports - FPGA RX interface Ports -----------------
        gt0_rxdata_out => RXDATA_2,
        --------------------------- Receive Ports - RX AFE -------------------------
        gt0_gtxrxp_in => RX_P_2,
        gt0_gtxrxn_in => RX_N_2,
        --------------------- Receive Ports - RX Equalizer Ports -------------------
        gt0_rxdfelpmreset_in => '0',
        gt0_rxmonitorsel_in => B"00",
        --------------- Receive Ports - RX Fabric Output Control Ports -------------
        --gt0_rxoutclkfabric_out => RXUSRCLK2_2,
        ------------- Receive Ports - RX Initialization and Reset Ports ------------
        gt0_gtrxreset_in => '0',                        -- (seems to have no influence)
        gt0_rxpmareset_in => RESET_IN,                  -- (a kind of reset function)
        -------------- Receive Ports -RX Initialization and Reset Ports ------------
        gt0_rxresetdone_out => RX_RESETDONE2,
        --------------------- TX Initialization and Reset Ports --------------------
        gt0_gttxreset_in => '0',                        -- (seems to have no influence)
        gt0_txuserrdy_in => '1',                        -- (seems to have no influence)
        ------------------ Transmit Ports - FPGA TX Interface Ports ----------------
        gt0_txusrclk_in => TXUSRCLK,
        gt0_txusrclk2_in => TXUSRCLK2_INT,
        ------------------ Transmit Ports - TX Data Path interface -----------------
        gt0_txdata_in => TXDATA_2,
        ---------------- Transmit Ports - TX Driver and OOB signaling --------------
        gt0_gtxtxn_out => TX_N_2,
        gt0_gtxtxp_out => TX_P_2,
        ----------- Transmit Ports - TX Fabric Clock Output Control Ports ----------
        ----gt0_txoutclk_out => TXUSRCLK2_2,
        --gt0_txoutclkfabric_out => TXUSRCLK2_2,
        ------------- Transmit Ports - TX Initialization and Reset Ports -----------
        gt0_txresetdone_out => TX_RESETDONE2,
        --____________________________COMMON PORTS________________________________
        GT0_QPLLLOCK_IN => GT0_QPLLLOCK_OUT,
        GT0_QPLLREFCLKLOST_IN => GT0_QPLLREFCLKLOST_OUT,
        --GT0_QPLLRESET_OUT => ,
        GT0_QPLLOUTCLK_IN => GT0_QPLLOUTCLK_OUT,
        GT0_QPLLOUTREFCLK_IN => GT0_QPLLOUTREFCLK_OUT
    );

    eyeScan_inst: eyeScan port map (
        CLK => SYSCLK_IN,
        SOFRST => RESET_IN,
        DRPDO => gt0_drpdo_i,
        DRPRDY => gt0_drprdy_i,
        DRPADDR => gt0_drpaddr_i,
        DRPWE => gt0_drpwe_i,
        DRPEN => gt0_drpen_i,
        DRPDI => gt0_drpdi_i,
        RunScan => RunScan,
        ScanComplete => ScanComplete,
        GetData_eye_req => GetData_eye_req,
        GetData_eye_rdy => GetData_eye_rdy,
        GetData_eye_nxt => GetData_eye_nxt,
        GetData_eye_cmplt => GetData_eye_cmplt,
        Max_Prescale => Max_Prescale,
        GetData_eye_vertical => GetData_eye_vertical,
        GetData_eye_horizontal => GetData_eye_horizontal,
        GetData_eye_samples => GetData_eye_samples,
        GetData_eye_errors => GetData_eye_errors
    );

end Behavioral;

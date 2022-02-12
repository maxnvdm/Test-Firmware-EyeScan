----------------------------------------------------------------------------------
-- Company: DESY 
-- Engineer: Artur Boebel
-- 
-- Create Date: 04/06/2019
-- Description: ATLAS EoS test firmware. To use with KC705 Kintex-7 FPGA development board.  
-- Needs a stable 160 MHz Source at MGT_CLK in (J15 / J16 Differential)  
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

--use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VComponents.all;

entity LPGBT_BERTEST_KC705 is
    Port ( clk_in_p : in STD_LOGIC;                             -- 200 MHz system clock input pair
           clk_in_n : in STD_LOGIC;
           refclk_mgt_p : in STD_LOGIC;                         -- 160 MHz reference clock input pair (external, J15 / J16)
           refclk_mgt_n : in STD_LOGIC;

           btn_reset : in STD_LOGIC;                            -- Reset input for GTX receiver (usually not needed)

           uart_rx : in STD_LOGIC;                              -- UART input
           uart_tx : out STD_LOGIC;                             -- UART output

           SCL0 : inout STD_LOGIC;                               -- I2C SCL 0
           SDA0 : inout STD_LOGIC;                               -- I2C SDA 0
           SCL1 : inout STD_LOGIC;                               -- I2C SCL 1
           SDA1 : inout STD_LOGIC;                               -- I2C SDA 1

           led : out STD_LOGIC_VECTOR (7 downto 0);             -- LED status display output

           LCD_E : out STD_LOGIC;                               -- LCD control outputs
           LCD_RW : out STD_LOGIC;                              
           LCD_RS : out STD_LOGIC;                              
           LCD_DB : out STD_LOGIC_VECTOR(3 downto 0);           -- LCD data outputs

           UPLINK1_OUT_P : out STD_LOGIC_VECTOR(14 downto 0);   -- 14 out of 15 uplink ELink #1 output pairs
           UPLINK1_OUT_N : out STD_LOGIC_VECTOR(14 downto 0);
           UPLINK2_OUT_P : out STD_LOGIC_VECTOR(15 downto 0);   -- 14 out of 16 uplink ELink #2 output pairs
           UPLINK2_OUT_N : out STD_LOGIC_VECTOR(15 downto 0);
           DOWNLINK_IN_P : in STD_LOGIC_VECTOR(10 downto 0);     -- 8 out of 11 downlink ELink input pairs
           DOWNLINK_IN_N : in STD_LOGIC_VECTOR(10 downto 0);
           BCLK_IN_P : in STD_LOGIC_VECTOR(3 downto 0);         -- 4 lpGBT clocking input pairs
           BCLK_IN_N : in STD_LOGIC_VECTOR(3 downto 0);
           EC_OUT_P : out STD_LOGIC;                            -- EC (AMAC) output pair
           EC_OUT_N : out STD_LOGIC;
           EC_IN_P : in STD_LOGIC;                              -- EC (AMAC) input pair
           EC_IN_N : in STD_LOGIC;

           SFP_RX_P_1 : in STD_LOGIC;                           -- Gigabit transceiver input pair (uplink #1)
           SFP_RX_N_1 : in STD_LOGIC;
           SFP_TX_P_1 : out STD_LOGIC;                          -- Gigabit transceiver output pair (downlink)
           SFP_TX_N_1 : out STD_LOGIC;
           SFP_RX_P_2 : in STD_LOGIC;                           -- Gigabit transceiver input pair (uplink #2)
           SFP_RX_N_2 : in STD_LOGIC;
           SFP_TX_P_2 : out STD_LOGIC;                          -- not used
           SFP_TX_N_2 : out STD_LOGIC;

           USER_SMA_CLOCK_P : out STD_LOGIC;                    -- 160 MHz clock output (external, J11 / J12, can be used for reference clock input)
           USER_SMA_CLOCK_N : out STD_LOGIC;
           USER_SMA_GPIO_P : out STD_LOGIC;                     -- 160 MHz clock output (external, J13 / J14)
           USER_SMA_GPIO_N : out STD_LOGIC;

           GPIO : inout STD_LOGIC_VECTOR(15 downto 0);          -- Multi purpose 16 bit GPIO 

           tx_disable : out STD_LOGIC;                          -- Disable input for gigabit transceiver #1: is set to GND
           tx_disable_2 : out STD_LOGIC);                       -- Disable input for gigabit transceiver #2: is set to GND 
end LPGBT_BERTEST_KC705;

architecture Behavioral of LPGBT_BERTEST_KC705 is

    constant CDIV : integer := 100000000 / 921600;   -- Baud rate divisor for UART: Clock is 100 MHz, use 921.6kbd (max. 3Mbd allowed).

    -- Clocking wizard components:
    component clk_wiz_4 port (clk_in1_p : IN STD_LOGIC; clk_in1_n : IN STD_LOGIC; clk_out1 : OUT STD_LOGIC; clk_out2 : OUT STD_LOGIC; clk_out3 : OUT STD_LOGIC ); end component;
    component clk_wiz_1 port (clk_in1 : IN STD_LOGIC; clk_out1 : OUT STD_LOGIC; clk_out2 : OUT STD_LOGIC); end component;
    component clk_wiz_5 port (clk_in1 : IN STD_LOGIC; clk_out1 : OUT STD_LOGIC; clk_out2 : OUT STD_LOGIC); end component;

    -- SelectIO components:
    component selectio_wiz_0 port(
        data_out_from_device : in STD_LOGIC_VECTOR(119 downto 0);
        data_out_to_pins_p : out STD_LOGIC_VECTOR(14 downto 0);
        data_out_to_pins_n : out STD_LOGIC_VECTOR(14 downto 0);
        clk_in : in STD_LOGIC;
        clk_div_in : in STD_LOGIC;
        io_reset : in STD_LOGIC
    ); end component;
    component selectio_wiz_1 port(
        data_out_from_device : in STD_LOGIC_VECTOR(127 downto 0);
        data_out_to_pins_p : out STD_LOGIC_VECTOR(15 downto 0);
        data_out_to_pins_n : out STD_LOGIC_VECTOR(15 downto 0);
        clk_in : in STD_LOGIC;
        clk_div_in : in STD_LOGIC;
        io_reset : in STD_LOGIC
    ); end component;
    component selectio_wiz_5 port (
        data_in_from_pins_p : in STD_LOGIC_VECTOR(10 downto 0);
        data_in_from_pins_n : in STD_LOGIC_VECTOR(10 downto 0);
        data_in_to_device : out STD_LOGIC_VECTOR(43 downto 0);
        bitslip : in STD_LOGIC_VECTOR(10 downto 0);
        clk_in : in STD_LOGIC;
        clk_div_in : in STD_LOGIC;
        io_reset : in STD_LOGIC
    ); end component;

    -- Clocks and counters:
    signal clk160, clk100, clk400 : std_logic;
    signal cntrclksys : std_logic_vector (15 downto 0) := X"FFFF";

    -- Data transceiver clocks:
    signal uplink1Clk160 : std_logic;   -- 160 MHz from Uplink #1 10G receiver
    signal uplink1Clk320 : std_logic;   -- 320 MHz synchronous to Uplink #1
    signal uplink1Clk80 : std_logic;    -- 80 MHz synchronous to Uplink #1
    signal uplink1Clk_en : std_logic;   -- Uplink #1 data enable flag
    signal uplink2Clk160 : std_logic;   -- 160 MHz from Uplink #2 10G receiver
    signal uplink2Clk320 : std_logic;   -- 320 MHz synchronous to Uplink #2
    signal uplink2Clk80 : std_logic;    -- 80 MHz synchronous to Uplink #2
    signal uplink2Clk_en : std_logic;   -- Uplink #2 data enable flag
    signal downlinkClk160 : std_logic;  -- 160 MHz from Downlink transmitter
    signal downlinkClk320 : std_logic;   -- 320 MHz synchronous to Downlink
    signal downlinkClk160_2 : std_logic; -- 160 MHz synchronous to Downlink
    signal downlinkClk_en : std_logic;  -- Downlink data request flag

    -- Data transceiver unit:
    signal RESET_IN : std_logic := '1';
    signal downlinkUserData : std_logic_vector (31 downto 0);
    signal downlinkEcData : std_logic_vector (1 downto 0);
    signal downlinkIcData : std_logic_vector (1 downto 0);
    signal uplink1Data : std_logic_vector (233 downto 0);
    signal uplink2Data : std_logic_vector (233 downto 0);
    signal aligned1, CRC1Ok : std_logic;
    signal aligned2, CRC2Ok : std_logic;
    signal BypassFEC1 : std_logic;
    signal BypassFEC2 : std_logic;
    signal cntrclkout : std_logic_vector (23 downto 0) := X"000000";

    signal align_limit_valid : STD_LOGIC_VECTOR (7 downto 0) := X"3F";      -- Debug. Nominal Value: 63
    signal align_limit_revalid : STD_LOGIC_VECTOR (7 downto 0) := X"0F";    -- Debug. Nominal Value: 15
    signal align_limit_invalid : STD_LOGIC_VECTOR (3 downto 0) := X"3";     -- Debug. Nominal Value: 3
    signal align_hdr_pos : STD_LOGIC_VECTOR (255 downto 0);                 -- Debug.

    --Elink unit (uplink #1):
    signal Elink1_PatGen_on : std_logic_vector (13 downto 0);
    signal Elink1_SynGen_on : std_logic_vector (13 downto 0);
    signal Elink1_inv : std_logic_vector (13 downto 0);
    signal Elink1_bit_shift : std_logic_vector (83 downto 0);
    signal Elink1_pat_out : std_logic_vector (223 downto 0);
    signal Elink1_selio_out : std_logic_vector (127 downto 0);
    signal Elink1_selio_out15 : std_logic_vector (119 downto 0);

    --Bit error counter unit #1:
    signal BErr1_BErrCnt : STD_LOGIC_VECTOR (223 downto 0);
    signal BErr1_PktLast15 : STD_LOGIC_VECTOR (55 downto 0);
    signal BErr1_CRCErrCnt : STD_LOGIC_VECTOR (15 downto 0);
    signal BErr1_AliErrCnt : STD_LOGIC_VECTOR (15 downto 0);
    signal Berr1_uplinkStatus : STD_LOGIC_VECTOR (1 downto 0);
    signal BErr1_rdy: STD_LOGIC;

    --Elink unit (uplink #2):
    signal Elink2_PatGen_on : std_logic_vector (13 downto 0);
    signal Elink2_SynGen_on : std_logic_vector (13 downto 0);
    signal Elink2_inv : std_logic_vector (13 downto 0);
    signal Elink2_bit_shift : std_logic_vector (83 downto 0);
    signal Elink2_pat_out : std_logic_vector (223 downto 0);
    signal Elink2_selio_out : std_logic_vector (127 downto 0);

    --Bit error counter unit #2:
    signal BErr2_BErrCnt : STD_LOGIC_VECTOR (223 downto 0);
    signal BErr2_PktLast15 : STD_LOGIC_VECTOR (55 downto 0);
    signal BErr2_CRCErrCnt : STD_LOGIC_VECTOR (15 downto 0);
    signal BErr2_AliErrCnt : STD_LOGIC_VECTOR (15 downto 0);
    signal Berr2_uplinkStatus : STD_LOGIC_VECTOR (1 downto 0);
    signal BErr2_rdy: STD_LOGIC;

    --Elink unit (downlink):
    signal Elink_dwn_PatGen_on : std_logic_vector (7 downto 0);
    signal Elink_dwn_SynGen_on : std_logic_vector (7 downto 0);
    signal Elink_dwn_inv : std_logic_vector (7 downto 0);
    signal Elink_dwn_bit_shift : std_logic_vector (47 downto 0);
    signal Elink_dwn_phase : std_logic_vector (15 downto 0);
    signal Elink_dwn_cmp_out : std_logic_vector (31 downto 0);
    signal Elink_dwn_rec_out : std_logic_vector (31 downto 0);
    signal Elink_dwn_selio_in : std_logic_vector (43 downto 0);

    --Bit error counter unit for downlink:
    signal BErrD_PktNumCnt : STD_LOGIC_VECTOR (47 downto 0);
    signal BErrD_BErrCnt : STD_LOGIC_VECTOR (127 downto 0);
    signal BErrD_PktLast15 : STD_LOGIC_VECTOR (31 downto 0);
    signal BErrD_rdy: STD_LOGIC;

    --Unit and bit error counter for EC:
    signal EC_PatGen_on_up : STD_LOGIC;
    signal EC_SynGen_on_up : STD_LOGIC;
    signal EC_Inv_on_up : STD_LOGIC;
    signal EC_Bit_shift_up : STD_LOGIC_VECTOR (5 downto 0);
    signal EC_PatGen_on_dwn : STD_LOGIC;
    signal EC_SynGen_on_dwn : STD_LOGIC;
    signal EC_Inv_on_dwn : STD_LOGIC;
    signal EC_Bit_shift_dwn : STD_LOGIC_VECTOR (5 downto 0);
    signal EC_Phase_dwn : STD_LOGIC_VECTOR (1 downto 0);
    signal EC_BErr_BErrCnt : STD_LOGIC_VECTOR (31 downto 0);
    signal EC_BErr_PktLast15 : STD_LOGIC_VECTOR (7 downto 0);
    signal EC_BErr_rdy: STD_LOGIC;

    -- Serial link configuration unit:
    signal ICC_Interface_in : STD_LOGIC_VECTOR (44 downto 0);
    signal ICC_Din_clk: STD_LOGIC;
    signal ICC_Dout: STD_LOGIC_VECTOR (7 downto 0);
    signal ICC_Dout_clk: STD_LOGIC;
    signal ICC_busy: STD_LOGIC;
    signal ICC_rx_valid: STD_LOGIC;

    -- GetData unit:
    signal GetData_LinkNumber: STD_LOGIC_VECTOR (3 downto 0);
    signal GetData_Get1 : STD_LOGIC;                            -- Uplink #1
    signal GetData_Rdy1 : STD_LOGIC;
    signal GetData_Dat1 : STD_LOGIC_VECTOR (127 downto 0);
    signal GetData_Pat1 : STD_LOGIC_VECTOR (127 downto 0);
    signal GetData_Get2 : STD_LOGIC;                            -- Uplink #2
    signal GetData_Rdy2 : STD_LOGIC;
    signal GetData_Dat2 : STD_LOGIC_VECTOR (127 downto 0);
    signal GetData_Pat2 : STD_LOGIC_VECTOR (127 downto 0);
    signal GetData_GetD : STD_LOGIC;                            -- Downlink
    signal GetData_RdyD : STD_LOGIC;
    signal GetData_DatD : STD_LOGIC_VECTOR (127 downto 0);
    signal GetData_PatD : STD_LOGIC_VECTOR (127 downto 0);
    signal GetData_GetC : STD_LOGIC;                            -- Clocks
    signal GetData_RdyC : STD_LOGIC;
    signal GetData_DatC : STD_LOGIC_VECTOR (255 downto 0);
    signal GetData_GetR : STD_LOGIC;                            -- RawData
    signal GetData_RdyR : STD_LOGIC;
    signal GetData_DatR : STD_LOGIC_VECTOR (255 downto 0);
    signal GetData_GetE : STD_LOGIC;                            -- EC
    signal GetData_RdyE : STD_LOGIC;
    signal GetData_DatE : STD_LOGIC_VECTOR (127 downto 0);
    signal GetData_PatE : STD_LOGIC_VECTOR (127 downto 0);
    signal DataUnlock : std_logic_vector (4 downto 0) := B"00000";
    signal DataLock_status : std_logic_vector (4 downto 0);

    -- ELink Matrix and Invert unit:
    signal Matrix_ELink1_Inv : STD_LOGIC_VECTOR (13 downto 0);   -- 14 bit: ELink1 inverter
    signal Matrix_ELink1_Mat : STD_LOGIC_VECTOR (55 downto 0);   -- 14 x 4 bit: ELink1 selector for multiplexing
    signal Matrix_ELink2_Inv : STD_LOGIC_VECTOR (13 downto 0);   -- 14 bit: ELink1 inverter
    signal Matrix_ELink2_Mat : STD_LOGIC_VECTOR (55 downto 0);   -- 14 x 4 bit: ELink1 selector for multiplexing
    signal Matrix_ELinkD_Inv : STD_LOGIC_VECTOR (7 downto 0);    -- 8 bit: ELink Downlink inverter
    signal Matrix_ELinkD_Mat : STD_LOGIC_VECTOR (31 downto 0);   -- 8 x 4 bit: ELink Downlink selector for multiplexing

    -- Sync Patterns for ELink / EC units:
    signal SyncPattern_UL1 : std_logic_vector (63 downto 0);
    signal SyncPattern_UL2 : std_logic_vector (63 downto 0);
    signal SyncPattern_DL  : std_logic_vector (63 downto 0);
    signal SyncPattern_EC  : std_logic_vector (63 downto 0);

    -- Command receive unit:
    signal cmd_received: STD_LOGIC := '0';
    signal cmd_rxenable : STD_LOGIC := '1';
    signal cmd_paraclk : STD_LOGIC := '0';
    signal cmd_word : STD_LOGIC_VECTOR(15 downto 0);
    signal cmd_bytenum : STD_LOGIC_VECTOR(15 downto 0);
    signal cmd_parabyte : STD_LOGIC_VECTOR(7 downto 0);

    -- Command timestamp unit:
    signal cmd_cnt100: STD_LOGIC_VECTOR(6 downto 0) := B"0000000";
    signal cmd_timer: STD_LOGIC_VECTOR(47 downto 0) := X"000000000000";
    signal cmd_fifo_pos : STD_LOGIC_VECTOR(3 downto 0) := X"0";
    signal cmd_word_fifo : STD_LOGIC_VECTOR(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    signal cmd_timestamp_fifo : STD_LOGIC_VECTOR(767 downto 0) := X"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";

    --- EyeScan module:
    signal RunScan, ScanComplete, GetData_eye_req, GetData_eye_rdy, GetData_eye_nxt, GetData_eye_cmplt : std_logic; -- EyeScan control signals
    signal Max_Prescale : std_logic_vector (4 downto 0);    -- EyeScan config parameter
    signal GetData_eye_vertical, GetData_eye_horizontal, GetData_eye_samples, GetData_eye_errors : std_logic_vector(991 downto 0);  -- 62 x 16 bit: Data output from EyeScan module

    -- Some Flags:
    signal BErrRun : STD_LOGIC;
    signal LinkReset : STD_LOGIC;
    signal INVERT_DL : std_logic;
    signal INVERT_UL1 : std_logic;
    signal INVERT_UL2 : std_logic;

    -- Response transmit unit:
    signal tx_busy, uart_tx_b: STD_LOGIC;
    signal datatxcmdbus: STD_LOGIC_VECTOR (9 downto 0) := B"0000000000";    -- combined bus: ( SEND & ByteClk & Data(7 downto 0) )

    -- Main unit:
    signal GetDeviceName, GetStatus, GetDataPattern, GetSettings, SetFlags, SetELink1, SetELink2, SetDownELink, SetEC, DoSerialConfigM1, DoSerialConfigM2, I2CWriteData0, I2CReadData0, I2CWriteData1, I2CReadData1, ReadWriteGPIO, SetELinkMatrix, SetSyncPattern, AlignerDebug, GetCmdTimestamps, EyeScanStatus, GetEyeScanData: STD_LOGIC := '0';

    signal datatxcmdbus_GetDeviceName: STD_LOGIC_VECTOR (9 downto 0);
    signal datatxcmdbus_GetStatus: STD_LOGIC_VECTOR (9 downto 0);
    signal datatxcmdbus_GetDataPattern: STD_LOGIC_VECTOR (9 downto 0);
    signal datatxcmdbus_GetSettings: STD_LOGIC_VECTOR (9 downto 0);
    signal datatxcmdbus_SetFlags: STD_LOGIC_VECTOR (9 downto 0);
    signal datatxcmdbus_SetELink1: STD_LOGIC_VECTOR (9 downto 0);
    signal datatxcmdbus_SetELink2: STD_LOGIC_VECTOR (9 downto 0);
    signal datatxcmdbus_SetDownELink: STD_LOGIC_VECTOR (9 downto 0);
    signal datatxcmdbus_SetEC: STD_LOGIC_VECTOR (9 downto 0);
    signal datatxcmdbus_DoSerialConfigM1: STD_LOGIC_VECTOR (9 downto 0);
    signal datatxcmdbus_DoSerialConfigM2: STD_LOGIC_VECTOR (9 downto 0);
    signal datatxcmdbus_I2CData0: STD_LOGIC_VECTOR (9 downto 0);
    signal datatxcmdbus_I2CData1: STD_LOGIC_VECTOR (9 downto 0);
    signal datatxcmdbus_ReadWriteGPIO: STD_LOGIC_VECTOR (9 downto 0);
    signal datatxcmdbus_SetELinkMatrix: STD_LOGIC_VECTOR (9 downto 0);
    signal datatxcmdbus_SetSyncPattern: STD_LOGIC_VECTOR (9 downto 0);
    signal datatxcmdbus_AlignerDebug: STD_LOGIC_VECTOR (9 downto 0);
    signal datatxcmdbus_GetCmdTimestamps: STD_LOGIC_VECTOR (9 downto 0);
    signal datatxcmdbus_EyeScanStatus: STD_LOGIC_VECTOR (9 downto 0);
    signal datatxcmdbus_GetEyeScanData: STD_LOGIC_VECTOR (9 downto 0);

    signal cmd_paraclk_GetDataPattern: STD_LOGIC := '0';
    signal cmd_paraclk_SetFlags: STD_LOGIC := '0';
    signal cmd_paraclk_SetELink1: STD_LOGIC := '0';
    signal cmd_paraclk_SetELink2: STD_LOGIC := '0';
    signal cmd_paraclk_SetDownELink: STD_LOGIC := '0';
    signal cmd_paraclk_SetEC: STD_LOGIC := '0';
    signal cmd_paraclk_DoSerialConfigM1: STD_LOGIC := '0';
    signal cmd_paraclk_DoSerialConfigM2: STD_LOGIC := '0';
    signal cmd_paraclk_I2CData0: STD_LOGIC := '0';
    signal cmd_paraclk_I2CData1: STD_LOGIC := '0';
    signal cmd_paraclk_ReadWriteGPIO: STD_LOGIC := '0';
    signal cmd_paraclk_SetELinkMatrix: STD_LOGIC := '0';
    signal cmd_paraclk_SetSyncPattern: STD_LOGIC := '0';
    signal cmd_paraclk_AlignerDebug: STD_LOGIC := '0';
    signal cmd_paraclk_EyeScanStatus: STD_LOGIC := '0';

    signal ICC_Interface_ConfigM1 : STD_LOGIC_VECTOR (44 downto 0);
    signal ICC_Interface_ConfigM2 : STD_LOGIC_VECTOR (44 downto 0);
    signal ICC_Interface_lpGBT_I2C_MasterNr : STD_LOGIC_VECTOR (1 downto 0);

    signal cmd_received_old, tx_busy_old: STD_LOGIC := '0';

begin

    -- Create and connect clocks: 160, 100 and 400 MHz:
    clk_wiz_4_inst: clk_wiz_4 port map(
        clk_in1_p => clk_in_p,
        clk_in1_n => clk_in_n,
        clk_out1 => clk160,
        clk_out2 => clk100,
        clk_out3 => clk400
    );

    -- Create and connect clocks: 320 MHz, 80 MHz and synchronous 160 MHz from 160 MHz input clock:
    clk_wiz_1_inst : clk_wiz_1 port map(clk_in1 => uplink1Clk160, clk_out1 => uplink1Clk320, clk_out2 => uplink1Clk80);
    clk_wiz_2_inst : clk_wiz_1 port map(clk_in1 => uplink2Clk160, clk_out1 => uplink2Clk320, clk_out2 => uplink2Clk80);
    clk_wiz_5_inst : clk_wiz_5 port map(clk_in1 => downlinkClk160, clk_out1 => downlinkClk320, clk_out2 => downlinkClk160_2);

    obufds_inst: OBUFDS port map(O => USER_SMA_CLOCK_P, OB => USER_SMA_CLOCK_N, I => clk160); -- differential output for 160 MHz clock.
    obufds_inst2: OBUFDS port map(O => USER_SMA_GPIO_P, OB => USER_SMA_GPIO_N, I => clk160); -- second differential output for 160 MHz clock.

    -- Handle Link reset:
    process (clk100) begin
    if rising_edge(clk100) then
        if cntrclksys = 0 then
            RESET_IN <= btn_reset or LinkReset;
        end if;
        cntrclksys <= cntrclksys - 1; 
    end if;
    end process;


    -- Data transceiver unit for optical high speed link (up- and downlink): 
    lpGBT_HighSpeedLink_inst: entity work.lpGBT_HighSpeedLink port map(
        sysclk_in => clk100,
        refclk_mgt_p => refclk_mgt_p,
        refclk_mgt_n => refclk_mgt_n,
        reset_in => RESET_IN,
        SFP_RX_P_1 => SFP_RX_P_1,
        SFP_RX_N_1 => SFP_RX_N_1,
        SFP_TX_P_1 => SFP_TX_P_1,
        SFP_TX_N_1 => SFP_TX_N_1,
        SFP_RX_P_2 => SFP_RX_P_2,
        SFP_RX_N_2 => SFP_RX_N_2,
        SFP_TX_P_2 => SFP_TX_P_2,
        SFP_TX_N_2 => SFP_TX_N_2,

        downlinkUserData => downlinkUserData,
        downlinkEcData => downlinkEcData,
        downlinkIcData => downlinkIcData,
        downlinkClk160_out => downlinkClk160,
        downlinkClk_en_out => downlinkClk_en,

        uplink1Data => uplink1Data,
        uplink1Clk160_out => uplink1Clk160,
        uplink1Clk_en_out => uplink1Clk_en,
        uplink1data_aligned => aligned1,
        uplink1data_CRCOK => CRC1Ok,
        uplink1data_bypassFEC => BypassFEC1,

        uplink2Data => uplink2Data,
        uplink2Clk160_out => uplink2Clk160,
        uplink2Clk_en_out => uplink2Clk_en,
        uplink2data_aligned => aligned2,
        uplink2data_CRCOK => CRC2Ok,
        uplink2data_bypassFEC => BypassFEC2,

        GetData_num => GetData_LinkNumber(1 downto 0),
        GetData_req => GetData_GetR,
        GetData_uplinkdata_raw => GetData_DatR,
        GetData_rdy => GetData_RdyR,
        uLData_locked_out => DataLock_status(1 downto 0),
        uLData_unlock => DataUnlock(1 downto 0),
        INVERT_DL => INVERT_DL,
        INVERT_UL1 => INVERT_UL1,
        INVERT_UL2 => INVERT_UL2,

        align_limit_valid => align_limit_valid,     -- Debug. Nominal Value: 63
        align_limit_revalid => align_limit_revalid, -- Debug. Nominal Value: 15
        align_limit_invalid => align_limit_invalid, -- Debug. Nominal Value: 3
        align_hdr_pos_out => align_hdr_pos,         -- Debug.

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

    tx_disable <= '0';      -- Enable SFP+ Transmitter #1
    tx_disable_2 <= '1';    -- Disable SFP+ Transmitter #2

    process (uplink1Clk160) begin
    if rising_edge(uplink1Clk160) then
        if uplink1Clk_en = '1' then
            cntrclkout <= cntrclkout + 1;  -- counter / divider for uplinkClk (just for blinking LED, indicates uplinkClk is running).
        end if;
    end if;
    end process;

    --Elink unit (uplink #1):
    lpGBT_ELink1_Unit_inst: entity work.lpGBT_ELink_Unit port map(
        clk160 => uplink1Clk160,
        clk320 => uplink1Clk320,
        clk80 => uplink1Clk80,
        clk_en => uplink1Clk_en,
        TestPatGen_on => Elink1_PatGen_on,
        SyncPatGen_on => Elink1_SynGen_on,
        SyncPattern => SyncPattern_UL1,
        HighInv_on => Elink1_inv,
        Bit_shift => Elink1_bit_shift,
        elink_inv => Matrix_ELink1_Inv,
        elink_sel => Matrix_ELink1_Mat,
        Pattern_out => Elink1_pat_out,
        data_selio_out => Elink1_selio_out
    );

    -- Elink1 uplink has just 15, not 16 possible output pairs:
    Elink1_selio_out15 <= Elink1_selio_out(126 downto 112) & Elink1_selio_out(110 downto 96) & Elink1_selio_out(94 downto 80) & Elink1_selio_out(78 downto 64) & Elink1_selio_out(62 downto 48) & Elink1_selio_out(46 downto 32) & Elink1_selio_out(30 downto 16) & Elink1_selio_out(14 downto 0);

    selectio_wiz_0_inst : selectio_wiz_0 port map(
        data_out_from_device => Elink1_selio_out15,
        data_out_to_pins_p => UPLINK1_OUT_P,
        data_out_to_pins_n => UPLINK1_OUT_N,
        clk_in => uplink1Clk320,
        clk_div_in => uplink1Clk80,
        io_reset => '0'
    );

    --Bit error counter #1:
    lpGBT_BitErrorCounter1_inst: entity work.lpGBT_BitErrorCounter port map(
        clk160 => uplink1Clk160,
        clk_en => uplink1Clk_en,
        run => BErrRun,
        On0 => Elink1_PatGen_on,
        On1 => Elink1_SynGen_on,
        DataCmp0 => Elink1_pat_out,
        DataCmp1 => uplink1Data(223 downto 0),
        Data_CRCOK => CRC1OK,
        Data_aligned => aligned1,
        GetBER_req => GetStatus,
        --PktNumCnt_out => BErr1_PktNumCnt,
        BErrCnt_out => BErr1_BErrCnt,
        PktLast15_out => BErr1_PktLast15,
        CRCErrCnt_out => BErr1_CRCErrCnt,
        AliErrCnt_out => BErr1_AliErrCnt,
        UplinkStatus_out => Berr1_uplinkStatus,
        GetBER_rdy => BErr1_rdy,
        GetData_LinkNumber => GetData_LinkNumber,
        GetData_req => GetData_Get1,
        GetData_D1 => GetData_Dat1,
        GetData_D2 => GetData_Pat1,
        GetData_rdy => GetData_Rdy1,
        uLData_locked_out => DataLock_status(2),
        uLData_unlock => DataUnlock(2)
    );

    --Elink unit (uplink #2):
    lpGBT_ELink2_Unit_inst: entity work.lpGBT_ELink_Unit port map(
        clk160 => uplink2Clk160,
        clk320 => uplink2Clk320,
        clk80 => uplink2Clk80,
        clk_en => uplink2Clk_en,
        TestPatGen_on => Elink2_PatGen_on,
        SyncPatGen_on => Elink2_SynGen_on,
        SyncPattern => SyncPattern_UL2,
        HighInv_on => Elink2_inv,
        Bit_shift => Elink2_bit_shift,
        elink_inv => Matrix_ELink2_Inv,
        elink_sel => Matrix_ELink2_Mat,
        Pattern_out => Elink2_pat_out,
        data_selio_out => Elink2_selio_out
    );

    selectio_wiz_1_inst : selectio_wiz_1 port map(
        data_out_from_device => Elink2_selio_out,
        data_out_to_pins_p => UPLINK2_OUT_P,
        data_out_to_pins_n => UPLINK2_OUT_N,
        clk_in => uplink2Clk320,
        clk_div_in => uplink2Clk80,
        io_reset => '0'
    );

    --Bit error counter #2:
    lpGBT_BitErrorCounter2_inst: entity work.lpGBT_BitErrorCounter port map(
        clk160 => uplink2Clk160,
        clk_en => uplink2Clk_en,
        run => BErrRun,
        On0 => Elink2_PatGen_on,
        On1 => Elink2_SynGen_on,
        DataCmp0 => Elink2_pat_out,
        DataCmp1 => uplink2Data(223 downto 0),
        Data_CRCOK => CRC2OK,
        Data_aligned => aligned2,
        GetBER_req => GetStatus,
        --PktNumCnt_out => BErr2_PktNumCnt,
        BErrCnt_out => BErr2_BErrCnt,
        PktLast15_out => BErr2_PktLast15,
        CRCErrCnt_out => BErr2_CRCErrCnt,
        AliErrCnt_out => BErr2_AliErrCnt,
        UplinkStatus_out => Berr2_uplinkStatus,
        GetBER_rdy => BErr2_rdy,
        GetData_LinkNumber => GetData_LinkNumber,
        GetData_req => GetData_Get2,
        GetData_D1 => GetData_Dat2,
        GetData_D2 => GetData_Pat2,
        GetData_rdy => GetData_Rdy2,
        uLData_locked_out => DataLock_status(3),
        uLData_unlock => DataUnlock(3)
    );
    
    --Elink unit (downlink):
    lpGBT_ELink_Downlink_inst: entity work.lpGBT_ELink_Downlink port map(
        clk160 => downlinkClk160,
        clk320 => downlinkClk320,
        clk160_2 => downlinkClk160_2,
        clk_en => downlinkClk_en,
        TestPatGen_on => Elink_dwn_PatGen_on,
        SyncPatGen_on => Elink_dwn_SynGen_on,
        SyncPattern => SyncPattern_DL,
        HighInv_on => Elink_dwn_inv,
        Bit_shift => Elink_dwn_bit_shift,
        Phase_track => Elink_dwn_phase,
        elink_inv => Matrix_ELinkD_Inv,
        elink_sel => Matrix_ELinkD_Mat,
        Pattern_out => downlinkUserData,
        Compare_out => Elink_dwn_cmp_out,
        Received_out => Elink_dwn_rec_out,
        data_selio_in => Elink_dwn_selio_in
    );

    selectio_wiz_5_inst : selectio_wiz_5 port map(
        data_in_from_pins_p => DOWNLINK_IN_P,
        data_in_from_pins_n => DOWNLINK_IN_N,
        data_in_to_device => Elink_dwn_selio_in,
        bitslip => B"00000000000",
        clk_in => downlinkClk320,
        clk_div_in => downlinkClk160_2,
        io_reset => '0'
    );

    --Bit error counter for downlink:
    lpGBT_DownlinkBitErrorCount_inst: entity work.lpGBT_DownlinkBitErrorCount port map(
        clk160 => downlinkClk160,
        clk_en => downlinkClk_en,
        run => BErrRun,
        On0 => Elink_dwn_PatGen_on,
        On1 => Elink_dwn_SynGen_on,
        DataCmp0 => Elink_dwn_cmp_out,
        DataCmp1 => Elink_dwn_rec_out,
        GetBER_req => GetStatus,
        PktNumCnt_out => BErrD_PktNumCnt,
        BErrCnt_out => BErrD_BErrCnt,
        PktLast15_out => BErrD_PktLast15,
        GetBER_rdy => BErrD_rdy,
        GetData_LinkNumber => GetData_LinkNumber,
        GetData_req => GetData_GetD,
        GetData_D1 => GetData_DatD,
        GetData_D2 => GetData_PatD,
        GetData_rdy => GetData_RdyD,
        dLData_locked_out => DataLock_status(4),
        dLData_unlock => DataUnlock(4)
    );

    --Unit and bit error counter for EC:
    lpGBT_EC_Unit_inst : entity work.lpGBT_EC_Unit port map(
        clk160_up => uplink1Clk160,
        clk_en_up => uplink1Clk_en,
        clk160_down => downlinkClk160,
        clk_en_dwn => downlinkClk_en,
        run => BErrRun,

        TestPatGen_on_up => EC_PatGen_on_up,
        SyncPatGen_on_up => EC_SynGen_on_up,
        SyncPattern => SyncPattern_EC,
        HighInv_on_up => EC_Inv_on_up,
        Bit_shift_up => EC_Bit_shift_up,
        ec_out_p => EC_OUT_P,
        ec_out_n => EC_OUT_N,
        Data_EC_up => uplink1Data(231 downto 230),
        Data_CRCOK => CRC1OK,
        Data_aligned => aligned1,

        TestPatGen_on_dwn => EC_PatGen_on_dwn,
        SyncPatGen_on_dwn => EC_SynGen_on_dwn,
        HighInv_on_dwn => EC_Inv_on_dwn,
        Bit_shift_dwn => EC_Bit_shift_dwn,
        Phase_track_dwn => EC_Phase_dwn,
        Data_EC_dwn_out => downlinkEcData,
        ec_in_p => EC_IN_P,
        ec_in_n => EC_IN_N,

        GetBER_req => GetStatus,
        BErrCnt_out => EC_BErr_BErrCnt,
        PktLast15_out => EC_BErr_PktLast15,
        GetBER_rdy => EC_BErr_rdy,
        GetData_LinkNumber => GetData_LinkNumber(0),
        GetData_req => GetData_GetE,
        GetData_D1 => GetData_DatE,
        GetData_D2 => GetData_PatE,
        GetData_rdy => GetData_RdyE
    );


    -- Unit for measuring the four lpGBT clock outputs: 
    lpGBT_ClockUnit_inst: entity work.lpGBT_ClockUnit port map(
        clk100 => clk100,
        clk400 => clk400,
        ClkMeas_in_p => BCLK_IN_P,
        ClkMeas_in_n => BCLK_IN_N,
        GetData_LinkNumber => GetData_LinkNumber,
        GetData_req => GetData_GetC,
        GetData_Data => GetData_DatC,
        GetData_rdy => GetData_RdyC
    );

    -- Serial link (IC) configuration unit:  
    lpGBT_ICConfig_inst: entity work.lpGBT_ICConfig port map(
        clk => clk100,
        Address_lpGBT => ICC_Interface_in(42 downto 36),
        data_num => ICC_Interface_in(35 downto 24),
        adr_in => ICC_Interface_in(15 downto 0),
        data_in => ICC_Interface_in(23 downto 16),
        data_in_clk_out => ICC_Din_clk,
        clk160_down => downlinkClk160,
        clk_en_dwn => downlinkClk_en,
        data_out => ICC_Dout,
        data_out_clk_out => ICC_Dout_clk,
        clk160_up => uplink1Clk160,
        clk_en_up => uplink1Clk_en,
        write => ICC_Interface_in(43),
        dosnd => ICC_Interface_in(44),
        busy_out => ICC_busy,
        rx_valid_out => ICC_rx_valid,
        ICData_down => downlinkIcData,
        ICData_up => uplink1Data(233 downto 232)
    );

    -- LCD interface:
    lpGBT_Statistic_on_LCD_inst: entity work.lpGBT_Statistic_on_LCD generic map (CLK_FREQ_MHZ_IN => 100) port map(
        clk => clk100,
        uplink1_clk160 => uplink1Clk160,
        uplink1_clk_en => uplink1Clk_en,
        uplink1_aligned => aligned1,
        uplink1_CRCOK => CRC1Ok,
        uplink1data_in => uplink1Data,
        uplink2_clk160 => uplink2Clk160,
        uplink2_clk_en => uplink2Clk_en,
        uplink2_aligned => aligned2,
        uplink2_CRCOK => CRC2Ok,
        uplink2data_in => uplink2Data,
        LCD_E => LCD_E,
        LCD_RW => LCD_RW,
        LCD_RS => LCD_RS,
        LCD_DB => LCD_DB
    );

    -- LED signaling: 
    led(7) <= cntrclkout(23);
    led(6) <= not uart_rx;
    led(5) <= not uart_tx_b;
    led(4) <= not cmd_rxenable;
    led(3) <= CRC2Ok;
    led(2) <= aligned2;
    led(1) <= CRC1Ok;
    led(0) <= aligned1;

    -- UART command receive unit:
    cmd_rx_inst: entity work.cmd_rx generic map (CDIV => CDIV, MHZ => 100, RAM_LEN => 512) port map (
        clk => clk100,
        clk_com => clk100,
        rxd => uart_rx,
        rxenable => cmd_rxenable,
        received_out => cmd_received,
        cmdword_out => cmd_word,
        bytenum_out => cmd_bytenum,
        parabyteclk_in => cmd_paraclk,
        parabyte_out => cmd_parabyte
    ); 

    -- UART response transmit unit:
    respond_tx_inst: entity work.respond_tx generic map(CDIV => CDIV, RAM_LEN => 512) port map (
        clk => clk100,
        clk_com => clk100,
        txd => uart_tx_b,
        dotx_in => datatxcmdbus(9),
        dataclk_in => datatxcmdbus(8),
        databyte_in => datatxcmdbus(7 downto 0),
        txbusy_out => tx_busy
    );


    -- Main unit:

    -- Process the received commands:
    process(clk100) begin
    if rising_edge(clk100) then
        if cmd_cnt100 = 0 then
            cmd_cnt100 <= B"1100011"; -- 99
            cmd_timer <= cmd_timer + 1;         -- Increment µs Timer
        else
            cmd_cnt100 <= cmd_cnt100 - 1;
        end if;
        if cmd_received = '1' and cmd_received_old = '0' then               -- New command received: set command flag:
            case cmd_word is
            when X"0001" => cmd_rxenable <= '0'; GetDeviceName <= '1';
            when X"0006" => cmd_rxenable <= '0'; GetStatus <= '1';
            when X"0007" => cmd_rxenable <= '0'; I2CWriteData0 <= '1';
            when X"000A" => cmd_rxenable <= '0'; I2CReadData0 <= '1';
            when X"0017" => cmd_rxenable <= '0'; I2CWriteData1 <= '1';
            when X"001A" => cmd_rxenable <= '0'; I2CReadData1 <= '1';
            when X"0019" => cmd_rxenable <= '0'; GetDataPattern <= '1';
            when X"0024" => cmd_rxenable <= '0'; GetSettings <= '1';
            when X"0033" => cmd_rxenable <= '0'; SetFlags <= '1';
            when X"000C" => cmd_rxenable <= '0'; SetELink1 <= '1';
            when X"0012" => cmd_rxenable <= '0'; SetELink2 <= '1';
            when X"0045" => cmd_rxenable <= '0'; SetDownELink <= '1';
            when X"0048" => cmd_rxenable <= '0'; SetEC <= '1';
            when X"002B" => cmd_rxenable <= '0'; DoSerialConfigM1 <= '1';
            when X"002C" => cmd_rxenable <= '0'; DoSerialConfigM2 <= '1'; ICC_Interface_lpGBT_I2C_MasterNr <= "00";
            when X"002D" => cmd_rxenable <= '0'; DoSerialConfigM2 <= '1'; ICC_Interface_lpGBT_I2C_MasterNr <= "01";
            when X"002E" => cmd_rxenable <= '0'; DoSerialConfigM2 <= '1'; ICC_Interface_lpGBT_I2C_MasterNr <= "10";
            when X"0052" => cmd_rxenable <= '0'; ReadWriteGPIO <= '1';
            when X"0057" => cmd_rxenable <= '0'; SetELinkMatrix <= '1';
            when X"005C" => cmd_rxenable <= '0'; SetSyncPattern <= '1';
            when X"0060" => cmd_rxenable <= '0'; AlignerDebug <= '1';
            when X"0066" => cmd_rxenable <= '0'; GetCmdTimestamps <= '1';
            when X"0071" => cmd_rxenable <= '0'; EyeScanStatus <= '1';
            when X"0074" => cmd_rxenable <= '0'; GetEyeScanData <= '1';
            when others =>
            end case;
            -- Save timestamp and command word:
            cmd_timestamp_fifo(conv_integer(cmd_fifo_pos)*48 + 47 downto conv_integer(cmd_fifo_pos)*48) <= cmd_timer;
            cmd_word_fifo(conv_integer(cmd_fifo_pos)*16 + 15 downto conv_integer(cmd_fifo_pos)*16) <= cmd_word;
            cmd_fifo_pos <= cmd_fifo_pos + 1;
        elsif tx_busy = '0' and tx_busy_old = '1' then                      -- Response transmission finished: reset all flags:
            cmd_rxenable <= '1';
            GetDeviceName <= '0';
            GetStatus <= '0';
            GetDataPattern <= '0';
            GetSettings <= '0';
            SetFlags <= '0';
            SetELink1 <= '0';
            SetELink2 <= '0';
            SetDownELink <= '0';
            SetEC <= '0';
            DoSerialConfigM1 <= '0';
            DoSerialConfigM2 <= '0';
            I2CWriteData0 <= '0';
            I2CReadData0 <= '0';
            I2CWriteData1 <= '0';
            I2CReadData1 <= '0';
            ReadWriteGPIO <= '0';
            SetELinkMatrix <= '0';
            SetSyncPattern <= '0';
            AlignerDebug <= '0';
            GetCmdTimestamps <= '0';
            EyeScanStatus <= '0';
            GetEyeScanData <= '0';
        end if;
        cmd_received_old <= cmd_received;
        tx_busy_old <= tx_busy;
    end if;
    end process;

    -- Connect specific module to the response unit, according to received command:
    datatxcmdbus <= datatxcmdbus_GetDeviceName    when GetDeviceName = '1'
               else datatxcmdbus_GetStatus        when GetStatus = '1'
               else datatxcmdbus_GetDataPattern   when GetDataPattern = '1'
               else datatxcmdbus_GetSettings      when GetSettings = '1'
               else datatxcmdbus_SetFlags         when SetFlags = '1'
               else datatxcmdbus_SetELink1        when SetELink1 = '1'
               else datatxcmdbus_SetELink2        when SetELink2 = '1'
               else datatxcmdbus_SetDownELink     when SetDownELink = '1'
               else datatxcmdbus_SetEC            when SetEC = '1'
               else datatxcmdbus_DoSerialConfigM1 when DoSerialConfigM1 = '1'
               else datatxcmdbus_DoSerialConfigM2 when DoSerialConfigM2 = '1'
               else datatxcmdbus_I2CData0         when I2CWriteData0 = '1' or I2CReadData0 = '1' 
               else datatxcmdbus_I2CData1         when I2CWriteData1 = '1' or I2CReadData1 = '1' 
               else datatxcmdbus_ReadWriteGPIO    when ReadWriteGPIO = '1'
               else datatxcmdbus_SetELinkMatrix   when SetELinkMatrix = '1'
               else datatxcmdbus_SetSyncPattern   when SetSyncPattern = '1'
               else datatxcmdbus_AlignerDebug     when AlignerDebug = '1'
               else datatxcmdbus_GetCmdTimestamps when GetCmdTimestamps = '1'
               else datatxcmdbus_EyeScanStatus    when EyeScanStatus = '1'
               else datatxcmdbus_GetEyeScanData   when GetEyeScanData = '1'
               else B"0000000000";

    -- Connect specific module to the parameter clock line, according to received command:
    cmd_paraclk <= cmd_paraclk_GetDataPattern   when GetDataPattern = '1'
              else cmd_paraclk_SetFlags         when SetFlags = '1'
              else cmd_paraclk_SetELink1        when SetELink1 = '1'
              else cmd_paraclk_SetELink2        when SetELink2 = '1'
              else cmd_paraclk_SetDownELink     when SetDownELink = '1'
              else cmd_paraclk_SetEC            when SetEC = '1'
              else cmd_paraclk_DoSerialConfigM1 when DoSerialConfigM1 = '1'
              else cmd_paraclk_DoSerialConfigM2 when DoSerialConfigM2 = '1'
              else cmd_paraclk_I2CData0         when I2CWriteData0 = '1' or I2CReadData0 = '1'
              else cmd_paraclk_I2CData1         when I2CWriteData1 = '1' or I2CReadData1 = '1'
              else cmd_paraclk_ReadWriteGPIO    when ReadWriteGPIO = '1'
              else cmd_paraclk_SetELinkMatrix   when SetELinkMatrix = '1'
              else cmd_paraclk_SetSyncPattern   when SetSyncPattern = '1'
              else cmd_paraclk_AlignerDebug     when AlignerDebug = '1'
              else cmd_paraclk_EyeScanStatus    when EyeScanStatus = '1'
              else '0';

    -- Connect the serial link (IC) configuration unit to specific module:
    ICC_Interface_in <= ICC_Interface_ConfigM1 when DoSerialConfigM1 = '1'
                   else ICC_Interface_ConfigM2 when DoSerialConfigM2 = '1'
                   else B"000000000000000000000000000000000000000000000";

    uart_tx <= uart_tx_b;


    -- Instatiate all the modules, which will process each one command: 

    lpGBT_GetDeviceName_inst: entity work.lpGBT_GetDeviceName port map(
        clk => clk100,
        start => GetDeviceName,
        datatxcmdbus => datatxcmdbus_GetDeviceName
    );

    lpGBT_GetStatus_inst: entity work.lpGBT_GetStatus port map(
        clk => clk100,
        start => GetStatus,
        datatxcmdbus => datatxcmdbus_GetStatus,
        PktNumCnt => BErrD_PktNumCnt,
        BErrCnt1 => BErr1_BErrCnt,
        BErrCnt2 => BErr2_BErrCnt,
        BErrCntDwn => BErrD_BErrCnt,
        BErrCntEC => EC_BErr_BErrCnt,
        CRCErr1 => BErr1_CRCErrCnt,
        AliErr1 => BErr1_AliErrCnt,
        CRCErr2 => BErr2_CRCErrCnt,
        AliErr2 => BErr2_AliErrCnt,
        PktLast15_1 => BErr1_PktLast15,
        PktLast15_2 => BErr2_PktLast15,
        PktLast15Dwn => BErrD_PktLast15,
        PktLast15EC => EC_BErr_PktLast15,
        BErr1_rdy => BErr1_rdy,
        BErr2_rdy => BErr2_rdy,
        BErrD_rdy => BErrD_rdy,
        BErrE_rdy => EC_BErr_rdy,
        uplink1Status => Berr1_uplinkStatus,
        uplink2Status => Berr2_uplinkStatus,
        BErrRun => BErrRun,
        BypassFEC1 => BypassFEC1,
        BypassFEC2 => BypassFEC2,
        DataLock_status => DataLock_status,
        LinkReset_status => RESET_IN,
        INVERT_DL_status => INVERT_DL,
        INVERT_UL1_status => INVERT_UL1,
        INVERT_UL2_status => INVERT_UL2
    );

    lpGBT_GetDataPattern_inst: entity work.lpGBT_GetDataPattern port map(
        clk => clk100,
        start => GetDataPattern,
        datatxcmdbus => datatxcmdbus_GetDataPattern,
        cmd_paraclk => cmd_paraclk_GetDataPattern, 
        cmd_parabyte => cmd_parabyte,
        link_number => GetData_LinkNumber,
        get1_out => GetData_Get1,
        get1_rdy => GetData_Rdy1,
        data_rec1 => GetData_Dat1,
        comp_pat1 => GetData_Pat1,
        get2_out => GetData_Get2,
        get2_rdy => GetData_Rdy2,
        data_rec2 => GetData_Dat2,
        comp_pat2 => GetData_Pat2,
        getD_out => GetData_GetD,
        getD_rdy => GetData_RdyD,
        data_rec_d => GetData_DatD,
        comp_pat_d => GetData_PatD,
        getC_out => GetData_GetC,
        getC_rdy => GetData_RdyC,
        data_clock => GetData_DatC,
        getR_out => GetData_GetR,
        getR_rdy => GetData_RdyR,
        data_raw => GetData_DatR,
        getE_out => GetData_GetE,
        getE_rdy => GetData_RdyE,
        data_rec_e => GetData_DatE,
        comp_pat_e => GetData_PatE
    );

    lpGBT_GetSettings_inst: entity work.lpGBT_GetSettings port map(
        clk => clk100,
        start => GetSettings,
        datatxcmdbus => datatxcmdbus_GetSettings,
        Elink1_PatGen_on => Elink1_PatGen_on,
        Elink1_SynGen_on => Elink1_SynGen_on,
        Elink1_inv => Elink1_inv,
        Elink1_bit_shift => Elink1_bit_shift,
        Elink2_PatGen_on => Elink2_PatGen_on,
        Elink2_SynGen_on => Elink2_SynGen_on,
        Elink2_inv => Elink2_inv,
        Elink2_bit_shift => Elink2_bit_shift,
        Elink_dwn_PatGen_on => Elink_dwn_PatGen_on,
        Elink_dwn_SynGen_on => Elink_dwn_SynGen_on,
        Elink_dwn_inv => Elink_dwn_inv,
        Elink_dwn_bit_shift => Elink_dwn_bit_shift,
        Elink_dwn_phase => Elink_dwn_phase,
        EC_PatGen_on_up => EC_PatGen_on_up,
        EC_SynGen_on_up => EC_SynGen_on_up,
        EC_inv_on_up => EC_inv_on_up,
        EC_bit_shift_up => EC_bit_shift_up,
        EC_PatGen_on_dwn => EC_PatGen_on_dwn,
        EC_SynGen_on_dwn => EC_SynGen_on_dwn,
        EC_inv_on_dwn => EC_inv_on_dwn,
        EC_bit_shift_dwn => EC_bit_shift_dwn,
        EC_phase_dwn => EC_phase_dwn
    );

    lpGBT_SetFlags_inst: entity work.lpGBT_SetFlags port map(
        clk => clk100,
        start => SetFlags,
        datatxcmdbus => datatxcmdbus_SetFlags,
        cmd_paraclk => cmd_paraclk_SetFlags, 
        cmd_parabyte => cmd_parabyte,
        RunBERT => BErrRun,
        BypassFEC1 => BypassFEC1,
        BypassFEC2 => BypassFEC2,
        DataUnlock_out => DataUnlock,
        DataLock_status => DataLock_status,
        LinkReset => LinkReset,
        INVERT_DL => INVERT_DL,
        INVERT_UL1 => INVERT_UL1,
        INVERT_UL2 => INVERT_UL2
    );

    lpGBT_SetElink1_inst: entity work.lpGBT_SetElinkData generic map (response => 12) port map(
        clk => clk100,
        start => SetElink1,
        datatxcmdbus => datatxcmdbus_SetElink1,
        cmd_paraclk => cmd_paraclk_SetElink1, 
        cmd_parabyte => cmd_parabyte,
        Elink_PatGen_on => Elink1_PatGen_on,
        Elink_SynGen_on => Elink1_SynGen_on,
        Elink_inv => Elink1_inv,
        Elink_bit_shift => Elink1_bit_shift
    );

    lpGBT_SetElink2_inst: entity work.lpGBT_SetElinkData generic map (response => 18) port map(
        clk => clk100,
        start => SetElink2,
        datatxcmdbus => datatxcmdbus_SetElink2,
        cmd_paraclk => cmd_paraclk_SetElink2, 
        cmd_parabyte => cmd_parabyte,
        Elink_PatGen_on => Elink2_PatGen_on,
        Elink_SynGen_on => Elink2_SynGen_on,
        Elink_inv => Elink2_inv,
        Elink_bit_shift => Elink2_bit_shift
    );

    lpGBT_SetDownELink_inst: entity work.lpGBT_SetDownELink port map(
        clk => clk100,
        start => SetDownELink,
        datatxcmdbus => datatxcmdbus_SetDownELink,
        cmd_paraclk => cmd_paraclk_SetDownELink, 
        cmd_parabyte => cmd_parabyte,
        Elink_dwn_PatGen_on => Elink_dwn_PatGen_on,
        Elink_dwn_SynGen_on => Elink_dwn_SynGen_on,
        Elink_dwn_inv => Elink_dwn_inv,
        Elink_dwn_bit_shift => Elink_dwn_bit_shift,
        Elink_dwn_phase => Elink_dwn_phase
    );

    lpGBT_SetEC_inst: entity work.lpGBT_SetEC port map (
        clk => clk100,
        start => SetEC,
        datatxcmdbus => datatxcmdbus_SetEC,
        cmd_paraclk => cmd_paraclk_SetEC,
        cmd_parabyte => cmd_parabyte,
        EC_PatGen_on_up => EC_PatGen_on_up,
        EC_SynGen_on_up => EC_SynGen_on_up,
        EC_inv_up => EC_Inv_on_up,
        EC_bit_shift_up => EC_Bit_shift_up,
        EC_PatGen_on_dwn => EC_PatGen_on_dwn,
        EC_SynGen_on_dwn => EC_SynGen_on_dwn,
        EC_inv_dwn => EC_Inv_on_dwn,
        EC_bit_shift_dwn => EC_Bit_shift_dwn,
        EC_phase_shift_dwn => EC_Phase_dwn
    );

    lpGBT_DoSerialConfigM1_inst: entity work.lpGBT_DoSerialConfig port map(
        clk => clk100,
        start => DoSerialConfigM1,
        datatxcmdbus => datatxcmdbus_DoSerialConfigM1,
        cmd_paraclk => cmd_paraclk_DoSerialConfigM1, 
        cmd_parabyte => cmd_parabyte,
        ICC_Address_lpGBT => ICC_Interface_ConfigM1(42 downto 36),
        ICC_NData => ICC_Interface_ConfigM1(35 downto 24),
        ICC_Addr => ICC_Interface_ConfigM1(15 downto 0),
        ICC_Din => ICC_Interface_ConfigM1(23 downto 16),
        ICC_Din_clk => ICC_Din_clk,
        ICC_Dout => ICC_Dout,
        ICC_Dout_clk => ICC_Dout_clk,
        ICC_write => ICC_Interface_ConfigM1(43),
        ICC_dosend => ICC_Interface_ConfigM1(44),
        ICC_busy => ICC_busy
    );

    lpGBT_DoSerialConfigM2_inst: entity work.lpGBT_DoSerialConfigM2 port map(
        clk => clk100,
        start => DoSerialConfigM2,
        lpGBT_I2C_MasterNr => ICC_Interface_lpGBT_I2C_MasterNr,
        datatxcmdbus => datatxcmdbus_DoSerialConfigM2,
        cmd_paraclk => cmd_paraclk_DoSerialConfigM2, 
        cmd_parabyte => cmd_parabyte,
        ICC_Interface => ICC_Interface_ConfigM2,
        ICC_Din_clk => ICC_Din_clk,
        ICC_Dout => ICC_Dout,
        ICC_Dout_clk => ICC_Dout_clk,
        ICC_busy => ICC_busy,
        ICC_rx_valid => ICC_rx_valid 
    );

    Transmit_I2C_0_inst: entity work.Transmit_I2C generic map(CDIV => 125, response => 7) port map(
        clk => clk100,
        start_wr => I2CWriteData0,
        start_rd => I2CReadData0,
        datatxcmdbus => datatxcmdbus_I2CData0,
        cmd_paraclk => cmd_paraclk_I2CData0, 
        cmd_parabyte => cmd_parabyte,
        bytenum => cmd_bytenum,
        scl => SCL0, 
        sda => SDA0
    );

    Transmit_I2C_1_inst: entity work.Transmit_I2C generic map(CDIV => 125, response => 23) port map(
        clk => clk100,
        start_wr => I2CWriteData1,
        start_rd => I2CReadData1,
        datatxcmdbus => datatxcmdbus_I2CData1,
        cmd_paraclk => cmd_paraclk_I2CData1, 
        cmd_parabyte => cmd_parabyte,
        bytenum => cmd_bytenum,
        scl => SCL1, 
        sda => SDA1
    );

    ReadWriteGPIO_inst: entity work.ReadWriteGPIO port map(
        clk => clk100,
        start => ReadWriteGPIO,
        datatxcmdbus => datatxcmdbus_ReadWriteGPIO,
        cmd_paraclk => cmd_paraclk_ReadWriteGPIO, 
        cmd_parabyte => cmd_parabyte,
        GPIO => GPIO
    );

    lpGBT_SetELinkMatrix_inst: entity work.lpGBT_SetELinkMatrix port map(
        clk => clk100,
        start => SetELinkMatrix,
        datatxcmdbus => datatxcmdbus_SetELinkMatrix,
        cmd_paraclk => cmd_paraclk_SetELinkMatrix, 
        cmd_parabyte => cmd_parabyte,
        ELink1_Inv => Matrix_ELink1_Inv,
        ELink1_Mat => Matrix_ELink1_Mat,
        ELink2_Inv => Matrix_ELink2_Inv,
        ELink2_Mat => Matrix_ELink2_Mat,
        ELinkD_Inv => Matrix_ELinkD_Inv,
        ELinkD_Mat => Matrix_ELinkD_Mat
    );

    lpGBT_SetSyncPattern_inst: entity work.lpGBT_SetSyncPattern port map(
        clk => clk100,
        start => SetSyncPattern,
        datatxcmdbus => datatxcmdbus_SetSyncPattern,
        cmd_paraclk => cmd_paraclk_SetSyncPattern, 
        cmd_parabyte => cmd_parabyte,
        SyncPattern_UL1 => SyncPattern_UL1,
        SyncPattern_UL2 => SyncPattern_UL2,
        SyncPattern_DL => SyncPattern_DL,
        SyncPattern_EC => SyncPattern_EC 
    );

    AlignerDebug_inst: entity work.AlignerDebug port map(
        clk => clk100,
        start => AlignerDebug,
        datatxcmdbus => datatxcmdbus_AlignerDebug,
        cmd_paraclk => cmd_paraclk_AlignerDebug, 
        cmd_parabyte => cmd_parabyte,
        align_limit_valid => align_limit_valid,
        align_limit_revalid => align_limit_revalid,
        align_limit_invalid => align_limit_invalid,
        align_hdr_pos => align_hdr_pos
    );

    GetCmdTimestamps_inst: entity work.GetCmdTimestamps port map(
        clk => clk100,
        start => GetCmdTimestamps,
        datatxcmdbus => datatxcmdbus_GetCmdTimestamps,
        timestamp_fifo => cmd_timestamp_fifo,
        word_fifo => cmd_word_fifo,
        fifo_pos => cmd_fifo_pos
    );

    EyeScanStatus_inst: entity work.EyeScanStatus port map(
        clk => clk100,
        start => EyeScanStatus,
        datatxcmdbus => datatxcmdbus_EyeScanStatus,
        cmd_paraclk => cmd_paraclk_EyeScanStatus, 
        cmd_parabyte => cmd_parabyte,
        RunScan => RunScan,
        GetData_eye_req => GetData_eye_req,
        GetData_eye_nxt => GetData_eye_nxt,
        Max_Prescale => Max_Prescale,
        ScanComplete => ScanComplete,
        GetData_eye_rdy => GetData_eye_rdy,
        GetData_eye_cmplt => GetData_eye_cmplt
    );

    GetEyeScanData_inst: entity work.GetEyeScanData port map(
        clk => clk100,
        start => GetEyeScanData,
        datatxcmdbus => datatxcmdbus_GetEyeScanData,
        GetData_eye_vertical => GetData_eye_vertical,
        GetData_eye_horizontal => GetData_eye_horizontal,
        GetData_eye_samples => GetData_eye_samples,
        GetData_eye_errors => GetData_eye_errors 
    );

end Behavioral;


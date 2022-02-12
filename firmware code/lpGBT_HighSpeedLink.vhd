----------------------------------------------------------------------------------
-- Company: DESY 
-- Engineer: Artur Boebel
-- 
-- Create Date: 04/06/2019
-- Description: High-speed-Link (optical) from/to the lpGBT
-- Needs a stable 160 MHz Source at MGT_CLK in  
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

--use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VComponents.all;

entity lpGBT_HighSpeedLink is
    Port ( sysclk_in : in STD_LOGIC;
           refclk_mgt_p : in STD_LOGIC;
           refclk_mgt_n : in STD_LOGIC;
           reset_in : in STD_LOGIC;
           SFP_RX_P_1 : in STD_LOGIC;
           SFP_RX_N_1 : in STD_LOGIC;
           SFP_TX_P_1 : out STD_LOGIC;
           SFP_TX_N_1 : out STD_LOGIC;
           SFP_RX_P_2 : in STD_LOGIC;
           SFP_RX_N_2 : in STD_LOGIC;
           SFP_TX_P_2 : out STD_LOGIC;
           SFP_TX_N_2 : out STD_LOGIC;

           downlinkUserData : in STD_LOGIC_VECTOR(31 downto 0);
           downlinkEcData : in STD_LOGIC_VECTOR(1 downto 0);
           downlinkIcData : in STD_LOGIC_VECTOR(1 downto 0);
           downlinkClk160_out : out STD_LOGIC;
           downlinkClk_en_out : out STD_LOGIC;

           uplink1Data : out STD_LOGIC_VECTOR(233 downto 0);
           uplink1Clk160_out : out STD_LOGIC;
           uplink1Clk_en_out : out STD_LOGIC;
           uplink1data_aligned : out STD_LOGIC;
           uplink1data_CRCOK : out STD_LOGIC;
           uplink1data_bypassFEC : in STD_LOGIC;
           
           uplink2Data : out STD_LOGIC_VECTOR(233 downto 0);
           uplink2Clk160_out : out STD_LOGIC;
           uplink2Clk_en_out : out STD_LOGIC;
           uplink2data_aligned : out STD_LOGIC;
           uplink2data_CRCOK : out STD_LOGIC;
           uplink2data_bypassFEC : in STD_LOGIC;

           GetData_num : in STD_LOGIC_VECTOR(1 downto 0);
           GetData_req : in STD_LOGIC;
           GetData_uplinkdata_raw : out STD_LOGIC_VECTOR(255 downto 0);
           GetData_rdy : out STD_LOGIC;
           uLData_locked_out : out STD_LOGIC_VECTOR(1 downto 0);
           uLData_unlock : in STD_LOGIC_VECTOR(1 downto 0);
           INVERT_DL : in STD_LOGIC;
           INVERT_UL1 : in STD_LOGIC;
           INVERT_UL2 : in STD_LOGIC;
           align_limit_valid : in STD_LOGIC_VECTOR (7 downto 0);      -- Debug. Nominal Value: 63
           align_limit_revalid : in STD_LOGIC_VECTOR (7 downto 0);    -- Debug. Nominal Value: 15
           align_limit_invalid : in STD_LOGIC_VECTOR (3 downto 0);    -- Debug. Nominal Value: 3
           align_hdr_pos_out : out STD_LOGIC_VECTOR (255 downto 0);    -- Debug.

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
end lpGBT_HighSpeedLink;

architecture Behavioral of lpGBT_HighSpeedLink is

    -- Transmitter (downlink):
    signal downLinkData : std_logic_vector (35 downto 0);
    signal downLinkScrambledData : std_logic_vector (35 downto 0);
    signal downLinkEncoderData_in : std_logic_vector (35 downto 0);
    signal downLinkInterleaverData_in : std_logic_vector (35 downto 0);
    signal downLinkInterleaverData_out : std_logic_vector (63 downto 0);
    signal downLinkFEC_in : std_logic_vector (23 downto 0);
    signal downLinkFEC_out : std_logic_vector (23 downto 0);
    signal downLinkTXData : std_logic_vector (63 downto 0);
    signal downLinkTXDataBuf : std_logic_vector (63 downto 0);
    signal downLinkExtData : std_logic_vector (255 downto 0);
    signal clk_en_scr, clk_en_out : std_logic := '0';
    signal TXUSRCLK2 : std_logic := '0';
    signal cntrtx : std_logic_vector (1 downto 0);

    signal GetData_Buffered1, GetData_Buffered2 : std_logic := '0';
   
    -- Data buffers:
    signal txdata, rxdata_1, rxdata_2: std_logic_vector (63 downto 0);
    signal txdata_I, rxdata_1_I, rxdata_2_I: std_logic_vector (63 downto 0);

    -- Receiver #1 (uplink):
    signal upLinkDataPacket_1 : std_logic_vector (255 downto 0);
    signal upLinkDataPacket_1_in : std_logic_vector (255 downto 0);
    signal upLinkDataPacket_1_in2 : std_logic_vector (255 downto 0);
    signal clk1_en_out : std_logic;

    signal uplinkdata1_aligned_buf1, uplinkdata1_aligned_buf2, uplinkdata1_aligned_buf3 : std_logic := '0';
    signal uplinkdata1_CRCOK_buf1, uplinkdata1_CRCOK_buf2, uLData1_locked, uplink1bypass : std_logic := '0';
    signal uLData_1_save1 : std_logic_vector (255 downto 0);
    signal uLData_1_save2 : std_logic_vector (255 downto 0);
    signal GetData_uplinkdata_1 : std_logic_vector (255 downto 0);
    signal upLinkDataDeinterleaved_1 : std_logic_vector (233 downto 0);
    signal upLinkFEC_1 : std_logic_vector (19 downto 0);
    signal upLinkDataFECdecoded_1 : std_logic_vector (233 downto 0);
    signal upLinkFECsyndr0_1 : std_logic_vector (9 downto 0);
    signal CntWait_1 : std_logic_vector (2 downto 0) := B"111";
    signal RXUSRCLK2_1 : std_logic := '0';

    -- Receiver #2 (uplink):
    signal upLinkDataPacket_2 : std_logic_vector (255 downto 0);
    signal upLinkDataPacket_2_in : std_logic_vector (255 downto 0);
    signal upLinkDataPacket_2_in2 : std_logic_vector (255 downto 0);
    signal clk2_en_out : std_logic;

    signal uplinkdata2_aligned_buf1, uplinkdata2_aligned_buf2, uplinkdata2_aligned_buf3 : std_logic := '0';
    signal uplinkdata2_CRCOK_buf1, uplinkdata2_CRCOK_buf2, uLData2_locked, uplink2bypass : std_logic := '0';
    signal uLData_2_save1 : std_logic_vector (255 downto 0);
    signal uLData_2_save2 : std_logic_vector (255 downto 0);
    signal GetData_uplinkdata_2 : std_logic_vector (255 downto 0);
    signal upLinkDataDeinterleaved_2 : std_logic_vector (233 downto 0);
    signal upLinkFEC_2 : std_logic_vector (19 downto 0);
    signal upLinkDataFECdecoded_2 : std_logic_vector (233 downto 0);
    signal upLinkFECsyndr0_2 : std_logic_vector (9 downto 0);
    signal CntWait_2 : std_logic_vector (2 downto 0) := B"111";
    signal RXUSRCLK2_2 : std_logic := '0';

begin

    -- DOWNLINK timing diagram:

    -- 160 MHz:          __    __    __    __    __    __    __    __    __    __    __  
    -- TXUSRCLK2       _|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |_
    -- = Clk160_out     .           .     .     .           .     .     .           .    
    --                  .           .     .     .           .     .     .           .    
    -- cntrtx[1:0]    0  X  1  X  2  X  3  X  0  X  1  X  2  X  3  X  0  X  1  X  2  X  3
    --                  .       _____     .     .       _____     .     .       _____    
    -- clk_en_out      ________|    .|_________________|    .|_________________|    .|___
    --                  .           .     .     .           .     .     .           .    
    -- downLinkData     R  Data[5]   X  Data[6] R  Data[6]   X  Data[7] R  Data[7]   X   
    --                 __                 . _____                 . _____                
    -- clk_en_scr       .|_________________|    .|_________________|    .|_______________
    --                  .                 .     .                 .     .                
    -- ScrambledData    .XXX      Data[5] .     .XXX      Data[6] .     .XXX      Data[7]
    --                  \                 .     \                 .     \                
    -- EncoderData_in   .X      Data[4]   .     .X      Data[5]   .     .X      Data[6]  
    -- FEC_out          .XXX      Data[4] .     .XXX      Data[5] .     .XXX      Data[6]
    --                  \                 .     \                 .     \                
    -- Interleaver_in   .X      Data[3]   .     .X      Data[4]   .     .X      Data[5]  
    -- FEC_in           .X      Data[3]   .     .X      Data[4]   .     .X      Data[5]  
    --                  \                 .     \                 .     \                
    -- Interleaver_out  .XXX      Data[2] .     .XXX     Data[3]  .     .XXX     Data[4] 
    --                  \                 .     \                 .     \                
    -- TxData           .X      Data[1]   .     .X     Data[2]    .     .X     Data[3]   
    --                  .                 \     .                 \     .                
    -- TxDataBuf        .    DL_Data[0]   .XXX  .   DL_Data[1]    .XXX  .   DL_Data[2]   

    -- Downlink path:

    downLinkData(31 downto 0) <= downlinkUserData;
    downLinkData(33 downto 32) <= downlinkEcData;
    downLinkData(35 downto 34) <= downlinkIcData;

    downlinkClk160_out <= TXUSRCLK2;
    downlinkClk_en_out <= clk_en_out;

    lpGBT_scrambler36bitOrder36_inst: entity work.lpGBT_scrambler36bitOrder36 port map (
        clk_i => TXUSRCLK2,
        clkEn_i => clk_en_scr,
        reset_i => RESET_IN,
        data_i => downLinkData,
        data_o => downLinkScrambledData
    );

    process (TXUSRCLK2) begin
    if rising_edge(TXUSRCLK2) then
        if clk_en_scr = '0' then
                downLinkEncoderData_in <= downLinkScrambledData;
        end if;
    end if;
    end process;

    lpGBT_downLinkFECEncoder_inst: entity work.lpGBT_downLinkFECEncoder port map (
        data_i => downLinkEncoderData_in,
        FEC_o => downLinkFEC_out
    );   

    process (TXUSRCLK2) begin
    if rising_edge(TXUSRCLK2) then
        if clk_en_scr = '0' then
                downLinkInterleaverData_in <= downLinkEncoderData_in;
                downLinkFEC_in <= downLinkFEC_out;
        end if;
    end if;
    end process;

    lpGBT_downLinkInterleaver_inst: entity work.lpGBT_downLinkInterleaver port map (
        data_i => downLinkInterleaverData_in,
        FEC_i => downLinkFEC_in,
        data_o => downLinkInterleaverData_out
    );

    process (TXUSRCLK2) begin
    if rising_edge(TXUSRCLK2) then
        if clk_en_scr = '0' then
                downLinkTXData <= downLinkInterleaverData_out;
        end if;
    end if;
    end process;

    g_GEN_FOR: for i in 0 to 63 generate
        downLinkExtData(i*4+3 downto i*4) <= downLinkTXDataBuf(i) & downLinkTXDataBuf(i) & downLinkTXDataBuf(i) & downLinkTXDataBuf(i);
    end generate g_GEN_FOR;


    process (TXUSRCLK2) begin
    if rising_edge(TXUSRCLK2) then
        if RESET_IN = '1' then
            txdata <= (others => '0');
            cntrtx <= B"00";
            clk_en_scr <= '0';
            clk_en_out <= '0';
        else
            case cntrtx is
                when B"00" => txdata <= downLinkExtData(63 downto 0);    clk_en_scr <= '0'; clk_en_out <= '0';
                when B"01" => txdata <= downLinkExtData(127 downto 64);  clk_en_scr <= '0'; clk_en_out <= '1';
                when B"10" => txdata <= downLinkExtData(191 downto 128); clk_en_scr <= '0'; clk_en_out <= '0';
                when B"11" => txdata <= downLinkExtData(255 downto 192); clk_en_scr <= '1'; clk_en_out <= '0';
                             downLinkTXDataBuf <= downLinkTXData;
            end case;
            cntrtx <= cntrtx + 1; 
        end if;
    end if;
    end process;

    txdata_I <= not txdata when INVERT_DL = '1' else txdata; 

    -- 10G Transceiver Module:

    gtx_rxtx_dual_inst: entity work.GTX_RxTx_dual port map(
        SYSCLK_IN => sysclk_in,
        REFCLK_MGT_P => refclk_mgt_p,
        REFCLK_MGT_N => refclk_mgt_n,
        RESET_IN => reset_in,
        --RESETDONE => RESETDONE,

        TXDATA => txdata_I,
        RXDATA => rxdata_1,
        TXUSRCLK2 => TXUSRCLK2, 
        RXUSRCLK2 => RXUSRCLK2_1,
        RX_P => SFP_RX_P_1,
        RX_N => SFP_RX_N_1,
        TX_P => SFP_TX_P_1,
        TX_N => SFP_TX_N_1,

        TXDATA_2 => (others => '0'),
        RXDATA_2 => rxdata_2,
        --TXUSRCLK2_2 => , 
        RXUSRCLK2_2 => RXUSRCLK2_2,
        RX_P_2 => SFP_RX_P_2,
        RX_N_2 => SFP_RX_N_2,
        TX_P_2 => SFP_TX_P_2,
        TX_N_2 => SFP_TX_N_2,

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

    GetData_uplinkdata_raw <= GetData_uplinkdata_1 when GetData_num(1) = '0'
                         else GetData_uplinkdata_2;
    GetData_rdy <= GetData_Buffered1 when GetData_num(1) = '0'
              else GetData_Buffered2;
    uLData_locked_out(0) <= uLData1_locked; 
    uLData_locked_out(1) <= uLData2_locked;

    rxdata_1_I <= not rxdata_1 when INVERT_UL1 = '1' else rxdata_1;
    rxdata_2_I <= not rxdata_2 when INVERT_UL2 = '1' else rxdata_2;

    -- UPLINK #1:

    lpGBT_Aligner1_inst: entity work.lpGBT_Aligner port map(
        rx_usrclk => RXUSRCLK2_1,
        clk_en_out => clk1_en_out,
        data_in => rxdata_1_I,
        data_out => upLinkDataPacket_1,
        limit_valid => align_limit_valid,     -- Debug. Nominal Value: 63
        limit_revalid => align_limit_revalid, -- Debug. Nominal Value: 15
        limit_invalid => align_limit_invalid, -- Debug. Nominal Value: 3
        hdr_pos_out => align_hdr_pos_out,     -- Debug.
        data_aligned => uplinkdata1_aligned_buf1
    );

    process(RXUSRCLK2_1) begin
    if rising_edge(RXUSRCLK2_1) then
        if clk1_en_out = '1' then
            upLinkDataPacket_1_in <= upLinkDataPacket_1;
            uplinkdata1_aligned_buf2 <= uplinkdata1_aligned_buf1;
            uplink1bypass <= uplink1data_bypassFEC;
        end if;
    end if;
    end process;

    lpGBT_Deinterleaver1_inst: entity work.lpGBT_Deinterleaver_10G_FEC5 port map(
        data_in => upLinkDataPacket_1_in,
        data_out => upLinkDataDeinterleaved_1,
        fec_out => upLinkFEC_1
    );

    lpGBT_uplink_decoder1_inst: entity work.lpGBT_uplink_decoder_10G_FEC5 port map(
        data_in => upLinkDataDeinterleaved_1, 
        fec_in => upLinkFEC_1,
        data_out => upLinkDataFECdecoded_1,
        syndr0_out => upLinkFECsyndr0_1,
        bypass => uplink1bypass
    );

    uplinkdata1_CRCOK_buf1 <= '1' when upLinkFECsyndr0_1 = B"0000000000" else '0'; 

    lpGBT_uplink_descramlber1_inst: entity work.lpGBT_uplink_descramlber_10G_FEC5 port map( 
        clk_i => RXUSRCLK2_1,
        clkEn_i => clk1_en_out,
        reset_i => RESET_IN,
        fec5_data_i => upLinkDataFECdecoded_1,
        fec5_data_o => uplink1Data
    );

    process(RXUSRCLK2_1) begin
    if rising_edge(RXUSRCLK2_1) then
        if clk1_en_out = '1' then
            upLinkDataPacket_1_in2 <= upLinkDataPacket_1_in;
            uplinkdata1_aligned_buf3 <= uplinkdata1_aligned_buf2;
            uplinkdata1_CRCOK_buf2 <= uplinkdata1_CRCOK_buf1;
        end if;
    end if;
    end process;

    uplink1Clk160_out <= RXUSRCLK2_1;
    uplink1Clk_en_out <= clk1_en_out;
    uplink1data_aligned <= uplinkdata1_aligned_buf3;
    uplink1data_CRCOK <= uplinkdata1_CRCOK_buf2;

    process(RXUSRCLK2_1) begin
    if rising_edge(RXUSRCLK2_1) then
        if clk1_en_out = '1' then

            -- Store last two packet raw data:
            if uLData1_locked = '0' then
                uLData_1_save2 <= upLinkDataPacket_1_in;
                uLData_1_save1 <= upLinkDataPacket_1_in2;
            end if;
            if uplinkdata1_aligned_buf3 = '0' then
                CntWait_1 <= B"111";
            elsif CntWait_1 > 0 then
                CntWait_1 <= CntWait_1 - 1;
            end if;
            if uLData_unlock(0) = '1' then uLData1_locked <= '0';
            elsif uplinkdata1_aligned_buf3 = '1' and CntWait_1 = 0 and uplinkdata1_CRCOK_buf2 = '0' then
                uLData1_locked <= '1';               -- Lock packet data in case of CRC error
            end if;

            -- Write data patterns to GetData output registers:
            if GetData_req = '1' then
                if GetData_Buffered1 = '0' then
                    if GetData_num(0) = '0' then GetData_uplinkdata_1 <= uLData_1_save1;
                    else                         GetData_uplinkdata_1 <= uLData_1_save2; end if;
                    GetData_Buffered1 <= '1';
                end if;
            else GetData_Buffered1 <= '0';
            end if;

        end if;
    end if;
    end process;


    -- UPLINK #2:

    lpGBT_Aligner2_inst: entity work.lpGBT_Aligner port map(
        rx_usrclk => RXUSRCLK2_2,
        clk_en_out => clk2_en_out,
        data_in => rxdata_2_I,
        data_out => upLinkDataPacket_2,
        limit_valid => align_limit_valid,     -- Debug. Nominal Value: 63
        limit_revalid => align_limit_revalid, -- Debug. Nominal Value: 15
        limit_invalid => align_limit_invalid, -- Debug. Nominal Value: 3
        --hdr_pos_out => ,
        data_aligned => uplinkdata2_aligned_buf1
    );

    process(RXUSRCLK2_2) begin
    if rising_edge(RXUSRCLK2_2) then
        if clk2_en_out = '1' then
            upLinkDataPacket_2_in <= upLinkDataPacket_2;
            uplinkdata2_aligned_buf2 <= uplinkdata2_aligned_buf1;
            uplink2bypass <= uplink2data_bypassFEC;
        end if;
    end if;
    end process;

    lpGBT_Deinterleaver2_inst: entity work.lpGBT_Deinterleaver_10G_FEC5 port map(
        data_in => upLinkDataPacket_2_in,
        data_out => upLinkDataDeinterleaved_2,
        fec_out => upLinkFEC_2
    );

    lpGBT_uplink_decoder2_inst: entity work.lpGBT_uplink_decoder_10G_FEC5 port map(
        data_in => upLinkDataDeinterleaved_2, 
        fec_in => upLinkFEC_2,
        data_out => upLinkDataFECdecoded_2,
        syndr0_out => upLinkFECsyndr0_2,
        bypass => uplink2bypass
    );

    uplinkdata2_CRCOK_buf1 <= '1' when upLinkFECsyndr0_2 = B"0000000000" else '0'; 

    lpGBT_uplink_descramlber2_inst: entity work.lpGBT_uplink_descramlber_10G_FEC5 port map( 
        clk_i => RXUSRCLK2_2,
        clkEn_i => clk2_en_out,
        reset_i => RESET_IN,
        fec5_data_i => upLinkDataFECdecoded_2,
        fec5_data_o => uplink2Data
    );

    process(RXUSRCLK2_2) begin
    if rising_edge(RXUSRCLK2_2) then
        if clk2_en_out = '1' then
            upLinkDataPacket_2_in2 <= upLinkDataPacket_2_in;
            uplinkdata2_aligned_buf3 <= uplinkdata2_aligned_buf2;
            uplinkdata2_CRCOK_buf2 <= uplinkdata2_CRCOK_buf1;
        end if;
    end if;
    end process;

    uplink2Clk160_out <= RXUSRCLK2_2;
    uplink2Clk_en_out <= clk2_en_out;
    uplink2data_aligned <= uplinkdata2_aligned_buf3;
    uplink2data_CRCOK <= uplinkdata2_CRCOK_buf2;

    process(RXUSRCLK2_2) begin
    if rising_edge(RXUSRCLK2_2) then
        if clk2_en_out = '1' then

            -- Store last two packet raw data:
            if uLData2_locked = '0' then
                uLData_2_save2 <= upLinkDataPacket_2_in;
                uLData_2_save1 <= upLinkDataPacket_2_in2;
            end if;
            if uplinkdata2_aligned_buf3 = '0' then
                CntWait_2 <= B"111";
            elsif CntWait_2 > 0 then
                CntWait_2 <= CntWait_2 - 1;
            end if;
            if uLData_unlock(1) = '1' then uLData2_locked <= '0';
            elsif uplinkdata2_aligned_buf3 = '1' and CntWait_2 = 0 and uplinkdata2_CRCOK_buf2 = '0' then
                uLData2_locked <= '1';               -- Lock packet data in case of CRC error
            end if;

            -- Write data patterns to GetData output registers:
            if GetData_req = '1' then
                if GetData_Buffered2 = '0' then
                    if GetData_num(0) = '1' then GetData_uplinkdata_2 <= uLData_2_save1;
                    else                         GetData_uplinkdata_2 <= uLData_2_save2; end if;
                    GetData_Buffered2 <= '1';
                end if;
            else GetData_Buffered2 <= '0';
            end if;

        end if;
    end if;
    end process;

end Behavioral;

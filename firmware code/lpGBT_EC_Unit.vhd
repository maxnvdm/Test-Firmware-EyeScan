-- Company: DESY 
-- Engineer: Artur Boebel
-- 
-- Create Date: 22/11/2019
-- Description: Generation and monitoring unit for EC (up- and downlink), each running at 80 Mbps.
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

Library UNISIM;
use UNISIM.vcomponents.all;

entity lpGBT_EC_Unit is
    Port (  
       clk160_up : in STD_LOGIC;                            -- 160 MHz uplink clock
       clk_en_up : in STD_LOGIC;                            -- 40 MHz uplink clock sync
       clk160_down : in STD_LOGIC;                          -- 160 MHz downlink clock
       clk_en_dwn : in STD_LOGIC;                           -- 40 MHz downlink clock sync
       run : in STD_LOGIC;

       TestPatGen_on_up : in STD_LOGIC;                     -- Switch on test pattern generator (uplink)
       SyncPatGen_on_up : in STD_LOGIC;                     -- Switch on sync pattern generator (uplink)
       SyncPattern : in STD_LOGIC_VECTOR (63 downto 0);     -- 64 bit: Sync Pattern (default: 550103070F1F3F7F)
       HighInv_on_up : in STD_LOGIC;                        -- Switch on data inverter (uplink)
       Bit_shift_up : in STD_LOGIC_VECTOR (5 downto 0);     -- 6 bit: number of bits to shift for data alignment (uplink)
       ec_out_p : out STD_LOGIC;                            -- EC out p-wire
       ec_out_n : out STD_LOGIC;                            -- EC out n-wire
       Data_EC_up : in STD_LOGIC_VECTOR (1 downto 0);       -- 2 EC bits, received by uplink frame 
       Data_CRCOK : in STD_LOGIC;
       Data_aligned : in STD_LOGIC;

       TestPatGen_on_dwn : in STD_LOGIC;                    -- Switch on test pattern generator (downlink)
       SyncPatGen_on_dwn : in STD_LOGIC;                    -- Switch on sync pattern generator (downlink)
       HighInv_on_dwn : in STD_LOGIC;                       -- Switch on data inverter (downlink)
       Bit_shift_dwn : in STD_LOGIC_VECTOR (5 downto 0);    -- 6 bit: number of bits to shift for data alignment (downlink)
       Phase_track_dwn : in STD_LOGIC_VECTOR (1 downto 0);  -- 2 bit: Phase alignment: 0, 90, 180, 270
       Data_EC_dwn_out : out STD_LOGIC_VECTOR (1 downto 0); -- 2 bit: ec pattern output 
       ec_in_p : in STD_LOGIC;                              -- EC in p-wire
       ec_in_n : in STD_LOGIC;                              -- EC in n-wire

       GetBER_req : in STD_LOGIC;
       BErrCnt_out : out STD_LOGIC_VECTOR (31 downto 0);
       PktLast15_out : out STD_LOGIC_VECTOR (7 downto 0);
       GetBER_rdy : out STD_LOGIC;
       GetData_LinkNumber : in STD_LOGIC;
       GetData_req : in STD_LOGIC;
       GetData_D1 : out STD_LOGIC_VECTOR (127 downto 0);
       GetData_D2 : out STD_LOGIC_VECTOR (127 downto 0);
       GetData_rdy : out STD_LOGIC
);
end lpGBT_EC_Unit;

architecture Behavioral of lpGBT_EC_Unit is

    component selectio_wiz_3 port (
        data_in_from_pins_p : in STD_LOGIC_VECTOR(0 downto 0);
        data_in_from_pins_n : in STD_LOGIC_VECTOR(0 downto 0);
        data_in_to_device : out STD_LOGIC_VECTOR(1 downto 0);
        clk_in : in STD_LOGIC;
        io_reset : in STD_LOGIC
    ); end component;

	signal cnt_up : STD_LOGIC := '0';
    signal ECout, ECout_buf : STD_LOGIC;

    signal PRBS_31_1_up : STD_LOGIC_VECTOR (30 downto 0) := B"0000010000000001000000000000001";
	signal PRBS_31_2_up : STD_LOGIC_VECTOR (30 downto 0) := B"0000010000000001000000000000010";
	signal PRBS_FIN_up : STD_LOGIC_VECTOR (31 downto 0) := X"00000000";
	signal SyncCount_up : STD_LOGIC_VECTOR(5 downto 0) := B"000000";

	signal databuf_EC_up : STD_LOGIC_VECTOR(67 downto 0);
    signal Pattern_up : STD_LOGIC_VECTOR (1 downto 0);  -- 2 bit: pattern for comparsion with EC uplink data 

    signal RunBuffered_up, GetBER_req_buf_up, GetBER_Buffered_up, GetData_req_buf_up, GetData_Buffered_up : STD_LOGIC := '0';
    signal CntWait_up : STD_LOGIC_VECTOR (2 downto 0) := B"000";
    signal BErrCnt_up : STD_LOGIC_VECTOR (15 downto 0) := X"0000";
    signal PktLast15_up : STD_LOGIC_VECTOR (3 downto 0) := X"0";
    signal DataPat1_up : STD_LOGIC_VECTOR (127 downto 0);
    signal DataPat2_up : STD_LOGIC_VECTOR (127 downto 0);

    signal GetData_D1_up : STD_LOGIC_VECTOR (127 downto 0);
    signal GetData_D2_up : STD_LOGIC_VECTOR (127 downto 0);

    signal PRBS_31_1_dwn : STD_LOGIC_VECTOR (30 downto 0) := B"0000010000000001000000000000001";
	signal PRBS_31_2_dwn : STD_LOGIC_VECTOR (30 downto 0) := B"0000010000000001000000000000010";
	signal PRBS_FIN_dwn : STD_LOGIC_VECTOR (31 downto 0) := X"00000000";
	signal SyncCount_dwn : STD_LOGIC_VECTOR(4 downto 0) := B"00000";
	
	signal Pattern_out_dwn : STD_LOGIC_VECTOR (1 downto 0);  -- 2 bit: pattern for comparsion with EC downlink data
	signal databuf_EC_dwn : STD_LOGIC_VECTOR(67 downto 0);
    signal Pattern_dwn : STD_LOGIC_VECTOR (1 downto 0); 

	signal data_selio_in : STD_LOGIC_VECTOR(1 downto 0);
	signal data_selio_buf : STD_LOGIC_VECTOR(7 downto 0);
    signal Pattern_cmp_dwn : STD_LOGIC_VECTOR (1 downto 0); 

    signal RunBuffered_dwn, GetBER_req_buf_dwn, GetBER_Buffered_dwn, GetData_req_buf_dwn, GetData_Buffered_dwn : STD_LOGIC := '0';

    signal BErrCnt_dwn : STD_LOGIC_VECTOR (15 downto 0) := X"0000";
    signal PktLast15_dwn : STD_LOGIC_VECTOR (3 downto 0) := X"0";
    signal DataPat1_dwn : STD_LOGIC_VECTOR (127 downto 0);
    signal DataPat2_dwn : STD_LOGIC_VECTOR (127 downto 0);

    signal GetData_D1_dwn : STD_LOGIC_VECTOR (127 downto 0);
    signal GetData_D2_dwn : STD_LOGIC_VECTOR (127 downto 0);

begin

    GetData_D1 <= GetData_D1_up when GetData_LinkNumber = '0' else GetData_D1_dwn;
    GetData_D2 <= GetData_D2_up when GetData_LinkNumber = '0' else GetData_D2_dwn;
    GetBER_rdy <= GetBER_Buffered_up and GetBER_buffered_dwn;
    GetData_rdy <= GetData_buffered_up and GetData_buffered_dwn;

-- Uplink: ---------------------------------------------------------------------------------------------------------

    OBUFDS_inst : OBUFDS port map (O => ec_out_p, OB => ec_out_n, I => ECout);

    -- Generate uplink Test Data:
    process (clk160_up) begin
    if rising_edge(clk160_up) then
        if clk_en_up = '1' then cnt_up <= '1';
        else cnt_up <= not cnt_up; end if;

        if cnt_up = '1' then        -- do this with 80 MHz:
            ECout <= ECout_buf;     

            -- Random pattern generator (32 bit), copy from Jonas Wolff:
            if SyncCount_up(4 downto 0) = 0 then
                PRBS_31_1_up(30 downto 1) <= PRBS_31_1_up(29 downto 0);
                PRBS_31_1_up(0) <= PRBS_31_1_up(27) xor PRBS_31_1_up(30);
                PRBS_31_2_up(30 downto 1) <= PRBS_31_2_up(29 downto 0);
                PRBS_31_2_up(0) <= PRBS_31_2_up(27) xor PRBS_31_2_up(30);
                PRBS_FIN_up <= PRBS_31_1_up(15 downto 0) & PRBS_31_2_up(15 downto 0);
            end if;

            -- Generates the test data: Random test pattern or sync pattern or just zeros or just ones:
            ECout_buf <= ( (TestPatGen_on_up and PRBS_FIN_up(conv_integer(SyncCount_up(4 downto 0))))
                        or (SyncPatGen_on_up and SyncPattern(conv_integer(63-SyncCount_up))) ) xor HighInv_on_up;
            SyncCount_up <= SyncCount_up + 1;

            -- Store the "history" of the last 176 bit of each elink in a FIFO (we have a huge delay on the uplink what must be compensated):
            databuf_EC_up(66 downto 0) <= databuf_EC_up(67 downto 1);
            databuf_EC_up(67) <= ECout_buf;

        end if;

        if clk_en_up = '1' then
            -- Extract 2 bit of the "history" to the generated data:
            Pattern_up(0) <= databuf_EC_up(64 - conv_integer(Bit_shift_up));
            Pattern_up(1) <= databuf_EC_up(63 - conv_integer(Bit_shift_up));
        end if;
       
    end if; 
    end process;

    -- Comparing and storing Uplink EC data:
    process (clk160_up) begin
    if rising_edge(clk160_up) then
        if clk_en_up = '1' then

            -- Bit error count:
            if run = '1' and RunBuffered_up = '1' then
                if Data_CRCOK = '0' or Data_aligned = '0' then
                    CntWait_up <= B"111";
                elsif CntWait_up > 0 then
                    CntWait_up <= CntWait_up - 1;
                end if;
                if Data_CRCOK = '1' and Data_aligned = '1' and CntWait_up = 0 and (TestPatGen_on_up = '1' or SyncPatGen_on_up = '1' ) then
                    if BErrCnt_up < X"FFF0" then
                        BErrCnt_up <= BErrCnt_up + ( Pattern_up(0) xor Data_EC_up(0) ) 
                                                 + ( Pattern_up(1) xor Data_EC_up(1) );
                    else BErrCnt_up <= X"FFFF";
                    end if;
                end if;
            elsif run = '1' then
                if RunBuffered_up = '0' then
                    BErrCnt_up <= X"0000";
                    RunBuffered_up <= '1'; 
                end if;
            else RunBuffered_up <= '0';
            end if;

            -- Last 15 packets compare:
            if Pattern_up = Data_EC_up then
                if PktLast15_up < 15 then PktLast15_up <= PktLast15_up + 1; end if;
            else
                if PktLast15_up > 0 then PktLast15_up <= PktLast15_up - 1; end if;
            end if;

            -- Data Pattern buffering:
            DataPat1_up(127 downto 2) <= DataPat1_up(125 downto 0);
            DataPat2_up(127 downto 2) <= DataPat2_up(125 downto 0);
            DataPat1_up(1 downto 0) <= Pattern_up;  
            DataPat2_up(1 downto 0) <= Data_EC_up;  

            -- Write data to output registers:
            GetBER_req_buf_up <= GetBER_req;
            if GetBER_req_buf_up = '1' then
                if GetBER_Buffered_up = '0' then
                    BErrCnt_out(31 downto 16) <= BErrCnt_up;
                    PktLast15_out(7 downto 4) <= PktLast15_up;
                    GetBER_Buffered_up <= '1';
                end if;
            else GetBER_Buffered_up <= '0';
            end if;

            -- Write data patterns to GetData output registers:
            GetData_req_buf_up <= GetData_req; 
            if GetData_req_buf_up = '1' then
                if GetData_Buffered_up = '0' then
                    GetData_D1_up <= DataPat1_up;
                    GetData_D2_up <= DataPat2_up;
                    GetData_Buffered_up <= '1';
                end if;
            else GetData_Buffered_up <= '0';
            end if;

        end if;
    end if;
    end process;

-- Downlink: ---------------------------------------------------------------------------------------------------------

    Data_EC_dwn_out <= Pattern_out_dwn;

    process (clk160_down) begin
    if rising_edge(clk160_down) then
        if clk_en_dwn = '1' then
            -- Random pattern generator (32 bit), copy from Jonas Wolff:
            if SyncCount_dwn(3 downto 0) = 0 then
                PRBS_31_1_dwn(30 downto 1) <= PRBS_31_1_dwn(29 downto 0);
                PRBS_31_1_dwn(0) <= PRBS_31_1_dwn(27) xor PRBS_31_1_dwn(30);
                PRBS_31_2_dwn(30 downto 1) <= PRBS_31_2_dwn(29 downto 0);
                PRBS_31_2_dwn(0) <= PRBS_31_2_dwn(27) xor PRBS_31_2_dwn(30);
                PRBS_FIN_dwn <= PRBS_31_1_dwn(15 downto 0) & PRBS_31_2_dwn(15 downto 0);
            end if;

            -- Test pattern generator:
            Pattern_out_dwn(0) <= ( (TestPatGen_on_dwn and PRBS_FIN_dwn(conv_integer(SyncCount_dwn(3 downto 0)) * 2 + 1))
                                 or (SyncPatGen_on_dwn and SyncPattern(63 - conv_integer(SyncCount_dwn) * 2 - 1)) ) xor HighInv_on_dwn;
            Pattern_out_dwn(1) <= ( (TestPatGen_on_dwn and PRBS_FIN_dwn(conv_integer(SyncCount_dwn(3 downto 0)) * 2))
                                 or (SyncPatGen_on_dwn and SyncPattern(63 - conv_integer(SyncCount_dwn) * 2)) ) xor HighInv_on_dwn;
            SyncCount_dwn <= SyncCount_dwn + 1;

            -- Store the "history" of the last 176 bit of each elink in a FIFO (we have a huge delay on the uplink what must be compensated):
            databuf_EC_dwn(65 downto 0) <= databuf_EC_dwn(67 downto 2);
            databuf_EC_dwn(66) <= Pattern_out_dwn(1);
            databuf_EC_dwn(67) <= Pattern_out_dwn(0);

            -- Extract 2 bit of the "history" to the generated data:
            Pattern_dwn <= databuf_EC_dwn(64 - conv_integer(Bit_shift_dwn) downto 63 - conv_integer(Bit_shift_dwn));
        end if;  
    end if; 
    end process;

    -- Input stage, sampling with DDR: 
    selectio_wiz_3_inst : selectio_wiz_3 port map(
        data_in_from_pins_p(0) => ec_in_p,
        data_in_from_pins_n(0) => ec_in_n,
        data_in_to_device => data_selio_in,
        clk_in => clk160_down,
        io_reset => '0'
    );

    -- Phase shift (select just every 4th bit):
    process (clk160_down) begin
    if rising_edge(clk160_down) then
        data_selio_buf(5 downto 0) <= data_selio_buf(7 downto 2);
        data_selio_buf(7 downto 6) <= data_selio_in(1 downto 0); -- data_selio_in(1) is the "newest". 
        if clk_en_dwn = '1' then
            Pattern_cmp_dwn(0) <= data_selio_buf(conv_integer(Phase_track_dwn));
            Pattern_cmp_dwn(1) <= data_selio_buf(conv_integer(Phase_track_dwn) + 4);
        end if;  
    end if; 
    end process;

    process (clk160_down) begin
    if rising_edge(clk160_down) then
        if clk_en_dwn = '1' then

            -- Bit error compare count:
            if run = '1' and RunBuffered_dwn = '1' then
                if TestPatGen_on_dwn = '1' or SyncPatGen_on_dwn = '1' then 
                    if BErrCnt_dwn < X"FFFC" then
                        BErrCnt_dwn <= BErrCnt_dwn + ( Pattern_cmp_dwn(0) xor Pattern_dwn(0) ) 
                                                   + ( Pattern_cmp_dwn(1) xor Pattern_dwn(1) );
                    else BErrCnt_dwn <= X"FFFF";
                    end if;
                end if;
            elsif run = '1' then
                if RunBuffered_dwn = '0' then
                    BErrCnt_dwn <= X"0000";
                    RunBuffered_dwn <= '1'; 
                end if;
            else RunBuffered_dwn <= '0';
            end if;

            -- Last 15 packets compare:
            if Pattern_cmp_dwn = Pattern_dwn then
                if PktLast15_dwn < 15 then PktLast15_dwn <= PktLast15_dwn + 1; end if;
            else
                if PktLast15_dwn > 0 then PktLast15_dwn <= PktLast15_dwn - 1; end if;
            end if;

            -- Data Pattern buffering:
            DataPat1_dwn(127 downto 2) <= DataPat1_dwn(125 downto 0);
            DataPat2_dwn(127 downto 2) <= DataPat2_dwn(125 downto 0);
            DataPat1_dwn(1) <= Pattern_dwn(0);  
            DataPat1_dwn(0) <= Pattern_dwn(1);  
            DataPat2_dwn(1) <= Pattern_cmp_dwn(0);  
            DataPat2_dwn(0) <= Pattern_cmp_dwn(1);  

            -- Write data to output registers:
            GetBER_req_buf_dwn <= GetBER_req;
            if GetBER_req_buf_dwn = '1' then
                if GetBER_Buffered_dwn = '0' then
                    BErrCnt_out(15 downto 0) <= BErrCnt_dwn;
                    PktLast15_out(3 downto 0) <= PktLast15_dwn;
                    GetBER_Buffered_dwn <= '1';
                end if;
            else GetBER_Buffered_dwn <= '0';
            end if;

            -- Write data patterns to GetData output registers:
            GetData_req_buf_dwn <= GetData_req; 
            if GetData_req_buf_dwn = '1' then
                if GetData_Buffered_dwn = '0' then
                    GetData_D1_dwn <= DataPat1_dwn;
                    GetData_D2_dwn <= DataPat2_dwn;
                    GetData_Buffered_dwn <= '1';
                end if;
            else GetData_Buffered_dwn <= '0';
            end if;

        end if;
    end if;
    end process;

end Behavioral;

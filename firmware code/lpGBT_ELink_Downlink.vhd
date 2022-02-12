----------------------------------------------------------------------------------
-- Company: DESY 
-- Engineer: Artur Boebel
-- 
-- Create Date: 04/06/2019
-- Description: Generation and monitoring unit for 14 synchronous ELinks (uplink), each running at 640 Mbps.  
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity lpGBT_ELink_Downlink is
    Port ( clk160 : in STD_LOGIC;                                -- 160 MHz 10G-packet synchronous clock in
           clk320 : in STD_LOGIC;                                -- 320 MHz clock in
           clk160_2 : in STD_LOGIC;                              -- 160 MHz clock in (synchronous and from same clock source as 320 MHz)
           clk_en : in STD_LOGIC;                                -- 40 MHz clock enable, synchronous to packet
           TestPatGen_on : in STD_LOGIC_VECTOR (7 downto 0);     -- 8 bit: Switch on test pattern generator for each ELink
           SyncPatGen_on : in STD_LOGIC_VECTOR (7 downto 0);     -- 8 bit: Switch on sync pattern generator for each ELink
           SyncPattern : in STD_LOGIC_VECTOR (63 downto 0);      -- 64 bit: Sync Pattern (default: 550103070F1F3F7F)
           HighInv_on : in STD_LOGIC_VECTOR (7 downto 0);        -- 8 bit: Switch on data inverter for each ELink
           Bit_shift : in STD_LOGIC_VECTOR (47 downto 0);        -- 8 x 6 bit: number of bits to shift for data alignment
           Phase_track : in STD_LOGIC_VECTOR (15 downto 0);      -- 8 x 2 bit: Phase alignment: 0, 90, 180, 270
           elink_inv : in STD_LOGIC_VECTOR (7 downto 0);         -- 8 bit: ELink inverter
           elink_sel : in STD_LOGIC_VECTOR (31 downto 0);        -- 8 x 4 bit: ELink selector for multiplexing
           Pattern_out : out STD_LOGIC_VECTOR (31 downto 0);     -- 8 x 4 bit: pattern output for downlink user data
           Compare_out : out STD_LOGIC_VECTOR (31 downto 0);     -- 8 x 4 bit: pattern compare output (delayed)
           Received_out : out STD_LOGIC_VECTOR (31 downto 0);    -- 8 x 4 bit: pattern received from ELinks
           data_selio_in : in STD_LOGIC_VECTOR (43 downto 0)     -- 11 x 4 bit ELink input data (from SelectIO)
    );
end lpGBT_ELink_Downlink;

architecture Behavioral of lpGBT_ELink_Downlink is

    signal PRBS_31_1 : STD_LOGIC_VECTOR (30 downto 0) := B"0000010000000001000000000000001";
	signal PRBS_31_2 : STD_LOGIC_VECTOR (30 downto 0) := B"0000010000000001000000000000010";
	signal PRBS_FIN : STD_LOGIC_VECTOR (31 downto 0) := X"00000000";
	signal cnt : STD_LOGIC_VECTOR (1 downto 0) := B"00";

	signal Pattern_out_buf : STD_LOGIC_VECTOR(31 downto 0);
	signal SyncCount : STD_LOGIC_VECTOR(3 downto 0) := X"F";
	signal data_selio_buf1 : STD_LOGIC_VECTOR(43 downto 0);
	signal data_selio_buf2 : STD_LOGIC_VECTOR(43 downto 0);
	signal data_selio : STD_LOGIC_VECTOR(43 downto 0);
	signal data_selio_sort : STD_LOGIC_VECTOR(31 downto 0);

    type t_8x72 is array(7 downto 0) of std_logic_vector(71 downto 0);
    signal Pattern_delayed: t_8x72;
    type t_8x16 is array(7 downto 0) of std_logic_vector(15 downto 0);
    signal data_elinks: t_8x16;

begin

    Pattern_out <= Pattern_out_buf;

    process (clk160) begin
    if rising_edge(clk160) then
        if clk_en = '1' then cnt <= B"01";
        else cnt <= cnt + 1; end if;

        -- Test pattern generator:
        -- Pattern out is: 77776666555544443333222211110000
        -- with 0...7: ELink channel                   ^  ^
        --                                         first  last

        if clk_en = '1' then
            -- Random pattern generator (32 bit), copy from Jonas Wolff:
            PRBS_31_1(30 downto 1) <= PRBS_31_1(29 downto 0);
            PRBS_31_1(0) <= PRBS_31_1(27) xor PRBS_31_1(30);
            PRBS_31_2(30 downto 1) <= PRBS_31_2(29 downto 0);
            PRBS_31_2(0) <= PRBS_31_2(27) xor PRBS_31_2(30);
            PRBS_FIN <= PRBS_31_1(15 downto 0) & PRBS_31_2(15 downto 0);

            for j in 0 to 7 loop
                for i in 0 to 3 loop
                    Pattern_out_buf(j*4+i) <= ( (TestPatGen_on(j) and PRBS_FIN(j*4+i))
                                             or (SyncPatGen_on(j) and SyncPattern(conv_integer(SyncCount)*4+i)) ) xor HighInv_on(j);
                end loop;  
            end loop;  
            SyncCount <= SyncCount - 1;
        end if;

        -- Delay stage (128 bit each channel)
        if cnt = 2 then
            for j in 0 to 7 loop
                for i in 0 to 16 loop
                    Pattern_delayed(j)(i*4+7 downto i*4+4) <= Pattern_delayed(j)(i*4+3 downto i*4);
                end loop;  
                Pattern_delayed(j)(3 downto 0) <= Pattern_out_buf(j*4+3 downto j*4);
            end loop;  
        end if;

        -- Delay selector
        if clk_en = '1' then
            for j in 0 to 7 loop
                Compare_out(j*4+3 downto j*4) <= Pattern_delayed(j)(conv_integer(Bit_shift(j*6+5 downto j*6)) + 8 downto conv_integer(Bit_shift(j*6+5 downto j*6)) + 5);
            end loop;
        end if;  
    end if; 
    end process;

    -- Input stage, sampling with 4x higher frequency: 
--    selectio_wiz_5_inst : selectio_wiz_5 port map(
--        data_in_from_pins_p => Elink_in_p(7 downto 0),
--        data_in_from_pins_n => Elink_in_n(7 downto 0),
--        data_in_to_device => data_selio_in,
--        bitslip => X"00",
--        clk_in => clk320,
--        clk_div_in => clk160_2,
--        io_reset => '0'
--    );

    -- Take data from select-io register:
    -- Data in is: 76543210765432107654321076543210
    -- with 0...7: ELink channel           ^^^^^^^^
    --                                        first

    process (clk160_2) begin
    if rising_edge(clk160_2) then
        data_selio_buf1 <= data_selio_in;
    end if; 
    end process;

    process (clk160) begin
    if falling_edge(clk160) then
        data_selio_buf2 <= data_selio_buf1;
    end if; 
    end process;

    process (clk160) begin
    if rising_edge(clk160) then
        data_selio <= data_selio_buf2;
    end if; 
    end process;

    process (clk160) begin
    if rising_edge(clk160) then
    
        for j in 0 to 3 loop
            for i in 0 to 7 loop
                if elink_sel(i*4+3 downto i*4) < 11 then
                    data_selio_sort(j*8+i) <= data_selio(j*11+conv_integer(elink_sel(i*4+3 downto i*4))) xor elink_inv(i);
                else
                    data_selio_sort(j*8+i) <= '0';
                end if;
            end loop;
        end loop;

        for j in 0 to 7 loop
            for i in 0 to 3 loop
                case cnt is
                when B"00" => data_elinks(j)(15-i) <= data_selio_sort(i*8+j);
                when B"01" => data_elinks(j)(11-i) <= data_selio_sort(i*8+j);
                when B"10" => data_elinks(j)(7-i) <= data_selio_sort(i*8+j);
                when B"11" => data_elinks(j)(3-i) <= data_selio_sort(i*8+j);
                end case;
            end loop;
        end loop;

        -- Phase shift (select just every 4th bit):
        if clk_en = '1' then
            for j in 0 to 7 loop
                for i in 0 to 3 loop
                    Received_out(j*4+i) <= data_elinks(j)(i*4 + 3 - conv_integer(Phase_track(j*2+1 downto j*2)));
                end loop;  
            end loop;
        end if;  
    end if; 
    end process;

end Behavioral;

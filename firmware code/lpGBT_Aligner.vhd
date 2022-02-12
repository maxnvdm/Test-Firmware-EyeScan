----------------------------------------------------------------------------------
-- Company: DESY 
-- Engineer: Artur Boebel
-- 
-- Create Date: 31/05/2019
-- Description: Data aligner for lpGBT upstream, 64bit input, 256bit output   
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

--use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VComponents.all;

entity lpGBT_Aligner is
    Port ( rx_usrclk : in STD_LOGIC;
           clk_en_out : out STD_LOGIC;
           data_in : in STD_LOGIC_VECTOR(63 downto 0);
           data_out : out STD_LOGIC_VECTOR(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000004";
           limit_valid : in STD_LOGIC_VECTOR (7 downto 0);      -- Debug. Nominal Value: 63
           limit_revalid : in STD_LOGIC_VECTOR (7 downto 0);    -- Debug. Nominal Value: 15
           limit_invalid : in STD_LOGIC_VECTOR (3 downto 0);    -- Debug. Nominal Value: 3
           hdr_pos_out : out STD_LOGIC_VECTOR (255 downto 0);   -- Debug.
           data_aligned : out STD_LOGIC
    );
end lpGBT_Aligner;

architecture Behavioral of lpGBT_Aligner is

    signal clk_en_data : std_logic := '0';
    signal cntrrx : std_logic_vector (1 downto 0) := B"00";

    signal rxdata_buf : std_logic_vector (191 downto 0);
    signal rxdata : std_logic_vector (511 downto 0);
    signal hdr_pos : std_logic_vector (255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    
    signal hdr_posnum : std_logic_vector (63 downto 0) := X"0000000000000000";
    signal hdr_found : std_logic_vector (15 downto 0) := X"0000";
    signal hdr_numfound : std_logic_vector (7 downto 0) := X"00";
    signal hdr_found_any : std_logic := '0';

begin

    -- UPLINK timing diagram:

    -- 160 MHz:          __    __    __    __    __    __    __    __    __    __    __  
    -- rx_usrclk       _|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |_
    --                  .     .     .     .     .     .     .     .     .     .     .    
    -- cntrrx[1:0]    000/11111/22222/33333/00000/11111/22222/33333/00000/11111/22222/333
    --                  .     .     .     .     .     .     .     .     .     .     .    
    -- rxdata[511:0]     Data[2,1]   XXXXXXXX    Data[3,2]   XXXXXXXX    Data[4,3]   XXXX
    --                  .     .     .     .     .     .     .     .     .     .     .    
    -- hdr_pos          .XXX      Data[1] .     .XXX      Data[2] .     .XXX      Data[3]
    --                  .     .     .     .     .     .     .     .     .     .     .    
    -- hdr_numfound     .XXXXX    Data[1] .     .XXXXX    Data[2] .     .XXXXX    Data[3]
    --                 __     .     .     . _____     .     .     . _____     .     .    
    -- clk_en_data      .|_________________|    .|_________________|    .|_______________   
    --                  .     .     .     .     .     .     .     .     .     .     .    
    -- data_out       X . Data[0]         .XXX  .   Data[1]       .XXX  .   Data[2]      
    --                  . _____     .     .     . _____     .     .     . _____     .    
    -- clk_en_out     ___|     |_________________|    .|_________________|     |_________


    -- Collext rx input packets in two 256 bit blocks (the new and the old one), together 512 bit. LSB is the first received:
    process (rx_usrclk) begin
    if rising_edge(rx_usrclk) then
        case cntrrx is
            when b"00" => clk_en_data <= '0'; clk_en_out <= '1'; rxdata_buf(63 downto 0) <= data_in;
            when b"01" => clk_en_data <= '0'; clk_en_out <= '0'; rxdata_buf(127 downto 64) <= data_in;
            when b"10" => clk_en_data <= '0'; clk_en_out <= '0'; rxdata_buf(191 downto 128) <= data_in;
                                                                 rxdata(255 downto 0) <= rxdata(511 downto 256);
            when b"11" => clk_en_data <= '1'; clk_en_out <= '0'; rxdata(511 downto 448) <= data_in;
                                                                 rxdata(447 downto 256) <= rxdata_buf;
        end case; 
        cntrrx <= cntrrx + 1;
        hdr_pos_out <= hdr_pos;
    end if; 
    end process;

    -- Look for valid header and it's position in 256 bit data block:  
    g_GEN_FOR1: for i in 0 to 255 generate
        lpGBT_HdrChk_inst : entity work.lpGBT_HdrChk port map(
                clk => rx_usrclk,
                clk_en => clk_en_data,
                hdr1 => rxdata(i),
                hdr0 => rxdata((i+1) mod 256),
                limit_valid => limit_valid,     -- Debug. Nominal Value: 63
                limit_revalid => limit_revalid, -- Debug. Nominal Value: 15
                limit_invalid => limit_invalid, -- Debug. Nominal Value: 3
                hdr_valid_out => hdr_pos(i)
            );
    end generate g_GEN_FOR1;

    -- Convert the position of the first '1' in the hdr_pos[256] vector to a number (hdr_numfound). 
    g_GEN_FOR2: for i in 0 to 15 generate
        get_lbit_pos_inst : entity work.get_lbit_pos port map(bit_vec => hdr_pos(i*16+15 downto i*16), pos => hdr_posnum(i*4+3 downto i*4), found => hdr_found(i));
    end generate g_GEN_FOR2;

    hdr_numfound <= hdr_posnum(3 downto 0) + x"00" when hdr_found(0) = '1' else
                    hdr_posnum(7 downto 4) + x"10" when hdr_found(1) = '1' else
                    hdr_posnum(11 downto 8) + x"20" when hdr_found(2) = '1' else
                    hdr_posnum(15 downto 12) + x"30" when hdr_found(3) = '1' else
                    hdr_posnum(19 downto 16) + x"40" when hdr_found(4) = '1' else
                    hdr_posnum(23 downto 20) + x"50" when hdr_found(5) = '1' else
                    hdr_posnum(27 downto 24) + x"60" when hdr_found(6) = '1' else
                    hdr_posnum(31 downto 28) + x"70" when hdr_found(7) = '1' else
                    hdr_posnum(35 downto 32) + x"80" when hdr_found(8) = '1' else
                    hdr_posnum(39 downto 36) + x"90" when hdr_found(9) = '1' else
                    hdr_posnum(43 downto 40) + x"A0" when hdr_found(10) = '1' else
                    hdr_posnum(47 downto 44) + x"B0" when hdr_found(11) = '1' else
                    hdr_posnum(51 downto 48) + x"C0" when hdr_found(12) = '1' else
                    hdr_posnum(55 downto 52) + x"D0" when hdr_found(13) = '1' else
                    hdr_posnum(59 downto 56) + x"E0" when hdr_found(14) = '1' else
                    hdr_posnum(63 downto 60) + x"F0" when hdr_found(15) = '1' else x"00";

    hdr_found_any <= '0' when hdr_found = X"0000" else '1';

    -- Align according the header position:     
    process (rx_usrclk) begin
    if rising_edge(rx_usrclk) then
        if clk_en_data = '1' then
            data_aligned <= hdr_found_any;
            if hdr_found_any = '1' then
                data_out <= rxdata(conv_integer(hdr_numfound) + 255 downto conv_integer(hdr_numfound));
            else
                data_out <= X"0000000000000000000000000000000000000000000000000000000000000004";
            end if;
        end if;
    end if; 
    end process;

end Behavioral;

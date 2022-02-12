----------------------------------------------------------------------------------
-- Company: DESY 
-- Engineer: Artur Boebel
-- 
-- Create Date: 04/06/2019
-- Description: Data interleaver for lpGBT downstream
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity lpGBT_downLinkInterleaver is
    generic ( HEADER_c : in std_logic_vector(3 downto 0) := "1001" );
    port ( data_i : in std_logic_vector(35 downto 0);
           FEC_i : in std_logic_vector(23 downto 0);
           data_o : out std_logic_vector(63 downto 0)
    );
end lpGBT_downLinkInterleaver;

architecture behavioral of lpGBT_downLinkInterleaver is
    signal interleaved_data : std_logic_vector(63 downto 0);
begin		
	interleaved_data(63 downto 24)	<=	HEADER_c(3) & 
										data_i(35) & 
										HEADER_c(2) & 
										data_i(34) & 
										HEADER_c(1) & 
										data_i(33) & 
										HEADER_c(0) & 
										data_i(26 downto 24) & 
										data_i(17 downto 15) & 
										data_i(8 downto 6) & 
										data_i(32 downto 30) &
										data_i(23 downto 21) &
										data_i(14 downto 12) &
										data_i(5 downto 3) &
										data_i(29 downto 27) &
										data_i(20 downto 18) &
										data_i(11 downto 9) &
										data_i(2 downto 0);
	interleaved_data(23 downto 0)	<=	FEC_i(23 downto 21) &
										FEC_i(17 downto 15) &
										FEC_i(11 downto 9) &
										FEC_i(5 downto 3) &
										FEC_i(20 downto 18) &
										FEC_i(14 downto 12) &
										FEC_i(8 downto 6) &
										FEC_i(2 downto 0);

    -- Reverse bit order:
    g_GEN_FOR: for i in 0 to 63 generate
        data_o(i) <= interleaved_data(63-i);
    end generate g_GEN_FOR;

end behavioral;

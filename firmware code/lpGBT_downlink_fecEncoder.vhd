----------------------------------------------------------------------------------
-- Company: DESY 
-- Engineer: Artur Boebel
-- 
-- Create Date: 04/06/2019
-- Description: FEC encoder for lpGBT upstream
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity lpGBT_downLinkFECEncoder is
    port ( data_i : in std_logic_vector(35 downto 0);
           FEC_o : out std_logic_vector(23 downto 0)
    );   
end lpGBT_downLinkFECEncoder;

architecture behavioral of lpGBT_downLinkFECEncoder IS

	signal virtualFrame_C0		: std_logic_vector(14 downto 0);
	signal virtualFrame_C1		: std_logic_vector(14 downto 0);
	signal virtualFrame_C2		: std_logic_vector(14 downto 0);
	signal virtualFrame_C3		: std_logic_vector(14 downto 0);
	signal FEC_s				: std_logic_vector(23 downto 0);

begin
		
	virtualFrame_C0	<= "000000" & data_i(8 downto 0);
	virtualFrame_C1	<= "000000" & data_i(17 downto 9);
	virtualFrame_C2	<= "000000" & data_i(26 downto 18);
	virtualFrame_C3	<= "000000" & data_i(35 downto 27);
	
	RSE0_inst: entity work.rs_encoder_N7K5 port map (
		msg => virtualFrame_C0,
		parity => FEC_s(5 downto 0)		
	);
	
	RSE1_inst: entity work.rs_encoder_N7K5 port map (
		msg => virtualFrame_C1,
		parity => FEC_s(11 downto 6)		
	);
	
	RSE2_inst: entity work.rs_encoder_N7K5 port map (
		msg => virtualFrame_C2,
		parity => FEC_s(17 downto 12)		
	);
	
	RSE3_inst: entity work.rs_encoder_N7K5 port map (
		msg => virtualFrame_C3,
		parity => FEC_s(23 downto 18)		
	);

    FEC_o <= FEC_s;

end behavioral;

----------------------------------------------------------------------------------
-- Company: DESY 
-- Engineer: Artur Boebel
-- 
-- Create Date: 03/06/2019
-- Description: Data decoder for lpGBT upstream for 10.24 Gbps / FEC5
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity lpGBT_uplink_decoder_10G_FEC5 is
    port ( data_in : in  std_logic_vector(233 downto 0);    -- Data input from de-interleaver
           fec_in  : in  std_logic_vector(19 downto 0);     -- FEC input from de-interleaver
           data_out : out std_logic_vector(233 downto 0);   -- Data output (FEC corrected)
           syndr0_out : out std_logic_vector(9 downto 0);
           bypass : in  std_logic
    );
end lpGBT_uplink_decoder_10G_FEC5;

architecture behavioral of lpGBT_uplink_decoder_10G_FEC5 is

    signal fec5_encoded_code0_s : std_logic_vector(144 downto 0);
    signal fec5_encoded_code1_s : std_logic_vector(144 downto 0);
    signal fec5_decoded_code0_s : std_logic_vector(144 downto 0);
    signal fec5_decoded_code1_s : std_logic_vector(144 downto 0);

begin 
    fec5_encoded_code0_s <= "00000000000000000000000000" & data_in(233 downto 232) & data_in(116 downto 0);

    rs_decoder_N31K29_c0_inst: entity work.rs_decoder_N31K29 port map (
        payloadData_i => fec5_encoded_code0_s,                
        fecData_i => fec_in(9 downto 0),
        data_o => fec5_decoded_code0_s,
        syndr0_out => syndr0_out(4 downto 0)
    );

    fec5_encoded_code1_s <= "000000000000000000000000000000" & data_in(231 downto 117);

    rs_decoder_N31K29_c1_inst: entity work.rs_decoder_N31K29 port map (
        payloadData_i => fec5_encoded_code1_s,                
        fecData_i => fec_in(19 downto 10),
        data_o => fec5_decoded_code1_s, 
        syndr0_out => syndr0_out(9 downto 5)
    );

    data_out <= data_in when bypass = '1' else
                fec5_decoded_code0_s(118 downto 117) & fec5_decoded_code1_s(114 downto 0) & fec5_decoded_code0_s(116 downto 0);

end behavioral;

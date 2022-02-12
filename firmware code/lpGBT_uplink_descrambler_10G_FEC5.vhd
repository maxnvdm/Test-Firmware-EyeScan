----------------------------------------------------------------------------------
-- Company: DESY 
-- Engineer: Artur Boebel
-- 
-- Create Date: 03/06/2019
-- Description: Data descrambler for lpGBT upstream for 10.24 Gbps / FEC5
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity lpGBT_uplink_descramlber_10G_FEC5 is 
   port ( clk_i       : in  std_logic;                        -- Input clock used to decode the received data
          clkEn_i     : in  std_logic;                        -- Clock enable used when the input clock is different from 40MHz
          reset_i     : in  std_logic;                        -- Uplink datapath's reset signal
          fec5_data_i : in  std_logic_vector(233 downto 0);   -- FEC5 User data input from decoder (scrambled)
          fec5_data_o : out std_logic_vector(233 downto 0)    -- FEC5 User data output (descrambled)
   );  
end lpGBT_uplink_descramlber_10G_FEC5;

architecture behavioral of lpGBT_uplink_descramlber_10G_FEC5 is

begin 
        
    descrambler58bitOrder58_l0_inst: entity work.descrambler58bitOrder58 port map (
        clk_i => clk_i,
        clkEn_i => clkEn_i,
        reset_i => reset_i,
        data_i => fec5_data_i(57 downto 0),
        data_o => fec5_data_o(57 downto 0),
        bypass => '0'
    );   
           
    descrambler58bitOrder58_l1_inst: entity work.descrambler58bitOrder58 port map (
        clk_i => clk_i,
        clkEn_i => clkEn_i,
        reset_i => reset_i,
        data_i => fec5_data_i(115 downto 58),
        data_o => fec5_data_o(115 downto 58),
        bypass => '0'
    );
           
    descrambler58bitOrder58_h0_inst: entity work.descrambler58bitOrder58 port map (
        clk_i => clk_i,
        clkEn_i => clkEn_i,
        reset_i => reset_i,
        data_i => fec5_data_i(173 downto 116),
        data_o => fec5_data_o(173 downto 116),
        bypass => '0'
    );   
           
    descrambler60bitOrder58_h1_inst: entity work.descrambler60bitOrder58 port map (
        clk_i => clk_i,
        clkEn_i => clkEn_i,
        reset_i => reset_i,
        data_i => fec5_data_i(233 downto 174),
        data_o => fec5_data_o(233 downto 174),
        bypass => '0'
    );
    
end behavioral;

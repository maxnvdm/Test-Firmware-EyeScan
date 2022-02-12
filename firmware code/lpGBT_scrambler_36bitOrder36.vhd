----------------------------------------------------------------------------------
-- Company: DESY 
-- Engineer: Artur Boebel
-- 
-- Create Date: 04/06/2019
-- Description: Data scrambler for lpGBT downstream
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity lpGBT_scrambler36bitOrder36 is
    generic ( INIT_SEED : in std_logic_vector(35 downto 0) := x"1fba847af"
    ); port ( clk_i : in std_logic;
              clkEn_i : in std_logic;
              reset_i : in std_logic;
              data_i : in  std_logic_vector(35 downto 0);
              data_o : out std_logic_vector(35 downto 0)
   );
end lpGBT_scrambler36bitOrder36;

architecture behavioral of lpGBT_scrambler36bitOrder36 is
    signal scrambledData : std_logic_vector(35 downto 0);
begin
    process(clk_i, reset_i) begin
        if rising_edge(clk_i) then
            if reset_i = '1' then scrambledData <= INIT_SEED;
            elsif clkEn_i = '1' then
                scrambledData(35 downto 25) <=  data_i(35 downto 25) xnor
                                                data_i(10 downto 0) xnor
                                                scrambledData(21 downto 11) xnor
                                                scrambledData(10 downto 0) xnor
                                                scrambledData(35 downto 25);
                scrambledData(24 downto 0)  <=  data_i(24 downto 0) xnor
                                                scrambledData(35 downto 11) xnor
                                                scrambledData(24 downto 0);
            end if;
        end if;
    end process;
    data_o <= scrambledData;

end behavioral;

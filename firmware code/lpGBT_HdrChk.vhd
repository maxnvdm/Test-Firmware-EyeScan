----------------------------------------------------------------------------------
-- Company: DESY 
-- Engineer: Artur Boebel
-- 
-- Create Date: 31/05/2019
-- Description: lpGBT Header check   
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

--use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VComponents.all;

entity lpGBT_HdrChk is
    Port ( clk : in STD_LOGIC;
           clk_en : in STD_LOGIC;
           hdr0 : in STD_LOGIC;
           hdr1 : in STD_LOGIC;
           limit_valid : in STD_LOGIC_VECTOR (7 downto 0);      -- Debug. Nominal Value: 63
           limit_revalid : in STD_LOGIC_VECTOR (7 downto 0);    -- Debug. Nominal Value: 15
           limit_invalid : in STD_LOGIC_VECTOR (3 downto 0);    -- Debug. Nominal Value: 3
           hdr_valid_out : out STD_LOGIC);
end lpGBT_HdrChk;

architecture Behavioral of lpGBT_HdrChk is
    signal cntr_valid : STD_LOGIC_VECTOR (7 downto 0) := X"00";
    signal cntr_revalid : STD_LOGIC_VECTOR (7 downto 0) := X"00";
    signal cntr_invalid : STD_LOGIC_VECTOR (3 downto 0) := X"0";
begin

    process (clk) begin
    if rising_edge(clk) then
        if clk_en = '1' then
             if hdr1 = '1' and hdr0 = '0' then
                if cntr_valid < limit_valid then cntr_valid <= cntr_valid + 1; else hdr_valid_out <= '1'; end if;
                if cntr_revalid < limit_revalid then cntr_revalid <= cntr_revalid + 1; else cntr_invalid <= X"0"; end if;
             else
                if cntr_invalid < limit_invalid then cntr_invalid <= cntr_invalid + 1;
                else cntr_valid <= X"00"; hdr_valid_out <= '0'; end if;
                cntr_revalid <= X"00";
             end if;
        end if;
    end if;
    end process;

end Behavioral;

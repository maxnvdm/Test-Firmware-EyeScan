----------------------------------------------------------------------------------
-- Company: DESY 
-- Engineer: Artur Boebel
-- 
-- Create Date: 18/06/2019
-- Description: Module for responding the DeviceName via UART
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity lpGBT_GetDeviceName is
    Port ( clk : in STD_LOGIC;
           start : in STD_LOGIC;
           datatxcmdbus : out STD_LOGIC_VECTOR (9 downto 0) := B"0000000000" );
end lpGBT_GetDeviceName;

architecture Behavioral of lpGBT_GetDeviceName is

    constant DeviceName : String := "lpGBT Test Firmware V1.6";

    signal cntr : std_logic_vector (4 downto 0) := B"00000";
    signal ck : std_logic := '0';

begin

    datatxcmdbus(8) <= ck;

    -- Prepare and send the response:
    process(clk) begin
    if rising_edge(clk) then
        if start = '1' then
            if cntr < 25 then 
                if ck = '0' then
                    datatxcmdbus(7 downto 0) <= conv_std_logic_vector(character'pos(DeviceName(conv_integer(cntr)+1)),8);
                    ck <= '1';  -- Clock the response byte
                else ck <= '0'; cntr <= cntr + 1; end if;
            else ck <= '0'; datatxcmdbus(9) <= '1'; end if; -- Send the response packet
        else 
            ck <= '0'; cntr <= (others => '0');
            datatxcmdbus(7 downto 0) <= X"00";
            datatxcmdbus(9) <= '0';
        end if; 
    end if;
    end process;

end Behavioral;

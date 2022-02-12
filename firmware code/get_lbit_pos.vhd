----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/31/2019 05:04:35 PM
-- Design Name: 
-- Module Name: get_lbit_pos - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity get_lbit_pos is
    Port ( bit_vec : in STD_LOGIC_VECTOR (15 downto 0);
           pos : out STD_LOGIC_VECTOR (3 downto 0);
           found : out STD_LOGIC  );
end get_lbit_pos;

architecture Behavioral of get_lbit_pos is
begin
    found <= '0' when bit_vec = X"0000" else '1';

    pos <= x"0" when bit_vec(0) = '1' else
           x"1" when bit_vec(1) = '1' else
           x"2" when bit_vec(2) = '1' else
           x"3" when bit_vec(3) = '1' else
           x"4" when bit_vec(4) = '1' else
           x"5" when bit_vec(5) = '1' else
           x"6" when bit_vec(6) = '1' else
           x"7" when bit_vec(7) = '1' else
           x"8" when bit_vec(8) = '1' else
           x"9" when bit_vec(9) = '1' else
           x"A" when bit_vec(10) = '1' else
           x"B" when bit_vec(11) = '1' else
           x"C" when bit_vec(12) = '1' else
           x"D" when bit_vec(13) = '1' else
           x"E" when bit_vec(14) = '1' else
           x"F" when bit_vec(15) = '1' else x"0";

end Behavioral;

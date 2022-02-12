----------------------------------------------------------------------------------
-- Company: DESY 
-- Engineer: Artur Boebel
-- 
-- Create Date: 02/06/2021
-- Description:
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity GetEyeScanData is
    Port ( clk : in STD_LOGIC;
       start : in STD_LOGIC;
       datatxcmdbus : out STD_LOGIC_VECTOR (9 downto 0) := B"0000000000";
       GetData_eye_vertical : in STD_LOGIC_VECTOR (991 downto 0);
       GetData_eye_horizontal : in STD_LOGIC_VECTOR (991 downto 0);
       GetData_eye_samples : in STD_LOGIC_VECTOR (991 downto 0);
       GetData_eye_errors : in STD_LOGIC_VECTOR (991 downto 0)
     );
 end GetEyeScanData;

architecture Behavioral of GetEyeScanData is

    signal cntr : std_logic_vector (8 downto 0) := B"000000000";
    signal byteout : std_logic_vector (7 downto 0) := X"00";
    signal ck : std_logic := '0';

begin

    datatxcmdbus(7 downto 0) <= byteout;
    datatxcmdbus(8) <= ck;

    -- Prepare and send the response:
    process(clk) begin
    if rising_edge(clk) then
        if start = '1' then
            if cntr < 496 then 
                if ck = '0' then
                    if cntr < 124 then
                        byteout <= GetData_eye_vertical(conv_integer(cntr)*8 + 7 downto conv_integer(cntr)*8);
                    elsif cntr >= 124 and cntr < 248 then
                        byteout <= GetData_eye_horizontal(conv_integer(cntr-124)*8 + 7 downto conv_integer(cntr-124)*8);
                    elsif cntr >= 248 and cntr < 372 then
                        byteout <= GetData_eye_samples(conv_integer(cntr-248)*8 + 7 downto conv_integer(cntr-248)*8);
                    elsif cntr >= 372 and cntr < 496 then
                        byteout <= GetData_eye_errors(conv_integer(cntr-372)*8 + 7 downto conv_integer(cntr-372)*8);
                    end if;
                    ck <= '1';  -- Clock the response byte
                else ck <= '0'; cntr <= cntr + 1; end if;
            else ck <= '0'; datatxcmdbus(9) <= '1'; end if; -- Send the response packet
        else 
            ck <= '0'; cntr <= B"000000000";
            byteout <= X"00";
            datatxcmdbus(9) <= '0';
        end if; 
    end if;
    end process;

end Behavioral;
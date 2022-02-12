----------------------------------------------------------------------------------
-- Company: DESY 
-- Engineer: Artur Boebel
-- 
-- Create Date: 07/04/2021
-- Description:
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity GetCmdTimestamps is
    Port ( clk : in STD_LOGIC;
           start : in STD_LOGIC;
           datatxcmdbus : out STD_LOGIC_VECTOR (9 downto 0) := B"0000000000";
           timestamp_fifo : in STD_LOGIC_VECTOR (767 downto 0);
           word_fifo : in STD_LOGIC_VECTOR (255 downto 0);
           fifo_pos : in STD_LOGIC_VECTOR (3 downto 0) );
end GetCmdTimestamps;

architecture Behavioral of GetCmdTimestamps is

    signal cntr : std_logic_vector (7 downto 0) := X"00";
    signal byteout : std_logic_vector (7 downto 0) := X"00";
    signal ck : std_logic := '0';

begin

    datatxcmdbus(7 downto 0) <= byteout;
    datatxcmdbus(8) <= ck;

    -- Prepare and send the response:
    process(clk) begin
    if rising_edge(clk) then
        if start = '1' then
            if cntr < 129 then 
                if ck = '0' then
                    if cntr < 32 then
                        if cntr(0) = '0' then byteout <= word_fifo(conv_integer(cntr+1)*8 + 7 downto conv_integer(cntr+1)*8);
                        else byteout <= word_fifo(conv_integer(cntr-1)*8 + 7 downto conv_integer(cntr-1)*8); end if;
                    elsif cntr >= 32 and cntr < 128 then
                        byteout <= timestamp_fifo((5 - ((conv_integer(cntr)-32) mod 6) + ((conv_integer(cntr)-32) / 6) * 6) * 8 + 7 downto (5 - ((conv_integer(cntr)-32) mod 6) + ((conv_integer(cntr)-32) / 6) * 6) * 8);
                    elsif cntr = 128 then
                        byteout <= X"0" & conv_std_logic_vector(conv_integer(fifo_pos) - 1, 4);
                    end if;
                    ck <= '1';  -- Clock the response byte
                else ck <= '0'; cntr <= cntr + 1; end if;
            else ck <= '0'; datatxcmdbus(9) <= '1'; end if; -- Send the response packet
        else 
            ck <= '0'; cntr <= X"00";
            byteout <= X"00";
            datatxcmdbus(9) <= '0';
        end if; 
    end if;
    end process;

end Behavioral;

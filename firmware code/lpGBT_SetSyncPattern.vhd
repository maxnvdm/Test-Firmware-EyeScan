----------------------------------------------------------------------------------
-- Company: DESY
-- Engineer: Artur Boebel
-- 
-- Create Date: 18/05/2020
-- Description: 
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity lpGBT_SetSyncPattern is
    Port ( clk : in STD_LOGIC;
           start : in STD_LOGIC;
           datatxcmdbus : out STD_LOGIC_VECTOR (9 downto 0) := B"0000000000";
           cmd_paraclk : out STD_LOGIC;
           cmd_parabyte : in STD_LOGIC_VECTOR (7 downto 0);
           SyncPattern_UL1 : out STD_LOGIC_VECTOR (63 downto 0) := X"550103070F1F3F7F";
           SyncPattern_UL2 : out STD_LOGIC_VECTOR (63 downto 0) := X"550103070F1F3F7F";
           SyncPattern_DL  : out STD_LOGIC_VECTOR (63 downto 0) := X"550103070F1F3F7F";
           SyncPattern_EC  : out STD_LOGIC_VECTOR (63 downto 0) := X"550103070F1F3F7F"
         );
end lpGBT_SetSyncPattern;

architecture Behavioral of lpGBT_SetSyncPattern is

    signal cntr : std_logic_vector (3 downto 0) := B"0000";
    signal ck, pck, dly : std_logic := '0';

    signal SetPat : std_logic_vector (3 downto 0) := B"0000";

begin

    datatxcmdbus(8) <= ck;
    cmd_paraclk <= pck;

    -- Get the parameter data, prepare and send the response:
    process(clk) begin
    if rising_edge(clk) then
        if start = '1' then
            if cntr < 9 then    -- Get the parameter data:
                if pck = '0' and dly = '0' then
                    case cntr is 
                    when B"0000" => SetPat <= cmd_parabyte(3 downto 0);
                    when others => if SetPat(0) = '1' then SyncPattern_UL1(conv_integer(8-cntr)*8+7 downto conv_integer(8-cntr)*8) <= cmd_parabyte; end if;
                                   if SetPat(1) = '1' then SyncPattern_UL2(conv_integer(8-cntr)*8+7 downto conv_integer(8-cntr)*8) <= cmd_parabyte; end if;
                                   if SetPat(2) = '1' then  SyncPattern_DL(conv_integer(8-cntr)*8+7 downto conv_integer(8-cntr)*8) <= cmd_parabyte; end if;
                                   if SetPat(3) = '1' then  SyncPattern_EC(conv_integer(8-cntr)*8+7 downto conv_integer(8-cntr)*8) <= cmd_parabyte; end if;
                    end case;
                    pck <= '1'; dly <= '1';
                elsif pck = '1' then pck <= '0'; dly <= '1'; 
                else pck <= '0'; dly <= '0'; cntr <= cntr + 1; end if;
            elsif cntr < 11 then -- Prepare the response: 
                if ck = '0' then
                    if cntr =  9 then datatxcmdbus(7 downto 0) <= X"00"; end if;
                    if cntr = 10 then datatxcmdbus(7 downto 0) <= X"5C"; end if;
                    ck <= '1';  -- Clock the response byte
                else ck <= '0'; cntr <= cntr + 1; end if;
            else ck <= '0'; pck <= '0'; datatxcmdbus(9) <= '1'; end if; -- Send the response packet
        else 
            ck <= '0'; pck <= '0'; cntr <= B"0000";
            datatxcmdbus(7 downto 0) <= X"00";
            datatxcmdbus(9) <= '0';
        end if; 
    end if;
    end process;

end Behavioral;
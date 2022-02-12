----------------------------------------------------------------------------------
-- Company: DESY
-- Engineer: Artur Boebel
-- 
-- Create Date: 29/07/2019
-- Description: 
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity lpGBT_SetDownELink is
    Port ( clk : in STD_LOGIC;
           start : in STD_LOGIC;
           datatxcmdbus : out STD_LOGIC_VECTOR (9 downto 0) := B"0000000000";
           cmd_paraclk : out STD_LOGIC;
           cmd_parabyte : in STD_LOGIC_VECTOR (7 downto 0);
           Elink_dwn_PatGen_on : out std_logic_vector (7 downto 0) := X"00";
           Elink_dwn_SynGen_on : out std_logic_vector (7 downto 0) := X"00";
           Elink_dwn_inv : out std_logic_vector (7 downto 0) := X"00";
           Elink_dwn_bit_shift : out std_logic_vector (47 downto 0) := X"7DF7DF7DF7DF";
           Elink_dwn_phase : out std_logic_vector (15 downto 0) := X"5555" );
end lpGBT_SetDownELink;

architecture Behavioral of lpGBT_SetDownELink is

    signal cntr : std_logic_vector (3 downto 0) := B"0000";
    signal ck, pck, dly : std_logic := '0';

begin

    datatxcmdbus(8) <= ck;
    cmd_paraclk <= pck;

    -- Get the parameter data, prepare and send the response:
    process(clk) begin
    if rising_edge(clk) then
        if start = '1' then
            if cntr < 13 then    -- Get the parameter data:
                if pck = '0' and dly = '0' then
                    case cntr is 
                    when B"0000" => Elink_dwn_PatGen_on <= cmd_parabyte;
                    when B"0001" => Elink_dwn_SynGen_on <= cmd_parabyte;
                    when B"0010" => Elink_dwn_inv <= cmd_parabyte;
                    when B"1011" => Elink_dwn_phase(15 downto 8) <= cmd_parabyte;
                    when B"1100" => Elink_dwn_phase(7 downto 0) <= cmd_parabyte;
                    when others => Elink_dwn_bit_shift(conv_integer(10-cntr)*6+5 downto conv_integer(10-cntr)*6) <= cmd_parabyte(5 downto 0);
                    end case;
                    pck <= '1'; dly <= '1';
                elsif pck = '1' then pck <= '0'; dly <= '1'; 
                else pck <= '0'; dly <= '0'; cntr <= cntr + 1; end if;
            elsif cntr < 15 then -- Prepare the response: 
                if ck = '0' then
                    if cntr = 13 then datatxcmdbus(7 downto 0) <= X"00"; end if;
                    if cntr = 14 then datatxcmdbus(7 downto 0) <= X"45"; end if;
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

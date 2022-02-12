-- Company: DESY 
-- Engineer: Artur Boebel
-- 
-- Create Date: 18/06/2019
-- Description: Module for setting the ELink parameters, downlink data and bit error count parameters
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity lpGBT_SetElinkData is
    Generic( Response : integer);
    Port ( clk : in STD_LOGIC;
           start : in STD_LOGIC;
           datatxcmdbus : out STD_LOGIC_VECTOR (9 downto 0);
           cmd_paraclk : out STD_LOGIC;
           cmd_parabyte : in STD_LOGIC_VECTOR (7 downto 0);
           Elink_PatGen_on : out std_logic_vector (13 downto 0) := B"00000000000000";
           Elink_SynGen_on : out std_logic_vector (13 downto 0) := B"00000000000000";
           Elink_inv : out std_logic_vector (13 downto 0) := B"00000000000000";
           Elink_bit_shift : out std_logic_vector (83 downto 0) := X"7DF7DF7DF7DF7DF7DF7DF" );
end lpGBT_SetElinkData;

architecture Behavioral of lpGBT_SetElinkData is

    signal cntr : std_logic_vector (4 downto 0) := B"00000";
    signal ck, pck, dly : std_logic := '0';

begin

    datatxcmdbus(8) <= ck;
    cmd_paraclk <= pck;

    -- Get the parameter data, prepare and send the response:
    process(clk) begin
    if rising_edge(clk) then
        if start = '1' then
            if cntr < 20 then    -- Get the parameter data:
                if pck = '0' and dly = '0' then
                    case cntr is
                    when B"00000" => Elink_PatGen_on(13 downto 8) <= cmd_parabyte(5 downto 0);
                    when B"00001" => Elink_PatGen_on(7 downto 0) <= cmd_parabyte;
                    when B"00010" => Elink_SynGen_on(13 downto 8) <= cmd_parabyte(5 downto 0);
                    when B"00011" => Elink_SynGen_on(7 downto 0) <= cmd_parabyte;
                    when B"00100" => Elink_inv(13 downto 8) <= cmd_parabyte(5 downto 0);
                    when B"00101" => Elink_inv(7 downto 0) <= cmd_parabyte;
                    when others => Elink_bit_shift(conv_integer(19-cntr)*6+5 downto conv_integer(19-cntr)*6) <= cmd_parabyte(5 downto 0);
                    end case;
                    pck <= '1'; dly <= '1';
                elsif pck = '1' then pck <= '0'; dly <= '1'; 
                else pck <= '0'; dly <= '0'; cntr <= cntr + 1; end if;
            elsif cntr < 22 then -- Prepare the response: 
                if ck = '0' then
                    if cntr = 20 then datatxcmdbus(7 downto 0) <= X"00"; end if;
                    if cntr = 21 then datatxcmdbus(7 downto 0) <= conv_std_logic_vector(Response, 8); end if;
                    ck <= '1';  -- Clock the response byte
                else ck <= '0'; cntr <= cntr + 1; end if;
            else ck <= '0'; pck <= '0'; datatxcmdbus(9) <= '1'; end if; -- Send the response packet
        else 
            ck <= '0'; pck <= '0'; cntr <= B"00000";
            datatxcmdbus(7 downto 0) <= X"00";
            datatxcmdbus(9) <= '0';
        end if; 
    end if;
    end process;

end Behavioral;

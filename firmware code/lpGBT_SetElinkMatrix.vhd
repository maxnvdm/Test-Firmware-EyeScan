----------------------------------------------------------------------------------
-- Company: DESY
-- Engineer: Artur Boebel
-- 
-- Create Date: 06/05/2020
-- Description: 
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity lpGBT_SetElinkMatrix is
    Port ( clk : in STD_LOGIC;
           start : in STD_LOGIC;
           datatxcmdbus : out STD_LOGIC_VECTOR (9 downto 0) := B"0000000000";
           cmd_paraclk : out STD_LOGIC;
           cmd_parabyte : in STD_LOGIC_VECTOR (7 downto 0);
           ELink1_Inv : out STD_LOGIC_VECTOR (13 downto 0) := B"00000000000000";   -- 14 bit: ELink1 inverter
           ELink1_Mat : out STD_LOGIC_VECTOR (55 downto 0) := X"DCBA9876543210";   -- 14 x 4 bit: ELink1 selector for multiplexing
           ELink2_Inv : out STD_LOGIC_VECTOR (13 downto 0) := B"00000000000000";   -- 14 bit: ELink1 inverter
           ELink2_Mat : out STD_LOGIC_VECTOR (55 downto 0) := X"DCBA9876543210";   -- 14 x 4 bit: ELink1 selector for multiplexing
           ELinkD_Inv : out STD_LOGIC_VECTOR (7 downto 0)  := X"00";     --  8 bit: ELink Downlink inverter
           ELinkD_Mat : out STD_LOGIC_VECTOR (31 downto 0) := X"76543210"  -- 8 x 4 bit: ELink Downlink selector for multiplexing
         );
end lpGBT_SetElinkMatrix;

architecture Behavioral of lpGBT_SetElinkMatrix is

    signal cntr : std_logic_vector (4 downto 0) := B"00000";
    signal ck, pck, dly : std_logic := '0';

begin

    datatxcmdbus(8) <= ck;
    cmd_paraclk <= pck;

    -- Get the parameter data, prepare and send the response:
    process(clk) begin
    if rising_edge(clk) then
        if start = '1' then
            if cntr < 23 then    -- Get the parameter data:
                if pck = '0' and dly = '0' then
                    case cntr is 
                    when B"00000" => ELink1_Mat(55 downto 48) <= cmd_parabyte;
                    when B"00001" => ELink1_Mat(47 downto 40) <= cmd_parabyte;
                    when B"00010" => ELink1_Mat(39 downto 32) <= cmd_parabyte;
                    when B"00011" => ELink1_Mat(31 downto 24) <= cmd_parabyte;
                    when B"00100" => ELink1_Mat(23 downto 16) <= cmd_parabyte;
                    when B"00101" => ELink1_Mat(15 downto 8) <= cmd_parabyte;
                    when B"00110" => ELink1_Mat(7 downto 0) <= cmd_parabyte;
                    when B"00111" => ELink2_Mat(55 downto 48) <= cmd_parabyte;
                    when B"01000" => ELink2_Mat(47 downto 40) <= cmd_parabyte;
                    when B"01001" => ELink2_Mat(39 downto 32) <= cmd_parabyte;
                    when B"01010" => ELink2_Mat(31 downto 24) <= cmd_parabyte;
                    when B"01011" => ELink2_Mat(23 downto 16) <= cmd_parabyte;
                    when B"01100" => ELink2_Mat(15 downto 8) <= cmd_parabyte;
                    when B"01101" => ELink2_Mat(7 downto 0) <= cmd_parabyte;
                    when B"01110" => ELinkD_Mat(31 downto 24) <= cmd_parabyte;
                    when B"01111" => ELinkD_Mat(23 downto 16) <= cmd_parabyte;
                    when B"10000" => ELinkD_Mat(15 downto  8) <= cmd_parabyte;
                    when B"10001" => ELinkD_Mat( 7 downto  0) <= cmd_parabyte;
                    when B"10010" => ELink1_Inv(13 downto 8) <= cmd_parabyte(5 downto 0);
                    when B"10011" => ELink1_Inv(7 downto 0) <= cmd_parabyte;
                    when B"10100" => ELink2_Inv(13 downto 8) <= cmd_parabyte(5 downto 0); 
                    when B"10101" => ELink2_Inv(7 downto 0) <= cmd_parabyte;
                    when B"10110" => ELinkD_Inv <= cmd_parabyte;
                    when others => 
                    end case;
                    pck <= '1'; dly <= '1';
                elsif pck = '1' then pck <= '0'; dly <= '1'; 
                else pck <= '0'; dly <= '0'; cntr <= cntr + 1; end if;
            elsif cntr < 25 then -- Prepare the response: 
                if ck = '0' then
                    if cntr = 23 then datatxcmdbus(7 downto 0) <= X"00"; end if;
                    if cntr = 24 then datatxcmdbus(7 downto 0) <= X"57"; end if;
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
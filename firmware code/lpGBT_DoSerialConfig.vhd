----------------------------------------------------------------------------------
-- Company: DESY 
-- Engineer: Artur Boebel
-- 
-- Create Date: 18/06/2019
-- Description: Module for controlling the serial transmission via IC
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity lpGBT_DoSerialConfig is
    Port ( clk : in STD_LOGIC;
           start : in STD_LOGIC;
           datatxcmdbus : out STD_LOGIC_VECTOR (9 downto 0);
           cmd_paraclk : out STD_LOGIC;
           cmd_parabyte : in STD_LOGIC_VECTOR (7 downto 0);
           ICC_Address_lpGBT : out STD_LOGIC_VECTOR (6 downto 0);
           ICC_NData : out STD_LOGIC_VECTOR (11 downto 0);
           ICC_Addr : out STD_LOGIC_VECTOR (15 downto 0);
           ICC_Din : out STD_LOGIC_VECTOR (7 downto 0);
           ICC_Din_clk : in STD_LOGIC;
           ICC_Dout : in STD_LOGIC_VECTOR (7 downto 0);
           ICC_Dout_clk : in STD_LOGIC;
           ICC_write : out STD_LOGIC := '0';
           ICC_dosend : out STD_LOGIC := '0';
           ICC_busy : in STD_LOGIC );
end lpGBT_DoSerialConfig;

architecture Behavioral of lpGBT_DoSerialConfig is

    signal cntr : std_logic_vector (2 downto 0) := B"000";
    signal pck, dly : std_logic := '0';

begin

    datatxcmdbus(8) <= ICC_Dout_clk when ICC_busy = '1' else '0';
    cmd_paraclk     <= ICC_Din_clk  when ICC_busy = '1' else pck;

    datatxcmdbus(7 downto 0) <= ICC_Dout;
    ICC_Din <= cmd_parabyte;

    process(clk) begin
    if rising_edge(clk) then
        if start = '1' then
            if cntr < 4 then
                if pck = '0' and dly = '0' then
                    case cntr is 
                    when B"000" => ICC_Address_lpGBT <= cmd_parabyte(7 downto 1);
                                   ICC_write <= not cmd_parabyte(0);
                    when B"001" => ICC_NData(11 downto 8) <= cmd_parabyte(3 downto 0);
                    when B"010" => ICC_NData(7 downto 0) <= cmd_parabyte;
                    when B"011" => ICC_Addr(15 downto 8) <= cmd_parabyte;
                    when others =>
                    end case;
                    pck <= '1'; dly <= '1';
                elsif pck = '1' then pck <= '0'; dly <= '1'; 
                else pck <= '0'; dly <= '0'; cntr <= cntr + 1; end if;
            elsif cntr = 4 then 
                ICC_Addr(7 downto 0) <= cmd_parabyte;
                cntr <= B"101";
            elsif cntr = 5 then
                ICC_dosend <= '1';
                if ICC_busy = '1' then cntr <= B"110"; end if;
            elsif cntr = 6 then
                ICC_dosend <= '0';
                if ICC_busy = '0' then cntr <= B"111"; end if;            
            else pck <= '0'; datatxcmdbus(9) <= '1'; end if;
        else 
            cntr <= B"000";
            datatxcmdbus(9) <= '0';
        end if; 
    end if;
    end process;

end Behavioral;

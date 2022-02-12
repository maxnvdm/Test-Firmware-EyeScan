-- Company: DESY 
-- Engineer: Artur Boebel
-- 
-- Create Date: 22/11/2019
-- Description: Module for setting the EC parameters, up- and downlink data and bit error count parameters
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity lpGBT_SetEC is
    Port ( clk : in STD_LOGIC;
       start : in STD_LOGIC;
       datatxcmdbus : out STD_LOGIC_VECTOR (9 downto 0);
       cmd_paraclk : out STD_LOGIC;
       cmd_parabyte : in STD_LOGIC_VECTOR (7 downto 0);
       EC_PatGen_on_up : out std_logic := '0';
       EC_SynGen_on_up : out std_logic := '0';
       EC_inv_up : out std_logic := '0';
       EC_bit_shift_up : out std_logic_vector (5 downto 0) := B"001111";
       EC_PatGen_on_dwn : out std_logic := '0';
       EC_SynGen_on_dwn : out std_logic := '0';
       EC_inv_dwn : out std_logic := '0';
       EC_bit_shift_dwn : out std_logic_vector (5 downto 0) := B"001111";
       EC_phase_shift_dwn : out std_logic_vector (1 downto 0) := B"01" );
end lpGBT_SetEC;

architecture Behavioral of lpGBT_SetEC is

    signal cntr : std_logic_vector (2 downto 0) := B"000";
    signal ck, pck, dly : std_logic := '0';

begin

    datatxcmdbus(8) <= ck;
    cmd_paraclk <= pck;

    -- Get the parameter data, prepare and send the response:
    process(clk) begin
    if rising_edge(clk) then
        if start = '1' then
            if cntr < 4 then    -- Get the parameter data:
                if pck = '0' and dly = '0' then
                    case cntr is 
                    when B"000" => EC_PatGen_on_up <= cmd_parabyte(0);
                                   EC_SynGen_on_up <= cmd_parabyte(1);
                                   EC_inv_up <= cmd_parabyte(2);
                                   EC_PatGen_on_dwn <= cmd_parabyte(4);
                                   EC_SynGen_on_dwn <= cmd_parabyte(5);
                                   EC_inv_dwn <= cmd_parabyte(6);
                    when B"001" => EC_bit_shift_up <= cmd_parabyte(5 downto 0);
                    when B"010" => EC_bit_shift_dwn <= cmd_parabyte(5 downto 0);
                    when B"011" => EC_phase_shift_dwn <= cmd_parabyte(1 downto 0);
                    when others =>
                    end case;
                    pck <= '1'; dly <= '1';
                elsif pck = '1' then pck <= '0'; dly <= '1'; 
                else pck <= '0'; dly <= '0'; cntr <= cntr + 1; end if;
            elsif cntr < 6 then -- Prepare the response: 
                if ck = '0' then
                    if cntr = 4 then datatxcmdbus(7 downto 0) <= X"00"; end if;
                    if cntr = 5 then datatxcmdbus(7 downto 0) <= X"48"; end if;
                    ck <= '1';  -- Clock the response byte
                else ck <= '0'; cntr <= cntr + 1; end if;
            else ck <= '0'; pck <= '0'; datatxcmdbus(9) <= '1'; end if; -- Send the response packet
        else 
            ck <= '0'; pck <= '0'; cntr <= B"000";
            datatxcmdbus(7 downto 0) <= X"00";
            datatxcmdbus(9) <= '0';
        end if; 
    end if;
    end process;

end Behavioral;

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

entity ReadWriteGPIO is
    Port ( clk : in STD_LOGIC;
           start : in STD_LOGIC;
           datatxcmdbus : out STD_LOGIC_VECTOR (9 downto 0) := B"0000000000";
           cmd_paraclk : out STD_LOGIC;
           cmd_parabyte : in STD_LOGIC_VECTOR (7 downto 0);
           GPIO : inout STD_LOGIC_VECTOR (15 downto 0)
         );
end ReadWriteGPIO;

architecture Behavioral of ReadWriteGPIO is

    component IOBUF port (O : OUT STD_LOGIC; I : IN STD_LOGIC; T : IN STD_LOGIC; IO : INOUT STD_LOGIC ); end component;

    signal O : std_logic_vector (15 downto 0) := X"0000";
    signal I : std_logic_vector (15 downto 0) := X"0000";
    signal T : std_logic_vector (15 downto 0) := X"FFFF";

    signal cntr : std_logic_vector (3 downto 0) := B"0000";
    signal ck, pck, dly : std_logic := '0';

begin

    datatxcmdbus(8) <= ck;
    cmd_paraclk <= pck;

    g_GEN_FOR: for j in 0 to 15 generate
        IOBUF_inst : IOBUF port map ( O => O(j), I => I(j), T => T(j), IO => GPIO(j) );
    end generate g_GEN_FOR;

    -- Get the parameter data, prepare and send the response:
    process(clk) begin
    if rising_edge(clk) then
        if start = '1' then
            if cntr < 6 then    -- Get the parameter data:
                if pck = '0' and dly = '0' then
                    case cntr is 
                    when B"000" => I(15 downto 8) <= I(15 downto 8) or cmd_parabyte; T(15 downto 8) <= T(15 downto 8) and not cmd_parabyte; 
                    when B"001" => I(7 downto 0)  <= I(7 downto 0)  or cmd_parabyte; T(7 downto 0)  <= T(7 downto 0)  and not cmd_parabyte; 
                    when B"010" => I(15 downto 8) <= I(15 downto 8) and not cmd_parabyte; T(15 downto 8) <= T(15 downto 8) and not cmd_parabyte;
                    when B"011" => I(7 downto 0)  <= I(7 downto 0)  and not cmd_parabyte; T(7 downto 0)  <= T(7 downto 0)  and not cmd_parabyte;
                    when B"100" => T(15 downto 8) <= T(15 downto 8) or cmd_parabyte;
                    when B"101" => T(7 downto 0)  <= T(7 downto 0)  or cmd_parabyte;
                    when others => 
                    end case;
                    pck <= '1'; dly <= '1';
                elsif pck = '1' then pck <= '0'; dly <= '1'; 
                else pck <= '0'; dly <= '0'; cntr <= cntr + 1; end if;
            elsif cntr < 10 then -- Prepare the response: 
                if ck = '0' then
                    if cntr = 6 then datatxcmdbus(7 downto 0) <= O(15 downto 8); end if;
                    if cntr = 7 then datatxcmdbus(7 downto 0) <= O(7 downto 0);  end if;
                    if cntr = 8 then datatxcmdbus(7 downto 0) <= T(15 downto 8); end if;
                    if cntr = 9 then datatxcmdbus(7 downto 0) <= T(7 downto 0);  end if;
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

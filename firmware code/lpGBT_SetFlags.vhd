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

entity lpGBT_SetFlags is
    Port ( clk : in STD_LOGIC;
           start : in STD_LOGIC;
           datatxcmdbus : out STD_LOGIC_VECTOR (9 downto 0) := B"0000000000";
           cmd_paraclk : out STD_LOGIC;
           cmd_parabyte : in STD_LOGIC_VECTOR (7 downto 0);
           RunBERT : out STD_LOGIC := '0';
           BypassFEC1 : out STD_LOGIC := '0';
           BypassFEC2 : out STD_LOGIC := '0';
           DataUnlock_out : out STD_LOGIC_VECTOR (4 downto 0);
           DataLock_status : in STD_LOGIC_VECTOR (4 downto 0);
           LinkReset : out STD_LOGIC := '0';
           INVERT_DL : out std_logic := '0';
           INVERT_UL1 : out std_logic := '0';
           INVERT_UL2 : out std_logic := '0'
         );
end lpGBT_SetFlags;

architecture Behavioral of lpGBT_SetFlags is

    signal cntr : std_logic_vector (4 downto 0) := B"00000";
    signal ck, pck, dly : std_logic := '0';
    
    signal DataUnlock : std_logic_vector (4 downto 0) := B"00000";

begin

    datatxcmdbus(8) <= ck;
    cmd_paraclk <= pck;
    DataUnlock_out <= DataUnlock;

    -- Get the parameter data, prepare and send the response:
    process(clk) begin
    if rising_edge(clk) then
        if start = '1' then
            if cntr < 2 then    -- Get the parameter data:
                if pck = '0' and dly = '0' then
                    case cntr is 
                    when B"00000" =>
                        INVERT_DL <= cmd_parabyte(6);
                        RunBERT <= cmd_parabyte(4);
                        BypassFEC1 <= cmd_parabyte(0);
                        BypassFEC2 <= cmd_parabyte(1);
                    when B"00001" =>
                        LinkReset <= cmd_parabyte(7);
                        INVERT_UL2 <= cmd_parabyte(6);
                        INVERT_UL1 <= cmd_parabyte(5);
                        DataUnlock <= cmd_parabyte(4 downto 0);
                    when others =>
                    end case;
                    pck <= '1'; dly <= '1';
                elsif pck = '1' then pck <= '0'; dly <= '1'; 
                else pck <= '0'; dly <= '0'; cntr <= cntr + 1; end if;
            elsif cntr < 4 then -- Prepare the response: 
                if ck = '0' then
                    if cntr = 2 then datatxcmdbus(7 downto 0) <= X"00"; end if;
                    if cntr = 3 then datatxcmdbus(7 downto 0) <= X"33"; end if;
                    ck <= '1';  -- Clock the response byte
                else ck <= '0'; cntr <= cntr + 1; end if;
            else ck <= '0'; pck <= '0'; datatxcmdbus(9) <= '1'; end if; -- Send the response packet
        else 
            ck <= '0'; pck <= '0'; cntr <= B"00000";
            datatxcmdbus(7 downto 0) <= X"00";
            datatxcmdbus(9) <= '0';
            DataUnlock <= DataUnlock and DataLock_status;               
        end if; 
    end if;
    end process;

end Behavioral;

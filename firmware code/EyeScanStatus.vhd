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

entity EyeScanStatus is
    Port ( clk : in STD_LOGIC;
       start : in STD_LOGIC;
       datatxcmdbus : out STD_LOGIC_VECTOR (9 downto 0) := B"0000000000";
       cmd_paraclk : out STD_LOGIC;
       cmd_parabyte : in STD_LOGIC_VECTOR (7 downto 0);
       RunScan : out STD_LOGIC;
       GetData_eye_req : out STD_LOGIC;
       GetData_eye_nxt : out STD_LOGIC;
       Max_Prescale : out STD_LOGIC_VECTOR (4 downto 0);
       ScanComplete : in STD_LOGIC;
       GetData_eye_rdy : in STD_LOGIC;
       GetData_eye_cmplt : in STD_LOGIC
     );
end EyeScanStatus;

architecture Behavioral of EyeScanStatus is

    signal cntr : std_logic_vector (1 downto 0) := B"00";
    signal ck, pck, dly : std_logic := '0';

begin

    datatxcmdbus(8) <= ck;
    cmd_paraclk <= pck;

    -- Get the parameter data, prepare and send the response:
    process(clk) begin
    if rising_edge(clk) then
        if start = '1' then
            if cntr < 1 then    -- Get the parameter data:
                if pck = '0' and dly = '0' then
                    case cntr is 
                    when B"00" => RunScan <= cmd_parabyte(7); GetData_eye_req <= cmd_parabyte(6); GetData_eye_nxt <= cmd_parabyte(5); Max_Prescale <= cmd_parabyte(4 downto 0);
                    when others => 
                    end case;
                    pck <= '1'; dly <= '1';
                elsif pck = '1' then pck <= '0'; dly <= '1'; 
                else pck <= '0'; dly <= '0'; cntr <= cntr + 1; end if;
            elsif cntr < 2 then -- Prepare the response: 
                if ck = '0' then
                    datatxcmdbus(7 downto 0) <= "00000" & ScanComplete & GetData_eye_rdy & GetData_eye_cmplt;
                    ck <= '1';  -- Clock the response byte
                else ck <= '0'; cntr <= cntr + 1; end if;
            else ck <= '0'; pck <= '0'; datatxcmdbus(9) <= '1'; end if; -- Send the response packet
        else 
            ck <= '0'; pck <= '0'; cntr <= B"00";
            datatxcmdbus(7 downto 0) <= X"00";
            datatxcmdbus(9) <= '0';
        end if; 
    end if;
    end process;

end Behavioral;

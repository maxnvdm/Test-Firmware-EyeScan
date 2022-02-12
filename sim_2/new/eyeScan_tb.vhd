library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity eyeScan_tb is

end eyeScan_tb;

architecture Behavioural of eyeScan_tb is
    component eyeScan
        port (
        CLK, TXFSMRESETDONE, RXFSMRESETDONE, SOFRST : in std_logic;
        DRPDO : in std_logic_vector (15 downto 0);
        DRPRDY, RunScan, GetData_eye_req, GetData_eye_nxt : in std_logic;
        DRPADDR : out std_logic_vector (8 downto 0);
        DRPWE, DRPEN, ScanComplete, GetData_eye_rdy, GetData_eye_cmplt : out std_logic;
        DRPDI : out std_logic_vector (15 downto 0);
        Max_Prescale : in std_logic_vector (4 downto 0);
        GetData_eye_vertical, GetData_eye_horizontal, GetData_eye_samples, GetData_eye_errors : out std_logic_vector (991 downto 0));
    end component;
    
    signal clk,TXFSMRESETDONE,RXFSMRESETDONE, SOFRST, DRPRDY, RunScan, GetData_eye_req, GetData_eye_nxt : std_logic :='0';
    signal DRPDO : std_logic_vector (15 downto 0) := "0000000000000110"; --0000000001100100
    signal GetData_eye_rdy, GetData_eye_cmplt, ScanComplete : std_logic;
    signal Max_Prescale : std_logic_vector (4 downto 0) :=(others => '0');
    signal GetData_eye_vertical, GetData_eye_horizontal, GetData_eye_samples, GetData_eye_errors : std_logic_vector (991 downto 0);
    signal DRPADDR : std_logic_vector (8 downto 0);
begin 

    UUT: eyeScan port map (
        CLK => clk,
        TXFSMRESETDONE => TXFSMRESETDONE,
        RXFSMRESETDONE => RXFSMRESETDONE,
        SOFRST => SOFRST,
        DRPDO => DRPDO,
        DRPRDY => DRPRDY,
        DRPADDR => DRPADDR,
        RunScan => RunScan,
        ScanComplete => ScanComplete,
        GetData_eye_req => GetData_eye_req,
        GetData_eye_rdy => GetData_eye_rdy,
        GetData_eye_nxt => GetData_eye_nxt,
        GetData_eye_cmplt => GetData_eye_cmplt,
        Max_Prescale => Max_Prescale,
        GetData_eye_vertical => GetData_eye_vertical,
        GetData_eye_horizontal => GetData_eye_horizontal,
        GetData_eye_samples => GetData_eye_samples,
        GetData_eye_errors => GetData_eye_errors);
        
        SOFRST <= '1', '0' after 40ns;
        process
        begin
            clk <= '1';
            wait for 5 ns;
            clk <= '0';
            wait for 5 ns;
            
        end process;
        
        process
        begin
            wait for 5ns;
            if DRPADDR = X"151" then
                DRPDO <= "0000000000000110";
                wait for 20ns;
                DRPDO <= "0000000000000000";
                wait for 20ns;
            else DRPDO <= "0000000001100100";
            end if;        
        end process;
        
        process
        begin
            wait for 100ns;
--            RunScan <= '1';
            DRPRDY <= '1';
        end process;
        
--        process
--        begin
--            wait for 1000ns;
--            if ScanComplete = '1' then
--                GetData_eye_req <= '1';
--            end if;
--        end process;
        
        process
        begin
            wait until (ScanComplete='1');
            GetData_eye_req <='1';
            wait for 20ns;
            GetData_eye_req <='0';
        end process;
        
        process
        begin
            wait until (GetData_eye_rdy ='1');
            wait for 20ns;
            GetData_eye_nxt <='1';
            wait for 10ns;
            GetData_eye_nxt <='0';
        end process;
        
        process
        begin
            wait for 100ns;
            RunScan <= '1';
            wait for 20ns;
            RunScan <= '0';
            wait;
        end process;
        
end Behavioural;
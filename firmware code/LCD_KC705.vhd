----------------------------------------------------------------------------------
-- Company: DESY 
-- Engineer: Artur Boebel
-- 
-- Create Date: 27/05/2019
-- Description: Module for accessing the 16x2 LCD on the KC705
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

--use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VComponents.all;

entity LCD_KC705 is
    Generic( CLK_FREQ_MHZ_IN : integer := 200 );
    Port ( clk : in STD_LOGIC;
           dclk : in STD_LOGIC;
           cmd : in STD_LOGIC;
           data_in : in STD_LOGIC_VECTOR (7 downto 0);
           busy : out STD_LOGIC;
           LCD_E : out STD_LOGIC;
           LCD_RW : out STD_LOGIC;
           LCD_RS : out STD_LOGIC;
           LCD_DB : out STD_LOGIC_VECTOR(3 downto 0) );
end LCD_KC705;

architecture Behavioral of LCD_KC705 is

    signal cntr : std_logic_vector(17 downto 0) := b"000000000000000000";
    signal data_buf : std_logic_vector(7 downto 0) := x"00";
    signal step : std_logic_vector(2 downto 0) := b"000";
    signal busy_out, cmd_buf : std_logic := '0';

begin
    LCD_RW <= '0';
    LCD_RS <= not cmd_buf;
    busy <= dclk or busy_out;

    -- We build our own, primitive processor for the data transfer to the LCD (control/data write):
    process(clk) begin
    if rising_edge(clk) then
        if dclk = '1' and busy_out = '0' then                                 -- Start processing the task:
            busy_out <= '1';
            step <= b"101";
            data_buf <= data_in;
            cmd_buf <= cmd;
        end if;
        if cntr > 0 then cntr <= cntr - 1;
        elsif step > 0 then
            case step is
                when b"101" => LCD_E <= '0'; LCD_DB <= data_buf(7 downto 4);  -- Set high nibble of data to LCD_DB 
                when b"100" => LCD_E <= '1';                                  -- Set LCD_E = 1
                when b"011" => LCD_E <= '0'; LCD_DB <= data_buf(3 downto 0);  -- Set LCD_E = 0, low nibble to LCD_DB
                when b"010" => LCD_E <= '1';                                  -- Set LCD_E = 1
                when b"001" => LCD_E <= '0';                                  -- Set LCD_E = 0
                when others =>
            end case;
            if cmd_buf = '1' then
                cntr <= conv_std_logic_vector(CLK_FREQ_MHZ_IN*1310,18);       -- Wait some ms (command)
            else
                cntr <= conv_std_logic_vector(CLK_FREQ_MHZ_IN*50,18);         -- Wait some µs (data)
            end if;
            step <= step - 1;
        elsif dclk = '0' then busy_out <= '0'; end if;                        -- Task finished.
    end if;
    end process;

end Behavioral;

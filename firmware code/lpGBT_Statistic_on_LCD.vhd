----------------------------------------------------------------------------------
-- Company: DESY 
-- Engineer: Artur Boebel
-- 
-- Create Date: 31/05/2019
-- Description: Displays a 256bit wide vector on the LCD   
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

--use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VComponents.all;

entity lpGBT_Statistic_on_LCD is
    Generic( CLK_FREQ_MHZ_IN : integer := 100 );
    Port ( clk : in STD_LOGIC;
           uplink1_clk160 : in STD_LOGIC;
           uplink1_clk_en : in STD_LOGIC;
           uplink1_aligned : in STD_LOGIC;
           uplink1_CRCOK : in STD_LOGIC;
           uplink1data_in : in STD_LOGIC_VECTOR (233 downto 0);
           uplink2_clk160 : in STD_LOGIC;
           uplink2_clk_en : in STD_LOGIC;
           uplink2_aligned : in STD_LOGIC;
           uplink2_CRCOK : in STD_LOGIC;
           uplink2data_in : in STD_LOGIC_VECTOR (233 downto 0);
           LCD_E : out STD_LOGIC;
           LCD_RW : out STD_LOGIC;
           LCD_RS : out STD_LOGIC;
           LCD_DB : out STD_LOGIC_VECTOR(3 downto 0) );
end lpGBT_Statistic_on_LCD;

architecture Behavioral of lpGBT_Statistic_on_LCD is

    type t_array16x8 is array (0 to 15) of STD_LOGIC_VECTOR(7 downto 0);
    constant HexToAscii : t_array16x8 := (
        X"30", X"31", X"32", X"33", X"34", X"35", X"36", X"37", X"38", X"39", X"41", X"42", X"43", X"44", X"45", X"46" );

    signal cntr : std_logic_vector(5 downto 0) := B"110000"; -- Initial count: 48, to initialize LCD at begin.
    signal delay : std_logic_vector(19 downto 0);
    signal DoDisplay : STD_LOGIC := '1';
    signal DoDisplay_buf1, DoDisplay_buf2 : STD_LOGIC := '0';
    signal cmd, dclk, lcd_busy : std_logic := '0';
    signal lcd_data : std_logic_vector(7 downto 0) := x"00";

    signal uplink1_aligned_buf : STD_LOGIC := '0';
    signal uplink1_CRCOK_buf : STD_LOGIC := '0';
    signal uplink1data_in_buf : STD_LOGIC_VECTOR (233 downto 0);
    signal uplink1_buffered : STD_LOGIC := '0';
    
    signal uplink2_aligned_buf : STD_LOGIC := '0';
    signal uplink2_CRCOK_buf : STD_LOGIC := '0';
    signal uplink2data_in_buf : STD_LOGIC_VECTOR (233 downto 0);
    signal uplink2_buffered : STD_LOGIC := '0';

begin

    -- lcd interface:
    lcd_inst: entity work.LCD_KC705 generic map (CLK_FREQ_MHZ_IN => CLK_FREQ_MHZ_IN) port map(
               clk => clk,
               dclk => dclk,
               cmd => cmd,
               data_in => lcd_data,
               busy => lcd_busy, 
               LCD_E => LCD_E, 
               LCD_RW => LCD_RW,
               LCD_RS => LCD_RS,
               LCD_DB => LCD_DB );    

    -- Data Buffering from uplink #1:
    process(uplink1_clk160) begin
    if rising_edge(uplink1_clk160) then
        if uplink1_clk_en = '1' then
            DoDisplay_buf1 <= DoDisplay;
            if DoDisplay_buf1 = '1' then
                if uplink1_buffered = '0' then
                    uplink1_aligned_buf <= uplink1_aligned;
                    uplink1_CRCOK_buf <= uplink1_CRCOK;
                    uplink1data_in_buf <= uplink1data_in;
                    uplink1_buffered <= '1';
                end if;
            else uplink1_buffered <= '0';
            end if;
        end if;
    end if;
    end process;

    -- Data Buffering from uplink #2:
    process(uplink2_clk160) begin
    if rising_edge(uplink2_clk160) then
        if uplink2_clk_en = '1' then
            DoDisplay_buf2 <= DoDisplay;
            if DoDisplay_buf2 = '1' then
                if uplink2_buffered = '0' then
                    uplink2_aligned_buf <= uplink2_aligned;
                    uplink2_CRCOK_buf <= uplink2_CRCOK;
                    uplink2data_in_buf <= uplink2data_in;
                    uplink2_buffered <= '1';
                end if;
            else uplink2_buffered <= '0';
            end if;
        end if;
    end if;
    end process;

    -- Display uplink data (just one nibble each channel) on LCD: First line #1, second line #2:
    process(clk) begin
    if rising_edge(clk) then
        if DoDisplay = '1' and uplink1_buffered = '1' and uplink2_buffered = '1' and lcd_busy = '0' and dclk = '0' then
            if cntr > 47 or cntr = 0 or cntr = 17 then cmd <= '1'; else cmd <= '0'; end if;
            case cntr is
            -- LCD first initial init:
            when B"110000" => lcd_data <= x"02";    --0x02 Init: 4 bit mode
            when b"110001" => lcd_data <= x"28";    --0x28 Init: Set 5x7 mode for characters
            when b"110010" => lcd_data <= x"0C";    --0x0C Init: display on, cursor off
            when b"110011" => lcd_data <= x"01";    --0x01 Clear display
            -- display upper line:
            when b"000000" => lcd_data <= x"80";    --0x80 Move the cursor to the beginning of the upper line 
            when b"000001" => lcd_data <= x"31";    --0x31 = 49 = "1" 
            when b"000010" => if uplink1data_in_buf(231 downto 230) = B"00" then lcd_data <= x"3A"; else lcd_data <= x"2E"; end if;  --0x3A = 58 = ":", 0x2E = 46 = "."
            -- display lower line:
            when b"010001" => lcd_data <= x"C0";    --0xC0 Move the cursor to the beginning of the lower line
            when b"010010" => lcd_data <= x"32";    --0x32 = 50 = "2" 
            when b"010011" => if uplink2data_in_buf(231 downto 230) = B"00" then lcd_data <= x"3A"; else lcd_data <= x"2E"; end if;  --0x3A = 58 = ":", 0x2E = 46 = "." 
            when others =>
                if cntr >= 3 and cntr < 17 then
                    if uplink1_aligned_buf = '1' then --and uplink1_CRCOK_buf = '1' then
                        lcd_data <= HexToAscii(conv_integer(uplink1data_in_buf(conv_integer(16-cntr)*16+3 downto conv_integer(16-cntr)*16)));
                    else lcd_data <= X"2D"; end if; --0x2D = 45 = "-"
                elsif cntr >= 20 and cntr < 34 then
                    if uplink2_aligned_buf = '1' then --and uplink2_CRCOK_buf = '1' then
                        lcd_data <= HexToAscii(conv_integer(uplink2data_in_buf(conv_integer(33-cntr)*16+3 downto conv_integer(33-cntr)*16)));
                    else lcd_data <= X"2D"; end if; --0x2D = 45 = "-"
                end if;
            end case;
            dclk <= '1';
            if cntr >= 51 then cntr <= B"000000";
            elsif cntr >= 33 then cntr <= B"000000"; delay <= X"FFFFF"; DoDisplay <= '0';
            else cntr <= cntr + 1; end if;
        elsif lcd_busy = '1' then
            dclk <= '0';
        elsif DoDisplay = '0' and lcd_busy = '0' then
            if delay > 0 then delay <= delay - 1;       -- wait some time until next refresh.
            else DoDisplay <= '1'; end if;
        end if;
    end if;
    end process;

end Behavioral;

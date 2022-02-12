----------------------------------------------------------------------------------
-- Company: DESY 
-- Engineer: Artur Boebel
-- 
-- Create Date: 18/06/2019
-- Description: Receiving module for UART commands
-- Minimum length: 6 bytes, maximum length: 516 bytes.
-- Receiving format:  0x01,  Len[15:8],  Len[7:0],  Cmd[15:8],  Cmd[7:0],  Data...[* Len-2],  CRC8   
-- Reception will be aborted after 20ms blank time.
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity cmd_rx is
    Generic( CDIV : integer; MHZ : integer; RAM_LEN : integer);
    Port ( clk : in STD_LOGIC;                                  -- clk input for output state machne (e.g. 100 MHz)
           clk_com : in STD_LOGIC;                              -- clk input for command and UART RX logic (e.g. 12 MHz)
           rxd : in STD_LOGIC;                                  -- UART RX pin
           rxenable : in STD_LOGIC;                             -- enable input for new command
           received_out : out STD_LOGIC;                        -- command received output
           cmdword_out : out STD_LOGIC_VECTOR(15 downto 0);     -- first two bytes is command-word
           bytenum_out : out STD_LOGIC_VECTOR(15 downto 0);
           parabyteclk_in : in STD_LOGIC;                       -- data clock for clocking out the parameter bytes
           parabyte_out : out STD_LOGIC_VECTOR(7 downto 0) );   -- parameter data output bus 
end cmd_rx;
architecture Behav of cmd_rx is

    function SEL_WIDTH(NUM: integer) return integer is begin
        if NUM > 2097151 then return 22;
        elsif NUM > 1048575 then return 21;
        elsif NUM > 524287 then return 20;
        elsif NUM > 262143 then return 19;
        elsif NUM > 131071 then return 18;
        elsif NUM > 65535 then return 17;
        elsif NUM > 32767 then return 16;
        elsif NUM > 16383 then return 15;
        elsif NUM > 8191 then return 14;
        elsif NUM > 4095 then return 13;
        elsif NUM > 2047 then return 12;
        elsif NUM > 1023 then return 11;
        elsif NUM > 511 then return 10;
        elsif NUM > 255 then return 9;
        elsif NUM > 127 then return 8;
        elsif NUM > 63 then return 7;
        elsif NUM > 31 then return 6;
        elsif NUM > 15 then return 5;
        elsif NUM > 7 then return 4;
        elsif NUM > 3 then return 3;
        else return 2;
        end if;
    end function SEL_WIDTH;
        
    constant MCNT_W: integer := SEL_WIDTH(MHZ*20000);

    type BYTE_ARRAY is array(RAM_LEN-1 downto 0) of STD_LOGIC_VECTOR(7 downto 0); 
    signal RxDataRam: BYTE_ARRAY; 

    signal busy, rdy, rxd_ena: STD_LOGIC; 
    signal received, rdy_old: STD_LOGIC := '0'; 

    signal data: STD_LOGIC_VECTOR(7 downto 0); 
    signal DCnt, OCnt: STD_LOGIC_VECTOR(15 downto 0) := X"0000"; 
    signal crc_calc: STD_LOGIC := '0'; 
    signal crc_first: STD_LOGIC := '0'; 
    signal crc_in: STD_LOGIC_VECTOR(7 downto 0) := B"00000000"; 
    signal crc_out: STD_LOGIC_VECTOR(7 downto 0);
    signal is_receiving: STD_LOGIC := '0';
    signal timeout: STD_LOGIC_VECTOR(MCNT_W-1 downto 0);

    signal bytenum : STD_LOGIC_VECTOR(15 downto 0) := X"0000";
    signal cmdword : STD_LOGIC_VECTOR(15 downto 0) := X"0000";
    
    signal parabyteclk_old: STD_LOGIC := '0';

begin

    rxd_ena <= rxd when rxenable = '1' else '1';

    uart_rx_inst: entity work.uart_rx generic map (CDIV => CDIV) port map(clk => clk_com, rxd_in => rxd_ena, busy_out => busy, rdy => rdy, data => data); 
    crc_inst: entity work.CRC8 port map(clk => clk_com, calc => crc_calc, first => crc_first, inp => crc_in, outp_out => crc_out);

    received_out <= received;

    process(clk) begin
    if rising_edge(clk) then
        if is_receiving = '0' then
            parabyte_out <= RxDataRam(conv_integer(OCnt));
            if parabyteclk_in = '1' and parabyteclk_old = '0' then
                OCnt <= OCnt + 1;
            end if;
            parabyteclk_old <= parabyteclk_in;
        else
            parabyte_out <= X"00";
            OCnt <= (others => '0'); 
        end if;
    end if;
    end process;

    process(clk_com) begin
    if rising_edge(clk_com) then
        if rdy = '1' and rdy_old = '0' then                 -- byte received:
            if is_receiving = '0' then
                if rxenable = '1' and data = X"01" then     -- first byte: Must be X"01", then start receiving:
                    received <= '0'; 
                    is_receiving <= '1';
                    crc_first <= '1';
                    bytenum <= X"0000";
                    cmdword <= X"0000";
                    DCnt <= X"0000";
                end if;
            else
                if rxenable = '0' then
                    is_receiving <= '0';
                elsif DCnt = X"0000" then                     -- second byte: Data length [15:8]:
                    bytenum(15 downto 8) <= data;
                    DCnt <= X"0001";
                elsif DCnt = X"0001" then                  -- third byte: Data length [7:0]:
                    bytenum(7 downto 0) <= data;
                    DCnt <= X"0002";
                elsif DCnt = (bytenum + 2) then            -- last byte: Receiving finished:
                    is_receiving <= '0';
                    if crc_out = data then                  -- CRC8 ok: Output data:
                        bytenum_out <= bytenum;
                        cmdword_out <= cmdword;
                        received <= '1';                
                    end if;
                elsif DCnt = X"0002" then
                    cmdword(15 downto 8) <= data;
                    DCnt <= X"0003";
                elsif DCnt = X"0003" then
                    cmdword(7 downto 0) <= data;
                    DCnt <= X"0004";
                else
                    RxDataRam(conv_integer(DCnt)-4) <= data;
                    DCnt <= DCnt + 1;
                end if;
                crc_first <= '0';                
            end if;
            crc_in <= data;
            crc_calc <= '1';
            timeout <= (others => '0');
        else
            crc_calc <= '0';
            if timeout < conv_std_logic_vector(MHZ*20000, MCNT_W) then
                timeout <= timeout + 1;
            else
                is_receiving <= '0';
            end if;
        end if;
        rdy_old <= rdy;
    end if;
    end process;

end Behav;

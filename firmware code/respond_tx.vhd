----------------------------------------------------------------------------------
-- Company: DESY 
-- Engineer: Artur Boebel
-- 
-- Create Date: 18/06/2019
-- Description: Transmitting module for UART responses
-- Minimum length: 4 bytes, maximum length: 514 bytes.
-- Transmitting format:  0x01,  Len[15:8],  Len[7:0],  Data...[* Len],  CRC8   
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity respond_tx is
    Generic( CDIV : integer; RAM_LEN : integer);
    Port ( clk : in STD_LOGIC;                              -- clk input for output state machne (e.g. 100 MHz)
           clk_com : in STD_LOGIC;                          -- clk input for command and UART TX logic (e.g. 12 MHz)
           txd : out STD_LOGIC;                             -- UART TX pin
           dotx_in : in STD_LOGIC;                          -- 0 to 1 starts transmission of data packet
           dataclk_in : in STD_LOGIC;                       -- 0 to 1 clocks byte data into buffer ram
           databyte_in : in STD_LOGIC_VECTOR (7 downto 0);  -- Data byte input bus
           txbusy_out : out STD_LOGIC);                     -- Busy output flag
end respond_tx;

architecture Behavioral of respond_tx is

    type BYTE_ARRAY is array(RAM_LEN-1 downto 0) of STD_LOGIC_VECTOR(7 downto 0); 
    signal TxDataRam: BYTE_ARRAY; 

    signal is_transmitting, was_transmitting: STD_LOGIC := '0';
    signal tx_busy: STD_LOGIC;
    signal snd, crc_first, dataclk_old, dotx_old: STD_LOGIC := '0';
    signal crc_out: STD_LOGIC_VECTOR (7 downto 0);
    signal tx_byte: STD_LOGIC_VECTOR (7 downto 0) := X"00";
    signal DCnt, OCnt: STD_LOGIC_VECTOR(15 downto 0) := X"0000"; 

begin

    uart_tx_inst: entity work.uart_tx generic map(CDIV => CDIV) port map(clk => clk_com, snd => snd, data => tx_byte, busy_out => tx_busy, txd => txd);
    crc_inst: entity work.CRC8 port map(clk => clk_com, calc => snd, first => crc_first, inp => tx_byte, outp_out => crc_out);

    txbusy_out <= is_transmitting;

    process(clk) begin
    if rising_edge(clk) then
        if is_transmitting = '0' then
            if was_transmitting = '0' then
                if dataclk_in = '1' and dataclk_old = '0' then
                    TxDataRam(conv_integer(DCnt)) <= databyte_in;
                    DCnt <= DCnt + 1;
                end if;
                dataclk_old <= dataclk_in;
            else
                was_transmitting <= '0';
                DCnt <= X"0000"; 
            end if;
        else
            was_transmitting <= '1';
        end if;
    end if;
    end process;

    process(clk_com) begin
    if rising_edge(clk_com) then
        if is_transmitting = '0' then
            if tx_busy = '0' then
                if dotx_in = '1' then
                    if dotx_old = '0' then  -- Send first byte = X"01":
                        crc_first <= '1';
                        tx_byte <= X"01";
                        OCnt <= X"0000";
                        is_transmitting <= '1';
                        snd <= '1';
                        dotx_old <= '1';
                    end if;
                else
                    dotx_old <= '0';
                end if;
            else
                snd <= '0';
            end if;
        else
            if tx_busy = '0' then
                if snd = '0' then
                    if OCnt = X"0000" then                  -- Send second byte: Data length [15:8]:
                        tx_byte <= DCnt(15 downto 8);
                        OCnt <= X"0001";
                    elsif OCnt = X"0001" then               -- Send third byte: Data length [7:0]:
                        tx_byte <= DCnt(7 downto 0);
                        OCnt <= X"0002";
                    elsif OCnt > DCnt + 1 then               -- Send last byte: CRC8 and finish transmission
                        tx_byte <= crc_out;
                        is_transmitting <= '0';
                    else                                    -- Send data byte:
                        tx_byte <= TxDataRam(conv_integer(OCnt)-2);
                        OCnt <= OCnt + 1;
                    end if;
                    snd <= '1';
                end if;
            else
                if snd = '0' then crc_first <= '0'; end if;
                snd <= '0';
            end if;
        end if;
    end if;
    end process;

end Behavioral;

----------------------------------------------------------------------------------
-- Company: DESY 
-- Engineer: Artur Boebel
-- 
-- Create Date: 18/06/2019
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity uart_tx is
    Generic( CDIV : integer );
    Port ( clk : in STD_LOGIC;
           snd : in STD_LOGIC;
           data : in STD_LOGIC_VECTOR (7 downto 0);
           busy_out : out STD_LOGIC;
           txd : out STD_LOGIC := '1' );
end uart_tx;
architecture Behav of uart_tx is

    function SEL_WIDTH(NUM: integer) return integer is begin
        if NUM > 32767 then return 16;
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
    
    constant ECNT_W : integer := SEL_WIDTH(CDIV);

    signal ecnt: STD_LOGIC_VECTOR(ECNT_W-1 downto 0); 
    signal bitcnt: STD_LOGIC_VECTOR(3 downto 0); 
    signal snd_old: STD_LOGIC := '0';
    signal busy: STD_LOGIC := '0';

begin

    busy_out <= busy;

    process(clk) begin
    if rising_edge(clk) then
        if busy = '0' then
            if snd = '1' then                           -- Start transmission:
                if snd_old = '0' then
                    ecnt <= conv_std_logic_vector(CDIV-2,ECNT_W);
                    busy <= '1'; txd <= '0'; bitcnt <= X"0";
                    snd_old <= '1';
                end if;
            else snd_old <= '0';
            end if;
        else
            if bitcnt = 0 then
                txd <= '0';                             -- Start bit
            elsif bitcnt >= 1 and bitcnt < 9 then
                txd <= data(conv_integer(bitcnt)-1);    -- Data bit
            else
                txd <= '1';                             -- Stop / idle bit
            end if;
            if ecnt = 0 then
                if bitcnt < 9 then
                    if bitcnt < 8 then
                        ecnt <= conv_std_logic_vector(CDIV-1,ECNT_W);
                    else
                        ecnt <= conv_std_logic_vector(CDIV-2,ECNT_W);
                    end if;
                    bitcnt <= bitcnt + 1;
                else
                    busy <= '0';                        -- Transmission finished
                end if;
            else ecnt <= ecnt - 1; end if;
            if snd = '0' then snd_old <= '0'; end if;
        end if;
    end if;
    end process;

end Behav;

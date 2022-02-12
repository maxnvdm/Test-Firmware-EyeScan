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

entity uart_rx is
    Generic( CDIV : integer );
    Port ( clk : in STD_LOGIC;
           rxd_in : in STD_LOGIC;
           busy_out : out STD_LOGIC;
           rdy : out STD_LOGIC;
           data : out STD_LOGIC_VECTOR (7 downto 0) );
end uart_rx;

architecture Behav of uart_rx is

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
        
    constant ECNT_W: integer := SEL_WIDTH(CDIV);

    signal ecnt: STD_LOGIC_VECTOR(ECNT_W-1 downto 0) := (others => '0'); 
    signal bitcnt: STD_LOGIC_VECTOR(3 downto 0) := X"0"; 
    signal busy: STD_LOGIC := '0';
    signal rxd: STD_LOGIC := '1';

begin

    process(clk) begin
    if rising_edge(clk) then
        rxd <= rxd_in;
        if busy = '1' then
            if ecnt = 0 then
                if bitcnt = 0 then
                    busy <= not rxd;
                    rdy <= '0';
                    bitcnt <= X"1";
                elsif bitcnt = 9 then
                    rdy <= rxd;
                    busy <= '0';
                else
                    data(conv_integer(bitcnt)-1) <= rxd;
                    rdy <= '0';
                    busy <= '1';
                    bitcnt <= bitcnt + 1;
                end if;
                ecnt <= conv_std_logic_vector(CDIV-1,ECNT_W);
            else
                ecnt <= ecnt - 1;
            end if;
        else
            if rxd = '0' then
                busy <= '1';
                bitcnt <= X"0";
            end if;
            ecnt <= conv_std_logic_vector(CDIV/2-1,ECNT_W);
        end if;
    end if;
    end process;

    busy_out <= busy;

end Behav;

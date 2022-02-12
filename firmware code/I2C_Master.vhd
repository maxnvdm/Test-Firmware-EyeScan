library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

Library UNISIM;
use UNISIM.vcomponents.all;

entity I2C_Master is
    Generic( CDIV : integer );
    Port ( clk : in STD_LOGIC;
           addr : in STD_LOGIC_VECTOR(6 downto 0);
           numbytes : in STD_LOGIC_VECTOR(7 downto 0);
           preprepstart : in STD_LOGIC;
           do_read : in STD_LOGIC;
           do_write : in STD_LOGIC;
           data_strobe : out STD_LOGIC := '0';
           data_out : out STD_LOGIC_VECTOR(7 downto 0);
           data_in : in STD_LOGIC_VECTOR(7 downto 0);
           busy_out : out STD_LOGIC;
           ack_ok : out STD_LOGIC;
           scl_b_ok : out STD_LOGIC;
           sda_b_ok : out STD_LOGIC;
           scl_e_ok : out STD_LOGIC;
           sda_e_ok : out STD_LOGIC;
           scl : inout STD_LOGIC := 'Z';
           sda : inout STD_LOGIC := 'Z'
    );
end I2C_Master;

architecture Behavioral of I2C_Master is

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
    
    signal busy_w, busy_r : std_logic := '0';
    signal ecnt: STD_LOGIC_VECTOR(ECNT_W-1 downto 0); 
    signal bitcnt: STD_LOGIC_VECTOR(7 downto 0); 
    signal bytecnt: STD_LOGIC_VECTOR(7 downto 0);
    signal byte_red: STD_LOGIC_VECTOR(7 downto 0); 

begin

    busy_out <= busy_w or busy_r;

    process(clk) begin
    if rising_edge(clk) then
        if do_write = '1' and busy_w = '0' and busy_r = '0' then
            busy_w <= '1';
            bytecnt <= numbytes;
            bitcnt <= (others => '0');
            ecnt <= (others => '0');
            ack_ok <= '1';
            scl_b_ok <= '1';
            sda_b_ok <= '1';
            scl_e_ok <= '1';
            sda_e_ok <= '1';
        elsif do_read = '1' and busy_r = '0' and busy_w = '0' then
            busy_r <= '1';
            bytecnt <= numbytes;
            bitcnt <= (others => '0');
            ecnt <= (others => '0');
            ack_ok <= '1';
            scl_b_ok <= '1';
            sda_b_ok <= '1';
            scl_e_ok <= '1';
            sda_e_ok <= '1';
        end if;
        if busy_w = '1' then
            if ecnt = 0 then
                case bitcnt is
                when X"00" => if sda = '0' then sda_b_ok <= '0'; end if; if scl = '0' then scl_b_ok <= '0'; end if; sda <= '0';
                when X"01" => scl <= '0';
                when X"02" => if addr(6) = '0' then sda <= '0'; else sda <= 'Z'; end if;
                when X"03" => scl <= 'Z';
                when X"04" => scl <= '0';
                when X"05" => if addr(5) = '0' then sda <= '0'; else sda <= 'Z'; end if;
                when X"06" => scl <= 'Z';
                when X"07" => scl <= '0';
                when X"08" => if addr(4) = '0' then sda <= '0'; else sda <= 'Z'; end if;
                when X"09" => scl <= 'Z';
                when X"0A" => scl <= '0';
                when X"0B" => if addr(3) = '0' then sda <= '0'; else sda <= 'Z'; end if;
                when X"0C" => scl <= 'Z';
                when X"0D" => scl <= '0';
                when X"0E" => if addr(2) = '0' then sda <= '0'; else sda <= 'Z'; end if;
                when X"0F" => scl <= 'Z';
                when X"10" => scl <= '0';
                when X"11" => if addr(1) = '0' then sda <= '0'; else sda <= 'Z'; end if;
                when X"12" => scl <= 'Z';
                when X"13" => scl <= '0';
                when X"14" => if addr(0) = '0' then sda <= '0'; else sda <= 'Z'; end if;
                when X"15" => scl <= 'Z';
                when X"16" => scl <= '0';
                when X"17" => sda <= '0';  -- write
                when X"18" => scl <= 'Z';
                when X"19" => scl <= '0';
                when X"1A" => sda <= 'Z';
                when X"1B" => scl <= 'Z'; data_strobe <= '1'; if sda = '1' then ack_ok <= '0'; end if;
                when X"1C" => scl <= '0';
                when X"1D" => if data_in(7) = '0' then sda <= '0'; else sda <= 'Z'; end if; data_strobe <= '0';
                when X"1E" => scl <= 'Z';
                when X"1F" => scl <= '0';
                when X"20" => if data_in(6) = '0' then sda <= '0'; else sda <= 'Z'; end if;
                when X"21" => scl <= 'Z';
                when X"22" => scl <= '0';
                when X"23" => if data_in(5) = '0' then sda <= '0'; else sda <= 'Z'; end if;
                when X"24" => scl <= 'Z';
                when X"25" => scl <= '0';
                when X"26" => if data_in(4) = '0' then sda <= '0'; else sda <= 'Z'; end if;
                when X"27" => scl <= 'Z';
                when X"28" => scl <= '0';
                when X"29" => if data_in(3) = '0' then sda <= '0'; else sda <= 'Z'; end if;
                when X"2A" => scl <= 'Z';
                when X"2B" => scl <= '0';
                when X"2C" => if data_in(2) = '0' then sda <= '0'; else sda <= 'Z'; end if;
                when X"2D" => scl <= 'Z';
                when X"2E" => scl <= '0';
                when X"2F" => if data_in(1) = '0' then sda <= '0'; else sda <= 'Z'; end if;
                when X"30" => scl <= 'Z';
                when X"31" => scl <= '0';
                when X"32" => if data_in(0) = '0' then sda <= '0'; else sda <= 'Z'; end if;
                when X"33" => scl <= 'Z';
                when X"34" => scl <= '0';
                when X"35" => sda <= 'Z';
                when X"36" => scl <= 'Z'; if sda = '1' then ack_ok <= '0'; end if;
                when X"37" => scl <= '0';
                when X"38" => if preprepstart = '0' then sda <= '0'; else sda <= 'Z'; end if;   -- STOP ('0') or REPEATED START ('Z')
                when X"39" => scl <= 'Z'; 
                when X"3A" => sda <= 'Z'; 
                when X"3B" => if sda = '0' then sda_e_ok <= '0'; end if; if scl = '0' then scl_e_ok <= '0'; end if; sda <= 'Z'; busy_w <= '0';
                when others =>
                end case;
                if bitcnt = X"35" then
                    if bytecnt > 1 then bytecnt <= bytecnt - 1; bitcnt <= X"1B"; else bitcnt <= X"36"; end if;
                else bitcnt <= bitcnt + 1; end if;
                ecnt <= conv_std_logic_vector(CDIV, ECNT_W);
            else
                ecnt <= ecnt - 1;
            end if;
        elsif busy_r = '1' then
            if ecnt = 0 then
                case bitcnt is
                when X"00" => if sda = '0' then sda_b_ok <= '0'; end if; if scl = '0' then scl_b_ok <= '0'; end if; sda <= '0';
                when X"01" => scl <= '0';
                when X"02" => if addr(6) = '0' then sda <= '0'; else sda <= 'Z'; end if;
                when X"03" => scl <= 'Z';
                when X"04" => scl <= '0';
                when X"05" => if addr(5) = '0' then sda <= '0'; else sda <= 'Z'; end if;
                when X"06" => scl <= 'Z';
                when X"07" => scl <= '0';
                when X"08" => if addr(4) = '0' then sda <= '0'; else sda <= 'Z'; end if;
                when X"09" => scl <= 'Z';
                when X"0A" => scl <= '0';
                when X"0B" => if addr(3) = '0' then sda <= '0'; else sda <= 'Z'; end if;
                when X"0C" => scl <= 'Z';
                when X"0D" => scl <= '0';
                when X"0E" => if addr(2) = '0' then sda <= '0'; else sda <= 'Z'; end if;
                when X"0F" => scl <= 'Z';
                when X"10" => scl <= '0';
                when X"11" => if addr(1) = '0' then sda <= '0'; else sda <= 'Z'; end if;
                when X"12" => scl <= 'Z';
                when X"13" => scl <= '0';
                when X"14" => if addr(0) = '0' then sda <= '0'; else sda <= 'Z'; end if;
                when X"15" => scl <= 'Z';
                when X"16" => scl <= '0';
                when X"17" => sda <= 'Z';  -- read
                when X"18" => scl <= 'Z';
                when X"19" => scl <= '0';
                when X"1A" => sda <= 'Z';
                when X"1B" => scl <= 'Z'; if sda = '1' then ack_ok <= '0'; end if;  
                when X"1C" => scl <= '0';
                when X"1D" => scl <= 'Z'; data_strobe <= '0';
                when X"1E" => scl <= '0'; byte_red(7) <= sda;
                when X"1F" => scl <= 'Z';
                when X"20" => scl <= '0'; byte_red(6) <= sda;
                when X"21" => scl <= 'Z';
                when X"22" => scl <= '0'; byte_red(5) <= sda;
                when X"23" => scl <= 'Z';
                when X"24" => scl <= '0'; byte_red(4) <= sda;
                when X"25" => scl <= 'Z';
                when X"26" => scl <= '0'; byte_red(3) <= sda;
                when X"27" => scl <= 'Z';
                when X"28" => scl <= '0'; byte_red(2) <= sda;
                when X"29" => scl <= 'Z';
                when X"2A" => scl <= '0'; byte_red(1) <= sda;
                when X"2B" => scl <= 'Z';
                when X"2C" => scl <= '0'; byte_red(0) <= sda;
                when X"2D" => if bytecnt > 0 then sda <= '0'; else sda <= 'Z'; end if; -- master ack
                when X"2E" => scl <= 'Z'; data_out <= byte_red;
                when X"2F" => scl <= '0';
                when X"30" => sda <= 'Z'; data_strobe <= '1';
                when X"31" => if preprepstart = '0' then sda <= '0'; else sda <= 'Z'; end if; data_strobe <= '0';   -- STOP ('0') or REPEATED START ('Z')
                when X"32" => scl <= 'Z'; 
                when X"33" => sda <= 'Z'; 
                when X"34" => if sda = '0' then sda_e_ok <= '0'; end if; if scl = '0' then scl_e_ok <= '0'; end if; sda <= 'Z'; busy_r <= '0';
                when others =>
                end case;
                if bitcnt = X"30" then
                    if bytecnt > 0 then bytecnt <= bytecnt - 1; bitcnt <= X"1D"; else bitcnt <= X"31"; end if;
                else bitcnt <= bitcnt + 1; end if;
                ecnt <= conv_std_logic_vector(CDIV, ECNT_W);
            else
                ecnt <= ecnt - 1;
            end if;
        else
            scl <= 'Z';
            sda <= 'Z';        
        end if;
    end if;
    end process;

end Behavioral;

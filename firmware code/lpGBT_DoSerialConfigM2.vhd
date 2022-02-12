----------------------------------------------------------------------------------
-- Company: DESY 
-- Engineer: Artur Boebel
-- 
-- Create Date: 18/06/2019
-- Description: Module for controlling the serial transmission to lpGBT 2 via IC
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity lpGBT_DoSerialConfigM2 is
    Port ( clk : in STD_LOGIC;
           start : in STD_LOGIC;
           lpGBT_I2C_MasterNr : in STD_LOGIC_VECTOR (1 downto 0);
           datatxcmdbus : out STD_LOGIC_VECTOR (9 downto 0);
           cmd_paraclk : out STD_LOGIC;
           cmd_parabyte : in STD_LOGIC_VECTOR (7 downto 0);
           ICC_Interface : out STD_LOGIC_VECTOR (44 downto 0);
           ICC_Din_clk : in STD_LOGIC;
           ICC_Dout : in STD_LOGIC_VECTOR (7 downto 0);
           ICC_Dout_clk : in STD_LOGIC;
           ICC_busy : in STD_LOGIC;
           ICC_rx_valid : in STD_LOGIC );
end lpGBT_DoSerialConfigM2;

architecture Behavioral of lpGBT_DoSerialConfigM2 is

    signal cntr : std_logic_vector (3 downto 0) := X"0";
    signal ck, pck, dly : std_logic := '0';

    signal ICC_Address_lpGBT, Address_lpGBT_M2 : std_logic_vector (6 downto 0) := B"0000000";
    signal NData, NWritten : std_logic_vector (11 downto 0) := X"000"; 
    signal Address : std_logic_vector (15 downto 0) := X"0000"; 
    signal Data_out : std_logic_vector (7 downto 0) := X"00"; 
    signal Data_in : std_logic_vector (7 downto 0) := X"00"; 
    signal IsWrCmd, DoRead, DoWrite : std_logic := '0';
    signal busy_rd, busy_wr, valid_rd, valid_wr : std_logic;

    signal ICC_Interface_read : STD_LOGIC_VECTOR (44 downto 0);
    signal ICC_Interface_write : STD_LOGIC_VECTOR (44 downto 0);

begin

    lpGBT_DoReadM2Reg_inst: entity work.lpGBT_DoReadM2Reg port map(
        clk => clk,
        Address => Address,
        Data_out => Data_out,
        Address_lpGBT_M2 => Address_lpGBT_M2,
        lpGBT_I2C_MasterNr => lpGBT_I2C_MasterNr,
        DoRead => DoRead,
        busy_out => busy_rd,
        rx_valid_out => valid_rd,
        ICC_NData => ICC_Interface_read(35 downto 24),
        ICC_Addr => ICC_Interface_read(15 downto 0),
        ICC_Din => ICC_Interface_read(23 downto 16),
        ICC_Din_clk => ICC_Din_clk,
        ICC_Dout => ICC_Dout,
        ICC_Dout_clk => ICC_Dout_clk,
        ICC_write => ICC_Interface_read(43),
        ICC_dosend => ICC_Interface_read(44),
        ICC_busy => ICC_busy,
        ICC_rx_valid => ICC_rx_valid 
    );

    lpGBT_DoWriteM2Reg_inst: entity work.lpGBT_DoWriteM2Reg port map(
        clk => clk,
        Address => Address,
        Data_in => Data_in,
        Address_lpGBT_M2 => Address_lpGBT_M2,
        lpGBT_I2C_MasterNr => lpGBT_I2C_MasterNr,
        DoWrite => DoWrite,
        busy_out => busy_wr,
        rx_valid_out => valid_wr,
        ICC_NData => ICC_Interface_write(35 downto 24),
        ICC_Addr => ICC_Interface_write(15 downto 0),
        ICC_Din => ICC_Interface_write(23 downto 16),
        ICC_Din_clk => ICC_Din_clk,
        ICC_Dout => ICC_Dout,
        ICC_Dout_clk => ICC_Dout_clk,
        ICC_write => ICC_Interface_write(43),
        ICC_dosend => ICC_Interface_write(44),
        ICC_busy => ICC_busy,
        ICC_rx_valid => ICC_rx_valid 
    );

    ICC_Interface <= ICC_Interface_read  when DoRead = '1'
                else ICC_Interface_write when DoWrite = '1'
                else B"000000000000000000000000000000000000000000000";

    ICC_Interface_read(42 downto 36) <= ICC_Address_lpGBT;
    ICC_Interface_write(42 downto 36) <= ICC_Address_lpGBT;

    datatxcmdbus(8) <= ck;
    cmd_paraclk <= pck;

    process(clk) begin
    if rising_edge(clk) then
        if start = '1' then
            if cntr < 8 then
                if pck = '0' and dly = '0' and ck = '0' then
                    case cntr is 
                    when X"0" => ICC_Address_lpGBT <= cmd_parabyte(7 downto 1);
                                 IsWrCmd <= not cmd_parabyte(0);
                    when X"1" => Address_lpGBT_M2 <= cmd_parabyte(7 downto 1);
                    when X"2" => NData(11 downto 8) <= cmd_parabyte(3 downto 0);
                    when X"3" => NData(7 downto 0) <= cmd_parabyte;
                    when X"4" => Address(15 downto 8) <= cmd_parabyte;
                    when X"5" => Address(7 downto 0) <= cmd_parabyte;
                    when X"6" =>
                        if IsWrCmd = '1' then 
                            DoWrite <= '1'; Data_in <= cmd_parabyte;
                            if busy_wr = '1' then cntr <= cntr + 1; end if;
                        else
                            DoRead <= '1';
                            if busy_rd = '1' then cntr <= cntr + 1; end if;
                        end if;
                    when X"7" =>
                        if IsWrCmd = '1' and busy_wr = '0' then
                            DoWrite <= '0'; DoRead <= '0';
                            if valid_wr = '1' then
                                Address <= Address + 1;
                                NWritten <= NWritten + 1;                            
                                NData <= NData - 1;
                                if NData > 1 then
                                    pck <= '1'; dly <= '1'; cntr <= cntr - 2;
                                else cntr <= X"8"; end if;
                            else cntr <= X"8"; end if;
                        elsif IsWrCmd = '0' and busy_rd = '0' then
                            DoWrite <= '0'; DoRead <= '0';
                            if valid_rd = '1' then
                                Address <= Address + 1;
                                NData <= NData - 1;
                                datatxcmdbus(7 downto 0) <= Data_out;
                                ck <= '1';
                                if NData > 1 then cntr <= cntr - 2; end if;
                            else cntr <= X"8"; end if;
                        end if;
                    when others =>
                    end case;
                    if cntr < 6 then pck <= '1'; dly <= '1'; end if;
                elsif ck = '1' then ck <= '0'; cntr <= cntr + 1;
                elsif pck = '1' then pck <= '0'; dly <= '1'; 
                else pck <= '0'; dly <= '0'; cntr <= cntr + 1; end if;
            elsif cntr < 10 then 
                if IsWrCmd = '1' then
                    if ck = '0' then
                        if cntr = 8 then datatxcmdbus(7 downto 0) <= X"0" & NWritten(11 downto 8); end if;
                        if cntr = 9 then datatxcmdbus(7 downto 0) <= NWritten(7 downto 0); end if;
                        ck <= '1';
                    else ck <= '0'; cntr <= cntr + 1; end if;
                else cntr <= X"A";
                end if;
            else ck <= '0'; pck <= '0'; datatxcmdbus(9) <= '1'; end if;
        else
            DoWrite <= '0'; DoRead <= '0';
            NWritten <= X"000";
            ck <= '0'; pck <= '0'; cntr <= X"0";
            datatxcmdbus(7 downto 0) <= X"00";
            datatxcmdbus(9) <= '0';
        end if; 
    end if;
    end process;

end Behavioral;

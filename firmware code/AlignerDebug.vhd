----------------------------------------------------------------------------------
-- Company: DESY
-- Engineer: Artur Boebel
-- 
-- Create Date: 06/05/2020
-- Description: 
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity AlignerDebug is
    Port ( clk : in STD_LOGIC;
           start : in STD_LOGIC;
           datatxcmdbus : out STD_LOGIC_VECTOR (9 downto 0) := B"0000000000";
           cmd_paraclk : out STD_LOGIC;
           cmd_parabyte : in STD_LOGIC_VECTOR (7 downto 0);
           align_limit_valid : out STD_LOGIC_VECTOR (7 downto 0) := X"3F";
           align_limit_revalid : out STD_LOGIC_VECTOR (7 downto 0) := X"0F";
           align_limit_invalid : out STD_LOGIC_VECTOR (3 downto 0) := X"3";
           align_hdr_pos : in STD_LOGIC_VECTOR (255 downto 0)
         );
end AlignerDebug;

architecture Behavioral of AlignerDebug is

    signal cntr : std_logic_vector (5 downto 0) := B"000000";
    signal ck, pck, dly : std_logic := '0';

    signal align_hdr_pos_buf : STD_LOGIC_VECTOR (255 downto 0);

begin

    datatxcmdbus(8) <= ck;
    cmd_paraclk <= pck;

    -- Get the parameter data, prepare and send the response:
    process(clk) begin
    if rising_edge(clk) then
        if start = '1' then
            if cntr < 3 then    -- Get the parameter data:
                if pck = '0' and dly = '0' then
                    case cntr is 
                    when B"000000" => align_limit_valid  <= cmd_parabyte; align_hdr_pos_buf <= align_hdr_pos;
                    when B"000001" => align_limit_revalid  <= cmd_parabyte;
                    when B"000010" => align_limit_invalid  <= cmd_parabyte(3 downto 0);
                    when others => 
                    end case;
                    pck <= '1'; dly <= '1';
                elsif pck = '1' then pck <= '0'; dly <= '1'; 
                else pck <= '0'; dly <= '0'; cntr <= cntr + 1; end if;
            elsif cntr < 35 then -- Prepare the response: 
                if ck = '0' then
                    datatxcmdbus(7 downto 0) <= align_hdr_pos_buf(conv_integer(34-cntr)*8 + 7 downto conv_integer(34-cntr)*8);
                    ck <= '1';  -- Clock the response byte
                else ck <= '0'; cntr <= cntr + 1; end if;
            else ck <= '0'; pck <= '0'; datatxcmdbus(9) <= '1'; end if; -- Send the response packet
        else 
            ck <= '0'; pck <= '0'; cntr <= B"000000";
            datatxcmdbus(7 downto 0) <= X"00";
            datatxcmdbus(9) <= '0';
        end if; 
    end if;
    end process;

end Behavioral;

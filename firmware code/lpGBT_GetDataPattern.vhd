----------------------------------------------------------------------------------
-- Company: DESY
-- Engineer: Artur Boebel
-- 
-- Create Date: 29/07/2019
-- Description: 
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity lpGBT_GetDataPattern is
    Port ( clk : in STD_LOGIC;
           start : in STD_LOGIC;
           datatxcmdbus : out STD_LOGIC_VECTOR (9 downto 0) := B"0000000000";
           cmd_paraclk : out STD_LOGIC;
           cmd_parabyte : in STD_LOGIC_VECTOR (7 downto 0);
           link_number : out STD_LOGIC_VECTOR (3 downto 0) := X"0";
           get1_out : out STD_LOGIC := '0';
           get1_rdy : in STD_LOGIC;
           data_rec1 : in STD_LOGIC_VECTOR (127 downto 0);
           comp_pat1 : in STD_LOGIC_VECTOR (127 downto 0);
           get2_out : out STD_LOGIC := '0';
           get2_rdy : in STD_LOGIC;
           data_rec2 : in STD_LOGIC_VECTOR (127 downto 0);
           comp_pat2 : in STD_LOGIC_VECTOR (127 downto 0);
           getD_out : out STD_LOGIC := '0';
           getD_rdy : in STD_LOGIC;
           data_rec_d : in STD_LOGIC_VECTOR (127 downto 0);
           comp_pat_d : in STD_LOGIC_VECTOR (127 downto 0);
           getC_out : out STD_LOGIC := '0';
           getC_rdy : in STD_LOGIC;
           data_clock : in STD_LOGIC_VECTOR (255 downto 0);
           getR_out : out STD_LOGIC := '0';
           getR_rdy : in STD_LOGIC;
           data_raw : in STD_LOGIC_VECTOR (255 downto 0);
           getE_out : out STD_LOGIC := '0';
           getE_rdy : in STD_LOGIC;
           data_rec_e : in STD_LOGIC_VECTOR (127 downto 0);
           comp_pat_e : in STD_LOGIC_VECTOR (127 downto 0)
    );
end lpGBT_GetDataPattern;

architecture Behavioral of lpGBT_GetDataPattern is

    signal cntr : std_logic_vector (5 downto 0) := B"000000";
    signal ck, pck, dly : std_logic := '0';

    signal source : std_logic_vector (2 downto 0) := B"000";
    signal data_block : std_logic_vector (255 downto 0);
    signal dwait : std_logic_vector (3 downto 0);

begin

    datatxcmdbus(8) <= ck;
    cmd_paraclk <= pck;

    data_block <= data_rec1 & comp_pat1   when source = B"000"
             else data_rec2 & comp_pat2   when source = B"001"
             else data_rec_d & comp_pat_d when source = B"010"
             else data_clock              when source = B"011"
             else data_raw                when source = B"100"
             else data_rec_e & comp_pat_e when source = B"101"
             else X"0000000000000000000000000000000000000000000000000000000000000000";

    -- Get the parameter data, prepare and send the response:
    process(clk) begin
    if rising_edge(clk) then
        if start = '1' then
            if cntr < 2 then    -- Get the parameter data:
                if pck = '0' and dly = '0' then
                    case cntr is 
                    when B"000000" => link_number <= cmd_parabyte(3 downto 0);
                    when B"000001" =>
                        case cmd_parabyte(2 downto 0) is
                        when B"000" => get1_out <= '1'; source <= B"000";
                        when B"001" => get2_out <= '1'; source <= B"001";
                        when B"010" => getD_out <= '1'; source <= B"010";
                        when B"011" => getC_out <= '1'; source <= B"011";
                        when B"100" => getR_out <= '1'; source <= B"100";
                        when B"101" => getE_out <= '1'; source <= B"101";
                        when others =>
                        end case;
                        dwait <= X"F";
                    when others =>
                    end case;
                    pck <= '1'; dly <= '1';
                elsif pck = '1' then pck <= '0'; dly <= '1'; 
                else pck <= '0'; dly <= '0'; cntr <= cntr + 1; end if;
            elsif cntr = 2 then --wait for data ready:  
                case source is
                when B"000" => if get1_rdy = '1' or dwait = 0 then cntr <= B"000011"; end if;
                when B"001" => if get2_rdy = '1' or dwait = 0 then cntr <= B"000011"; end if;
                when B"010" => if getD_rdy = '1' or dwait = 0 then cntr <= B"000011"; end if;
                when B"011" => if getC_rdy = '1' or dwait = 0 then cntr <= B"000011"; end if;
                when B"100" => if getR_rdy = '1' or dwait = 0 then cntr <= B"000011"; end if;
                when B"101" => if getE_rdy = '1' or dwait = 0 then cntr <= B"000011"; end if;
                when others => if dwait = 0 then cntr <= B"000011"; end if;
                end case;
                if dwait > 0 then dwait <= dwait - 1; end if;
            elsif cntr < 35 then -- Prepare the response: 
                if ck = '0' then
                        datatxcmdbus(7 downto 0) <= data_block(conv_integer(34-cntr)*8 + 7 downto conv_integer(34-cntr)*8);
                    ck <= '1';  -- Clock the response byte
                else ck <= '0'; cntr <= cntr + 1; end if;
            else ck <= '0'; pck <= '0'; datatxcmdbus(9) <= '1'; end if; -- Send the response packet
        else 
            ck <= '0'; pck <= '0'; cntr <= B"000000";
            datatxcmdbus(7 downto 0) <= X"00";
            datatxcmdbus(9) <= '0';
            get1_out <= '0'; get2_out <= '0'; getD_out <= '0'; getC_out <= '0'; getR_out <= '0'; getE_out <= '0';
        end if; 
    end if;
    end process;

end Behavioral;

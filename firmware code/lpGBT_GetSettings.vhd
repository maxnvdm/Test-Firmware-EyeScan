----------------------------------------------------------------------------------
-- Company: DESY 
-- Engineer: Artur Boebel
-- 
-- Create Date: 31/07/2019
-- Description: Module for responding the actual ELink Settings via UART
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity lpGBT_GetSettings is
    Port ( clk : in STD_LOGIC;
           start : in STD_LOGIC;
           datatxcmdbus : out STD_LOGIC_VECTOR (9 downto 0) := B"0000000000";
           Elink1_PatGen_on : in std_logic_vector (13 downto 0);
           Elink1_SynGen_on : in std_logic_vector (13 downto 0);
           Elink1_inv : in std_logic_vector (13 downto 0);
           Elink1_bit_shift : in std_logic_vector (83 downto 0);
           Elink2_PatGen_on : in std_logic_vector (13 downto 0);
           Elink2_SynGen_on : in std_logic_vector (13 downto 0);
           Elink2_inv : in std_logic_vector (13 downto 0);
           Elink2_bit_shift : in std_logic_vector (83 downto 0);
           Elink_dwn_PatGen_on : in std_logic_vector (7 downto 0);
           Elink_dwn_SynGen_on : in std_logic_vector (7 downto 0);
           Elink_dwn_inv : in std_logic_vector (7 downto 0);
           Elink_dwn_bit_shift : in std_logic_vector (47 downto 0);
           Elink_dwn_phase : in std_logic_vector (15 downto 0);
           EC_PatGen_on_up : in std_logic;
           EC_SynGen_on_up : in std_logic;
           EC_inv_on_up : in std_logic;
           EC_bit_shift_up : in std_logic_vector (5 downto 0);
           EC_PatGen_on_dwn : in std_logic;
           EC_SynGen_on_dwn : in std_logic;
           EC_inv_on_dwn : in std_logic;
           EC_bit_shift_dwn : in std_logic_vector (5 downto 0);
           EC_phase_dwn : in std_logic_vector (1 downto 0) );
end lpGBT_GetSettings;

architecture Behavioral of lpGBT_GetSettings is

    signal cntr : std_logic_vector (5 downto 0) := B"000000";
    signal byteout : std_logic_vector (7 downto 0) := X"00";
    signal ck : std_logic := '0';

begin

    datatxcmdbus(7 downto 0) <= byteout;
    datatxcmdbus(8) <= ck;

    -- Prepare and send the response:
    process(clk) begin
    if rising_edge(clk) then
        if start = '1' then
            if cntr < 57 then 
                if ck = '0' then
                    if    cntr = 0 then byteout <= B"00" & Elink1_PatGen_on(13 downto 8);
                    elsif cntr = 1 then byteout <= Elink1_PatGen_on(7 downto 0);
                    elsif cntr = 2 then byteout <= B"00" & Elink1_SynGen_on(13 downto 8);
                    elsif cntr = 3 then byteout <= Elink1_SynGen_on(7 downto 0);
                    elsif cntr = 4 then byteout <= B"00" & Elink1_inv(13 downto 8);
                    elsif cntr = 5 then byteout <= Elink1_inv(7 downto 0);
                    elsif cntr >= 6 and cntr < 20 then
                            byteout <= B"00" & Elink1_bit_shift(conv_integer(19-cntr)*6+5 downto conv_integer(19-cntr)*6);
                    elsif cntr = 20 then byteout <= B"00" & Elink2_PatGen_on(13 downto 8);
                    elsif cntr = 21 then byteout <= Elink2_PatGen_on(7 downto 0);
                    elsif cntr = 22 then byteout <= B"00" & Elink2_SynGen_on(13 downto 8);
                    elsif cntr = 23 then byteout <= Elink2_SynGen_on(7 downto 0);
                    elsif cntr = 24 then byteout <= B"00" & Elink2_inv(13 downto 8);
                    elsif cntr = 25 then byteout <= Elink2_inv(7 downto 0);
                    elsif cntr >= 26 and cntr < 40 then
                            byteout <= B"00" & Elink2_bit_shift(conv_integer(39-cntr)*6+5 downto conv_integer(39-cntr)*6);
                    elsif cntr = 40 then byteout <= Elink_dwn_PatGen_on;
                    elsif cntr = 41 then byteout <= Elink_dwn_SynGen_on;
                    elsif cntr = 42 then byteout <= Elink_dwn_inv;
                    elsif cntr >= 43 and cntr < 51 then
                            byteout <= B"00" & Elink_dwn_bit_shift(conv_integer(50-cntr)*6+5 downto conv_integer(50-cntr)*6);
                    elsif cntr = 51 then byteout <= Elink_dwn_phase(15 downto 8);
                    elsif cntr = 52 then byteout <= Elink_dwn_phase(7 downto 0);
                    elsif cntr = 53 then byteout <= '0' & EC_inv_on_dwn & EC_SynGen_on_dwn & EC_PatGen_on_dwn & '0' & EC_inv_on_up & EC_SynGen_on_up & EC_PatGen_on_up;
                    elsif cntr = 54 then byteout <= B"00" & EC_bit_shift_up;
                    elsif cntr = 55 then byteout <= B"00" & EC_bit_shift_dwn;
                    elsif cntr = 56 then byteout <= B"000000" & EC_phase_dwn;
                    else byteout <= X"00";
                    end if;
                    ck <= '1';  -- Clock the response byte
                else ck <= '0'; cntr <= cntr + 1; end if;
            else ck <= '0'; datatxcmdbus(9) <= '1'; end if; -- Send the response packet
        else 
            ck <= '0'; cntr <= B"000000";
            byteout <= X"00";
            datatxcmdbus(9) <= '0';
        end if; 
    end if;
    end process;

end Behavioral;

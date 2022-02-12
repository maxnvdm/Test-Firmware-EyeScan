----------------------------------------------------------------------------------
-- Company: DESY 
-- Engineer: Artur Boebel
-- 
-- Create Date: 18/06/2019
-- Description: Module for responding the Status via UART
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity lpGBT_GetStatus is
    Port ( clk : in STD_LOGIC;
           start : in STD_LOGIC;
           datatxcmdbus : out STD_LOGIC_VECTOR (9 downto 0) := B"0000000000";
           PktNumCnt : in STD_LOGIC_VECTOR (47 downto 0);
           BErrCnt1 : in STD_LOGIC_VECTOR (223 downto 0);
           BErrCnt2 : in STD_LOGIC_VECTOR (223 downto 0);
           BErrCntDwn : in STD_LOGIC_VECTOR (127 downto 0);
           BErrCntEC : in STD_LOGIC_VECTOR (31 downto 0);
           CRCErr1 : in STD_LOGIC_VECTOR (15 downto 0);
           AliErr1 : in STD_LOGIC_VECTOR (15 downto 0);
           CRCErr2 : in STD_LOGIC_VECTOR (15 downto 0);
           AliErr2 : in STD_LOGIC_VECTOR (15 downto 0);
           PktLast15_1 : in STD_LOGIC_VECTOR (55 downto 0);
           PktLast15_2 : in STD_LOGIC_VECTOR (55 downto 0);
           PktLast15Dwn : in STD_LOGIC_VECTOR (31 downto 0);
           PktLast15EC : in STD_LOGIC_VECTOR (7 downto 0);
           BErr1_rdy : in STD_LOGIC;
           BErr2_rdy : in STD_LOGIC;
           BErrD_rdy : in STD_LOGIC;
           BErrE_rdy : in STD_LOGIC;
           uplink1Status : in STD_LOGIC_VECTOR (1 downto 0);
           uplink2Status : in STD_LOGIC_VECTOR (1 downto 0);
           BErrRun : in STD_LOGIC;
           BypassFEC1 : in STD_LOGIC;
           BypassFEC2 : in STD_LOGIC;
           DataLock_status : in STD_LOGIC_VECTOR (4 downto 0);
           LinkReset_status : in STD_LOGIC;
           INVERT_DL_status : in STD_LOGIC;
           INVERT_UL1_status : in STD_LOGIC;
           INVERT_UL2_status : in STD_LOGIC );
end lpGBT_GetStatus;

architecture Behavioral of lpGBT_GetStatus is

    signal cntr : std_logic_vector (6 downto 0) := B"0000000";
    signal byteout : std_logic_vector (7 downto 0) := X"00";
    signal ck : std_logic := '0';

begin

    datatxcmdbus(7 downto 0) <= byteout;
    datatxcmdbus(8) <= ck;

    -- Prepare and send the response:
    process(clk) begin
    if rising_edge(clk) then
        if start = '1' and ( ( BErr1_rdy = '1' and BErr2_rdy = '1' and BErrD_rdy = '1' and BErrE_rdy = '1' ) or LinkReset_status = '1' ) then
            if cntr < 111 then 
                if ck = '0' then
                    if cntr < 6 then                    -- 6 Byte Number of Packets:
                        byteout <= PktNumCnt(conv_integer(5-cntr)*8 + 7 downto conv_integer(5-cntr)*8);
                    elsif cntr >= 6 and cntr < 34 then  -- 28 Byte Errorcounts ELink 1:
                        byteout <= BErrCnt1(conv_integer(33-cntr)*8 + 7 downto conv_integer(33-cntr)*8);
                    elsif cntr >= 34 and cntr < 62 then  -- 28 Byte Errorcounts ELink 2:
                        byteout <= BErrCnt2(conv_integer(61-cntr)*8 + 7 downto conv_integer(61-cntr)*8);
                    elsif cntr >= 62 and cntr < 78 then  -- 16 Byte Errorcounts ELink Downlink:
                        byteout <= BErrCntDwn(conv_integer(77-cntr)*8 + 7 downto conv_integer(77-cntr)*8);
                    elsif cntr >= 78 and cntr < 82 then  -- 4 Byte Errorcounts EC Up- and Downlink:
                        byteout <= BErrCntEC(conv_integer(81-cntr)*8 + 7 downto conv_integer(81-cntr)*8);
                    elsif cntr = 82 then byteout <= CRCErr1(15 downto 8);
                    elsif cntr = 83 then byteout <= CRCErr1(7 downto 0);
                    elsif cntr = 84 then byteout <= AliErr1(15 downto 8);
                    elsif cntr = 85 then byteout <= AliErr1(7 downto 0);
                    elsif cntr = 86 then byteout <= CRCErr2(15 downto 8);
                    elsif cntr = 87 then byteout <= CRCErr2(7 downto 0);
                    elsif cntr = 88 then byteout <= AliErr2(15 downto 8);
                    elsif cntr = 89 then byteout <= AliErr2(7 downto 0);
                    elsif cntr >= 90 and cntr < 97 then  -- 7 Byte status of last 15 packet match ELink 1:
                        byteout <= PktLast15_1(conv_integer(96-cntr)*8 + 7 downto conv_integer(96-cntr)*8);
                    elsif cntr >= 97 and cntr < 104 then -- 7 Byte status of last 15 packet match ELink 2:
                        byteout <= PktLast15_2(conv_integer(103-cntr)*8 + 7 downto conv_integer(103-cntr)*8);
                    elsif cntr >= 104 and cntr < 108 then -- 4 Byte status of last 15 packet match ELink Downlink:
                        byteout <= PktLast15Dwn(conv_integer(107-cntr)*8 + 7 downto conv_integer(107-cntr)*8);
                    elsif cntr = 108 then byteout <= PktLast15EC;
                    elsif cntr = 109 then byteout <= BErrRun & INVERT_DL_status & BypassFEC2 & BypassFEC1 & uplink2Status & uplink1Status;
                    elsif cntr = 110 then byteout <= LinkReset_status & INVERT_UL2_status & INVERT_UL1_status & DataLock_status;
                    end if;
                    ck <= '1';  -- Clock the response byte
                else ck <= '0'; cntr <= cntr + 1; end if;
            else ck <= '0'; datatxcmdbus(9) <= '1'; end if; -- Send the response packet
        else 
            ck <= '0'; cntr <= B"0000000";
            byteout <= X"00";
            datatxcmdbus(9) <= '0';
        end if; 
    end if;
    end process;

end Behavioral;

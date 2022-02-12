----------------------------------------------------------------------------------
-- Company: DESY 
-- Engineer: Artur Boebel
-- 
-- Create Date: 05/07/2019
-- Description: Bit error counter for lpGBT BERTest
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

--use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VComponents.all;

entity lpGBT_BitErrorCounter is
    Port ( clk160 : in STD_LOGIC;
           clk_en : in STD_LOGIC;
           run : in STD_LOGIC;
           On0 : in STD_LOGIC_VECTOR (13 downto 0);
           On1 : in STD_LOGIC_VECTOR (13 downto 0);
           DataCmp0 : in STD_LOGIC_VECTOR (223 downto 0);
           DataCmp1 : in STD_LOGIC_VECTOR (223 downto 0);
           Data_CRCOK : in STD_LOGIC;
           Data_aligned : in STD_LOGIC;
           GetBER_req : in STD_LOGIC;
           --PktNumCnt_out : out STD_LOGIC_VECTOR (47 downto 0);
           BErrCnt_out : out STD_LOGIC_VECTOR (223 downto 0);
           PktLast15_out : out STD_LOGIC_VECTOR (55 downto 0);
           CRCErrCnt_out : out STD_LOGIC_VECTOR (15 downto 0);
           AliErrCnt_out : out STD_LOGIC_VECTOR (15 downto 0);
           UplinkStatus_out : out STD_LOGIC_VECTOR (1 downto 0);
           GetBER_rdy : out STD_LOGIC;
           GetData_LinkNumber : in STD_LOGIC_VECTOR (3 downto 0);
           GetData_req : in STD_LOGIC;
           GetData_D1 : out STD_LOGIC_VECTOR (127 downto 0);
           GetData_D2 : out STD_LOGIC_VECTOR (127 downto 0);
           GetData_rdy : out STD_LOGIC;
           uLData_locked_out : out STD_LOGIC;
           uLData_unlock : in STD_LOGIC );
end lpGBT_BitErrorCounter;

architecture Behavioral of lpGBT_BitErrorCounter is

    signal RunBuffered, GetBER_Buffered, GetData_Buffered, uLData_locked : STD_LOGIC := '0';
    signal GetBER_req_buf, GetData_req_buf : STD_LOGIC := '0';
    --signal PktNumCnt : STD_LOGIC_VECTOR (47 downto 0) := X"000000000000";
    type t_arr_14x16 is array (13 downto 0) of STD_LOGIC_VECTOR (15 downto 0);
    signal BErrCnt : t_arr_14x16 := ( X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000" );
    type t_arr_14x4 is array (13 downto 0) of STD_LOGIC_VECTOR (3 downto 0);
    signal PktLast15 : t_arr_14x4 := ( X"0", X"0", X"0", X"0", X"0", X"0", X"0", X"0", X"0", X"0", X"0", X"0", X"0", X"0" );
    signal CRCErrCnt : STD_LOGIC_VECTOR (15 downto 0) := X"0000";
    signal AliErrCnt : STD_LOGIC_VECTOR (15 downto 0) := X"0000";
    signal CntWait : STD_LOGIC_VECTOR (2 downto 0) := B"000";
    type t_arr_14x128 is array (13 downto 0) of STD_LOGIC_VECTOR (127 downto 0);
    signal DataPat1 : t_arr_14x128;
    signal DataPat2 : t_arr_14x128;

begin

    uLData_locked_out <= uLData_locked;

    process (clk160) begin
    if rising_edge(clk160) then
        if clk_en = '1' then

            -- Packet, bit error, CRC, alignment and packet compare count:
            if run = '1' and RunBuffered = '1' then
                --PktNumCnt <= PktNumCnt + 1;
                if Data_CRCOK = '0'   and CRCErrCnt < X"FFFF" then CRCErrCnt <= CRCErrCnt + 1; end if;
                if Data_aligned = '0' and AliErrCnt < X"FFFF" then AliErrCnt <= AliErrCnt + 1; end if;
                if Data_CRCOK = '0' or Data_aligned = '0' then
                    CntWait <= B"111";
                elsif CntWait > 0 then
                    CntWait <= CntWait - 1;
                end if;
                if Data_CRCOK = '1' and Data_aligned = '1' and CntWait = 0 then
                    for i in 0 to 13 loop
                        if On0(i) = '1' or On1(i) = '1' then
                            if BErrCnt(i) < X"FFF0" then
                                BErrCnt(i) <= BErrCnt(i) + ( DataCmp0(i*16+ 0) xor DataCmp1(i*16+ 0) ) 
                                                         + ( DataCmp0(i*16+ 1) xor DataCmp1(i*16+ 1) )  
                                                         + ( DataCmp0(i*16+ 2) xor DataCmp1(i*16+ 2) )
                                                         + ( DataCmp0(i*16+ 3) xor DataCmp1(i*16+ 3) )
                                                         + ( DataCmp0(i*16+ 4) xor DataCmp1(i*16+ 4) )
                                                         + ( DataCmp0(i*16+ 5) xor DataCmp1(i*16+ 5) )
                                                         + ( DataCmp0(i*16+ 6) xor DataCmp1(i*16+ 6) )
                                                         + ( DataCmp0(i*16+ 7) xor DataCmp1(i*16+ 7) )
                                                         + ( DataCmp0(i*16+ 8) xor DataCmp1(i*16+ 8) )
                                                         + ( DataCmp0(i*16+ 9) xor DataCmp1(i*16+ 9) )
                                                         + ( DataCmp0(i*16+10) xor DataCmp1(i*16+10) )
                                                         + ( DataCmp0(i*16+11) xor DataCmp1(i*16+11) )
                                                         + ( DataCmp0(i*16+12) xor DataCmp1(i*16+12) )
                                                         + ( DataCmp0(i*16+13) xor DataCmp1(i*16+13) )
                                                         + ( DataCmp0(i*16+14) xor DataCmp1(i*16+14) )
                                                         + ( DataCmp0(i*16+15) xor DataCmp1(i*16+15) );
                            else BErrCnt(i) <= X"FFFF";
                            end if;
                        end if;
                    end loop;
                end if;
            elsif run = '1' then
                if RunBuffered = '0' then
                    --PktNumCnt <= X"000000000000";
                    for i in 0 to 13 loop BErrCnt(i) <= X"0000"; end loop;
                    CRCErrCnt <= X"0000";
                    AliErrCnt <= X"0000";
                    RunBuffered <= '1'; 
                end if;
            else RunBuffered <= '0';
            end if;

            -- Last 15 packets compare:
            for i in 0 to 13 loop
                if DataCmp0(i*16+15 downto i*16) = DataCmp1(i*16+15 downto i*16) then
                    if PktLast15(i) < 15 then PktLast15(i) <= PktLast15(i) + 1; end if;
                else
                    if PktLast15(i) > 0 then PktLast15(i) <= PktLast15(i) - 1; end if;
                    if Data_CRCOK = '1' and Data_aligned = '1' and CntWait = 0 then
                        if uLData_unlock = '0' and run = '1' and (On0(i) = '1' or On1(i) = '1')  then uLData_locked <= '1'; end if;
                    end if;
                end if;
            end loop;
            if uLData_unlock = '1' then uLData_locked <= '0'; end if;

            -- Data Pattern buffering:
            if uLData_locked = '0' then
                for j in 0 to 13 loop
                    for i in 0 to 6 loop
                        DataPat1(j)(i*16+31 downto i*16+16) <= DataPat1(j)(i*16+15 downto i*16);
                        DataPat2(j)(i*16+31 downto i*16+16) <= DataPat2(j)(i*16+15 downto i*16);
                    end loop;
                    DataPat1(j)(15 downto 0) <= DataCmp0(j*16+15 downto j*16);  
                    DataPat2(j)(15 downto 0) <= DataCmp1(j*16+15 downto j*16);  
                end loop;
            end if;

            -- Write data to output registers:
            GetBER_req_buf <= GetBER_req;
            if GetBER_req_buf = '1' then
                if GetBER_Buffered = '0' then
                    --PktNumCnt_out <= PktNumCnt;
                    for i in 0 to 13 loop
                         BErrCnt_out(i*16+15 downto i*16) <= BErrCnt(i);
                         PktLast15_out(i*4+3 downto i*4) <= PktLast15(i);
                    end loop;
                    CRCErrCnt_out <= CRCErrCnt;
                    AliErrCnt_out <= AliErrCnt;
                    UplinkStatus_out <= Data_CRCOK & Data_aligned;
                    GetBER_Buffered <= '1';
                end if;
            else GetBER_Buffered <= '0';
            end if;
            GetBER_rdy <= GetBER_Buffered;

            -- Write data patterns to GetData output registers:
            GetData_req_buf <= GetData_req; 
            if GetData_req_buf = '1' then
                if GetData_Buffered = '0' then
                    if GetData_LinkNumber < 14 then
                        GetData_D1 <= DataPat1(conv_integer(GetData_LinkNumber));
                        GetData_D2 <= DataPat2(conv_integer(GetData_LinkNumber));
                    end if;
                    GetData_Buffered <= '1';
                end if;
            else GetData_Buffered <= '0';
            end if;
            GetData_rdy <= GetData_Buffered;

        end if;
    end if;
    end process;

end Behavioral;

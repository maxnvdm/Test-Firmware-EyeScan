----------------------------------------------------------------------------------
-- Company: DESY 
-- Engineer: Artur Boebel
-- 
-- Create Date: 30/07/2019
-- Description: Bit error counter for downlink
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

--use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VComponents.all;

entity lpGBT_DownlinkBitErrorCount is
    Port ( clk160 : in STD_LOGIC;
           clk_en : in STD_LOGIC;
           run : in STD_LOGIC;
           On0 : in STD_LOGIC_VECTOR (7 downto 0);
           On1 : in STD_LOGIC_VECTOR (7 downto 0);
           DataCmp0 : in STD_LOGIC_VECTOR (31 downto 0);
           DataCmp1 : in STD_LOGIC_VECTOR (31 downto 0);
           GetBER_req : in STD_LOGIC;
           PktNumCnt_out : out STD_LOGIC_VECTOR (47 downto 0);
           BErrCnt_out : out STD_LOGIC_VECTOR (127 downto 0);
           PktLast15_out : out STD_LOGIC_VECTOR (31 downto 0);
           GetBER_rdy : out STD_LOGIC;
           GetData_LinkNumber : in STD_LOGIC_VECTOR (3 downto 0);
           GetData_req : in STD_LOGIC;
           GetData_D1 : out STD_LOGIC_VECTOR (127 downto 0);
           GetData_D2 : out STD_LOGIC_VECTOR (127 downto 0);
           GetData_rdy : out STD_LOGIC;
           dLData_locked_out : out STD_LOGIC;
           dLData_unlock : in STD_LOGIC );
end lpGBT_DownlinkBitErrorCount;

architecture Behavioral of lpGBT_DownlinkBitErrorCount is

    signal RunBuffered, GetBER_Buffered, GetData_Buffered, dLData_locked : STD_LOGIC := '0';
    signal GetBER_req_buf, GetData_req_buf : STD_LOGIC := '0';
    signal PktNumCnt : STD_LOGIC_VECTOR (47 downto 0) := X"000000000000";
    type t_arr_8x16 is array (7 downto 0) of STD_LOGIC_VECTOR (15 downto 0);
    signal BErrCnt : t_arr_8x16 := ( X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000" );
    type t_arr_8x4 is array (7 downto 0) of STD_LOGIC_VECTOR (3 downto 0);
    signal PktLast15 : t_arr_8x4 := ( X"0", X"0", X"0", X"0", X"0", X"0", X"0", X"0" );
    type t_arr_8x128 is array (7 downto 0) of STD_LOGIC_VECTOR (127 downto 0);
    signal DataPat1 : t_arr_8x128;
    signal DataPat2 : t_arr_8x128;

begin

    dLData_locked_out <= dLData_locked;

    process (clk160) begin
    if rising_edge(clk160) then
        if clk_en = '1' then

            -- Packet, bit error, CRC, alignment and packet compare count:
            if run = '1' and RunBuffered = '1' then
                PktNumCnt <= PktNumCnt + 1;
                for i in 0 to 7 loop
                    if On0(i) = '1' or On1(i) = '1' then
                        if BErrCnt(i) < X"FFFC" then
                            BErrCnt(i) <= BErrCnt(i) + ( DataCmp0(i*4+ 0) xor DataCmp1(i*4+ 0) ) 
                                                     + ( DataCmp0(i*4+ 1) xor DataCmp1(i*4+ 1) )  
                                                     + ( DataCmp0(i*4+ 2) xor DataCmp1(i*4+ 2) )
                                                     + ( DataCmp0(i*4+ 3) xor DataCmp1(i*4+ 3) );
                        else BErrCnt(i) <= X"FFFF";
                        end if;
                    end if;
                end loop;
            elsif run = '1' then
                if RunBuffered = '0' then
                    PktNumCnt <= X"000000000000";
                    for i in 0 to 7 loop BErrCnt(i) <= X"0000"; end loop;
                    RunBuffered <= '1'; 
                end if;
            else RunBuffered <= '0';
            end if;

            -- Last 15 packets compare:
            for i in 0 to 7 loop
                if DataCmp0(i*4+3 downto i*4) = DataCmp1(i*4+3 downto i*4) then
                    if PktLast15(i) < 15 then PktLast15(i) <= PktLast15(i) + 1; end if;
                else
                    if PktLast15(i) > 0 then PktLast15(i) <= PktLast15(i) - 1; end if;
                    if dLData_unlock = '0' and run = '1' and (On0(i) = '1' or On1(i) = '1') then dLData_locked <= '1'; end if;
                end if;
            end loop;
            if dLData_unlock = '1' then dLData_locked <= '0'; end if;

            -- Data Pattern buffering:
            if dLData_locked = '0' then
                for j in 0 to 7 loop
                    for i in 0 to 30 loop
                        DataPat1(j)(i*4+7 downto i*4+4) <= DataPat1(j)(i*4+3 downto i*4);
                        DataPat2(j)(i*4+7 downto i*4+4) <= DataPat2(j)(i*4+3 downto i*4);
                    end loop;
                    DataPat1(j)(3 downto 0) <= DataCmp0(j*4+3 downto j*4);  
                    DataPat2(j)(3 downto 0) <= DataCmp1(j*4+3 downto j*4);  
                end loop;
            end if;

            -- Write data to output registers:
            GetBER_req_buf <= GetBER_req;
            if GetBER_req_buf = '1' then
                if GetBER_Buffered = '0' then
                    PktNumCnt_out <= PktNumCnt;
                    for i in 0 to 7 loop
                         BErrCnt_out(i*16+15 downto i*16) <= BErrCnt(i);
                         PktLast15_out(i*4+3 downto i*4) <= PktLast15(i);
                    end loop;
                    GetBER_Buffered <= '1';
                end if;
            else GetBER_Buffered <= '0';
            end if;
            GetBER_rdy <= GetBER_Buffered;

            -- Write data patterns to GetData output registers:
            GetData_req_buf <= GetData_req;
            if GetData_req_buf = '1' then
                if GetData_Buffered = '0' then
                    if GetData_LinkNumber < 8 then
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

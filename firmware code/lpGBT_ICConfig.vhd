----------------------------------------------------------------------------------
-- Company: DESY 
-- Engineer: Artur Boebel
-- 
-- Create Date: 04/06/2019
-- Description: Generates and receives IC data to configure lpGBT
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

--use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VComponents.all;

entity lpGBT_ICConfig is
    Port ( clk : in STD_LOGIC;                              -- System clock (e.g. 100 MHz)
           Address_lpGBT : in STD_LOGIC_VECTOR(6 downto 0); -- Usually: B"1110001" 
           data_num : in STD_LOGIC_VECTOR(11 downto 0);     -- Number of bytes to write or read
           adr_in : in STD_LOGIC_VECTOR(15 downto 0);       -- Start address

           data_in : in STD_LOGIC_VECTOR(7 downto 0);       -- Data byte input to write to lpGBT 
           data_in_clk_out : out STD_LOGIC := '0';          -- Rising edge requests following data byte
           clk160_down : in STD_LOGIC;                      -- 160 MHz downlink clock
           clk_en_dwn : in STD_LOGIC;                       -- 40 MHz downlink clock sync

           data_out : out STD_LOGIC_VECTOR(7 downto 0);     -- Data byte red
           data_out_clk_out : out STD_LOGIC := '0';         -- reads data at rising edge
           clk160_up : in STD_LOGIC;                        -- 160 MHz uplink clock
           clk_en_up : in STD_LOGIC;                        -- 40 MHz uplink clock sync

           write : in STD_LOGIC := '0';                     -- set '1' to write data, '0' to read data 
           dosnd : in STD_LOGIC := '0';                     -- rising edge: start operation
           busy_out : out STD_LOGIC := '0';                 -- Outputs '1' during operation
           rx_valid_out : out STD_LOGIC := '0';             -- Outputs '1' when last received frame was valid

           ICData_down : out STD_LOGIC_VECTOR(1 downto 0);  -- connect to downlink IC
           ICData_up : in STD_LOGIC_VECTOR(1 downto 0)      -- connect to uplink IC
    );
end lpGBT_ICConfig;

architecture Behavioral of lpGBT_ICConfig is
    constant Frame_delimiter : STD_LOGIC_VECTOR(7 downto 0) := X"7E";

	signal cnt_d : STD_LOGIC_VECTOR (1 downto 0) := B"00";
	signal cnt_u : STD_LOGIC_VECTOR (1 downto 0) := B"00";

    signal ICData_down_buf : STD_LOGIC_VECTOR (1 downto 0) := B"11";
    signal ICout, ICout2 : STD_LOGIC := '1';
    signal dosndBuf, dosndOld, write_buf, busy, busy_old, data_in_clk, rx_valid : STD_LOGIC := '0';
    signal TWait : STD_LOGIC_VECTOR (7 downto 0);

    signal Address_lpGBT_buf : STD_LOGIC_VECTOR(6 downto 0) := B"1110001";
    signal ByteCntT, ByteCntR, ByteNumR : STD_LOGIC_VECTOR (11 downto 0) := X"000";
    signal adr_buf : STD_LOGIC_VECTOR (15 downto 0);

    signal TMode : STD_LOGIC_VECTOR (3 downto 0) := X"0";
    signal dataTXp : STD_LOGIC_VECTOR (2 downto 0);
    signal NOneT : STD_LOGIC_VECTOR (2 downto 0);
    signal TXbuf : STD_LOGIC_VECTOR (7 downto 0);
    signal data_out_buf : STD_LOGIC_VECTOR (7 downto 0);
    signal parityT, parityR : STD_LOGIC_VECTOR (7 downto 0);
    
    signal ICin, IC1_buf, IC0_buf : STD_LOGIC := '1';
    
    signal DoRx, DoStartRx, data_out_clk : STD_LOGIC := '0';
    signal dataRXp : STD_LOGIC_VECTOR (2 downto 0);
    signal NOneR : STD_LOGIC_VECTOR (2 downto 0);
    signal RXFDbuf : STD_LOGIC_VECTOR (7 downto 0);
    signal RXbuf : STD_LOGIC_VECTOR (7 downto 0);

begin

    data_out <= data_out_buf;
    rx_valid_out <= rx_valid;
    ICData_down <= ICData_down_buf;

    -- 160 MHz:          __    __    __    __    __    __    __    __    __    __    __  
    -- clk160_down     _|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |_
    --                 __                   _____                   _____                
    -- clk_en_dwn       .|_________________|    .|_________________|    .|_______________
    --                  .                       .                       .                
    -- cnt_d[1:0]     000/11111/22222/33333/00000/11111/22222/33333/00000/11111/22222/333

    process (clk) begin
    if rising_edge(clk) then
        data_in_clk_out <= data_in_clk;
        data_out_clk_out <= data_out_clk;
        busy_out <= busy;
    end if;
    end process;

    process (clk160_down) begin
    if rising_edge(clk160_down) then
    
        dosndBuf <= dosnd;
        if clk_en_dwn = '1' then cnt_d <= B"01";
        else cnt_d <= cnt_d + 1; end if;

        -- Downlink: Send IC frame to lpGBT:
        if cnt_d(0) = '0' then
            if TMode = X"0" then                                        -- Idle state, send always '1's:
                ICout <= '1'; data_in_clk <= '0';
                if dosndBuf = '1' then
                    if dosndOld = '0' then                              -- Prepare new frame to send:
                        TMode <= X"1";
                        dataTXp <= B"111";
                        dosndOld <= '1'; busy <= '1';
                        Address_lpGBT_buf <= Address_lpGBT;
                        ByteCntT <= data_num;
                        write_buf <= write;
                        adr_buf <= adr_in;
                    end if;
                else dosndOld <= '0';
                end if;
            elsif TMode = X"1" then                                     -- Send frame delimiter (start):
                ICout <= Frame_delimiter(conv_integer(dataTXp));
                if dataTXp = B"000" then
                    TMode <= X"2";
                    NOneT <= B"000";
                    TXbuf <= X"00";                                     -- Next: Send Reserved byte (zero)
                    parityT <= X"00";
                end if; 
                dataTXp <= dataTXp - 1;
            elsif TMode = X"B" then                                     -- Send frame delimiter (end):
                ICout <= Frame_delimiter(conv_integer(dataTXp));
                if dataTXp = B"000" then TMode <= X"C"; TWait <= X"FF";
                else dataTXp <= dataTXp - 1; end if;
            elsif TMode = X"C" then                                     -- finished: wait for Rx finished
                ICout <= '1';
                if TWait = X"00" then
                    if DoRx = '0' then busy <= '0'; TMode <= X"0"; end if;
                else 
                    if DoRx = '0' then TWait <= TWait - 1; else TWait <= X"00"; end if; 
                end if;
            else                                                        -- Byte to send:            
                if NOneT > 4 then ICout <= '0'; NOneT <= B"000";        -- Sequence of five ones lastly sent? Insert stuffing bit '0' before continuing.    
                else
                    if TXbuf(7-conv_integer(dataTXp)) = '1' then ICout <= '1'; NOneT <= NOneT + 1;  -- Send '1' (and count it).
                    else ICout <= '0'; NOneT <= B"000"; end if;                                   -- Send '0'.
                    dataTXp <= dataTXp - 1;
                end if;
                if dataTXp = B"111" and NOneT < 5 and TMode > 3 then parityT <= parityT xor TXbuf; end if;  -- Add parity
                if dataTXp = B"100" and TMode = 8 and ByteCntT > 0 then data_in_clk <= '1'; end if;     -- Make extern request of new byte
                if dataTXp = B"000" and NOneT < 5 then                                                  -- Byte sent: prepare next byte:
                    case TMode is
                    when X"2" => TXbuf <= Address_lpGBT_buf & not write_buf; TMode <= X"3";   -- lpGBT adress
                    when X"3" => TXbuf <= X"00";                             TMode <= X"4";   -- Command (will be ignored)
                    when X"4" => TXbuf <= ByteCntT(7 downto 0);              TMode <= X"5";   -- Num. Bytes LSB
                    when X"5" => TXbuf <= X"0" & ByteCntT(11 downto 8);      TMode <= X"6";   -- Num. Bytes MSB
                    when X"6" => TXbuf <= adr_buf(7 downto 0);               TMode <= X"7";   -- Mem.Adress LSB
                    when X"7" =>                                                              -- Mem.Adress MSB
                        TXbuf <= adr_buf(15 downto 8);
                        if write_buf = '1' then TMode <= X"8";    
                        else TMode <= X"9"; end if;
                    when X"8" =>                                                              -- Data byte
                        TXbuf <= data_in;
                        ByteCntT <= ByteCntT - 1;
                        if ByteCntT <= 1 then TMode <= X"9"; end if;
                    when X"9" => TXbuf <= parityT;                           TMode <= X"A";    -- Parity
                    when X"A" => TMode <= X"B";                                               -- Parity sent: next will be end frame delimiter
                    when others => 
                    end case;
                    data_in_clk <= '0';
                end if;
            end if;
        else    -- Downlink: Combine the two downstream bits IC[1] and IC[0] and clock them out:
            if cnt_d(1) = '0' then
                ICout2 <= ICout;
            else
                ICData_down_buf <= ICout2 & ICout;
            end if;
        end if;
    end if;
    end process;

    ----------------------------------------------------------------------------------------------------------------------------------------------

    process (clk160_up) begin
    if rising_edge(clk160_up) then
        if clk_en_up = '1' then

            -- Uplink: Clock the two upstream bits IC[1] and IC[0] in:
            IC1_buf <= ICData_up(1);
            IC0_buf <= ICData_up(0);

            cnt_u <= B"01";
        else cnt_u <= cnt_u + 1; end if;

        -- Uplink: Separate the two upstream bits IC[1] and IC[0]:
        if cnt_d(0) = '1' then
            if cnt_d(1) = '0' then
                ICin <= IC1_buf;
            else
                ICin <= IC0_buf;
            end if;  
        else    -- Uplink: Receive IC Frame from lpGBT:
            if RXFDbuf = X"FF" then                 -- Idle state, just ones received:
                DoRx <= '0';
                data_out_clk <= '0';
                if busy = '1' then
                    if busy_old = '0' then busy_old <= '1'; rx_valid <= '0'; end if;
                else busy_old <= '0'; end if;
            elsif RXFDbuf = Frame_delimiter then    -- Frame delimiter received: start or stop receiving:
                if DoRx = '0' then
                    if ICin = '1' then NOneR <= B"001"; else NOneR <= B"000"; end if;
                    RXbuf(0) <= ICin;
                    dataRXp <= B"110";
                    DoRx <= '1'; DoStartRx <= '1';
                    ByteCntR <= X"000"; ByteNumR <= X"000"; parityR <= X"00";
                    rx_valid <= '0';
                else
                    if ByteCntR = ByteNumR + 8 and parityR = 0 then rx_valid <= '1'; end if;
                    DoRx <= '0'; data_out_clk <= '0';
                end if;
            elsif DoRx = '1' then                   -- Byte received:
                if NOneR > 4 then
                    if ICin = '0' then NOneR <= B"000";
                    else
                        if NOneR < 7 then NOneR <= NOneR + 1; end if;
                    end if;
                else
                    RXbuf(7-conv_integer(dataRXp)) <= ICin;
                    if ICin = '1' then NOneR <= NOneR + 1; else NOneR <= B"000"; end if;
                    dataRXp <= dataRXp - 1;
                end if;
                if dataRXp = B"011" and DoStartRx = '0' then
                    if data_out_clk = '0' then
                        if ByteCntR > 1 then parityR <= parityR xor data_out_buf; end if;
                        if ByteCntR = 3 then ByteNumR(7 downto 0) <= data_out_buf; end if;
                        if ByteCntR = 4 then ByteNumR(11 downto 8) <= data_out_buf(3 downto 0);end if;
                        ByteCntR <= ByteCntR + 1;
                    end if;
                    data_out_clk <= '1';
                elsif dataRXp = B"111" and NOneR < 5 then
                    data_out_clk <= '0';
                    data_out_buf <= RXbuf;
                    DoStartRx <= '0';
                end if;
            else
                if busy = '1' then
                    if busy_old = '0' then busy_old <= '1'; rx_valid <= '0'; end if;
                else busy_old <= '0'; end if;
            end if;
            RXFDbuf(7 downto 1) <= RXFDbuf(6 downto 0);
            RXFDbuf(0) <= ICin;
            busy_old <= busy;
        end if;
    end if;
    end process;

end Behavioral;

----------------------------------------------------------------------------------
-- Company: DESY 
-- Engineer: Artur Boebel
-- 
-- Create Date: 18/06/2019
-- Description: Module for controlling the read of a configuration byte from lpGBT 2
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity lpGBT_DoReadM2Reg is
    Port ( clk : in STD_LOGIC;
           Address : in STD_LOGIC_VECTOR (15 downto 0);
           Data_out : out STD_LOGIC_VECTOR (7 downto 0);
           Address_lpGBT_M2 : in STD_LOGIC_VECTOR (6 downto 0);
           lpGBT_I2C_MasterNr : in STD_LOGIC_VECTOR (1 downto 0);
           DoRead : in STD_LOGIC;
           busy_out : out STD_LOGIC;
           rx_valid_out : out STD_LOGIC := '0';
           ICC_NData : out STD_LOGIC_VECTOR (11 downto 0);
           ICC_Addr : out STD_LOGIC_VECTOR (15 downto 0);
           ICC_Din : out STD_LOGIC_VECTOR (7 downto 0);
           ICC_Din_clk : in STD_LOGIC;
           ICC_Dout : in STD_LOGIC_VECTOR (7 downto 0);
           ICC_Dout_clk : in STD_LOGIC;
           ICC_write : out STD_LOGIC := '0';
           ICC_dosend : out STD_LOGIC := '0';
           ICC_busy : in STD_LOGIC;
           ICC_rx_valid : in STD_LOGIC );
end lpGBT_DoReadM2Reg;

architecture Behavioral of lpGBT_DoReadM2Reg is

    signal cntr : std_logic_vector (4 downto 0) := B"00000";
    signal cnt_din, cntWICC : std_logic_vector (2 downto 0) := B"000";

    signal busy, Dout_clk_old, StartOld, I2C_complete : std_logic := '0';

    signal ICC_Addr_B : STD_LOGIC_VECTOR (15 downto 0);
    signal ICC_Din_B : STD_LOGIC_VECTOR (7 downto 0);
    signal ICC_write_B, ICC_dosend_B : std_logic := '0';
    signal ICC_I2Wait : STD_LOGIC_VECTOR (7 downto 0);

    signal ICC_B1 : std_logic_vector (8 downto 0);
    signal ICC_B2 : std_logic_vector (8 downto 0);

begin

    ICC_Din <= ICC_Din_B;
    ICC_Addr <= ICC_Addr_B;
    ICC_write <= ICC_write_B;
    ICC_dosend <= ICC_dosend_B;

    ICC_NData <= X"001";
    busy_out <= busy;

    process(clk) begin
    if rising_edge(clk) then
        if DoRead = '1' and StartOld = '0' and busy = '0' then
            busy <= '1'; cntr <= B"00000"; cntWICC <= B"000";
            case lpGBT_I2C_MasterNr is
            when B"01" =>  ICC_B1 <= B"011110111"; ICC_B2 <= B"101110110";  -- I2CM1: 0x0f7 and 0x176
            when B"10" =>  ICC_B1 <= B"011111110"; ICC_B2 <= B"110001011";  -- I2CM2: 0x0fe and 0x18b
            when others => ICC_B1 <= B"011110000"; ICC_B2 <= B"101100001";  -- I2CM0: 0x0f0 and 0x161
            end case; 
        elsif busy = '1' then
            case cntr is
            when B"00000" => ICC_Addr_B <= ( B"0000000" & ICC_B1 ) + 2; ICC_Din_B <= X"0A"; ICC_write_B <= '1';  -- Write(0x100, 0x0A);
            when B"00010" => ICC_Addr_B <= ( B"0000000" & ICC_B1 ) + 6; ICC_Din_B <= X"00";                      -- Write(0x104, 0x00);
            when B"00100" => ICC_Addr_B <= ( B"0000000" & ICC_B1 ) + 2; ICC_Din_B <= Address(7 downto 0);        -- Write(0x100, Address[7:0]);
            when B"00110" => ICC_Addr_B <= ( B"0000000" & ICC_B1 ) + 3; ICC_Din_B <= Address(15 downto 8);       -- Write(0x101, Address[15:8]);
            when B"01000" => ICC_Addr_B <= ( B"0000000" & ICC_B1 ) + 6; ICC_Din_B <= X"08";                      -- Write(0x104, 0x08);
            when B"01010" => ICC_Addr_B <= ( B"0000000" & ICC_B1 ) + 1; ICC_Din_B <= '0' & Address_lpGBT_M2;     -- Write(0x0FF, Address_lpGBT_M2);
            when B"01100" => ICC_Addr_B <= ( B"0000000" & ICC_B1 ) + 6; ICC_Din_B <= X"0C"; ICC_I2Wait <= X"FF"; -- Write(0x104, 0x0C);
            when B"01110" => ICC_Addr_B <= ( B"0000000" & ICC_B2 ) + 0;                     ICC_write_B <= '0';  -- Read(0x18B);
            when B"10000" => ICC_Addr_B <= ( B"0000000" & ICC_B1 ) + 2; ICC_Din_B <= X"02"; ICC_write_B <= '1';  -- Write(0x100, 0x02);
            when B"10010" => ICC_Addr_B <= ( B"0000000" & ICC_B1 ) + 6; ICC_Din_B <= X"00";                      -- Write(0x104, 0x00);
            when B"10100" => ICC_Addr_B <= ( B"0000000" & ICC_B1 ) + 1; ICC_Din_B <= '0' & Address_lpGBT_M2;     -- Write(0x0FF, Address_lpGBT_M2);
            when B"10110" => ICC_Addr_B <= ( B"0000000" & ICC_B1 ) + 6; ICC_Din_B <= X"03"; ICC_I2Wait <= X"FF"; -- Write(0x104, 0x03);
            when B"11000" => ICC_Addr_B <= ( B"0000000" & ICC_B2 ) + 0;                     ICC_write_B <= '0';  -- Read(0x18B);
            when B"11010" => ICC_Addr_B <= ( B"0000000" & ICC_B2 ) + 2;                     ICC_write_B <= '0';  -- Read(0x18D);
            when B"11100" => busy <= '0';                                                    -- operation finished
            when others =>
            end case;
            if cntr(0) = '0' then
                cnt_din <= B"000";
                if cntr < B"11100" then                                                      
                    if cntWICC < 7 then cntWICC <= cntWICC + 1;
                        if cntWICC > 1 then ICC_dosend_B <= '1'; end if;                     -- Start ICC transmission
                        if ICC_busy = '1' then cntr <= cntr + 1; end if;                     -- ICC transmission running? : ...
                    else ICC_dosend_B <= '0'; rx_valid_out <= '0'; cntr <= B"11100"; end if; -- No response from ICC module: Abort.
                end if;
            else
                ICC_dosend_B <= '0'; cntWICC <= B"000";
                if ICC_write_B = '1' then                                                    -- Last transmission was a write sequence: 
                    if ICC_busy = '0' then                                                   -- ICC (write) transmission finished:
                        if ICC_rx_valid = '1' then cntr <= cntr + 1;                         -- Successfull? Then do next transmission.
                        else rx_valid_out <= '0'; cntr <= B"11100"; end if;                  -- Not successfull? Abort operation.
                    end if;
                else                                                                         -- Last transmission was a read sequence:
                    if ICC_Dout_clk = '1' and Dout_clk_old = '0' then                        -- Receive byte from IC control:
                        if cnt_din = 7 then                                                  -- 8th received byte is the received data:
                            I2C_complete <= ICC_Dout(2);                                     -- If read was I2C Status request: get complete bit.
                            if cntr > B"11010" then Data_out <= ICC_Dout; end if;            -- If read was data request: get received byte.
                        end if;
                        cnt_din <= cnt_din + 1; 
                    end if;
                    Dout_clk_old <= ICC_Dout_clk;
                    if ICC_busy = '0' then                                                   -- ICC (read) transmission finished:
                        if cntr < B"11011" then
                            if I2C_complete = '1' and ICC_rx_valid = '1' then                -- I2C transaction completed and valid?
                                cntr <= cntr + 1;
                            else
                                if ICC_I2Wait = 0 then rx_valid_out <= '0'; cntr <=B"11100"; -- Not successfull? Abort operation.
                                else cntr <= cntr - 1; ICC_I2Wait <= ICC_I2Wait - 1; end if; -- I2C transaction still not completed or not valid? Redo register read.
                            end if;                                   
                        else rx_valid_out <= ICC_rx_valid; cntr <= B"11100"; end if;         -- Finish operation.
                    end if;
                end if;
            end if;
        end if;
        StartOld <= DoRead; 
    end if;
    end process;

end Behavioral;

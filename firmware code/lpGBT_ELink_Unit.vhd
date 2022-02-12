----------------------------------------------------------------------------------
-- Company: DESY 
-- Engineer: Artur Boebel
-- 
-- Create Date: 04/06/2019
-- Description: Generation and monitoring unit for 14 synchronous ELinks (uplink), each running at 640 Mbps.  
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity lpGBT_ELink_Unit is
    Port ( clk160 : in STD_LOGIC;                               -- 160 MHz 10G-packet synchronous clock in
           clk320 : in STD_LOGIC;                               -- 320 MHz clock in
           clk80  : in STD_LOGIC;                               -- 80 MHz clock in
           clk_en : in STD_LOGIC;                               -- 40 MHz clock enable, synchronous to packet
           TestPatGen_on : in STD_LOGIC_VECTOR (13 downto 0);   -- 14 bit: Switch on test pattern generator for each ELink
           SyncPatGen_on : in STD_LOGIC_VECTOR (13 downto 0);   -- 14 bit: Switch on sync pattern generator for each ELink
           SyncPattern : in STD_LOGIC_VECTOR (63 downto 0);     -- 64 bit: Sync Pattern (default: 550103070F1F3F7F)
           HighInv_on : in STD_LOGIC_VECTOR (13 downto 0);      -- 14 bit: Switch on data inverter for each ELink
           Bit_shift : in STD_LOGIC_VECTOR (83 downto 0);       -- 14 x 6 bit: number of bits to shift for data alignment
           elink_inv : in STD_LOGIC_VECTOR (13 downto 0);       -- 14 bit: ELink inverter
           elink_sel : in STD_LOGIC_VECTOR (55 downto 0);       -- 14 x 4 bit: ELink selector for multiplexing
           Pattern_out : out STD_LOGIC_VECTOR (223 downto 0);   -- 14 x 16 bit: pattern output for comparsion with 10G uplink data 
           data_selio_out : out STD_LOGIC_VECTOR (127 downto 0) -- 16 x 8 bit ELink output data (to SelectIO)
    );
end lpGBT_ELink_Unit;

architecture Behavioral of lpGBT_ELink_Unit is

    signal PRBS_31_1 : STD_LOGIC_VECTOR (30 downto 0) := B"0000010000000001000000000000001";
	signal PRBS_31_2 : STD_LOGIC_VECTOR (30 downto 0) := B"0000010000000001000000000000010";
	signal PRBS_FIN : STD_LOGIC_VECTOR (31 downto 0) := X"00000000";
	signal cnt : STD_LOGIC_VECTOR (1 downto 0) := B"00";

	signal data_selio : STD_LOGIC_VECTOR(111 downto 0);
	signal data_selio_buf1 : STD_LOGIC_VECTOR(111 downto 0);
    signal data_selio_sort : STD_LOGIC_VECTOR(127 downto 0) := X"00000000000000000000000000000000";
	signal Pattern_out_buf : STD_LOGIC_VECTOR(223 downto 0);

    signal elink_inv_buf : STD_LOGIC_VECTOR (13 downto 0);
    signal elink_sel_buf : STD_LOGIC_VECTOR (55 downto 0);

	signal SyncCount : STD_LOGIC_VECTOR(2 downto 0);

    type t_14x8 is array(13 downto 0) of std_logic_vector(7 downto 0);
    signal data_elinks: t_14x8;
    type t_14x216 is array(13 downto 0) of std_logic_vector(215 downto 0);
    signal databuf_elinks: t_14x216;

begin

    -- What does this module have to do?
    -- 1) Generate test data patterns for ELink uplink lines
    -- 2) Provide data alignment for later comparsion with the received uplink data
    --     (requires adjustable data delay via FIFO):
      
    --     Data sent over the SelectIO Module (112 bits, 80 MHz clock, sends 8 bits each ELink, results in 640 Mbps):
    --     (D = Ch. 13, ... , 0 = Ch. 0)
    --                               8. bit sent          3. bit sent    2. bit sent    1. bit sent
    --     data_selio(111 downto 0): DCBA9876543210 ..... DCBA9876543210 DCBA9876543210 DCBA9876543210

    --     Data, we will receive from the Uplink (224 bits, 40 MHz Clock):
    --                               Ch. 13               Ch. 2            Ch. 1            Ch. 0
    --     uplinkData(223 downto 0): DDDDDDDDDDDDDDDD ... 2222222222222222 1111111111111111 0000000000000000
    --                               ^              ^
    --                               first bit rec. last

    --     So, the task is also to sort the bits into the right order / register.

    --ELink Output:
    --	(Generate Data)
    --data_selio	[14*8]
    --	(Invert)
    --data_selio_buf1	[14*8]
    --	(Matrix)
    --data_selio_sort	[16*8]
    --	(Out Buf)
    --data_selio_out	[16*8]
    --	(To Select_IO)

    -- Random pattern generator (32 bit), copy from Jonas Wolff:
    process (clk160) begin
    if rising_edge(clk160) then
        if clk_en = '1' then cnt <= B"01";
        else cnt <= cnt + 1; end if;
    
        if cnt(0) = '0' then     
            -- Random pattern generator (32 bit), copy from Jonas Wolff:
            PRBS_31_1(30 downto 1) <= PRBS_31_1(29 downto 0);
            PRBS_31_1(0) <= PRBS_31_1(27) xor PRBS_31_1(30);
            PRBS_31_2(30 downto 1) <= PRBS_31_2(29 downto 0);
            PRBS_31_2(0) <= PRBS_31_2(27) xor PRBS_31_2(30);
            PRBS_FIN <= PRBS_31_1(15 downto 0) & PRBS_31_2(15 downto 0);

            elink_inv_buf <= elink_inv;
            elink_sel_buf <= elink_sel;

            for j in 0 to 13 loop
                for i in 0 to 7 loop
                    -- Generates the test data: Random test pattern or sync pattern or just zeros or just ones:
                    data_selio(i*14+j) <= ( (TestPatGen_on(j) and PRBS_FIN(i*2+j))
                                         or (SyncPatGen_on(j) and SyncPattern(63-conv_integer(SyncCount)*8-i)) ) xor HighInv_on(j);
                    -- Sort the elink bits to each group:
                    data_elinks(j)(i) <= data_selio(i*14+j);

                    -- Apply ELink output inversion:
                    data_selio_buf1(i*14+j) <= data_selio(i*14+j) xor elink_inv_buf(j);

                    -- Apply ELink output matrix selection:
                    data_selio_sort(i*16+conv_integer(elink_sel_buf(j*4+3 downto j*4))) <= data_selio_buf1(i*14+j);
                end loop;
                -- Store the "history" of the last 176 bit of each elink in a FIFO (we have a huge delay on the uplink what must be compensated):
                for k in 0 to 25 loop
                    databuf_elinks(j)(k*8+7 downto k*8) <= databuf_elinks(j)(k*8+15 downto k*8+8);
                end loop;
                databuf_elinks(j)(215 downto 208) <= data_elinks(j);
                -- Extract 16 bit of the "history" to the output of the module:
                for i in 0 to 15 loop
                    Pattern_out_buf(j*16+i) <= databuf_elinks(j)(78 - conv_integer(Bit_shift(j*6+5 downto j*6)) - i);
                end loop;
            end loop;

            SyncCount <= SyncCount + 1;
            -- output pattern, synchronous to clk (40 MHz):
            if cnt(1) = '1' then Pattern_out <= Pattern_out_buf; end if;
        end if; 
    end if; 
    end process;

    -- Take data to select-io register:
    process (clk80) begin
    if rising_edge(clk80) then
        data_selio_out <= data_selio_sort;
    end if; 
    end process;

end Behavioral;

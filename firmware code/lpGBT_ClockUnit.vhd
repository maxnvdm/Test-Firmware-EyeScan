----------------------------------------------------------------------------------
-- Company: DESY 
-- Engineer: Artur Boebel
-- 
-- Create Date: 31/07/2019
-- Description:   
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity lpGBT_ClockUnit is
    Port ( clk100 : in STD_LOGIC;
           clk400 : in STD_LOGIC;
           ClkMeas_in_p : in STD_LOGIC_VECTOR (3 downto 0);
           ClkMeas_in_n : in STD_LOGIC_VECTOR (3 downto 0);
           GetData_LinkNumber : in STD_LOGIC_VECTOR (3 downto 0);
           GetData_req : in STD_LOGIC;
           GetData_Data : out STD_LOGIC_VECTOR (255 downto 0);
           GetData_rdy : out STD_LOGIC );
end lpGBT_ClockUnit;

architecture Behavioral of lpGBT_ClockUnit is

    component selectio_wiz_2 port (
        data_in_from_pins_p : in STD_LOGIC_VECTOR(3 downto 0);
        data_in_from_pins_n : in STD_LOGIC_VECTOR(3 downto 0);
        data_in_to_device : out STD_LOGIC_VECTOR(31 downto 0);
        bitslip : in STD_LOGIC_VECTOR(3 downto 0);
        clk_in : in STD_LOGIC;
        clk_div_in : in STD_LOGIC;
        io_reset : in STD_LOGIC
    ); end component;

    signal GetData_Buffered, GetData_req_buf : STD_LOGIC := '0';
    signal data_selio_in : STD_LOGIC_VECTOR (31 downto 0);
    type t_arr_4x256 is array (3 downto 0) of STD_LOGIC_VECTOR (255 downto 0);
    signal DataPat : t_arr_4x256;

begin

    -- Input stage: 
    selectio_wiz_2_inst : selectio_wiz_2 port map(
        data_in_from_pins_p => ClkMeas_in_p,
        data_in_from_pins_n => ClkMeas_in_n,
        data_in_to_device => data_selio_in,
        bitslip => X"0",
        clk_in => clk400,
        clk_div_in => clk100,
        io_reset => '0'
    );

    process (clk100) begin
    if rising_edge(clk100) then
        -- Data Pattern buffering:
        for j in 0 to 3 loop
            for i in 0 to 30 loop
                DataPat(j)(i*8+15 downto i*8+8) <= DataPat(j)(i*8+7 downto i*8);
            end loop;  
            for i in 0 to 7 loop
                DataPat(j)(i) <= data_selio_in((7-i)*4+j);
            end loop;  
        end loop;  
        -- Write data patterns to GetData output registers:
        GetData_req_buf <= GetData_req;
        if GetData_req_buf = '1' then
            if GetData_Buffered = '0' then
                if GetData_LinkNumber < 4 then
                    GetData_Data <= DataPat(conv_integer(GetData_LinkNumber));
                end if;
                GetData_Buffered <= '1';
            end if;
        else GetData_Buffered <= '0';
        end if;
        GetData_rdy <= GetData_Buffered;
    end if;
    end process;

end Behavioral;

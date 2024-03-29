-------------------------------------------------------
--! @file
--! @author Julian Mendez <julian.mendez@cern.ch> (CERN - EP-ESE-BE)
--! @version 1.0
--! @brief 58bit Order 60 descrambler
-------------------------------------------------------

--! Include the IEEE VHDL standard library
library ieee;
use ieee.std_logic_1164.all;

--! Include the LpGBT-FPGA specific package
--use work.lpgbtfpga_package.all;

--! @brief descrambler60bitOrder58 - 58bit Order 60 descrambler
ENTITY descrambler60bitOrder58 IS
   PORT (
        -- Clocks & reset
        clk_i                             : in  std_logic;
        clkEn_i                           : in  std_logic;
        
        reset_i                           : in  std_logic;
        
        -- Data
        data_i                            : in  std_logic_vector(59 downto 0);
        data_o                            : out std_logic_vector(59 downto 0);
        
        -- Control
        bypass                            : in  std_logic        
   );   
END descrambler60bitOrder58;

--! @brief descrambler60bitOrder58 architecture - 58bit Order 60 descrambler
ARCHITECTURE behabioral of descrambler60bitOrder58 IS

    signal memory_register        : std_logic_vector(59 downto 0);
    signal descrambledData        : std_logic_vector(59 downto 0);
    
BEGIN                 --========####   Architecture Body   ####========-- 
        
    -- Scrambler output register
    reg_proc: process(clk_i, reset_i)
    begin
    
        if rising_edge(clk_i) then
            if reset_i = '1' then
                descrambledData  <= (others => '0');
                memory_register  <= (others => '0');

            elsif clkEn_i = '1' then
                memory_register               <=  data_i;

                descrambledData(59 downto 58) <=  data_i(59 downto 58) xnor data_i(20 downto 19) xnor data_i(1 downto 0);
                descrambledData(57 downto 39) <=  data_i(57 downto 39) xnor data_i(18 downto 0) xnor memory_register(57 downto 39);
                descrambledData(38 downto 0)  <=  data_i(38 downto 0)  xnor memory_register(57 downto 19) xnor memory_register(38 downto 0);

            end if;

        end if;

    end process;

    data_o    <= descrambledData when bypass = '0' else
                 data_i;
    
END behabioral;
--=================================================================================================--
--#################################################################################################--
--=================================================================================================--
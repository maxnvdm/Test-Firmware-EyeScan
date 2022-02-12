----------------------------------------------------------------------------------
-- Company: DESY 
-- Engineer: Artur Boebel
-- 
-- Create Date: 31/05/2019
-- Description: Data deinterleaver for lpGBT upstream for 10.24 Gbps / FEC5
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

--use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VComponents.all;

entity lpGBT_Deinterleaver_10G_FEC5 is
    Port ( data_in : in STD_LOGIC_VECTOR (255 downto 0);
           data_out : out STD_LOGIC_VECTOR (233 downto 0);
           fec_out : out STD_LOGIC_VECTOR (19 downto 0));
end lpGBT_Deinterleaver_10G_FEC5;

architecture Behavioral of lpGBT_Deinterleaver_10G_FEC5 is
    signal reverse : STD_LOGIC_VECTOR (255 downto 0);
begin

    -- Reverse bit order:
    g_GEN_FOR: for i in 0 to 255 generate
        reverse(i) <= data_in(255-i);
    end generate g_GEN_FOR;

    data_out(233 downto 232) <= reverse(253 downto 252);    
    data_out(116 downto 115) <= reverse(251 downto 250);    
    data_out(231 downto 227) <= reverse(249 downto 245);    
    data_out(114 downto 110) <= reverse(244 downto 240);    
    data_out(226 downto 222) <= reverse(239 downto 235);    
    data_out(109 downto 105) <= reverse(234 downto 230);    
    data_out(221 downto 217) <= reverse(229 downto 225);    
    data_out(104 downto 100) <= reverse(224 downto 220);    
    data_out(216 downto 212) <= reverse(219 downto 215);    
    data_out( 99 downto  95) <= reverse(214 downto 210);    
    data_out(211 downto 207) <= reverse(209 downto 205);    
    data_out( 94 downto  90) <= reverse(204 downto 200);    
    data_out(206 downto 202) <= reverse(199 downto 195);    
    data_out( 89 downto  85) <= reverse(194 downto 190);    
    data_out(201 downto 197) <= reverse(189 downto 185);    
    data_out( 84 downto  80) <= reverse(184 downto 180);    
    data_out(196 downto 192) <= reverse(179 downto 175);    
    data_out( 79 downto  75) <= reverse(174 downto 170);    
    data_out(191 downto 187) <= reverse(169 downto 165);    
    data_out( 74 downto  70) <= reverse(164 downto 160);    
    data_out(186 downto 182) <= reverse(159 downto 155);    
    data_out( 69 downto  65) <= reverse(154 downto 150);    
    data_out(181 downto 177) <= reverse(149 downto 145);    
    data_out( 64 downto  60) <= reverse(144 downto 140);    
    data_out(176 downto 172) <= reverse(139 downto 135);    
    data_out( 59 downto  55) <= reverse(134 downto 130);    
    data_out(171 downto 167) <= reverse(129 downto 125);    
    data_out( 54 downto  50) <= reverse(124 downto 120);    
    data_out(166 downto 162) <= reverse(119 downto 115);    
    data_out( 49 downto  45) <= reverse(114 downto 110);    
    data_out(161 downto 157) <= reverse(109 downto 105);    
    data_out( 44 downto  40) <= reverse(104 downto 100);    
    data_out(156 downto 152) <= reverse(99 downto 95);    
    data_out( 39 downto  35) <= reverse(94 downto 90);    
    data_out(151 downto 147) <= reverse(89 downto 85);    
    data_out( 34 downto  30) <= reverse(84 downto 80);    
    data_out(146 downto 142) <= reverse(79 downto 75);    
    data_out( 29 downto  25) <= reverse(74 downto 70);    
    data_out(141 downto 137) <= reverse(69 downto 65);    
    data_out( 24 downto  20) <= reverse(64 downto 60);    
    data_out(136 downto 132) <= reverse(59 downto 55);    
    data_out( 19 downto  15) <= reverse(54 downto 50);    
    data_out(131 downto 127) <= reverse(49 downto 45);    
    data_out( 14 downto  10) <= reverse(44 downto 40);    
    data_out(126 downto 122) <= reverse(39 downto 35);    
    data_out(  9 downto   5) <= reverse(34 downto 30);    
    data_out(121 downto 117) <= reverse(29 downto 25);    
    data_out(  4 downto   0) <= reverse(24 downto 20);    

    fec_out(19 downto 15) <= reverse(19 downto 15);    
    fec_out( 9 downto  5) <= reverse(14 downto 10);    
    fec_out(14 downto 10) <= reverse(9 downto 5);    
    fec_out( 4 downto  0) <= reverse(4 downto 0);    

end Behavioral;

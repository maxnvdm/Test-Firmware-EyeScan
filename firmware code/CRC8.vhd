----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 20.03.2019 13:10:40
-- Design Name: 
-- Module Name: CRC8 - Behav
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity CRC8 is
    Port ( clk : in STD_LOGIC;
           calc : in STD_LOGIC;
           first : in STD_LOGIC;
           inp : in STD_LOGIC_VECTOR(7 downto 0);
           outp_out : out STD_LOGIC_VECTOR(7 downto 0) );
end CRC8;
architecture Behav of CRC8 is
    signal cdly: STD_LOGIC := '0'; 
    signal cx: STD_LOGIC_VECTOR(7 downto 0); 
    signal outp: STD_LOGIC_VECTOR(7 downto 0); 
    type t_array256x8 is array (0 to 255) of STD_LOGIC_VECTOR(7 downto 0);
    constant CRC8c : t_array256x8 := ( X"00", X"07", X"0E", X"09", X"1C", X"1B", X"12", X"15",
                                       X"38", X"3F", X"36", X"31", X"24", X"23", X"2A", X"2D",
                                       X"70", X"77", X"7E", X"79", X"6C", X"6B", X"62", X"65",
                                       X"48", X"4F", X"46", X"41", X"54", X"53", X"5A", X"5D",
                                       X"E0", X"E7", X"EE", X"E9", X"FC", X"FB", X"F2", X"F5",
                                       X"D8", X"DF", X"D6", X"D1", X"C4", X"C3", X"CA", X"CD",
                                       X"90", X"97", X"9E", X"99", X"8C", X"8B", X"82", X"85",
                                       X"A8", X"AF", X"A6", X"A1", X"B4", X"B3", X"BA", X"BD",
                                       X"C7", X"C0", X"C9", X"CE", X"DB", X"DC", X"D5", X"D2",
                                       X"FF", X"F8", X"F1", X"F6", X"E3", X"E4", X"ED", X"EA",
                                       X"B7", X"B0", X"B9", X"BE", X"AB", X"AC", X"A5", X"A2",
                                       X"8F", X"88", X"81", X"86", X"93", X"94", X"9D", X"9A",
                                       X"27", X"20", X"29", X"2E", X"3B", X"3C", X"35", X"32",
                                       X"1F", X"18", X"11", X"16", X"03", X"04", X"0D", X"0A",
                                       X"57", X"50", X"59", X"5E", X"4B", X"4C", X"45", X"42",
                                       X"6F", X"68", X"61", X"66", X"73", X"74", X"7D", X"7A",
                                       X"89", X"8E", X"87", X"80", X"95", X"92", X"9B", X"9C",
                                       X"B1", X"B6", X"BF", X"B8", X"AD", X"AA", X"A3", X"A4",
                                       X"F9", X"FE", X"F7", X"F0", X"E5", X"E2", X"EB", X"EC",
                                       X"C1", X"C6", X"CF", X"C8", X"DD", X"DA", X"D3", X"D4",
                                       X"69", X"6E", X"67", X"60", X"75", X"72", X"7B", X"7C",
                                       X"51", X"56", X"5F", X"58", X"4D", X"4A", X"43", X"44",
                                       X"19", X"1E", X"17", X"10", X"05", X"02", X"0B", X"0C",
                                       X"21", X"26", X"2F", X"28", X"3D", X"3A", X"33", X"34",
                                       X"4E", X"49", X"40", X"47", X"52", X"55", X"5C", X"5B",
                                       X"76", X"71", X"78", X"7F", X"6A", X"6D", X"64", X"63",
                                       X"3E", X"39", X"30", X"37", X"22", X"25", X"2C", X"2B",
                                       X"06", X"01", X"08", X"0F", X"1A", X"1D", X"14", X"13",
                                       X"AE", X"A9", X"A0", X"A7", X"B2", X"B5", X"BC", X"BB",
                                       X"96", X"91", X"98", X"9F", X"8A", X"8D", X"84", X"83",
                                       X"DE", X"D9", X"D0", X"D7", X"C2", X"C5", X"CC", X"CB",
                                       X"E6", X"E1", X"E8", X"EF", X"FA", X"FD", X"F4", X"F3" );
begin
    cx <= X"FF" xor inp when first = '1' else outp xor inp;
    process(clk) begin
    if rising_edge(clk) then
        if cdly = '1' and calc = '0' then outp <= CRC8c(conv_integer(cx)); end if;
        cdly <= calc;
    end if;
    end process;
    outp_out <= outp;
end Behav;

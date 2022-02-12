library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

Library UNISIM;
use UNISIM.vcomponents.all;

entity Transmit_I2C is
    Generic( CDIV : integer;
             Response : integer );
    Port ( clk : in STD_LOGIC;
           start_wr : in STD_LOGIC;
           start_rd : in STD_LOGIC;
           datatxcmdbus : out STD_LOGIC_VECTOR(9 downto 0);
           cmd_paraclk : out STD_LOGIC; 
           cmd_parabyte : in STD_LOGIC_VECTOR(7 downto 0);
           bytenum : in STD_LOGIC_VECTOR(15 downto 0);
           scl : inout STD_LOGIC;
           sda : inout STD_LOGIC
    );
end Transmit_I2C;

architecture Behavioral of Transmit_I2C is

    signal cntr : std_logic_vector (2 downto 0) := B"000";
    signal ck, pck, dly : std_logic := '0';

    signal addr : std_logic_vector (7 downto 0) := X"00";
    signal numbytes : std_logic_vector (7 downto 0) := X"00";
    signal byte : std_logic_vector (7 downto 0) := X"00";
    signal do_read, do_write, data_strobe, I2Cbusy, ack_ok, scl_b_ok, sda_b_ok, scl_e_ok, sda_e_ok : std_logic := '0'; 

begin

    datatxcmdbus(8) <= (start_wr and ck) or (start_rd and data_strobe);
    cmd_paraclk <= (start_wr and data_strobe) or (start_rd and pck);

    I2C_Master_inst: entity work.I2C_Master generic map (CDIV => CDIV) port map (
        clk => clk,
        addr => addr(7 downto 1),
        numbytes => numbytes,
        preprepstart => addr(0),
        do_read => do_read,
        do_write => do_write,
        data_strobe => data_strobe,
        data_out => byte,
        data_in => cmd_parabyte,
        busy_out => I2Cbusy,
        ack_ok => ack_ok,
        scl_b_ok => scl_b_ok,
        sda_b_ok => sda_b_ok,
        scl_e_ok => scl_e_ok,
        sda_e_ok => sda_e_ok,
        scl => scl,
        sda => sda
    ); 

    -- Get the parameter data, prepare and send the response:
    process(clk) begin
    if rising_edge(clk) then
        if start_wr = '1' then
            if cntr < 2 then    -- Get the parameter data:
                if cntr = 0 then
                    addr <= cmd_parabyte;
                    numbytes <= bytenum(7 downto 0) - 3;
                    do_write <= '1';
                    if I2Cbusy = '1' then cntr <= B"001"; end if;
                elsif cntr = 1 then
                    do_write <= '0';
                    if I2Cbusy = '0' then cntr <= B"010"; end if;
                end if;
            elsif cntr < 4 then -- Prepare the response: 
                if ck = '0' then
                        if cntr = 2 then datatxcmdbus(7 downto 0) <= not scl_e_ok & not sda_e_ok & not scl_b_ok & not sda_b_ok & B"000" & not ack_ok;
                        elsif cntr = 3 then datatxcmdbus(7 downto 0) <= conv_std_logic_vector(Response, 8); end if;
                    ck <= '1';  -- Clock the response byte
                else ck <= '0'; cntr <= cntr + 1; end if;
            else ck <= '0'; pck <= '0'; datatxcmdbus(9) <= '1'; end if; -- Send the response packet
        elsif start_rd = '1' then
            if cntr < 2 then    -- Get the parameter data:
                if pck = '0' and dly = '0' then
                    case cntr is 
                    when B"000" => addr <= cmd_parabyte;
                    when B"001" => numbytes <= cmd_parabyte;
                    when others =>
                    end case;
                    pck <= '1'; dly <= '1';
                elsif pck = '1' then pck <= '0'; dly <= '1'; 
                else pck <= '0'; dly <= '0'; cntr <= cntr + 1; end if;
            elsif cntr = 2 then
                do_read <= '1';
                if I2Cbusy = '1' then cntr <= B"011"; end if;
            elsif cntr = 3 then
                datatxcmdbus(7 downto 0) <= byte;
                do_read <= '0';
                if I2Cbusy = '0' then cntr <= B"100"; end if;
            elsif cntr = 4 then
                ck <= '0'; pck <= '0'; datatxcmdbus(9) <= '1';
            end if;
        else 
            ck <= '0'; pck <= '0'; cntr <= B"000";
            datatxcmdbus(7 downto 0) <= X"00";
            datatxcmdbus(9) <= '0';
        end if; 
    end if;
    end process;

end Behavioral;

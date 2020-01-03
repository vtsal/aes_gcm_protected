----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity prng_tb is

end prng_tb;

architecture behavioral of prng_tb is

signal clk: std_logic:='1';
signal ld: std_logic;
signal rseed : std_logic_vector(192 - 1 downto 0);
signal rnum: std_logic_vector(192 - 1 downto 0):=(others => '0');

constant S : integer:=192;
constant R : integer:=192;
constant L : integer:=16; 
constant period : time:=8 ns;

begin

rseed <= x"0123456789abcdef0123456789abcdef0123456789abcdef";

uut1: entity work.PRNG_dut1(structural)
            generic map(S => S, R => R, L => L)
            port map( clk => clk,
				           rseed => rseed,
                       ld  => ld,
                       rnum => rnum
				);

clk <= not clk after period/2;


main_process: process
begin
	 ld <= '1';
	 wait for period;
	 ld <= '0';
    wait for period * 20;
     ld <= '1';
     wait for period;
     ld <= '0';
	  wait for period * 20;
	  

    wait;
end process;	


end behavioral;


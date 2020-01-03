----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity fifo_tb is

end fifo_tb;

architecture behavioral of fifo_tb is
constant period : time:= 8 ns;

signal clk : std_logic:='1';
signal rst, reinit, write, read, almost_full, almost_empty, full, empty : std_logic;
signal din, dout : std_logic_vector(15 downto 0);

begin

fifo_test : entity work.dut_fifo(structure)
    generic map(
        G_LOG2DEPTH => 9,
        G_W => 16
    )
    port map(

        clk => clk,
        rst => rst,
        reinit => reinit,
        write => write,
        read => read,
        din => din,
        dout => dout,
        almost_full => almost_full,
        almost_empty => almost_empty,
        full => full,
        empty => empty
        
        );

clk <= not clk after period/2;

test_process: process
begin
    --rst <= '1';
    reinit <= '0';
    wait for period;
    rst <= '0';
    read <= '0';
    din <= x"1234";
    write <= '1';
    wait for period;
    din <= x"5678";
    wait for period;
    write <= '0';
    wait for period;
    read <= '1';
    wait for period;
    wait for period;
    read <= '0';
    wait for period*5;
    reinit <= '1';
    wait for period;
    reinit <= '0';
    read <= '1';
    wait for period;
    wait for period;
    read <= '0';
    
    wait;
		
end process;

end behavioral;

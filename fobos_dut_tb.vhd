----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
USE ieee.std_logic_textio.all;

LIBRARY std;
USE std.textio.all;

entity fobos_dut_tb is

end fobos_dut_tb;

architecture behavioral of fobos_dut_tb is
constant period : time:= 8 ns;

FILE inFile: TEXT OPEN READ_MODE is "dinFile.txt";
FILE outFile: TEXT OPEN WRITE_MODE is "doutFile.txt";

signal clk : std_logic:='0';
signal rst, di_valid, di_ready, do_valid, do_ready, writestrobe : std_logic:='0';
signal din, dout : std_logic_vector(3 downto 0);

begin

fobos_test : entity work.FOBOS_DUT(structural)
    generic map(
    W => 8,
    SW => 8
    )
    port map(

        clk => clk,
        rst => rst,
        di_valid => di_valid,
        di_ready => di_ready,
        do_valid => do_valid,
        do_ready => do_ready,
        din => din,
        dout => dout
        
        );

clk <= not clk after period/2;
rst <= '0';

test_process: process
begin
    rst <= '0';
    wait for period * 3;
    do_ready <= '1'; 
    wait;
		
end process;

test_ctrl: entity work.test_controller(behavioral)
    port map(
        clk => clk,
        rst => rst,
        do_valid => do_valid,
        writestrobe => writestrobe
        );

readVec: PROCESS(clk)

  VARIABLE VectorLine: LINE;
  VARIABLE VectorValid : BOOLEAN;
  VARIABLE x :    STD_LOGIC_VECTOR(3 DOWNTO 0);
  VARIABLE space: CHARACTER;

BEGIN



IF (rising_edge(clk)) THEN
    if (do_ready = '1') then
        if (not endfile(inFile)) then
		      readline(inFile, VectorLine);
			 end if;
            if (di_ready = '1') then

            --readline(inFile, VectorLine);
            hread(VectorLine, x, good => VectorValid);
            din <= x;
            di_valid <= '1';
            --end if;
         else 
            di_valid <= '0';
       end if;
    else 
        --di_valid <= '0';   
    end if;
end if;

ASSERT VectorValid
Report "Vector Not Valid"

SEVERITY ERROR;
--wait for period/2;

end process;

writeVec: PROCESS(clk)

  VARIABLE VectorLine: LINE;

BEGIN

IF (rising_edge(CLK)) THEN
     IF (do_ready = '1') then
     IF (do_valid = '1') THEN
        
          hwrite(VectorLine, dout);        
          --writeline(outFile, VectorLine);
      END IF;
END IF;
END IF;

IF (rising_edge(CLK)) THEN
	IF (writestrobe = '1') then
		writeline(outFile, VectorLine);
	end if;
end if;

ASSERT False
Report "Writing Result"
SEVERITY NOTE;
--wait for period/2;

END Process;

     
end behavioral;

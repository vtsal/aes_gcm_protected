-- PRNG

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity PRNG_dut1 is
	 generic( S: integer:=192;
			    R: integer:=192;
				 L: integer:=16);
    port(
	 clk		: in std_logic;
	 ld      : in std_logic;
	 rseed   : in std_logic_vector(S-1 downto 0);
    rnum 	: out std_logic_vector(R -1 downto 0):=(others => '0')
    );

end PRNG_dut1;

architecture structural of PRNG_dut1 is

type lfsr_column is array (0 to (R/L)-1) of std_logic_vector(L-1 downto 0);

signal next_lfsr, lfsr : lfsr_column;
 
begin

rnum <= lfsr(3) & lfsr(2) & lfsr(1) & lfsr(0); -- only valid for 16*12 LFSRs for 64 bits of pseudorandomness

i1: for i in 0 to (R/L)-1 generate  -- 64/16 = 4; # of 16-bit LFSRs

-- LFSR = 16,14,13,11

next_lfsr(i)(15) <= rseed(i*L + 15) when (ld = '1') else lfsr(i)(0);
next_lfsr(i)(14) <= rseed(i*L + 14) when (ld = '1') else lfsr(i)(15);
next_lfsr(i)(13) <= rseed(i*L + 13) when (ld = '1') else lfsr(i)(14) xor lfsr(i)(0);
next_lfsr(i)(12) <= rseed(i*L + 12) when (ld = '1') else lfsr(i)(13) xor lfsr(i)(0);
next_lfsr(i)(11) <= rseed(i*L + 11) when (ld = '1') else lfsr(i)(12);
next_lfsr(i)(10) <= rseed(i*L + 10) when (ld = '1') else lfsr(i)(11) xor lfsr(i)(0);
next_lfsr(i)(9) <= rseed(i*L + 9) when (ld = '1') else lfsr(i)(10);
next_lfsr(i)(8) <= rseed(i*L + 8) when (ld = '1') else lfsr(i)(9);
next_lfsr(i)(7) <= rseed(i*L + 7) when (ld = '1') else lfsr(i)(8);
next_lfsr(i)(6) <= rseed(i*L + 6) when (ld = '1') else lfsr(i)(7);
next_lfsr(i)(5) <= rseed(i*L + 5) when (ld = '1') else lfsr(i)(6);
next_lfsr(i)(4) <= rseed(i*L + 4) when (ld = '1') else lfsr(i)(5);
next_lfsr(i)(3) <= rseed(i*L + 3) when (ld = '1') else lfsr(i)(4);
next_lfsr(i)(2) <= rseed(i*L + 2) when (ld = '1') else lfsr(i)(3);
next_lfsr(i)(1) <= rseed(i*L + 1) when (ld = '1') else lfsr(i)(2);
next_lfsr(i)(0) <= rseed(i*L + 0) when (ld = '1') else lfsr(i)(1);

reg1: entity work.dut_regn(behavioral)
	generic map(N=>L)
	port map(
		clk => clk,
		rst => '0',
		en => '1',
		d  => next_lfsr(i),
		q  => lfsr(i)
		);

end generate i1;

end architecture structural;

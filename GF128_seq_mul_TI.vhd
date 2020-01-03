-------------------------------------------------------------------------------
--! @file       GF128_seq_mul_TI.vhd
--! @author     William Diehl
--! @brief      
--! @date       24 May 2018
-------------------------------------------------------------------------------
-- seq multiplier
-- 3-share TI-protected GF 2^128 multiplier

library ieee;
use ieee.std_logic_1164.ALL;
use IEEE.STD_LOGIC_unsigned.all;

entity GF128_seq_mul_TI is
    port (

    clk   : in std_logic;
    start : in std_logic;
    rdi_valid : in std_logic;
    clr_mult : in std_logic;
    busy : out std_logic;
    done  : out std_logic;
    ma, mb   : in std_logic_vector(127 downto 0);
    xa, xb, ya, yb  : in  std_logic_vector(127 downto 0);
    oa, ob		: out std_logic_vector(127 downto 0)
    );

end entity GF128_seq_mul_TI;

architecture structural of GF128_seq_mul_TI is

  function extend_bit ( x : std_logic; size : integer ) return std_logic_vector is
    variable ret : std_logic_vector(size-1 downto 0);
    begin
        for i in 0 to size-1 loop
            ret(i) := x;
        end loop;
        return ret;
    end function extend_bit;
 
constant FIELD : integer:=128;    

type state is (IDLE_ST, INIT_ST, RUN_ST);
signal current_state : state;
signal next_state : state;

signal p, p1, p2, p3, b_reg, b1_reg, b2_reg, b3_reg, a_mul, a1_mul, a2_mul, a3_mul, a_reg, a1_reg, a2_reg, a3_reg, 
       next_b, next_b1, next_b2, next_b3, reverse_a, reverse_a1, reverse_a2, reverse_a3, reverse_b, reverse_b1, reverse_b2, reverse_b3, 
       reverse_o, reverse_oa, reverse_ob : std_logic_vector(FIELD-1 downto 0);
signal x, x1, x2, x3 : std_logic_vector(FIELD downto 0); -- size is FIELD + 1
signal sp, sp1, sp2, sp3, b_mul, b1_mul, b2_mul, b3_mul : std_logic;
signal s_before, s1_before, s2_before, s3_before, s_after, s1_after, s2_after, s3_after, 
       s_after_reg, s1_after_reg, s2_after_reg, s3_after_reg : std_logic_vector(FIELD-1 downto 0);
signal ctr, next_ctr : std_logic_vector(6 downto 0):=(others => '0');
signal en, init, finished : std_logic;
signal result, resulta, resultb, next_result, next_resulta, next_resultb : std_logic_vector(FIELD-1 downto 0);
signal en_result : std_logic;
signal a1, a2, a3, b1, b2, b3 : std_logic_vector(FIELD-1 downto 0);
signal b1_mul_ext, b2_mul_ext, b3_mul_ext : std_logic_vector(FIELD-1 downto 0);

attribute keep_hierarchy : string;
attribute keep_hierarchy of structural: architecture is "true";

begin

-- reshare 2 to 3 shares

a1 <= xa xor ma;
a2 <= ma;
a3 <= xb;

b1 <= ya;
b2 <= yb xor mb;
b3 <= mb;
 
-- the convention used in this aes-gcm is a(127) is lsb ... a(0) is msb
-- however, the multiplier uses a(127) is msb ... a(0) is lsb
-- therefore, input and output must be reversed

reversebits_a1: for i in 0 to 127 generate
                   reverse_a1(i) <= a1_reg(127 - i);
                end generate reversebits_a1;

reversebits_a2: for i in 0 to 127 generate
                   reverse_a2(i) <= a2_reg(127 - i);
                end generate reversebits_a2;

reversebits_a3: for i in 0 to 127 generate
                   reverse_a3(i) <= a3_reg(127 - i);
                end generate reversebits_a3;

reversebits_b1: for i in 0 to 127 generate
                   reverse_b1(i) <= b1(127 - i);
                end generate reversebits_b1;
				 
reversebits_b2: for i in 0 to 127 generate
                   reverse_b2(i) <= b2(127 - i);
                end generate reversebits_b2;

reversebits_b3: for i in 0 to 127 generate
                   reverse_b3(i) <= b3(127 - i);
                end generate reversebits_b3;

reversebits_oa: for i in 0 to 127 generate
                   resulta(i) <= reverse_oa(127 - i);
                end generate reversebits_oa;

reversebits_ob: for i in 0 to 127 generate
                   resultb(i) <= reverse_ob(127 - i);
                end generate reversebits_ob;

finished <= '1' when (ctr = (FIELD - 1)) else '0';

s1_before <= (others => '0') when (init = '1') else s1_after_reg;
s2_before <= (others => '0') when (init = '1') else s2_after_reg;
s3_before <= (others => '0') when (init = '1') else s3_after_reg;

b1_mul <= b1(0) when (init = '1') else b1_reg(FIELD-1);
b2_mul <= b2(0) when (init = '1') else b2_reg(FIELD-1);
b3_mul <= b3(0) when (init = '1') else b3_reg(FIELD-1);

a1_mul <= reverse_a1;
a2_mul <= reverse_a2;
a3_mul <= reverse_a3;

b1_mul_ext <= extend_bit(b1_mul, FIELD);
b2_mul_ext <= extend_bit(b2_mul, FIELD);
b3_mul_ext <= extend_bit(b3_mul, FIELD);

and1: entity work.and_3TI(dataflow)
    port map(
    xa => a2_mul, 
    xb => a3_mul,
    ya => b2_mul_ext,
    yb => b3_mul_ext,
    o => p1
    );

and2: entity work.and_3TI(dataflow)
    port map(
    xa => a3_mul, 
    xb => a1_mul,
    ya => b3_mul_ext,
    yb => b1_mul_ext,
    o => p2
    );

and3: entity work.and_3TI(dataflow)
    port map(
    xa => a1_mul, 
    xb => a2_mul,
    ya => b1_mul_ext,
    yb => b2_mul_ext,
    o => p3
    );


sp1 <= s1_before(FIELD-1) xor p1(FIELD-1);
sp2 <= s2_before(FIELD-1) xor p2(FIELD-1);
sp3 <= s3_before(FIELD-1) xor p3(FIELD-1);

x1 <= sp1 & (s1_before(FIELD-2 downto 7) xor p1(FIELD-2 downto 7)) & (s1_before(6) xor p1(6) xor sp1) & (s1_before(5 downto 2) xor p1(5 downto 2)) &
     (s1_before(1) xor p1(1) xor sp1) & (s1_before(0) xor p1(0) xor sp1) & sp1; -- FIELD + 1 bits

x2 <= sp2 & (s2_before(FIELD-2 downto 7) xor p2(FIELD-2 downto 7)) & (s2_before(6) xor p2(6) xor sp2) & (s2_before(5 downto 2) xor p2(5 downto 2)) &
     (s2_before(1) xor p2(1) xor sp2) & (s2_before(0) xor p2(0) xor sp2) & sp2; -- FIELD + 1 bits

x3 <= sp3 & (s3_before(FIELD-2 downto 7) xor p3(FIELD-2 downto 7)) & (s3_before(6) xor p3(6) xor sp3) & (s3_before(5 downto 2) xor p3(5 downto 2)) &
     (s3_before(1) xor p3(1) xor sp3) & (s3_before(0) xor p3(0) xor sp3) & sp3; -- FIELD + 1 bits

s1_after <= x1(FIELD-1 downto 0); -- FIELD bits
s2_after <= x2(FIELD-1 downto 0); -- FIELD bits
s3_after <= x3(FIELD-1 downto 0); -- FIELD bits

reverse_oa <= p1 xor s3_before xor p3 xor s2_before;
reverse_ob <= p2 xor s1_before;

en_result <= finished or clr_mult;

next_resulta <= resulta when finished = '1' else (others => '0');
next_resultb <= resultb when finished = '1' else (others => '0');

resultrega : entity work.reg_n(behavioral)
    generic map(n=> FIELD)
    port map(
       clk => clk,
       en => en_result,
       d => next_resulta,
       q => oa
    );

resultregb : entity work.reg_n(behavioral)
    generic map(n=> FIELD)
    port map(
       clk => clk,
       en => en_result,
       d => next_resultb,
       q => ob
    );

next_b1 <= (reverse_b1(FIELD-2 downto 0) & '0') when (init = '1') else (b1_reg(FIELD-2 downto 0) & '0');

breg1 : entity work.reg_n(behavioral)
    generic map(n=> FIELD)
    port map(
       clk => clk,
       en => en,
       d => next_b1,
       q => b1_reg
    );

next_b2 <= (reverse_b2(FIELD-2 downto 0) & '0') when (init = '1') else (b2_reg(FIELD-2 downto 0) & '0');

breg2 : entity work.reg_n(behavioral)
    generic map(n=> FIELD)
    port map(
       clk => clk,
       en => en,
       d => next_b2,
       q => b2_reg
    );

next_b3 <= (reverse_b3(FIELD-2 downto 0) & '0') when (init = '1') else (b3_reg(FIELD-2 downto 0) & '0');

breg3 : entity work.reg_n(behavioral)
    generic map(n=> FIELD)
    port map(
       clk => clk,
       en => en,
       d => next_b3,
       q => b3_reg
    );

next_ctr <= ctr + 1;

ctrreg: entity work.reg_n(behavioral)   
    generic map(n=> 7)
    port map(
       clk => clk,
       en => en,
       d => next_ctr,
       q => ctr
    );
	
sreg1: entity work.reg_n(behavioral)   
    generic map(n=> FIELD)
    port map(
      clk => clk,
      en => en,
      d => s1_after,
      q => s1_after_reg
    );

sreg2: entity work.reg_n(behavioral)   
    generic map(n=> FIELD)
    port map(
       clk => clk,
       en => en,
       d => s2_after,
       q => s2_after_reg
    );

sreg3: entity work.reg_n(behavioral)   
    generic map(n=> FIELD)
    port map(
       clk => clk,
       en => en,
       d => s3_after,
       q => s3_after_reg
    );

areg1: entity work.reg_n(behavioral)   
    generic map(n=> FIELD)
	port map(
        clk => clk,
        en => start,
        d => a1,
        q => a1_reg
    );

areg2: entity work.reg_n(behavioral)   
    generic map(n=> FIELD)
    port map(
        clk => clk,
        en => start,
        d => a2,
        q => a2_reg
    );

areg3: entity work.reg_n(behavioral)   
    generic map(n=> FIELD)
    port map(
        clk => clk,
        en => start,
        d => a3,
        q => a3_reg
    );

-- FSM

sync_process: process(clk)
begin

IF (rising_edge(clk)) THEN
	   current_state <= next_state;
END IF;
end process;

public_process: process(current_state, start, rdi_valid, finished)
begin

busy <= '0';
done <= '0';
en <= '0';
init <= '0';

case current_state is
	
   when IDLE_ST =>
        if (start = '1') then
            next_state <= INIT_ST;
        else
            next_state <= IDLE_ST;
        end if;
		
   when INIT_ST =>
        busy <= '1';
        if (rdi_valid = '1') then
            init <= '1';
            en <= '1';
            next_state <= RUN_ST;
        else
            next_state <= INIT_ST;
        end if;
		
   when RUN_ST => 
        busy <= '1';
        if (rdi_valid = '1') then
            if (finished = '1') then
                next_state <= IDLE_ST;
                en <= '1';
                done <= '1';
            else
                en <= '1';
                next_state <= RUN_ST;
            end if;
        else
            next_state <= RUN_ST;
        end if;

   when others => 

end case;
end process;	

end structural;

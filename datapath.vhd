
-------------------------------------------------------------------------------
--! @file       datapath.vhd
--! @author     William Diehl
--! @brief      
--! @date       24 May 2018
-------------------------------------------------------------------------------

-- AES Hybrid 8/32 bit datapath
-- 2/3-share TI protected
-- 5-stage pipeline with 8-bit S-box

library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_unsigned.all;
use IEEE.STD_LOGIC_arith.all;
use work.AES_pkg.all;

entity datapath is
	port(	
		clk : in std_logic;
		en  : in std_logic;
		start : in std_logic;
		rst : in std_logic;
		last_round: out std_logic;

		ksbox_en, rnd_cntr_en, regwrite : in std_logic;
		k_cntr_en, xsel_init, index_en : in std_logic;
		en_bank : in signal4_array;
		en_key_reg : in signal16_array;
		ksel : in std_logic_vector(1 downto 0);
		ssel : in std_logic;
		 
		data_in_a, data_in_b : in std_logic_vector(127 downto 0);
		remask	: in std_logic_vector(39 downto 0);
		key_in_a, key_in_b : in std_logic_vector(127 downto 0);
		douta, doutb : out std_logic_vector(127 downto 0)
            );

END datapath;

ARCHITECTURE structural OF datapath IS	 

-- regsel in upper two bits; colsel in lower two bits; initialized to "1100"
constant regsel_load : std_logic_vector(1 downto 0):="11";

type array16_8_type is array (0 to 15) of std_logic_vector(7 downto 0);
type array3_8_type is array (0 to 2) of std_logic_vector(7 downto 0);
type array4_32_type is array (0 to 3) of std_logic_vector(31 downto 0);

signal key_reg_a, key_reg_b : array16_8_type;
signal en_reg_i, col_reg_en : signal4_array;
signal col_rega, col_regb : array3_8_type; 
signal i_rega, i_regb, rk_update_reg_a, rk_update_reg_b : array4_32_type;

signal next_key_reg_a, next_key_reg_b : std_logic_vector(7 downto 0);
signal rk_update_a, rk_update_b : std_logic_vector(31 downto 0);
signal k12a, k12b, k13a, k13b, k14a, k14b, k15a, k15b : std_logic_vector(7 downto 0);

signal first_key_a_in, first_key_b_in : std_logic_vector(7 downto 0);
signal first_xa, first_xb, first_keya, first_keyb : array16_8_type;

signal first_data_a, first_data_b : std_logic_vector(127 downto 0);

signal previous_ka_in, previous_kb_in, x1a_in, x1b_in : std_logic_vector(7 downto 0);
signal ka_in, kb_in, k1a_in, k1b_in : std_logic_vector(7 downto 0);
signal ksbox_a, ksbox_b : std_logic_vector(7 downto 0);
signal ksbox_rc_a, ksbox_rc_b, round_constant : std_logic_vector(7 downto 0);
signal key_operand_1_a, key_operand_1_b, key_operand_2_a, key_operand_2_b : std_logic_vector(7 downto 0);
signal xa_in, xb_in, sbox_in_a, sbox_in_b, after_subbytes_a, after_subbytes_b : std_logic_vector(7 downto 0);
signal add_roundkey_resulta, add_roundkey_resultb : std_logic_vector(31 downto 0);
signal after_shiftrows_a, after_shiftrows_b,
       before_roundkey_a, before_roundkey_b,
       add_roundkey_resulta_last, add_roundkey_resultb_last,
	   before_roundkey_a_last, before_roundkey_b_last: std_logic_vector(31 downto 0);

signal xa_reg, xb_reg, next_xa_reg, next_xb_reg : array16_8_type;
signal mixcol_resulta, mixcol_resultb, next_roundkey_resulta, next_roundkey_resultb : std_logic_vector(31 downto 0);

signal round, next_rnd_cntr : std_logic_vector(3 downto 0):=x"0";
signal k_cntr, next_k_cntr : std_logic_vector(3 downto 0):=x"0";

signal s_in_sel : std_logic_vector(1 downto 0);
signal finished : std_logic;signal colsel, regsel : std_logic_vector(1 downto 0);
signal colsel_reg, next_colsel_reg, regsel_reg, next_regsel_reg : std_logic_vector(1 downto 0);

begin		  					 

fst_dt_a: entity work.reg_n(behavioral)
       generic map(N => 128)
       port map(
		   clk => clk,
		   d => data_in_a,
		   en => xsel_init,
		   q => first_data_a
	   	);

fst_dt_b: entity work.reg_n(behavioral)
       generic map(N => 128)
       port map(
		   clk => clk,
		   d => data_in_b,
		   en => xsel_init,
		   q => first_data_b
	   	);
			
-- round key scheduling

-- k12, k13, k14 and k15 loaded either from key_in or from key register
 
	 k12a <= key_in_a(127 - 12*8 downto 120 - 12*8) when (round = 0) else key_reg_a(12);
	 k12b <= key_in_b(127 - 12*8 downto 120 - 12*8) when (round = 0) else key_reg_b(12);
	 
	 k13a <= key_in_a(127 - 13*8 downto 120 - 13*8) when (round = 0) else key_reg_a(13);
	 k13b <= key_in_b(127 - 13*8 downto 120 - 13*8) when (round = 0) else key_reg_b(13);
	 
	 k14a <= key_in_a(127 - 14*8 downto 120 - 14*8) when (round = 0) else key_reg_a(14);
	 k14b <= key_in_b(127 - 14*8 downto 120 - 14*8) when (round = 0) else key_reg_b(14);

	 k15a <= key_in_a(127 - 15*8 downto 120 - 15*8) when (round = 0) else key_reg_a(15);
	 k15b <= key_in_b(127 - 15*8 downto 120 - 15*8) when (round = 0) else key_reg_b(15);

-- assign initial key addition and initial status (x) in first round

	ks1: for k in 0 to 15 generate
		first_keya(k) <= key_in_a(127 - k*8 downto 120 - k*8);
		first_keyb(k) <= key_in_b(127 - k*8 downto 120 - k*8);
		first_xa(k) <= first_data_a(127 - k*8 downto 120 - k*8); 
		first_xb(k) <= first_data_b(127 - k*8 downto 120 - k*8);
	end generate ks1;

-- store round keys
	 
    sk1a: for i in 0 to 3 generate
	    sk2a: for j in 0 to 3 generate	

       key_rg_a: entity work.reg_n(behavioral)
       generic map(N => 8)
       port map(
		   clk => clk,
		   d => next_key_reg_a,
		   en => en_key_reg(i*4+j),
		   q => key_reg_a(i*4+j)
	   	);

	    end generate sk2a;
    end generate sk1a;		

    sk1b: for i in 0 to 3 generate
	    sk2b: for j in 0 to 3 generate	

       key_rg_b: entity work.reg_n(behavioral)
       generic map(N => 8)
       port map(
		   clk => clk,
		   d => next_key_reg_b,
		   en => en_key_reg(i*4+j),
		   q => key_reg_b(i*4+j)
	   	);

	    end generate sk2b;
   end generate sk1b;		

-- updated round keys applied at end of rounds

   rk1a: for k in 0 to 3 generate
		rk_update_reg_a(k) <= key_reg_a(k*4+0) & key_reg_a(k*4+1) & key_reg_a(k*4+2) & key_reg_a(k*4+3);
	end generate rk1a;
	
   rk1b: for k in 0 to 3 generate
		rk_update_reg_b(k) <= key_reg_b(k*4+0) & key_reg_b(k*4+1) & key_reg_b(k*4+2) & key_reg_b(k*4+3);
	end generate rk1b;
	
	with regsel select
		rk_update_a <= rk_update_reg_a(0) when "00",
					   rk_update_reg_a(1) when "01",
					   rk_update_reg_a(2) when "10",
					   rk_update_reg_a(3) when "11",
					   (OTHERS => '0') when others;

	with regsel select
		rk_update_b <= rk_update_reg_b(0) when "00",
					   rk_update_reg_b(1) when "01",
					   rk_update_reg_b(2) when "10",
					   rk_update_reg_b(3) when "11",
					   (OTHERS => '0') when others;

-- select proper form of round key for update

    ksbox_rc_a <= after_subbytes_a xor round_constant when (colsel = "00" and ksbox_en = '1') else after_subbytes_a;	
    ksbox_rc_b <= after_subbytes_b; -- round constant only applied to one of two shares
	 
	key_operand_1_a <= first_key_a_in when (round = 0) else ka_in;
	key_operand_1_b <= first_key_b_in when (round = 0) else kb_in;
	 
	key_operand_2_a <= previous_ka_in when (ksbox_en = '0') else ksbox_rc_a;
	key_operand_2_b <= previous_kb_in when (ksbox_en = '0') else ksbox_rc_b;
	 	 
	next_key_reg_a <= key_operand_1_a xor key_operand_2_a;
    next_key_reg_b <= key_operand_1_b xor key_operand_2_b;
	 
	 with round select
		round_constant <= x"01" when x"0",
				x"02" when x"1",
				x"04" when x"2",
				x"08" when x"3",
				x"10" when x"4",
				x"20" when x"5",
				x"40" when x"6",
				x"80" when x"7",
				x"1B" when x"8",
				x"36" when x"9",
				x"00" when others;	

-- keys to use in first round

	with k_cntr select
		first_key_a_in <= first_keya(0) when x"0",	
                          first_keya(1) when x"1",
						  first_keya(2) when x"2",
						  first_keya(3) when x"3",
						  first_keya(4) when x"4",
						  first_keya(5) when x"5",
						  first_keya(6) when x"6",
						  first_keya(7) when x"7",
						  first_keya(8) when x"8",
						  first_keya(9) when x"9",
						  first_keya(10) when x"A",
						  first_keya(11) when x"B",
						  first_keya(12) when x"C",
						  first_keya(13) when x"D",
						  first_keya(14) when x"E",
						  first_keya(15) when x"F",
						  (OTHERS => '0') when others;

	with k_cntr select
		first_key_b_in <= first_keyb(0) when x"0",	
                          first_keyb(1) when x"1",
						  first_keyb(2) when x"2",
						  first_keyb(3) when x"3",
						  first_keyb(4) when x"4",
						  first_keyb(5) when x"5",
						  first_keyb(6) when x"6",
						  first_keyb(7) when x"7",
						  first_keyb(8) when x"8",
						  first_keyb(9) when x"9",
						  first_keyb(10) when x"A",
						  first_keyb(11) when x"B",
						  first_keyb(12) when x"C",
						  first_keyb(13) when x"D",
						  first_keyb(14) when x"E",
						  first_keyb(15) when x"F",
						  (OTHERS => '0') when others;

-- keys to use in all rounds except for 1st

     with k_cntr select
		ka_in <=  key_reg_a(0) when x"0",
         		  key_reg_a(1) when x"1",
    		      key_reg_a(2) when x"2",
		          key_reg_a(3) when x"3",
		          key_reg_a(4) when x"4",
		          key_reg_a(5) when x"5",
		          key_reg_a(6) when x"6",
		          key_reg_a(7) when x"7",
		          key_reg_a(8) when x"8",
		          key_reg_a(9) when x"9",
		          key_reg_a(10) when x"a",
		          key_reg_a(11) when x"b",
		          key_reg_a(12) when x"c",
		          key_reg_a(13) when x"d",
		          key_reg_a(14) when x"e",
		          key_reg_a(15) when x"f",
			      (OTHERS => '0') when others;

     with k_cntr select
		kb_in <=  key_reg_b(0) when x"0",
         		  key_reg_b(1) when x"1",
    		      key_reg_b(2) when x"2",
		          key_reg_b(3) when x"3",
		          key_reg_b(4) when x"4",
		          key_reg_b(5) when x"5",
		          key_reg_b(6) when x"6",
		          key_reg_b(7) when x"7",
		          key_reg_b(8) when x"8",
		          key_reg_b(9) when x"9",
		          key_reg_b(10) when x"a",
		          key_reg_b(11) when x"b",
		          key_reg_b(12) when x"c",
		          key_reg_b(13) when x"d",
		          key_reg_b(14) when x"e",
		          key_reg_b(15) when x"f",
			      (OTHERS => '0') when others;

-- used for round key calculation

	with k_cntr select
		previous_ka_in <= key_reg_a(0) when x"4",
						  key_reg_a(1) when x"5",
						  key_reg_a(2) when x"6",
						  key_reg_a(3) when x"7",
						  key_reg_a(4) when x"8",
						  key_reg_a(5) when x"9",
						  key_reg_a(6) when x"A",
						  key_reg_a(7) when x"B",
						  key_reg_a(8) when x"C",
						  key_reg_a(9) when x"D",
						  key_reg_a(10) when x"E",
						  key_reg_a(11) when x"F",
						  (OTHERS => '0') when others;
								
	with k_cntr select
		previous_kb_in <= key_reg_b(0) when x"4",
						  key_reg_b(1) when x"5",
						  key_reg_b(2) when x"6",
						  key_reg_b(3) when x"7",
						  key_reg_b(4) when x"8",
						  key_reg_b(5) when x"9",
						  key_reg_b(6) when x"A",
						  key_reg_b(7) when x"B",
						  key_reg_b(8) when x"C",
						  key_reg_b(9) when x"D",
						  key_reg_b(10) when x"E",
						  key_reg_b(11) when x"F",
						  (OTHERS => '0') when others;

-- round key additions for initial round key only have to match the 
-- order of status bytes, since "shiftrows" is conducted prior to s box processing

     with k_cntr select
		k1a_in <= first_keya(0) when x"0",
		          first_keya(5) when x"1",
		          first_keya(10) when x"2",
		          first_keya(15) when x"3",
		          first_keya(4) when x"4",
		          first_keya(9) when x"5",
		          first_keya(14) when x"6",
		          first_keya(3) when x"7",
		          first_keya(8) when x"8",
		          first_keya(13) when x"9",
		          first_keya(2) when x"a",
		          first_keya(7) when x"b",
		          first_keya(12) when x"c",
		          first_keya(1) when x"d",
		          first_keya(6) when x"e",
		          first_keya(11) when x"f",
			      (OTHERS => '0') when others;

     with k_cntr select
		k1b_in <= first_keyb(0) when x"0",
		          first_keyb(5) when x"1",
		          first_keyb(10) when x"2",
		          first_keyb(15) when x"3",
		          first_keyb(4) when x"4",
		          first_keyb(9) when x"5",
		          first_keyb(14) when x"6",
		          first_keyb(3) when x"7",
		          first_keyb(8) when x"8",
		          first_keyb(13) when x"9",
		          first_keyb(2) when x"a",
		          first_keyb(7) when x"b",
		          first_keyb(12) when x"c",
		          first_keyb(1) when x"d",
		          first_keyb(6) when x"e",
		          first_keyb(11) when x"f",
			      (OTHERS => '0') when others;

	 next_k_cntr <= (others => '0') when (start = '1') else (k_cntr + 1);	

    k_counter: entity work.reg_n(behavioral)
    generic map(N => 4)
    port map(
		clk => clk,
		d => next_k_cntr,
		en => k_cntr_en,
		q => k_cntr
		);

      with k_cntr select
		x1a_in <= first_xa(0) when x"0",
		          first_xa(5) when x"1",
		          first_xa(10) when x"2",
		          first_xa(15) when x"3",
		          first_xa(4) when x"4",
		          first_xa(9) when x"5",
		          first_xa(14) when x"6",
		          first_xa(3) when x"7",
		          first_xa(8) when x"8",
		          first_xa(13) when x"9",
		          first_xa(2) when x"a",
		          first_xa(7) when x"b",
		          first_xa(12) when x"c",
		          first_xa(1) when x"d",
		          first_xa(6) when x"e",
		          first_xa(11) when x"f",
			      (OTHERS => '0') when others;

     with k_cntr select
		x1b_in <= first_xb(0) when x"0",
		          first_xb(5) when x"1",
		          first_xb(10) when x"2",
		          first_xb(15) when x"3",
		          first_xb(4) when x"4",
		          first_xb(9) when x"5",
		          first_xb(14) when x"6",
		          first_xb(3) when x"7",
		          first_xb(8) when x"8",
		          first_xb(13) when x"9",
		          first_xb(2) when x"a",
		          first_xb(7) when x"b",
		          first_xb(12) when x"c",
		          first_xb(1) when x"d",
		          first_xb(6) when x"e",
		          first_xb(11) when x"f",
			      (OTHERS => '0') when others;

-- status byte to be input to sbox is indexed by "xsel" (provided by controller)
-- the sequence of xsel is 0, 5, 10, 15, 4, 9, 14, 3, 8, 13, 2, 7, 12, 1, 6, 11
-- this performs "shiftrows" prior to entering s-box pipeline

     with k_cntr select
		xa_in <= xa_reg(0) when x"0",
		         xa_reg(5) when x"1",
		     xa_reg(10) when x"2",
		         xa_reg(15) when x"3",
		         xa_reg(4) when x"4",
		         xa_reg(9) when x"5",
		         xa_reg(14) when x"6",
		         xa_reg(3) when x"7",
		         xa_reg(8) when x"8",
		         xa_reg(13) when x"9",
		         xa_reg(2) when x"a",
		         xa_reg(7) when x"b",
		         xa_reg(12) when x"c",
		         xa_reg(1) when x"d",
		         xa_reg(6) when x"e",
		         xa_reg(11) when x"f",
			     (OTHERS => '0') when others;

     with k_cntr select
		xb_in <= xb_reg(0) when x"0",
		         xb_reg(5) when x"1",
		         xb_reg(10) when x"2",
		         xb_reg(15) when x"3",
		         xb_reg(4) when x"4",
		         xb_reg(9) when x"5",
		         xb_reg(14) when x"6",
		         xb_reg(3) when x"7",
		         xb_reg(8) when x"8",
		         xb_reg(13) when x"9",
		         xb_reg(2) when x"a",
		         xb_reg(7) when x"b",
		         xb_reg(12) when x"c",
		         xb_reg(1) when x"d",
		         xb_reg(6) when x"e",
		         xb_reg(11) when x"f",
			     (OTHERS => '0') when others;

next_regsel_reg <= regsel_load when (xsel_init = '1') else (regsel_reg + 1);
next_colsel_reg <= (others => '0') when (xsel_init = '1') else (colsel_reg + 1);
regsel <= regsel_reg;
colsel <= colsel_reg;

-- increments once every 4 cycles

regsel_rg: entity work.reg_n(behavioral)
		generic map(N=>2)
		port map(
			clk => clk,
			en => index_en,
			d => next_regsel_reg,
			q => regsel_reg);

-- increments every cycle

colsel_rg: entity work.reg_n(behavioral)
		generic map(N=>2)
		port map(
			clk => clk,
			en => en,
			d => next_colsel_reg,
			q => colsel_reg);

-- input to S-box pipeline for round key updates k12 - k15			
	  with ksel select
			ksbox_a <= k12a when "00",
					   k13a when "01",
					   k14a when "10",
					   k15a when "11",
					  (OTHERS => '0') when others;

	  with ksel select
			ksbox_b <= k12b when "00",
					   k13b when "01",
					   k14b when "10",
					   k15b when "11",
					   (OTHERS => '0') when others;
	  
	  s_in_sel(1) <= ssel; -- 0 is key to sbox, 1 is status to sbox
	  s_in_sel(0) <= '0' when (round = 0) else '1';

	  with s_in_sel select
			sbox_in_a <=  ksbox_a when "00",
					      ksbox_a when "01",
					      (x1a_in xor k1a_in) when "10",
					      xa_in when "11",
					      (OTHERS => '0') when others;

	  with s_in_sel select
			sbox_in_b <=  ksbox_b when "00",
					      ksbox_b when "01",
					      (x1b_in xor k1b_in) when "10",
					      xb_in when "11",
					      (OTHERS => '0') when others;

-- 5-stage pipelined S-box
-- results of values input on clock cycle 1 are available on clock cycle 5
-- requires 40 bits of randomness per clock cycle for remasking
-- start-up stages are "primed" with random values at every stage to prevent
-- abnormal power condition during start-up stages

     s_box_TI: entity work.AES_Sbox_TI(structural)
		port map(
		clk => clk,
		rst => rst,
		en => en,
		primer => start,
		dina => sbox_in_a,
		dinb => sbox_in_b,
		after_subbytesa => after_subbytes_a,	
		after_subbytesb => after_subbytes_b,
		m => remask
		);

-- 4-byte column is computed at end of every S-box
-- 1st 3 bytes are registered

    col_reg_en(0) <= '1' when (colsel = "00") else '0';
    col_reg_en(1) <= '1' when (colsel = "01") else '0';
    col_reg_en(2) <= '1' when (colsel = "10") else '0';
    col_reg_en(3) <= '1' when (colsel = "11") else '0';

    c1a: for i in 0 to 2 generate

    col_reg_ca: entity work.reg_n(behavioral)
    generic map(N => 8)
    port map(
		clk => clk,
		d => after_subbytes_a,
		en => col_reg_en(i),
		q => col_rega(i)
		);
    end generate c1a;

    c1b: for i in 0 to 2 generate

    col_reg_cb: entity work.reg_n(behavioral)
    generic map(N => 8)
    port map(
		clk => clk,
		d => after_subbytes_b,
		en => col_reg_en(i),
		q => col_regb(i)
		);
    end generate c1b;

    after_shiftrows_a <= col_rega(0) & col_rega(1) & col_rega(2) & after_subbytes_a;
    after_shiftrows_b <= col_regb(0) & col_regb(1) & col_regb(2) & after_subbytes_b;

-- 4 byte column mix columns
	 
    MixCola: entity work.MixCol(structural)
	port map(
		input => after_shiftrows_a,
		output => mixcol_resulta
		);

    MixColb: entity work.MixCol(structural)
	port map(
		input => after_shiftrows_b,
		output => mixcol_resultb
		);

-- two sets of after-mix columns signals are necessary because the 
-- first three columns are computed at round N and final column computed at round N+1

     before_roundkey_a <= after_shiftrows_a when (round > 8) else mixcol_resulta;
     before_roundkey_b <= after_shiftrows_b when (round > 8) else mixcol_resultb;

     before_roundkey_a_last <= after_shiftrows_a when (round > 9) else mixcol_resulta;
     before_roundkey_b_last <= after_shiftrows_b when (round > 9) else mixcol_resultb;

     add_roundkey_resulta <= rk_update_a xor before_roundkey_a; 
     add_roundkey_resultb <= rk_update_b xor before_roundkey_b; 

     add_roundkey_resulta_last <= rk_update_a xor before_roundkey_a_last; 
     add_roundkey_resultb_last <= rk_update_b xor before_roundkey_b_last; 

-- Each 4-byte column result (for 1st 3 columns of new state) is stored until time
-- to store to state variable
  
    en_reg_i(0) <= '1' when (regsel = "00" and regwrite = '1') else '0';
    en_reg_i(1) <= '1' when (regsel = "01" and regwrite = '1') else '0';
    en_reg_i(2) <= '1' when (regsel = "10" and regwrite = '1') else '0';
    en_reg_i(3) <= '1' when (regsel = "11" and regwrite = '1') else '0';

    next_roundkey_resulta <= add_roundkey_resulta_last when (regsel = "11") else add_roundkey_resulta;
    next_roundkey_resultb <= add_roundkey_resultb_last when (regsel = "11") else add_roundkey_resultb;
	 
	 g1a: for i in 0 to 3 generate

    rega_i: entity work.reg_n(behavioral)
    generic map(N => 32)
    port map(
		clk => clk,
		d => next_roundkey_resulta,
		en => en_reg_i(i),
		q => i_rega(i)
		);
    end generate g1a;
   	  
    g1b: for i in 0 to 3 generate

    regb_i: entity work.reg_n(behavioral)
    generic map(N => 32)
    port map(
		clk => clk,
		d => next_roundkey_resultb,
		en => en_reg_i(i),
		q => i_regb(i)
		);
    end generate g1b;

 -- updated status word
 
    r1: for i in 0 to 3 generate
	r2: for j in 0 to 3 generate

    xa_reg_n: entity work.reg_n(behavioral)
    generic map(N => 8)
    port map(
		clk => clk,
		d => next_xa_reg(i*4+j),
		en => en_bank(i),
		q => xa_reg(i*4+j)
		);

    xb_reg_n: entity work.reg_n(behavioral)
    generic map(N => 8)
    port map(
		clk => clk,
		d => next_xb_reg(i*4+j),
		en => en_bank(i),
		q => xb_reg(i*4+j)
		);

	end generate r2;
    end generate r1;

    r3: for i in 0 to 3 generate
	r4: for j in 0 to 3 generate

    	next_xa_reg(i*4+j) <= i_rega(i)(31 - 8*j downto 24 - 8*j); 	
    	next_xb_reg(i*4+j) <= i_regb(i)(31 - 8*j downto 24 - 8*j); 	

    end generate r4;
	end generate r3;

    round_counter: entity work.reg_n(behavioral)
    generic map(N => 4)
    port map(
		clk => clk,
		d => next_rnd_cntr,
		en => rnd_cntr_en,
		q => round
		);

    next_rnd_cntr <= (others => '0') when (start = '1') else (round + 1);	

    finished <= '1' when (round = x"A") else '0';
    last_round <= finished;

--! caution: output not available until last register write

    d1: for j in 0 to 15 generate
	
		 douta(127 - 8*j downto 120 - 8*j) <= xa_reg(j);
		 doutb(127 - 8*j downto 120 - 8*j) <= xb_reg(j);
	 end generate d1;

-- end round update

end structural;

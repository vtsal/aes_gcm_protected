-- GF_INV_GF8_TIa
-------------------------------------------------------------------------------
--! @file       GF_INV_GF8_TIa.vhd
--! @author     William Diehl
--! @brief      
--! @date       24 May 2018
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.ALL;

entity GF_INV_GF8_TIa is
    port (
	 
	clk, rst, en : in std_logic;

	xa  : in  std_logic_vector(7 downto 0);
	xb  : in  std_logic_vector(7 downto 0);

	ya  : out std_logic_vector(7 downto 0);
	yb  : out std_logic_vector(7 downto 0);

	m   : in std_logic_vector(39 downto 0);
	primer : in std_logic

	);

end entity GF_INV_GF8_TIa;

architecture structural of GF_INV_GF8_TIa is

signal r0, r0a, r0b, r0c, r1, r1a, r1c, r1b, SQ_INa, SQ_INb, SQ_INc, 
		 SQ_OUTa, SQ_OUTb, SQ_OUTc, MUL_1_OUTa, MUL_1_OUTb, MUL_1_OUTc,
		 GF_INV_INa, GF_INV_INb, GF_INV_INc, 
		 GF_INV_OUTa, GF_INV_OUTb, GF_INV_OUTc, 
		 MUL_2_OUTa, MUL_2_OUTb, MUL_2_OUTc,
		 MUL_3_OUTa, MUL_3_OUTb, MUL_3_OUTc,
		 MUL_3_OUTa_p, MUL_3_OUTb_p, MUL_3_OUTc_p, 
		 MUL_2_OUTa_p, MUL_2_OUTb_p, MUL_2_OUTc_p	:std_logic_vector(3 downto 0);
		 
signal SQ_OUTa_reg, SQ_OUTb_reg, SQ_OUTc_reg,
	   SQ_OUTa_reg_p, SQ_OUTb_reg_p, SQ_OUTc_reg_p: std_logic_vector(3 downto 0);
				  
signal r1a1_reg, r1a2_reg, r1a3_reg,
       r1b1_reg, r1b2_reg, r1b3_reg,
	   r1c1_reg, r1c2_reg, r1c3_reg,
	   r0a1_reg, r0a2_reg, r0a3_reg,
	   r0b1_reg, r0b2_reg, r0b3_reg,
	   r0c1_reg, r0c2_reg, r0c3_reg : std_logic_vector(3 downto 0);
				  
signal r1a1_reg_p, r1a2_reg_p, r1a3_reg_p, 
	   r1b1_reg_p, r1b2_reg_p, r1b3_reg_p,
	   r1c1_reg_p, r1c2_reg_p, r1c3_reg_p,
	   r0a1_reg_p, r0a2_reg_p, r0a3_reg_p,
	   r0b1_reg_p, r0b2_reg_p, r0b3_reg_p,
	   r0c1_reg_p, r0c2_reg_p, r0c3_reg_p : std_logic_vector(3 downto 0);
		
signal m1, m2, m3, m4 : std_logic_vector(3 downto 0);
signal m5, m6, m7, m8 : std_logic_vector(5 downto 0);

attribute keep : string;

attribute keep of r0, r0a, r0b, r0c, r1, r1a, r1c, r1b, SQ_INa, SQ_INb, SQ_INc, 
		 SQ_OUTa, SQ_OUTb, SQ_OUTc, MUL_1_OUTa, MUL_1_OUTb, MUL_1_OUTc,
		 GF_INV_INa, GF_INV_INb, GF_INV_INc, 
		 GF_INV_OUTa, GF_INV_OUTb, GF_INV_OUTc, 
		 MUL_2_OUTa, MUL_2_OUTb, MUL_2_OUTc,
		 MUL_3_OUTa, MUL_3_OUTb, MUL_3_OUTc, MUL_3_OUTa_p, MUL_3_OUTb_p, 
		 MUL_2_OUTb_p, MUL_2_OUTc_p : signal is "true";

begin

-- generate random masking

		m1 <= m(39 downto 36);
		m2 <= m(35 downto 32);
		m3 <= m(31 downto 28);
		m4 <= m(27 downto 24);
		m5 <= m(23 downto 18);
		m6 <= m(17 downto 12);
		m7 <= m(11 downto 6);
		m8 <= m(5 downto 0);
				
		r1a         <= xa(7 downto 4) xor m1;
		r1b         <= xb(7 downto 4) xor m2;
        r1c	      <= m1 xor m2;

		r0a         <= xa(3 downto 0) xor m3;
		r0b         <= xb(3 downto 0) xor m4;
        r0c	      <= m3 xor m4;

		SQ_INa      <= r1a xor r0a;
		SQ_INb      <= r1b xor r0b;
		SQ_INc      <= r1c xor r0c;

	sqr1a: entity work.GF_SQ_SCL_4(structural)
		port map(
			x => SQ_INa,
			y => SQ_OUTa
			);

	sqr1b: entity work.GF_SQ_SCL_4(structural)
		port map(
			x => SQ_INb,
			y => SQ_OUTb
			);

	sqr1c: entity work.GF_SQ_SCL_4(structural)
		port map(
			x => SQ_INc,
			y => SQ_OUTc
			);

	sqr1a_reg: entity work.reg_n(behavioral)
		generic map(N=>4)
		port map(
			clk => clk,
			--rst => rst,
			en => en,
			d => SQ_OUTa,
			q => SQ_OUTa_reg
			);
			
	sqr1b_reg: entity work.reg_n(behavioral)
		generic map(N=>4)
		port map(
			clk => clk,
			--rst => rst,
			en => en,
			d => SQ_OUTb,
			q => SQ_OUTb_reg
			);

	sqr1c_reg: entity work.reg_n(behavioral)
		generic map(N=>4)
		port map(
			clk => clk,
			--rst => rst,
			en => en,
			d => SQ_OUTc,
			q => SQ_OUTc_reg
			);

	mul1: entity work.GF_MUL_4_TIa(structural)
		port map(
			clk => clk,
			rst => rst,
			en => en,
			primer => primer,
			m => m5,
			xa => r1a,
			xb => r1b,
			xc => r1c,
			ya => r0a,
			yb => r0b,
			yc => r0c,
			oa => MUL_1_OUTa,
			ob => MUL_1_OUTb,
			oc => MUL_1_OUTc
			);

-- prime the pipeline

		SQ_OUTa_reg_p <= m1 when (primer = '1') else SQ_OUTa_reg;
		SQ_OUTb_reg_p <= m2 when (primer = '1') else SQ_OUTb_reg;
		SQ_OUTc_reg_p <= m3 when (primer = '1') else SQ_OUTc_reg;
 	
		GF_INV_INa  <= MUL_1_OUTa xor SQ_OUTa_reg_p;
		GF_INV_INb  <= MUL_1_OUTb xor SQ_OUTb_reg_p;
	    GF_INV_INc  <= MUL_1_OUTc xor SQ_OUTc_reg_p;

	inv1: entity work.GF_INV_4_TIa(structural)
		port map(
			clk => clk,
			rst => rst,
			en => en,
			primer => primer,
			m => m6,

			xa => GF_INV_INa,
			xb => GF_INV_INb,
			xc => GF_INV_INc,
			ya => GF_INV_OUTa,
			yb => GF_INV_OUTb,
			yc => GF_INV_OUTc
			);

r0a_rg1: entity work.reg_n(behavioral)
		generic map(N=>4)
		port map(
			clk => clk,
			--rst => rst,
			en => en,
			d => r0a,
			q => r0a1_reg
			);

r0a1_reg_p <= m4 when (primer = '1') else r0a1_reg;

r0a_rg2: entity work.reg_n(behavioral)
		generic map(N=>4)
		port map(
			clk => clk,
			--rst => rst,
			en => en,
			d => r0a1_reg_p,
			q => r0a2_reg
			);

r0a2_reg_p <= m5(4 downto 1) when (primer = '1') else r0a2_reg;

r0a_rg3: entity work.reg_n(behavioral)
		generic map(N=>4)
		port map(
			clk => clk,
			--rst => rst,
			en => en,
			d => r0a2_reg_p,
			q => r0a3_reg
			);

r0a3_reg_p <= m6(5 downto 2) when (primer = '1') else r0a3_reg;

r0b_rg1: entity work.reg_n(behavioral)
		generic map(N=>4)
		port map(
			clk => clk,
			--rst => rst,
			en => en,
			d => r0b,
			q => r0b1_reg
			);

r0b1_reg_p <= (m7(2 downto 0) & m6(3)) when (primer = '1') else r0b1_reg;

r0b_rg2: entity work.reg_n(behavioral)
		generic map(N=>4)
		port map(
			clk => clk,
			--rst => rst,
			en => en,
			d => r0b1_reg_p,
			q => r0b2_reg
			);

r0b2_reg_p <= m6(3 downto 0) when (primer = '1') else r0b2_reg;

r0b_rg3: entity work.reg_n(behavioral)
		generic map(N=>4)
		port map(
			clk => clk,
			--rst => rst,
			en => en,
			d => r0b2_reg_p,
			q => r0b3_reg
			);

r0b3_reg_p <= m8(4 downto 1) when (primer = '1') else r0b3_reg;

r0c_rg1: entity work.reg_n(behavioral)
		generic map(N=>4)
		port map(
			clk => clk,
			--rst => rst,
			en => en,
			d => r0c,
			q => r0c1_reg
			);

r0c1_reg_p <= (m2(1 downto 0) & m3(1 downto 0)) when (primer = '1') else r0c1_reg;

r0c_rg2: entity work.reg_n(behavioral)
		generic map(N=>4)
		port map(
			clk => clk,
			--rst => rst,
			en => en,
			d => r0c1_reg_p,
			q => r0c2_reg
			);

r0c2_reg_p <= m1 when (primer = '1') else r0c2_reg;

r0c_rg3: entity work.reg_n(behavioral)
		generic map(N=>4)
		port map(
			clk => clk,
			--rst => rst,
			en => en,
			d => r0c2_reg_p,
			q => r0c3_reg
			);

r0c3_reg_p <= m2 when (primer = '1') else r0c3_reg;

r1a_rg1: entity work.reg_n(behavioral)
		generic map(N=>4)
		port map(
			clk => clk,
			--rst => rst,
			en => en,
			d => r1a,
			q => r1a1_reg
			);

r1a1_reg_p <= m3 when (primer = '1') else r1a1_reg;

r1a_rg2: entity work.reg_n(behavioral)
		generic map(N=>4)
		port map(
			clk => clk,
			--rst => rst,
			en => en,
			d => r1a1_reg_p,
			q => r1a2_reg
			);

r1a2_reg_p <= m4 when (primer = '1') else r1a2_reg;

r1a_rg3: entity work.reg_n(behavioral)
		generic map(N=>4)
		port map(
			clk => clk,
			--rst => rst,
			en => en,
			d => r1a2_reg_p,
			q => r1a3_reg
			);

r1a3_reg_p <= m5(3 downto 0) when (primer = '1') else r1a3_reg;

r1b_rg1: entity work.reg_n(behavioral)
		generic map(N=>4)
		port map(
			clk => clk,
			--rst => rst,
			en => en,
			d => r1b,
			q => r1b1_reg
			);

r1b1_reg_p <= m6(5 downto 2) when (primer = '1') else r1b1_reg;

r1b_rg2: entity work.reg_n(behavioral)
		generic map(N=>4)
		port map(
			clk => clk,
			--rst => rst,
			en => en,
			d => r1b1_reg_p,
			q => r1b2_reg
			);

r1b2_reg_p <= m1 when (primer = '1') else r1b2_reg;

r1b_rg3: entity work.reg_n(behavioral)
		generic map(N=>4)
		port map(
			clk => clk,
			--rst => rst,
			en => en,
			d => r1b2_reg_p,
			q => r1b3_reg
			);

r1b3_reg_p <= m8(3 downto 0) when (primer = '1') else r1b3_reg;

r1c_rg1: entity work.reg_n(behavioral)
		generic map(N=>4)
		port map(
			clk => clk,
			--rst => rst,
			en => en,
			d => r1c,
			q => r1c1_reg
			);

r1c1_reg_p <= m3 when (primer = '1') else r1c1_reg;

r1c_rg2: entity work.reg_n(behavioral)
		generic map(N=>4)
		port map(
			clk => clk,
			--rst => rst,
			en => en,
			d => r1c1_reg_p,
			q => r1c2_reg
			);

r1c2_reg_p <= m4 when (primer = '1') else r1c2_reg;

r1c_rg3: entity work.reg_n(behavioral)
		generic map(N=>4)
		port map(
			clk => clk,
			--rst => rst,
			en => en,
			d => r1c2_reg_p,
			q => r1c3_reg
			);

r1c3_reg_p <= m5(3 downto 0) when (primer = '1') else r1c3_reg;

	mul2: entity work.GF_MUL_4_TIa(structural)
		port map(
			clk => clk,
			rst => rst,
			en => en,
			primer => primer,
			m => m7,

			xa => r1a3_reg_p,
			xb => r1b3_reg_p,
			xc => r1c3_reg_p,
			ya => GF_INV_OUTa,
			yb => GF_INV_OUTb,
			yc => GF_INV_OUTc,	
			oa => MUL_2_OUTa,
			ob => MUL_2_OUTb,
			oc => MUL_2_OUTc
			);

	mul3: entity work.GF_MUL_4_TIa(structural)
	port map(
			clk => clk,
			rst => rst,
			en => en,
			primer => primer,
			m => m8,

			xa => GF_INV_OUTa,
			xb => GF_INV_OUTb,
			xc => GF_INV_OUTc,
			ya => r0a3_reg_p,
			yb => r0b3_reg_p,
			yc => r0c3_reg_p,
			oa => MUL_3_OUTa,
			ob => MUL_3_OUTb,	
			oc => MUL_3_OUTc
			);

		MUL_3_OUTa_p <= m1(2)& m3(2) & m4(1) & m2(0) when (primer = '1') else MUL_3_OUTa;
		MUL_3_OUTb_p <= m1(1)& m3(3) & m4(2) & m2(2) when (primer = '1') else MUL_3_OUTb;
		MUL_3_OUTc_p <= m1(0)& m3(1) & m4(2) & m2(3) when (primer = '1') else MUL_3_OUTc;
		
		MUL_2_OUTa_p <= m4(2)& m1(2) & m2(1) & m1(0) when (primer = '1') else MUL_2_OUTa;
		MUL_2_OUTb_p <= m2(1)& m2(3) & m3(2) & m4(2) when (primer = '1') else MUL_2_OUTb;
		MUL_2_OUTc_p <= m3(0)& m4(1) & m1(2) & m3(3) when (primer = '1') else MUL_2_OUTc;
				
		ya <= (MUL_3_OUTa_p xor MUL_3_OUTb_p) & MUL_2_OUTa_p;
		yb <= MUL_3_OUTc_p & (MUL_2_OUTb_p xor MUL_2_OUTc_p);
      
end structural;

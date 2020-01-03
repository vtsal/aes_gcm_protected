-- GF_INV_4_TIa

-------------------------------------------------------------------------------
--! @file       GF_INV_4_TIa.vhd
--! @author     William Diehl
--! @brief      
--! @date       24 May 2018
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.ALL;

entity GF_INV_4_TIa is
    port (

	clk, rst, en, primer : in std_logic;
	
	xa  : in  std_logic_vector(3 downto 0);
	xb  : in  std_logic_vector(3 downto 0);
	xc  : in  std_logic_vector(3 downto 0);

	m	 : in std_logic_vector(5 downto 0);
	
	ya		: out std_logic_vector(3 downto 0);
	yb		: out std_logic_vector(3 downto 0);
	yc		: out std_logic_vector(3 downto 0)

	);

end entity GF_INV_4_TIa;

architecture structural of GF_INV_4_TIa is

signal r0, r0a, r0b, r0c, r1, r1a, r1b, r1c,
	   SQ_INa, SQ_INb, SQ_INc, 
	   SQ_OUTa, SQ_OUTb, SQ_OUTc,
       MUL_1_OUTa, MUL_1_OUTb, MUL_1_OUTc,
	   GF_INV_INa, GF_INV_INb, GF_INV_INc,
	   GF_INV_OUTa,  GF_INV_OUTb, GF_INV_OUTc,
	   MUL_2_OUTa, MUL_2_OUTb, MUL_2_OUTc, MUL_2_OUT,
	   MUL_3_OUTa, MUL_3_OUTb, MUL_3_OUTc, MUL_3_OUT,
	   m1, m2, m3, m4 :std_logic_vector(1 downto 0);

signal MUL_1_OUTa_reg, MUL_1_OUTb_reg, MUL_1_OUTc_reg,
  	   MUL_2_OUTa_reg, MUL_2_OUTb_reg, MUL_2_OUTc_reg,
	   MUL_3_OUTa_reg, MUL_3_OUTb_reg, MUL_3_OUTc_reg,
	   SQ_OUTa_reg, SQ_OUTb_reg, SQ_OUTc_reg,
       r1a_reg, r1b_reg, r1c_reg, r0a_reg, r0b_reg, r0c_reg : std_logic_vector(1 downto 0);
		 
signal SQ_OUTa_reg_p, SQ_OUTb_reg_p, SQ_OUTc_reg_p,
       r1a_reg_p, r1b_reg_p, r1c_reg_p, r0a_reg_p, r0b_reg_p, r0c_reg_p : std_logic_vector(1 downto 0);
		 
attribute keep : string;

attribute keep of r0, r0a, r0b, r0c, r1, r1a, r1b, r1c,
		 SQ_INa, SQ_INb, SQ_INc, 
		 SQ_OUTa, SQ_OUTb, SQ_OUTc,
         MUL_1_OUTa, MUL_1_OUTb, MUL_1_OUTc,
		 GF_INV_INa, GF_INV_INb, GF_INV_INc,
		 GF_INV_OUTa,  GF_INV_OUTb, GF_INV_OUTc,
		 MUL_2_OUTa, MUL_2_OUTb, MUL_2_OUTc, MUL_2_OUT,
		 MUL_3_OUTa, MUL_3_OUTb, MUL_3_OUTc, MUL_3_OUT : signal is "true";

begin

r1a <= xa(3 downto 2);
r1b <= xb(3 downto 2);
r1c <= xc(3 downto 2);

r0a <= xa(1 downto 0);
r0b <= xb(1 downto 0);
r0c <= xc(1 downto 0);

SQ_INa <= r1a xor r0a;
SQ_INb <= r1b xor r0b;
SQ_INc <= r1c xor r0c;

	sqr1a: entity work.GF_SQ_SCL_2(dataflow)
		port map(
			x => SQ_INa,
			y => SQ_OUTa
			);

	sqr1b: entity work.GF_SQ_SCL_2(dataflow)
		port map(
			x => SQ_INb,
			y => SQ_OUTb
			);

	sqr1c: entity work.GF_SQ_SCL_2(dataflow)
		port map(
			x => SQ_INc,
			y => SQ_OUTc
			);

	sqr1a_reg: entity work.reg_n(behavioral)
		generic map(N=>2)
		port map(
			clk => clk,
			--rst => rst,
			en => en,
			d => SQ_OUTa,
			q => SQ_OUTa_reg
			);

	sqr1b_reg: entity work.reg_n(behavioral)
		generic map(N=>2)
		port map(
			clk => clk,
			--rst => rst,
			en => en,
			d => SQ_OUTb,
			q => SQ_OUTb_reg
			);

	sqr1c_reg: entity work.reg_n(behavioral)
		generic map(N=>2)
		port map(
			clk => clk,
			--rst => rst,
			en => en,
			d => SQ_OUTc,
			q => SQ_OUTc_reg
			);

	r1a_rg: entity work.reg_n(behavioral)
		generic map(N=>2)
		port map(
			clk => clk,
			--rst => rst,
			en => en,
			d => r1a,
			q => r1a_reg
			);

	r1b_rg: entity work.reg_n(behavioral)
		generic map(N=>2)
		port map(
			clk => clk,
			--rst => rst,
			en => en,
			d => r1b,
			q => r1b_reg
			);

	r1c_rg: entity work.reg_n(behavioral)
		generic map(N=>2)
		port map(
			clk => clk,
			--rst => rst,
			en => en,
			d => r1c,
			q => r1c_reg
			);
			
	r0a_rg: entity work.reg_n(behavioral)
		generic map(N=>2)
		port map(
			clk => clk,
			--rst => rst,
			en => en,
			d => r0a,
			q => r0a_reg
			);
			
		r0b_rg: entity work.reg_n(behavioral)
		generic map(N=>2)
		port map(
			clk => clk,
			--rst => rst,
			en => en,
			d => r0b,
			q => r0b_reg
			);
		
	r0c_rg: entity work.reg_n(behavioral)
		generic map(N=>2)
		port map(
			clk => clk,
			--rst => rst,
			en => en,
			d => r0c,
			q => r0c_reg
			);

	mul1a: entity work.GF_MUL_2_TIma(dataflow)
		port map(
			xa => r1b,
			xb => r1c,
			ya => r0b,
			yb => r0c,
			m => m(1 downto 0),
			o => MUL_1_OUTa
			);
			
	mul1b: entity work.GF_MUL_2_TImb(dataflow)
		port map(
			xa => r1c,
			xb => r1a,
			ya => r0c,
			yb => r0a,
			m => m(1 downto 0),
			o => MUL_1_OUTb
			);

	mul1c: entity work.GF_MUL_2_TImc(dataflow)
		port map(
			xa => r1a,
			xb => r1b,
			ya => r0a,
			yb => r0b,
			m => m(1 downto 0),
			o => MUL_1_OUTc
			);

	mul1a_reg: entity work.reg_n(behavioral)
		generic map(N=>2)
		port map(
			clk => clk,
			--rst => rst,
			en => en,
			d => MUL_1_OUTa,
			q => MUL_1_OUTa_reg
			);

	mul1b_reg: entity work.reg_n(behavioral)
		generic map(N=>2)
		port map(
			clk => clk,
			--rst => rst,
			en => en,
			d => MUL_1_OUTb,
			q => MUL_1_OUTb_reg
			);

	mul1c_reg: entity work.reg_n(behavioral)
		generic map(N=>2)
		port map(
			clk => clk,
			--rst => rst,
			en => en,
			d => MUL_1_OUTc,
			q => MUL_1_OUTc_reg
			);

    SQ_OUTa_reg_p <= m(5 downto 4) when (primer = '1') else SQ_OUTa_reg;  
	SQ_OUTb_reg_p <= m(3 downto 2) when (primer = '1') else SQ_OUTb_reg;  
	SQ_OUTc_reg_p <= m(1 downto 0) when (primer = '1') else SQ_OUTc_reg;  

	GF_INV_INa  <= MUL_1_OUTa_reg xor SQ_OUTa_reg_p;
	GF_INV_INb  <= MUL_1_OUTb_reg xor SQ_OUTb_reg_p;
	GF_INV_INc  <= MUL_1_OUTc_reg xor SQ_OUTc_reg_p;
	
	inv1a: entity work.GF_INV_2(dataflow)
		port map(
			x => GF_INV_INa,
			y => GF_INV_OUTa
			);
		
	inv1b: entity work.GF_INV_2(dataflow)
		port map(
			x => GF_INV_INb,
			y => GF_INV_OUTb
			);

	inv1c: entity work.GF_INV_2(dataflow)
		port map(
			x => GF_INV_INc,
			y => GF_INV_OUTc
			);

    r1a_reg_p <= m(4 downto 3) when (primer = '1') else r1a_reg;
	r1b_reg_p <= m(2 downto 1) when (primer = '1') else r1b_reg;
	r1c_reg_p <= m(0) & m(5) when (primer = '1') else r1c_reg;

    r0a_reg_p <= m(5) & m(1) when (primer = '1') else r0a_reg;
	r0b_reg_p <= m(2) & m(4) when (primer = '1') else r0b_reg;
	r0c_reg_p <= m(3) & m(0) when (primer = '1') else r0c_reg;

	mul2a: entity work.GF_MUL_2_TIma(dataflow)
		port map(
			xa => r1b_reg_p,
			xb => r1c_reg_p,
			ya => GF_INV_OUTb,
			yb => GF_INV_OUTc,
			m => m(3 downto 2),
			o => MUL_2_OUTa
			);

	mul2b: entity work.GF_MUL_2_TImb(dataflow)
		port map(
			xa => r1c_reg_p,
			xb => r1a_reg_p,
			ya => GF_INV_OUTc,
			yb => GF_INV_OUTa,
			m => m(3 downto 2),
			o => MUL_2_OUTb
			);

	mul2c: entity work.GF_MUL_2_TImc(dataflow)
		port map(
			xa => r1a_reg_p,
			xb => r1b_reg_p,
			ya => GF_INV_OUTa,
			yb => GF_INV_OUTb,
			m => m(3 downto 2),
			o => MUL_2_OUTc
			);

	mul2a_reg: entity work.reg_n(behavioral)
		generic map(N=>2)
		port map(
			clk => clk,
			--rst => rst,
			en => en,
			d => MUL_2_OUTa,
			q => MUL_2_OUTa_reg
			);

	mul2b_reg: entity work.reg_n(behavioral)
		generic map(N=>2)
		port map(
			clk => clk,
			--rst => rst,
			en => en,
			d => MUL_2_OUTb,
			q => MUL_2_OUTb_reg
			);

	mul2c_reg: entity work.reg_n(behavioral)
		generic map(N=>2)
		port map(
			clk => clk,
			--rst => rst,
			en => en,
			d => MUL_2_OUTc,
			q => MUL_2_OUTc_reg
			);

	mul3a: entity work.GF_MUL_2_TIma(dataflow)
		port map(
			xa => GF_INV_OUTb,
			xb => GF_INV_OUTc,
			ya => r0b_reg_p,
			yb => r0c_reg_p,
			m => m(5 downto 4),
			o => MUL_3_OUTa
			);

	mul3b: entity work.GF_MUL_2_TImb(dataflow)
		port map(
			xa => GF_INV_OUTc,
			xb => GF_INV_OUTa,
			ya => r0c_reg_p,
			yb => r0a_reg_p,
			m => m(5 downto 4),
			o => MUL_3_OUTb
			);

	mul3c: entity work.GF_MUL_2_TImc(dataflow)
		port map(
			xa => GF_INV_OUTa,
			xb => GF_INV_OUTb,
			ya => r0a_reg_p,
			yb => r0b_reg_p,
			m => m(5 downto 4),
			o => MUL_3_OUTc
			);

	mul3a_reg: entity work.reg_n(behavioral)
		generic map(N=>2)
		port map(
			clk => clk,
			--rst => rst,
			en => en,
			d => MUL_3_OUTa,
			q => MUL_3_OUTa_reg
			);

	mul3b_reg: entity work.reg_n(behavioral)
		generic map(N=>2)
		port map(
			clk => clk,
			--rst => rst,
			en => en,
			d => MUL_3_OUTb,
			q => MUL_3_OUTb_reg
			);

	mul3c_reg: entity work.reg_n(behavioral)
		generic map(N=>2)
		port map(
			clk => clk,
			--rst => rst,
			en => en,
			d => MUL_3_OUTc,
			q => MUL_3_OUTc_reg
			);

	ya <= MUL_3_OUTa_reg & MUL_2_OUTa_reg;
	yb <= MUL_3_OUTb_reg & MUL_2_OUTb_reg;
	yc <= MUL_3_OUTc_reg & MUL_2_OUTc_reg;

end structural;

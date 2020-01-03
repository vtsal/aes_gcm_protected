-- GF_MUL_4_TIa
-------------------------------------------------------------------------------
--! @file       GF_MUL_4_TIa.vhd
--! @author     William Diehl
--! @brief      
--! @date       24 May 2018
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.ALL;

entity GF_MUL_4_TIa is
    port (

    clk, rst, en, primer : in std_logic;
    xa : in  std_logic_vector(3 downto 0);
    xb : in  std_logic_vector(3 downto 0);
    xc : in  std_logic_vector(3 downto 0);

    ya : in  std_logic_vector(3 downto 0);
    yb : in  std_logic_vector(3 downto 0);
    yc : in  std_logic_vector(3 downto 0);

    m  : in std_logic_vector(5 downto 0);
	
    oa : out std_logic_vector(3 downto 0);
    ob : out std_logic_vector(3 downto 0);
    oc : out std_logic_vector(3 downto 0)

    );

end entity GF_MUL_4_TIa;

architecture structural of GF_MUL_4_TIa is

signal tao1, tao1a, tao1b, tao1c, tao0, tao0a, tao0b, tao0c,
       delta1, delta1a, delta1b, delta1c, delta0, delta0a, delta0b, delta0c, 
       fi1a, fi1b, fi1c, fi0a, fi0b, fi0c, tmp1a, tmp1b, tmp1c, tmp0a, tmp0b, tmp0c, RES_MUL1a, RES_MUL1b, RES_MUL1c,
       RES_MUL0a, RES_MUL0b, RES_MUL0c,
       RES_MUL_SCL, RES_MUL_SCLa, RES_MUL_SCLb, RES_MUL_SCLc: std_logic_vector(1 downto 0);

signal RES_MUL1a_reg, RES_MUL1b_reg, RES_MUL1c_reg,
       RES_MUL0a_reg, RES_MUL0b_reg, RES_MUL0c_reg,
       RES_MUL_SCLa_reg, RES_MUL_SCLb_reg, RES_MUL_SCLc_reg: std_logic_vector(1 downto 0);

signal RES_MUL1a_reg_p, RES_MUL1b_reg_p, RES_MUL1c_reg_p,
       RES_MUL0a_reg_p, RES_MUL0b_reg_p, RES_MUL0c_reg_p,
       RES_MUL_SCLa_reg_p, RES_MUL_SCLb_reg_p, RES_MUL_SCLc_reg_p: std_logic_vector(1 downto 0);

attribute keep : string;

attribute keep of tao1, tao1a, tao1b, tao1c, tao0, tao0a, tao0b, tao0c,
       delta1, delta1a, delta1b, delta1c, delta0, delta0a, delta0b, delta0c, 
       fi1a, fi1b, fi1c, fi0a, fi0b, fi0c, tmp1a, tmp1b, tmp1c, tmp0a, tmp0b, tmp0c, RES_MUL1a, RES_MUL1b, RES_MUL1c,
       RES_MUL0a, RES_MUL0b, RES_MUL0c,
       RES_MUL_SCL, RES_MUL_SCLa, RES_MUL_SCLb, RES_MUL_SCLc: signal is "true";

begin

-- generate masking


   tao1a    <= xa(3 downto 2);
   tao1b    <= xb(3 downto 2);
   tao1c    <= xc(3 downto 2);

   tao0a    <= xa(1 downto 0);
   tao0b    <= xb(1 downto 0);
   tao0c    <= xc(1 downto 0);

   delta1a    <= ya(3 downto 2);
   delta1b    <= yb(3 downto 2);
   delta1c    <= yc(3 downto 2);

   delta0a    <= ya(1 downto 0);
   delta0b    <= yb(1 downto 0);
   delta0c    <= yc(1 downto 0);

   tmp1a      <= tao1a xor tao0a;
   tmp1b      <= tao1b xor tao0b;
   tmp1c      <= tao1c xor tao0c;
			
   tmp0a      <= delta1a xor delta0a;
   tmp0b      <= delta1b xor delta0b;
   tmp0c      <= delta1c xor delta0c;
	
	mul1a: entity work.GF_MUL_2_TIma(dataflow)
		port map(
			xa => tao1b,
			xb => tao1c,
			ya => delta1b,
			yb => delta1c,
			m => m(1 downto 0),
			o => RES_MUL1a
			);

	mul1b: entity work.GF_MUL_2_TImb(dataflow)
		port map(
			xa => tao1c,
			xb => tao1a,
			ya => delta1c,
			yb => delta1a,
			m => m(1 downto 0), --m(3 downto 2),
			o => RES_MUL1b
			);

	mul1c: entity work.GF_MUL_2_TImc(dataflow)
		port map(
			xa => tao1a,
			xb => tao1b,
			ya => delta1a,
			yb => delta1b,
			m => m(1 downto 0), --(m(3 downto 2) xor m(1 downto 0)),
			o => RES_MUL1c
			);

	mul1a_reg: entity work.reg_n(behavioral)
		generic map(N=>2)
		port map(
			clk => clk,
			--rst => rst,
			en => en,
			d => RES_MUL1a,
			q => RES_MUL1a_reg
			);

	mul1b_reg: entity work.reg_n(behavioral)
		generic map(N=>2)
		port map(
			clk => clk,
			--rst => rst,
			en => en,
			d => RES_MUL1b,
			q => RES_MUL1b_reg
			);

	mul1c_reg: entity work.reg_n(behavioral)
		generic map(N=>2)
		port map(
			clk => clk,
			--rst => rst,
			en => en,
			d => RES_MUL1c,
			q => RES_MUL1c_reg
			);

	mul2a: entity work.GF_MUL_2_TIma(dataflow)
		port map(
			xa => tao0b,
			xb => tao0c,
			ya => delta0b,
			yb => delta0c,
			m => m(3 downto 2), --m(5 downto 4),
			o => RES_MUL0a
			);

	mul2b: entity work.GF_MUL_2_TImb(dataflow)
		port map(
			xa => tao0c,
			xb => tao0a,
			ya => delta0c,
			yb => delta0a,
			m => m(3 downto 2), --m(7 downto 6),
			o => RES_MUL0b
			);

	mul2c: entity work.GF_MUL_2_TImc(dataflow)
		port map(
			xa => tao0a,
			xb => tao0b,
			ya => delta0a,
			yb => delta0b,
			m => m(3 downto 2), --(m(7 downto 6) xor m(5 downto 4)),
			o => RES_MUL0c
			);

	mul2a_reg: entity work.reg_n(behavioral)
		generic map(N=>2)
		port map(
			clk => clk,
			--rst => rst,
			en => en,
			d => RES_MUL0a,
			q => RES_MUL0a_reg
			);

	mul2b_reg: entity work.reg_n(behavioral)
		generic map(N=>2)
		port map(
			clk => clk,
			--rst => rst,
			en => en,
			d => RES_MUL0b,
			q => RES_MUL0b_reg
			);

	mul2c_reg: entity work.reg_n(behavioral)
		generic map(N=>2)
		port map(
			clk => clk,
			--rst => rst,
			en => en,
			d => RES_MUL0c,
			q => RES_MUL0c_reg
			);

	scl1a: entity work.GF_MUL_SCL_2_TIma(dataflow)
		port map(
			xa => tmp1b,
			xb => tmp1c,
			ya => tmp0b,
			yb => tmp0c,
			m => m(5 downto 4),
			o => RES_MUL_SCLa
			);
			
	scl1b: entity work.GF_MUL_SCL_2_TImb(dataflow)
		port map(
			xa => tmp1c,
			xb => tmp1a,
			ya => tmp0c,
			yb => tmp0a,
			m => m(5 downto 4),
			o => RES_MUL_SCLb
			);

	scl1c: entity work.GF_MUL_SCL_2_TImc(dataflow)
		port map(
			xa => tmp1a,
			xb => tmp1b,
			ya => tmp0a,
			yb => tmp0b,
			m => m(5 downto 4), --(m(11 downto 10) xor m(9 downto 8)),
			o => RES_MUL_SCLc
			);

	scl1a_reg: entity work.reg_n(behavioral)
		generic map(N=>2)
		port map(
			clk => clk,
			--rst => rst,
			en => en,
			d => RES_MUL_SCLa,
			q => RES_MUL_SCLa_reg
			);

	scl1b_reg: entity work.reg_n(behavioral)
		generic map(N=>2)
		port map(
			clk => clk,
			--rst => rst,
			en => en,
			d => RES_MUL_SCLb,
			q => RES_MUL_SCLb_reg
			);

	scl1c_reg: entity work.reg_n(behavioral)
		generic map(N=>2)
		port map(
			clk => clk,
			--rst => rst,
			en => en,
			d => RES_MUL_SCLc,
			q => RES_MUL_SCLc_reg
			);

    RES_MUL1a_reg_p <= m(5 downto 4) when (primer = '1') else RES_MUL1a_reg;
    RES_MUL1b_reg_p <= m(3 downto 2) when (primer = '1') else RES_MUL1b_reg;
    RES_MUL1c_reg_p <= m(1 downto 0) when (primer = '1') else RES_MUL1c_reg;
	
    RES_MUL0a_reg_p <= m(4 downto 3) when (primer = '1') else RES_MUL0a_reg;
    RES_MUL0b_reg_p <= m(2 downto 1) when (primer = '1') else RES_MUL0b_reg;
    RES_MUL0c_reg_p <= (m(0) & m(5)) when (primer = '1') else RES_MUL0c_reg;

    RES_MUL_SCLa_reg_p <= (m(5)& m(3)) when (primer = '1') else RES_MUL_SCLa_reg;
    RES_MUL_SCLb_reg_p <= (m(1)& m(4)) when (primer = '1') else RES_MUL_SCLb_reg;
    RES_MUL_SCLc_reg_p <= (m(0)& m(2)) when (primer = '1') else RES_MUL_SCLc_reg;

    fi1a         <= RES_MUL1a_reg_p xor RES_MUL_SCLa_reg_p;
    fi1b         <= RES_MUL1b_reg_p xor RES_MUL_SCLb_reg_p;
    fi1c         <= RES_MUL1c_reg_p xor RES_MUL_SCLc_reg_p;

    fi0a         <= RES_MUL0a_reg_p xor RES_MUL_SCLa_reg_p;
    fi0b         <= RES_MUL0b_reg_p xor RES_MUL_SCLb_reg_p;
    fi0c         <= RES_MUL0c_reg_p xor RES_MUL_SCLc_reg_p;

    oa           <= fi1a & fi0a;
    ob           <= fi1b & fi0b;
    oc           <= fi1c & fi0c;

end structural;

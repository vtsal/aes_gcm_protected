-------------------------------------------------------------------------------
--! @file       AES_Sbox_TI.vhd
--! @author     William Diehl
--! @brief      
--! @date       24 May 2018
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity AES_Sbox_TI is
    port(
		  clk                : in std_logic;
		  rst                : in std_logic;
		  en				 : in std_logic;
          dina               : in  std_logic_vector(7 downto 0);
          dinb               : in  std_logic_vector(7 downto 0);
          after_subbytesa    : out std_logic_vector(7 downto 0);
          after_subbytesb    : out std_logic_vector(7 downto 0);
	      m                  : in std_logic_vector(39 downto 0);
		  primer             : in std_logic
    );

end AES_Sbox_TI;

architecture structural of AES_Sbox_TI is

constant AFFINE_C : std_logic_vector(7 downto 0):=x"63";

signal after_mul_invxa, after_mul_invxb     : std_logic_vector(7 downto 0);
signal after_mul_mxa, after_mul_mxb         : std_logic_vector(7 downto 0);
signal to_invgf8a, to_invgf8b               : std_logic_vector(7 downto 0);
signal after_invgf8a, after_invgf8b         : std_logic_vector(7 downto 0);

attribute keep : string;
attribute keep of after_mul_invxa : signal is "true";
attribute keep of after_mul_invxb : signal is "true";
attribute keep of after_mul_mxa : signal is "true";
attribute keep of after_mul_mxb : signal is "true";
attribute keep of to_invgf8a : signal is "true";
attribute keep of to_invgf8b : signal is "true";
attribute keep of after_invgf8a : signal is "true";
attribute keep of after_invgf8b : signal is "true";
	 
begin

 mul1a: entity work.MUL_INVX(dataflow)
	port map(
		x => dina,
		y => after_mul_invxa
		);

 mul1b: entity work.MUL_INVX(dataflow)
	port map(
		x => dinb,
		y => after_mul_invxb
		);

      to_invgf8a <= after_mul_invxa;
      to_invgf8b <= after_mul_invxb;

 inv1: entity work.GF_INV_GF8_TIa(structural)
	port map(
		clk => clk,
		rst => rst,
		en => en,
		xa => to_invgf8a,
		xb => to_invgf8b,
		ya => after_invgf8a,
		yb => after_invgf8b,
		m => m,
		primer => primer
		);
	    	
 mul2a: entity work.MUL_MX(dataflow)
	port map(
		x => after_invgf8a,
		y => after_mul_mxa
		);
		
 mul2b: entity work.MUL_MX(dataflow)
	port map(
		x => after_invgf8b,
		y => after_mul_mxb
		);

      after_subbytesa  <= after_mul_mxa xor AFFINE_C;
      after_subbytesb  <= after_mul_mxb; -- constants must be added an odd number of times to shared values

end architecture structural;

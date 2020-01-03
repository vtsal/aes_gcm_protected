-------------------------------------------------------------------------------
--! @file       AES.vhd
--! @author     William Diehl
--! @brief      
--! @date       21 Jul 2017
-------------------------------------------------------------------------------
-- Pipelined 2-/3-share TI-protected AES encryption
-- Protection of key and data paths
-- AES

library ieee;
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;  
use IEEE.NUMERIC_STD.ALL;
use work.AES_pkg.all;

entity AES is

port(

-- control signals

	clock : in std_logic;
	start : in std_logic;
	rdi_valid : in std_logic;
	done  : out std_logic;
	busy  : out std_logic;

-- data signals

	data_in_a   : in std_logic_vector(127 downto 0);
	data_in_b	: in std_logic_vector(127 downto 0);
	remask	    : in std_logic_vector(39 downto 0);
	key_in_a    : in std_logic_vector(127 downto 0);
	key_in_b	: in std_logic_vector(127 downto 0);
	data_out_a  : out std_logic_vector(127 downto 0);
	data_out_b  : out std_logic_vector(127 downto 0)

);

end AES;

architecture structural of AES is
 
signal en, regwrite, bubble, rnd_cntr_en, ksbox_en, k_cntr_en: std_logic:='0';
signal done_signal: std_logic:='0';
signal reset : std_logic:='0';
signal en_bank : signal4_array;
signal en_key_reg : signal16_array;
signal ksel : std_logic_vector(1 downto 0);
signal ssel : std_logic;
signal xsel_init, index_en : std_logic;

begin

AESDataPath: entity work.datapath(structural)

	port map(
		clk => clock,
		rst => reset,
		en => en,
		start => start,
		-- data signals

		data_in_a => data_in_a,
		data_in_b => data_in_b,
		remask => remask,
		
	    key_in_a => key_in_a,
		key_in_b => key_in_b,
		douta => data_out_a,
		doutb => data_out_b,

		last_round => done_signal,
		index_en => index_en,
		en_bank => en_bank,
		ksbox_en => ksbox_en,
		regwrite => regwrite,
		
		k_cntr_en => k_cntr_en,
		en_key_reg => en_key_reg,
		ksel => ksel,
		ssel => ssel,
		xsel_init => xsel_init,
		rnd_cntr_en => rnd_cntr_en 

		);

AESCtrl: entity work.controller(behavioral)

	port map(

		clk => clock,
		rst => reset,
		start => start,
		en => en,
		rdi_valid => rdi_valid,
		last_round => done_signal,
		regwrite => regwrite,
		ksbox_en => ksbox_en,
		rnd_cntr_en => rnd_cntr_en,
		done => done,
		busy => busy,
		k_cntr_en => k_cntr_en,
		xsel_init => xsel_init,
		index_en => index_en,
		ssel => ssel,
		ksel => ksel,
		en_key_reg => en_key_reg,
		en_bank => en_bank
			
		);

end structural;

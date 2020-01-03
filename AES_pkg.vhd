-------------------------------------------------------------------------------
--! @file       AES_pkg.vhd
--! @brief      Package definition used by various AES modules
--!
--! @author     Ekawat (ice) Homsirikamol
--!             Marcin Rogawski
--! @acknowledgement Pawel Chodowiec
--! @copyright  Copyright (c) 2016 Cryptographic Engineering Research Group
--!             ECE Department, George Mason University Fairfax, VA, U.S.A.
--!             All rights Reserved.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

package AES_pkg is
	--! AES constants
	constant AES_SBOX_SIZE	    : integer :=  8;
	constant AES_WORD_SIZE	    : integer := 32;
	constant AES_BLOCK_SIZE	    : integer :=128;
	constant AES_KEY_SIZE	    : integer :=128;

    constant AES_ROUNDS			  : integer := 10; -- compatibility addition
    constant AES_K128_ROUNDS    : integer := 10;
    constant AES_K256_ROUNDS    : integer := 14;

    constant MODE_ECB           : std_logic_vector(1 downto 0) := "00";
    constant MODE_ECB_ENC       : std_logic_vector(2 downto 0) := "000";
    constant MODE_ECB_DEC       : std_logic_vector(2 downto 0) := "001";
    constant MODE_CBC           : std_logic_vector(1 downto 0) := "01";
    constant MODE_CBC_ENC       : std_logic_vector(2 downto 0) := "010";
    constant MODE_CBC_DEC       : std_logic_vector(2 downto 0) := "011";
    constant MODE_CFB           : std_logic_vector(1 downto 0) := "10";
    constant MODE_CFB_ENC       : std_logic_vector(2 downto 0) := "100";
    constant MODE_CFB_DEC       : std_logic_vector(2 downto 0) := "101";
    constant MODE_CTR           : std_logic_vector(2 downto 0) := "110";
    constant MODE_OFB           : std_logic_vector(2 downto 0) := "111";

    constant AFFINE_C           : std_logic_vector(7 downto 0) := x"63";

    type t_AES_state     is array (0 to 3, 0 to 3) of std_logic_vector( 7 downto 0);
    type t_AES_column    is array (0 to 3)         of std_logic_vector( 7 downto 0);

	 -- masking addition
	 type t_AES_returnstate is array (0 to 3, 0 to 3) of std_logic_vector(15 downto 0);
	 type signal4_array is array (0 to 3) of std_logic; 	
	 type signal16_array is array (0 to 15) of std_logic;
	 
end AES_pkg;

--package body AES_pkg is

--end package body;
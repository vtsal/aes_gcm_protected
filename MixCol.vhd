-------------------------------------------------------------------------------
--! @file       MixCol.vhd
--! @author     William Diehl
--! @brief      
--! @date       24 May 2018
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity MixCol is
    port(
        input       : in  std_logic_vector(31 downto 0);
        output      : out std_logic_vector(31 downto 0)
    );
end MixCol;

architecture structural of MixCol is
    type col_array_type is array (0 to 3) of std_logic_vector(7 downto 0);	
    signal mulx2    : col_array_type;
    signal mulx3    : col_array_type;

begin

    m_gen : for i in 0 to 3 generate
        m2  : entity work.AES_mulx02(dataflow)
            port map (  input  => input(8*i+7 downto 8*i),
                        output => mulx2(i));
        m3  : entity work.AES_mulx03(dataflow)
            port map (  input  => input(8*i+7 downto 8*i),
                        output => mulx3(i));
    end generate;

    output(31 downto 24) <= mulx2(3) xor mulx3(2) xor input(15 downto 8) xor input(7 downto 0);
    output(23 downto 16) <= input(31 downto 24) xor mulx2(2) xor mulx3(1) xor input(7 downto 0);
    output(15 downto 8) <= input(31 downto 24) xor input(23 downto 16) xor mulx2(1) xor mulx3(0);
    output(7 downto 0) <= mulx3(3) xor input(23 downto 16) xor input(15 downto 8) xor mulx2(0);

end structural;

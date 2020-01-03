
-------------------------------------------------------------------------------
--! @file       AES_mulx02.vhd
--! @author     William Diehl
--! @brief      
--! @date       24 May 2018
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity AES_mulx02 is
    port(
        input       : in  std_logic_vector(7 downto 0);
        output      : out std_logic_vector(7 downto 0)
    );
end AES_mulx02;

architecture dataflow of AES_mulx02 is

--attribute keep_hierarchy : string;
--attribute keep_hierarchy of dataflow architecture is "true";

begin
    output(7) <= input(6);
    output(6) <= input(5);
    output(5) <= input(4);
    output(4) <= input(7) xor input(3);
    output(3) <= input(7) xor input(2);
    output(2) <= input(1);
    output(1) <= input(7) xor input(0);
    output(0) <= input(7);
end dataflow;

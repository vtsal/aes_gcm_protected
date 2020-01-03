-- MUL_MX
-------------------------------------------------------------------------------
--! @file       MUL_MX.vhd
--! @author     William Diehl
--! @brief      
--! @date       24 May 2018
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.ALL;

entity MUL_MX is
    port (

    x  : in  std_logic_vector(7 downto 0);
    y  : out std_logic_vector(7 downto 0)
    );

end entity MUL_MX;

architecture dataflow of MUL_MX is
attribute keep_hierarchy : string;
attribute keep_hierarchy of dataflow: architecture is "true";

begin

   y(7) <= x(5) xor x(3);
   y(6) <= x(7) xor x(3);
   y(5) <= x(6) xor x(0);
   y(4) <= x(7) xor x(5) xor x(3);
   y(3) <= x(7) xor x(6) xor x(5) xor x(4) xor x(3);
   y(2) <= x(6) xor x(5) xor x(3) xor x(2) xor x(0);
   y(1) <= x(5) xor x(4) xor x(1);
   y(0) <= x(6) xor x(4) xor x(1);

end dataflow;

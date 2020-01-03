-- GF_MUL_2_TImb

-------------------------------------------------------------------------------
--! @file       GF_MUL_2_TImb.vhd
--! @author     William Diehl
--! @brief      
--! @date       24 May 2018
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.ALL;

entity GF_MUL_2_TImb is
    port (
    xa, xb, ya, yb, m  : in  std_logic_vector(1 downto 0);
    o                  : out std_logic_vector(1 downto 0)
    );

end entity GF_MUL_2_TImb;

architecture dataflow of GF_MUL_2_TImb is

attribute keep_hierarchy : string;
attribute keep_hierarchy of dataflow: architecture is "true";

begin

   o(1) <= (xa(1) and yb(0)) xor (xb(1) and ya(0)) xor (xb(1) and yb(0)) xor 
           (xa(0) and yb(1)) xor (xb(0) and ya(1)) xor (xb(0) and yb(1)) xor
           (xa(0) and yb(0)) xor (xb(0) and ya(0)) xor (xb(0) and yb(0)) xor
           (xa(1) and m(1)) xor (m(1) and ya(1));

--   o(1) <= (x(1) and y(0)) xor (x(0) and y(1)) xor (x(0) and y(0));

   o(0) <= (xa(1) and yb(1)) xor (xb(1) and ya(1)) xor (xb(1) and yb(1)) xor 
           (xa(1) and yb(0)) xor (xb(1) and ya(0)) xor (xb(1) and yb(0)) xor
           (xa(0) and yb(1)) xor (xb(0) and ya(1)) xor (xb(0) and yb(1)) xor
           (xb(0) and m(0)) xor (m(0) and yb(0)) xor m(0);

--	o(0) <= (x(1) and y(1)) xor (x(1) and y(0)) xor (x(0) and y(1));

end dataflow;

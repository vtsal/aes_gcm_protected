-- and_3TI
-------------------------------------------------------------------------------
--! @file       and_TI.vhd
--! @author     William Diehl
--! @brief      
--! @date       24 May 2018
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.ALL;

entity and_3TI is
    port (

    xa, xb, ya, yb  : in  std_logic_vector(127 downto 0);
    o               : out std_logic_vector(127 downto 0)
    );

end entity and_3TI;

architecture dataflow of and_3TI is

attribute keep_hierarchy : string;
attribute keep_hierarchy of dataflow: architecture is "true";

begin

    o <= (xb and ya) xor (xa and yb) xor (xa and ya);

end dataflow;

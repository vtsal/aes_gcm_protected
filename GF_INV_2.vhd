-- GF_INV_2

-------------------------------------------------------------------------------
--! @file       GF_INV_2_TImc.vhd
--! @author     William Diehl
--! @brief      
--! @date       24 May 2018
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.ALL;

entity GF_INV_2 is
    port (
    x  : in  std_logic_vector(1 downto 0);
    y  : out std_logic_vector(1 downto 0)
    );

end entity GF_INV_2;

architecture dataflow of GF_INV_2 is

attribute keep_hierarchy : string;
attribute keep_hierarchy of dataflow: architecture is "true";

begin

   y(1) <= x(0);
   y(0) <= x(1);

end dataflow;

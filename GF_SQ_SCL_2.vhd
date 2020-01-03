-- GF_SQ_SCL_2
-------------------------------------------------------------------------------
--! @file       GF_SQ_SCL_2.vhd
--! @author     William Diehl
--! @brief      
--! @date       24 May 2018
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.ALL;

entity GF_SQ_SCL_2 is
    port (

    x  : in  std_logic_vector(1 downto 0);
    y  : out std_logic_vector(1 downto 0)
    );

end entity GF_SQ_SCL_2;

architecture dataflow of GF_SQ_SCL_2 is

attribute keep_hierarchy : string;
attribute keep_hierarchy of dataflow: architecture is "true";

begin

    y <= x(1) & (x(1) xor x(0));

end dataflow;

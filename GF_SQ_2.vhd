-- GF_SQ_2
-------------------------------------------------------------------------------
--! @file       GF_SQ_2.vhd
--! @author     William Diehl
--! @brief      
--! @date       24 May 2018
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.ALL;

entity GF_SQ_2 is
    port (

    x  : in  std_logic_vector(1 downto 0);
    y  : out std_logic_vector(1 downto 0)
    );

end entity GF_SQ_2;

architecture dataflow of GF_SQ_2 is

begin

    y(1) <= x(0);
    y(0) <= x(1);
end dataflow;

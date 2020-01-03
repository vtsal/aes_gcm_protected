-- GF_SQ_SCL_4
-------------------------------------------------------------------------------
--! @file       GF_SQ_SCL_4.vhd
--! @author     William Diehl
--! @brief      
--! @date       24 May 2018
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.ALL;

entity GF_SQ_SCL_4 is
    port (

    x  : in  std_logic_vector(3 downto 0);
    y  : out std_logic_vector(3 downto 0)
    );

end entity GF_SQ_SCL_4;

architecture structural of GF_SQ_SCL_4 is

signal tao1, tao0, delta1, delta0, tmp1, tmp0: std_logic_vector(1 downto 0); 

   attribute keep : string;

attribute keep of tao1, tao0, delta1, delta0, tmp1, tmp0: signal is "true";

begin

   tao1   <= x(3 downto 2);
   tao0   <= x(1 downto 0);
   tmp1   <= tao1 xor tao0;

   scl1: entity work.GF_SCL_2(dataflow)
      port map(
          x => tao0,
          y => tmp0
      );

   sqr1: entity work.GF_SQ_2(dataflow)
      port map(
          x => tmp1,
          y => delta1
      );

   sqr2: entity work.GF_SQ_2(dataflow)
      port map(
          x => tmp0,
          y => delta0
      );

    y <= delta1 & delta0;

end structural;

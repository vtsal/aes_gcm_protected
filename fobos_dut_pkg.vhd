library ieee;
use ieee.std_logic_1164.all;

package fobos_dut_pkg is

function log2_ceil (N : natural) return natural;
end fobos_dut_pkg;

package body fobos_dut_pkg is

function log2_ceil(N: natural) return natural is
    begin
        if (N=0) then
            return 0;
        elsif N <=2 then
            return 1;
        else 
            if (N mod 2 = 0) then
                  return 1 + log2_ceil(N/2);
            else
                  return 1 + log2_ceil((N+1)/2);
            end if;
        end if;
     end function log2_ceil;

end package body fobos_dut_pkg;

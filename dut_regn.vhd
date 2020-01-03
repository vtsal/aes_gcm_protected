-------------------------------------------------------------------------------
--! @file       regn.vhd
--! @author     William Diehl
--! @brief      
--! @date       12 Mar 2017
-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY dut_regn IS
	GENERIC (N:INTEGER :=16);
	PORT(D : IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
	     CLK  : IN STD_LOGIC;
         EN   : IN STD_LOGIC;
         RST : IN STD_LOGIC;
	     Q    : OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0):=(OTHERS=>'0'));
END dut_regn;

ARCHITECTURE behavioral OF dut_regn IS
BEGIN
	PROCESS (CLK)
        BEGIN
            
            IF rising_edge(CLK) THEN
               if (rst = '1') then
                    Q <= (OTHERS=>'0');
               else if (EN = '1') then
                        Q <= D;
                     end if;   
               end if;
	    end if;
        END PROCESS;
END behavioral;
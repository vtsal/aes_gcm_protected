-------------------------------------------------------------------------------
--! @file       reg1.vhd
--! @author     William Diehl
--! @brief      
--! @date       12 Mar 2017
-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY dut_reg1 IS
	PORT(D : IN STD_LOGIC;
	     CLK  : IN STD_LOGIC;
         EN   : IN STD_LOGIC;
	     Q    : OUT STD_LOGIC:='0');
END dut_reg1;

ARCHITECTURE behavioral OF dut_reg1 IS
BEGIN
	PROCESS (CLK)
        BEGIN
            
            IF rising_edge(CLK) THEN
              if (EN = '1') then
                  Q <= D;
                
              end if;
	    end if;
        END PROCESS;
END behavioral;

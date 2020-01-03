-------------------------------------------------------------------------------
--! @file       controller.vhd
--! @author     William Diehl
--! @brief      
--! @date       24 May 2018
-------------------------------------------------------------------------------
-- Controller for 205-cycle pipelined AES
-- stalls AES computations if rdi_valid = '0'

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.all;
use work.AES_pkg.all;

entity controller is
    PORT ( clk : in std_logic;
           start : in std_logic;
           rst : in std_logic;
           last_round : in std_logic;
           rdi_valid : in std_logic;
           en : out std_logic:='0';
           regwrite : out std_logic:='0';
           rnd_cntr_en : out std_logic:='0';
           ksbox_en : out std_logic:='0';
           ssel : out std_logic:='0';
           done: out std_logic:='0';
           busy : out std_logic;
           k_cntr_en : out std_logic;
           index_en : out std_logic;
           xsel_init : out std_logic;
           ksel : out std_logic_vector(1 downto 0);
           en_bank : out signal4_array;
           en_key_reg : out signal16_array
          );

end controller;

architecture behavioral of controller is
    type state is (IDLE, S_0, S_1, S_2, S_3, S_4, S_5, S_6, S_7, S_8, S_9, S_10, S_11,
    S_12, S_13, S_14, S_15, S_16, S_17, S_18, S_19, S_DONE);

    signal current_state : state;
    signal next_state : state;
begin

sync_process: process(clk)
begin

if (rising_edge(clk)) then
	if (rst = '1') then
	   current_state <= IDLE; -- idle state
	else
	   current_state <= next_state;
	end if;
end if;

end process;

public_process: process(current_state, start, rdi_valid, last_round)
begin
 
	 -- defaults
en <= '0'; 

-- writes 32-bit results back to status

en_bank(0) <= '0';
en_bank(1) <= '0';
en_bank(2) <= '0';
en_bank(3) <= '0';

-- updates round key 1 byte at a time

en_key_reg(0) <= '0';
en_key_reg(1) <= '0';
en_key_reg(2) <= '0';
en_key_reg(3) <= '0';
en_key_reg(4) <= '0';
en_key_reg(5) <= '0';
en_key_reg(6) <= '0';
en_key_reg(7) <= '0';
en_key_reg(8) <= '0';
en_key_reg(9) <= '0';
en_key_reg(10) <= '0';
en_key_reg(11) <= '0';
en_key_reg(12) <= '0';
en_key_reg(13) <= '0';
en_key_reg(14) <= '0';
en_key_reg(15) <= '0';

regwrite <= '0';
rnd_cntr_en <= '0';
ksbox_en <= '0';
k_cntr_en <= '0';  

ssel <= '1'; -- default is status to sbox (0 is key, 1 is status)

xsel_init <= '0';
index_en <= '0';
done <= '0';
busy <= '1';

case current_state is
		 		 
	 when IDLE => 
        busy <= '0';
		 
		if (start = '1') then
			xsel_init <= '1'; -- initialize counters
			index_en <= '1'; -- initialize counters
			rnd_cntr_en <= '1'; -- initialize round counters
			en <= '1'; 
			k_cntr_en <= '1'; 
			next_state <= S_0;
		else
			next_state <= IDLE;
		end if;
	    
	when S_0 => 

          ssel <= '0'; -- key to sbox
		  ksel <= "01"; -- k13 to Sbox
		  if (rdi_valid = '1') then
		      en <= '1';
				en_bank(0) <= '1'; -- write 32-bit column 0 to new state
				next_state <= S_1;
		  else
				next_state <= S_0;
		  end if;
		  
	when S_1 =>

   	  ssel <= '0'; -- key to sbox	
		  ksel <= "10"; -- k14 to Sbox
		  if (rdi_valid = '1') then
				en <= '1';
				en_bank(1) <= '1'; -- write 32-bit column 1 to new state
				next_state <= S_2;
		  else
				next_state <= S_1;
		  end if;
		
	when S_2 =>

   	  ssel <= '0'; -- key to sbox	
		  ksel <= "11"; -- k15 to Sbox
		  if (rdi_valid = '1') then
				en <= '1';
				en_bank(2) <= '1'; -- write 32-bit column 2 to new state
				next_state <= S_3;
		  else
				next_state <= S_2;
		  end if;
							
	when S_3 =>

   	  ssel <= '0'; -- key to sbox	
		  ksel <= "00"; -- k12 to Sbox
		  if (rdi_valid = '1') then
				en <= '1';
				regwrite <= '1'; -- write result to temporary column
				index_en <= '1'; -- update regsel
				next_state <= S_4;
		  else
			   next_state <= S_3;
		  end if;
	 
	when S_4 => 

         if (rdi_valid = '1') then
				en <= '1';
				k_cntr_en <= '1';
				ksbox_en <= '1'; -- the output from pipeline is S(k13)
				en_bank(3) <= '1'; -- write 32-bit column 3 to new state
				en_key_reg(0) <= '1'; -- update round key 0
				if (last_round = '1') then
					next_state <= S_DONE;	
				else
					next_state <= S_5;
				end if;
			else
				next_state <= S_4;
			end if;

	when S_5 => 
			
			if (rdi_valid = '1') then
				k_cntr_en <= '1';
				en <= '1';
				ksbox_en <= '1'; -- the output from pipeline is S(k14)
				en_key_reg(1) <= '1'; -- update round key 1
				next_state <= S_6;
			else
				next_state <= S_5;
			end if;

	when S_6 => 
			
			if (rdi_valid = '1') then
				k_cntr_en <= '1';
				en <= '1';
				ksbox_en <= '1'; -- the output from pipeline is S(k15)
				en_key_reg(2) <= '1'; -- update round key 2
				next_state <= S_7;
			else
				next_state <= S_6;
			end if;
			
	when S_7 => 
			
			if (rdi_valid = '1') then
				k_cntr_en <= '1';
				en <= '1';
				ksbox_en <= '1'; -- the output from pipeline is S(k12)
				en_key_reg(3) <= '1'; -- update round key 3
				index_en <= '0';
				next_state <= S_8;
			else
				next_state <= S_7;
			end if;

	when S_8 => 

         if (rdi_valid = '1') then
				k_cntr_en <= '1';
				en <= '1';
				en_key_reg(4) <= '1'; -- update round key 4
				next_state <= S_9;
			else
				next_state <= S_8;
			end if;

	when S_9 => 

			if (rdi_valid = '1') then
				k_cntr_en <= '1';
				en <= '1';
				en_key_reg(5) <= '1'; -- update round key 5			
				next_state <= S_10;
			else
				next_state <= S_9;
			end if;

	when S_10 => 

			if (rdi_valid = '1') then
				k_cntr_en <= '1';
				en <= '1';
				en_key_reg(6) <= '1'; -- update round key 6
				next_state <= S_11;
			else
				next_state <= S_10;
			end if;

	when S_11 => 

			if (rdi_valid = '1') then
				k_cntr_en <= '1';
				en <= '1';
				index_en <= '1'; -- update regsel
				en_key_reg(7) <= '1'; -- update round key 7
				regwrite <= '1';
				next_state <= S_12;
			else
				next_state <= S_11;
			end if;

	when S_12 => 

			if (rdi_valid = '1') then
				k_cntr_en <= '1';
				en <= '1';
				en_key_reg(8) <= '1'; -- update round key 8
				next_state <= S_13;
			else
				next_state <= S_12;
			end if;

	when S_13 => 
		
		   if (rdi_valid = '1') then
				k_cntr_en <= '1';
				en <= '1';
				en_key_reg(9) <= '1';	-- update round key 9 
				next_state <= S_14;
			else
				next_state <= S_13;
			end if;

	when S_14 =>
	
			if (rdi_valid = '1') then
				k_cntr_en <= '1';
				en <= '1';
				en_key_reg(10) <= '1'; -- update round key 10
				next_state <= S_15;
			else
				next_state <= S_14;
			end if;

	when S_15 =>
		
			if (rdi_valid = '1') then
				k_cntr_en <= '1';
				en <= '1';
				regwrite <= '1';
				index_en <= '1'; -- update regsel
				en_key_reg(11) <= '1'; -- update round key 11
				next_state <= S_16;
			else
				next_state <= S_15;
			end if;

	when S_16 =>
	
			if (rdi_valid = '1') then
				k_cntr_en <= '1';
				en <= '1';
				en_key_reg(12) <= '1'; -- update round key 12
				next_state <= S_17;
			else
				next_state <= S_16;
			end if;

	when S_17 =>
	
	      if (rdi_valid = '1') then
				k_cntr_en <= '1';
				en <= '1';
				en_key_reg(13) <= '1';	 -- update round key 13
				next_state <= S_18;
			else
				next_state <= S_17;
			end if;

	when S_18 =>
	
			if (rdi_valid = '1') then
				k_cntr_en <= '1';
				en <= '1';
				en_key_reg(14) <= '1'; -- update round key 14
				next_state <= S_19;
			else
				next_state <= S_18;
			end if;

	when S_19 =>
	
	      if (rdi_valid = '1') then
				k_cntr_en <= '1';
				en <= '1';
				regwrite <= '1';
				en_key_reg(15) <= '1'; -- update round key 15
				index_en <= '1'; -- update regsel
				rnd_cntr_en <= '1'; -- update round
				next_state <= S_0;
			else
				next_state <= S_19;
			end if;
		
	when S_DONE => 
			done <= '1';
			next_state <= IDLE;
					 
	WHEN OTHERS =>
	
		  next_state <= IDLE;
			  
	end case; 

END process;
		
END behavioral; 

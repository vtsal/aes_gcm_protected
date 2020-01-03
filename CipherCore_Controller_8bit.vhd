-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--! @file       CipherCore_Controller_8bit.vhd
--! @author     William Diehl 
--! @brief      Controller for AES-GCM in LW interface with PW=SW=8
--! @version    02-24-2018     
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.all;

entity CipherCore_Controller_8bit is
    port (
     clk : std_logic;
     rst : std_logic;
	 
     bdi_ready  : out std_logic;
     bdi_valid  : in std_logic;
     bdo_ready  : in std_logic;
     bdo_valid  : out std_logic;
     key_update : in std_logic;
     key_valid  : in std_logic;
     key_ready  : out std_logic;
     rdi_valid  : in std_logic;
     bdi_eoi    : in std_logic;
     bdi_eot    : in std_logic;
     bdi_type   : in std_logic_vector(3 downto 0);
     end_of_block : out std_logic;
     decrypt    : in std_logic;
     msg_auth_valid	: out std_logic;
     ld_ctr_out : out std_logic_vector(4 downto 0);

     aes_done   : in std_logic;
     mult_done  : in std_logic;
     aes_busy   : in std_logic;
     mult_busy  : in std_logic;
     sel_tag    : out  std_logic;
     en_key     : out  std_logic;
     en_h       : out  std_logic;
     en_npub    : out  std_logic;
     en_ctr     : out  std_logic;
     en_aes     : out  std_logic;
     en_mult    : out  std_logic;
     clr_ctr    : out  std_logic;
     clr_bdi    : out  std_logic;
     clr_mult   : out  std_logic;
     en_bdi     : out  std_logic;
     en_bdo     : out  std_logic;
     ld_bdo     : out  std_logic;
     sel_aes    : out  std_logic;
     xor2_sel   : out  std_logic_vector(1 downto 0);
     msg_auth_ready  : in std_logic;
     len_init_z1     : out std_logic;
     en_len_a_z1     : out std_logic;
     en_len_d_z1	 : out std_logic;
   
     state_debug	 : out std_logic_vector(7 downto 0); -- profiler
     
     -- Added by Behnaz ------------------------------------
     --=====================================================
     raReg_en       : out std_logic;
     rbReg_en       : out std_logic;
     c1a_en         : out std_logic;
     c2a_en         : out std_logic;
     c1b_en         : out std_logic;
     c2b_en         : out std_logic;
     d1a_en         : out std_logic;
     d2a_en         : out std_logic;
     d1b_en         : out std_logic;
     d2b_en         : out std_logic
     --=====================================================

     );
end CipherCore_Controller_8bit;

architecture behavioral of CipherCore_Controller_8bit is

constant KEY_BYTES : integer := 16; -- 128 bit key
constant NPUB_BYTES : integer := 12; -- 96 bit npub
constant EXP_TAG_BYTES : integer := 16; -- 128 bit expected tag
constant TAG_BYTES : integer := 16; -- 128 bit tag
constant BDI_BYTES : integer := 16; -- 128 bit AD, M, C
constant AD_TYPE : integer:= 1; -- HDR_AD

type state is (S_INIT, S_CHECK_KEY, S_LOAD_KEY, S_COMPUTE_H, S_LOAD_NPUB, 
                   S_WAIT_AUTH_DATA, S_LOAD_AD, S_PROCESS_AD, S_LOAD_M, S_PROCESS_M,
                   S_WAIT_H, S_M_OUT, S_START_EK0, S_MULT_LEN, S_LOAD_EXP_TAG,
                   S_FINISH, S_TAG_OUT,
                   verify_tag1, verify_tag2, verify_tag3, verify_tag4, verify_tag5, verify_tag6 -- Added by Behnaz
                  );
signal current_state : state;
signal nstate : state;

signal set_h_ready : std_logic;
signal reset_h_ready : std_logic;
signal h_ready : std_logic;
signal clr_ld_ctr : std_logic;
signal en_ld_ctr : std_logic;
signal clr_wr_ctr : std_logic;
signal en_wr_ctr : std_logic;
signal ld_exp_wr_ctr : std_logic;
signal set_last_ad_flag : std_logic;
signal set_last_m_flag : std_logic;
signal last_ad_flag : std_logic;
signal last_m_flag : std_logic;
signal reset_last_ad_flag : std_logic;
signal reset_last_m_flag : std_logic;
signal ld_ctr : std_logic_vector(4 downto 0):=(others => '0');
signal exp_wr_ctr, wr_ctr : std_logic_vector(4 downto 0):=(others => '0');
signal decrypt_reg : std_logic:='0';
signal en_decrypt_reg : std_logic;
signal en_len_a, en_len_d, len_init : std_logic;

begin

ld_ctr_out <= ld_ctr;

sync_process: process(clk)
begin

if (rising_edge(clk)) then
    if (rst = '1') then
       current_state <= S_INIT; -- idle state
    else
       current_state <= nstate;
       if (set_h_ready = '1') then
          h_ready <= '1';
       end if;
       if (reset_h_ready = '1') then
          h_ready <= '0';
       end if;
       if (clr_ld_ctr = '1') then
          ld_ctr <= (others => '0');
       end if;
       if (en_ld_ctr = '1') then
          ld_ctr <= std_logic_vector(unsigned(ld_ctr) + 1);
      end if;
      if (en_wr_ctr = '1') then
          wr_ctr <= std_logic_vector(unsigned(wr_ctr) + 1);
      end if;
      if (clr_wr_ctr = '1') then
          wr_ctr <= (others => '0');
      end if;
      if (ld_exp_wr_ctr = '1') then
          exp_wr_ctr <= ld_ctr;
      end if;
      if (set_last_ad_flag = '1') then
          last_ad_flag <= '1';
      end if;
      if (reset_last_ad_flag = '1') then
          last_ad_flag <= '0';
      end if;
      if (set_last_m_flag = '1') then
          last_m_flag <= '1';
      end if;
      if (reset_last_m_flag = '1') then
          last_m_flag <= '0';
      end if;
      if (en_decrypt_reg = '1') then
          decrypt_reg <= decrypt;
      end if;
      en_len_a_z1 <= en_len_a;
      en_len_d_z1 <= en_len_d;
      len_init_z1 <= len_init;
   end if;
end if;

end process;

public_process: process(current_state, bdi_valid, bdo_ready, key_update, key_valid, aes_busy, mult_busy,
                        ld_ctr, wr_ctr, h_ready, bdi_eot, bdi_eoi, bdi_type, msg_auth_ready, decrypt_reg,
                        last_ad_flag, last_m_flag, rdi_valid)
begin
	 -- defaults
bdi_ready <= '0';
key_ready <= '0';
bdo_valid <= '0';
end_of_block <= '0';

en_key <= '0';
en_h <= '0'; 
en_npub <= '0';
en_ctr <= '0';
en_aes <= '0';
en_mult <= '0';
clr_ctr <= '0';
clr_bdi <= '0';
clr_mult <= '0';
en_bdi <= '0';
en_bdo <= '0';
ld_bdo <= '0';
sel_aes <= '0';
xor2_sel <= "00";
len_init <= '0';
en_len_a <= '0';
en_len_d <= '0';
set_h_ready <= '0';
reset_h_ready <= '0';
clr_ld_ctr <= '0';
en_ld_ctr <= '0';
clr_wr_ctr <= '0';
en_wr_ctr <= '0';
ld_exp_wr_ctr <= '0';
set_last_ad_flag <= '0';
set_last_m_flag <= '0';
reset_last_ad_flag <= '0';
reset_last_m_flag <= '0';
msg_auth_valid <= '0';
sel_tag <= '0';
en_decrypt_reg <= '0';

-- Added by Behnaz -------------------------------
--================================================
raReg_en  <= '0';
rbReg_en  <= '0';
c1a_en    <= '0';
c2a_en    <= '0';
c1b_en    <= '0';
c2b_en    <= '0';
d1a_en    <= '0';
d2a_en    <= '0';
d1b_en    <= '0';
d2b_en    <= '0';
--================================================

state_debug <= x"00"; -- profiler default

case current_state is
		 		 
        when S_INIT => 
            clr_mult <= '1';
             clr_bdi <= '1';
             en_ctr <= '1';
             clr_ctr <= '1'; 
             len_init <= '1';
             en_len_a <= '1';
             en_len_d <= '1';
             reset_last_m_flag <= '1';
             reset_last_ad_flag <= '1';
             nstate <= S_CHECK_KEY;	
    
	when S_CHECK_KEY => 

        if (key_update = '1') then
             if (key_valid = '1') then
                 nstate <= S_LOAD_KEY;
                 reset_h_ready <= '1';
             else 
                 nstate <= S_CHECK_KEY;
             end if;
         else 
             if (bdi_valid = '1') then
                   nstate <= S_LOAD_NPUB;
             else
                   nstate <= S_CHECK_KEY;
             end if;
         end if;

         state_debug <= x"01"; -- profiler default

	when S_LOAD_KEY => 

        if (key_valid = '1') then
           key_ready <= '1';
           en_key <= '1';
           if (ld_ctr = KEY_BYTES - 1) then
              clr_ld_ctr <= '1';
              nstate <= S_COMPUTE_H;
           else
              en_ld_ctr <= '1';
              nstate <= S_LOAD_KEY;
           end if;
         else
              nstate <= S_LOAD_KEY;
         end if;

         state_debug <= x"02"; -- profiler default

	when S_COMPUTE_H => 
       
         if (rdi_valid = '1') then
            sel_aes <= '1';
            en_aes <= '1';
            nstate <= S_LOAD_NPUB;
         else
            nstate <= S_COMPUTE_H;
         end if;

         state_debug <= x"03"; -- profiler default

     when S_LOAD_NPUB => 
 
        if (bdi_valid = '1') then
           en_npub <= '1';
           bdi_ready <= '1';
           if (ld_ctr = NPUB_BYTES - 1) then
             en_decrypt_reg <= '1'; 
             clr_ld_ctr <= '1';
             if (bdi_eoi = '1') then -- no AD or PT
                nstate <= S_START_EK0;
             else
                en_ctr <= '1'; 
                nstate <= S_WAIT_AUTH_DATA;
             end if;
           else
             en_ld_ctr <= '1';
             nstate <= S_LOAD_NPUB;
           end if;
        else
            nstate <= S_LOAD_NPUB;
        end if;

        state_debug <= x"04"; -- profiler default

   when S_WAIT_AUTH_DATA => 
        if (bdi_valid = '1' and rdi_valid = '1') then -- cannot tell what is data type until bdi_valid
           if (bdi_type = AD_TYPE) then -- AD
              nstate <= S_LOAD_AD;
           else -- Block is PT
              if (h_ready = '1') then
                 en_aes <= '1';
                 nstate <= S_LOAD_M; -- start Ek(npub||ctr)
              else
                  nstate <= S_WAIT_H;
              end if;
           end if;
        else 
           nstate <= S_WAIT_AUTH_DATA;
        end if;
	     
        state_debug <= x"05"; -- profiler default
	  
	when S_WAIT_H => -- we want to start a PT block but aes is busy
        if (h_ready = '1' and rdi_valid = '1') then
              en_aes <= '1';
              nstate <= S_LOAD_M;
        else
              if (h_ready = '0' and aes_busy = '0') then
                 en_h <= '1';
                 set_h_ready <= '1';
              end if;
              nstate <= S_WAIT_H;
        end if;
	
        state_debug <= x"06"; -- profiler default

    when S_LOAD_AD => 
		
         if (bdi_valid = '1') then
                bdi_ready <= '1';
                en_bdi <= '1';
                en_ld_ctr <= '1';
                if ((ld_ctr = BDI_BYTES - 1) or bdi_eot = '1') then
                   if (bdi_eot = '1') then
                      set_last_ad_flag <= '1';
                   end if;
                   if (bdi_eoi = '1') then
                      set_last_m_flag <= '1';
                   end if;
                   nstate <= S_PROCESS_AD;
                   en_len_a <= '1'; -- write # of AD bytes to AD length counter
                else 
                   nstate <= S_LOAD_AD;
                end if;
         else
                nstate <= S_LOAD_AD;
         end if;

         state_debug <= x"07"; -- profiler default

    when S_PROCESS_AD => 

         if (h_ready = '1' and rdi_valid = '1') then -- has Ek(0) -> H completed?
            if (mult_busy = '0') then
               xor2_sel <= "10"; -- AD always comes through bdi_data
                en_mult <= '1';
                clr_bdi <= '1'; 
                clr_ld_ctr <= '1';
                if (last_ad_flag = '1') then -- no more AD
                    if (last_m_flag = '1') then -- no PT
                       en_ctr <= '1';
                       clr_ctr <= '1'; 
                       nstate <= S_START_EK0;
                    else
                       clr_bdi <= '1'; -- reset bdi_data
                       en_aes <= '1'; 
                       nstate <= S_LOAD_M;
                   end if;
                else
                   nstate <= S_LOAD_AD;
                end if;
            else
                nstate <= S_PROCESS_AD;
            end if;
        else
            if (h_ready = '0' and aes_busy = '0') then
               en_h <= '1'; 
               set_h_ready <= '1';
            end if;
            nstate <= S_PROCESS_AD;
        end if;       
	
        state_debug <= x"08"; -- profiler default

	when S_LOAD_M => -- if we are here, we know that there is message
	
             if (bdi_valid = '1') then
                bdi_ready <= '1';
                en_bdi <= '1';
                en_ld_ctr <= '1';
                if ((ld_ctr = BDI_BYTES - 1) or bdi_eot = '1') then
                   if (bdi_eot = '1') then
                      set_last_m_flag <= '1';
                   end if;
                   nstate <= S_PROCESS_M;
                   en_ctr <= '1'; -- test
                   en_len_d <= '1'; -- write # of AD bytes to AD length counter
                   ld_exp_wr_ctr <= '1'; -- load the write counter with the number of bytes that came in	
                else 
                   nstate <= S_LOAD_M;
                end if;
             else
                nstate <= S_LOAD_M;
             end if;
				      
             state_debug <= x"09"; -- profiler default
				
        when S_PROCESS_M => 
	    
             if (aes_busy = '0' and rdi_valid = '1') then
                if (mult_busy = '0') then
                   ld_bdo <= '1'; -- a block of M or C is ready for output
                   en_bdo <= '1';
                   clr_ld_ctr <= '1';
                   if (decrypt_reg = '1') then 
                      xor2_sel <= "10"; -- bdi_data (C)
                   else 
                      xor2_sel <= "00"; -- xor1 (M)
                   end if;
                   en_mult <= '1';
                   if (last_m_flag = '1') then -- last PT segment
                      en_ctr <= '1';
                      clr_ctr <= '1';
                   else
                      en_aes <= '1';
                   end if;
                   clr_bdi <= '1';
                   nstate <= S_M_OUT;
                else
                   nstate <= S_PROCESS_M; 
                end if;
             else
                nstate <= S_PROCESS_M;
             end if;  
	
	         state_debug <= x"0a"; -- profiler default

	when S_M_OUT => 
		
             if (bdo_ready = '1') then         
                 bdo_valid <= '1';
                 en_bdo <= '1';
                 if (wr_ctr = exp_wr_ctr) then
                    clr_wr_ctr <= '1'; 
                    end_of_block <= '1';
                    if (last_m_flag = '1') then
                       nstate <= S_START_EK0;
                    else
                       nstate <= S_LOAD_M;
                    end if;
                 else
                    en_wr_ctr <= '1';
                    nstate <= S_M_OUT;
                 end if;
             else
                 nstate <= S_M_OUT;
             end if;
     
             state_debug <= x"0b"; -- profiler default

     when S_START_EK0 => 

         if (h_ready = '1' and rdi_valid = '1') then
             en_aes <= '1';
             nstate <= S_MULT_LEN;
         else
             nstate <= S_START_EK0;
             if (h_ready = '0' and aes_busy = '0') then
                en_h <= '1';
                set_h_ready <= '1';
             end if;
         end if;

         state_debug <= x"0c"; -- profiler default

      when S_MULT_LEN => 

              if (mult_busy = '0' and rdi_valid = '1') then
                 xor2_sel <= "11"; -- len(a)||len(d)
                 en_mult <= '1';
                 if (decrypt_reg = '1') then
                    nstate <= S_LOAD_EXP_TAG;
                 else
                    nstate <= S_FINISH;
                 end if;
              else
                 nstate <= S_MULT_LEN;
              end if;

              state_debug <= x"0d"; -- profiler default

     when S_LOAD_EXP_TAG => 

          if (bdi_valid = '1') then
             en_bdi <= '1';
             bdi_ready <= '1';
             if (ld_ctr = EXP_TAG_BYTES - 1) then
                clr_ld_ctr <= '1';
                nstate <= S_FINISH;
             else
                 en_ld_ctr <= '1';
                 nstate <= S_LOAD_EXP_TAG;
             end if;
           else
             nstate <= S_LOAD_EXP_TAG;
           end if;

           state_debug <= x"0e"; -- profiler default
           
      

      when S_FINISH => 
           
           xor2_sel <= "01"; -- aes_do EK(npub||1)
           if (mult_busy = '0' and aes_busy = '0') then
              if (decrypt_reg = '1') then
--                 if (msg_auth_ready = '1') then
--                    msg_auth_valid <= '1'; 
--                    nstate <= S_INIT;
--                 else
--                    nstate <= S_FINISH;
--                 end if;
                nstate <= verify_tag1; -- Added by Behnaz
              else 
                 sel_tag <= '1'; 
                 ld_bdo <= '1';
                 en_bdo <= '1';
                 nstate <= S_TAG_OUT;
              end if;
          else
             nstate <= S_FINISH;
          end if;

          state_debug <= x"0f"; -- profiler default
          
      --- Added by Behnaz ---------------------------------------------------------------------------
      --=============================================================================================     
      when verify_tag1 =>
            xor2_sel    <= "01"; -- aes_do EK(npub||1)
            c1a_en      <= '1'; 
            nstate      <= verify_tag2;
                
      when verify_tag2 => 
            xor2_sel    <= "01"; -- aes_do EK(npub||1)
            raReg_en    <= '1';   
            c2a_en      <= '1';
            c1b_en      <= '1';
            nstate      <= verify_tag3;
                
      when verify_tag3 => 
            xor2_sel    <= "01"; -- aes_do EK(npub||1) 
            rbReg_en    <= '1'; 
            d1a_en      <= '1';
            c2b_en      <= '1'; 
            nstate      <= verify_tag4;
        
      when verify_tag4 =>                              
            d1b_en      <= '1';
            d2a_en      <= '1';
            nstate      <= verify_tag5;
            
      when verify_tag5 =>                              
            d2b_en      <= '1';
            nstate      <= verify_tag6;
      
      when verify_tag6 =>
            if (msg_auth_ready = '1') then
                msg_auth_valid <= '1'; 
                nstate <= S_INIT;
            else
                nstate <= verify_tag6;
            end if;
      --=============================================================================================   

     when S_TAG_OUT => 

           if (bdo_ready = '1') then
               en_bdo <= '1';
               bdo_valid <= '1';
               if (wr_ctr = TAG_BYTES - 1) then
                   clr_wr_ctr <= '1';
                   end_of_block <= '1';
                   nstate <= S_INIT;
               else
                   en_wr_ctr <= '1';
                   nstate <= S_TAG_OUT;
               end if;
            else
                nstate <= S_TAG_OUT;
            end if;
            state_debug <= x"10"; -- profiler default

	when others =>
	  
	end case; 

end process;
		
end behavioral; 

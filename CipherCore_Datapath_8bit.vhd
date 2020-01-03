-------------------------------------------------------------------------------
--! @file       CipherCore_Datapath_8bit.vhd
--! @author     William Diehl 
--! @brief      Datapath for AES-GCM in LW interface with PW=SW=8
--! @version    02-24-2018     
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.AEAD_pkg.all;

entity CipherCore_Datapath_8bit is
    generic (
        G_MAX_LEN           : integer := SINGLE_PASS_MAX;
        G_NPUB_SIZE         : integer := 96; -- default for aes-gcm
        G_DBLK_SIZE         : integer := 128; --default for aes-gcm
        G_KEY_SIZE		    : integer := 128 --default for aes-gcm
    );
    port    (
        clk                 : in  std_logic;
        rst                 : in  std_logic;

        --! Input
        bdi_a, bdi_b        : in  std_logic_vector(8 - 1 downto 0):=(others => '0');
        key_a, key_b        : in  std_logic_vector(8 - 1 downto 0);
        ld_ctr			    : in  std_logic_vector(4 downto 0);
        rdi_data            : in std_logic_vector(64 - 1 downto 0);
        rdi_valid           : in std_logic;

        --! Control        
        aes_done            : out std_logic;
        mult_done           : out std_logic;
        mult_busy           : out std_logic;
        aes_busy            : out std_logic;
        en_key              : in  std_logic;
        en_h                : in  std_logic;
        en_npub             : in  std_logic;
        en_ctr              : in  std_logic;
        en_aes              : in  std_logic;
        en_mult             : in  std_logic;
        clr_mult            : in  std_logic;
        clr_ctr             : in  std_logic;
        clr_bdi             : in  std_logic:='0';
        en_bdi              : in  std_logic:='0';
        en_bdo              : in  std_logic;
        ld_bdo              : in  std_logic;
        sel_aes             : in  std_logic;
        xor2_sel            : in  std_logic_vector(1 downto 0);
        msg_auth            : out std_logic;
        len_init            : in std_logic;
        en_len_a            : in std_logic;
        en_len_d            : in std_logic;
        sel_tag             : in std_logic;
        --! Output
        bdo_a, bdo_b        : out std_logic_vector(8 - 1 downto 0);
        --state_debug		    : out std_logic_vector(11 downto 0)
        
         -- Added by Behnaz ------------------------------------
         --=====================================================
         raReg_en       : in std_logic;
         rbReg_en       : in std_logic;
         c1a_en         : in std_logic;
         c2a_en         : in std_logic;
         c1b_en         : in std_logic;
         c2b_en         : in std_logic;
         d1a_en         : in std_logic;
         d2a_en         : in std_logic;
         d1b_en         : in std_logic;
         d2b_en         : in std_logic
         --=====================================================
    );

end entity CipherCore_Datapath_8bit;

architecture structural of CipherCore_Datapath_8bit is

    constant ZEROS          : std_logic_vector(128 - 1 downto 0):= (others => '0');
    constant CTR_INIT_CONST : std_logic_vector(31 downto 0):=x"00000001";
    constant WHITECONST : std_logic_vector(127 downto 0):=x"FEDCBA98765432105577AABB22DDFF66"; -- whitening constant

    type bdi_array is array(0 to 15) of std_logic_vector(7 downto 0);
    type bdi_signal_array is array(0 to 15) of std_logic;

    signal next_bdi_data_a, bdi_data_reg_a, next_bdi_data_b, bdi_data_reg_b : bdi_array;
    signal bdi_data_en : bdi_signal_array;
    signal npub_a, next_npub_a, npub_b, next_npub_b : std_logic_vector(G_NPUB_SIZE - 1 downto 0);
    signal bdi_data_a, bdi_data_b : std_logic_vector(G_DBLK_SIZE - 1 downto 0); -- 128 bits
    signal bdi_valid_bytes : std_logic_vector(15 downto 0);
    signal bdi_valid_bits  : std_logic_vector(127 downto 0);
    signal next_key_reg_a,  next_key_reg_b, key_reg_a, key_reg_b : std_logic_vector(G_KEY_SIZE - 1 downto 0);
    signal h_reg_a, h_reg_b : std_logic_vector(G_DBLK_SIZE - 1 downto 0);
    signal next_ctr, ctr_reg : std_logic_vector(31 downto 0); -- per AES-GCM spec
    signal gctr_a, gctr_b : std_logic_vector(127 downto 0);
    signal aes_din_a, aes_din_b, aes_do_a, aes_do_b : std_logic_vector(127 downto 0);
    signal mult_do_a, mult_do_b : std_logic_vector(127 downto 0);
    signal xor1_in_a, xor1_in_b, xor2_in_a, xor2_in_b, xor1_out_a, xor1_out_b, xor2_out_a, xor2_out_b : std_logic_vector(127 downto 0);
    signal result_a, result_b, next_bdo_reg_a, next_bdo_reg_b, bdo_reg_a, bdo_reg_b, aes_do_trunc_a, aes_do_trunc_b : std_logic_vector(127 downto 0);
    signal len_a, len_b : std_logic_vector(127 downto 0);
    signal len_a_reg, next_len_a_reg, len_d_reg, next_len_d_reg : std_logic_vector(G_MAX_LEN - 1 downto 0);
    
    -- Added by Behnaz ----------------------------------------------------------------------------
    --=============================================================================================
    signal ra, rb           : std_logic_vector(63 downto 0);  
    signal c1a_in, c1a_out  : std_logic_vector(63 downto 0);
    signal c2a_in, c2a_out  : std_logic_vector(63 downto 0);
    signal c1b_in, c1b_out  : std_logic_vector(63 downto 0);
    signal c2b_in, c2b_out  : std_logic_vector(63 downto 0);
    signal d1a_in, d1a_out  : std_logic_vector(63 downto 0);
    signal d2a_in, d2a_out  : std_logic_vector(63 downto 0);
    signal d1b_in, d1b_out  : std_logic_vector(63 downto 0);
    signal d2b_in, d2b_out  : std_logic_vector(63 downto 0);
    
    signal etag             : std_logic_vector(127 downto 0);
    signal ctag             : std_logic_vector(127 downto 0);
    --=============================================================================================
    
    signal aes_rdy, mult_rdy : std_logic;
	 
    constant RW : integer:=64;
    constant RREGLEN : integer:= 256; -- length of randomness accumulator
    signal rnd_reg : std_logic_vector(RREGLEN - 1 downto 0):=(others => '0');
   
begin

-- determine bdi_valid_bytes from ld_ctr
    
    with ld_ctr select
        bdi_valid_bytes <= x"0000" when "00000",
                           x"0001" when "00001",
                           x"0003" when "00010",
                           x"0007" when "00011",
                           x"000F" when "00100",
                           x"001F" when "00101",
                           x"003F" when "00110",
                           x"007F" when "00111",
                           x"00FF" when "01000",
                           x"01FF" when "01001",
                           x"03FF" when "01010",
                           x"07FF" when "01011",
                           x"0FFF" when "01100",
                           x"1FFF" when "01101",
                           x"3FFF" when "01110",
                           x"7FFF" when "01111",
                           x"FFFF" when "10000",
                           x"FFFF" when others;
				
-- load variable length bdi_data (which could be npub, AD, M, C, or exp_tag) from bdi
    getBdi:
    for i in 0 to 15 generate
		  
-- WHITECONST is whitening - equivalent to (others => '0')
        next_bdi_data_a(i) <= WHITECONST(i*8 + 7 downto i * 8) when (clr_bdi = '1') else bdi_a;
        next_bdi_data_b(i) <= WHITECONST(i*8 + 7 downto i * 8) when (clr_bdi = '1') else bdi_b;

        bdi_a_regs: entity work.reg_n(behavioral)
        generic map(N => 8)
        port map(
             clk => clk,
             en => bdi_data_en(i),
             d => next_bdi_data_a(i),
             q => bdi_data_reg_a(i)
        );

        bdi_b_regs: entity work.reg_n(behavioral)
        generic map(N => 8)
        port map(
             clk => clk,
             en => bdi_data_en(i),
             d => next_bdi_data_b(i),
             q => bdi_data_reg_b(i)
        );

    end generate;

    bdi_data_en(0) <= '1' when ((ld_ctr = "00000" and en_bdi = '1') or clr_bdi = '1') else '0';
    bdi_data_en(1) <= '1' when ((ld_ctr = "00001" and en_bdi = '1') or clr_bdi = '1') else '0';
    bdi_data_en(2) <= '1' when ((ld_ctr = "00010" and en_bdi = '1') or clr_bdi = '1') else '0';
    bdi_data_en(3) <= '1' when ((ld_ctr = "00011" and en_bdi = '1') or clr_bdi = '1') else '0';
    bdi_data_en(4) <= '1' when ((ld_ctr = "00100" and en_bdi = '1') or clr_bdi = '1') else '0';
    bdi_data_en(5) <= '1' when ((ld_ctr = "00101" and en_bdi = '1') or clr_bdi = '1') else '0';
    bdi_data_en(6) <= '1' when ((ld_ctr = "00110" and en_bdi = '1') or clr_bdi = '1') else '0';
    bdi_data_en(7) <= '1' when ((ld_ctr = "00111" and en_bdi = '1') or clr_bdi = '1') else '0';
    bdi_data_en(8) <= '1' when ((ld_ctr = "01000" and en_bdi = '1') or clr_bdi = '1') else '0';
    bdi_data_en(9) <= '1' when ((ld_ctr = "01001" and en_bdi = '1') or clr_bdi = '1') else '0';
    bdi_data_en(10) <= '1' when ((ld_ctr = "01010" and en_bdi = '1') or clr_bdi = '1') else '0';
    bdi_data_en(11) <= '1' when ((ld_ctr = "01011" and en_bdi = '1') or clr_bdi = '1') else '0';
    bdi_data_en(12) <= '1' when ((ld_ctr = "01100" and en_bdi = '1') or clr_bdi = '1') else '0';
    bdi_data_en(13) <= '1' when ((ld_ctr = "01101" and en_bdi = '1') or clr_bdi = '1') else '0';
    bdi_data_en(14) <= '1' when ((ld_ctr = "01110" and en_bdi = '1') or clr_bdi = '1') else '0';
    bdi_data_en(15) <= '1' when ((ld_ctr = "01111" and en_bdi = '1') or clr_bdi = '1') else '0';

    bdi_data_a <= bdi_data_reg_a(0) &
                  bdi_data_reg_a(1) &
                  bdi_data_reg_a(2) &
                  bdi_data_reg_a(3) &
                  bdi_data_reg_a(4) &
                  bdi_data_reg_a(5) &
                  bdi_data_reg_a(6) &
                  bdi_data_reg_a(7) &
                  bdi_data_reg_a(8) &
                  bdi_data_reg_a(9) &
                  bdi_data_reg_a(10) &
                  bdi_data_reg_a(11) &
                  bdi_data_reg_a(12) &
                  bdi_data_reg_a(13) &
                  bdi_data_reg_a(14) &
                  bdi_data_reg_a(15);	

    bdi_data_b <= bdi_data_reg_b(0) &
                  bdi_data_reg_b(1) &
                  bdi_data_reg_b(2) &
                  bdi_data_reg_b(3) &
                  bdi_data_reg_b(4) &
                  bdi_data_reg_b(5) &
                  bdi_data_reg_b(6) &
                  bdi_data_reg_b(7) &
                  bdi_data_reg_b(8) &
                  bdi_data_reg_b(9) &
                  bdi_data_reg_b(10) &
                  bdi_data_reg_b(11) &
                  bdi_data_reg_b(12) &
                  bdi_data_reg_b(13) &
                  bdi_data_reg_b(14) &
                  bdi_data_reg_b(15);	

-- end load bdi_data
     next_npub_a <= npub_a(G_NPUB_SIZE - 8 - 1 downto 0) & bdi_a; -- left shift into register
     next_npub_b <= npub_b(G_NPUB_SIZE - 8 - 1 downto 0) & bdi_b; -- left shift into register

    npub_a_rg: entity work.reg_n(behavioral)
    generic map(N=>G_NPUB_SIZE) -- 96 bits
    port map(
        clk => clk,
        en => en_npub,
        d => next_npub_a,
        q => npub_a
    );

     npub_b_rg: entity work.reg_n(behavioral)
     generic map(N=>G_NPUB_SIZE) -- 96 bits
      port map(
        clk => clk,
        en => en_npub,
        d => next_npub_b,
        q => npub_b
     );

     next_key_reg_a <= key_reg_a(G_KEY_SIZE - 8 - 1 downto 0) & key_a;
     next_key_reg_b <= key_reg_b(G_KEY_SIZE - 8 - 1 downto 0) & key_b;
  
     key_a_rg: entity work.reg_n(behavioral)
     generic map(N=>G_KEY_SIZE) -- 128 bits
      port map(
        clk => clk,
        en => en_key,
        d => next_key_reg_a,
        q => key_reg_a
     );

     key_b_rg: entity work.reg_n(behavioral)
     generic map(N=>G_KEY_SIZE) -- 128 bits
     port map(
        clk => clk,
        en => en_key,
        d => next_key_reg_b,
        q => key_reg_b
     );

     h_a_rg: entity work.reg_n(behavioral)
     generic map(N=>G_DBLK_SIZE) -- 128 bits
     port map(
        clk => clk,
        en => en_h,
        d => aes_do_a,
        q => h_reg_a
     );

     h_b_rg: entity work.reg_n(behavioral)
     generic map(N=>G_DBLK_SIZE) -- 128 bits
     port map(
        clk => clk,
        en => en_h,
        d => aes_do_b,
        q => h_reg_b
    );
    
    --- Added by Behnaz ---------------------------------------------------------------------------
    --=============================================================================================
    raReg: entity work.reg_n(behavioral) -- Register random share for 64-MSB of the Tag
    generic map(N => 64)
    Port map(
        clk     => clk,
        en      => raReg_en,
        d       => rdi_data,
        q       => ra
    );
    
    rbReg: entity work.reg_n(behavioral) -- Register random share for 64-LSB of the Tag
    generic map(N => 64)
    Port map(
        clk     => clk,
        en      => rbReg_en,
        d       => rdi_data,
        q       => rb
    );
    
    c1a_in      <= xor2_out_a(127 downto 64) xor bdi_data_a(127 downto 64);
    c1aReg: entity work.reg_n(behavioral) 
    generic map(N => 64)
    Port map(
        clk     => clk,
        en      => c1a_en,
        d       => c1a_in,
        q       => c1a_out
    );
    
    c2a_in      <= xor2_out_b(127 downto 64) xor bdi_data_b(127 downto 64);       
    c2aReg: entity work.reg_n(behavioral)
    generic map(N => 64)
    Port map(
        clk     => clk,
        en      => c2a_en,
        d       => c2a_in,
        q       => c2a_out
    );
    
    c1b_in      <= xor2_out_a(63 downto 0) xor bdi_data_a(63 downto 0);
    c1bReg: entity work.reg_n(behavioral)
    generic map(N => 64)
    Port map(
        clk     => clk,
        en      => c1b_en,
        d       => c1b_in,
        q       => c1b_out
    );
      
    c2b_in      <= xor2_out_b(63 downto 0) xor bdi_data_b(63 downto 0);
    c2bReg: entity work.reg_n(behavioral)
    generic map(N => 64)
    Port map(
        clk     => clk,
        en      => c2b_en,
        d       => c2b_in,
        q       => c2b_out
    );

    d1a_in      <= c1a_out xor c2a_out xor ra;
    d1aReg: entity work.reg_n(behavioral)
    generic map(N => 64)
    Port map(
        clk     => clk,
        en      => d1a_en,
        d       => d1a_in,
        q       => d1a_out
    );
    
    d2a_in      <=  d1a_out xor ra;
    d2aReg: entity work.reg_n(behavioral)
    generic map(N => 64)
    Port map(
        clk     => clk,
        en      => d2a_en,
        d       => d2a_in,
        q       => d2a_out
    );
    
    d1b_in      <= c1b_out xor c2b_out xor rb;
    d1bReg: entity work.reg_n(behavioral)
    generic map(N => 64)
    Port map(
        clk     => clk,
        en      => d1b_en,
        d       => d1b_in,
        q       => d1b_out
    ); 
    
    d2b_in      <= d1b_out xor rb;
    d2bReg: entity work.reg_n(behavioral)
    generic map(N => 64)
    Port map(
        clk     => clk,
        en      => d2b_en,
        d       => d2b_in,
        q       => d2b_out
    ); 
    --=============================================================================================


-- reinvestigate prewhitening of counter
    next_ctr <= CTR_INIT_CONST when (clr_ctr = '1') else std_logic_vector(unsigned(ctr_reg) + 1);

    ctr_rg: entity work.reg_n(behavioral)
    generic map(N=> 32) -- per AES-GCM spec
    port map(	
        clk => clk,
        en => en_ctr,
        d => next_ctr,
        q => ctr_reg
    );

-- aes core
    gctr_a <= npub_a & ctr_reg; -- npub||ctr
    gctr_b <= npub_b & ZEROS(31 downto 0); -- npub||ctr

-- WHITECONST is whitening - equivalent to (others => '0')
    aes_din_a <= WHITECONST when sel_aes = '1' else gctr_a;
    aes_din_b <= WHITECONST when sel_aes = '1' else gctr_b;

    uAES: entity work.AES(structural)
    port map(
        clock => clk,
        start => en_aes,
        rdi_valid => rdi_valid,
        done	=> aes_done,
        busy => aes_busy,
        remask => rdi_data(39 downto 0),
        data_in_a => aes_din_a,
        data_in_b => aes_din_b,
        key_in_a => key_reg_a,
        key_in_b => key_reg_b,
        data_out_a => aes_do_a,
        data_out_b => aes_do_b
        --state_debug => state_debug(7 downto 0)
   );

-- gf128 multiplier
    
     rnd_process: process(clk)
     begin
        if (rising_edge(clk)) then
            rnd_reg <= rnd_reg(RREGLEN - RW - 1 downto 0) & rdi_data;
        end if;
     end process;
	 
    uMult: entity work.GF128_seq_mul_TI(structural)
    port map (clk=>clk,
              clr_mult => clr_mult,
              start=> en_mult,
              rdi_valid => rdi_valid,
              ma => rnd_reg(255 downto 128), -- initial reshare
              mb => rnd_reg(127 downto 0), -- initial reshare
              xa => xor2_out_a,
              xb => xor2_out_b,
              ya => h_reg_a,
              yb => h_reg_b,
              done=> mult_done,
              busy => mult_busy,
              oa => mult_do_a,
              ob => mult_do_b
  --state_debug => state_debug(11 downto 8)
  );

    xor1_out_a <= aes_do_trunc_a; 
    xor1_out_b <= aes_do_trunc_b; 

    with xor2_sel select
        xor2_in_a <= xor1_out_a when "00", -- CT
                     aes_do_a when "01", -- Ek(npub||1)
                     bdi_data_a when "10", -- AD
                     len_a when "11", -- len(A)||len(C)
                     len_a when others;

    with xor2_sel select
        xor2_in_b <= xor1_out_b when "00", -- CT
                     aes_do_b when "01", -- Ek(npub||1)
                     bdi_data_b when "10", -- AD
                     len_b when "11", -- len(A)||len(C)
                     len_b when others; 

    xor2_out_a <= mult_do_a xor xor2_in_a;
    xor2_out_b <= mult_do_b xor xor2_in_b;
	 
    result_a <= xor1_out_a when sel_tag = '0' else xor2_out_a; -- if tag then sel_tag = '1'
    result_b <= xor1_out_b when sel_tag = '0' else xor2_out_b; -- if tag then sel_tag = '1'

    next_bdo_reg_a <= result_a when (ld_bdo = '1') else bdo_reg_a(G_DBLK_SIZE - 8 - 1 downto 0) & x"00"; -- shift left to dump to bdo
    next_bdo_reg_b <= result_b when (ld_bdo = '1') else bdo_reg_b(G_DBLK_SIZE - 8 - 1 downto 0) & x"00"; -- shift left to dump to bdo

    bdo_a_rg: entity work.reg_n(behavioral)
    generic map(N=> G_DBLK_SIZE) -- 128
    port map(
        clk => clk,
        en => en_bdo,
        d => next_bdo_reg_a,
        q => bdo_reg_a
    );

    bdo_b_rg: entity work.reg_n(behavioral)
    generic map(N=> G_DBLK_SIZE) -- 128
    port map(
        clk => clk,
        en => en_bdo,
        d => next_bdo_reg_b,
        q => bdo_reg_b
    );

    bdo_a <= bdo_reg_a(127 downto 120); -- dump one byte at a time
    bdo_b <= bdo_reg_b(127 downto 120); -- dump one byte at a time
    --! Removed for t-test
    --msg_auth <= '1' when xor2_out = bdi_data else '0';
--    msg_auth <= '1';
    
    -- Added by Behnaz ---------------------------------------------------------
    --==========================================================================
    msg_auth <= '1' when ((d2a_out = 0) and (d2b_out = 0)) else '0';
    --==========================================================================
    
-- truncate output of C or M to match input if last block not full

    genXor:
    for i in 15 downto 0 generate
        bdi_valid_bits(8*i+7 downto 8*i) <= (others => bdi_valid_bytes(15-i));

        aes_do_trunc_a(8*i+7 downto 8*i) <=  ((bdi_data_a(8*i+7 downto 8*i) xor
                                             aes_do_a(8*i+7 downto 8*i)) and bdi_valid_bits(8*i+7 downto 8*i)) xor
                                             WHITECONST(8*i+7 downto 8*i);

        aes_do_trunc_b(8*i+7 downto 8*i) <=  ((bdi_data_b(8*i+7 downto 8*i) xor
                                             aes_do_b(8*i+7 downto 8*i)) and bdi_valid_bits(8*i+7 downto 8*i)) xor
                                             WHITECONST(8*i+7 downto 8*i);
    end generate;

-- compute and store len(A)||len(C) for tag generation

-- WHITECONST is whitening - equivalent to (others => '0')
    len_a <= WHITECONST(63 downto G_MAX_LEN + 3) & len_a_reg & "000" 
    & WHITECONST(63 downto G_MAX_LEN + 3) & ZEROS(G_MAX_LEN - 1 downto 0) & "000";

    len_b <= WHITECONST(63 downto G_MAX_LEN + 3) & ZEROS(G_MAX_LEN - 1 downto 0) & "000" 
    & WHITECONST(63 downto G_MAX_LEN + 3) & len_d_reg & "000";

-- AD length counter 
    	 
   next_len_a_reg <= (others => '0') when (len_init = '1') else
   std_logic_vector(unsigned(len_a_reg) + unsigned(ld_ctr));
	 
   len_a_ctr: entity work.reg_n(behavioral)
    generic map(N=>G_MAX_LEN)
    port map(
        clk => clk,
        en => en_len_a,
        d => next_len_a_reg,
        q => len_a_reg
    );

-- AD length counter 
    	 
     next_len_d_reg <= (others => '0') when (len_init = '1') else
     std_logic_vector(unsigned(len_d_reg) + unsigned(ld_ctr));
						 
     len_d_ctr: entity work.reg_n(behavioral)
     generic map(N=>G_MAX_LEN)
     port map(
        clk => clk,
        en => en_len_d,
        d => next_len_d_reg,
        q => len_d_reg
     );
	 
end architecture structural;

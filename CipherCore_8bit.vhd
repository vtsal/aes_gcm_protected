-------------------------------------------------------------------------------
--! @file       CipherCore_8bit.vhd
--! @author     William Diehl
--! @brief      
--! @date       24 May 2018
-------------------------------------------------------------------------------
-- Top-level entity for TI-protected AES

library ieee;
use ieee.std_logic_1164.ALL;
use work.AEAD_pkg.all;

entity CipherCore_8bit is
    generic (
        --! Reset behavior
        G_ASYNC_RSTN    : boolean := False; --! Async active low reset
        --! Block size (bits)
        G_DBLK_SIZE     : integer := 128;   --! Data
        G_KEY_SIZE      : integer := 32;    --! Key
        G_TAG_SIZE      : integer := 128;   --! Tag
        --! The number of bits required to hold block size expressed in
        --! bytes = log2_ceil(G_DBLK_SIZE/8)
        G_LBS_BYTES      : integer := 4;
        --! Maximum supported AD/message/ciphertext length = 2^G_MAX_LEN-1
        G_MAX_LEN       : integer := SINGLE_PASS_MAX
    );
    port (
        --! Global
        clk             : in  std_logic;
        rst             : in  std_logic;
        --! PreProcessor (data)
        key_a, key_b    : in  std_logic_vector(8       -1 downto 0);
        bdi_a, bdi_b    : in  std_logic_vector(8      -1 downto 0);
        --! PreProcessor (controls)
        key_ready       : out std_logic;
        key_valid       : in  std_logic;
        key_update      : in  std_logic;
        decrypt         : in  std_logic;
        bdi_ready       : out std_logic;
        bdi_valid       : in  std_logic;
        bdi_type        : in  std_logic_vector(3 downto 0);
        bdi_partial     : in  std_logic;
        bdi_eot         : in  std_logic;
        bdi_eoi         : in  std_logic;
        bdi_size        : in  std_logic_vector(2 downto 0);
        bdi_valid_bytes : in  std_logic_vector(0 downto 0);
        --! PostProcessor
        bdo_a, bdo_b    : out std_logic_vector(8      -1 downto 0);
        bdo_valid       : out std_logic;
        bdo_ready       : in  std_logic;
        bdo_size        : out std_logic_vector(G_LBS_BYTES+1    -1 downto 0);
        end_of_block    : out std_logic;
        msg_auth        : out std_logic;
        msg_auth_ready  : in std_logic;
        msg_auth_valid  : out std_logic;
        rdi_data        : in std_logic_vector(63 downto 0);
        rdi_valid       : in std_logic;
		  
        state_debug     : out std_logic_vector(19 downto 0) -- optional
    );
end entity CipherCore_8bit;

architecture structural of CipherCore_8bit is
    signal aes_done             : std_logic;
    signal mult_done            : std_logic;
    signal aes_busy             : std_logic;
    signal mult_busy            : std_logic;
    signal en_key               : std_logic;
    signal en_h                 : std_logic;
    signal en_npub              : std_logic;
    signal en_ctr               : std_logic;
    signal en_aes               : std_logic;
    signal en_mult              : std_logic;
    signal en_bdi               : std_logic;
    signal en_bdo               : std_logic;
    signal clr_ctr              : std_logic;
    signal clr_mult             : std_logic;
    signal clr_bdi              : std_logic;
    signal ld_bdo               : std_logic;
    signal sel_tag              : std_logic;
    signal xor2_sel             : std_logic_vector(1 downto 0);
    signal sel_aes              : std_logic;
    signal ld_ctr               : std_logic_vector(4 downto 0);
    signal en_len_a, en_len_d, len_init : std_logic;
    
    -- Added by Behnaz ------------------------------------
    --=====================================================
    signal     raReg_en         : std_logic;
    signal     rbReg_en         : std_logic;
    signal     c1a_en           : std_logic;
    signal     c2a_en           : std_logic;
    signal     c1b_en           : std_logic;
    signal     c2b_en           : std_logic;
    signal     d1a_en           : std_logic;
    signal     d2a_en           : std_logic;
    signal     d1b_en           : std_logic;
    signal     d2b_en           : std_logic;
    --=====================================================
	 
begin

    u_cc_dp:
    entity work.CipherCore_Datapath_8bit(structural)
    generic map (G_MAX_LEN => G_MAX_LEN)
    port map (
        clk             => clk              ,
        rst             => rst              ,

        --! Input Processor
        key_a           => key_a              ,
        key_b           => key_b              ,
        bdi_a           => bdi_a              ,
        bdi_b           => bdi_b              ,
        ld_ctr          => ld_ctr             ,
        rdi_data        => rdi_data,
        rdi_valid       => rdi_valid,

        --! Output Processor
        bdo_a           => bdo_a              ,
        bdo_b           => bdo_b              ,
        msg_auth        => msg_auth           ,

        --! Controller
        en_len_a        => en_len_a           ,
        en_len_d        => en_len_d           ,
        len_init        => len_init           ,

        aes_done        => aes_done         ,
        mult_done       => mult_done        ,
        aes_busy        => aes_busy         ,
        mult_busy       => mult_busy        ,

        en_key          => en_key           ,
        en_h            => en_h             ,
        en_npub         => en_npub          ,
        en_ctr          => en_ctr           ,
        en_aes          => en_aes           ,
        en_mult         => en_mult          ,
        en_bdi          => en_bdi           ,
        ld_bdo          => ld_bdo           ,
        en_bdo          => en_bdo           ,
        clr_ctr         => clr_ctr          ,
        clr_mult        => clr_mult         ,
        clr_bdi         => clr_bdi          ,
        sel_tag         => sel_tag          ,
        xor2_sel        => xor2_sel         ,
        sel_aes         => sel_aes          ,
        --state_debug     => state_debug(11 downto 0)
        
         -- Added by Behnaz ------------------------------------
         --=====================================================
         raReg_en       => raReg_en         ,
         rbReg_en       => rbReg_en         ,
         c1a_en         => c1a_en           ,
         c2a_en         => c2a_en           ,
         c1b_en         => c1b_en           ,
         c2b_en         => c2b_en           ,
         d1a_en         => d1a_en           ,
         d2a_en         => d2a_en           ,
         d1b_en         => d1b_en           ,
         d2b_en         => d2b_en
         --=====================================================		  
    );

    u_cc_ctrl:
    entity work.CipherCore_Controller_8bit(behavioral)
    port map (
        clk             => clk              ,
        rst             => rst              ,

        --! Input
        key_ready       => key_ready        ,
        key_valid       => key_valid        ,
        rdi_valid       => rdi_valid,
        key_update      => key_update       ,
        decrypt         => decrypt          ,
        bdi_ready       => bdi_ready        ,
        bdi_valid       => bdi_valid        ,
        bdi_type        => bdi_type         ,
        bdi_eot         => bdi_eot          ,
        bdi_eoi         => bdi_eoi          ,

        ld_ctr_out      => ld_ctr           ,
        aes_done        => aes_done         ,
        mult_done       => mult_done        ,
        aes_busy        => aes_busy         ,
        mult_busy       => mult_busy        ,
        en_key          => en_key           ,
        en_h            => en_h             ,
        en_npub         => en_npub          ,
        en_ctr          => en_ctr           ,
        en_aes          => en_aes           ,
        en_mult         => en_mult          ,
        en_bdi          => en_bdi           ,
        en_bdo          => en_bdo           ,
        clr_ctr         => clr_ctr          ,
        clr_mult        => clr_mult         ,
        clr_bdi         => clr_bdi          ,
        ld_bdo          => ld_bdo           ,
        sel_tag         => sel_tag          ,
        xor2_sel        => xor2_sel         ,
        sel_aes         => sel_aes          , 
        en_len_a_z1     => en_len_a         ,
        en_len_d_z1     => en_len_d         ,
        len_init_z1     => len_init         ,

        --! Output
        msg_auth_valid  => msg_auth_valid   ,
        msg_auth_ready  => msg_auth_ready   ,
        end_of_block    => end_of_block     ,
        bdo_ready       => bdo_ready        ,
        bdo_valid       => bdo_valid        ,
		  --state_debug     => state_debug(19 downto 12)
		  
		-- Added by Behnaz ------------------------------------
         --=====================================================
         raReg_en       => raReg_en         ,
         rbReg_en       => rbReg_en         ,
         c1a_en         => c1a_en           ,
         c2a_en         => c2a_en           ,
         c1b_en         => c1b_en           ,
         c2b_en         => c2b_en           ,
         d1a_en         => d1a_en           ,
         d2a_en         => d2a_en           ,
         d1b_en         => d1b_en           ,
         d2b_en         => d2b_en
         --=====================================================		
    );
	 
end structural;

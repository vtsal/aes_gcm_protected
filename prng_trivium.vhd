-- =====================================================================
-- Copyright © 2017-2018 by Cryptographic Engineering Research Group (CERG),
-- ECE Department, George Mason University
-- Fairfax, VA, U.S.A.
-- Author: Farnoud Farahmand
-- =====================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-- use work.PRNG_pkg.all;

entity prng_trivium is
   generic (
			RW : integer:= 64  -- allowable values are 1, 2, ... 64
    );
    port(
        clk         : in  std_logic;
        rst         : in  std_logic;
		en_prng     : in  std_logic;
        seed        : in  std_logic_vector(128 - 1 downto 0);
		reseed      : in std_logic;
		reseed_ack  : out std_logic;
		rdi_data    : out std_logic_vector(RW - 1 downto 0);
		rdi_ready   : in std_logic;
		rdi_valid   : out std_logic
    );
end prng_trivium;

architecture structural of prng_trivium is
    type state_type     is (S_IDLE, S_RESEED, S_RUN);
    signal state,nstate : state_type;

    constant ZEROES     : std_logic_vector(128 - 1 downto 0):=(others => '0');
    signal ctr          : std_logic_vector(RW - 1 downto 0);
    signal key          : std_logic_vector(80 - 1 downto 0);
    signal iv           : std_logic_vector(80 - 1 downto 0);
    signal key_iv_update    : std_logic;
    signal init_done    : std_logic;
    signal reseed_req   : std_logic;
    signal din_valid    : std_logic;
    signal din_ready    : std_logic;
    signal clr_ctr      : std_logic;
    signal en_ctr       : std_logic;


begin

--! DATAPATH --!--!--!--!--!--!--!--!--!--!--!--!--!--!--!--!--!--!--!--!--!
    key <= seed(80 -1 downto 0);
    iv  <= seed(128-1 downto 80)&x"00000000";

    trivium_primitive: entity work.trivium(behavioral)
	generic map(
        M_SIZE          => RW
    )
    port map(
        clk         => clk,
        rst         => rst,

        key           => key,
        iv            => iv,
        key_iv_update => key_iv_update,
        init_done     => init_done,

        din         => ctr,
        din_valid   => din_valid,
        din_ready   => din_ready,

        dout        => rdi_data,
        dout_valid  => rdi_valid,
        dout_ready  => rdi_ready,

        done        => reseed_req
    );

    --! CONTROLLER --!--!--!--!--!--!--!--!--!--!--!--!--!--!--!--!--!--!--!--!-
	sync_process: process(clk)
	begin
		if (rising_edge(clk)) then
 		   if (rst = '1') then
				state <= S_IDLE;
			else
				state <= nstate;
			end if;
			if (clr_ctr = '1') then
				ctr <= ZEROES(RW-1 downto 0);
            elsif (en_ctr = '1') then
				ctr <= std_logic_vector(unsigned(ctr) + 1);
			end if;
		end if;
	end process;

    state_process: process(state, reseed, init_done, reseed_req, en_prng, din_ready)
    begin
        -- defaults
        nstate        <= state;
        key_iv_update <= '0';
        reseed_ack    <= '0';
        en_ctr        <= '0';
        din_valid     <= '0';
        clr_ctr       <= '0';

    	case state is

    		when S_IDLE =>
    			if (reseed = '1') then
                    key_iv_update <= '1';
    				nstate        <= S_RESEED;
    			end if;

    		when S_RESEED =>
                if (init_done = '1') then
                    clr_ctr     <= '1';
                    reseed_ack  <= '1';
                    nstate      <= S_RUN;
    			end if;

    		when S_RUN =>
                if (reseed_req = '1') then
                    if (reseed = '1') then
                        key_iv_update <= '1';
                        nstate        <= S_RESEED;
                    else
                        nstate        <= S_IDLE;
                    end if;
    			elsif (reseed = '1') then
    				key_iv_update <= '1';
                    nstate        <= S_RESEED;
                elsif (en_prng = '1') then
                    din_valid   <= '1';
                    if (din_ready = '1') then
                        en_ctr <= '1';
                    end if;
                end if;

    		when OTHERS =>

    	end case;

    end process;

end structural;

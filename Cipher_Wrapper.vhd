-- Cipher_Wrapper

library ieee;
use ieee.std_logic_1164.ALL;

entity Cipher_Wrapper is
    generic (
        G_DBLK_SIZE              : integer := 128;  --! Data Block size (bits)
        G_KEY_SIZE               : integer := 128  --! Key size (bits)
            );
    port (
        --! Global signals
        clk             : in  std_logic;
        init            : in  std_logic;
        done            : out std_logic; 
 
        --! SERDES signals
        sin             : in  std_logic;
        ssel            : in  std_logic;
        sout            : out std_logic
    );
end entity Cipher_Wrapper;

architecture structural of Cipher_Wrapper is
    signal sipo         : std_logic_vector(G_DBLK_SIZE*5 + G_KEY_SIZE - 1 downto 0);
    signal piso         : std_logic_vector(G_DBLK_SIZE-1 downto 0);
    signal piso_data    : std_logic_vector(G_DBLK_SIZE-1 downto 0);
begin
    pReg:
    process(clk)
    begin
        if rising_edge(clk) then
            sipo <= sin & sipo(G_DBLK_SIZE*5 + G_KEY_SIZE - 1 downto 1);
            if (ssel = '1') then
                piso <= piso_data;
            else
                piso <= '0' & piso(G_DBLK_SIZE-1 downto 1);
            end if;
        end if;
    end process;
    sout <= piso(0);

    uuw:
    entity work.AES(structural)
    
    port map (
        clock                 => clk,
        start                => init,
        done                => done,

        data_in             => sipo(G_DBLK_SIZE - 1 downto 0),
        key_in              => sipo(G_KEY_SIZE + G_DBLK_SIZE - 1 downto G_DBLK_SIZE),
        mask1_in             => sipo(G_DBLK_SIZE + G_KEY_SIZE + G_DBLK_SIZE - 1 downto G_DBLK_SIZE + G_KEY_SIZE),
		  mask2_in             => sipo(2 * G_DBLK_SIZE + G_KEY_SIZE + G_DBLK_SIZE - 1 downto G_DBLK_SIZE + G_KEY_SIZE + G_DBLK_SIZE),
        mask3_in             => sipo(3 * G_DBLK_SIZE + G_KEY_SIZE + G_DBLK_SIZE - 1 downto 2 * G_DBLK_SIZE + G_KEY_SIZE + G_DBLK_SIZE),
		  mask4_in             => sipo(4 * G_DBLK_SIZE + G_KEY_SIZE + G_DBLK_SIZE - 1 downto 3 * G_DBLK_SIZE + G_KEY_SIZE + G_DBLK_SIZE),

        data_out            => piso_data(G_DBLK_SIZE-1 downto 0)
         
    );
end structural;
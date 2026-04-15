library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-------------------------------------------------

entity pdm_driver is
    generic (
        G_CLK_DIV : positive := 32  --! Dělička hodin (100 MHz / 32 = 3.125 MHz)
    );
    port (
        clk          : in  std_logic;  --! Hlavní hodinový signál 100 MHz
        rst          : in  std_logic;  --! Synchronní reset
        mic_clk_o    : out std_logic;  --! Hodiny pro mikrofon
        mic_lr_sel_o : out std_logic;  --! Výběr kanálu: '0' = levý
        mic_data_i   : in  std_logic;  --! PDM data z mikrofonu
        pdm_data_o   : out std_logic;  --! Vzorkovaný PDM bit
        pdm_valid_o  : out std_logic   --! Jednocyklový pulz = nový platný vzorek
    );
end entity pdm_driver;

-------------------------------------------------

architecture Behavioral of pdm_driver is

    signal sig_cnt     : integer range 0 to G_CLK_DIV - 1 := 0;
    signal sig_clk_div : std_logic := '0';

begin

    -- Vždy používáme levý kanál mikrofonu
    mic_lr_sel_o <= '0';

    -- Dělení hlavního clocku a vzorkování PDM dat
    p_clk_div : process (clk) is
    begin
        if rising_edge(clk) then
            if rst = '1' then
                sig_cnt     <= 0;
                sig_clk_div <= '0';
                pdm_data_o  <= '0';
                pdm_valid_o <= '0';
            else
                pdm_valid_o <= '0';  -- Výchozí stav: žádný platný vzorek

                if sig_cnt = G_CLK_DIV - 1 then
                    sig_cnt     <= 0;
                    sig_clk_div <= not sig_clk_div;

                    -- Vzorkování dat na náběžné hraně MIC_CLK (0 -> 1)
                    if sig_clk_div = '0' then
                        pdm_data_o  <= mic_data_i;
                        pdm_valid_o <= '1';
                    end if;
                else
                    sig_cnt <= sig_cnt + 1;
                end if;
            end if;
        end if;
    end process p_clk_div;

    -- Výstupní hodinový signál pro mikrofon
    mic_clk_o <= sig_clk_div;

end architecture Behavioral;
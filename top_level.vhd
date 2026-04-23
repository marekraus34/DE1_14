library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_level is
    port (
        clk          : in  std_logic;                     -- Hlavní hodinový signál systému
        rst          : in  std_logic;                     -- Synchronní reset aktivní v log. 1

        btn_l_i      : in  std_logic;                     -- Tlačítko vlevo  (snížení citlivosti)
        btn_r_i      : in  std_logic;                     -- Tlačítko vpravo (zvýšení citlivosti)
        btn_u_i      : in  std_logic;                     -- Tlačítko nahoře (přepnutí peak hold)
        btn_d_i      : in  std_logic;                     -- Tlačítko dole   (reset peak hodnoty)

        mic_data_i   : in  std_logic;                     -- PDM datový signál z mikrofonu
        mic_clk_o    : out std_logic;                     -- Hodinový signál generovaný pro mikrofon
        mic_lr_sel_o : out std_logic;                     -- Volba kanálu mikrofonu

        led_o        : out std_logic_vector(15 downto 0) -- Výstup na LED lištu
    );
end entity;

architecture Behavioral of top_level is

    -- Ošetřené výstupy tlačítek po debounce
    signal btn_l, btn_r, btn_u, btn_d : std_logic;

    -- Nastavená velikost okna pro PDM filtr
    signal window : std_logic_vector(7 downto 0);

    -- Signály z pdm_driver do pdm_filter
    signal pdm_data, pdm_valid : std_logic;

    -- Výstup z pdm_filter: amplituda a informace o platnosti nové hodnoty
    signal pcm_data  : std_logic_vector(7 downto 0);
    signal pcm_valid : std_logic;

    -- Výstup z peak_hold do led_bar
    signal level       : std_logic_vector(7 downto 0);
    signal peak_active : std_logic;

begin

    -- Debounce pro tlačítko BTNL
    deb_l: entity work.debounce
        port map (
            clk   => clk,
            rst   => rst,
            btn_i => btn_l_i,
            btn_o => btn_l
        );

    -- Debounce pro tlačítko BTNR
    deb_r: entity work.debounce
        port map (
            clk   => clk,
            rst   => rst,
            btn_i => btn_r_i,
            btn_o => btn_r
        );

    -- Debounce pro tlačítko BTNU
    deb_u: entity work.debounce
        port map (
            clk   => clk,
            rst   => rst,
            btn_i => btn_u_i,
            btn_o => btn_u
        );

    -- Debounce pro tlačítko BTND
    deb_d: entity work.debounce
        port map (
            clk   => clk,
            rst   => rst,
            btn_i => btn_d_i,
            btn_o => btn_d
        );

    -- Komunikace s PDM mikrofonem:
    -- generování MIC_CLK, výběr kanálu a vzorkování MIC_DATA
    pdm_drv: entity work.pdm_driver
        port map (
            clk          => clk,
            rst          => rst,
            mic_clk_o    => mic_clk_o,
            mic_lr_sel_o => mic_lr_sel_o,
            mic_data_i   => mic_data_i,
            pdm_data_o   => pdm_data,
            pdm_valid_o  => pdm_valid
        );

    -- Řízení citlivosti:
    -- BTNR zvyšuje citlivost, BTNL snižuje citlivost
    -- Výstupem je velikost integračního okna pro pdm_filter
    sens: entity work.sensitivity_ctrl
        port map (
            clk      => clk,
            rst      => rst,
            btn_up_i => btn_r,
            btn_dn_i => btn_l,
            window_o => window
        );

    -- Převod PDM signálu na amplitudu (PCM-like hodnota)
    -- pdm_filter sčítá jedničky v zadaném okně a vytváří pcm_data
    filt: entity work.pdm_filter
        port map (
            clk         => clk,
            rst         => rst,
            window_i    => window,
            pdm_data_i  => pdm_data,
            pdm_valid_i => pdm_valid,
            pcm_data_o  => pcm_data,
            pcm_valid_o => pcm_valid
        );

    -- Režim peak hold:
    -- BTNU přepíná aktivaci peak hold
    -- BTND resetuje drženou peak hodnotu
    peak: entity work.peak_hold
        port map (
            clk           => clk,
            rst           => rst,
            btn_mode_i    => btn_u,
            btn_reset_i   => btn_d,
            btn_dn_i      => btn_l,
            level_i       => pcm_data,
            valid_i       => pcm_valid,
            level_o       => level,
            peak_active_o => peak_active
        );

    -- Zobrazení výsledné úrovně signálu na LED
    -- Modul led_bar převádí číselnou hodnotu "level" na LED výstup
    leds: entity work.led_bar
        port map (
            clk           => clk,
            rst           => rst,
            level_i       => level,
            valid_i       => pcm_valid,
            peak_active_i => peak_active,
            led_o         => led_o
        );

end architecture;

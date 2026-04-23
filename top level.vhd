-------------------------------------------------
--! @brief Top level entity
--! @version 1.2 – beat_detector on/off via SW0
-------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
-------------------------------------------------
entity top_level is
    port (
        clk          : in  std_logic;
        rst          : in  std_logic;
        btn_l_i      : in  std_logic;
        btn_r_i      : in  std_logic;
        btn_u_i      : in  std_logic;
        btn_d_i      : in  std_logic;
        sw0_i        : in  std_logic;  --! SW0: '1' = beat mode on
        mic_data_i   : in  std_logic;
        mic_clk_o    : out std_logic;
        mic_lr_sel_o : out std_logic;
        led_o        : out std_logic_vector(15 downto 0)
    );
end entity top_level;
-------------------------------------------------
architecture Behavioral of top_level is

    signal btn_l, btn_r, btn_u, btn_d : std_logic;
    signal window      : std_logic_vector(7 downto 0);
    signal pdm_data    : std_logic;
    signal pdm_valid   : std_logic;
    signal pcm_data    : std_logic_vector(7 downto 0);
    signal pcm_valid   : std_logic;
    signal level       : std_logic_vector(7 downto 0);
    signal peak_active : std_logic;
    signal beat_raw    : std_logic;  --! Raw beat signal from detector
    signal beat        : std_logic;  --! Gated beat signal (only when SW0=1)

begin

    --! Gate beat signal with SW0
    beat <= beat_raw and sw0_i;

    deb_l : entity work.debounce
        port map ( clk => clk, rst => rst, btn_i => btn_l_i, btn_o => btn_l );

    deb_r : entity work.debounce
        port map ( clk => clk, rst => rst, btn_i => btn_r_i, btn_o => btn_r );

    deb_u : entity work.debounce
        port map ( clk => clk, rst => rst, btn_i => btn_u_i, btn_o => btn_u );

    deb_d : entity work.debounce
        port map ( clk => clk, rst => rst, btn_i => btn_d_i, btn_o => btn_d );

    pdm_drv : entity work.pdm_driver
        port map (
            clk          => clk,
            rst          => rst,
            mic_clk_o    => mic_clk_o,
            mic_lr_sel_o => mic_lr_sel_o,
            mic_data_i   => mic_data_i,
            pdm_data_o   => pdm_data,
            pdm_valid_o  => pdm_valid
        );

    sens : entity work.sensitivity_ctrl
        port map (
            clk      => clk,
            rst      => rst,
            btn_up_i => btn_r,
            btn_dn_i => btn_l,
            window_o => window
        );

    filt : entity work.pdm_filter
        port map (
            clk         => clk,
            rst         => rst,
            window_i    => window,
            pdm_data_i  => pdm_data,
            pdm_valid_i => pdm_valid,
            pcm_data_o  => pcm_data,
            pcm_valid_o => pcm_valid
        );

    peak : entity work.peak_hold
        port map (
            clk           => clk,
            rst           => rst,
            btn_mode_i    => btn_u,
            btn_reset_i   => btn_d,
            level_i       => pcm_data,
            valid_i       => pcm_valid,
            level_o       => level,
            peak_active_o => peak_active
        );

    beat_det : entity work.beat_detector
        port map (
            clk     => clk,
            rst     => rst,
            level_i => level,
            valid_i => pcm_valid,
            beat_o  => beat_raw
        );

    leds : entity work.led_bar
        port map (
            clk           => clk,
            rst           => rst,
            level_i       => level,
            valid_i       => pcm_valid,
            peak_active_i => peak_active,
            beat_i        => beat,
            led_o         => led_o
        );

end architecture Behavioral;

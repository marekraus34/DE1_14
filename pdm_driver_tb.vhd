library ieee;
use ieee.std_logic_1164.all;

entity tb_pdm_driver is
end tb_pdm_driver;

architecture tb of tb_pdm_driver is

    component pdm_driver
        generic (
            G_CLK_DIV : positive := 32
        );
        port (clk          : in  std_logic;
              rst          : in  std_logic;
              mic_clk_o    : out std_logic;
              mic_lr_sel_o : out std_logic;
              mic_data_i   : in  std_logic;
              pdm_data_o   : out std_logic;
              pdm_valid_o  : out std_logic);
    end component;

    signal clk          : std_logic;
    signal rst          : std_logic;
    signal mic_clk_o    : std_logic;
    signal mic_lr_sel_o : std_logic;
    signal mic_data_i   : std_logic := '0';
    signal pdm_data_o   : std_logic;
    signal pdm_valid_o  : std_logic;

    -- Main clock: 1 MHz (1000 ns perióda)
    -- mic_clk = 1 MHz / (2 * 32) = ~15.6 kHz
    constant TbPeriod : time := 10 ns;
    signal TbClock    : std_logic := '0';
    signal TbSimEnded : std_logic := '0';

begin

    dut : pdm_driver
        generic map (
            G_CLK_DIV => 32
        )
        port map (
            clk          => clk,
            rst          => rst,
            mic_clk_o    => mic_clk_o,
            mic_lr_sel_o => mic_lr_sel_o,
            mic_data_i   => mic_data_i,
            pdm_data_o   => pdm_data_o,
            pdm_valid_o  => pdm_valid_o
        );

    -- Generovanie hodín
    TbClock <= not TbClock after TbPeriod / 2 when TbSimEnded /= '1' else '0';
    clk <= TbClock;

    stimuli : process
    begin
        mic_data_i <= '0';

        -- Reset
        rst <= '1';
        wait for 5 * TbPeriod;
        rst <= '0';

        wait for 200 * TbPeriod;

        -- Simulácia PDM dát z mikrofónu (striedanie 0/1)
        mic_data_i <= '1';
        wait for 640 * TbPeriod;   -- 1 celý cyklus mic_clk

        mic_data_i <= '0';
        wait for 640 * TbPeriod;

        mic_data_i <= '1';
        wait for 640 * TbPeriod;

        mic_data_i <= '1';
        wait for 640 * TbPeriod;

        mic_data_i <= '0';
        wait for 640 * TbPeriod;

        mic_data_i <= '1';
        wait for 640 * TbPeriod;

        wait for 5000 * TbPeriod;

        TbSimEnded <= '1';
        wait;
    end process;

end tb;

configuration cfg_tb_pdm_driver of tb_pdm_driver is
    for tb
    end for;
end cfg_tb_pdm_driver;

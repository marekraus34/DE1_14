-- Testbench automatically generated online
-- at https://vhdl.lapinoo.net
-- Generation date : Thu, 16 Apr 2026 09:38:12 GMT
-- Request id : cfwk-fed377c2-69e0ae049d178

library ieee;
use ieee.std_logic_1164.all;

entity tb_top_level is
end tb_top_level;

architecture tb of tb_top_level is

    component top_level
        port (clk          : in std_logic;
              rst          : in std_logic;
              btn_l_i      : in std_logic;
              btn_r_i      : in std_logic;
              btn_u_i      : in std_logic;
              btn_d_i      : in std_logic;
              mic_data_i   : in std_logic;
              mic_clk_o    : out std_logic;
              mic_lr_sel_o : out std_logic;
              led_o        : out std_logic_vector (15 downto 0));
    end component;

    signal clk          : std_logic;
    signal rst          : std_logic;
    signal btn_l_i      : std_logic;
    signal btn_r_i      : std_logic;
    signal btn_u_i      : std_logic;
    signal btn_d_i      : std_logic;
    signal mic_data_i   : std_logic;
    signal mic_clk_o    : std_logic;
    signal mic_lr_sel_o : std_logic;
    signal led_o        : std_logic_vector (15 downto 0);

    constant TbPeriod : time := 1000 ns; -- ***EDIT*** Put right period here
    signal TbClock : std_logic := '0';
    signal TbSimEnded : std_logic := '0';

begin

    dut : top_level
    port map (clk          => clk,
              rst          => rst,
              btn_l_i      => btn_l_i,
              btn_r_i      => btn_r_i,
              btn_u_i      => btn_u_i,
              btn_d_i      => btn_d_i,
              mic_data_i   => mic_data_i,
              mic_clk_o    => mic_clk_o,
              mic_lr_sel_o => mic_lr_sel_o,
              led_o        => led_o);

    -- Clock generation
    TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';

    -- ***EDIT*** Check that clk is really your main clock signal
    clk <= TbClock;

    stimuli : process
    begin
        -- ***EDIT*** Adapt initialization as needed
        btn_l_i <= '0';
        btn_r_i <= '0';
        btn_u_i <= '0';
        btn_d_i <= '0';
        mic_data_i <= '0';

        -- Reset generation
        -- ***EDIT*** Check that rst is really your reset signal
        rst <= '1';
        wait for 100 ns;
        rst <= '0';
        wait for 100 ns;

        -- ***EDIT*** Add stimuli here
        wait for 100 * TbPeriod;

        -- Stop the clock and hence terminate the simulation
        TbSimEnded <= '1';
        wait;
    end process;

end tb;

-- Configuration block below is required by some simulators. Usually no need to edit.

configuration cfg_tb_top_level of tb_top_level is
    for tb
    end for;
end cfg_tb_top_level;
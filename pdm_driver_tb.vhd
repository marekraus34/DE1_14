-- Testbench automatically generated online
-- at https://vhdl.lapinoo.net
-- Generation date : Thu, 16 Apr 2026 09:33:46 GMT
-- Request id : cfwk-fed377c2-69e0acfab5637

library ieee;
use ieee.std_logic_1164.all;

entity tb_pdm_driver is
end tb_pdm_driver;

architecture tb of tb_pdm_driver is

    component pdm_driver
        port (clk          : in std_logic;
              rst          : in std_logic;
              mic_clk_o    : out std_logic;
              mic_lr_sel_o : out std_logic;
              mic_data_i   : in std_logic;
              pdm_data_o   : out std_logic;
              pdm_valid_o  : out std_logic);
    end component;

    signal clk          : std_logic;
    signal rst          : std_logic;
    signal mic_clk_o    : std_logic;
    signal mic_lr_sel_o : std_logic;
    signal mic_data_i   : std_logic;
    signal pdm_data_o   : std_logic;
    signal pdm_valid_o  : std_logic;

    constant TbPeriod : time := 1000 ns; -- ***EDIT*** Put right period here
    signal TbClock : std_logic := '0';
    signal TbSimEnded : std_logic := '0';

begin

    dut : pdm_driver
    port map (clk          => clk,
              rst          => rst,
              mic_clk_o    => mic_clk_o,
              mic_lr_sel_o => mic_lr_sel_o,
              mic_data_i   => mic_data_i,
              pdm_data_o   => pdm_data_o,
              pdm_valid_o  => pdm_valid_o);

    -- Clock generation
    TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';

    -- ***EDIT*** Check that clk is really your main clock signal
    clk <= TbClock;

    stimuli : process
    begin
        -- ***EDIT*** Adapt initialization as needed
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

configuration cfg_tb_pdm_driver of tb_pdm_driver is
    for tb
    end for;
end cfg_tb_pdm_driver;
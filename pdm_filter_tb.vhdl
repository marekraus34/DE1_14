-- Testbench automatically generated online
-- at https://vhdl.lapinoo.net
-- Generation date : Wed, 15 Apr 2026 18:06:43 GMT
-- Request id : cfwk-fed377c2-69dfd3b38596a

library ieee;
use ieee.std_logic_1164.all;

entity tb_pdm_filter is
end tb_pdm_filter;

architecture tb of tb_pdm_filter is

    component pdm_filter
        port (clk         : in std_logic;
              rst         : in std_logic;
              window_i    : in std_logic_vector (7 downto 0);
              pdm_data_i  : in std_logic;
              pdm_valid_i : in std_logic;
              pcm_data_o  : out std_logic_vector (7 downto 0);
              pcm_valid_o : out std_logic);
    end component;

    signal clk         : std_logic;
    signal rst         : std_logic;
    signal window_i    : std_logic_vector (7 downto 0);
    signal pdm_data_i  : std_logic;
    signal pdm_valid_i : std_logic;
    signal pcm_data_o  : std_logic_vector (7 downto 0);
    signal pcm_valid_o : std_logic;

    constant TbPeriod : time := 1000 ns; -- ***EDIT*** Put right period here
    signal TbClock : std_logic := '0';
    signal TbSimEnded : std_logic := '0';

begin

    dut : pdm_filter
    port map (clk         => clk,
              rst         => rst,
              window_i    => window_i,
              pdm_data_i  => pdm_data_i,
              pdm_valid_i => pdm_valid_i,
              pcm_data_o  => pcm_data_o,
              pcm_valid_o => pcm_valid_o);

    -- Clock generation
    TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';

    -- ***EDIT*** Check that clk is really your main clock signal
    clk <= TbClock;

    stimuli : process
    begin
        -- ***EDIT*** Adapt initialization as needed
        window_i <= (others => '0');
        pdm_data_i <= '0';
        pdm_valid_i <= '0';

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

configuration cfg_tb_pdm_filter of tb_pdm_filter is
    for tb
    end for;
end cfg_tb_pdm_filter;

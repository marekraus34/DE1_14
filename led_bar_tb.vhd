-- Testbench automatically generated online
-- at https://vhdl.lapinoo.net
-- Generation date : Mon, 20 Apr 2026 17:21:40 GMT
-- Request id : cfwk-fed377c2-69e660a46c4dc

library ieee;
use ieee.std_logic_1164.all;

entity tb_led_bar is
end tb_led_bar;

architecture tb of tb_led_bar is

    component led_bar
        port (clk           : in std_logic;
              rst           : in std_logic;
              level_i       : in std_logic_vector (7 downto 0);
              valid_i       : in std_logic;
              peak_active_i : in std_logic;
              led_o         : out std_logic_vector (15 downto 0));
    end component;

    signal clk           : std_logic;
    signal rst           : std_logic;
    signal level_i       : std_logic_vector (7 downto 0);
    signal valid_i       : std_logic;
    signal peak_active_i : std_logic;
    signal led_o         : std_logic_vector (15 downto 0);

    constant TbPeriod : time := 10 ns; -- ***EDIT*** Put right period here
    signal TbClock : std_logic := '0';
    signal TbSimEnded : std_logic := '0';

begin

    dut : led_bar
    port map (clk           => clk,
              rst           => rst,
              level_i       => level_i,
              valid_i       => valid_i,
              peak_active_i => peak_active_i,
              led_o         => led_o);

    -- Clock generation
    TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';

    -- ***EDIT*** Check that clk is really your main clock signal
    clk <= TbClock;

    stimuli : process
begin
    -- Inicializácia
    level_i <= (others => '0');
    valid_i <= '0';
    peak_active_i <= '0';
    rst <= '1';
    wait for 50 ns;
    
    rst <= '0';
    wait for 50 ns;

    -- Test 1: Nízka úroveň
    level_i <= x"0A"; 
    valid_i <= '1';
    wait for 100 ns;
    valid_i <= '0'; 
    wait for 100 ns;

    -- Test 2: Vysoká úroveň
    level_i <= x"C8"; 
    valid_i <= '1';
    wait for 100 ns;
    valid_i <= '0';

    -- Koniec simulácie
    wait for 500 ns;
    TbSimEnded <= '1';
    wait;
end process;

end tb;

-- Configuration block below is required by some simulators. Usually no need to edit.

configuration cfg_tb_led_bar of tb_led_bar is
    for tb
    end for;
end cfg_tb_led_bar;

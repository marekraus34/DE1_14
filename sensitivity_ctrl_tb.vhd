-- Testbench automatically generated online
-- at https://vhdl.lapinoo.net
-- Generation date : Mon, 20 Apr 2026 17:31:44 GMT
-- Request id : cfwk-fed377c2-69e6630083e57

library ieee;
use ieee.std_logic_1164.all;

entity tb_sensitivity_ctrl is
end tb_sensitivity_ctrl;

architecture tb of tb_sensitivity_ctrl is

    component sensitivity_ctrl
        port (clk      : in std_logic;
              rst      : in std_logic;
              btn_up_i : in std_logic;
              btn_dn_i : in std_logic;
              window_o : out std_logic_vector (7 downto 0));
    end component;

    signal clk      : std_logic;
    signal rst      : std_logic;
    signal btn_up_i : std_logic;
    signal btn_dn_i : std_logic;
    signal window_o : std_logic_vector (7 downto 0);

    constant TbPeriod : time := 20 ns; -- ***EDIT*** Put right period here
    signal TbClock : std_logic := '0';
    signal TbSimEnded : std_logic := '0';

begin

    dut : sensitivity_ctrl
    port map (clk      => clk,
              rst      => rst,
              btn_up_i => btn_up_i,
              btn_dn_i => btn_dn_i,
              window_o => window_o);

    -- Clock generation
    TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';

    -- ***EDIT*** Check that clk is really your main clock signal
    clk <= TbClock;

    stimuli : process
    begin
        -- Inicializácia
        btn_up_i <= '0';
        btn_dn_i <= '0';
        rst <= '1';
        wait for 50 ns;
        rst <= '0';
        wait for 50 ns;

        -- 1. Test: Window UP
        btn_up_i <= '1';
        wait for 20 ns; 
        btn_up_i <= '0';
        
        wait for 200 ns; -- pauza na spracovanie

        -- 2. Test: Window DOWN
        btn_dn_i <= '1';
        wait for 20 ns;
        btn_dn_i <= '0';

        wait for 500 ns;

        TbSimEnded <= '1';
        wait;
    end process;

end tb;

-- Configuration block below is required by some simulators. Usually no need to edit.

configuration cfg_tb_sensitivity_ctrl of tb_sensitivity_ctrl is
    for tb
    end for;
end cfg_tb_sensitivity_ctrl;
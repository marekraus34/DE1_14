-- Testbench automatically generated online
-- at https://vhdl.lapinoo.net
-- Generation date : Mon, 20 Apr 2026 16:52:10 GMT
-- Request id : cfwk-fed377c2-69e659ba9e0bb

library ieee;
use ieee.std_logic_1164.all;

entity tb_debounce is
end tb_debounce;

architecture tb of tb_debounce is

    component debounce
       generic (
            G_MAX : positive
        );
        port (
            clk   : in std_logic;
            rst   : in std_logic;
            btn_i : in std_logic;
            btn_o : out std_logic
        );
    end component;

    signal clk   : std_logic;
    signal rst   : std_logic;
    signal btn_i : std_logic;
    signal btn_o : std_logic;

    constant TbPeriod : time := 20 ns; -- ***EDIT*** Put right period here
    signal TbClock : std_logic := '0';
    signal TbSimEnded : std_logic := '0';

begin

    dut : debounce
    generic map (
        G_MAX => 5 
    )
    port map (clk   => clk,
              rst   => rst,
              btn_i => btn_i,
              btn_o => btn_o);

    -- Clock generation
    TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';

    -- ***EDIT*** Check that clk is really your main clock signal
    clk <= TbClock;

    -- constant TbPeriod : time := 20 ns;

    stimuli : process
    begin
        btn_i <= '0';
        rst <= '1';
        wait for 100 ns; -- Reset počas niekoľkých cyklov
        rst <= '0';
        wait for 100 ns;

        btn_i <= '1'; wait for 40 ns;
        btn_i <= '0'; wait for 40 ns;
        btn_i <= '1'; wait for 40 ns;
        btn_i <= '0'; wait for 40 ns;
        
        btn_i <= '1'; 
        
        
        wait for 500 ns; 

       
        btn_i <= '0';
        wait for 500 ns;

        TbSimEnded <= '1';
        wait;
    end process;

end tb;

-- Configuration block below is required by some simulators. Usually no need to edit.

configuration cfg_tb_debounce of tb_debounce is
    for tb
    end for;
end cfg_tb_debounce;
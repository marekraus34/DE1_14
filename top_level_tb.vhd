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

    constant TbPeriod : time := 20 ns; -- ***EDIT*** Put right period here
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

    -- Generovanie hodín
    TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';
    clk <= TbClock;
    
   stimuli : process
    begin
        -- 1. Inicializácia všetkých vstupov
        rst <= '1';
        btn_l_i <= '0'; btn_r_i <= '0'; btn_u_i <= '0'; btn_d_i <= '0';
        mic_data_i <= '0';
        wait for 100 ns;
        
        -- 2. Uvoľnenie resetu
        rst <= '0';
        wait for 100 ns;

        -- 3. Simulácia maximálneho hluku
        mic_data_i <= '1';
        
       
        wait for 150 us; 

        -- 4. Test tlačidiel (napr. zmena citlivosti)
        btn_u_i <= '1';
        wait for 20 us;
        btn_u_i <= '0';

        wait for 50 us;

        -- Ukončenie simulácie
        TbSimEnded <= '1';
        wait;
    end process;
end tb;

-- Configuration block below is required by some simulators. Usually no need to edit.

configuration cfg_tb_top_level of tb_top_level is
    for tb
    end for;
end cfg_tb_top_level;

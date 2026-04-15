-------------------------------------------------
--! @brief Testbench for pdm_filter
--! @version 1.0
--!
--! Tests:
--!   1. Reset behaviour
--!   2. Silent input (all zeros) -> amplitude = 0
--!   3. Medium input (half ones) -> amplitude = window/2
--!   4. Loud input (all ones)    -> amplitude = window
--!   5. Window size change via window_i
-------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
-------------------------------------------------
entity tb_pdm_filter is
end entity tb_pdm_filter;
-------------------------------------------------
architecture Behavioral of tb_pdm_filter is

    constant C_CLK_PERIOD : time    := 10 ns;  --! 100 MHz
    constant C_WINDOW     : integer := 64;      --! Test window size

    signal clk         : std_logic := '0';
    signal rst         : std_logic := '1';
    signal window      : std_logic_vector(7 downto 0) := std_logic_vector(to_unsigned(C_WINDOW, 8));
    signal pdm_data    : std_logic := '0';
    signal pdm_valid   : std_logic := '0';
    signal pcm_data    : std_logic_vector(7 downto 0);
    signal pcm_valid   : std_logic;

begin

    --! DUT instance
    uut : entity work.pdm_filter
        port map (
            clk         => clk,
            rst         => rst,
            window_i    => window,
            pdm_data_i  => pdm_data,
            pdm_valid_i => pdm_valid,
            pcm_data_o  => pcm_data,
            pcm_valid_o => pcm_valid
        );

    --! Clock generator
    clk <= not clk after C_CLK_PERIOD / 2;

    --! Helper procedure: send N PDM bits with given value
    p_stimulus : process is

        --! Send one PDM bit with valid pulse
        procedure send_bit(data : std_logic) is
        begin
            pdm_data  <= data;
            pdm_valid <= '1';
            wait for C_CLK_PERIOD;
            pdm_valid <= '0';
            wait for C_CLK_PERIOD;
        end procedure;

        --! Send a full window of identical bits
        procedure send_window(data : std_logic; count : integer) is
        begin
            for i in 0 to count - 1 loop
                send_bit(data);
            end loop;
        end procedure;

    begin
        -- ------------------------------------------------
        -- Test 1: Reset
        -- ------------------------------------------------
        rst <= '1';
        wait for 5 * C_CLK_PERIOD;
        rst <= '0';
        wait for 2 * C_CLK_PERIOD;

        -- ------------------------------------------------
        -- Test 2: Silent input - all zeros
        -- Expected pcm_data = 0
        -- ------------------------------------------------
        send_window('0', C_WINDOW);
        wait for 10 * C_CLK_PERIOD;

        -- ------------------------------------------------
        -- Test 3: Medium input - half ones, half zeros
        -- Expected pcm_data = 32 (= C_WINDOW / 2)
        -- ------------------------------------------------
        for i in 0 to C_WINDOW - 1 loop
            if i < C_WINDOW / 2 then
                send_bit('1');
            else
                send_bit('0');
            end if;
        end loop;
        wait for 10 * C_CLK_PERIOD;

        -- ------------------------------------------------
        -- Test 4: Loud input - all ones
        -- Expected pcm_data = 64 (= C_WINDOW)
        -- ------------------------------------------------
        send_window('1', C_WINDOW);
        wait for 10 * C_CLK_PERIOD;

        -- ------------------------------------------------
        -- Test 5: Change window size to 32
        -- Expected pcm_data = 16 (half ones in window 32)
        -- ------------------------------------------------
        window <= std_logic_vector(to_unsigned(32, 8));
        for i in 0 to 31 loop
            if i < 16 then
                send_bit('1');
            else
                send_bit('0');
            end if;
        end loop;
        wait for 10 * C_CLK_PERIOD;

        -- End simulation
        wait;
    end process p_stimulus;

end architecture Behavioral;

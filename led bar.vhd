-------------------------------------------------
--! @brief LED bar display (VU meter) with decay + beat flash
--! @version 1.4
--!
--! Normal mode (peak hold inactive):
--!   - LEDs jump up to current amplitude instantly
--!   - Then slowly fall down (decay effect)
--!
--! Peak hold mode (BTNU active):
--!   - Holds maximum level, no decay
--!   - Top LED blinks ~6 Hz as indication
--!
--! Beat detected (beat_i = '1'):
--!   - All 16 LEDs flash ON instantly
--!   - Overrides normal VU meter display
-------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
-------------------------------------------------
entity led_bar is
    generic (
        C_DECAY_TIME : positive := 12_500_000
    );
    port (
        clk           : in  std_logic;
        rst           : in  std_logic;
        level_i       : in  std_logic_vector(7 downto 0);
        valid_i       : in  std_logic;
        peak_active_i : in  std_logic;
        beat_i        : in  std_logic;  --! Beat detected – flash all LEDs
        led_o         : out std_logic_vector(15 downto 0)
    );
end entity led_bar;
-------------------------------------------------
architecture Behavioral of led_bar is

    signal sig_disp_level : integer range 0 to 16 := 0;
    signal sig_level      : integer range 0 to 16 := 0;
    signal sig_decay_cnt  : integer range 0 to C_DECAY_TIME := 0;
    signal sig_blink_cnt  : unsigned(23 downto 0) := (others => '0');
    signal sig_blink      : std_logic := '0';

begin

    sig_level <= to_integer(unsigned(level_i(7 downto 4)));

    p_blink : process (clk) is
    begin
        if rising_edge(clk) then
            if rst = '1' then
                sig_blink_cnt <= (others => '0');
                sig_blink     <= '0';
            else
                sig_blink_cnt <= sig_blink_cnt + 1;
                if sig_blink_cnt = 0 then
                    sig_blink <= not sig_blink;
                end if;
            end if;
        end if;
    end process p_blink;

    p_decay : process (clk) is
    begin
        if rising_edge(clk) then
            if rst = '1' then
                sig_disp_level <= 0;
                sig_decay_cnt  <= 0;
            else
                if peak_active_i = '0' then
                    if valid_i = '1' then
                        if sig_level >= sig_disp_level then
                            sig_disp_level <= sig_level;
                            sig_decay_cnt  <= 0;
                        end if;
                    end if;
                    if sig_disp_level > sig_level then
                        if sig_decay_cnt < C_DECAY_TIME then
                            sig_decay_cnt <= sig_decay_cnt + 1;
                        else
                            sig_disp_level <= sig_disp_level - 1;
                            sig_decay_cnt  <= 0;
                        end if;
                    end if;
                else
                    if valid_i = '1' then
                        if sig_level > sig_disp_level then
                            sig_disp_level <= sig_level;
                        end if;
                    end if;
                    sig_decay_cnt <= 0;
                end if;
            end if;
        end if;
    end process p_decay;

    p_led : process (clk) is
    begin
        if rising_edge(clk) then
            if rst = '1' then
                led_o <= (others => '0');
            else
                -- Beat flash: all LEDs on
                if beat_i = '1' then
                    led_o <= (others => '1');
                else
                    led_o <= (others => '0');
                    for i in 0 to 15 loop
                        if i < sig_disp_level then
                            led_o(i) <= '1';
                        elsif i = sig_disp_level and peak_active_i = '1' then
                            led_o(i) <= sig_blink;
                        end if;
                    end loop;
                end if;
            end if;
        end if;
    end process p_led;

end architecture Behavioral;

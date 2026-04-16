-------------------------------------------------
--! @brief LED bar display (VU meter) with peak decay
--! @version 1.1
--!
--! Converts amplitude value (0-255) to number of
--! lit LEDs (0-16).
--!
--! When peak hold is INACTIVE: shows current level
--! but also holds the peak for C_HOLD_TIME cycles
--! before it drops back down (peak decay effect).
--!
--! When peak hold is ACTIVE (BTNU): holds maximum
--! indefinitely, top LED blinks at ~6 Hz.
-------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
-------------------------------------------------
entity led_bar is
    generic (
        -- How long to hold peak before decay (@ 100 MHz)
        -- 50_000_000 = 0.5 sec, 100_000_000 = 1 sec
        C_HOLD_TIME : positive := 50_000_000
    );
    port (
        clk           : in  std_logic;  --! Main clock
        rst           : in  std_logic;  --! High-active synchronous reset
        level_i       : in  std_logic_vector(7 downto 0);  --! Amplitude 0-255
        valid_i       : in  std_logic;  --! New amplitude pulse
        peak_active_i : in  std_logic;  --! '1' = peak hold mode active (BTNU)
        led_o         : out std_logic_vector(15 downto 0)  --! 16 LEDs output
    );
end entity led_bar;
-------------------------------------------------
architecture Behavioral of led_bar is

    signal sig_level     : integer range 0 to 16 := 0;

    -- Peak decay signals
    signal sig_peak_disp  : integer range 0 to 16 := 0;  -- displayed peak
    signal sig_hold_cnt   : integer range 0 to C_HOLD_TIME := 0;

    -- Blink for peak hold active mode (~6 Hz)
    signal sig_blink_cnt : unsigned(23 downto 0) := (others => '0');
    signal sig_blink     : std_logic := '0';

begin

    sig_level <= to_integer(unsigned(level_i(7 downto 4)));

    --! Blink generator for peak hold active indication
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

    --! Peak decay logic
    --! When peak hold inactive: hold displayed peak for C_HOLD_TIME,
    --! then let it drop to current level
    p_decay : process (clk) is
    begin
        if rising_edge(clk) then
            if rst = '1' then
                sig_peak_disp <= 0;
                sig_hold_cnt  <= 0;
            else
                if peak_active_i = '0' then
                    -- Update peak if new level is higher
                    if valid_i = '1' then
                        if sig_level > sig_peak_disp then
                            sig_peak_disp <= sig_level;
                            sig_hold_cnt  <= 0;  -- Reset hold timer
                        else
                            -- Count hold time
                            if sig_hold_cnt < C_HOLD_TIME then
                                sig_hold_cnt <= sig_hold_cnt + 1;
                            else
                                -- Hold expired: drop to current level
                                sig_peak_disp <= sig_level;
                                sig_hold_cnt  <= 0;
                            end if;
                        end if;
                    end if;
                else
                    -- Peak hold active mode: reset decay
                    sig_peak_disp <= 0;
                    sig_hold_cnt  <= 0;
                end if;
            end if;
        end if;
    end process p_decay;

    --! Update LED bar
    p_led : process (clk) is
    begin
        if rising_edge(clk) then
            if rst = '1' then
                led_o <= (others => '0');
            elsif valid_i = '1' then
                led_o <= (others => '0');
                for i in 0 to 15 loop
                    if peak_active_i = '0' then
                        -- Normal mode: light up to current level
                        if i < sig_level then
                            led_o(i) <= '1';
                        -- Show peak marker (single LED above current level)
                        elsif i = sig_peak_disp and sig_peak_disp > sig_level then
                            led_o(i) <= '1';
                        end if;
                    else
                        -- Peak hold active mode
                        if i < sig_level then
                            led_o(i) <= '1';
                        elsif i = sig_level then
                            led_o(i) <= sig_blink;  -- Blink top LED
                        end if;
                    end if;
                end loop;
            end if;
        end if;
    end process p_led;

end architecture Behavioral;

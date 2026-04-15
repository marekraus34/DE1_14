-------------------------------------------------
--! @brief LED bar display (VU meter)
--! @version 1.0
--!
--! Converts amplitude value (0-255) to number of
--! lit LEDs (0-16). When peak hold is active, the
--! topmost lit LED blinks at ~6 Hz to indicate
--! peak hold mode is on.
-------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
-------------------------------------------------
entity led_bar is
    port (
        clk           : in  std_logic;  --! Main clock
        rst           : in  std_logic;  --! High-active synchronous reset
        level_i       : in  std_logic_vector(7 downto 0);  --! Amplitude 0-255
        valid_i       : in  std_logic;  --! New amplitude pulse
        peak_active_i : in  std_logic;  --! '1' = peak hold mode active
        led_o         : out std_logic_vector(15 downto 0)  --! 16 LEDs output
    );
end entity led_bar;
-------------------------------------------------
architecture Behavioral of led_bar is

    --! Scale 0-255 to 0-16 by taking upper 4 bits
    signal sig_level  : integer range 0 to 16 := 0;

    --! Blink generator for peak hold indication (~6 Hz @ 100 MHz)
    signal sig_blink_cnt : unsigned(23 downto 0) := (others => '0');
    signal sig_blink     : std_logic := '0';

begin

    --! Convert 8-bit amplitude to 0-16 range (divide by 16)
    sig_level <= to_integer(unsigned(level_i(7 downto 4)));

    --! Free-running blink counter
    p_blink : process (clk) is
    begin
        if rising_edge(clk) then
            if rst = '1' then
                sig_blink_cnt <= (others => '0');
                sig_blink     <= '0';
            else
                sig_blink_cnt <= sig_blink_cnt + 1;
                -- Toggle every 2^23 cycles = ~84 ms = ~6 Hz blink
                if sig_blink_cnt = 0 then
                    sig_blink <= not sig_blink;
                end if;
            end if;
        end if;
    end process p_blink;

    --! Update LED bar on each new amplitude value
    p_led : process (clk) is
    begin
        if rising_edge(clk) then
            if rst = '1' then
                led_o <= (others => '0');
            elsif valid_i = '1' then
                led_o <= (others => '0');
                for i in 0 to 15 loop
                    if i < sig_level then
                        -- Lit LEDs below peak level
                        led_o(i) <= '1';
                    elsif i = sig_level and peak_active_i = '1' then
                        -- Top LED blinks when peak hold is active
                        led_o(i) <= sig_blink;
                    end if;
                end loop;
            end if;
        end if;
    end process p_led;

end architecture Behavioral;

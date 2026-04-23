-------------------------------------------------
--! @brief Beat detector
--! @version 1.0
--!
--! Detects sudden amplitude increase (beat/loud sound).
--! When current level rises more than C_THRESHOLD above
--! the running average, a beat is detected and all LEDs
--! flash for C_FLASH_TIME clock cycles.
--!
--! Running average is updated every new pcm sample
--! using simple IIR: avg = avg - avg/8 + level/8
--!
--! SW0 = '1' enables beat mode (gated in top_level)
-------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
-------------------------------------------------
entity beat_detector is
    generic (
        -- Minimum amplitude jump above average to detect beat (0-255)
        -- 40 = medium sensitivity
        -- 20 = high sensitivity (reacts to quiet sounds)
        -- 60 = low sensitivity (only loud sounds)
        C_THRESHOLD  : positive := 40;
        -- How long all LEDs stay on after beat (clock cycles)
        -- 5_000_000 = 50 ms @ 100 MHz
        C_FLASH_TIME : positive := 5_000_000
    );
    port (
        clk     : in  std_logic;  --! Main clock 100 MHz
        rst     : in  std_logic;  --! High-active synchronous reset
        level_i : in  std_logic_vector(7 downto 0);  --! Amplitude from peak_hold
        valid_i : in  std_logic;  --! New amplitude pulse from pdm_filter
        beat_o  : out std_logic   --! '1' = beat detected, flash all LEDs
    );
end entity beat_detector;
-------------------------------------------------
architecture Behavioral of beat_detector is

    -- Running average scaled x8 to avoid division loss
    signal sig_avg      : unsigned(10 downto 0) := (others => '0');
    signal sig_avg_real : unsigned(7 downto 0)  := (others => '0');

    -- Flash counter
    signal sig_flash_cnt : integer range 0 to C_FLASH_TIME := 0;
    signal sig_beat      : std_logic := '0';

begin

    beat_o <= sig_beat;

    p_beat : process (clk) is
        variable v_level : unsigned(7 downto 0);
        variable v_diff  : unsigned(7 downto 0);
    begin
        if rising_edge(clk) then
            if rst = '1' then
                sig_avg       <= (others => '0');
                sig_avg_real  <= (others => '0');
                sig_flash_cnt <= 0;
                sig_beat      <= '0';
            else
                -- Flash timer: keep beat_o high for C_FLASH_TIME cycles
                if sig_beat = '1' then
                    if sig_flash_cnt < C_FLASH_TIME then
                        sig_flash_cnt <= sig_flash_cnt + 1;
                    else
                        sig_beat      <= '0';
                        sig_flash_cnt <= 0;
                    end if;
                end if;

                -- Process new amplitude sample
                if valid_i = '1' then
                    v_level := unsigned(level_i);

                    -- IIR average update: avg = avg - avg/8 + level/8
                    sig_avg      <= sig_avg
                                    - (sig_avg srl 3)
                                    + resize(v_level, 11);
                    sig_avg_real <= sig_avg(10 downto 3);

                    -- Beat detection: current level >> running average
                    if v_level > sig_avg_real then
                        v_diff := v_level - sig_avg_real;
                        if to_integer(v_diff) > C_THRESHOLD then
                            sig_beat      <= '1';
                            sig_flash_cnt <= 0;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process p_beat;

end architecture Behavioral;

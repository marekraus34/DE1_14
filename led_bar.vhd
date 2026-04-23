library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
-------------------------------------------------
entity led_bar is
    generic (
        -- How many clock cycles between each decay step (1 LED drop)
        -- 6_250_000 = drop one LED every 62.5 ms @ 100 MHz (~160 ms total fall)
        -- 12_500_000 = drop one LED every 125 ms @ 100 MHz (~1 sec total fall)
        -- 25_000_000 = drop one LED every 250 ms @ 100 MHz (~2 sec total fall)
        C_DECAY_TIME : positive := 12_500_000
    );
    port (
        clk           : in  std_logic;
        rst           : in  std_logic;
        level_i       : in  std_logic_vector(7 downto 0);
        valid_i       : in  std_logic;
        peak_active_i : in  std_logic;
        led_o         : out std_logic_vector(15 downto 0)
    );
end entity led_bar;
-------------------------------------------------
architecture Behavioral of led_bar is

    -- Current displayed level (what LEDs show)
    signal sig_disp_level : integer range 0 to 16 := 0;

    -- Actual incoming level scaled 0-16
    signal sig_level : integer range 0 to 16 := 0;

    -- Decay counter
    signal sig_decay_cnt : integer range 0 to C_DECAY_TIME := 0;

    -- Blink for peak hold active mode (~6 Hz)
    signal sig_blink_cnt : unsigned(23 downto 0) := (others => '0');
    signal sig_blink     : std_logic := '0';

begin

    -- Scale 0-255 to 0-16
    sig_level <= to_integer(unsigned(level_i(7 downto 4)));

    --! Blink generator ~6 Hz
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

    --! Decay logic:
    --! If new level > displayed: jump up instantly
    --! If new level < displayed: wait C_DECAY_TIME then drop by 1
    p_decay : process (clk) is
    begin
        if rising_edge(clk) then
            if rst = '1' then
                sig_disp_level <= 0;
                sig_decay_cnt  <= 0;
            else
                if peak_active_i = '0' then
                    -- New sample arrived
                    if valid_i = '1' then
                        if sig_level >= sig_disp_level then
                            -- Jump up instantly to new level
                            sig_disp_level <= sig_level;
                            sig_decay_cnt  <= 0;  -- Reset decay timer
                        end if;
                    end if;

                    -- Decay: count down and drop one LED at a time
                    if sig_disp_level > sig_level then
                        if sig_decay_cnt < C_DECAY_TIME then
                            sig_decay_cnt <= sig_decay_cnt + 1;
                        else
                            sig_disp_level <= sig_disp_level - 1;
                            sig_decay_cnt  <= 0;
                        end if;
                    end if;

                else
                 -- Peak hold active: zobrazuj přímo hodnotu z peak_hold
                    if valid_i = '1' then
                        sig_disp_level <= sig_level;
                    end if;
                    sig_decay_cnt <= 0;
                end if;
            end if;
        end if;
    end process p_decay;

    --! Drive LEDs based on displayed level
    p_led : process (clk) is
    begin
        if rising_edge(clk) then
            if rst = '1' then
                led_o <= (others => '0');
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
    end process p_led;

end architecture Behavioral;

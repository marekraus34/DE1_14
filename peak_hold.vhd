-------------------------------------------------
--! @brief Debounce module
--! @version 1.0
--! @author Marek Raus
--! @date 2026
--! @copyright MIT license
-------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
-------------------------------------------------
entity peak_hold is
    port (
        clk           : in  std_logic;  --! Main clock
        rst           : in  std_logic;  --! High-active synchronous reset
        btn_mode_i    : in  std_logic;  --! BTNU: toggle peak hold on/off (debounced pulse)
        btn_reset_i   : in  std_logic;  --! BTND: reset peak value (debounced pulse)
        btn_dn_i      : in  std_logic;   --! BTNL: reset peak value (debounded pulse)
        level_i       : in  std_logic_vector(7 downto 0);  --! Live amplitude from pdm_filter
        valid_i       : in  std_logic;  --! New amplitude pulse from pdm_filter
        level_o       : out std_logic_vector(7 downto 0);  --! Output: peak or live value
        peak_active_o : out std_logic   --! '1' = peak hold mode is active
    );
end entity peak_hold;
-------------------------------------------------
architecture Behavioral of peak_hold is

    signal sig_peak_en  : std_logic          := '0';
    signal sig_peak_val : unsigned(7 downto 0) := (others => '0');

begin

    p_peak : process (clk) is
    begin
        if rising_edge(clk) then
            if rst = '1' then
                sig_peak_en  <= '0';
                sig_peak_val <= (others => '0');
            else
                -- BTNU: toggle peak hold mode
                if btn_mode_i = '1' then
                    sig_peak_en  <= not sig_peak_en;
                    sig_peak_val <= (others => '0');  -- Clear peak on mode change
                end if;

                -- BTND: manually reset peak to current value
                if btn_reset_i = '1' or btn_dn_i = '1' then
                    sig_peak_val <= (others => '0');
                end if;

                -- Update peak if new value is higher
                if valid_i = '1' and sig_peak_en = '1' then
                    if unsigned(level_i) > sig_peak_val then
                        sig_peak_val <= unsigned(level_i);
                    end if;
                end if;
            end if;
        end if;
    end process p_peak;

    -- Output: peak value when active, live value when inactive
    level_o       <= std_logic_vector(sig_peak_val) when sig_peak_en = '1'
                     else level_i;
    peak_active_o <= sig_peak_en;

end architecture Behavioral;

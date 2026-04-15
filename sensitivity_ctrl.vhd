-------------------------------------------------
--! @brief Microphone sensitivity controller
--! @version 1.0
--!
--! Controls the PDM filter window size via buttons.
--! Smaller window = higher sensitivity (reacts more
--! to quiet sounds). Larger window = lower sensitivity.
--!
--! Window range: 32 (most sensitive) to 224 (least),
--! step size 32. Default: 128 (medium).
--!
--! BTNR = increase sensitivity (decrease window)
--! BTNL = decrease sensitivity (increase window)
-------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
-------------------------------------------------
entity sensitivity_ctrl is
    port (
        clk      : in  std_logic;  --! Main clock
        rst      : in  std_logic;  --! High-active synchronous reset
        btn_up_i : in  std_logic;  --! BTNR: increase sensitivity (debounced pulse)
        btn_dn_i : in  std_logic;  --! BTNL: decrease sensitivity (debounced pulse)
        window_o : out std_logic_vector(7 downto 0)  --! Window size for pdm_filter
    );
end entity sensitivity_ctrl;
-------------------------------------------------
architecture Behavioral of sensitivity_ctrl is

    --! Window size: 32 = most sensitive, 224 = least sensitive
    signal sig_window : unsigned(7 downto 0) := to_unsigned(128, 8);

begin

    p_sensitivity : process (clk) is
    begin
        if rising_edge(clk) then
            if rst = '1' then
                sig_window <= to_unsigned(128, 8);  -- Default: medium sensitivity
            else
                -- BTNR: increase sensitivity = smaller window
                if btn_up_i = '1' and sig_window > 32 then
                    sig_window <= sig_window - 32;
                -- BTNL: decrease sensitivity = larger window
                elsif btn_dn_i = '1' and sig_window < 224 then
                    sig_window <= sig_window + 32;
                end if;
            end if;
        end if;
    end process p_sensitivity;

    window_o <= std_logic_vector(sig_window);

end architecture Behavioral;

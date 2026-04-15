-------------------------------------------------
--! @brief PDM decimation filter (accumulator)
--! @version 1.0
--!
--! Counts the number of '1' bits in a window of
--! N PDM samples. The result represents the audio
--! amplitude. Window size is set by sensitivity_ctrl.
--!
--! Output pcm_data_o range: 0 to window_i value
--! pcm_valid_o pulses once per completed window.
-------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
-------------------------------------------------
entity pdm_filter is
    port (
        clk         : in  std_logic;  --! Main clock
        rst         : in  std_logic;  --! High-active synchronous reset
        window_i    : in  std_logic_vector(7 downto 0);  --! Window size from sensitivity_ctrl
        pdm_data_i  : in  std_logic;  --! PDM bit from pdm_driver
        pdm_valid_i : in  std_logic;  --! Valid PDM bit pulse from pdm_driver
        pcm_data_o  : out std_logic_vector(7 downto 0);  --! Amplitude value 0-255
        pcm_valid_o : out std_logic   --! Single-cycle pulse = new amplitude ready
    );
end entity pdm_filter;
-------------------------------------------------
architecture Behavioral of pdm_filter is

    signal sig_acc : unsigned(7 downto 0) := (others => '0');  --! Accumulator
    signal sig_cnt : unsigned(7 downto 0) := (others => '0');  --! Sample counter

begin

    --! Accumulate PDM bits over window, output sum when window complete
    p_filter : process (clk) is
    begin
        if rising_edge(clk) then
            if rst = '1' then
                sig_acc     <= (others => '0');
                sig_cnt     <= (others => '0');
                pcm_data_o  <= (others => '0');
                pcm_valid_o <= '0';
            else
                pcm_valid_o <= '0';  -- Default: no output pulse

                if pdm_valid_i = '1' then
                    -- Window complete: output result and reset
                    if sig_cnt >= unsigned(window_i) - 1 then
                        pcm_data_o  <= std_logic_vector(sig_acc);
                        pcm_valid_o <= '1';
                        sig_cnt     <= (others => '0');
                        -- Start fresh accumulator for next window
                        if pdm_data_i = '1' then
                            sig_acc <= to_unsigned(1, 8);
                        else
                            sig_acc <= (others => '0');
                        end if;
                    -- Still within window: accumulate
                    else
                        if pdm_data_i = '1' then
                            sig_acc <= sig_acc + 1;
                        end if;
                        sig_cnt <= sig_cnt + 1;
                    end if;
                end if;
            end if;
        end if;
    end process p_filter;

end architecture Behavioral;

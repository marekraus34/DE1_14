-------------------------------------------------
--! @brief Debounce module
--! @version 1.0
--! @author Marek Raus
--! @date 2026
--! @copyright MIT license
-------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
-------------------------------------------------
entity debounce is
    generic (
        G_MAX : positive := 200_000  --! Sampling period (200_000 = 2 ms @ 100 MHz)
                                     --! Use 2 for simulation
    );
    port (
        clk   : in  std_logic;  --! Main clock
        rst   : in  std_logic;  --! High-active synchronous reset
        btn_i : in  std_logic;  --! Raw button input
        btn_o : out std_logic   --! Single-cycle pulse on press
    );
end entity debounce;
-------------------------------------------------
architecture Behavioral of debounce is

    signal ce_sample          : std_logic;
    signal shift_reg          : std_logic_vector(3 downto 0) := (others => '0');
    signal sync0, sync1       : std_logic := '0';
    signal debounced, delayed : std_logic := '0';

    component clk_en is
        generic ( G_MAX : positive );
        port (
            clk : in  std_logic;
            rst : in  std_logic;
            ce  : out std_logic
        );
    end component clk_en;

begin

    --! Clock enable instance for sampling period
    clk_en_inst : clk_en
        generic map ( G_MAX => G_MAX )
        port map (
            clk => clk,
            rst => rst,
            ce  => ce_sample
        );

    --! Synchronize, shift-register debounce, edge detect
    p_debounce : process (clk) is
    begin
        if rising_edge(clk) then
            if rst = '1' then
                sync0     <= '0';
                sync1     <= '0';
                shift_reg <= (others => '0');
                debounced <= '0';
                delayed   <= '0';
                btn_o     <= '0';
            else
                -- Two-stage synchronizer
                sync0 <= btn_i;
                sync1 <= sync0;

                -- Shift register sampled at ce_sample rate
                if ce_sample = '1' then
                    shift_reg <= shift_reg(2 downto 0) & sync1;
                end if;

                -- Stable high or low
                if shift_reg = "1111" then
                    debounced <= '1';
                elsif shift_reg = "0000" then
                    debounced <= '0';
                end if;

                -- Rising edge detection -> single pulse
                delayed <= debounced;
                if debounced = '1' and delayed = '0' then
                    btn_o <= '1';
                else
                    btn_o <= '0';
                end if;
            end if;
        end if;
    end process p_debounce;

end architecture Behavioral;

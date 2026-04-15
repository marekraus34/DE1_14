# Audio Visualizer (PDM) – Nexys A7-50T

## Členové týmu

| Jméno | Role |
|---|---|
| Jan Maláč | PDM driver, top-level |
| Peter Rafaelis | PDM filtr, sensitivity_ctrl, testbench |
| Marek Raus | LED bar, peak_hold, dokumentace |

---

## Obsah

- [Cíl projektu](#cíl-projektu)
- [Lab 1: Architecture](#lab-1-architecture)
- [Lab 2: Unit Design](#lab-2-unit-design)
- [Lab 3: Integration](#lab-3-integration)
- [Lab 4: Tuning](#lab-4-tuning)
- [Lab 5: Defense](#lab-5-defense)

---

## Cíl projektu

Cílem projektu je zobrazení intenzity zvukového signálu v reálném čase pomocí 16 LED na desce Nexys A7-50T. Deska obsahuje zabudovaný MEMS mikrofon s PDM (Pulse Density Modulation) rozhraním. FPGA čte 1-bitový PDM datový tok, zpracuje ho decimačním filtrem a výslednou amplitudu zobrazí jako sloupcový VU metr na LED. Uživatel může pomocí tlačítek měnit citlivost a režim zobrazení.

### Základní funkce

- Čtení PDM dat z onboard MEMS mikrofonu
- Decimační filtr (akumulátor) pro převod PDM → amplituda
- Zobrazení hlasitosti na 16x LED jako VU metr
- Nastavitelná citlivost mikrofonu tlačítky BTNL / BTNR
- Režim Peak Hold – LED drží poslední maximum, přepíná BTNU
- Reset peak hodnoty tlačítkem BTND
- Reset celého systému tlačítkem BTNC

### Ovládání tlačítky

| Tlačítko | Pin | Funkce |
|---|---|---|
| **BTNC** | N17 | Reset – výchozí stav (citlivost střední, peak hold vypnutý) |
| **BTNL** | P17 | Snížení citlivosti – reaguje méně na slabé zvuky |
| **BTNR** | M17 | Zvýšení citlivosti – reaguje více na slabé zvuky |
| **BTNU** | M18 | Zapnutí / vypnutí režimu Peak Hold |
| **BTND** | P18 | Ruční reset peak hold hodnoty |

---

## Lab 1: Architecture

### Blokové schéma
```
		               MIC_DATA
        +-------------|-----------------------------------------------------------------------------+
        |	          |   +-------------------------------------------------------------------------|-----> MIC_CLK
        |	         \|/  |									                                        |
        |	    +------------+  +------------+  	          +-----------+  +---------+	        |
 CLK----|	    | pdm_driver |->| pdm_filter |--( pcm_data )->| peak_hold |->| led_bar |------------|-----> LED [15:0]
		|	    +------------+  +------------+  	          +-----------+  +---------+	        |
		|			                  /|\		           	   /|\     /|\			                |
		|			              ( window )		            |	    |			                |
		|			                   |			            |	    |			                |
		|		              +------------------+		        |	    |			                |
		|		              | sensitivity_ctrl |		        |	    |			                |
		|                     +------------------+	           	|	    |			                |
		|			             /|\        /|\		            |	    |			                |
 RST  __|			              |          |		            |	    |			                |
(BTNC)  |      	+------+     +----------+    |			        |	    |			                |
		|	    | BTNL |---->| debounce |    |		          	|	    |			                |
		|	    +------+     +----------+    |		            |	    |			                |
		|     	+------+	           +----------+	          	|	    |			                |
		|     	| BTNR |-------------->| debounce |	           	|     	|			                |
		|     	+------+	           +----------+	          	|	    |			                |
		|     	+------+			                       +----------+ |			                |
		|	    | BTNU |---------------------------------->| debounce | |			                |
      	|	    +------+			                       +----------+ |			                |
      	|     	+------+				                           +----------+			            |
		|	    | BTND |------------------------------------------>| debounce |			            |
      	|     	+------+				                           +----------+			            |
      	+-------------------------------------------------------------------------------------------+
```

### Popis modulů

| Modul | Soubor | Popis |
|---|---|---|
| `clk_en` | `src/clk_en.vhd` | Standardní lab komponenta – hodinový enable |
| `debounce` | `src/debounce.vhd` | Ošetření zákmitů pro všechna tlačítka |
| `pdm_driver` | `src/pdm_driver.vhd` | Generuje clock pro mikrofon (~3.125 MHz), čte PDM data |
| `sensitivity_ctrl` | `src/sensitivity_ctrl.vhd` | Mění velikost okna filtru dle tlačítek BTNL/BTNR |
| `pdm_filter` | `src/pdm_filter.vhd` | Akumulátor – počítá '1' za nastavitelné okno vzorků |
| `peak_hold` | `src/peak_hold.vhd` | Drží maximální hodnotu, přepíná BTNU, resetuje BTND |
| `led_bar` | `src/led_bar.vhd` | Převede amplitudu 0–255 na 0–16 LED, bliká při peak hold |
| `top_level` | `src/top_level.vhd` | Propojení všech modulů |

### Příprava .XDC souboru

| Signál | Pin | Popis |
|---|---|---|
| `clk` | E3 | 100 MHz hlavní hodiny |
| `rst` | N17 | Reset (BTNC) |
| `btn_l_i` | P17 | Snížení citlivosti (BTNL) |
| `btn_r_i` | M17 | Zvýšení citlivosti (BTNR) |
| `btn_u_i` | M18 | Peak Hold on/off (BTNU) |
| `btn_d_i` | P18 | Reset peak hold (BTND) |
| `mic_clk_o` | J5 | Clock do MEMS mikrofonu |
| `mic_data_i` | H5 | PDM data z mikrofonu |
| `mic_lr_sel_o` | F5 | Výběr kanálu (L/R) |
| `led_o[0..15]` | H17..V11 | 16x LED |

---



## Lab 2: Unit Design

### debounce

Ošetřuje zákmity mechanických tlačítek. Vzorkuje vstup každé 2 ms pomocí posuvného registru a propustí stabilní hodnotu jako jednorázový pulz.

#### Porty

| Port | Směr | Typ | Popis |
|---|---|---|---|
| `clk` | in | std_logic | Hlavní hodiny 100 MHz |
| `rst` | in | std_logic | Synchronní reset, active high |
| `btn_i` | in | std_logic | Surový vstup tlačítka |
| `btn_o` | out | std_logic | Ošetřený výstup – 1 pulz na 1 stisk |

#### VHDL kód

```vhdl
library ieee;
  use ieee.std_logic_1164.all;

entity debounce is
    generic (
        G_MAX : positive := 200_000  -- 2 ms @ 100 MHz; pro simulaci použij 2
    );
    port (
        clk   : in  std_logic;
        rst   : in  std_logic;
        btn_i : in  std_logic;
        btn_o : out std_logic
    );
end entity debounce;

architecture Behavioral of debounce is

    signal ce_sample          : std_logic;
    signal shift_reg          : std_logic_vector(3 downto 0) := (others => '0');
    signal sync0, sync1       : std_logic := '0';
    signal debounced, delayed : std_logic := '0';

    component clk_en is
        generic ( G_MAX : positive );
        port ( clk : in std_logic; rst : in std_logic; ce : out std_logic );
    end component;

begin

    clk_en_inst : clk_en
        generic map ( G_MAX => G_MAX )
        port map ( clk => clk, rst => rst, ce => ce_sample );

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
                sync0 <= btn_i;
                sync1 <= sync0;
                if ce_sample = '1' then
                    shift_reg <= shift_reg(2 downto 0) & sync1;
                end if;
                if    shift_reg = "1111" then debounced <= '1';
                elsif shift_reg = "0000" then debounced <= '0';
                end if;
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
```

---

---
zde bude pdm_driver i s vhdl kodem aji porty tam vlozi hanz
---

---
### sensitivity_ctrl

Nastavuje velikost okna filtru. BTNR zvyšuje citlivost (menší okno), BTNL ji snižuje (větší okno). 5 kroků po 32, rozsah 32–224.

#### Porty

| Port | Směr | Typ | Popis |
|---|---|---|---|
| `clk` | in | std_logic | Hlavní hodiny |
| `rst` | in | std_logic | Synchronní reset |
| `btn_up_i` | in | std_logic | BTNR – zvýšení citlivosti |
| `btn_dn_i` | in | std_logic | BTNL – snížení citlivosti |
| `window_o` | out | std_logic_vector(7 downto 0) | Velikost okna (32–224) |

#### VHDL kód

```vhdl
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity sensitivity_ctrl is
    port (
        clk      : in  std_logic;
        rst      : in  std_logic;
        btn_up_i : in  std_logic;
        btn_dn_i : in  std_logic;
        window_o : out std_logic_vector(7 downto 0)
    );
end entity sensitivity_ctrl;

architecture Behavioral of sensitivity_ctrl is

    signal sig_window : unsigned(7 downto 0) := to_unsigned(128, 8);

begin

    p_sensitivity : process (clk) is
    begin
        if rising_edge(clk) then
            if rst = '1' then
                sig_window <= to_unsigned(128, 8);
            else
                if btn_up_i = '1' and sig_window > 32 then
                    sig_window <= sig_window - 32;
                elsif btn_dn_i = '1' and sig_window < 224 then
                    sig_window <= sig_window + 32;
                end if;
            end if;
        end if;
    end process p_sensitivity;

    window_o <= std_logic_vector(sig_window);

end architecture Behavioral;
```

---

### pdm_filter

Akumulátor počítá jedničky za okno N PDM bitů. Velikost okna určuje `sensitivity_ctrl`. Výsledek odpovídá amplitudě signálu.

#### Porty

| Port | Směr | Typ | Popis |
|---|---|---|---|
| `clk` | in | std_logic | Hlavní hodiny |
| `rst` | in | std_logic | Synchronní reset |
| `window_i` | in | std_logic_vector(7 downto 0) | Velikost okna ze sensitivity_ctrl |
| `pdm_data_i` | in | std_logic | PDM bit z driveru |
| `pdm_valid_i` | in | std_logic | Platný PDM bit |
| `pcm_data_o` | out | std_logic_vector(7 downto 0) | Amplituda 0–255 |
| `pcm_valid_o` | out | std_logic | Nová platná hodnota |

#### VHDL kód

```vhdl
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity pdm_filter is
    port (
        clk         : in  std_logic;
        rst         : in  std_logic;
        window_i    : in  std_logic_vector(7 downto 0);
        pdm_data_i  : in  std_logic;
        pdm_valid_i : in  std_logic;
        pcm_data_o  : out std_logic_vector(7 downto 0);
        pcm_valid_o : out std_logic
    );
end entity pdm_filter;

architecture Behavioral of pdm_filter is

    signal sig_acc : unsigned(7 downto 0) := (others => '0');
    signal sig_cnt : unsigned(7 downto 0) := (others => '0');

begin

    p_filter : process (clk) is
    begin
        if rising_edge(clk) then
            if rst = '1' then
                sig_acc     <= (others => '0');
                sig_cnt     <= (others => '0');
                pcm_data_o  <= (others => '0');
                pcm_valid_o <= '0';
            else
                pcm_valid_o <= '0';

                if pdm_valid_i = '1' then
                    if sig_cnt >= unsigned(window_i) - 1 then
                        pcm_data_o  <= std_logic_vector(sig_acc);
                        pcm_valid_o <= '1';
                        sig_cnt     <= (others => '0');
                        if pdm_data_i = '1' then
                            sig_acc <= to_unsigned(1, 8);
                        else
                            sig_acc <= (others => '0');
                        end if;
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
```

#### Simulace (tb_pdm_filter)

<img width="1482" height="830" alt="image" src="https://github.com/user-attachments/assets/0e6ff2f1-5520-4856-bd2f-f80278f6f72d" />

*Obr. 1: Behaviorální simulace modulu pdm_filter. Signál pcm_data postupně nabývá hodnot:
0x00 (ticho), 0x20 (střední hlasitost), 0x3E (hlasitý zvuk) a 0x11 po změně okna na 32 vzorků.*



### peak_hold

Drží maximální hodnotu amplitudy. BTNU přepíná Peak Hold on/off, BTND resetuje maximum na aktuální hodnotu. Při aktivním Peak Hold je `peak_active_o = '1'`.

#### Porty

| Port | Směr | Typ | Popis |
|---|---|---|---|
| `clk` | in | std_logic | Hlavní hodiny |
| `rst` | in | std_logic | Synchronní reset |
| `btn_mode_i` | in | std_logic | BTNU – přepnutí Peak Hold |
| `btn_reset_i` | in | std_logic | BTND – reset peak hodnoty |
| `level_i` | in | std_logic_vector(7 downto 0) | Aktuální amplituda |
| `valid_i` | in | std_logic | Nová platná hodnota |
| `level_o` | out | std_logic_vector(7 downto 0) | Výstup (peak nebo přímá hodnota) |
| `peak_active_o` | out | std_logic | '1' = Peak Hold je zapnutý |

#### VHDL kód

```vhdl
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity peak_hold is
    port (
        clk           : in  std_logic;
        rst           : in  std_logic;
        btn_mode_i    : in  std_logic;
        btn_reset_i   : in  std_logic;
        level_i       : in  std_logic_vector(7 downto 0);
        valid_i       : in  std_logic;
        level_o       : out std_logic_vector(7 downto 0);
        peak_active_o : out std_logic
    );
end entity peak_hold;

architecture Behavioral of peak_hold is

    signal sig_peak_en  : std_logic            := '0';
    signal sig_peak_val : unsigned(7 downto 0) := (others => '0');

begin

    p_peak : process (clk) is
    begin
        if rising_edge(clk) then
            if rst = '1' then
                sig_peak_en  <= '0';
                sig_peak_val <= (others => '0');
            else
                if btn_mode_i = '1' then
                    sig_peak_en  <= not sig_peak_en;
                    sig_peak_val <= (others => '0');
                end if;

                if btn_reset_i = '1' then
                    sig_peak_val <= unsigned(level_i);
                end if;

                if valid_i = '1' and sig_peak_en = '1' then
                    if unsigned(level_i) > sig_peak_val then
                        sig_peak_val <= unsigned(level_i);
                    end if;
                end if;
            end if;
        end if;
    end process p_peak;

    level_o       <= std_logic_vector(sig_peak_val) when sig_peak_en = '1'
                     else level_i;
    peak_active_o <= sig_peak_en;

end architecture Behavioral;
```

---

### led_bar

Převede amplitudu (0–255) na počet rozsvícených LED (0–16). Při aktivním Peak Hold bliká nejvyšší rozsvícená LED (~6 Hz) jako vizuální indikace.

#### Porty

| Port | Směr | Typ | Popis |
|---|---|---|---|
| `clk` | in | std_logic | Hlavní hodiny |
| `rst` | in | std_logic | Synchronní reset |
| `level_i` | in | std_logic_vector(7 downto 0) | Amplituda 0–255 |
| `valid_i` | in | std_logic | Nová platná hodnota |
| `peak_active_i` | in | std_logic | Peak Hold aktivní |
| `led_o` | out | std_logic_vector(15 downto 0) | 16 LED výstupů |

#### VHDL kód

```vhdl
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity led_bar is
    port (
        clk           : in  std_logic;
        rst           : in  std_logic;
        level_i       : in  std_logic_vector(7 downto 0);
        valid_i       : in  std_logic;
        peak_active_i : in  std_logic;
        led_o         : out std_logic_vector(15 downto 0)
    );
end entity led_bar;

architecture Behavioral of led_bar is

    signal sig_level     : integer range 0 to 16 := 0;
    signal sig_blink_cnt : unsigned(23 downto 0) := (others => '0');
    signal sig_blink     : std_logic := '0';

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

    p_led : process (clk) is
    begin
        if rising_edge(clk) then
            if rst = '1' then
                led_o <= (others => '0');
            elsif valid_i = '1' then
                led_o <= (others => '0');
                for i in 0 to 15 loop
                    if i < sig_level then
                        led_o(i) <= '1';
                    elsif i = sig_level and peak_active_i = '1' then
                        led_o(i) <= sig_blink;
                    end if;
                end loop;
            end if;
        end if;
    end process p_led;

end architecture Behavioral;
```

---

## Lab 3: Integration

*Bude doplněno – top_level.vhd, syntéza, testování na HW.*

---

## Lab 4: Tuning

*Bude doplněno – ladění, optimalizace.*

---

## Lab 5: Defense

*Bude doplněno – video, poster, resource report.*

### Resource Report (po syntéze)

| Resource | Used | Available | Utilization |
|---|---|---|---|
| LUT | – | 20800 | – |
| FF | – | 41600 | – |
| BRAM | – | 50 | – |
| IO | – | 210 | – |

---

## Reference

- [Nexys A7 Reference Manual](https://digilent.com/reference/programmable-logic/nexys-a7/reference-manual)
- [PDM Microphone Datasheet – SPH0641LU4H-1](https://www.knowles.com/docs/default-source/default-document-library/sph0641lu4h-1-datasheet.pdf)
- [tomas-fryza/vhdl-examples](https://github.com/tomas-fryza/vhdl-examples)
- Vivado 2025.2
- [draw.io](https://draw.io) – blokové schéma

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
- CLK (hodinový signál) a RST (reset) vstupují do celého systému
- pdm_driver generuje hodinový signál pro mikrofon (MIC_CLK), čte datový signál z mikrofonu (MIC_DATA) a vytváří signály pdm_data (hustota jedniček) a pdm_valid (0/1), které posílá do pdm_filter
- převádí pdm_data (hustotu jedniček) na pcm_data (číselnou hodnotu), přičemž přičemž používá parametr window pro nastavení citlivosti
- peak_hold zpracovává hodnotu signálu pcm_data (číselnou hodnotu) a podle toho jestli je v aktivním režimu (drží maximální úroveň signálu) nebo neaktivním režimu (LED ukazují aktuální úroveň signálu)
- led_bar zobrazuje úroveň signálu pomocí LED na výstupu LED[15:0]
- debounce filtruje vstupy tlačítek a zamezuje zákmitům
- BTNL a BTNR vstupují přes debounce do sensitivity_ctrl (kontrola sensitivity), nastavují velikost okna (window) a díky tomu mění citlivost mikrofonu
- BTNU vstupuje přes debounce do peak_hold a přemíná režim mezi 0 (vypnuto) a zapnuto (1)
- BTND vstupuje přes debounce také do peak_hold a slouží jako reset držené maximální hodnoty

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

[debounce.vhd](debounce.vhd)

#### Simulace (tb_debounce)

<img width="1482" height="830" alt="image" src="https://github.com/marekraus34/DE1_14/blob/main/debouncer_tb_sim.png?raw=true" />

*Obr. 1: Behaviorální simulace modulu debounce. Signál btn_i obsahuje 
zákmity – rychlé krátké pulzy simulující mechanické poskakování tlačítka. 
Modul tyto zákmity filtruje a na výstupu btn_o propustí jediný čistý 
pulz až poté, co je vstup stabilní po dobu 4 vzorkovacích period. 
Zákmity uprostřed průběhu (kolem 300–500 ns) jsou potlačeny, 
výstup btn_o reaguje až na stabilní stisk kolem 700 ns.*

---
### pdm_driver

Generuje hodinový signál pro mikrofon a synchronně s ním vzorkuje jeho 1 bitový PDM výstup, přičemž označuje každý nový platný vzorek signálem pdm_valid.

### Porty
| Port           | Směr | Typ       | Popis                                  |
|----------------|------|-----------|----------------------------------------|
| `clk`          | in   | std_logic | Hlavní hodinový signál 100 MHz         |
| `rst`          | in   | std_logic | Synchronní reset, active high          |
| `mic_clk_o`    | out  | std_logic | Hodinový signál pro mikrofon           |
| `mic_lr_sel_o` | out  | std_logic | Výběr kanálu mikrofonu (0 = levý)      |
| `mic_data_i`   | in   | std_logic | Datový vstup z mikrofonu (PDM)         |
| `pdm_data_o`   | out  | std_logic | Vzorkovaný PDM bit                     |
| `pdm_valid_o`  | out  | std_logic | Platnost vzorku (1 takt = nový vzorek) |

#### VHDL kód

[pdm_driver.vhd](pdm_driver.vhd)

#### Simulace (tb_pdm_driver)

<img width="1482" height="830" alt="image" src="https://github.com/marekraus34/DE1_14/blob/main/pdm_driver_tb_sim.png?raw=true" />

*Obr. 2: Behaviorální simulace modulu pdm_driver. Po resetu začne 
mic_clk_o generovat hodinový signál pro mikrofon (100 MHz / 32 = 3.125 MHz). 
Signál pdm_valid_o pulzuje vždy na náběžné hraně mic_clk_o a indikuje 
nový platný PDM vzorek. Signál pdm_data_o kopíruje hodnotu mic_data_i 
v okamžiku vzorkování.*

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

[sensitivity_ctrl.vhd](sensitivity_ctrl.vhd)

#### Simulace (tb_sensitivity_ctrl)

<img width="1482" height="830" alt="image" src="https://github.com/marekraus34/DE1_14/blob/main/sens_ctrl_tb_sim.png?raw=true" />

*Obr. 3: Behaviorální simulace modulu sensitivity_ctrl. Po resetu je 
výchozí hodnota okna window_o = 0x80 (128, střední citlivost). 
Po stisku btn_up_i (BTNR) se okno zmenší na 0x60 (96, vyšší citlivost). 
Po stisku btn_dn_i (BTNL) se okno vrátí zpět na 0x80 (128).*

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

[pdm_filter.vhd](pdm_filter.vhd)

#### Simulace (tb_pdm_filter)

<img width="1482" height="830" alt="image" src="https://github.com/user-attachments/assets/0e6ff2f1-5520-4856-bd2f-f80278f6f72d" />

*Obr. 4: Behaviorální simulace modulu pdm_filter. Signál pcm_data postupně nabývá hodnot:
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

[peak_hold.vhd](peak_hold.vhd)

### led_bar

Převede amplitudu (0–255) na počet rozsvícených LED (0–16). 
V normálním režimu LED okamžitě vyskočí na aktuální úroveň 
a poté pomalu klesají (decay efekt). Při aktivním Peak Hold 
(BTNU) drží maximum bez decay a nejvyšší rozsvícená LED 
bliká ~6 Hz jako vizuální indikace.

#### Porty

| Port | Směr | Typ | Popis |
|---|---|---|---|
| `clk` | in | std_logic | Hlavní hodiny |
| `rst` | in | std_logic | Synchronní reset |
| `level_i` | in | std_logic_vector(7 downto 0) | Amplituda 0–255 |
| `valid_i` | in | std_logic | Nová platná hodnota |
| `peak_active_i` | in | std_logic | Peak Hold aktivní (BTNU) |
| `led_o` | out | std_logic_vector(15 downto 0) | 16 LED výstupů |

#### Generics

| Generic | Výchozí hodnota | Popis |
|---|---|---|
| `C_DECAY_TIME` | 12_500_000 | Počet taktů mezi každým krokem poklesu (125 ms @ 100 MHz) |

#### Chování

| Režim | Popis |
|---|---|
| Peak Hold vypnutý | LED skočí nahoru okamžitě, pak každých 125 ms klesnou o jednu |
| Peak Hold zapnutý | LED drží maximum, nejvyšší bliká ~6 Hz |

#### VHDL kód

[led_bar.vhd](led_bar.vhd)

#### Simulace (tb_led_bar)

<img width="1482" height="830" alt="image" src="https://github.com/marekraus34/DE1_14/blob/main/led_bar_tb_sim.png?raw=true" />

*Obr. 5: Behaviorální simulace modulu led_bar. 
Signál level_i postupně nabývá hodnot 0x00 (ticho → led_o = 0x0000), 
0x0A (nízká úroveň → led_o = 0x0000, pod prahem) a 0xC8 
(vysoká úroveň → led_o = 0x0FFF, rozsvíceno 12 LED). 
Signál valid_i pulzuje při každé nové platné hodnotě amplitudy.*

---

## Lab 3: Integration

### top_level

Propojuje všechny moduly systému (mikrofon, zpracování signálu, tlačítka a LED výstup) do jednoho celku a zajišťuje tok dat od vstupu MIC až po zobrazení na LED.

#### Porty

| Port            | Směr | Typ                           | Popis                                             |
|-----------------|------|-------------------------------|---------------------------------------------------|
| `clk`           | in   | std_logic                     | Hlavní hodinový signál (100 MHz)                  |
| `rst`           | in   | std_logic                     | Synchronní reset (active high)                    |
| `btn_l_i`       | in   | std_logic                     | Vstup tlačítka vlevo (snížení citlivosti)         |
| `btn_r_i`       | in   | std_logic                     | Vstup tlačítka vpravo (zvýšení citlivosti)        |
| `btn_u_i`       | in   | std_logic                     | Vstup tlačítka nahoru (zapnutí/vypnutí peak hold) |
| `btn_d_i`       | in   | std_logic                     | Vstup tlačítka dolů (reset peak hodnoty)          |
| `mic_data_i`    | in   | std_logic                     | Datový signál z PDM mikrofonu                     |
| `mic_clk_o`     | out  | std_logic                     | Hodinový signál pro mikrofon                      |
| `mic_lr_sel_o`  | out  | std_logic                     | Výběr kanálu mikrofonu (0 = levý)                 |
| `led_o`         | out  | std_logic_vector(15 downto 0) | Výstup pro 16 LED (VU metr)                       |

#### VHDL

[top_level.vhd](top_level.vhd)

#### Simulace (tb_top_level)

<img width="1482" height="830" alt="image" src="https://github.com/marekraus34/DE1_14/blob/main/top_level_tb.png?raw=true" />

*Obr. 5: Behaviorální simulace modulu top_level. Po resetu (rst = '1' 
do ~100 ns) se systém inicializuje – window_o = 0x80 (střední citlivost), 
pcm_data = 0x00, level = 0x00, led_o = 0x0000. Od ~200 ns je přiveden 
mic_data_i = '1' (simulace hlasitého zvuku) a mic_clk_o začne generovat 
hodinový signál pro mikrofon. Signál mic_lr_sel_o = '0' potvrzuje 
výběr levého kanálu. Simulace ověřuje správné propojení všech modulů 
v top_level entitě.*

---

### Testování na hardware (Nexys A7-50T)

#### Syntéza
- Syntéza proběhla bez chyb
- Implementace proběhla bez chyb
- Bitstream byl úspěšně nahrán do desky

#### Funkční testy na desce

| Test | Popis | Výsledek |
|---|---|---|
| Základní VU metr | Mluvení do mikrofonu rozsvítí LED | ✅ |
| BTNL/BTNR | Změna citlivosti mikrofonu | ✅ |
| BTNU | Zapnutí/vypnutí Peak Hold | ✅ |
| BTND | Reset peak hodnoty | ✅ |
| BTNC | Reset celého systému | ✅ |
| Decay efekt | LED pomalu klesají po odeznění zvuku | ✅ |

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
- [Vivado 2025.2](https://www.amd.com/en/products/software/adaptive-socs-and-fpgas/vivado.html)


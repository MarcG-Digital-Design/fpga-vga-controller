library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Top-level for Intel DE10-Lite (MAX10).
-- Derives a 25 MHz pixel clock from the 50 MHz board oscillator via PLL,
-- reads pixel data from the image ROM and drives the on-board VGA DAC.
entity top is
    port (
        clk_50      : in  std_logic;                     -- 50 MHz board clock
        rst_n       : in  std_logic;                     -- Active-low reset (KEY0)
        vga_r       : out std_logic_vector(3 downto 0);
        vga_g       : out std_logic_vector(3 downto 0);
        vga_b       : out std_logic_vector(3 downto 0);
        vga_hsync   : out std_logic;
        vga_vsync   : out std_logic
    );
end entity top;

architecture rtl of top is

    -- Image dimensions and centering offset on the 640x480 display
    constant IMG_W  : integer := 256;
    constant IMG_H  : integer := 256;
    constant H_OFF  : integer := (640 - IMG_W) / 2;  -- 192
    constant V_OFF  : integer := (480 - IMG_H) / 2;  -- 112

    signal clk_25   : std_logic;
    signal pll_lock : std_logic;
    signal rst      : std_logic;

    signal hsync_s, vsync_s, display_en_s : std_logic;
    signal h_cnt, v_cnt : unsigned(9 downto 0);

    signal rom_addr : std_logic_vector(15 downto 0);
    signal rom_data : std_logic_vector(11 downto 0);

    signal in_image : std_logic;

    component pll_25mhz is
        port (
            inclk0 : in  std_logic;
            c0     : out std_logic;
            locked : out std_logic
        );
    end component;

begin

    rst <= not rst_n or not pll_lock;

    u_pll : pll_25mhz
        port map (inclk0 => clk_50, c0 => clk_25, locked => pll_lock);

    u_timing : entity work.vga_timing
        port map (
            clk_25     => clk_25,
            rst        => rst,
            hsync      => hsync_s,
            vsync      => vsync_s,
            display_en => display_en_s,
            h_count    => h_cnt,
            v_count    => v_cnt
        );

    -- Build ROM address from pixel position relative to image origin
    in_image <= '1' when (h_cnt >= H_OFF) and (h_cnt < H_OFF + IMG_W) and
                         (v_cnt >= V_OFF) and (v_cnt < V_OFF + IMG_H) else '0';

    rom_addr <= std_logic_vector(
                    resize(v_cnt - V_OFF, 8) & std_logic_vector(resize(h_cnt - H_OFF, 8))
                ) when in_image = '1' else (others => '0');

    u_rom : entity work.image_rom
        port map (clk => clk_25, addr => rom_addr, data => rom_data);

    -- Output: pixel colour inside the image window, black elsewhere
    process(clk_25)
    begin
        if rising_edge(clk_25) then
            vga_hsync <= hsync_s;
            vga_vsync <= vsync_s;
            if display_en_s = '1' and in_image = '1' then
                vga_r <= rom_data(11 downto 8);
                vga_g <= rom_data(7  downto 4);
                vga_b <= rom_data(3  downto 0);
            else
                vga_r <= (others => '0');
                vga_g <= (others => '0');
                vga_b <= (others => '0');
            end if;
        end if;
    end process;

end architecture rtl;

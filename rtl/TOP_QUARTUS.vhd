library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Synthesis-level wrapper around VGA_DISPLAY_RAM.
-- Adds the two pieces that live OUTSIDE VGA_DISPLAY_RAM in our design :
--   * clk_divider : 50 MHz oscillator -> 25 MHz pixel clock
--   * image_ram   : inferred ROM initialized from a .mif file
--
-- This is the entity that gets pinned to the DE10-Lite and programmed
-- onto the FPGA. Its ports match the physical pins of the board.
--
-- DE10-Lite pin mapping (to be set in the .qsf file) :
--   MAX10_CLK1_50 -> P11   (50 MHz oscillator)
--   KEY[0]        -> B8    (push button, active low -> wired to nRST)
--   VGA_R[3..0]   -> A9, B10, C9, A5
--   VGA_G[3..0]   -> L7, K7, J7, J8
--   VGA_B[3..0]   -> B6, B7, A7, A8
--   VGA_HS        -> N3
--   VGA_VS        -> N1
entity TOP_QUARTUS is
    Port (
        MAX10_CLK1_50 : in  STD_LOGIC;
        KEY0          : in  STD_LOGIC;
        VGA_R         : out STD_LOGIC_VECTOR(3 downto 0);
        VGA_G         : out STD_LOGIC_VECTOR(3 downto 0);
        VGA_B         : out STD_LOGIC_VECTOR(3 downto 0);
        VGA_HS        : out STD_LOGIC;
        VGA_VS        : out STD_LOGIC
    );
end TOP_QUARTUS;

architecture rtl of TOP_QUARTUS is

    -- ---------------------------------------------------------------------
    -- Component declarations
    -- ---------------------------------------------------------------------
    component clk_divider
        Port (
            CLK_50 : in  STD_LOGIC;
            CLK_25 : out STD_LOGIC
        );
    end component;

    component image_ram
        generic (
            ADDR_BITS : integer := 16;
            DATA_BITS : integer := 12;
            INIT_FILE : string  := "PERROQUET.mif"
        );
        Port (
            clock   : in  STD_LOGIC;
            address : in  STD_LOGIC_VECTOR(ADDR_BITS - 1 downto 0);
            q       : out STD_LOGIC_VECTOR(DATA_BITS - 1 downto 0)
        );
    end component;

    component VGA_DISPLAY_RAM
        generic (
            IMG_WIDTH  : integer := 256;
            IMG_HEIGHT : integer := 256;
            ADDR_BITS  : integer := 16
        );
        Port (
            CLK_25MHZ : in  STD_LOGIC;
            nRST      : in  STD_LOGIC;
            RAM_ADDR  : out STD_LOGIC_VECTOR(ADDR_BITS - 1 downto 0);
            RAM_DATA  : in  STD_LOGIC_VECTOR(11 downto 0);
            VGA_R     : out STD_LOGIC_VECTOR(3 downto 0);
            VGA_G     : out STD_LOGIC_VECTOR(3 downto 0);
            VGA_B     : out STD_LOGIC_VECTOR(3 downto 0);
            VGA_HS    : out STD_LOGIC;
            VGA_VS    : out STD_LOGIC
        );
    end component;

    -- ---------------------------------------------------------------------
    -- Internal signals
    -- ---------------------------------------------------------------------
    signal clk_25mhz : STD_LOGIC;
    signal ram_addr  : STD_LOGIC_VECTOR(15 downto 0);
    signal ram_data  : STD_LOGIC_VECTOR(11 downto 0);

begin

    -- 50 MHz -> 25 MHz pixel clock
    div_inst : clk_divider
        port map (
            CLK_50 => MAX10_CLK1_50,
            CLK_25 => clk_25mhz
        );

    -- Image ROM, initialized from PERROQUET.mif at synthesis time
    rom_inst : image_ram
        generic map (
            ADDR_BITS => 16,
            DATA_BITS => 12,
            INIT_FILE => "PERROQUET.mif"
        )
        port map (
            clock   => clk_25mhz,
            address => ram_addr,
            q       => ram_data
        );

    -- Main VGA controller core (already simulated and validated)
    -- KEY0 on the DE10-Lite is active low : nothing pressed -> '1' -> no
    -- reset ; pressed -> '0' -> reset asserted. This matches the nRST
    -- convention used inside VGA_DISPLAY_RAM, so KEY0 is wired directly.
    vga_inst : VGA_DISPLAY_RAM
        generic map (
            IMG_WIDTH  => 256,
            IMG_HEIGHT => 256,
            ADDR_BITS  => 16
        )
        port map (
            CLK_25MHZ => clk_25mhz,
            nRST      => KEY0,
            RAM_ADDR  => ram_addr,
            RAM_DATA  => ram_data,
            VGA_R     => VGA_R,
            VGA_G     => VGA_G,
            VGA_B     => VGA_B,
            VGA_HS    => VGA_HS,
            VGA_VS    => VGA_VS
        );

end rtl;

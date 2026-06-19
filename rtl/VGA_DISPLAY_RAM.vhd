library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Top-level of the VGA display.
-- Wires together the 6 building blocks:
--   HSYNC_COUNT, VSYNC_COUNT, COMPARATOR_HSYNC, COMPARATOR_VSYNC,
--   COMPARATOR_TDISP, RGB_OUTPUT.
-- The RAM is intentionally external and exposed through the RAM_ADDR /
-- RAM_DATA ports so it can be mocked in simulation and replaced by an
-- altsyncram IP in Quartus.
-- The PLL (50 MHz -> 25 MHz) is also external (handled in a Quartus
-- wrapper) so this module takes a 25 MHz clock directly.
entity VGA_DISPLAY_RAM is
    generic (
            IMG_WIDTH  : integer := 256;
            IMG_HEIGHT : integer := 256;
            ADDR_BITS  : integer := 16
    );
    Port (
            CLK_25MHZ : in  STD_LOGIC;
            nRST      : in  STD_LOGIC;
            -- RAM interface (RAM lives outside this module)
            RAM_ADDR  : out STD_LOGIC_VECTOR(ADDR_BITS - 1 downto 0);
            RAM_DATA  : in  STD_LOGIC_VECTOR(11 downto 0);
            -- VGA outputs
            VGA_R     : out STD_LOGIC_VECTOR(3 downto 0);
            VGA_G     : out STD_LOGIC_VECTOR(3 downto 0);
            VGA_B     : out STD_LOGIC_VECTOR(3 downto 0);
            VGA_HS    : out STD_LOGIC;
            VGA_VS    : out STD_LOGIC
    );
end VGA_DISPLAY_RAM;

architecture Behavioral of VGA_DISPLAY_RAM is
    --TODO :  declare components (HSYNC_COUNT, VSYNC_COUNT,
    --         COMPARATOR_HSYNC, COMPARATOR_VSYNC, COMPARATOR_TDISP,
    --         RGB_OUTPUT)


    component HSYNC_COUNT is
        port(        
            CLK              : in  STD_LOGIC;
            nRST             : in  STD_LOGIC;
            HCOUNT_OVERFLOW  : out  STD_LOGIC;
            HCOUNTER_VALUE   : out STD_LOGIC_VECTOR(9 downto 0)
        );
    end component;

    component VSYNC_COUNT is
        port(        
            CLK              : in  STD_LOGIC;
            nRST             : in  STD_LOGIC;
            HCOUNT_OVERFLOW  : in  STD_LOGIC;
            VCOUNTER_VALUE   : out STD_LOGIC_VECTOR(9 downto 0)
        );
    end component;

    component COMPARATOR_HSYNC is
        port(        
            CLK              : in  STD_LOGIC;
            nRST             : in  STD_LOGIC;
            HCOUNTER_VALUE   : in  STD_LOGIC_VECTOR(9 downto 0);
            H_SYNC           : out STD_LOGIC
        );
    end component;

    component COMPARATOR_VSYNC is
        port(
            CLK              : in  STD_LOGIC;
            nRST             : in  STD_LOGIC;
            VCOUNTER_VALUE   : in  STD_LOGIC_VECTOR(9 downto 0);
            V_SYNC           : out STD_LOGIC
        );
    end component;

    component COMPARATOR_TDISP is
        port(
            CLK              : in  STD_LOGIC;
            nRST             : in  STD_LOGIC;
            HCOUNTER_VALUE   : in  STD_LOGIC_VECTOR(9 downto 0);
            VCOUNTER_VALUE   : in  STD_LOGIC_VECTOR(9 downto 0);
            DISPLAY_SIGNAL   : out STD_LOGIC
        );
    end component;


    component RGB_OUTPUT is
        generic(
            IMG_WIDTH  : integer := 256;  -- img  size
            IMG_HEIGHT : integer := 256; -- img  size
            ADDR_BITS  : integer := 16
        );

        Port (
            CLK              : in  STD_LOGIC;
            nRST             : in  STD_LOGIC;
            DISPLAY_SIGNAL   : in  STD_LOGIC;
            HCOUNTER_VALUE   : in  STD_LOGIC_VECTOR(9 downto 0);
            VCOUNTER_VALUE   : in  STD_LOGIC_VECTOR(9 downto 0);
            DATA             : in  STD_LOGIC_VECTOR(11 downto 0);
            ADDRESS          : out  STD_LOGIC_VECTOR(ADDR_BITS - 1 downto 0);
            VGA_R            : out  STD_LOGIC_VECTOR(3 downto 0);
            VGA_G            : out  STD_LOGIC_VECTOR(3 downto 0);
            VGA_B            : out  STD_LOGIC_VECTOR(3 downto 0)
            );
    end component;

    -- TODO : declare internal signals
    signal s_DISPLAY_SIGNAL  : STD_LOGIC;
    signal s_HCOUNTER_VALUE  : STD_LOGIC_VECTOR(9 downto 0);
    signal s_VCOUNTER_VALUE  : STD_LOGIC_VECTOR(9 downto 0);
    signal s_HCOUNT_OVERFLOW : STD_LOGIC;
    

begin

    -- Instantiate each component and wire them with internal signals
    component1 : HSYNC_COUNT
        port map(
            CLK             => CLK_25MHZ,
            nRST            => nRST,
            HCOUNT_OVERFLOW => s_HCOUNT_OVERFLOW,
            HCOUNTER_VALUE  => s_HCOUNTER_VALUE
        );

    -- Fixed syntax and correct routing for VCOUNTER_VALUE
    component2 : VSYNC_COUNT 
        port map(
            CLK             => CLK_25MHZ,
            nRST            => nRST,
            HCOUNT_OVERFLOW => s_HCOUNT_OVERFLOW,
            VCOUNTER_VALUE  => s_VCOUNTER_VALUE
        );

    component3 : COMPARATOR_HSYNC 
        port map(
            CLK             => CLK_25MHZ,
            nRST            => nRST,
            HCOUNTER_VALUE  => s_HCOUNTER_VALUE,
            H_SYNC          => VGA_HS
        );

    component4 : COMPARATOR_VSYNC 
        port map(
            CLK             => CLK_25MHZ,
            nRST            => nRST,
            VCOUNTER_VALUE  => s_VCOUNTER_VALUE,
            V_SYNC          => VGA_VS
        );

    component5 : COMPARATOR_TDISP 
        port map(
            CLK             => CLK_25MHZ,
            nRST            => nRST,
            HCOUNTER_VALUE  => s_HCOUNTER_VALUE,
            VCOUNTER_VALUE  => s_VCOUNTER_VALUE,
            DISPLAY_SIGNAL  => s_DISPLAY_SIGNAL
        );

    -- RGB_OUTPUT generics are forwarded from the top-level generics
    component6 : RGB_OUTPUT
        generic map (
            IMG_WIDTH  => IMG_WIDTH,
            IMG_HEIGHT => IMG_HEIGHT,
            ADDR_BITS  => ADDR_BITS
        )
        port map(
            CLK             => CLK_25MHZ,
            nRST            => nRST,
            DISPLAY_SIGNAL  => s_DISPLAY_SIGNAL,
            HCOUNTER_VALUE  => s_HCOUNTER_VALUE,
            VCOUNTER_VALUE  => s_VCOUNTER_VALUE,
            DATA            => RAM_DATA,
            address         => RAM_ADDR,
            VGA_R           => VGA_R,
            VGA_G           => VGA_G,
            VGA_B           => VGA_B
        );
end Behavioral;

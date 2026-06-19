library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

-- Self-checking testbench for RGB_OUTPUT.
-- The DUT is instantiated with a small 4x4 image so the testbench can
-- mock the RAM with a 16-entry constant array (TEST_RAM) and predict
-- the VGA output for each pixel.
-- Five phases:
--   1) Reset asserted          -> VGA stays at 0 even inside the image
--   2) Reset released
--   3) DISPLAY = '0' (blanking) -> VGA forced to 0 even inside the image
--   4) DISPLAY = '1' outside image zone -> VGA = 0
--   5) DISPLAY = '1' inside image -> VGA reflects the TEST_RAM content
--
-- Latency note : the DUT registers ADDRESS at cycle N+1 and VGA at cycle N+2
-- after H,V are set. The check_pixel procedure waits 2 clock edges to read
-- the final VGA value.
entity RGB_OUTPUT_selfcheck_tb is
end RGB_OUTPUT_selfcheck_tb;


architecture sim of RGB_OUTPUT_selfcheck_tb is

    -- ---------------------------------------------------------------------
    -- DUT declaration
    -- ---------------------------------------------------------------------
    component RGB_OUTPUT
        generic (
            IMG_WIDTH  : integer := 256;
            IMG_HEIGHT : integer := 256;
            ADDR_BITS  : integer := 16
        );
        Port (
            CLK              : in  STD_LOGIC;
            nRST             : in  STD_LOGIC;
            DISPLAY_SIGNAL   : in  STD_LOGIC;
            HCOUNTER_VALUE   : in  STD_LOGIC_VECTOR(9 downto 0);
            VCOUNTER_VALUE   : in  STD_LOGIC_VECTOR(9 downto 0);
            DATA             : in  STD_LOGIC_VECTOR(11 downto 0);
            ADDRESS          : out STD_LOGIC_VECTOR(ADDR_BITS - 1 downto 0);
            VGA_R            : out STD_LOGIC_VECTOR(3 downto 0);
            VGA_G            : out STD_LOGIC_VECTOR(3 downto 0);
            VGA_B            : out STD_LOGIC_VECTOR(3 downto 0)
        );
    end component;

    -- ---------------------------------------------------------------------
    -- Constants (declared before signals so they can be used in port widths)
    -- ---------------------------------------------------------------------
    constant CLK_PERIOD : time    := 40 ns;   -- 25 MHz pixel clock
    constant TEST_W     : integer := 4;       -- mock image width
    constant TEST_H     : integer := 4;       -- mock image height
    constant ADDR_W     : integer := 4;       -- log2(TEST_W * TEST_H) = 4 bits

    -- ---------------------------------------------------------------------
    -- Signals wired to the DUT
    -- ---------------------------------------------------------------------
    signal CLK             : STD_LOGIC := '0';
    signal nRST            : STD_LOGIC := '0';   -- active low, asserted at start
    signal HCOUNTER_VALUE  : STD_LOGIC_VECTOR(9 downto 0);
    signal VCOUNTER_VALUE  : STD_LOGIC_VECTOR(9 downto 0);
    signal DISPLAY_SIGNAL  : STD_LOGIC;
    signal DATA            : STD_LOGIC_VECTOR(11 downto 0) := (others => '0');
    signal ADDRESS         : STD_LOGIC_VECTOR(ADDR_W - 1 downto 0);
    signal VGA_R           : STD_LOGIC_VECTOR(3 downto 0);
    signal VGA_G           : STD_LOGIC_VECTOR(3 downto 0);
    signal VGA_B           : STD_LOGIC_VECTOR(3 downto 0);

    signal sim_done : boolean := false;

    -- ---------------------------------------------------------------------
    -- Mock RAM : 4x4 image preloaded with a recognizable pattern
    -- Each entry encodes the row/column so the expected VGA output is
    -- trivial to predict from the pixel coordinates.
    -- ---------------------------------------------------------------------
    type ram_t is array (0 to TEST_W * TEST_H - 1) of STD_LOGIC_VECTOR(11 downto 0);

    constant TEST_RAM : ram_t := (
        0  => x"100", 1  => x"200", 2  => x"300", 3  => x"400",  -- row 0
        4  => x"500", 5  => x"600", 6  => x"700", 7  => x"800",  -- row 1
        8  => x"900", 9  => x"A00", 10 => x"B00", 11 => x"C00",  -- row 2
        12 => x"D00", 13 => x"E00", 14 => x"F00", 15 => x"FFF"   -- row 3
    );

    -- ---------------------------------------------------------------------
    -- Checking procedure : drive H,V,DISPLAY, wait for the DUT latency,
    -- then compare VGA_R/G/B against the expected values.
    -- ---------------------------------------------------------------------
    procedure check_pixel(
        h : integer; v : integer; disp : STD_LOGIC;
        exp_r : integer; exp_g : integer; exp_b : integer;
        tag : string
    ) is
    begin
        HCOUNTER_VALUE <= std_logic_vector(to_unsigned(h, 10));
        VCOUNTER_VALUE <= std_logic_vector(to_unsigned(v, 10));
        DISPLAY_SIGNAL <= disp;

        -- Latency : 2 cycles for VGA to reflect the new DATA
        wait until rising_edge(CLK);   -- cycle 1 : DUT computes ADDRESS
        wait until rising_edge(CLK);   -- cycle 2 : DATA propagates to VGA
        wait for 1 ns;

        assert to_integer(unsigned(VGA_R)) = exp_r
            report "VGA_R FAIL [" & tag & "] expected " &
                   integer'image(exp_r) & " got " &
                   integer'image(to_integer(unsigned(VGA_R)))
            severity failure;

        assert to_integer(unsigned(VGA_G)) = exp_g
            report "VGA_G FAIL [" & tag & "] expected " &
                   integer'image(exp_g) & " got " &
                   integer'image(to_integer(unsigned(VGA_G)))
            severity failure;

        assert to_integer(unsigned(VGA_B)) = exp_b
            report "VGA_B FAIL [" & tag & "] expected " &
                   integer'image(exp_b) & " got " &
                   integer'image(to_integer(unsigned(VGA_B)))
            severity failure;
    end procedure;

begin

    -- Mock RAM : combinational read, DATA tracks ADDRESS with no delay
    DATA <= TEST_RAM(to_integer(unsigned(ADDRESS)));

    -- DUT instance configured for the 4x4 mock image
    DUT : RGB_OUTPUT
        generic map (
            IMG_WIDTH  => TEST_W,
            IMG_HEIGHT => TEST_H,
            ADDR_BITS  => ADDR_W
        )
        port map (
            CLK             => CLK,
            nRST            => nRST,
            HCOUNTER_VALUE  => HCOUNTER_VALUE,
            VCOUNTER_VALUE  => VCOUNTER_VALUE,
            DISPLAY_SIGNAL  => DISPLAY_SIGNAL,
            DATA            => DATA,
            ADDRESS         => ADDRESS,
            VGA_R           => VGA_R,
            VGA_G           => VGA_G,
            VGA_B           => VGA_B
        );

    -- Free-running clock
    clk_process : process
    begin
        while not sim_done loop
            CLK <= '0';
            wait for CLK_PERIOD / 2;
            CLK <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
        wait;
    end process;

    stim_process : process
    begin

        -- PHASE 1 : reset asserted -> output forced to 0
        wait for CLK_PERIOD * 4;
        check_pixel(462, 269, '1', 0, 0, 0, "reset wins on visible pixel");

        -- PHASE 2 : release reset
        nRST <= '1';
        wait until rising_edge(CLK);
        wait for 1 ns;

        -- PHASE 3 : DISPLAY = '0' (blanking) forces black even inside image
        check_pixel(462, 269, '0', 0, 0, 0, "blanking forces black");

        -- PHASE 4 : DISPLAY = '1' but outside image zone -> black
        check_pixel(100, 100, '1', 0, 0, 0, "outside image");

        -- PHASE 5 : DISPLAY = '1' inside image -> VGA reflects TEST_RAM
        check_pixel(462, 269, '1',  1,  0, 0, "pixel (0,0)");
        check_pixel(463, 269, '1',  2,  0, 0, "pixel (1,0)");
        check_pixel(464, 269, '1',  3,  0, 0, "pixel (2,0)");
        check_pixel(465, 269, '1',  4,  0, 0, "pixel (3,0)");
        check_pixel(462, 270, '1',  5,  0, 0, "pixel (0,1)");
        check_pixel(465, 272, '1', 15, 15, 15, "pixel (3,3)");

        report "ALL TESTS PASSED" severity note;
        sim_done <= true;
        wait;
    end process;

end sim;

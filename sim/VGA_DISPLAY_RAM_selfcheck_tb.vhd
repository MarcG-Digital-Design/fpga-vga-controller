library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Integration testbench for VGA_DISPLAY_RAM.
-- Smoke-test level : verifies that the top wires the 6 sub-modules
-- correctly and that the VGA timing signals pulse at the expected rate.
--
-- The test runs slightly longer than one full VGA frame (~16.7 ms) and
-- checks :
--   * RAM_ADDR is 0 while reset is asserted (warning)
--   * VGA_HS pulses at least 500 times in one frame (525 lines expected)
--   * VGA_VS pulses at least once per frame
--
-- Per-pixel image content is NOT checked here : that is covered by the
-- RGB_OUTPUT unit testbench and ultimately validated on a real VGA screen.
entity VGA_DISPLAY_RAM_selfcheck_tb is
end VGA_DISPLAY_RAM_selfcheck_tb;

architecture behavior of VGA_DISPLAY_RAM_selfcheck_tb is

    -- Component Declaration for the Unit Under Test (UUT)
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

    -- Stimulus signals (Inputs)
    signal CLK_25MHZ : STD_LOGIC := '0';
    signal nRST      : STD_LOGIC := '0';
    signal RAM_DATA  : STD_LOGIC_VECTOR(11 downto 0) := (others => '0');

    -- Observed signals (Outputs)
    signal RAM_ADDR  : STD_LOGIC_VECTOR(15 downto 0);
    signal VGA_R     : STD_LOGIC_VECTOR(3 downto 0);
    signal VGA_G     : STD_LOGIC_VECTOR(3 downto 0);
    signal VGA_B     : STD_LOGIC_VECTOR(3 downto 0);
    signal VGA_HS    : STD_LOGIC;
    signal VGA_VS    : STD_LOGIC;

    -- Clock period definition for 25 MHz
    constant CLK_PERIOD : time := 40 ns;

    -- Simulation flag to gracefully stop the clock generator
    signal sim_done : boolean := false;

    -- Counters used to verify HSYNC and VSYNC pulse activity
    signal hs_count : integer := 0;
    signal vs_count : integer := 0;

begin

    -- Instantiate the Unit Under Test (UUT)
    uut: VGA_DISPLAY_RAM
    port map (
        CLK_25MHZ => CLK_25MHZ,
        nRST      => nRST,
        RAM_ADDR  => RAM_ADDR,
        RAM_DATA  => RAM_DATA,
        VGA_R     => VGA_R,
        VGA_G     => VGA_G,
        VGA_B     => VGA_B,
        VGA_HS    => VGA_HS,
        VGA_VS    => VGA_VS
    );

    -- Clock generation process
    clk_process : process
    begin
        while not sim_done loop
            CLK_25MHZ <= '0';
            wait for CLK_PERIOD / 2;
            CLK_25MHZ <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
        wait;
    end process;

    -- RAM Mock Process
    -- Immediately provides mock data back to the module based on the requested address
    ram_mock_process : process(RAM_ADDR)
    begin
        -- Cast the lower 12 bits of the address directly into the pixel data
        -- This will create a visible pattern if you render the simulation output
        RAM_DATA <= RAM_ADDR(11 downto 0);
    end process;

    -- Count falling edges of VGA_HS (one pulse per scanline, active low)
    hs_counter : process(VGA_HS)
    begin
        if falling_edge(VGA_HS) then
            hs_count <= hs_count + 1;
        end if;
    end process;

    -- Count falling edges of VGA_VS (one pulse per frame, active low)
    vs_counter : process(VGA_VS)
    begin
        if falling_edge(VGA_VS) then
            vs_count <= vs_count + 1;
        end if;
    end process;

    -- Main stimulus and self-check process
    stim_proc : process
    begin
        report "--- STARTING VGA DISPLAY RAM SIMULATION ---" severity note;

        -- 1. Apply initial reset state
        nRST <= '0';
        wait for CLK_PERIOD * 5;

        -- 2. Self-check: Ensure address is explicitly 0 during reset
        -- Note: Depending on internal logic, some designs let the address float ('U') during reset.
        -- We assert a warning here rather than an error if it fails, to just flag it.
        assert (unsigned(RAM_ADDR) = 0)
            report "[WARNING] RAM_ADDR is not driven to 0 during reset."
            severity warning;

        -- 3. Release reset and start the system
        nRST <= '1';
        wait for CLK_PERIOD * 2;
        report "Reset released. VGA counters should start." severity note;

        -- 4. Run a bit more than one full frame (~16.7 ms) so VS pulses at least once
        wait for 17 ms;

        -- 5. After one full frame, expect at least:
        --      - 500 horizontal sync pulses (525 lines per frame, allow margin)
        --      - 1 vertical sync pulse
        assert hs_count >= 500
            report "[ERROR] Not enough HSYNC pulses: got " & integer'image(hs_count)
            severity failure;

        assert vs_count >= 1
            report "[ERROR] VSYNC never pulsed during one full frame"
            severity failure;

        report "Counters OK : HS = " & integer'image(hs_count) &
               " , VS = " & integer'image(vs_count)
            severity note;

        report "--- SIMULATION COMPLETED SUCCESSFULLY (Basic checks passed) ---" severity note;

        -- 6. End the simulation
        sim_done <= true;
        wait;
    end process;

end behavior;

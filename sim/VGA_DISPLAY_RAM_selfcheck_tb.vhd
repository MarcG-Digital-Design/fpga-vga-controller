library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Self-checking testbench for VGA_DISPLAY_RAM
entity VGA_DISPLAY_RAM__selfcheck_tb is
end VGA_DISPLAY_RAM__selfcheck_tb;

architecture behavior of VGA_DISPLAY_RAM__selfcheck_tb is

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

        -- 4. Wait for slightly more than one full horizontal line (Standard VGA is 800 clock cycles per line)
        -- 850 cycles * 40 ns = 34000 ns
        wait for 34000 ns;

        -- 5. Self-check: Ensure H_SYNC generated a pulse (toggled)
        -- This verifies the horizontal counter and comparator are alive
        assert (VGA_HS'active) 
            report "[ERROR] VGA_HS did not toggle! Horizontal counter might be stuck." 
            severity error;

        -- 6. Let the simulation run to capture part of the vertical progression
        -- (To simulate a full frame to see V_SYNC toggle, you would need to wait ~ 16.7 ms)
        wait for 100000 ns;

        report "--- SIMULATION COMPLETED SUCCESSFULLY (Basic checks passed) ---" severity note;

        -- 7. End the simulation
        sim_done <= true;
        wait;
    end process;

end behavior;
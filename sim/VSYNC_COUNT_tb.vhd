library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Manual testbench for VSYNC_COUNT
-- Goal: generate CLK, release the reset, and generate HCOUNT_OVERFLOW pulses,
-- then observe VCOUNTER_VALUE and VCOUNT_OVERFLOW in GTKWave or ModelSim.
entity VSYNC_COUNT_tb is
end VSYNC_COUNT_tb;

architecture sim of VSYNC_COUNT_tb is

    -- Device Under Test (DUT) component declaration
    component VSYNC_COUNT
        Port (
            CLK              : in  STD_LOGIC;
            nRST             : in  STD_LOGIC;
            HCOUNT_OVERFLOW  : in  STD_LOGIC;
            VCOUNT_OVERFLOW  : out STD_LOGIC;
            VCOUNTER_VALUE   : out STD_LOGIC_VECTOR(9 downto 0)
        );
    end component;

    -- 25 MHz pixel clock -> 40 ns period
    constant CLK_PERIOD : time := 40 ns;

    -- Internal signals initialization
    signal CLK              : STD_LOGIC := '0';
    signal nRST             : STD_LOGIC := '0'; -- Start with active reset (low)
    signal HCOUNT_OVERFLOW  : STD_LOGIC := '0';
    signal VCOUNT_OVERFLOW  : STD_LOGIC;
    signal VCOUNTER_VALUE   : STD_LOGIC_VECTOR(9 downto 0);

    -- Flag to stop clock generation cleanly
    signal sim_done : boolean := false;

begin

    -- DUT instantiation
    DUT : VSYNC_COUNT
        port map (
            CLK              => CLK,
            nRST             => nRST,
            HCOUNT_OVERFLOW  => HCOUNT_OVERFLOW,
            VCOUNT_OVERFLOW  => VCOUNT_OVERFLOW,
            VCOUNTER_VALUE   => VCOUNTER_VALUE
        );

    -- Clock generation process
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

    -- Stimulus process: Reset sequence followed by one HCOUNT_OVERFLOW pulse
    -- every 8 clock cycles (accelerated pace for simulation purposes).
    stim_process : process
    begin
        -- 1. Hardware Reset Sequence
        nRST <= '0';
        wait for CLK_PERIOD * 2; 
        nRST <= '1'; -- Asynchronous reset release
        wait until rising_edge(CLK); -- Synchronize with clock for subsequent stimuli

        wait for CLK_PERIOD * 4;

        -- 2. Line generation (600 pulses to observe the wrap-around at 524)
        for i in 0 to 599 loop
            wait until rising_edge(CLK);
            HCOUNT_OVERFLOW <= '1';
            wait until rising_edge(CLK);
            HCOUNT_OVERFLOW <= '0';
            
            -- 6 clock cycles pause between two horizontal pulses
            wait for CLK_PERIOD * 6;
        end loop;

        -- End of simulation
        sim_done <= true;
        wait;
    end process;

end sim;
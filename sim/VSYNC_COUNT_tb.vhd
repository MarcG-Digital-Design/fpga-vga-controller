library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Manual testbench for VSYNC_COUNT.
-- Generates CLK, asserts nRST low for a few cycles, then drives
-- HCOUNT_OVERFLOW pulses so the V counter can be observed in GTKWave.
entity VSYNC_COUNT_tb is
end VSYNC_COUNT_tb;

architecture sim of VSYNC_COUNT_tb is

    component VSYNC_COUNT
        Port (
            CLK              : in  STD_LOGIC;
            nRST             : in  STD_LOGIC;
            HCOUNT_OVERFLOW  : in  STD_LOGIC;
            VCOUNTER_VALUE   : out STD_LOGIC_VECTOR(9 downto 0)
        );
    end component;

    -- 25 MHz pixel clock -> 40 ns period
    constant CLK_PERIOD : time := 40 ns;

    signal CLK             : STD_LOGIC := '0';
    signal nRST            : STD_LOGIC := '0';   -- start asserted (active low)
    signal HCOUNT_OVERFLOW : STD_LOGIC := '0';
    signal VCOUNTER_VALUE  : STD_LOGIC_VECTOR(9 downto 0);

    signal sim_done : boolean := false;

begin

    DUT : VSYNC_COUNT
        port map (
            CLK             => CLK,
            nRST            => nRST,
            HCOUNT_OVERFLOW => HCOUNT_OVERFLOW,
            VCOUNTER_VALUE  => VCOUNTER_VALUE
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

    -- Stimulus
    stim_process : process
    begin
        -- Phase 1 : hold reset low for 4 clock cycles, then release
        wait for CLK_PERIOD * 4;
        nRST <= '1';
        wait for CLK_PERIOD * 2;

        -- Phase 2 : 300 line pulses (counter climbs but does NOT wrap yet)
        for i in 0 to 299 loop
            wait until rising_edge(CLK);
            HCOUNT_OVERFLOW <= '1';
            wait until rising_edge(CLK);
            HCOUNT_OVERFLOW <= '0';
            wait for CLK_PERIOD * 6;
        end loop;

        -- Phase 3 : mid-run reset pulse, the counter must fall back to 0
        wait for CLK_PERIOD * 4;
        nRST <= '0';
        wait for CLK_PERIOD * 4;
        nRST <= '1';
        wait for CLK_PERIOD * 4;

        -- Phase 4 : 600 more pulses to also exercise the 524 -> 0 wrap
        for i in 0 to 599 loop
            wait until rising_edge(CLK);
            HCOUNT_OVERFLOW <= '1';
            wait until rising_edge(CLK);
            HCOUNT_OVERFLOW <= '0';
            wait for CLK_PERIOD * 6;
        end loop;

        sim_done <= true;
        wait;
    end process;

end sim;

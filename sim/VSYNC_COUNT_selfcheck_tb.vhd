library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Self-checking testbench for VSYNC_COUNT.
-- The testbench keeps its own reference counter ("expected") and compares
-- it against the DUT output after every HCOUNT_OVERFLOW pulse.
-- On any mismatch it reports with severity FAILURE, which makes GHDL exit
-- with a non-zero code -> automated PASS/FAIL, no framework needed.
entity VSYNC_COUNT_selfcheck_tb is
end VSYNC_COUNT_selfcheck_tb;

architecture sim of VSYNC_COUNT_selfcheck_tb is

    component VSYNC_COUNT
        Port (
            CLK              : in  STD_LOGIC;
            HCOUNT_OVERFLOW  : in  STD_LOGIC;
            VCOUNTER_VALUE   : out STD_LOGIC_VECTOR(9 downto 0)
        );
    end component;

    constant CLK_PERIOD : time    := 40 ns;   -- 25 MHz pixel clock
    constant LAST_LINE  : integer := 524;     -- counter wraps after this value

    signal CLK             : STD_LOGIC := '0';
    signal HCOUNT_OVERFLOW : STD_LOGIC := '0';
    signal VCOUNTER_VALUE  : STD_LOGIC_VECTOR(9 downto 0);

    signal sim_done : boolean := false;

begin

    DUT : VSYNC_COUNT
        port map (
            CLK             => CLK,
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

    -- Stimulus + checker
    check_process : process
        variable expected     : integer := 0;
        variable wrap_checked  : boolean := false;
    begin
        -- Let a few clocks pass after reset
        wait until rising_edge(CLK);
        wait until rising_edge(CLK);

        -- Drive 530 line pulses: enough to cross the 524 -> 0 wrap
        for i in 0 to 530 loop

            -- Generate a clean one-cycle HCOUNT_OVERFLOW pulse
            HCOUNT_OVERFLOW <= '1';
            wait until rising_edge(CLK);   -- this edge is sampled by the DUT
            HCOUNT_OVERFLOW <= '0';

            -- Update the reference model the same way the DUT should behave
            if expected = LAST_LINE then
                expected     := 0;
                wrap_checked := true;
            else
                expected := expected + 1;
            end if;

            -- Let the combinational output settle, then compare
            wait for 1 ns;
            assert to_integer(unsigned(VCOUNTER_VALUE)) = expected
                report "MISMATCH at pulse " & integer'image(i) &
                       " : DUT = " & integer'image(to_integer(unsigned(VCOUNTER_VALUE))) &
                       " , expected = " & integer'image(expected)
                severity failure;

            -- Space pulses out a little (mimics real line spacing)
            wait until rising_edge(CLK);
            wait until rising_edge(CLK);
        end loop;

        -- Make sure we actually exercised the wrap-around
        assert wrap_checked
            report "Test incomplete: the 524 -> 0 wrap was never reached"
            severity failure;

        report "ALL TESTS PASSED" severity note;
        sim_done <= true;
        wait;
    end process;

end sim;

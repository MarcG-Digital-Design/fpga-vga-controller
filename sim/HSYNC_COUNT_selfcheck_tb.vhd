library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Self-checking testbench for HSYNC_COUNT.
-- Four phases:
--   1) Reset asserted     -> counter and overflow stay at 0
--   2) Reset released
--   3) Free running        -> counter matches the reference model,
--                            overflow pulses high only on the 799 -> 0 wrap
--   4) Mid-run reset       -> counter and overflow return to 0
-- Mismatches use `severity failure` so GHDL exits with a non-zero code.
entity HSYNC_COUNT_selfcheck_tb is
end HSYNC_COUNT_selfcheck_tb;

architecture sim of HSYNC_COUNT_selfcheck_tb is

    -- Helper: read the DUT counter output as an integer
    function dut_value(v : STD_LOGIC_VECTOR) return integer is
    begin
        return to_integer(unsigned(v));
    end function;

    component HSYNC_COUNT
        Port (
            CLK              : in  STD_LOGIC;
            nRST             : in  STD_LOGIC;
            HCOUNT_OVERFLOW  : out STD_LOGIC;
            HCOUNTER_VALUE   : out STD_LOGIC_VECTOR(9 downto 0)
        );
    end component;

    constant CLK_PERIOD : time := 40 ns;   -- 25 MHz pixel clock

    signal CLK             : STD_LOGIC := '0';
    signal nRST            : STD_LOGIC := '0';   -- active low, asserted at start
    signal HCOUNT_OVERFLOW : STD_LOGIC;
    signal HCOUNTER_VALUE  : STD_LOGIC_VECTOR(9 downto 0);

    signal sim_done : boolean := false;

begin

    DUT : HSYNC_COUNT
        port map (
            CLK             => CLK,
            nRST            => nRST,
            HCOUNT_OVERFLOW => HCOUNT_OVERFLOW,
            HCOUNTER_VALUE  => HCOUNTER_VALUE
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
    stim_process : process
        variable expected  : integer := 0;
        variable wrap_seen : boolean := false;
    begin

        -- ╔══════════ PHASE 1 : reset asserted ══════════════════════════════╗
        for i in 0 to 100 loop
            wait until rising_edge(CLK);
            wait for 1 ns;
            assert HCOUNT_OVERFLOW = '0'
                report "RESET FAIL: overflow not 0 while nRST is asserted"
                severity failure;
            assert dut_value(HCOUNTER_VALUE) = 0
                report "RESET FAIL: counter not 0 while nRST is asserted"
                severity failure;
        end loop;

        -- ╔══════════ PHASE 2 : release reset ═══════════════════════════════╗
        nRST <= '1';

        -- ╔══════════ PHASE 3 : counting + overflow pulse ═══════════════════╗
        for i in 0 to 3000 loop
            wait until rising_edge(CLK);
            wait for 1 ns;

            -- Step A : update the reference model the same way the DUT does
            if expected = 799 then
                expected  := 0;
                wrap_seen := true;
            else
                expected := expected + 1;
            end if;

            -- Step B : compare DUT counter to the model
            assert dut_value(HCOUNTER_VALUE) = expected
                report "COUNT FAIL : DUT = " &
                       integer'image(dut_value(HCOUNTER_VALUE)) &
                       " , expected = " & integer'image(expected)
                severity failure;

            -- Step C : overflow pulses high only on the cycle right after a wrap
            if expected = 0 then
                assert HCOUNT_OVERFLOW = '1'
                    report "OVERFLOW FAIL: pulse missing on wrap"
                    severity failure;
            else
                assert HCOUNT_OVERFLOW = '0'
                    report "OVERFLOW FAIL: spurious pulse at counter = " &
                           integer'image(expected)
                    severity failure;
            end if;
        end loop;

        -- Coverage check : make sure the test actually exercised the wrap
        assert wrap_seen
            report "Test incomplete: the 799 -> 0 wrap was never reached"
            severity failure;

        -- ╔══════════ PHASE 4 : mid-run reset ═══════════════════════════════╗
        nRST <= '0';
        for i in 0 to 100 loop
            wait until rising_edge(CLK);
            wait for 1 ns;
            assert HCOUNT_OVERFLOW = '0'
                report "RESET FAIL: overflow not cleared by mid-run reset"
                severity failure;
            assert dut_value(HCOUNTER_VALUE) = 0
                report "RESET FAIL: counter not cleared by mid-run reset"
                severity failure;
        end loop;

        -- ╔══════════ End ═══════════════════════════════════════════════════╗
        report "ALL TESTS PASSED" severity note;
        sim_done <= true;
        wait;
    end process;

end sim;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Self-checking testbench for VSYNC_COUNT.
-- Three checks are performed:
--   1) After reset release, the counter starts at 0.
--   2) The counter increments by 1 on each HCOUNT_OVERFLOW pulse and
--      wraps from 524 back to 0.
--   3) Asserting nRST mid-run forces the counter back to 0 immediately.
-- Mismatches use `severity failure` so GHDL exits with a non-zero code.
entity VSYNC_COUNT_selfcheck_tb is
end VSYNC_COUNT_selfcheck_tb;

architecture sim of VSYNC_COUNT_selfcheck_tb is

    component VSYNC_COUNT
        Port (
            CLK              : in  STD_LOGIC;
            nRST             : in  STD_LOGIC;
            HCOUNT_OVERFLOW  : in  STD_LOGIC;
            VCOUNTER_VALUE   : out STD_LOGIC_VECTOR(9 downto 0)
        );
    end component;

    constant CLK_PERIOD : time    := 40 ns;   -- 25 MHz pixel clock
    constant LAST_LINE  : integer := 524;     -- counter wraps after this value

    signal CLK             : STD_LOGIC := '0';
    signal nRST            : STD_LOGIC := '0';
    signal HCOUNT_OVERFLOW : STD_LOGIC := '0';
    signal VCOUNTER_VALUE  : STD_LOGIC_VECTOR(9 downto 0);

    signal sim_done : boolean := false;

    -- Helper: read the DUT output as an integer
    function dut_value(v : STD_LOGIC_VECTOR) return integer is
    begin
        return to_integer(unsigned(v));
    end function;

begin

    DUT : VSYNC_COUNT
        port map (
            CLK             => CLK,
            nRST            => nRST,
            HCOUNT_OVERFLOW => HCOUNT_OVERFLOW,
            VCOUNTER_VALUE  => VCOUNTER_VALUE
        );

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

    check_process : process
        variable expected    : integer := 0;
        variable wrap_seen   : boolean := false;
    begin
        -- ---- Check 1 : reset behavior ---------------------------------------
        -- Hold reset low for a few clocks, the counter must stay at 0.
        wait for CLK_PERIOD * 4;
        assert dut_value(VCOUNTER_VALUE) = 0
            report "RESET FAIL: counter not 0 while nRST is asserted"
            severity failure;

        nRST <= '1';
        wait until rising_edge(CLK);
        wait for 1 ns;
        assert dut_value(VCOUNTER_VALUE) = 0
            report "RESET FAIL: counter not 0 right after nRST release"
            severity failure;

        -- ---- Check 2 : count and wrap ---------------------------------------
        for i in 0 to 530 loop
            HCOUNT_OVERFLOW <= '1';
            wait until rising_edge(CLK);
            HCOUNT_OVERFLOW <= '0';

            if expected = LAST_LINE then
                expected  := 0;
                wrap_seen := true;
            else
                expected := expected + 1;
            end if;

            wait for 1 ns;
            assert dut_value(VCOUNTER_VALUE) = expected
                report "COUNT FAIL at pulse " & integer'image(i) &
                       " : DUT = " & integer'image(dut_value(VCOUNTER_VALUE)) &
                       " , expected = " & integer'image(expected)
                severity failure;

            wait until rising_edge(CLK);
            wait until rising_edge(CLK);
        end loop;

        assert wrap_seen
            report "COUNT FAIL: the 524 -> 0 wrap was never reached"
            severity failure;

        -- ---- Check 3 : reset in the middle of operation ---------------------
        -- Counter is somewhere > 0 here. Pulse nRST low and confirm it returns
        -- to 0 even while HCOUNT_OVERFLOW stays low.
        nRST <= '0';
        wait until rising_edge(CLK);
        wait for 1 ns;
        assert dut_value(VCOUNTER_VALUE) = 0
            report "RESET FAIL: counter not cleared by mid-run reset"
            severity failure;

        nRST <= '1';

        report "ALL TESTS PASSED" severity note;
        sim_done <= true;
        wait;
    end process;

end sim;

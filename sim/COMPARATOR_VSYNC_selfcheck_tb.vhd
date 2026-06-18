library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity COMPARATOR_VSYNC_selfcheck_tb is
end COMPARATOR_VSYNC_selfcheck_tb;


architecture sim of COMPARATOR_VSYNC_selfcheck_tb is


component  COMPARATOR_VSYNC
    Port (
        CLK              : in  STD_LOGIC;
        nRST             : in  STD_LOGIC;
        VCOUNTER_VALUE   : in  STD_LOGIC_VECTOR(9 downto 0);
        V_SYNC           : out STD_LOGIC
        );
end component;

constant CLK_PERIOD : time := 40 ns;   -- 25 MHz pixel clock

    signal CLK             : STD_LOGIC := '0';
    signal nRST            : STD_LOGIC := '0';   -- active low, asserted at start
    signal VCOUNTER_VALUE  : STD_LOGIC_VECTOR(9 downto 0);
    signal V_SYNC          : STD_LOGIC;

    signal sim_done : boolean := false;



begin

    DUT : COMPARATOR_VSYNC
        port map (
            CLK             => CLK,
            nRST            => nRST,
            VCOUNTER_VALUE  => VCOUNTER_VALUE,
            V_SYNC          => V_SYNC
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
        -- checking procedure
        procedure check_point(v : integer; expected : STD_LOGIC; tag : string) is
        begin
            VCOUNTER_VALUE <= std_logic_vector(to_unsigned(v, 10));
            wait until rising_edge(CLK);
            wait for 1 ns;
            assert V_SYNC = expected
                report "VSYNC FAIL [" & tag & "] at v=" & integer'image(v)
                severity failure;
        end procedure;

    begin
        -- Phase 1 : Reset asserted
        wait for CLK_PERIOD * 4;
        check_point(0, '1', "reset wins at start");   -- v=0 would be pulse, but reset forces idle

        -- PHASE 1 bis : release reset
        wait for CLK_PERIOD * 2;
        nRST <= '1';
        wait for CLK_PERIOD * 2;

        -- PHASE 2 : checks across the pulse boundary at v=2
        wait until rising_edge(CLK);
        check_point(  0, '0', "first pulse line");
        check_point(  1, '0', "last pulse line");
        check_point(  2, '1', "first idle line (back porch)");
        check_point(100, '1', "back porch / pre-visible");
        check_point(250, '1', "middle of visible area");
        check_point(524, '1', "last line of frame");

        -- PHASE 3 : reset in the middle
        nRST <= '0';
        check_point(0, '1', "reset overrides pulse");   -- forces idle while v=0 would be pulse

        report "ALL TESTS PASSED" severity note;
        sim_done <= true;
        wait;
    end process;


end sim;

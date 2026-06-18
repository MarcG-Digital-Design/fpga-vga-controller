library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity COMPARATOR_HSYNC_selfcheck_tb is
end COMPARATOR_HSYNC_selfcheck_tb;


architecture sim of COMPARATOR_HSYNC_selfcheck_tb is


component  COMPARATOR_HSYNC
    Port (
        CLK              : in  STD_LOGIC;
        nRST             : in  STD_LOGIC;
        HCOUNTER_VALUE   : in  STD_LOGIC_VECTOR(9 downto 0);
        H_SYNC           : out STD_LOGIC
        );
end component;

constant CLK_PERIOD : time := 40 ns;   -- 25 MHz pixel clock

    signal CLK             : STD_LOGIC := '0';
    signal nRST            : STD_LOGIC := '0';   -- active low, asserted at start
    signal HCOUNTER_VALUE  : STD_LOGIC_VECTOR(9 downto 0);
    signal H_SYNC  : STD_LOGIC;

    signal sim_done : boolean := false;



begin

    DUT : COMPARATOR_HSYNC
        port map (
            CLK             => CLK,
            nRST            => nRST,
            HCOUNTER_VALUE  => HCOUNTER_VALUE,
            H_SYNC => H_SYNC
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
        procedure check_point(h : integer; expected : STD_LOGIC; tag : string) is
        begin
            HCOUNTER_VALUE <= std_logic_vector(to_unsigned(h, 10));
            wait until rising_edge(CLK);
            wait for 1 ns;
            assert H_SYNC = expected
                report "HSYNC FAIL [" & tag & "] at h=" & integer'image(h)
                severity failure;
        end procedure;

    begin
        -- Phase 1 Reset
        wait for CLK_PERIOD * 4;
        check_point(50, '1', "reset wins at start");   -- h=50 would be pulse, but reset forces idle

        -- PHASE 1 bis : release reset
        wait for CLK_PERIOD * 2;
        nRST <= '1';
        wait for CLK_PERIOD * 2;

        -- PHASE 2 : checks across the pulse boundary at h=96
        wait until rising_edge(CLK);
        check_point(  0, '0', "first pulse pixel");
        check_point( 50, '0', "middle of pulse");
        check_point( 95, '0', "last pulse pixel");
        check_point( 96, '1', "first idle pixel");
        check_point(400, '1', "middle visible");
        check_point(799, '1', "last pixel of line");

        -- PHASE 3 : reset in the middle
        nRST <= '0';
        check_point(50, '1', "reset overrides pulse");   -- forces idle while h=50 would be pulse

        report "ALL TESTS PASSED" severity note;
        sim_done <= true;
        wait;
    end process;


end sim;

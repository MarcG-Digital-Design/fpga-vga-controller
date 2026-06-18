library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity COMPARATOR_TDISP_selfcheck_tb is
end COMPARATOR_TDISP_selfcheck_tb;


architecture sim of COMPARATOR_TDISP_selfcheck_tb is


component  COMPARATOR_TDISP
    Port (
            CLK              : in  STD_LOGIC;
            nRST             : in  STD_LOGIC;
            HCOUNTER_VALUE   : in  STD_LOGIC_VECTOR(9 downto 0);
            VCOUNTER_VALUE   : in  STD_LOGIC_VECTOR(9 downto 0);
            DISPLAY_SIGNAL   : out STD_LOGIC
        );
end component;

constant CLK_PERIOD : time := 40 ns;   -- 25 MHz pixel clock

    signal CLK             : STD_LOGIC := '0';
    signal nRST            : STD_LOGIC := '0';   -- active low, asserted at start
    signal HCOUNTER_VALUE  : STD_LOGIC_VECTOR(9 downto 0);
    signal VCOUNTER_VALUE  : STD_LOGIC_VECTOR(9 downto 0);
    signal DISPLAY_SIGNAL  : STD_LOGIC;

    signal sim_done : boolean := false;


    
    procedure check_point(h : integer; v : integer; expected : STD_LOGIC; tag : string) is
    begin
        HCOUNTER_VALUE <= std_logic_vector(to_unsigned(h, 10));
        VCOUNTER_VALUE <= std_logic_vector(to_unsigned(v, 10));
        wait until rising_edge(CLK);
        wait for 1 ns;
        assert DISPLAY_SIGNAL = expected
            report "DISPLAY FAIL [" & tag & "] at (" &
                integer'image(h) & "," & integer'image(v) & ")"
            severity failure;
    end procedure;


begin

    DUT : COMPARATOR_TDISP
        port map (
            CLK             => CLK,
            nRST            => nRST,
            VCOUNTER_VALUE => VCOUNTER_VALUE,
            HCOUNTER_VALUE  => HCOUNTER_VALUE,
            DISPLAY_SIGNAL => DISPLAY_SIGNAL
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
        -- Phase 1 Reset
        wait for CLK_PERIOD * 4;
        check_point(400, 250, '0', "reset at start (in visible zone, but reset wins)");
        
        -- PHASE 1 bis : 
        wait for CLK_PERIOD * 2;
        nRST <= '1';
        wait for CLK_PERIOD * 2;
        

        -- PHASE 2 : checks
        wait until rising_edge(CLK);
        check_point(400, 250, '1', "center");
        check_point(144,  31, '1', "top-left corner");
        check_point(784, 511, '1', "bottom-right corner");
        check_point(143, 250, '0', "just left");
        check_point(785, 250, '0', "just right");
        check_point(400,  30, '0', "just above");
        check_point(400, 512, '0', "just below");
        check_point(  0,   0, '0', "origin");
        check_point(799, 524, '0', "bottom-right blanking");
	check_point(784, 31, '1', "top-right corner");

        -- PHASE 3 : reset in the middle
        nRST <= '0';
        check_point(400, 250, '0', "reset overrides visible area");

    report "ALL TESTS PASSED" severity note;
    sim_done <= true;
    wait;

end process;


end sim;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;  


entity HSYNC_COUNT_tb is
end HSYNC_COUNT_tb;

architecture sim of HSYNC_COUNT_tb is
    component HSYNC_COUNT
        Port (
        CLK              : in  STD_LOGIC;
	nRST             : in  STD_LOGIC;
        HCOUNT_OVERFLOW  : out  STD_LOGIC;
        HCOUNTER_VALUE   : out STD_LOGIC_VECTOR(9 downto 0)
);
    end component;

    constant CLK_PERIOD : time := 40 ns;
    signal CLK             : STD_LOGIC := '0';
    signal nRST            : STD_LOGIC := '0';
    signal HCOUNT_OVERFLOW : STD_LOGIC;          -- pas d'init
    signal HCOUNTER_VALUE  : STD_LOGIC_VECTOR(9 downto 0);
    signal sim_done        : boolean := false;
begin


    DUT : HSYNC_COUNT
        port map (
            CLK             => CLK,
            nRST            => nRST,
            HCOUNT_OVERFLOW => HCOUNT_OVERFLOW,
            HCOUNTER_VALUE  => HCOUNTER_VALUE
        );


    clk_process : process
    begin
        while not sim_done loop
            CLK <= '0'; wait for CLK_PERIOD / 2;
            CLK <= '1'; wait for CLK_PERIOD / 2;
        end loop;
        wait;
    end process;


    stim_process : process
    begin
        -- Phase 1 : hold reset low for 15 clock cycles, then release
        wait for CLK_PERIOD * 15;
        nRST <= '1';
        wait for CLK_PERIOD * 2;


        wait for CLK_PERIOD * 4000;
        nRST <= '0';

        sim_done <= true;
        wait;

    end process;

end sim;
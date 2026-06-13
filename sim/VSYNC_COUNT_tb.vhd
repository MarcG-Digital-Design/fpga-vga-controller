library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Testbench manuel pour VSYNC_COUNT
-- But : generer CLK et des impulsions HCOUNT_OVERFLOW,
-- puis observer VCOUNTER_VALUE dans GTKWave.
entity VSYNC_COUNT_tb is
end VSYNC_COUNT_tb;

architecture sim of VSYNC_COUNT_tb is

    -- Composant teste (DUT = Device Under Test)
    component VSYNC_COUNT
        Port (
            CLK              : in  STD_LOGIC;
            HCOUNT_OVERFLOW  : in  STD_LOGIC;
            VCOUNTER_VALUE   : out STD_LOGIC_VECTOR(9 downto 0)
        );
    end component;

    -- Horloge pixel 25 MHz -> periode 40 ns
    constant CLK_PERIOD : time := 40 ns;

    signal CLK             : STD_LOGIC := '0';
    signal HCOUNT_OVERFLOW : STD_LOGIC := '0';
    signal VCOUNTER_VALUE  : STD_LOGIC_VECTOR(9 downto 0);

    -- Permet d'arreter proprement la generation d'horloge
    signal sim_done : boolean := false;

begin

    -- Instanciation du DUT
    DUT : VSYNC_COUNT
        port map (
            CLK             => CLK,
            HCOUNT_OVERFLOW => HCOUNT_OVERFLOW,
            VCOUNTER_VALUE  => VCOUNTER_VALUE
        );

    -- Generation de l'horloge
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

    -- Stimuli : une impulsion HCOUNT_OVERFLOW d'un cycle
    -- tous les 8 coups d'horloge (rythme acceleré pour bien voir
    -- le compteur monter et reboucler a 524 sans attendre une vraie ligne).
    stim_process : process
    begin
        -- on laisse passer quelques cycles au demarrage
        wait for CLK_PERIOD * 4;

        -- 600 impulsions : assez pour depasser 524 et voir le wrap a 0
        for i in 0 to 599 loop
            wait until rising_edge(CLK);
            HCOUNT_OVERFLOW <= '1';
            wait until rising_edge(CLK);
            HCOUNT_OVERFLOW <= '0';
            -- 6 cycles de pause entre deux impulsions
            wait for CLK_PERIOD * 6;
        end loop;

        sim_done <= true;
        wait;
    end process;

end sim;

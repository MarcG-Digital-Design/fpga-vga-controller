library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Integration testbench for VGA_DISPLAY_RAM (the synthesis top).
-- Smoke-test level : feeds a 50 MHz clock and a reset, lets the design
-- run for ~17 ms (one full frame) and verifies that VGA_HS / VGA_VS
-- pulse at the expected rate.
--
-- The Quartus altsyncram IP_ROM is replaced at simulation time by the
-- behavioural mock defined in sim/IP_ROM.vhd (same entity name, same
-- ports, but pure VHDL so GHDL can elaborate it).
entity VGA_DISPLAY_RAM_selfcheck_tb is
end VGA_DISPLAY_RAM_selfcheck_tb;

architecture behavior of VGA_DISPLAY_RAM_selfcheck_tb is

    component VGA_DISPLAY_RAM
        generic (
            IMG_WIDTH  : integer := 256;
            IMG_HEIGHT : integer := 256;
            ADDR_BITS  : integer := 16
        );
        Port (
            MAX10_CLK1_50 : in  STD_LOGIC;
            KEY0          : in  STD_LOGIC;
            VGA_R         : out STD_LOGIC_VECTOR(3 downto 0);
            VGA_G         : out STD_LOGIC_VECTOR(3 downto 0);
            VGA_B         : out STD_LOGIC_VECTOR(3 downto 0);
            VGA_HS        : out STD_LOGIC;
            VGA_VS        : out STD_LOGIC
        );
    end component;

    -- Stimulus signals (inputs)
    signal MAX10_CLK1_50 : STD_LOGIC := '0';
    signal KEY0          : STD_LOGIC := '0';   -- active low : '0' = reset asserted

    -- Observed signals (outputs)
    signal VGA_R  : STD_LOGIC_VECTOR(3 downto 0);
    signal VGA_G  : STD_LOGIC_VECTOR(3 downto 0);
    signal VGA_B  : STD_LOGIC_VECTOR(3 downto 0);
    signal VGA_HS : STD_LOGIC;
    signal VGA_VS : STD_LOGIC;

    -- 50 MHz oscillator -> 20 ns period (DE10-Lite on-board clock)
    constant CLK50_PERIOD : time := 20 ns;

    -- Flag used to stop the clock generator cleanly
    signal sim_done : boolean := false;

    -- Counters used to verify HSYNC and VSYNC pulse activity
    signal hs_count : integer := 0;
    signal vs_count : integer := 0;

begin

    -- DUT
    uut : VGA_DISPLAY_RAM
        port map (
            MAX10_CLK1_50 => MAX10_CLK1_50,
            KEY0          => KEY0,
            VGA_R         => VGA_R,
            VGA_G         => VGA_G,
            VGA_B         => VGA_B,
            VGA_HS        => VGA_HS,
            VGA_VS        => VGA_VS
        );

    -- 50 MHz on-board oscillator
    clk_process : process
    begin
        while not sim_done loop
            MAX10_CLK1_50 <= '0';
            wait for CLK50_PERIOD / 2;
            MAX10_CLK1_50 <= '1';
            wait for CLK50_PERIOD / 2;
        end loop;
        wait;
    end process;

    -- Count falling edges of VGA_HS (one pulse per scanline, active low)
    hs_counter : process(VGA_HS)
    begin
        if falling_edge(VGA_HS) then
            hs_count <= hs_count + 1;
        end if;
    end process;

    -- Count falling edges of VGA_VS (one pulse per frame, active low)
    vs_counter : process(VGA_VS)
    begin
        if falling_edge(VGA_VS) then
            vs_count <= vs_count + 1;
        end if;
    end process;

    -- Main stimulus + self-check process
    stim_proc : process
    begin
        report "--- STARTING VGA_DISPLAY_RAM SIMULATION ---" severity note;

        -- 1. Reset asserted (KEY0 = '0' = button pressed)
        KEY0 <= '0';
        wait for CLK50_PERIOD * 10;

        -- 2. Release reset
        KEY0 <= '1';
        wait for CLK50_PERIOD * 4;
        report "Reset released. VGA counters should start." severity note;

        -- 3. Run a bit more than one full frame (~16.7 ms) so VS pulses
        wait for 17 ms;

        -- 4. After one frame, expect at least :
        --      - 500 horizontal sync pulses (525 lines per frame, allow margin)
        --      - 1 vertical sync pulse
        assert hs_count >= 500
            report "[ERROR] Not enough HSYNC pulses: got " & integer'image(hs_count)
            severity failure;

        assert vs_count >= 1
            report "[ERROR] VSYNC never pulsed during one full frame"
            severity failure;

        report "Counters OK : HS = " & integer'image(hs_count) &
               " , VS = " & integer'image(vs_count)
            severity note;

        report "--- SIMULATION COMPLETED SUCCESSFULLY ---" severity note;

        sim_done <= true;
        wait;
    end process;

end behavior;

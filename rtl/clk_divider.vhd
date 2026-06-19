library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Simple clock divider : produces a 25 MHz clock from a 50 MHz input
-- by toggling on every rising edge of the input clock (divide by 2).
--
-- Notes :
--   * The output is a derived clock. Quartus will emit a warning about
--     it not being a true global clock — that is expected and harmless
--     for this design (single 25 MHz domain, no high-speed paths).
--   * For phase-locked or non-integer ratios (e.g. 25.175 MHz) a real
--     PLL would be required. 25 MHz from a 50 MHz oscillator is fine
--     for any standard VGA monitor.
entity clk_divider is
    Port (
        CLK_50 : in  STD_LOGIC;
        CLK_25 : out STD_LOGIC
    );
end clk_divider;

architecture rtl of clk_divider is
    signal toggle : STD_LOGIC := '0';
begin

    process(CLK_50)
    begin
        if rising_edge(CLK_50) then
            toggle <= not toggle;
        end if;
    end process;

    CLK_25 <= toggle;

end rtl;

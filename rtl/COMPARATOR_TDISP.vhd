library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity COMPARATOR_TDISP is
    Port (
        CLK              : in  STD_LOGIC;
        nRST             : in  STD_LOGIC;
        HCOUNTER_VALUE   : in  STD_LOGIC_VECTOR(9 downto 0);
        VCOUNTER_VALUE   : in  STD_LOGIC_VECTOR(9 downto 0);
        DISPLAY_SIGNAL   : out STD_LOGIC
    );
end COMPARATOR_TDISP;

architecture Behavioral of COMPARATOR_TDISP is
begin

    process(CLK)
    begin
        if rising_edge(CLK) then
            if nRST = '0' then
                DISPLAY_SIGNAL <= '0';
            elsif (unsigned(VCOUNTER_VALUE) >= 31  and unsigned(VCOUNTER_VALUE) <= 511) and
                  (unsigned(HCOUNTER_VALUE) >= 144 and unsigned(HCOUNTER_VALUE) <= 784) then
                DISPLAY_SIGNAL <= '1';   -- in visible area
            else
                DISPLAY_SIGNAL <= '0';   -- in blanking
            end if;
        end if;
    end process;

end Behavioral;
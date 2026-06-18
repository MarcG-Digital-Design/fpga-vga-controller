library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity COMPARATOR_VSYNC is
    Port (
        CLK              : in  STD_LOGIC;
        nRST             : in  STD_LOGIC;
        VCOUNTER_VALUE   : in  STD_LOGIC_VECTOR(9 downto 0);
        V_SYNC           : out STD_LOGIC
    );
end COMPARATOR_VSYNC;

architecture Behavioral of COMPARATOR_VSYNC is
begin

    process(CLK)
    begin
        if rising_edge(CLK) then
            if nRST = '0' then
                V_SYNC <= '1';
            elsif unsigned(VCOUNTER_VALUE) < 2 then
                V_SYNC <= '0';   
            else
                V_SYNC <= '1';   
            end if;
        end if;
    end process;

end Behavioral;
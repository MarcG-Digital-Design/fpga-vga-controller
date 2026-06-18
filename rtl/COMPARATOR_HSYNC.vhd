library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity COMPARATOR_HSYNC is
    Port (
        CLK              : in  STD_LOGIC;
        nRST             : in  STD_LOGIC;
        HCOUNTER_VALUE   : in  STD_LOGIC_VECTOR(9 downto 0);
        H_SYNC           : out STD_LOGIC
    );
end COMPARATOR_HSYNC;

architecture Behavioral of COMPARATOR_HSYNC is
begin

    process(CLK)
    begin
        if rising_edge(CLK) then
            if nRST = '0' then
                H_SYNC <= '1';
            elsif unsigned(HCOUNTER_VALUE) < 96 then
                H_SYNC <= '0';   
            else
                H_SYNC <= '1';   
            end if;
        end if;
    end process;

end Behavioral;
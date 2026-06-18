library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity VSYNC_COUNT is
    Port (
        CLK              : in  STD_LOGIC;
	    nRST		     : in STD_LOGIC;
        HCOUNT_OVERFLOW  : in  STD_LOGIC;
        VCOUNTER_VALUE   : out STD_LOGIC_VECTOR(9 downto 0)
    );
end VSYNC_COUNT;

architecture Behavioral of VSYNC_COUNT is
    signal signal_count : UNSIGNED(9 downto 0) := (others => '0');
begin

	 process(CLK)
    begin
        if rising_edge(CLK) then
            if nRST = '0' then 
                signal_count <= (others => '0');
            elsif HCOUNT_OVERFLOW = '1' then
                if signal_count = 524 then
                    signal_count <= (others => '0');
                else
                    signal_count <= signal_count + 1;
                end if;
            end if;
        end if;
    end process;

    VCOUNTER_VALUE <= STD_LOGIC_VECTOR(signal_count);

end Behavioral;

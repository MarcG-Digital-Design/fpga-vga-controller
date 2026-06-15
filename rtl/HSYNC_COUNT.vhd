library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity HSYNC_COUNT is
    Port (
        CLK              : in  STD_LOGIC;
	nRST             : in  STD_LOGIC;
        HCOUNT_OVERFLOW  : out  STD_LOGIC;
        HCOUNTER_VALUE   : out STD_LOGIC_VECTOR(9 downto 0)
    );
end HSYNC_COUNT;

architecture Behavioral of HSYNC_COUNT is
    signal signal_count : UNSIGNED(9 downto 0) := (others => '0');
begin

    process(CLK)
    begin
        if rising_edge(CLK) then
				 if nRST = '0' then
					  signal_count <= (others => '0');
					  HCOUNT_OVERFLOW <= '0';
				 elsif signal_count = 799 then
					  signal_count <= (others => '0');
					  HCOUNT_OVERFLOW <= '1';
				 else
					  signal_count <= signal_count + 1;
					  HCOUNT_OVERFLOW <= '0';
				 end if;

        end if;
    end process;

    HCOUNTER_VALUE <= STD_LOGIC_VECTOR(signal_count);

end Behavioral;

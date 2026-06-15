library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity VSYNC_COUNT is
    Port (
        CLK              : in  STD_LOGIC;
        nRST             : in  STD_LOGIC;
        HCOUNT_OVERFLOW  : in  STD_LOGIC;
        VCOUNTER_VALUE   : out STD_LOGIC_VECTOR(9 downto 0)
    );
end VSYNC_COUNT;

architecture Behavioral of VSYNC_COUNT is
    signal signal_vcount : UNSIGNED(9 downto 0) := (others => '0');
begin

    process(CLK)
    begin
        if rising_edge(CLK) then
            if nRST = '0' then
                signal_vcount <= (others => '0');
            
            -- Increment only when horizontal line is finished (Clock Enable)
            elsif HCOUNT_OVERFLOW = '1' then 
                if signal_vcount = 524 then
                    signal_vcount <= (others => '0');
                else
                    signal_vcount <= signal_vcount + 1;
                end if;
            end if;
        end if;
    end process;

    VCOUNTER_VALUE <= STD_LOGIC_VECTOR(signal_vcount);

end Behavioral;
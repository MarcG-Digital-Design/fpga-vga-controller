library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Inferred single-port ROM (Quartus will synthesize this as an M9K block
-- on MAX10 thanks to the ram_init_file attribute and the registered read).
--
-- The contents are initialized from a .mif file at synthesis time.
-- Make sure the .mif file lives in the project root (next to the .qpf
-- and .qsf) or that its path is in the Quartus project search list.
--
-- Interface :
--   clock   : in  -- pixel clock (25 MHz here)
--   address : in  -- linear pixel address
--   q       : out -- 12-bit RGB pixel (registered, 1-cycle latency)
entity image_ram is
    generic (
        ADDR_BITS : integer := 16;
        DATA_BITS : integer := 12;
        INIT_FILE : string  := "PERROQUET.mif"
    );
    Port (
        clock   : in  STD_LOGIC;
        address : in  STD_LOGIC_VECTOR(ADDR_BITS - 1 downto 0);
        q       : out STD_LOGIC_VECTOR(DATA_BITS - 1 downto 0)
    );
end image_ram;

architecture rtl of image_ram is

    type rom_t is array (0 to 2**ADDR_BITS - 1)
                  of STD_LOGIC_VECTOR(DATA_BITS - 1 downto 0);

    signal rom : rom_t;

    -- Quartus-specific attribute : tells the synthesis tool to load the
    -- block RAM contents from the given .mif file.
    attribute ram_init_file : string;
    attribute ram_init_file of rom : signal is INIT_FILE;

begin

    process(clock)
    begin
        if rising_edge(clock) then
            q <= rom(to_integer(unsigned(address)));
        end if;
    end process;

end rtl;

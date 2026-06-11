library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Single-port ROM inferred from a .mif file (Intel Quartus altsyncram style).
-- Stores a 256x256 image encoded as 12-bit RGB (4 bits per channel).
entity image_rom is
    port (
        clk     : in  std_logic;
        addr    : in  std_logic_vector(15 downto 0);  -- 256*256 = 65536 words
        data    : out std_logic_vector(11 downto 0)   -- RRRR_GGGG_BBBB
    );
end entity image_rom;

architecture rtl of image_rom is

    type rom_t is array(0 to 65535) of std_logic_vector(11 downto 0);

    -- Quartus will replace this with Block RAM initialised from image.mif
    signal rom : rom_t;
    attribute ram_init_file : string;
    attribute ram_init_file of rom : signal is "../mif/image.mif";

begin

    process(clk)
    begin
        if rising_edge(clk) then
            data <= rom(to_integer(unsigned(addr)));
        end if;
    end process;

end architecture rtl;

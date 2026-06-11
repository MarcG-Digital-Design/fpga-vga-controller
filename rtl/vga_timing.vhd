library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_timing is
    port (
        clk_25      : in  std_logic;
        rst         : in  std_logic;
        hsync       : out std_logic;
        vsync       : out std_logic;
        display_en  : out std_logic;
        h_count     : out unsigned(9 downto 0);
        v_count     : out unsigned(9 downto 0)
    );
end entity vga_timing;

architecture rtl of vga_timing is

    -- Horizontal timing (pixels at 25 MHz)
    constant H_ACTIVE      : integer := 640;
    constant H_FRONT_PORCH : integer := 16;
    constant H_SYNC_PULSE  : integer := 96;
    constant H_BACK_PORCH  : integer := 48;
    constant H_TOTAL       : integer := 800;

    -- Vertical timing (lines)
    constant V_ACTIVE      : integer := 480;
    constant V_FRONT_PORCH : integer := 11;
    constant V_SYNC_PULSE  : integer := 2;
    constant V_BACK_PORCH  : integer := 31;
    constant V_TOTAL       : integer := 524;

    signal h_cnt : unsigned(9 downto 0) := (others => '0');
    signal v_cnt : unsigned(9 downto 0) := (others => '0');

begin

    process(clk_25)
    begin
        if rising_edge(clk_25) then
            if rst = '1' then
                h_cnt <= (others => '0');
                v_cnt <= (others => '0');
            else
                if h_cnt = H_TOTAL - 1 then
                    h_cnt <= (others => '0');
                    if v_cnt = V_TOTAL - 1 then
                        v_cnt <= (others => '0');
                    else
                        v_cnt <= v_cnt + 1;
                    end if;
                else
                    h_cnt <= h_cnt + 1;
                end if;
            end if;
        end if;
    end process;

    hsync      <= '0' when (h_cnt >= H_ACTIVE + H_FRONT_PORCH) and
                            (h_cnt <  H_ACTIVE + H_FRONT_PORCH + H_SYNC_PULSE) else '1';
    vsync      <= '0' when (v_cnt >= V_ACTIVE + V_FRONT_PORCH) and
                            (v_cnt <  V_ACTIVE + V_FRONT_PORCH + V_SYNC_PULSE) else '1';
    display_en <= '1' when (h_cnt < H_ACTIVE) and (v_cnt < V_ACTIVE) else '0';

    h_count <= h_cnt;
    v_count <= v_cnt;

end architecture rtl;

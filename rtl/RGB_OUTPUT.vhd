library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity RGB_OUTPUT is

    -- NOTE : Quartus does NOT allow referencing one generic from the default
    -- expression of another generic in the same interface list (it is a
    -- VHDL-2008 feature that the Quartus 18.1 analyzer rejects).
    -- ADDR_BITS is therefore exposed as a plain parameter ; the caller
    -- (TOP_QUARTUS or the testbench) is responsible for passing a value
    -- consistent with IMG_WIDTH * IMG_HEIGHT.
    generic(
        IMG_WIDTH  : integer := 256;  -- img width  in pixels
        IMG_HEIGHT : integer := 256;  -- img height in pixels
        ADDR_BITS  : integer := 16    -- log2(IMG_WIDTH * IMG_HEIGHT), set by the caller
    );

    Port (
        CLK              : in  STD_LOGIC;
        nRST             : in  STD_LOGIC;
        DISPLAY_SIGNAL   : in  STD_LOGIC;
        HCOUNTER_VALUE   : in  STD_LOGIC_VECTOR(9 downto 0);
        VCOUNTER_VALUE   : in  STD_LOGIC_VECTOR(9 downto 0);
        DATA   : in  STD_LOGIC_VECTOR(11 downto 0);
        address   : out  STD_LOGIC_VECTOR(ADDR_BITS - 1 downto 0);
        VGA_R   : out  STD_LOGIC_VECTOR(3 downto 0);
        VGA_G   : out  STD_LOGIC_VECTOR(3 downto 0);
        VGA_B   : out  STD_LOGIC_VECTOR(3 downto 0)
    );
end RGB_OUTPUT;

architecture Behavioral of RGB_OUTPUT is

        
        -- calcules des constantes
        constant H_centre : integer := (144 + 784) / 2; 
        constant V_centre : integer := (31 + 511) / 2;
        constant H_min : integer := H_centre - IMG_WIDTH / 2;
        constant V_min : integer := V_centre - IMG_HEIGHT / 2;
        constant H_max : integer := H_min + IMG_WIDTH -1;
        constant V_max : integer := V_min + IMG_HEIGHT-1;


begin
    process(CLK)
        variable h_rel : integer range 0 to IMG_WIDTH - 1;
        variable v_rel : integer range 0 to IMG_HEIGHT - 1;
    begin
        if rising_edge(CLK) then
            if nRST = '0' then
                VGA_R   <= (others => '0');
                VGA_G   <= (others => '0');
                VGA_B   <= (others => '0');
                address <= (others => '0');

            elsif DISPLAY_SIGNAL = '1' then
                if (to_integer(unsigned(VCOUNTER_VALUE)) >= V_min and
                    to_integer(unsigned(VCOUNTER_VALUE)) <= V_max and
                    to_integer(unsigned(HCOUNTER_VALUE)) >= H_min and
                    to_integer(unsigned(HCOUNTER_VALUE)) <= H_max) then
                    
                    v_rel := to_integer(unsigned(VCOUNTER_VALUE)) - V_min;
                    h_rel := to_integer(unsigned(HCOUNTER_VALUE)) - H_min;
                    
                    address <= std_logic_vector(to_unsigned(v_rel * IMG_WIDTH + h_rel, ADDR_BITS));
                    VGA_R <= DATA(11 downto 8);
                    VGA_G <= DATA( 7 downto 4);
                    VGA_B <= DATA( 3 downto 0);
                else
                    VGA_R <= (others => '0');
                    VGA_G <= (others => '0');
                    VGA_B <= (others => '0');
                end if;

            else
                VGA_R <= (others => '0');
                VGA_G <= (others => '0');
                VGA_B <= (others => '0');
            end if;
        end if;
    end process;
end Behavioral;
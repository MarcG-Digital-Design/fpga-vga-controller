library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity RGB_OUTPUT is


    -- consistent with IMG_WIDTH * IMG_HEIGHT.
    generic(
        IMG_WIDTH  : integer := 256;  -- img width  in pixels
        IMG_HEIGHT : integer := 256;  -- img height in pixels
        ADDR_BITS  : integer := 16    -- log2(IMG_WIDTH * IMG_HEIGHT), 
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

        
        -- Position of the image inside the 640x480 visible area.
        -- H_min is shifted 4 pixels earlier to compensate for the read
        -- pipeline (RGB_OUTPUT address register + altsyncram address
        -- register + altsyncram output register + RGB_OUTPUT VGA register
        -- = 4 clock cycles from HCOUNTER to VGA_R).
        constant PIPE_LATENCY : integer := 4;
        constant H_centre : integer := (144 + 784) / 2;
        constant V_centre : integer := (31 + 511) / 2;
        constant H_min : integer := H_centre - IMG_WIDTH / 2 - PIPE_LATENCY;
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
                    -- Visible area but outside the image window : output
                    -- black AND reset the ROM address so that the first
                    -- pixel of the next image line does not display stale
                    -- data from the end of the previous line.
                    VGA_R   <= (others => '0');
                    VGA_G   <= (others => '0');
                    VGA_B   <= (others => '0');
                    address <= (others => '0');
                end if;

            else
                -- Blanking (front porch, sync, back porch) : idem, reset
                -- both the VGA output and the ROM address.
                VGA_R   <= (others => '0');
                VGA_G   <= (others => '0');
                VGA_B   <= (others => '0');
                address <= (others => '0');
            end if;
        end if;
    end process;
end Behavioral;

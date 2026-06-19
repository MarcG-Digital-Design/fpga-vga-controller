library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use MATH

entity VGA_DISPLAY_RAM is
    generic (
        IMG_WIDTH  : integer := 256;
        IMG_HEIGHT : integer := 256;
        ADDR_BITS  : integer := 16
    );
    Port (
        CLK_25MHZ : in  STD_LOGIC;
        nRST      : in  STD_LOGIC;
        -- Interface RAM (exposée pour pouvoir la mocker en simu)
        RAM_ADDR  : out STD_LOGIC_VECTOR(ADDR_BITS - 1 downto 0);
        RAM_DATA  : in  STD_LOGIC_VECTOR(11 downto 0);
        -- Sortie VGA
        VGA_R     : out STD_LOGIC_VECTOR(3 downto 0);
        VGA_G     : out STD_LOGIC_VECTOR(3 downto 0);
        VGA_B     : out STD_LOGIC_VECTOR(3 downto 0);
        VGA_HS    : out STD_LOGIC;
        VGA_VS    : out STD_LOGIC
    );
end VGA_DISPLAY_RAM;

signal CLK_25MHZ
Signal nRST
signal HCOUNTER_VALUE
signal VCOUNTER_VALUE
signal HCOUNT_OVERFLOW
SIGNAL HSYNC
SIGNAL VSYNC
SIGNAL DISPLAY_SIGNAL 
SIGNAL ADRESS
SIGNAL DATA



architecture Behavioral of VGA_DISPLAY_RAM is
begin

    PORT MAP : VGA_DISPLAY_RAM
        port map (
            CLK             => CLK,
            nRST            => nRST,
            RAM_ADDR        => RAM_ADDR,
            RAM_DATA        => RAM_DATA,
            VGA_R           => VGA_R,
            VGA_G           => VGA_G,
            VGA_B           => VGA_B,
            VGA_HS          => VGA_HS,
            VGA_VS          => VGA_VS
            
        );



end sim;
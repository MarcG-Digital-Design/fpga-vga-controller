# fpga-vga-controller

# VGA Controller with ROM Image Display

## Overview
A custom VGA controller : 
The goal was to design a VGA controller from scratch on an  DE10-Lite FPGA to display images stored in internal ROM.

## Architecture
* **Memory Management:** The image data is converted into a `.mif` file and mapped into the FPGA's internal ROM.
* **VGA Timing:** Implementation of a custom timing generator (640x480 @ 60Hz) to drive the horizontal and vertical synchronization signals (HSYNC/VSYNC).
* **Data Flow:** The pixel data is read synchronously from the ROM based on the active display coordinates (H_count, V_count) and sent to the RGB DAC interface.

## Technical skills
* **Video Timing & Synchronization:** Precise implementation of VGA standards (640x480 @ 60Hz), including HSYNC, VSYNC, and Blanking intervals management.
* **Clock Management:** Use of PLLs to generate the required pixel clock frequency from the system master clock.
* **Resource Optimization:** Use of embedded block RAM for image storage.
* **Timing Constraints:** Adherence to standard VGA signaling protocols.
* **Simulation:** Full verification of the video pipeline using testbenches.

## 📁 Repository Structure
* `/rtl`: VHDL source files (Controller, ROM, Clock Divider).
* `/sim`: Simulation testbench for timing validation.
* `/mif`: Memory initialization files for image storage.
* `/doc`: Project documentation.




# fpga-vga-controller

A custom VGA controller implemented in VHDL on an Intel DE10-Lite (MAX10) FPGA — displays a static image stored in internal Block RAM at 640×480 @ 60 Hz.

---

## Overview

The goal of this project was to design a VGA controller from scratch, covering the full RTL cycle: architecture definition, VHDL implementation, simulation with testbenches, and real hardware validation.

The image is pre-processed in MATLAB, converted into a 12-bit `.mif` file, and loaded into the FPGA's internal ROM at synthesis time.

---

## Architecture

**Memory Management**
The image data is converted into a `.mif` file (Memory Initialization File) and mapped into the FPGA's internal ROM. A 16-bit address bus is built by concatenating the horizontal and vertical pixel counters, with an offset applied to center the 256×256 image on the 640×480 display.

**VGA Timing**
Custom timing generator producing HSYNC, VSYNC and DISPLAY_SIGNAL signals — no external IP used. Clocked at 25 MHz (derived from the 50 MHz system clock via PLL).

| | Active | Front Porch | Sync Pulse | Back Porch | Total |
|---|---|---|---|---|---|
| Horizontal | 640 | 16 | 96 | 48 | **800** |
| Vertical | 480 | 11 | 2 | 31 | **524** |

**Data Flow**
Pixel data is read synchronously from the ROM using the active display coordinates (H_count, V_count) and sent to the 12-bit resistor-ladder VGA DAC on the board.

---

## Repository Structure

```
fpga-vga-controller/
├── rtl/        # VHDL source files
├── sim/        # Simulation testbenches
├── mif/        # Memory initialization files
├── scripts/    # MATLAB image conversion script (BMP → MIF)
└── doc/        # Project report and hardware validation photos
```

---

## Skills

`VHDL` · `RTL Design` · `VGA Timing` · `Block RAM / ROM` · `PLL / Clock Management` · `Testbench / Simulation` · `Intel Quartus Prime` · `MATLAB`


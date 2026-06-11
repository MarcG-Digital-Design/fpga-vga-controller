# fpga-vga-controller

# VGA Controller with ROM Image Display

## Overview
A custom VGA controller : The goal was to design a VGA controller from scratch on an  DE10-Lite FPGA to display images stored in internal ROM.

## Architecture
* **Memory Management:** The image data is converted into a `.mif` file and mapped into the FPGA's internal ROM.
* **VGA Timing:** Implementation of a custom timing generator (640x480 @ 60Hz) to drive the horizontal and vertical synchronization signals (HSYNC/VSYNC).
* **Data Flow:** The pixel data is read synchronously from the ROM based on the active display coordinates (H_count, V_count) and sent to the RGB DAC interface.

## Technical Highlights
* **Resource Optimization:** Use of embedded block RAM for image storage.
* **Timing Constraints:** Adherence to standard VGA signaling protocols.
* **Simulation:** Full verification of the video pipeline using testbenches.

## 📁 Repository Structure
* `/rtl`: VHDL source files (Controller, ROM, Clock Divider).
* `/sim`: Simulation testbench for timing validation.
* `/mif`: The memory initialization file containing the pixel data.

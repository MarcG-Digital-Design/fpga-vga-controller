# Simple GHDL build/test flow for the FPGA VGA controller.
#
# Usage:
#   make testvsync   -> VSYNC_COUNT self-checking testbench (PASS/FAIL)
#   make wavevsync   -> VSYNC_COUNT manual testbench + GTKWave
#   make testhsync   -> HSYNC_COUNT self-checking testbench (PASS/FAIL)
#   make wavehsync   -> HSYNC_COUNT manual testbench + GTKWave
#   make testtdisp   -> COMPARATOR_TDISP self-checking testbench (PASS/FAIL)
#   make testhcmp    -> COMPARATOR_HSYNC self-checking testbench (PASS/FAIL)
#   make testvcmp    -> COMPARATOR_VSYNC self-checking testbench (PASS/FAIL)
#   make testrgboutput -> RGB_OUTPUT self-checking testbench (PASS/FAIL)
#   make testtop     -> VGA_DISPLAY_RAM integration testbench (PASS/FAIL)
#   make test        -> run every self-checking testbench (unit + integration)
#   make clean       -> remove generated files
#
# Exit code of `make test*` is non-zero if any assertion fails,
# so it can be wired straight into CI later.

GHDL      := ghdl
GHDLFLAGS := --std=08
RTL       := ../rtl
SIM       := .

# Default target: run all self-checking tests
all: test

# Aggregate self-check target (handy for CI)
test: testvsync testhsync testtdisp testhcmp testvcmp testrgboutput testtop

# ---- VSYNC_COUNT ------------------------------------------------------------
# Self-checking test (Etape B)
testvsync:
	$(GHDL) -a $(GHDLFLAGS) $(RTL)/VSYNC_COUNT.vhd $(SIM)/VSYNC_COUNT_selfcheck_tb.vhd
	$(GHDL) -e $(GHDLFLAGS) VSYNC_COUNT_selfcheck_tb
	$(GHDL) -r $(GHDLFLAGS) VSYNC_COUNT_selfcheck_tb --assert-level=error

# Manual waveform inspection (Etape A)
wavevsync:
	$(GHDL) -a $(GHDLFLAGS) $(RTL)/VSYNC_COUNT.vhd $(SIM)/VSYNC_COUNT_tb.vhd
	$(GHDL) -e $(GHDLFLAGS) VSYNC_COUNT_tb
	$(GHDL) -r $(GHDLFLAGS) VSYNC_COUNT_tb --vcd=vsync.vcd --stop-time=1ms
	gtkwave vsync.vcd

# ---- HSYNC_COUNT ------------------------------------------------------------
# Self-checking test
testhsync:
	$(GHDL) -a $(GHDLFLAGS) $(RTL)/HSYNC_COUNT.vhd $(SIM)/HSYNC_COUNT_selfcheck_tb.vhd
	$(GHDL) -e $(GHDLFLAGS) HSYNC_COUNT_selfcheck_tb
	$(GHDL) -r $(GHDLFLAGS) HSYNC_COUNT_selfcheck_tb --assert-level=error

# Manual waveform inspection 
wavehsync:
	$(GHDL) -a $(GHDLFLAGS) $(RTL)/HSYNC_COUNT.vhd $(SIM)/HSYNC_COUNT_tb.vhd
	$(GHDL) -e $(GHDLFLAGS) HSYNC_COUNT_tb
	$(GHDL) -r $(GHDLFLAGS) HSYNC_COUNT_tb --vcd=hsync.vcd --stop-time=1ms
	gtkwave hsync.vcd

# ---- COMPARATOR_TDISP-----------------------------------------------------------
testtdisp:
	$(GHDL) -a $(GHDLFLAGS) $(RTL)/COMPARATOR_TDISP.vhd $(SIM)/COMPARATOR_TDISP_selfcheck_tb.vhd
	$(GHDL) -e $(GHDLFLAGS) COMPARATOR_TDISP_selfcheck_tb
	$(GHDL) -r $(GHDLFLAGS) COMPARATOR_TDISP_selfcheck_tb --assert-level=error

# ---- COMPARATOR_HSYNC-------------------------------------------------------
testhcmp:
	$(GHDL) -a $(GHDLFLAGS) $(RTL)/COMPARATOR_HSYNC.vhd $(SIM)/COMPARATOR_HSYNC_selfcheck_tb.vhd
	$(GHDL) -e $(GHDLFLAGS) COMPARATOR_HSYNC_selfcheck_tb
	$(GHDL) -r $(GHDLFLAGS) COMPARATOR_HSYNC_selfcheck_tb --assert-level=error

# ---- COMPARATOR_VSYNC ------------------------------------------------------
testvcmp:
	$(GHDL) -a $(GHDLFLAGS) $(RTL)/COMPARATOR_VSYNC.vhd $(SIM)/COMPARATOR_VSYNC_selfcheck_tb.vhd
	$(GHDL) -e $(GHDLFLAGS) COMPARATOR_VSYNC_selfcheck_tb
	$(GHDL) -r $(GHDLFLAGS) COMPARATOR_VSYNC_selfcheck_tb --assert-level=error

# ---- RGB_OUTPUT ------------------------------------------------------
testrgboutput:
	$(GHDL) -a $(GHDLFLAGS) $(RTL)/RGB_OUTPUT.vhd $(SIM)/RGB_OUTPUT_selfcheck_tb.vhd
	$(GHDL) -e $(GHDLFLAGS) RGB_OUTPUT_selfcheck_tb
	$(GHDL) -r $(GHDLFLAGS) RGB_OUTPUT_selfcheck_tb --assert-level=error

# ---- VGA_DISPLAY_RAM (top-level integration test) -------------------------
# Runs the full synthesis top with a behavioural mock of the Quartus IP_ROM
# (sim/IP_ROM.vhd) and the clk_divider, simulates a bit over one frame
# (~17 ms) and checks that HSYNC and VSYNC pulse at the expected rate.
testtop:
	$(GHDL) -a $(GHDLFLAGS) $(RTL)/HSYNC_COUNT.vhd $(RTL)/VSYNC_COUNT.vhd \
	                        $(RTL)/COMPARATOR_HSYNC.vhd $(RTL)/COMPARATOR_VSYNC.vhd \
	                        $(RTL)/COMPARATOR_TDISP.vhd $(RTL)/RGB_OUTPUT.vhd \
	                        $(RTL)/clk_divider.vhd \
	                        $(SIM)/IP_ROM.vhd \
	                        $(RTL)/VGA_DISPLAY_RAM.vhd \
	                        $(SIM)/VGA_DISPLAY_RAM_selfcheck_tb.vhd
	$(GHDL) -e $(GHDLFLAGS) VGA_DISPLAY_RAM_selfcheck_tb
	$(GHDL) -r $(GHDLFLAGS) VGA_DISPLAY_RAM_selfcheck_tb --stop-time=20ms --assert-level=failure


clean:
	$(GHDL) --remove
	rm -f *.vcd

.PHONY: all test testvsync wavevsync testhsync wavehsync testtdisp testhcmp testvcmp testrgboutput testtop clean
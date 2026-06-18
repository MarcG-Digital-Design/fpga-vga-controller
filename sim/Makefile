# Simple GHDL build/test flow for the FPGA VGA controller.
#
# Usage:
#   make testvsync   -> VSYNC_COUNT self-checking testbench (PASS/FAIL)
#   make wavevsync   -> VSYNC_COUNT manual testbench + GTKWave
#   make testhsync   -> HSYNC_COUNT self-checking testbench (PASS/FAIL)
#   make wavehsync   -> HSYNC_COUNT manual testbench + GTKWave
#   make test        -> run every self-checking testbench
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
test: testvsync testhsync

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
# Self-checking test (Etape B)
testhsync:
	$(GHDL) -a $(GHDLFLAGS) $(RTL)/HSYNC_COUNT.vhd $(SIM)/HSYNC_COUNT_selfcheck_tb.vhd
	$(GHDL) -e $(GHDLFLAGS) HSYNC_COUNT_selfcheck_tb
	$(GHDL) -r $(GHDLFLAGS) HSYNC_COUNT_selfcheck_tb --assert-level=error

# Manual waveform inspection (Etape A)
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

clean:
	$(GHDL) --remove
	rm -f *.vcd

.PHONY: all test testvsync wavevsync testhsync wavehsync clean

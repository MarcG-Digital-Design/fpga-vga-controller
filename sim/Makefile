# Simple GHDL build/test flow for the FPGA VGA controller.
#
# Usage:
#   make test     -> run the self-checking testbench (PASS/FAIL)
#   make wave     -> run the manual testbench and open GTKWave
#   make clean    -> remove generated files
#
# Exit code of `make test` is non-zero if any assertion fails,
# so it can be wired straight into CI later.

GHDL      := ghdl
GHDLFLAGS := --std=08
RTL       := ../rtl
SIM       := .

# Default target
all: test

# ---- Self-checking test (Etape B) -------------------------------------------
test:
	$(GHDL) -a $(GHDLFLAGS) $(RTL)/VSYNC_COUNT.vhd $(SIM)/VSYNC_COUNT_selfcheck_tb.vhd
	$(GHDL) -e $(GHDLFLAGS) VSYNC_COUNT_selfcheck_tb
	$(GHDL) -r $(GHDLFLAGS) VSYNC_COUNT_selfcheck_tb --assert-level=error

# ---- Manual waveform inspection (Etape A) -----------------------------------
wave:
	$(GHDL) -a $(GHDLFLAGS) $(RTL)/VSYNC_COUNT.vhd $(SIM)/VSYNC_COUNT_tb.vhd
	$(GHDL) -e $(GHDLFLAGS) VSYNC_COUNT_tb
	$(GHDL) -r $(GHDLFLAGS) VSYNC_COUNT_tb --vcd=vsync.vcd --stop-time=1ms
	gtkwave vsync.vcd

# ---- Housekeeping -----------------------------------------------------------
clean:
	$(GHDL) --remove
	rm -f *.vcd

.PHONY: all test wave clean

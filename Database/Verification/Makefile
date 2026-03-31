#============================================================================
# Makefile for AES IP Verification
#============================================================================

# Simulator selection
SIM ?= iverilog

# Directories
RTL_DIR = ../RTL
TB_DIR = .
ENV_DIR = ./Env
TC_DIR = ./Testcases

# Test selection (default: smoke)
TEST ?= tc_smoke

# Test path
TEST_PATH = $(TC_DIR)/directed/$(TEST).sv

# UVM path
UVM_DIR = $(ENV_DIR)/uvm

# Output (to Temp directory)
OUT_DIR = ../../Temp/VCS
VCD_FILE = $(OUT_DIR)/$(TEST).vcd

#==============================================================================
# Icarus Verilog (Open Source)
#==============================================================================
ifeq ($(SIM),iverilog)

IVERILOG = iverilog
VVP = vvp

COMP_FLAGS = -g2012 -Wall \
	-y $(RTL_DIR) \
	-I $(RTL_DIR) \
	-I $(ENV_DIR)/tb

.PHONY: compile sim view clean lint regression help

compile:
	@mkdir -p $(OUT_DIR)
	@echo "Compiling $(TEST)..."
	$(IVERILOG) $(COMP_FLAGS) -o $(OUT_DIR)/$(TEST).out \
		$(ENV_DIR)/tb/tb_base.sv \
		$(TEST_PATH)

sim: compile
	@echo "Running $(TEST)..."
	cd $(OUT_DIR) && $(VVP) $(TEST).out

view:
	gtkwave $(VCD_FILE) &

lint:
	@echo "Running lint check on all RTL..."
	@for f in $(RTL_DIR)/*.v; do \
		echo "=== Lint: $$f ==="; \
		$(IVERILOG) $(COMP_FLAGS) -o /dev/null $$f 2>&1 || true; \
	done

endif

#==============================================================================
# Common targets
#==============================================================================
.PHONY: all clean regression help list-tests

all: sim

clean:
	rm -rf ../../Temp/VCS/*
	rm -f transcript

regression:
	./Regression/scripts/run_regression.sh

list-tests:
	@echo "Available tests:"
	@ls -1 $(TC_DIR)/directed/*.sv | xargs -n1 basename | sed 's/.sv//' | sed 's/^/  - /'

help:
	@echo "AES IP Verification Makefile"
	@echo ""
	@echo "Usage: make [TEST=test_name] [target]"
	@echo ""
	@echo "Tests (TEST=):"
	@echo "  tc_smoke        - Basic smoke test"
	@echo "  tc_ecb_nist     - ECB mode NIST vectors"
	@echo "  tc_cbc_nist     - CBC mode NIST vectors"
	@echo "  tc_ctr_nist     - CTR mode NIST vectors"
	@echo "  tc_cts_boundary - CTS boundary (1-127 bit)"
	@echo ""
	@echo "Targets:"
	@echo "  compile     - Compile testbench"
	@echo "  sim         - Run simulation (default: tc_smoke)"
	@echo "  view        - Open waveform viewer"
	@echo "  lint        - Run lint check on all RTL"
	@echo "  regression  - Run full regression"
	@echo "  list-tests  - Show all available tests"
	@echo "  clean       - Clean output files"
	@echo ""
	@echo "Examples:"
	@echo "  make TEST=tc_smoke sim"
	@echo "  make TEST=tc_ecb_nist sim"
	@echo "  make regression"
	@echo "  make lint"

#============================================================================
# Makefile for AES IP Verification
#============================================================================

# Simulator selection
SIM ?= iverilog

# Directories
RTL_DIR = ../RTL
TB_DIR = .

# Output
OUT_DIR = ./out
VCD_FILE = $(OUT_DIR)/aes_simple.vcd

#==============================================================================
# Icarus Verilog (Open Source)
#==============================================================================
ifeq ($(SIM),iverilog)

IVERILOG = iverilog
VVP = vvp

COMP_FLAGS = -g2012 -Wall \
	-y $(RTL_DIR) \
	-I $(RTL_DIR)

.PHONY: compile sim view clean

compile:
	mkdir -p $(OUT_DIR)
	$(IVERILOG) $(COMP_FLAGS) -o $(OUT_DIR)/sim.out \
		$(RTL_DIR)/aes_top.v \
		$(TB_DIR)/tb_simple.sv

sim: compile
	$(VVP) $(OUT_DIR)/sim.out

view:
	gtkwave $(VCD_FILE) &

lint:
	@for f in $(RTL_DIR)/*.v; do \
		echo "=== Lint: $$f ==="; \
		$(IVERILOG) $(COMP_FLAGS) -o /dev/null $$f 2>&1 || true; \
	done

endif

#==============================================================================
# Verilator
#==============================================================================
ifeq ($(SIM),verilator)

VERILATOR = verilator

COMP_FLAGS = --cc --exe --build --trace \
	-y $(RTL_DIR) \
	-Mdir $(OUT_DIR)/obj_dir

.PHONY: compile sim clean

compile:
	mkdir -p $(OUT_DIR)
	$(VERILATOR) $(COMP_FLAGS) \
		--top-module tb_simple \
		$(RTL_DIR)/aes_top.v \
		$(TB_DIR)/tb_simple.sv

sim: compile
	$(OUT_DIR)/obj_dir/Vtb_simple

endif

#==============================================================================
# Common targets
#==============================================================================
.PHONY: all clean help

all: compile sim

clean:
	rm -rf $(OUT_DIR)
	rm -f *.vcd
	rm -f transcript

help:
	@echo "AES IP Verification Makefile"
	@echo ""
	@echo "Usage: make [SIM=simulator] [target]"
	@echo ""
	@echo "Simulators:"
	@echo "  SIM=iverilog  - Icarus Verilog (default)"
	@echo "  SIM=verilator - Verilator"
	@echo ""
	@echo "Targets:"
	@echo "  compile - Compile testbench"
	@echo "  sim     - Run simulation"
	@echo "  view    - Open waveform viewer"
	@echo "  lint    - Run lint check on all RTL"
	@echo "  clean   - Clean output files"
	@echo "  all     - Compile and simulate"
	@echo ""
	@echo "Examples:"
	@echo "  make SIM=iverilog compile"
	@echo "  make SIM=iverilog sim"
	@echo "  make lint"

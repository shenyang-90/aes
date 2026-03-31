#============================================================================
# Makefile for AES IP UVM Verification
#============================================================================

# Simulator selection
SIM ?= iverilog

# Directories
RTL_DIR = ../../RTL
UVM_DIR = .

# Test selection
TEST ?= aes_smoke_test

# Output
OUT_DIR = ../../Temp/VCS
VCD_FILE = $(OUT_DIR)/aes_tb.vcd

#==============================================================================
# Icarus Verilog (Open Source)
#==============================================================================
ifeq ($(SIM),iverilog)

IVERILOG = iverilog
VVP = vvp

COMP_FLAGS = -g2012 -Wall \
	-y $(RTL_DIR) \
	-I $(RTL_DIR) \
	-DUVM_NO_DPI \
	-DUVM_CMDLINE_NO_DPI

SIM_FLAGS = -n $(VCD_FILE)

.PHONY: compile sim view clean

compile:
	mkdir -p $(OUT_DIR)
	$(IVERILOG) $(COMP_FLAGS) -o $(OUT_DIR)/sim.out \
		$(RTL_DIR)/aes_top.v \
		$(UVM_DIR)/tb_top.sv

sim: compile
	$(VVP) $(SIM_FLAGS) $(OUT_DIR)/sim.out +UVM_TESTNAME=$(TEST)

view:
	gtkwave $(VCD_FILE) &

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
		--top-module aes_top \
		$(RTL_DIR)/aes_top.v

sim: compile
	$(OUT_DIR)/obj_dir/Vaes_top +UVM_TESTNAME=$(TEST)

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
	@echo "AES IP UVM Verification Makefile"
	@echo ""
	@echo "Usage: make [SIM=simulator] [TEST=test_name] [target]"
	@echo ""
	@echo "Simulators:"
	@echo "  SIM=iverilog  - Icarus Verilog (default)"
	@echo "  SIM=verilator - Verilator"
	@echo ""
	@echo "Tests:"
	@echo "  TEST=aes_smoke_test  - Basic smoke test"
	@echo "  TEST=aes_ecb_test    - ECB mode test"
	@echo "  TEST=aes_cbc_test    - CBC mode test"
	@echo "  TEST=aes_ctr_test    - CTR mode test"
	@echo "  TEST=aes_xts_test    - XTS mode test"
	@echo "  TEST=aes_cts_test    - CTS mode test"
	@echo "  TEST=aes_stress_test - Stress test"
	@echo ""
	@echo "Targets:"
	@echo "  compile - Compile testbench"
	@echo "  sim     - Run simulation"
	@echo "  view    - Open waveform viewer"
	@echo "  clean   - Clean output files"
	@echo "  all     - Compile and simulate"
	@echo ""
	@echo "Examples:"
	@echo "  make SIM=iverilog TEST=aes_smoke_test sim"
	@echo "  make SIM=verilator TEST=aes_ecb_test all"

#============================================================================
# Makefile for AES IP Verification - Multi-Simulator Support
# Supports: Verilator (default), VCS
# Debug: Verdi
# Coverage: lcov (Verilator), URG (VCS)
#============================================================================

# Tool paths (adjust based on your installation)
VERILATOR = /usr/local/bin/verilator
VERILATOR_COVERAGE = /usr/local/bin/verilator_coverage
VCS = vcs
VERDI = verdi
URG = urg

# Directories
VERIF_DIR = .
RTL_DIR = ../RTL
ENV_DIR = ./Env
VERILATOR_DIR = $(ENV_DIR)/verilator
TC_DIR = ./Testcases/directed

# VCS directories
VCS_DIR = ../../Temp/VCS
VCS_COV_DIR = $(VCS_DIR)/coverage
VCS_LOG_DIR = $(VCS_DIR)/logs

# Output directories - All temporary files in Temp/
TEMP_DIR = ../../Temp/Verilator
COV_DIR = $(TEMP_DIR)/coverage
REPORT_DIR = $(TEMP_DIR)/html
LOG_DIR = $(TEMP_DIR)/logs
SUMMARY_FILE = ../../ProjectMgmt/Reviews/IDR/COVERAGE_REPORT.md

# Verilator flags
VERILATOR_FLAGS = --cc --trace --timing \
                  --coverage-line --coverage-toggle \
                  --public-flat-rw \
                  -Wno-PINMISSING -Wno-WIDTHTRUNC -Wno-WIDTHEXPAND \
                  -Wno-LATCH -Wno-CASEINCOMPLETE \
                  -Mdir $(TEMP_DIR)/obj_dir \
                  -CFLAGS "-std=c++20 -O2" \
                  -LDFLAGS "-lpthread"

# Testbench files
TB_COVERAGE = $(VERILATOR_DIR)/tb_coverage.sv
SIM_MAIN = $(VERILATOR_DIR)/sim_main.cpp

# Default target
.PHONY: all compile run coverage report clean help

all: compile run coverage report

# Setup directories
setup:
	@mkdir -p $(TEMP_DIR) $(COV_DIR) $(REPORT_DIR) $(LOG_DIR)
	@echo "[SETUP] Directories ready"

# Compile with Verilator
compile: setup
	@echo "========================================"
	@echo "Compiling with Verilator..."
	@echo "========================================"
	unset VERILATOR_ROOT && \
	$(VERILATOR) $(VERILATOR_FLAGS) --build --exe --top-module tb_coverage \
		$(RTL_DIR)/*.v \
		$(TB_COVERAGE) \
		$(SIM_MAIN) \
		2>&1 | tee $(LOG_DIR)/compile.log | tail -20
	@echo "[COMPILE] Done"

# Run simulation
run:
	@echo "========================================"
	@echo "Running simulation..."
	@echo "========================================"
	cd $(TEMP_DIR) && ./obj_dir/Vtb_coverage 2>&1 | tee $(LOG_DIR)/simulation.log
	@echo "[RUN] Done"

# Collect coverage
coverage:
	@echo "========================================"
	@echo "Processing coverage..."
	@echo "========================================"
	@if [ -f $(TEMP_DIR)/coverage.dat ]; then \
		cp $(TEMP_DIR)/coverage.dat $(COV_DIR)/; \
		$(VERILATOR_COVERAGE) --write-info $(COV_DIR)/coverage.info \
			$(COV_DIR)/coverage.dat 2>&1 | tee $(LOG_DIR)/coverage.log; \
		echo "[COVERAGE] Data saved to $(COV_DIR)"; \
	else \
		echo "[WARN] No coverage.dat found"; \
	fi

# Generate HTML report
report: coverage
	@echo "========================================"
	@echo "Generating report..."
	@echo "========================================"
	@if command -v genhtml >/dev/null 2>&1; then \
		genhtml $(COV_DIR)/coverage.info -o $(REPORT_DIR) \
			--ignore-errors source 2>&1 | tee $(LOG_DIR)/report.log; \
		echo "[REPORT] HTML: $(REPORT_DIR)/index.html"; \
	else \
		echo "[WARN] genhtml not found, install lcov for HTML reports"; \
	fi

# Full coverage flow: compile + run + coverage + report
cov: compile run coverage report
	@echo ""
	@echo "========================================"
	@echo "Coverage Collection Complete"
	@echo "========================================"
	@tail -5 $(LOG_DIR)/report.log 2>/dev/null || true
	@echo ""
	@echo "[SUMMARY] Generating summary report..."
	@echo "# AES IP Coverage Report" > $(SUMMARY_FILE)
	@echo "" >> $(SUMMARY_FILE)
	@echo "**Generated**: $$(date '+%Y-%m-%d %H:%M:%S')" >> $(SUMMARY_FILE)
	@echo "" >> $(SUMMARY_FILE)
	@echo "## Summary" >> $(SUMMARY_FILE)
	@echo "" >> $(SUMMARY_FILE)
	@echo "| Item | Location |" >> $(SUMMARY_FILE)
	@echo "|------|----------|" >> $(SUMMARY_FILE)
	@echo "| Coverage Data | $(COV_DIR)/ |" >> $(SUMMARY_FILE)
	@echo "| HTML Report | $(REPORT_DIR)/index.html |" >> $(SUMMARY_FILE)
	@echo "| Full Logs | $(LOG_DIR)/ |" >> $(SUMMARY_FILE)
	@echo "" >> $(SUMMARY_FILE)
	@echo "## Notes" >> $(SUMMARY_FILE)
	@echo "" >> $(SUMMARY_FILE)
	@echo "All temporary coverage data is stored in Temp/ directory." >> $(SUMMARY_FILE)
	@echo "This summary is the only file written to ProjectMgmt/Reviews/IDR/." >> $(SUMMARY_FILE)
	@echo "[SUMMARY] Report: $(SUMMARY_FILE)"

# Quick run (using existing compile)
quick:
	@echo "========================================"
	@echo "Quick run (no recompile)..."
	@echo "========================================"
	cd $(TEMP_DIR) && ./obj_dir/Vtb_coverage

# Clean build artifacts
clean:
	@echo "Cleaning..."
	rm -rf $(TEMP_DIR)/obj_dir
	rm -f $(TEMP_DIR)/*.vcd $(TEMP_DIR)/*.fst
	rm -f $(TEMP_DIR)/coverage.dat
	@echo "[CLEAN] Build artifacts removed"

# Clean everything including reports
clean-all: clean
	@echo "Cleaning all generated files..."
	rm -rf $(COV_DIR)/* $(REPORT_DIR)/* $(LOG_DIR)/*
	@echo "[CLEAN-ALL] All cleaned"

# View coverage report
view:
	@if [ -f $(REPORT_DIR)/index.html ]; then \
		echo "Opening $(REPORT_DIR)/index.html"; \
		firefox $(REPORT_DIR)/index.html & \
	else \
		echo "Report not found. Run 'make report' first."; \
	fi

# List available testcases
list-tests:
	@echo "Available testcases ($(shell ls $(TC_DIR)/*.sv | wc -l)):"
	@ls -1 $(TC_DIR)/*.sv | xargs -n1 basename | sed 's/.sv$$//' | nl

# VCS Compile
vcs-compile: setup-vcs
	@echo "========================================"
	@echo "Compiling with VCS..."
	@echo "========================================"
	cd $(VCS_DIR) && $(VCS) -full64 -sverilog -debug_access+all -kdb \
		-timescale=1ns/1ps \
		+incdir+$(TC_DIR) \
		+incdir+$(ENV_DIR)/tb \
		-CFLAGS "-DVCS" \
		-f $(VERIF_DIR)/rtl.f \
		$(TB_COVERAGE) \
		-o simv \
		2>&1 | tee $(VCS_LOG_DIR)/compile.log
	@echo "[VCS COMPILE] Done"

# VCS Run
vcs-run:
	@echo "========================================"
	@echo "Running VCS simulation..."
	@echo "========================================"
	cd $(VCS_DIR) && ./simv +vcs+lic+wait \
		2>&1 | tee $(VCS_LOG_DIR)/simulation.log
	@echo "[VCS RUN] Done"

# VCS Coverage Collection
vcs-coverage:
	@echo "========================================"
	@echo "Collecting VCS coverage..."
	@echo "========================================"
	cd $(VCS_DIR) && $(URG) -dir simv.vdb \
		-format both \
		-report $(VCS_COV_DIR) \
		-togl $(RTL_DIR)/*.v \
		-line $(RTL_DIR)/*.v \
		-cond $(RTL_DIR)/*.v \
		-fsm $(RTL_DIR)/*.v \
		2>&1 | tee $(VCS_LOG_DIR)/coverage.log
	@echo "[VCS COVERAGE] Report: $(VCS_COV_DIR)/dashboard.txt"

# VCS Full Flow
vcs-cov: vcs-compile vcs-run vcs-coverage
	@echo ""
	@echo "========================================"
	@echo "VCS Coverage Collection Complete"
	@echo "========================================"
	@echo "Coverage Report: $(VCS_COV_DIR)/dashboard.txt"

# Verdi Debug - Open waveform
verdi:
	@echo "========================================"
	@echo "Opening Verdi..."
	@echo "========================================"
	@if [ -f $(VCS_DIR)/simv.vdb/snps/fdebug/verdi.db ]; then \
		cd $(VCS_DIR) && $(VERDI) -dbdir simv.vdb & \
	elif [ -f $(TEMP_DIR)/waveform.vcd ]; then \
		$(VERDI) -ssf $(TEMP_DIR)/waveform.vcd -dbdir $(VCS_DIR)/simv.vdb & \
	else \
		echo "[ERROR] No waveform database found. Run 'make vcs-run' first."; \
	fi

# Verdi Coverage - Open coverage
verdi-cov:
	@echo "========================================"
	@echo "Opening Verdi Coverage..."
	@echo "========================================"
	@if [ -d $(VCS_DIR)/simv.vdb ]; then \
		$(VERDI) -cov -covdir $(VCS_DIR)/simv.vdb & \
	else \
		echo "[ERROR] No coverage database found. Run 'make vcs-cov' first."; \
	fi

# Setup VCS directories
setup-vcs:
	@mkdir -p $(VCS_DIR) $(VCS_COV_DIR) $(VCS_LOG_DIR)
	@echo "[SETUP] VCS directories ready"

# Clean VCS artifacts
clean-vcs:
	@echo "Cleaning VCS artifacts..."
	rm -rf $(VCS_DIR)/simv* $(VCS_DIR)/csrc $(VCS_DIR)/vc_hdrs.h
	rm -rf $(VCS_DIR)/*.vpd $(VCS_DIR)/*.vcd
	rm -rf $(VCS_DIR)/verdiLog $(VCS_DIR)/novas*
	@echo "[CLEAN-VCS] Done"

# Help
help:
	@echo "========================================"
	@echo "AES IP Verification Makefile"
	@echo "========================================"
	@echo ""
	@echo "=== Verilator Targets ==="
	@echo "  make compile      - Compile with Verilator"
	@echo "  make run          - Run simulation"
	@echo "  make coverage     - Collect coverage data"
	@echo "  make report       - Generate HTML report"
	@echo "  make cov          - Full flow (compile+run+coverage+report)"
	@echo "  make quick        - Quick run (no recompile)"
	@echo ""
	@echo "=== VCS Targets ==="
	@echo "  make vcs-compile  - Compile with VCS"
	@echo "  make vcs-run      - Run VCS simulation"
	@echo "  make vcs-coverage - Collect VCS coverage"
	@echo "  make vcs-cov      - Full VCS flow"
	@echo ""
	@echo "=== Verdi Targets ==="
	@echo "  make verdi        - Open Verdi waveform viewer"
	@echo "  make verdi-cov    - Open Verdi coverage viewer"
	@echo ""
	@echo "=== Utility Targets ==="
	@echo "  make clean        - Clean build artifacts"
	@echo "  make clean-all    - Clean everything including reports"
	@echo "  make clean-vcs    - Clean VCS artifacts"
	@echo "  make view         - Open coverage report in browser"
	@echo "  make list-tests   - List all testcases"
	@echo "  make help         - Show this help"
	@echo ""
	@echo "Output locations:"
	@echo "  Verilator: $(TEMP_DIR)"
	@echo "  VCS:       $(VCS_DIR)"
	@echo "  Summary:   $(SUMMARY_FILE)"

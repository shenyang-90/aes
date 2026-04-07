#============================================================================
# Makefile for AES IP Verification - Verilator Only
#============================================================================

# Verilator path
VERILATOR = /usr/local/bin/verilator
VERILATOR_COVERAGE = /usr/local/bin/verilator_coverage

# Directories
RTL_DIR = ../RTL
ENV_DIR = ./Env
VERILATOR_DIR = $(ENV_DIR)/verilator
TC_DIR = ./Testcases/directed

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

# Help
help:
	@echo "========================================"
	@echo "AES IP Verification Makefile"
	@echo "========================================"
	@echo ""
	@echo "Targets:"
	@echo "  make compile    - Compile with Verilator"
	@echo "  make run        - Run simulation"
	@echo "  make coverage   - Collect coverage data"
	@echo "  make report     - Generate HTML report"
	@echo "  make cov        - Full flow (compile+run+coverage+report)"
	@echo "  make quick      - Quick run (no recompile)"
	@echo "  make clean      - Clean build artifacts"
	@echo "  make clean-all  - Clean everything including reports"
	@echo "  make view       - Open coverage report in browser"
	@echo "  make list-tests - List all testcases"
	@echo ""
	@echo "Output locations:"
	@echo "  Build:    $(TEMP_DIR)"
	@echo "  Coverage: $(COV_DIR)"
	@echo "  Report:   $(REPORT_DIR)"
	@echo "  Logs:     $(LOG_DIR)"
	@echo "  Summary:  $(SUMMARY_FILE)"

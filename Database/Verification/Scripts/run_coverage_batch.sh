#!/bin/bash
#============================================================================
# Batch Coverage Collection Script for AES IP
# Description: Run all testcases from test_list_cov_final.txt and merge coverage
# Usage: ./run_coverage_batch.sh [test_list_file]
#============================================================================

set -e

# Default test list
TEST_LIST="${1:-../Regression/test_list_cov_final.txt}"

# Configuration
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
VERIF_DIR=$(dirname "$SCRIPT_DIR")
PROJECT_DIR="$VERIF_DIR/../.."
RTL_DIR="$PROJECT_DIR/Database/RTL"
TC_DIR="$VERIF_DIR/Testcases/directed"

# Output directories - All temporary files in Temp/
TEMP_DIR="$PROJECT_DIR/Temp/Verilator"
COV_DIR="$TEMP_DIR/coverage"
REPORT_DIR="$TEMP_DIR/html"
LOG_DIR="$TEMP_DIR/logs"
REPORT_OUTPUT="$PROJECT_DIR/ProjectMgmt/Reviews/IDR/COVERAGE_REPORT.md"

# Tools
VERILATOR="/usr/local/bin/verilator"
VERILATOR_COVERAGE="/usr/local/bin/verilator_coverage"

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

# Create directories
mkdir -p "$TEMP_DIR" "$COV_DIR" "$REPORT_DIR" "$LOG_DIR"

echo "========================================"
echo "Batch Coverage Collection"
echo "========================================"
echo "Test List: $TEST_LIST"
echo "Output: $COV_DIR"
echo ""

# Check test list exists
if [ ! -f "$TEST_LIST" ]; then
    echo -e "${RED}Error: Test list not found: $TEST_LIST${NC}"
    exit 1
fi

# Parse test list and run each testcase
TOTAL=0
PASS=0
FAIL=0

# Read testcases from file
declare -a TESTCASES
while IFS= read -r line; do
    [[ "$line" =~ ^#.*$ ]] && continue
    [[ -z "$line" ]] && continue
    if [[ "$line" == *.sv ]]; then
        # Extract just the filename
        tc_file=$(basename "$line")
        TESTCASES+=("$tc_file")
    fi
done < "$TEST_LIST"

echo "Found ${#TESTCASES[@]} testcases"
echo ""

# Run each testcase
for tc_file in "${TESTCASES[@]}"; do
    TOTAL=$((TOTAL + 1))
    tc_name="${tc_file%.sv}"
    tc_path="$TC_DIR/$tc_file"
    
    echo -e "${BLUE}[$TOTAL/${#TESTCASES[@]}] Running $tc_name...${NC}"
    
    # Check testcase exists
    if [ ! -f "$tc_path" ]; then
        echo -e "${RED}  ✗ Testcase not found: $tc_path${NC}"
        FAIL=$((FAIL + 1))
        continue
    fi
    
    # Generate custom sim_main.cpp for this testcase
    sim_main_file="$TEMP_DIR/${tc_name}_sim_main.cpp"
    cat > "$sim_main_file" << EOFCPP
// Auto-generated sim_main for $tc_name
#include <verilated.h>
#include <verilated_vcd_c.h>
#include <verilated_cov.h>
#include "V${tc_name}.h"
#include <iostream>

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);
    
    V${tc_name}* dut = new V${tc_name};
    
    VerilatedVcdC* tfp = new VerilatedVcdC;
    dut->trace(tfp, 99);
    tfp->open("waveform.vcd");
    
    VL_PRINTF("[INFO] Starting $tc_name simulation\\n");
    
    vluint64_t sim_time = 0;
    vluint64_t max_sim_time = 500000;
    
    while (!Verilated::gotFinish() && sim_time < max_sim_time) {
        dut->eval();
        tfp->dump(sim_time);
        sim_time++;
    }
    
    VL_PRINTF("[INFO] Simulation ended at time %lu\\n", sim_time);
    
    VerilatedCov::write("coverage.dat");
    
    tfp->close();
    delete tfp;
    delete dut;
    
    VL_PRINTF("[DONE] Coverage written\\n");
    
    return 0;
}
EOFCPP
    
    # Clean previous build - use unique obj_dir for each testcase
    OBJ_DIR="$TEMP_DIR/obj_dir_${tc_name}"
    rm -rf "$OBJ_DIR"
    rm -f "$TEMP_DIR/coverage.dat"
    
    # Compile (from VERIF_DIR so include paths work)
    cd "$VERIF_DIR"
    if ! $VERILATOR --cc --trace --timing \
        --coverage-line --coverage-toggle \
        --public-flat-rw \
        -Wno-PINMISSING -Wno-WIDTHTRUNC -Wno-WIDTHEXPAND \
        -Wno-LATCH -Wno-CASEINCOMPLETE \
        -I"$TC_DIR" \
        -I"Env/tb" \
        -Mdir "$OBJ_DIR" \
        -CFLAGS "-std=c++20 -O2" \
        -LDFLAGS "-lpthread" \
        --build --exe \
        --top-module "$tc_name" \
        "$RTL_DIR"/*.v \
        "$tc_path" \
        "$sim_main_file" \
        > "$LOG_DIR/${tc_name}_compile.log" 2>&1; then
        
        echo -e "${RED}  ✗ Compile failed${NC}"
        tail -5 "$LOG_DIR/${tc_name}_compile.log"
        FAIL=$((FAIL + 1))
        rm -f "$sim_main_file"
        continue
    fi
    
    # Run simulation
    export VERILATOR_THREADS=1
    unset VERILATOR_ROOT
    
    if timeout 300 "$OBJ_DIR/V${tc_name}" \
        > "$LOG_DIR/${tc_name}.log" 2>&1; then
        
        # Check coverage data generated (in current dir which is VERIF_DIR)
        if [ -f "$VERIF_DIR/coverage.dat" ]; then
            mv "$VERIF_DIR/coverage.dat" "$COV_DIR/${tc_name}.dat"
            echo -e "${GREEN}  ✓ Pass (coverage saved)${NC}"
            PASS=$((PASS + 1))
        else
            echo -e "${YELLOW}  ⚠ Pass (no coverage)${NC}"
            PASS=$((PASS + 1))
        fi
    else
        echo -e "${RED}  ✗ Fail${NC}"
        FAIL=$((FAIL + 1))
    fi
    
    # Clean up
    rm -f "$sim_main_file"
done

echo ""
echo "========================================"
echo "Batch Run Complete"
echo "========================================"
echo "Total:   $TOTAL"
echo -e "${GREEN}Pass:    $PASS${NC}"
echo -e "${RED}Fail:    $FAIL${NC}"
echo ""

# Merge coverage if we have data files
DAT_COUNT=$(find "$COV_DIR" -name "*.dat" -type f | wc -l)
if [ "$DAT_COUNT" -gt 0 ]; then
    echo "Merging $DAT_COUNT coverage data files..."
    
    # Merge all .dat files
    $VERILATOR_COVERAGE --write-info "$COV_DIR/merged.info" \
        "$COV_DIR"/*.dat \
        > "$LOG_DIR/merge.log" 2>&1 || true
    
    echo "Coverage merged: $COV_DIR/merged.info"
    echo ""
    
    # Extract only RTL coverage data
    echo "Extracting RTL-only coverage..."
    if command -v lcov &> /dev/null; then
        lcov --extract "$COV_DIR/merged.info" "*/Database/RTL/*" \
            -o "$COV_DIR/rtl.info" \
            > "$LOG_DIR/extract.log" 2>&1 || true
        echo "RTL coverage extracted: $COV_DIR/rtl.info"
    else
        # Fallback: use merged.info directly
        cp "$COV_DIR/merged.info" "$COV_DIR/rtl.info"
    fi
    
    # Generate HTML report (RTL only)
    if command -v genhtml &> /dev/null; then
        echo "Generating HTML report (RTL only)..."
        genhtml "$COV_DIR/rtl.info" -o "$REPORT_DIR" \
            --ignore-errors source \
            > "$LOG_DIR/report.log" 2>&1 || true
        
        echo "HTML Report: $REPORT_DIR/index.html"
        echo ""
        
        # Show summary
        tail -5 "$LOG_DIR/report.log" 2>/dev/null || true
    else
        echo -e "${YELLOW}Warning: genhtml not found, skipping HTML report${NC}"
    fi
else
    echo -e "${YELLOW}No coverage data files found${NC}"
fi

echo ""
echo "========================================"
echo "Coverage Collection Complete"
echo "========================================"
echo "Coverage data: $COV_DIR"
echo "HTML report:   $REPORT_DIR/index.html"
echo "Logs:          $LOG_DIR"

# Generate summary report to ProjectMgmt/Reviews/IDR/
echo ""
echo "Generating summary report..."

# Extract coverage data from LCOV info file (RTL only)
if [ -f "$COV_DIR/rtl.info" ]; then
    TOTAL_LINES=$(grep -c "^DA:" "$COV_DIR/rtl.info" 2>/dev/null || echo "0")
    HIT_LINES=$(grep "^DA:" "$COV_DIR/rtl.info" | grep -v ",0$" | wc -l)
    
    if [ "$TOTAL_LINES" -gt 0 ]; then
        COVERAGE=$(awk "BEGIN {printf \"%.1f\", ($HIT_LINES/$TOTAL_LINES)*100}")
    else
        COVERAGE="0.0"
    fi
    
    cat > "$REPORT_OUTPUT" << EOF
# AES IP Coverage Report (Batch)

**Generated**: $(date '+%Y-%m-%d %H:%M:%S')
**Tool**: Verilator + lcov/genhtml
**Testcases**: $TOTAL total, $PASS passed, $FAIL failed

## Summary

| Metric | Value |
|--------|-------|
| Line Coverage | ${COVERAGE}% (${HIT_LINES}/${TOTAL_LINES}) |
| Coverage Data Files | $DAT_COUNT |
| Coverage Data | ${COV_DIR}/ |
| Merged Info | ${COV_DIR}/merged.info |
| HTML Report | ${REPORT_DIR}/index.html |
| Full Logs | ${LOG_DIR}/ |

## Location

- Temporary files: \`${TEMP_DIR}/\`
- This report: \`${REPORT_OUTPUT}\`

## Notes

All temporary coverage data is stored in Temp/ directory.
This summary is the only file written to ProjectMgmt/Reviews/IDR/.
EOF
    
    echo "Summary report: $REPORT_OUTPUT"
fi

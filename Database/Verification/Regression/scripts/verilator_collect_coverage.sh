#!/bin/bash
#============================================================================
# Coverage Collection Script
# Description: Automated coverage collection for regression
#============================================================================

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR/../../../.."
RTL_DIR="$PROJECT_DIR/Database/RTL"
TC_DIR="$PROJECT_DIR/Database/Verification/Testcases/directed"
OUT_DIR="$PROJECT_DIR/Temp/Coverage/$(date +%Y%m%d_%H%M%S)"
COV_MERGE_DIR="$PROJECT_DIR/Temp/Coverage/merged"

# Testcases to run
TESTCASES=(
    "tc_random_modes"
    "tc_random_keys"
    "tc_random_data"
    "tc_random_errors"
    "tc_stress_random"
)

# Create output directory
mkdir -p $OUT_DIR $COV_MERGE_DIR

echo "========================================"
echo "AES IP Coverage Collection"
echo "========================================"
echo "Output Directory: $OUT_DIR"
echo ""

# Function to run single testcase
run_testcase() {
    local tc_name=$1
    local tc_file="$TC_DIR/${tc_name}.sv"
    local tc_out="$OUT_DIR/${tc_name}"
    
    echo "----------------------------------------"
    echo "Running: $tc_name"
    echo "----------------------------------------"
    
    mkdir -p $tc_out
    
    # Compile
    echo "[COMPILE] $tc_name"
    verilator --cc --coverage-line --coverage-toggle --coverage-branch \
        --trace -Mdir $tc_out/obj_dir --exe sim_main.cpp \
        -CFLAGS "-std=c++17 -O2" \
        $RTL_DIR/*.v $tc_file \
        > $tc_out/compile.log 2>&1
    
    make -C $tc_out/obj_dir -f V${tc_name}.mk \
        > $tc_out/build.log 2>&1
    
    # Run
    echo "[RUN] $tc_name"
    $tc_out/obj_dir/V${tc_name} \
        > $tc_out/simulation.log 2>&1 || true
    
    # Collect coverage
    echo "[COVERAGE] $tc_name"
    verilator_coverage --write-info $tc_out/coverage.info \
        --write $tc_out/coverage.dat \
        > $tc_out/coverage.log 2>&1
    
    # Extract coverage percentage
    if [ -f "$tc_out/coverage.info" ]; then
        local lines=$(grep -c "^DA:" $tc_out/coverage.info 2>/dev/null || echo "0")
        echo "[INFO] $tc_name: $lines coverage points recorded"
    fi
    
    echo "[DONE] $tc_name"
}

# Run all testcases
echo "Running ${#TESTCASES[@]} testcases..."
for tc in "${TESTCASES[@]}"; do
    run_testcase "$tc"
done

# Merge coverage
echo ""
echo "========================================"
echo "Merging Coverage Data"
echo "========================================"

# Find all coverage.dat files
cov_files=$(find $OUT_DIR -name "coverage.dat" -type f 2>/dev/null | tr '\n' ' ')

if [ -n "$cov_files" ]; then
    verilator_coverage --write-info $COV_MERGE_DIR/merged.info \
        --write $COV_MERGE_DIR/merged.dat \
        $cov_files \
        > $COV_MERGE_DIR/merge.log 2>&1
    
    echo "[MERGE] Coverage merged to $COV_MERGE_DIR"
    
    # Generate HTML if lcov available
    if command -v genhtml >/dev/null 2>&1; then
        genhtml $COV_MERGE_DIR/merged.info -o $COV_MERGE_DIR/html \
            --ignore-errors source \
            > $COV_MERGE_DIR/htmlgen.log 2>&1
        echo "[REPORT] HTML report: $COV_MERGE_DIR/html/index.html"
    fi
else
    echo "[WARNING] No coverage files found to merge"
fi

# Summary
echo ""
echo "========================================"
echo "Coverage Collection Complete"
echo "========================================"
echo "Output Directory: $OUT_DIR"
echo "Merged Coverage: $COV_MERGE_DIR"
echo ""
echo "Individual Results:"
for tc in "${TESTCASES[@]}"; do
    if [ -f "$OUT_DIR/$tc/coverage.info" ]; then
        echo "  ✓ $tc"
    else
        echo "  ✗ $tc (failed)"
    fi
done

echo ""
echo "Next Steps:"
echo "  1. Review merged coverage: $COV_MERGE_DIR"
echo "  2. Open HTML report: $COV_MERGE_DIR/html/index.html"
echo "  3. Identify coverage gaps"
echo ""

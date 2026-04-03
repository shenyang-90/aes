#!/bin/bash
#============================================================================
# Run NEW coverage enhancement testcases
# Output goes to Temp/Verilator directory
#============================================================================

set -e

# Get script directory
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

# Set up directories (relative to script location)
# Script is at: Database/Verification/Scripts/
# So we need to go up 2 levels to get to project root
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEMP_DIR="$ROOT_DIR/Temp/Verilator"
RTL_DIR="$ROOT_DIR/Database/RTL"
TC_DIR="$ROOT_DIR/Database/Verification/Testcases/directed"
ENV_DIR="$ROOT_DIR/Database/Verification/Env"

# Tools
VERILATOR=/usr/local/bin/verilator

# Testcases
NEW_TESTS=(
    "tc_cts_full_boundary"
    "tc_gcm_advanced" 
    "tc_xts_multi_sector"
    "tc_error_recovery"
)

# Create directories
mkdir -p "$TEMP_DIR"/{logs,coverage,reports,obj_dir}

echo "========================================"
echo "AES IP Coverage Enhancement Tests"
echo "========================================"
echo "Root directory: $ROOT_DIR"
echo "Temp directory: $TEMP_DIR"
echo "RTL directory: $RTL_DIR"
echo "Testcases: ${#NEW_TESTS[@]}"
echo ""

# Verify directories exist
if [ ! -d "$RTL_DIR" ]; then
    echo "[ERROR] RTL directory not found: $RTL_DIR"
    exit 1
fi

if [ ! -d "$TC_DIR" ]; then
    echo "[ERROR] Testcase directory not found: $TC_DIR"
    exit 1
fi

# Clean previous coverage data
rm -f "$TEMP_DIR"/coverage/*.dat
rm -f "$TEMP_DIR"/coverage/*.info
rm -f "$TEMP_DIR"/coverage.dat

cd "$TEMP_DIR"

# Function to run single test
run_test() {
    local test_name=$1
    local log_file="$TEMP_DIR/logs/${test_name}.log"
    
    echo "========================================"
    echo "Running: $test_name"
    echo "========================================"
    
    # Check if testcase file exists
    if [ ! -f "$TC_DIR/${test_name}.sv" ]; then
        echo "[ERROR] Testcase file not found: $TC_DIR/${test_name}.sv"
        return 1
    fi
    
    # Compile
    echo "[1/3] Compiling..."
    $VERILATOR --cc --trace --timing \
        --coverage-line --coverage-toggle \
        --public-flat-rw \
        -Wno-PINMISSING -Wno-WIDTHTRUNC -Wno-WIDTHEXPAND \
        -Mdir "$TEMP_DIR/obj_dir" \
        -CFLAGS "-std=c++20 -O2" \
        -LDFLAGS "-lpthread" \
        --build --exe \
        --top-module tb_coverage \
        "$RTL_DIR"/*.v \
        "$TC_DIR/${test_name}.sv" \
        "$ENV_DIR/verilator/sim_main.cpp" \
        2>&1 | tee "$log_file" || {
            echo "[ERROR] Compilation failed for $test_name"
            return 1
        }
    
    # Run simulation (with timeout)
    echo "[2/3] Running simulation..."
    if [ -f "$TEMP_DIR/obj_dir/Vtb_coverage" ]; then
        timeout 180 "$TEMP_DIR/obj_dir/Vtb_coverage" +trace \
            2>&1 | tee -a "$log_file" || {
            echo "[WARN] Simulation may have timed out or finished with errors"
        }
    else
        echo "[ERROR] Simulation executable not found"
        return 1
    fi
    
    # Collect coverage
    echo "[3/3] Collecting coverage..."
    if [ -f "$TEMP_DIR/coverage.dat" ]; then
        mv "$TEMP_DIR/coverage.dat" "$TEMP_DIR/coverage/${test_name}.dat"
        echo "[OK] Coverage data: coverage/${test_name}.dat"
        
        # Generate info file
        $VERILATOR_coverage --write-info "$TEMP_DIR/coverage/${test_name}.info" \
            "$TEMP_DIR/coverage/${test_name}.dat" 2>/dev/null || true
    else
        echo "[WARN] No coverage data generated"
    fi
    
    echo "[OK] $test_name completed"
    echo ""
}

# Run all tests
for test in "${NEW_TESTS[@]}"; do
    run_test "$test" || echo "[WARN] $test had issues but continuing..."
done

echo "========================================"
echo "All tests completed"
echo "========================================"
echo ""

# Merge coverage
echo "Merging coverage data..."
if ls "$TEMP_DIR"/coverage/*.dat 1> /dev/null 2>&1; then
    $VERILATOR_coverage --write-info "$TEMP_DIR/coverage/merged.info" \
        "$TEMP_DIR"/coverage/*.dat 2>&1 | tee "$TEMP_DIR/logs/merge.log" || true
    echo "[OK] Merged coverage: coverage/merged.info"
    
    # Generate HTML report
    if command -v genhtml >/dev/null 2>&1; then
        echo "Generating HTML report..."
        genhtml "$TEMP_DIR/coverage/merged.info" -o "$TEMP_DIR/reports/html" \
            --ignore-errors source 2>&1 | tee "$TEMP_DIR/logs/report.log" || true
        echo "[OK] HTML report: reports/html/index.html"
    else
        echo "[INFO] genhtml not found. Install lcov for HTML reports."
    fi
else
    echo "[WARN] No coverage data files found"
fi

echo ""
echo "Summary:"
echo "  Coverage data: $TEMP_DIR/coverage/"
echo "  Logs: $TEMP_DIR/logs/"
echo "  Reports: $TEMP_DIR/reports/"
echo ""

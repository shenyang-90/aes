#!/bin/bash
#============================================================================
# Unified Coverage Collection Script for AES IP
# Replaces: collect_coverage.sh + run_iverilog_coverage.sh + 
#           run_iverilog_cov.sh + verilator_collect_coverage.sh +
#           run_new_coverage_tests.sh + run_all_testcases_coverage.sh
# Usage: ./run_coverage.sh [verilator|iverilog] [test_name|all|new]
#============================================================================

set -e

# Configuration
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
VERIF_DIR=$(dirname "$SCRIPT_DIR")
PROJECT_DIR="$VERIF_DIR/../.."
RTL_DIR="$PROJECT_DIR/Database/RTL"
TC_DIR="$VERIF_DIR/Testcases/directed"
ENV_DIR="$VERIF_DIR/Env"
REPORT_DIR="$PROJECT_DIR/ProjectMgmt/Reviews/IDR"
COV_DIR="$PROJECT_DIR/Temp/Coverage"

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

# Tools
VERILATOR=${VERILATOR:-/usr/local/bin/verilator}

# Parse arguments
TOOL="${1:-verilator}"
TEST_ARG="${2:-all}"

# Test lists
BASELINE_TESTS=("tc_smoke" "tc_ecb_nist" "tc_cbc_nist" "tc_ctr_nist" "tc_cts_boundary")
NEW_TESTS=("tc_cts_full_boundary" "tc_gcm_advanced" "tc_xts_multi_sector" "tc_error_recovery")
ALL_TESTS=()
for tc in "$TC_DIR"/*.sv; do
    [ -f "$tc" ] && ALL_TESTS+=("$(basename "$tc" .sv)")
done

# Create directories
mkdir -p "$COV_DIR"/{data,html,logs,merged} "$REPORT_DIR"

# Select tests
case "$TEST_ARG" in
    baseline) TESTS=("${BASELINE_TESTS[@]}");;
    new) TESTS=("${NEW_TESTS[@]}");;
    all) TESTS=("${ALL_TESTS[@]}");;
    *) TESTS=("$TEST_ARG");;
esac

echo "========================================"
echo "AES IP Coverage Collection ($TOOL)"
echo "Tests: ${#TESTS[@]}"
echo "Output: $COV_DIR"
echo "========================================"

#============================================================================
# Verilator Coverage
#============================================================================
run_verilator_coverage() {
    local test=$1
    local test_out="$COV_DIR/data/$test"
    mkdir -p "$test_out"
    
    echo "[$test] Compiling with Verilator..."
    $VERILATOR --cc --trace --timing \
        --coverage-line --coverage-toggle \
        --public-flat-rw \
        -Wno-WIDTHTRUNC -Wno-WIDTHEXPAND \
        -Mdir "$test_out/obj_dir" \
        -CFLAGS "-std=c++20 -O2" \
        -LDFLAGS "-lpthread" \
        --build --exe \
        --top-module tb_coverage \
        -f "$VERIF_DIR/filelist.f" \
        "$ENV_DIR/verilator/tb_coverage.sv" \
        "$ENV_DIR/verilator/sim_main.cpp" \
        > "$test_out/compile.log" 2>&1 || {
            echo -e "${RED}  Compile failed${NC}"
            return 1
        }
    
    echo "[$test] Running simulation..."
    timeout 180 "$test_out/obj_dir/Vtb_coverage" \
        > "$test_out/sim.log" 2>&1 || true
    
    # Collect coverage
    if [ -f "$COV_DIR/data/coverage.dat" ]; then
        mv "$COV_DIR/data/coverage.dat" "$test_out/coverage.dat"
        echo -e "${GREEN}  Coverage: $test_out/coverage.dat${NC}"
    fi
}

#============================================================================
# Icarus Verilog Coverage (Line count only)
#============================================================================
run_iverilog_coverage() {
    local test=$1
    local test_out="$COV_DIR/data/$test"
    mkdir -p "$test_out"
    
    echo "[$test] Compiling with Icarus..."
    iverilog -g2012 -Wall \
        -y "$RTL_DIR" -I "$RTL_DIR" -I "$ENV_DIR/tb" \
        -o "$test_out/sim.out" \
        "$TC_DIR/${test}.sv" \
        > "$test_out/compile.log" 2>&1 || {
            echo -e "${RED}  Compile failed${NC}"
            return 1
        }
    
    echo "[$test] Running simulation..."
    timeout 60 vvp "$test_out/sim.out" > "$test_out/sim.log" 2>&1 || true
    
    echo -e "${GREEN}  Completed${NC}"
}

#============================================================================
# Merge Coverage
#============================================================================
merge_coverage() {
    echo ""
    echo "========================================"
    echo "Merging Coverage Data"
    echo "========================================"
    
    local cov_files=""
    for dat in "$COV_DIR"/data/*/coverage.dat; do
        [ -f "$dat" ] && cov_files="$cov_files $dat"
    done
    
    if [ -n "$cov_files" ]; then
        $VERILATOR --coverage-merge \
            --write-info "$COV_DIR/merged/coverage.info" \
            $cov_files \
            > "$COV_DIR/logs/merge.log" 2>&1 || true
        
        echo -e "${GREEN}Merged: $COV_DIR/merged/coverage.info${NC}"
        
        # Generate HTML
        if command -v genhtml >/dev/null 2>&1; then
            genhtml "$COV_DIR/merged/coverage.info" \
                -o "$COV_DIR/html" \
                --ignore-errors source \
                > "$COV_DIR/logs/genhtml.log" 2>&1 || true
            echo -e "${GREEN}HTML: $COV_DIR/html/index.html${NC}"
            
            # Copy to IDR
            cp -r "$COV_DIR/html" "$REPORT_DIR/"
            echo "IDR Report: $REPORT_DIR/html/index.html"
        fi
    else
        echo -e "${YELLOW}No coverage files to merge${NC}"
    fi
}

#============================================================================
# Main Execution
#============================================================================
TOTAL=0; PASS=0; FAIL=0

for TEST in "${TESTS[@]}"; do
    TOTAL=$((TOTAL + 1))
    printf "[%2d/%d] %-30s " "$TOTAL" "${#TESTS[@]}" "$TEST"
    
    if [ "$TOOL" = "verilator" ]; then
        run_verilator_coverage "$TEST" && PASS=$((PASS + 1)) || FAIL=$((FAIL + 1))
    else
        run_iverilog_coverage "$TEST" && PASS=$((PASS + 1)) || FAIL=$((FAIL + 1))
    fi
done

# Merge if verilator mode
[ "$TOOL" = "verilator" ] && merge_coverage

# Summary
echo ""
echo "========================================"
echo "Coverage Collection Complete"
echo "========================================"
echo "Total:  $TOTAL"
echo -e "${GREEN}Pass:   $PASS${NC}"
[ $FAIL -gt 0 ] && echo -e "${RED}Fail:   $FAIL${NC}"

exit $FAIL

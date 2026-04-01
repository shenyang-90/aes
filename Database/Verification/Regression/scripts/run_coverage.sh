#!/bin/bash
#============================================================================
# Script: run_coverage.sh
# Description: Run coverage collection for AES IP
# Usage: ./run_coverage.sh [test_name|all]
#============================================================================

set -e

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERIF_DIR="$(dirname $(dirname $SCRIPT_DIR))"
PROJECT_DIR="$VERIF_DIR/../.."
RTL_DIR="$PROJECT_DIR/Database/RTL"
OUT_DIR="$PROJECT_DIR/Temp/Coverage"
REPORT_DIR="$PROJECT_DIR/ProjectMgmt/Reviews/IDR"

# Create directories
mkdir -p $OUT_DIR
mkdir -p $REPORT_DIR

# Test list - 28 testcases (core + coverage)
TESTS=(
    # Core tests
    "tc_smoke"
    "tc_register_full"
    "tc_interrupt_all"
    "tc_ecb_nist"
    "tc_cbc_nist"
    "tc_cbc_decrypt"
    "tc_ctr_nist"
    "tc_ctr_counter"
    "tc_key_length"
    "tc_key_length_192_0"
    "tc_key_length_192_1"
    "tc_key_length_192_2"
    "tc_key_length_256_0"
    "tc_key_length_256_1"
    "tc_key_length_256_2"
    "tc_gcm_basic"
    "tc_xts_basic"
    "tc_cts_boundary"
    "tc_fault_inject"
    "tc_fault_data_corr"
    "tc_sbox_masked"
    "tc_ecb_multiblock"
    "tc_key_len_error"
    # Multi-Block
    "tc_cbc_multiblock"
    "tc_ctr_multiblock"
    # Coverage maximization tests (IDR新增)
    "tc_toggle_coverage"
    "tc_corner_cases"
    "tc_reset_error_coverage"
)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_header() {
    echo ""
    echo "========================================"
    echo "$1"
    echo "========================================"
}

print_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

print_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
}

print_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

# Function to run single test with coverage
run_test_coverage() {
    local test_name=$1
    local test_path="$VERIF_DIR/Testcases/directed/${test_name}.sv"
    
    if [ ! -f "$test_path" ]; then
        print_warn "Test $test_name not found, skipping"
        return 1
    fi
    
    print_info "Running $test_name with coverage..."
    
    # Compile with coverage flags
    iverilog -g2012 \
        -Wall \
        -y $RTL_DIR \
        -I $RTL_DIR \
        -I $VERIF_DIR/Env/tb \
        -o $OUT_DIR/${test_name}.out \
        $test_path \
        2>&1 | tee $OUT_DIR/${test_name}_compile.log
    
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        print_fail "Compilation failed for $test_name"
        return 1
    fi
    
    # Run simulation
    cd $OUT_DIR
    timeout 30 vvp ${test_name}.out 2>&1 | tee $OUT_DIR/${test_name}_sim.log
    local exit_code=${PIPESTATUS[0]}
    cd - > /dev/null
    
    if [ $exit_code -ne 0 ]; then
        print_fail "Simulation failed for $test_name"
        return 1
    fi
    
    # Check pass/fail
    local pass_count=$(grep -c "\[PASS\]" $OUT_DIR/${test_name}_sim.log 2>/dev/null || echo 0)
    local fail_count=$(grep -c "\[FAIL\]" $OUT_DIR/${test_name}_sim.log 2>/dev/null || echo 0)
    
    if [ "$fail_count" -eq "0" ]; then
        print_pass "$test_name: $pass_count passed"
        return 0
    else
        print_fail "$test_name: $fail_count failed"
        return 1
    fi
}

# Main execution
print_header "AES IP Coverage Collection"
echo "Date: $(date)"
echo "Output: $OUT_DIR"
echo ""

# Parse arguments
if [ $# -eq 0 ] || [ "$1" == "all" ]; then
    # Run all tests
    print_info "Running all ${#TESTS[@]} tests..."
    
    TOTAL=0
    PASSED=0
    FAILED=0
    
    for test in "${TESTS[@]}"; do
        TOTAL=$((TOTAL + 1))
        if run_test_coverage "$test"; then
            PASSED=$((PASSED + 1))
        else
            FAILED=$((FAILED + 1))
        fi
    done
    
    print_header "Coverage Collection Summary"
    echo "Total tests:  $TOTAL"
    print_pass "Passed:       $PASSED"
    if [ $FAILED -gt 0 ]; then
        print_fail "Failed:       $FAILED"
    fi
    echo ""
    echo "Coverage report: $OUT_DIR/"
    
    # Generate summary report
    REPORT_FILE="$REPORT_DIR/coverage_report_$(date +%Y%m%d_%H%M%S).txt"
    echo "AES IP Coverage Collection Report" > $REPORT_FILE
    echo "=================================" >> $REPORT_FILE
    echo "Date: $(date)" >> $REPORT_FILE
    echo "" >> $REPORT_FILE
    echo "Total tests: $TOTAL" >> $REPORT_FILE
    echo "Passed: $PASSED" >> $REPORT_FILE
    echo "Failed: $FAILED" >> $REPORT_FILE
    echo "" >> $REPORT_FILE
    echo "Test details:" >> $REPORT_FILE
    for test in "${TESTS[@]}"; do
        if grep -q "\[FAIL\]" $OUT_DIR/${test}_sim.log 2>/dev/null; then
            echo "  [FAIL] $test" >> $REPORT_FILE
        else
            echo "  [PASS] $test" >> $REPORT_FILE
        fi
    done
    
    print_info "Report saved: $REPORT_FILE"
    
else
    # Run single test
    run_test_coverage "$1"
fi

print_header "Coverage Collection Complete"

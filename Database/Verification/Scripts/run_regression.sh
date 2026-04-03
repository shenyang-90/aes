#!/bin/bash
#============================================================================
# Unified Regression Script for AES IP
# Replaces: run_regression.sh + run_regression_fast.sh + run_coverage.sh
# Usage: ./run_regression.sh [fast|full|coverage] [test_name]
#============================================================================

set -e

# Configuration
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
VERIF_DIR=$(dirname "$SCRIPT_DIR")
PROJECT_DIR="$VERIF_DIR/../.."
REPORT_DIR="$PROJECT_DIR/ProjectMgmt/Reviews/IDR"
OUT_DIR="$PROJECT_DIR/Temp/Regression"
RTL_DIR="$PROJECT_DIR/Database/RTL"

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

# Test Suites
FAST_TESTS=(
    "tc_smoke" "tc_register_full" "tc_interrupt_all"
    "tc_ecb_nist" "tc_cbc_nist" "tc_ctr_nist"
    "tc_key_length" "tc_error_handling" "tc_gcm_basic" "tc_xts_basic"
)

FULL_TESTS=(
    "tc_smoke" "tc_register_full" "tc_interrupt_all"
    "tc_ecb_nist" "tc_ecb_multiblock" "tc_mode_coverage"
    "tc_cbc_nist" "tc_cbc_decrypt" "tc_ctr_nist" "tc_ctr_counter"
    "tc_cbc_multiblock" "tc_ctr_multiblock"
    "tc_gcm_basic" "tc_xts_basic" "tc_cts_boundary"
    "tc_key_length" "tc_key_len_check" "tc_key_len_error" "tc_key_single"
    "tc_key_schedule_simple" "tc_sbox_masked"
    "tc_error_handling" "tc_error_injection"
    "tc_fault_inject" "tc_fault_data_corr"
    "tc_aes_core_direct" "tc_aes128_only"
    "tc_toggle_coverage" "tc_corner_cases" "tc_reset_error_coverage"
    "tc_safety_dual_rail" "tc_safety_crc_error"
)

COVERAGE_TESTS=(
    "tc_smoke" "tc_register_full" "tc_interrupt_all"
    "tc_ecb_nist" "tc_cbc_nist" "tc_cbc_decrypt"
    "tc_ctr_nist" "tc_ctr_counter" "tc_key_length"
    "tc_key_length_192_0" "tc_key_length_192_1" "tc_key_length_256_0"
    "tc_gcm_basic" "tc_xts_basic" "tc_cts_boundary"
    "tc_fault_inject" "tc_sbox_masked"
    "tc_toggle_coverage" "tc_corner_cases" "tc_reset_error_coverage"
)

# Parse arguments
MODE="${1:-fast}"
SINGLE_TEST="$2"
SIMULATOR="${SIMULATOR:-iverilog}"

# Create directories
mkdir -p "$REPORT_DIR" "$OUT_DIR"

# Counters
TOTAL=0; PASS=0; FAIL=0; TIMEOUT=0
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Select test list
case "$MODE" in
    fast) TESTS=("${FAST_TESTS[@]}"); TIMEOUT_SEC=60 ;;
    full) TESTS=("${FULL_TESTS[@]}"); TIMEOUT_SEC=120 ;;
    coverage) TESTS=("${COVERAGE_TESTS[@]}"); TIMEOUT_SEC=180 ;;
    *) echo "Unknown mode: $MODE. Use: fast|full|coverage"; exit 1 ;;
esac

# Single test override
if [ -n "$SINGLE_TEST" ]; then
    TESTS=("$SINGLE_TEST")
fi

# Report file
REPORT_FILE="$REPORT_DIR/regression_${MODE}_${TIMESTAMP}.txt"

echo "========================================" | tee "$REPORT_FILE"
echo "AES IP Regression Test ($MODE mode)" | tee -a "$REPORT_FILE"
echo "Simulator: $SIMULATOR" | tee -a "$REPORT_FILE"
echo "Started: $(date)" | tee -a "$REPORT_FILE"
echo "Tests: ${#TESTS[@]}" | tee -a "$REPORT_FILE"
echo "========================================" | tee -a "$REPORT_FILE"

# Run test function
run_test() {
    local test=$1
    local log="$OUT_DIR/${test}.log"
    
    if [ "$SIMULATOR" = "iverilog" ]; then
        timeout ${TIMEOUT_SEC}s make -C "$VERIF_DIR" SIM=iverilog TEST=$test sim > "$log" 2>&1
    else
        echo "Simulator $SIMULATOR not supported yet" >&2
        return 1
    fi
}

# Main loop
for TEST in "${TESTS[@]}"; do
    TOTAL=$((TOTAL + 1))
    printf "[%2d/%d] %-30s " "$TOTAL" "${#TESTS[@]}" "$TEST"
    
    if run_test "$TEST"; then
        echo -e "${GREEN}PASS${NC}" | tee -a "$REPORT_FILE"
        PASS=$((PASS + 1))
    else
        local exit_code=$?
        if [ $exit_code -eq 124 ]; then
            echo -e "${YELLOW}TIMEOUT${NC}" | tee -a "$REPORT_FILE"
            TIMEOUT=$((TIMEOUT + 1))
        else
            echo -e "${RED}FAIL${NC}" | tee -a "$REPORT_FILE"
            FAIL=$((FAIL + 1))
        fi
    fi
done

# Summary
echo "" | tee -a "$REPORT_FILE"
echo "========================================" | tee -a "$REPORT_FILE"
echo "Regression Complete: $(date)" | tee -a "$REPORT_FILE"
echo "========================================" | tee -a "$REPORT_FILE"
echo "Total:    $TOTAL" | tee -a "$REPORT_FILE"
echo -e "${GREEN}Pass:     $PASS${NC}" | tee -a "$REPORT_FILE"
[ $FAIL -gt 0 ] && echo -e "${RED}Fail:     $FAIL${NC}" | tee -a "$REPORT_FILE"
[ $TIMEOUT -gt 0 ] && echo -e "${YELLOW}Timeout:  $TIMEOUT${NC}" | tee -a "$REPORT_FILE"
echo "Report:   $REPORT_FILE" | tee -a "$REPORT_FILE"

# Link to latest
ln -sf "$REPORT_FILE" "$REPORT_DIR/regression_latest.txt"

# Exit code
[ $FAIL -eq 0 ] && [ $TIMEOUT -eq 0 ] && exit 0 || exit 1

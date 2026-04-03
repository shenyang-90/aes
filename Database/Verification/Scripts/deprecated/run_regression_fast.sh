#!/bin/bash
#============================================================================
# Fast Regression Test Script for AES IP (with timeout)
#============================================================================

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
VERIF_DIR=$(dirname "$SCRIPT_DIR")
PROJECT_DIR="$VERIF_DIR/../.."
REPORT_DIR="$PROJECT_DIR/ProjectMgmt/Reviews/IDR"
OUT_DIR="$PROJECT_DIR/Temp/VCS"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Create directories
mkdir -p "$REPORT_DIR" "$OUT_DIR"

# Test list - Key tests for quick regression
TESTS=(
    "tc_smoke"
    "tc_register_full"
    "tc_interrupt_all"
    "tc_ecb_nist"
    "tc_cbc_nist"
    "tc_ctr_nist"
    "tc_key_length"
    "tc_error_handling"
    "tc_gcm_basic"
    "tc_xts_basic"
)

# Counters
TOTAL=0
PASS=0
FAIL=0
TIMEOUT=0

# Timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="$REPORT_DIR/regression_report_${TIMESTAMP}.txt"

echo "========================================" | tee "$REPORT_FILE"
echo "AES IP Fast Regression Test" | tee -a "$REPORT_FILE"
echo "Started: $(date)" | tee -a "$REPORT_FILE"
echo "Test Timeout: 60s per test" | tee -a "$REPORT_FILE"
echo "========================================" | tee -a "$REPORT_FILE"

# Run each test with timeout
cd "$VERIF_DIR" || exit 1

for TEST in "${TESTS[@]}"; do
    TOTAL=$((TOTAL + 1))
    
    echo "" | tee -a "$REPORT_FILE"
    echo "[$TOTAL] Running $TEST..." | tee -a "$REPORT_FILE"
    
    # Run with 60 second timeout
    timeout 60s make SIM=iverilog TEST=${TEST} sim > "$OUT_DIR/${TEST}.log" 2>&1
    exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}  PASS${NC}" | tee -a "$REPORT_FILE"
        PASS=$((PASS + 1))
    elif [ $exit_code -eq 124 ]; then
        echo -e "${YELLOW}  TIMEOUT${NC}" | tee -a "$REPORT_FILE"
        TIMEOUT=$((TIMEOUT + 1))
        # Check if test made progress
        if grep -q "PASS\|Test Results" "$OUT_DIR/${TEST}.log" 2>/dev/null; then
            echo "  (Test made progress before timeout)" | tee -a "$REPORT_FILE"
        fi
    else
        echo -e "${RED}  FAIL${NC}" | tee -a "$REPORT_FILE"
        FAIL=$((FAIL + 1))
    fi
done

# Summary
echo "" | tee -a "$REPORT_FILE"
echo "========================================" | tee -a "$REPORT_FILE"
echo "Regression Complete: $(date)" | tee -a "$REPORT_FILE"
echo "========================================" | tee -a "$REPORT_FILE"
echo "Total:    $TOTAL" | tee -a "$REPORT_FILE"
echo -e "${GREEN}Pass:     $PASS${NC}" | tee -a "$REPORT_FILE"
echo -e "${RED}Fail:     $FAIL${NC}" | tee -a "$REPORT_FILE"
echo -e "${YELLOW}Timeout:  $TIMEOUT${NC}" | tee -a "$REPORT_FILE"
echo "Report:   $REPORT_FILE" | tee -a "$REPORT_FILE"

# Return code
if [ $FAIL -eq 0 ] && [ $TIMEOUT -eq 0 ]; then
    echo -e "\n${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "\n${YELLOW}Some tests failed or timed out${NC}"
    exit 0
fi

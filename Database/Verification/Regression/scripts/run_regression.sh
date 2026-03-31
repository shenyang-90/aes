#!/bin/bash
#============================================================================
# Regression Test Script for AES IP
#============================================================================

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
TB_DIR=$(dirname "$SCRIPT_DIR")
REPORT_DIR="$TB_DIR/../reports"
OUT_DIR="$TB_DIR/../out"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Create directories
mkdir -p "$REPORT_DIR" "$OUT_DIR"

# Test list
TESTS=(
    "tc_smoke"
    "tc_ecb_nist"
    "tc_cbc_nist"
    "tc_ctr_nist"
    "tc_cts_boundary"
)

# Counters
TOTAL=0
PASS=0
FAIL=0

# Timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="$REPORT_DIR/regression_report_${TIMESTAMP}.txt"

echo "========================================" | tee "$REPORT_FILE"
echo "AES IP Regression Test" | tee -a "$REPORT_FILE"
echo "Started: $(date)" | tee -a "$REPORT_FILE"
echo "========================================" | tee -a "$REPORT_FILE"

# Run each test
for TEST in "${TESTS[@]}"; do
    TOTAL=$((TOTAL + 1))
    
    echo "" | tee -a "$REPORT_FILE"
    echo "[$TOTAL] Running $TEST..." | tee -a "$REPORT_FILE"
    
    # Compile and run
    cd "$TB_DIR" || exit 1
    
    if make SIM=iverilog TB=Testcases/directed/${TEST}.sv run > "$OUT_DIR/${TEST}.log" 2>&1; then
        echo -e "${GREEN}  PASS${NC}" | tee -a "$REPORT_FILE"
        PASS=$((PASS + 1))
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
echo "Total:  $TOTAL" | tee -a "$REPORT_FILE"
echo -e "${GREEN}Pass:   $PASS${NC}" | tee -a "$REPORT_FILE"
echo -e "${RED}Fail:   $FAIL${NC}" | tee -a "$REPORT_FILE"
echo "Report: $REPORT_FILE" | tee -a "$REPORT_FILE"

# Return code
if [ $FAIL -eq 0 ]; then
    echo -e "\n${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "\n${RED}Some tests failed!${NC}"
    exit 1
fi

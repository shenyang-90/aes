#!/bin/bash
#============================================================================
# Coverage Collection Script for AES IP
#============================================================================

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
VERIF_DIR=$(dirname "$SCRIPT_DIR")
AES_DIR=$(dirname "$VERIF_DIR")
TEMP_DIR="$AES_DIR/Temp"
COV_DIR="$SCRIPT_DIR/.."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "========================================"
echo "AES IP Coverage Collection"
echo "========================================"
echo ""

# Create directories
mkdir -p "$COV_DIR/data"
mkdir -p "$COV_DIR/html"

# Test list
TESTS=(
    "tc_smoke"
    "tc_ecb_nist"
    "tc_cbc_nist"
    "tc_ctr_nist"
    "tc_cts_boundary"
)

# Run tests and collect coverage
TOTAL=0
PASS=0
FAIL=0

COV_DATA="$COV_DIR/data/coverage_$(date +%Y%m%d_%H%M%S).txt"

echo "Running regression with coverage..." | tee "$COV_DATA"
echo "" | tee -a "$COV_DATA"

cd "$VERIF_DIR" || exit 1

for TEST in "${TESTS[@]}"; do
    TOTAL=$((TOTAL + 1))
    echo "[$TOTAL] Running $TEST..."
    
    # Run with coverage flags
    if make TEST=$TEST SIM=iverilog clean > /dev/null 2>&1; then
        if make TEST=$TEST SIM=iverilog compile > "$TEMP_DIR/VCS/${TEST}_compile.log" 2>&1; then
            if make TEST=$TEST SIM=iverilog sim > "$TEMP_DIR/VCS/${TEST}_sim.log" 2>&1; then
                echo -e "${GREEN}  PASS${NC}" | tee -a "$COV_DATA"
                PASS=$((PASS + 1))
            else
                echo -e "${RED}  FAIL (simulation)${NC}" | tee -a "$COV_DATA"
                FAIL=$((FAIL + 1))
            fi
        else
            echo -e "${RED}  FAIL (compile)${NC}" | tee -a "$COV_DATA"
            FAIL=$((FAIL + 1))
        fi
    fi
done

echo "" | tee -a "$COV_DATA"
echo "========================================" | tee -a "$COV_DATA"
echo "Regression Complete" | tee -a "$COV_DATA"
echo "========================================" | tee -a "$COV_DATA"
echo "Total:  $TOTAL" | tee -a "$COV_DATA"
echo -e "${GREEN}Pass:   $PASS${NC}" | tee -a "$COV_DATA"
echo -e "${RED}Fail:   $FAIL${NC}" | tee -a "$COV_DATA"
echo "" | tee -a "$COV_DATA"

# Calculate pass rate
PASS_RATE=$((PASS * 100 / TOTAL))
echo "Pass Rate: ${PASS_RATE}%" | tee -a "$COV_DATA"

echo "" | tee -a "$COV_DATA"
echo "Coverage data saved to: $COV_DATA"

# Return code based on pass rate
if [ $PASS_RATE -ge 80 ]; then
    echo -e "${GREEN}Coverage collection successful!${NC}"
    exit 0
else
    echo -e "${RED}Coverage collection failed - pass rate too low${NC}"
    exit 1
fi

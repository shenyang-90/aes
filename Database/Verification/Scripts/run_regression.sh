#!/bin/bash
#============================================================================
# Regression Test Script for AES IP
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
NC='\033[0m' # No Color

# Create directories
mkdir -p "$REPORT_DIR" "$OUT_DIR"

# Test list - Full regression (32 testcases)
TESTS=(
    # Smoke
    "tc_smoke"
    # Register & Interrupt
    "tc_register_full"
    "tc_interrupt_all"
    # ECB Mode
    "tc_ecb_nist"
    "tc_ecb_multiblock"
    "tc_mode_coverage"
    # CBC Mode
    "tc_cbc_nist"
    "tc_cbc_decrypt"
    # CTR Mode
    "tc_ctr_nist"
    "tc_ctr_counter"
    # Multi-Block
    "tc_cbc_multiblock"
    "tc_ctr_multiblock"
    # GCM Mode
    "tc_gcm_basic"
    # XTS Mode
    "tc_xts_basic"
    # CTS Mode
    "tc_cts_boundary"
    # Key Length (simplified - main tests only)
    "tc_key_length"
    "tc_key_len_check"
    "tc_key_len_error"
    "tc_key_single"
    # Key Schedule
    "tc_key_schedule_simple"
    # S-Box
    "tc_sbox_masked"
    # Error Handling
    "tc_error_handling"
    "tc_error_injection"
    # Fault Injection
    "tc_fault_inject"
    "tc_fault_data_corr"
    # Core/Direct
    "tc_aes_core_direct"
    "tc_aes128_only"
    # Coverage Maximization (IDR新增)
    "tc_toggle_coverage"
    "tc_corner_cases"
    "tc_reset_error_coverage"
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

#!/bin/bash
#============================================================================
# Script: verify_rtl_fixes.sh
# Description: Verify RTL fixes for BUG-003, BUG-004, BUG-005
# Usage: ./verify_rtl_fixes.sh [bug_number]
#============================================================================

OUT_DIR="../../Temp/VCS"
mkdir -p $OUT_DIR

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_header() {
    echo ""
    echo "==========================================="
    echo "$1"
    echo "==========================================="
}

print_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

print_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Function to compile and run test
run_test() {
    local test_name=$1
    local bug_id=$2
    
    print_header "Testing: $test_name (BUG-$bug_id)"
    
    # Compile
    make TEST=$test_name compile > /tmp/${test_name}_compile.log 2>&1
    if [ ! -f "$OUT_DIR/${test_name}.out" ]; then
        print_fail "Compilation failed for $test_name"
        tail -10 /tmp/${test_name}_compile.log
        return 1
    fi
    print_pass "Compilation successful"
    
    # Run simulation
    cd $OUT_DIR
    timeout 15 vvp "${test_name}.out" > /tmp/${test_name}_sim.log 2>&1
    exit_code=$?
    cd - > /dev/null
    
    if [ $exit_code -ne 0 ]; then
        print_fail "Simulation crashed for $test_name"
        return 1
    fi
    
    # Check results
    local pass_count=$(grep "\[PASS\]" /tmp/${test_name}_sim.log 2>/dev/null | wc -l | tr -d ' ')
    local fail_count=$(grep "\[FAIL\]" /tmp/${test_name}_sim.log 2>/dev/null | wc -l | tr -d ' ')
    
    echo "  Pass count: $pass_count"
    echo "  Fail count: $fail_count"
    
    # Display relevant output
    grep -E "(PASS|FAIL|Expected|Actual|Ciphertext|Plaintext)" /tmp/${test_name}_sim.log | head -20
    
    if [ "$fail_count" -eq "0" ] && [ "$pass_count" -gt "0" ]; then
        print_pass "All tests passed for $test_name"
        return 0
    else
        print_fail "Some tests failed for $test_name"
        return 1
    fi
}

# Main execution
print_header "RTL Fix Verification Script"
echo "Date: $(date)"
echo ""

if [ $# -eq 0 ]; then
    # Run all bug verifications
    
    # BUG-003: AES-192/256 key length
    run_test "tc_key_length" "003"
    BUG003_RESULT=$?
    
    # BUG-004: GCM mode
    run_test "tc_gcm_basic" "004"
    BUG004_RESULT=$?
    
    # BUG-005: XTS mode
    run_test "tc_xts_basic" "005"
    BUG005_RESULT=$?
    
    # Summary
    print_header "Verification Summary"
    
    if [ $BUG003_RESULT -eq 0 ]; then
        print_pass "BUG-003 (AES-192/256 key length)"
    else
        print_fail "BUG-003 (AES-192/256 key length)"
    fi
    
    if [ $BUG004_RESULT -eq 0 ]; then
        print_pass "BUG-004 (GCM mode)"
    else
        print_fail "BUG-004 (GCM mode)"
    fi
    
    if [ $BUG005_RESULT -eq 0 ]; then
        print_pass "BUG-005 (XTS mode)"
    else
        print_fail "BUG-005 (XTS mode)"
    fi
    
    TOTAL=$((BUG003_RESULT + BUG004_RESULT + BUG005_RESULT))
    
    echo ""
    if [ $TOTAL -eq 0 ]; then
        print_pass "ALL BUG FIXES VERIFIED SUCCESSFULLY!"
        exit 0
    else
        print_fail "SOME BUG FIXES NEED MORE WORK"
        exit 1
    fi
    
else
    # Run specific bug verification
    case $1 in
        003)
            # Run all 6 individual key length tests
            TOTAL_PASS=0
            TOTAL_FAIL=0
            for test in tc_key_length_192_0 tc_key_length_192_1 tc_key_length_192_2 \
                        tc_key_length_256_0 tc_key_length_256_1 tc_key_length_256_2; do
                run_test "$test" "003"
                if [ $? -eq 0 ]; then
                    TOTAL_PASS=$((TOTAL_PASS + 1))
                else
                    TOTAL_FAIL=$((TOTAL_FAIL + 1))
                fi
            done
            print_header "BUG-003 Summary"
            echo "Passed: $TOTAL_PASS/6"
            echo "Failed: $TOTAL_FAIL/6"
            if [ $TOTAL_FAIL -eq 0 ]; then
                print_pass "BUG-003 (AES-192/256 key length)"
                exit 0
            else
                print_fail "BUG-003 (AES-192/256 key length)"
                exit 1
            fi
            ;;
        004)
            run_test "tc_gcm_basic" "004"
            ;;
        005)
            run_test "tc_xts_basic" "005"
            ;;
        *)
            echo "Usage: $0 [003|004|005]"
            exit 1
            ;;
    esac
fi

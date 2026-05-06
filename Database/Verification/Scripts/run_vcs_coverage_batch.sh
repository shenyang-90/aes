#!/bin/bash
#============================================================================
# VCS Batch Coverage Collection Script for AES IP
# Description: Run multiple testcases with VCS and merge coverage
# Usage: ./run_vcs_coverage_batch.sh [test_list_file]
#============================================================================

set -e

# Default test list
TEST_LIST="${1:-../Regression/test_list_cov_final.txt}"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

# Directories
RTL_DIR="${PROJECT_ROOT}/Database/RTL"
VERIF_DIR="${PROJECT_ROOT}/Database/Verification"
TC_DIR="${VERIF_DIR}/Testcases/directed"
VCS_DIR="${PROJECT_ROOT}/Temp/VCS"
COV_DIR="${VCS_DIR}/coverage"
LOG_DIR="${VCS_DIR}/logs"
MERGED_DIR="${COV_DIR}/merged"
REPORT_OUTPUT="${PROJECT_ROOT}/ProjectMgmt/Reviews/IDR/VCS_COVERAGE_REPORT.md"

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

# Check tools
if ! command -v vcs &> /dev/null; then
    echo -e "${RED}[ERROR] VCS not found in PATH${NC}"
    exit 1
fi

# Create directories
mkdir -p "${VCS_DIR}" "${COV_DIR}" "${LOG_DIR}" "${MERGED_DIR}"

echo "========================================"
echo "VCS Batch Coverage Collection"
echo "========================================"
echo "Test List: ${TEST_LIST}"
echo "Output: ${COV_DIR}"
echo ""

# Check test list exists
if [ ! -f "${TEST_LIST}" ]; then
    echo -e "${RED}[ERROR] Test list not found: ${TEST_LIST}${NC}"
    exit 1
fi

# Parse testcases from file
declare -a TESTCASES
while IFS= read -r line; do
    [[ "$line" =~ ^#.*$ ]] && continue
    [[ -z "$line" ]] && continue
    if [[ "$line" == *.sv ]]; then
        tc_file=$(basename "$line")
        TESTCASES+=("${tc_file%.sv}")
    fi
done < "${TEST_LIST}"

echo "Found ${#TESTCASES[@]} testcases"
echo ""

# Track results
TOTAL=0
PASS=0
FAIL=0

# Compile once with all RTL
echo "[SETUP] Compiling RTL with VCS..."
cd "${VERIF_DIR}"

# Generate file list if not exists
if [ ! -f "rtl.f" ]; then
    echo "// RTL File List for VCS" > rtl.f
    for f in "${RTL_DIR}"/*.v; do
        echo "$f" >> rtl.f
    done
fi

# Run each testcase
for tc_name in "${TESTCASES[@]}"; do
    TOTAL=$((TOTAL + 1))
    tc_path="${TC_DIR}/${tc_name}.sv"
    
    echo -e "${BLUE}[${TOTAL}/${#TESTCASES[@]}] Running ${tc_name}...${NC}"
    
    # Check testcase exists
    if [ ! -f "${tc_path}" ]; then
        echo -e "${RED}  ✗ Testcase not found: ${tc_path}${NC}"
        FAIL=$((FAIL + 1))
        continue
    fi
    
    # Compile (per testcase to include the test)
    cd "${VCS_DIR}"
    if ! vcs -full64 -sverilog \
        -debug_access+all \
        -timescale=1ns/1ps \
        +incdir+"${TC_DIR}" \
        +incdir+"${ENV_DIR}/tb" \
        +define+VCS \
        -f "${VERIF_DIR}/rtl.f" \
        "${tc_path}" \
        -o "simv_${tc_name}" \
        > "${LOG_DIR}/${tc_name}_compile.log" 2>&1; then
        
        echo -e "${RED}  ✗ Compile failed${NC}"
        FAIL=$((FAIL + 1))
        continue
    fi
    
    # Run simulation with coverage
    if timeout 300 "./simv_${tc_name}" \
        -cm line+cond+fsm+tgl+branch \
        -cm_dir "${tc_name}.vdb" \
        > "${LOG_DIR}/${tc_name}.log" 2>&1; then
        
        echo -e "${GREEN}  ✓ Pass${NC}"
        PASS=$((PASS + 1))
    else
        echo -e "${RED}  ✗ Fail${NC}"
        FAIL=$((FAIL + 1))
    fi
done

echo ""
echo "========================================"
echo "Batch Run Complete"
echo "========================================"
echo "Total:   ${TOTAL}"
echo -e "${GREEN}Pass:    ${PASS}${NC}"
echo -e "${RED}Fail:    ${FAIL}${NC}"
echo ""

# Merge coverage if URG is available
if command -v urg &> /dev/null && [ ${PASS} -gt 0 ]; then
    echo "Merging coverage data..."
    
    # Find all vdb directories
    VDB_DIRS=$(find "${VCS_DIR}" -name "*.vdb" -type d | tr '\n' ' ')
    
    if [ -n "${VDB_DIRS}" ]; then
        urg -dir ${VDB_DIRS} \
            -format both \
            -report "${MERGED_DIR}" \
            -dbname "${MERGED_DIR}/merged.vdb" \
            > "${LOG_DIR}/merge.log" 2>&1
        
        echo -e "${GREEN}Coverage merged: ${MERGED_DIR}/dashboard.txt${NC}"
        
        # Show summary
        if [ -f "${MERGED_DIR}/dashboard.txt" ]; then
            echo ""
            grep "Total Coverage" "${MERGED_DIR}/dashboard.txt" | head -3
        fi
    fi
else
    echo -e "${YELLOW}[WARN] URG not available or no coverage data${NC}"
fi

echo ""
echo "========================================"
echo "VCS Coverage Collection Complete"
echo "========================================"
echo "Coverage data: ${COV_DIR}"
echo "Merged report: ${MERGED_DIR}/dashboard.txt"
echo "Logs:          ${LOG_DIR}"

# Generate summary report
if [ -f "${MERGED_DIR}/dashboard.txt" ]; then
    echo ""
    echo "Generating summary report..."
    
    COVERAGE_LINE=$(grep "Total Coverage" "${MERGED_DIR}/dashboard.txt" 2>/dev/null | head -1 || echo "N/A")
    
    cat > "${REPORT_OUTPUT}" << EOF
# AES IP VCS Batch Coverage Report

**Generated**: $(date '+%Y-%m-%d %H:%M:%S')
**Tool**: VCS + URG
**Testcases**: ${TOTAL} total, ${PASS} passed, ${FAIL} failed

## Summary

| Metric | Value |
|--------|-------|
| Total Coverage | ${COVERAGE_LINE} |
| Coverage Data | ${COV_DIR}/ |
| Merged Report | ${MERGED_DIR}/dashboard.txt |
| Full Logs | ${LOG_DIR}/ |

## View Coverage

\`\`\`bash
# Open merged coverage in Verdi
verdi -cov -covdir ${MERGED_DIR}/merged.vdb
\`\`\`

## Notes

- All temporary coverage data is stored in Temp/VCS/ directory
- This summary is the only file written to ProjectMgmt/Reviews/IDR/
EOF
    
    echo "Summary: ${REPORT_OUTPUT}"
fi

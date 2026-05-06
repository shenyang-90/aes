#!/bin/bash
#============================================================================
# VCS Simulation Script for AES IP
# Description: Compile and run simulation with VCS
# Usage: ./run_vcs.sh [testcase_name]
#============================================================================

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

# Directories
RTL_DIR="${PROJECT_ROOT}/Database/RTL"
VERIF_DIR="${PROJECT_ROOT}/Database/Verification"
ENV_DIR="${VERIF_DIR}/Env"
TC_DIR="${VERIF_DIR}/Testcases/directed"
VCS_DIR="${PROJECT_ROOT}/Temp/VCS"
COV_DIR="${VCS_DIR}/coverage"
LOG_DIR="${VCS_DIR}/logs"
REPORT_OUTPUT="${PROJECT_ROOT}/ProjectMgmt/Reviews/IDR/VCS_COVERAGE_REPORT.md"

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

# Testcase selection
TESTCASE="${1:-tc_smoke}"

# Create directories
mkdir -p "${VCS_DIR}" "${COV_DIR}" "${LOG_DIR}"

echo "========================================"
echo "VCS Simulation for AES IP"
echo "========================================"
echo "Testcase: ${TESTCASE}"
echo "Output: ${VCS_DIR}"
echo ""

# Check VCS availability
if ! command -v vcs &> /dev/null; then
    echo -e "${RED}[ERROR] VCS not found in PATH${NC}"
    echo "Please load VCS environment: source <vcs_install>/setup.sh"
    exit 1
fi

# Find testcase file
TC_FILE="${TC_DIR}/${TESTCASE}.sv"
if [ ! -f "${TC_FILE}" ]; then
    echo -e "${RED}[ERROR] Testcase not found: ${TC_FILE}${NC}"
    echo "Available testcases:"
    ls -1 "${TC_DIR}"/*.sv | xargs -n1 basename | sed 's/.sv$//' | head -10
    exit 1
fi

echo "[1/4] Compiling with VCS..."
cd "${VCS_DIR}"

vcs -full64 -sverilog \
    -debug_access+all -kdb \
    -timescale=1ns/1ps \
    +incdir+"${TC_DIR}" \
    +incdir+"${ENV_DIR}/tb" \
    +define+VCS \
    -f "${VERIF_DIR}/rtl.f" \
    "${RTL_DIR}"/*.v \
    "${TC_FILE}" \
    -o simv \
    2>&1 | tee "${LOG_DIR}/compile_${TESTCASE}.log"

if [ ! -f "${VCS_DIR}/simv" ]; then
    echo -e "${RED}[ERROR] Compilation failed${NC}"
    exit 1
fi

echo -e "${GREEN}[COMPILE] Done${NC}"
echo ""

echo "[2/4] Running simulation..."
cd "${VCS_DIR}"

# Run with coverage collection
./simv +vcs+lic+wait \
    -cm line+cond+fsm+tgl+branch \
    -cm_dir "${TESTCASE}.vdb" \
    2>&1 | tee "${LOG_DIR}/run_${TESTCASE}.log"

echo -e "${GREEN}[RUN] Done${NC}"
echo ""

echo "[3/4] Processing coverage..."

# Check if urg is available
if command -v urg &> /dev/null; then
    urg -dir "${TESTCASE}.vdb" \
        -format both \
        -report "${COV_DIR}/${TESTCASE}" \
        -dbname "${COV_DIR}/${TESTCASE}.vdb" \
        2>&1 | tee "${LOG_DIR}/coverage_${TESTCASE}.log"
    
    echo -e "${GREEN}[COVERAGE] Report: ${COV_DIR}/${TESTCASE}/dashboard.txt${NC}"
else
    echo -e "${YELLOW}[WARN] URG not found, skipping coverage report generation${NC}"
fi

echo ""
echo "========================================"
echo "VCS Simulation Complete"
echo "========================================"
echo -e "${GREEN}Testcase: ${TESTCASE}${NC}"
echo "Waveform:   ${VCS_DIR}/simv.vdb (open with verdi)"
echo "Coverage:   ${COV_DIR}/${TESTCASE}/"
echo "Logs:       ${LOG_DIR}/"
echo ""

# Generate summary report
if command -v urg &> /dev/null && [ -f "${COV_DIR}/${TESTCASE}/dashboard.txt" ]; then
    echo "Generating summary report..."
    
    # Extract coverage from dashboard
    COVERAGE_LINE=$(grep "Total Coverage" "${COV_DIR}/${TESTCASE}/dashboard.txt" 2>/dev/null | head -1 || echo "N/A")
    
    cat > "${REPORT_OUTPUT}" << EOF
# AES IP VCS Coverage Report

**Generated**: $(date '+%Y-%m-%d %H:%M:%S')
**Tool**: VCS + Verdi
**Testcase**: ${TESTCASE}

## Summary

| Metric | Value |
|--------|-------|
| Testcase | ${TESTCASE} |
| Coverage Line | ${COVERAGE_LINE} |
| VDB File | ${VCS_DIR}/${TESTCASE}.vdb |
| HTML Report | ${COV_DIR}/${TESTCASE}/dashboard.txt |
| Full Logs | ${LOG_DIR}/ |

## Location

- Simulation files: \`${VCS_DIR}/\`
- Coverage data: \`${COV_DIR}/\`
- This report: \`${REPORT_OUTPUT}\`

## View Coverage

\`\`\`bash
# Open in Verdi
make verdi-cov

# Or open specific testcase
verdi -cov -covdir ${VCS_DIR}/${TESTCASE}.vdb
\`\`\`
EOF
    
    echo "Summary: ${REPORT_OUTPUT}"
fi

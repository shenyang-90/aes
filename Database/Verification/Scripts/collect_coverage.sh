#!/bin/bash
#================================================================================
# Coverage Collection Script for AES IP (ASIL-D) - IDR Review
# Description: Run tb_coverage and generate coverage report
# Usage: ./collect_coverage.sh
#================================================================================

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

# Directories
RTL_DIR="${PROJECT_ROOT}/Database/RTL"
VERIF_DIR="${PROJECT_ROOT}/Database/Verification"
ENV_DIR="${VERIF_DIR}/Env"
TEMP_DIR="${PROJECT_ROOT}/Temp/Verilator"
COV_DIR="${PROJECT_ROOT}/ProjectMgmt/Reviews/IDR/coverage"
REPORT_DIR="${PROJECT_ROOT}/ProjectMgmt/Reviews/IDR/html"
LOG_DIR="${PROJECT_ROOT}/ProjectMgmt/Reviews/IDR/logs"

# Tools
VERILATOR="/usr/local/bin/verilator"
VERILATOR_COVERAGE="/usr/local/bin/verilator_coverage"

# Create directories
mkdir -p "${TEMP_DIR}" "${COV_DIR}" "${REPORT_DIR}" "${LOG_DIR}"

echo "========================================"
echo "AES IP Coverage Collection (Verilator)"
echo "========================================"
echo "Project: ${PROJECT_ROOT}"
echo "Output: ${COV_DIR}"
echo ""

# Set single thread mode to avoid threading issues
export VERILATOR_THREADS=1
unset VERILATOR_ROOT

echo "[1/4] Compiling testbench..."
cd "${TEMP_DIR}"

${VERILATOR} --cc --trace --timing \
    --coverage-line --coverage-toggle \
    --public-flat-rw \
    -Wno-PINMISSING -Wno-WIDTHTRUNC -Wno-WIDTHEXPAND -Wno-LATCH -Wno-CASEINCOMPLETE \
    -Mdir "${TEMP_DIR}/obj_dir" \
    -CFLAGS "-std=c++20 -O2" \
    -LDFLAGS "-lpthread" \
    --build --exe \
    --top-module tb_coverage \
    ${RTL_DIR}/*.v \
    ${ENV_DIR}/verilator/tb_coverage.sv \
    ${ENV_DIR}/verilator/sim_main_coverage.cpp \
    2>&1 | tee "${LOG_DIR}/compile.log" | tail -20

if [ ! -f "${TEMP_DIR}/obj_dir/Vtb_coverage" ]; then
    echo "Error: Compilation failed"
    exit 1
fi

echo ""
echo "[2/4] Running simulation..."
rm -f "${TEMP_DIR}/coverage.dat"
cd "${TEMP_DIR}"
./obj_dir/Vtb_coverage 2>&1 | tee "${LOG_DIR}/simulation.log"

if [ ! -f "${TEMP_DIR}/coverage.dat" ]; then
    echo "Error: No coverage data generated"
    exit 1
fi

echo ""
echo "[3/4] Processing coverage data..."
cp "${TEMP_DIR}/coverage.dat" "${COV_DIR}/coverage.dat"
${VERILATOR_COVERAGE} --write-info "${COV_DIR}/coverage.info" "${COV_DIR}/coverage.dat" 2>&1 | tee "${LOG_DIR}/coverage.log"

echo ""
echo "[4/4] Generating HTML report..."
if command -v genhtml &> /dev/null; then
    genhtml "${COV_DIR}/coverage.info" -o "${REPORT_DIR}" --ignore-errors source 2>&1 | tee "${LOG_DIR}/genhtml.log"
    echo ""
    echo "HTML Report: ${REPORT_DIR}/index.html"
else
    echo "Warning: genhtml not available, skipping HTML report generation"
fi

echo ""
echo "========================================"
echo "Coverage Collection Complete"
echo "========================================"
echo "Coverage data: ${COV_DIR}/coverage.dat"
echo "LCOV info: ${COV_DIR}/coverage.info"
echo "HTML report: ${REPORT_DIR}/index.html"
echo "Logs: ${LOG_DIR}/"
echo ""

# Display summary if genhtml was available
if [ -f "${REPORT_DIR}/index.html" ]; then
    grep -A2 "Overall coverage" "${LOG_DIR}/genhtml.log" 2>/dev/null || true
fi

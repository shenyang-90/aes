#!/bin/bash
#============================================================================
# Regression Script for AES IP - Verilator Only
# Usage: ./run_regression.sh [fast|full|cov]
#============================================================================

set -e

# Configuration
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
VERIF_DIR=$(dirname "$SCRIPT_DIR")
PROJECT_DIR="$VERIF_DIR/../.."

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

# Parse arguments
MODE="${1:-fast}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="$PROJECT_DIR/ProjectMgmt/Reviews/IDR/regression_${MODE}_${TIMESTAMP}.txt"

# Create directories
mkdir -p "$PROJECT_DIR/ProjectMgmt/Reviews/IDR" "$PROJECT_DIR/Temp/Regression"

echo "========================================" | tee "$REPORT_FILE"
echo "AES IP Regression Test ($MODE mode)" | tee -a "$REPORT_FILE"
echo "Tool: Verilator" | tee -a "$REPORT_FILE"
echo "Started: $(date)" | tee -a "$REPORT_FILE"
echo "========================================" | tee -a "$REPORT_FILE"

cd "$VERIF_DIR"

case "$MODE" in
    fast)
        echo "Running fast regression (compile + quick run)..." | tee -a "$REPORT_FILE"
        make clean compile 2>&1 | tee -a "$REPORT_FILE"
        make quick 2>&1 | tee -a "$REPORT_FILE"
        echo -e "${GREEN}Fast regression complete${NC}" | tee -a "$REPORT_FILE"
        ;;
    full)
        echo "Running full regression with coverage..." | tee -a "$REPORT_FILE"
        make clean-all cov 2>&1 | tee -a "$REPORT_FILE"
        echo -e "${GREEN}Full regression complete${NC}" | tee -a "$REPORT_FILE"
        ;;
    cov|coverage)
        echo "Running coverage collection..." | tee -a "$REPORT_FILE"
        ./Scripts/collect_coverage.sh 2>&1 | tee -a "$REPORT_FILE"
        echo -e "${GREEN}Coverage collection complete${NC}" | tee -a "$REPORT_FILE"
        ;;
    *)
        echo "Unknown mode: $MODE"
        echo "Usage: $0 [fast|full|cov]"
        echo ""
        echo "Modes:"
        echo "  fast  - Clean compile and quick run"
        echo "  full  - Full flow with coverage (make cov)"
        echo "  cov   - Run coverage collection script"
        exit 1
        ;;
esac

# Summary
echo "" | tee -a "$REPORT_FILE"
echo "========================================" | tee -a "$REPORT_FILE"
echo "Regression Complete: $(date)" | tee -a "$REPORT_FILE"
echo "========================================" | tee -a "$REPORT_FILE"
echo "Report: $REPORT_FILE" | tee -a "$REPORT_FILE"
echo "Coverage: $PROJECT_DIR/ProjectMgmt/Reviews/IDR/html/index.html" | tee -a "$REPORT_FILE"

# Link to latest
ln -sf "$REPORT_FILE" "$PROJECT_DIR/ProjectMgmt/Reviews/IDR/regression_latest.txt"

echo ""
echo "To view coverage report:"
echo "  firefox $PROJECT_DIR/ProjectMgmt/Reviews/IDR/html/index.html &"

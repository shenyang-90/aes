#!/bin/bash
#============================================================================
# Environment Setup Script for AES IP Verification
# Replaces: setup_verilator_cov.sh (simplified version)
# Usage: ./setup_env.sh
#============================================================================

set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
VERIF_DIR=$(dirname "$SCRIPT_DIR")
PROJECT_DIR="$VERIF_DIR/../.."

# Colors
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

echo "========================================"
echo "AES IP Verification Environment Setup"
echo "========================================"

# Check tools
check_tool() {
    local tool=$1
    local min_version=$2
    
    if command -v "$tool" &> /dev/null; then
        local version=$($tool --version 2>/dev/null | head -1 || echo "unknown")
        echo -e "${GREEN}✓${NC} $tool: $version"
        return 0
    else
        echo -e "${RED}✗${NC} $tool: not found"
        return 1
    fi
}

echo ""
echo "Checking Tools:"
check_tool "verilator" "5.0"
check_tool "iverilog" "10.0"
check_tool "genhtml" "1.0"
check_tool "make"
check_tool "python3"

# Create directories
echo ""
echo "Creating Directories:"
for dir in "$PROJECT_DIR/Temp/Regression" "$PROJECT_DIR/Temp/Coverage" \
           "$PROJECT_DIR/ProjectMgmt/Reviews/IDR"; do
    mkdir -p "$dir"
    echo -e "${GREEN}✓${NC} $dir"
done

# Check RTL files
echo ""
echo "Checking RTL Files:"
RTL_DIR="$PROJECT_DIR/Database/RTL"
if [ -d "$RTL_DIR" ]; then
    local rtl_count=$(find "$RTL_DIR" -name "*.v" | wc -l)
    echo -e "${GREEN}✓${NC} RTL files: $rtl_count found"
else
    echo -e "${RED}✗${NC} RTL directory not found: $RTL_DIR"
fi

# Check Testcases
echo ""
echo "Checking Testcases:"
TC_DIR="$VERIF_DIR/Testcases/directed"
if [ -d "$TC_DIR" ]; then
    local tc_count=$(find "$TC_DIR" -name "*.sv" | wc -l)
    echo -e "${GREEN}✓${NC} Testcases: $tc_count found"
else
    echo -e "${RED}✗${NC} Testcase directory not found: $TC_DIR"
fi

echo ""
echo "========================================"
echo "Setup Complete!"
echo "========================================"
echo ""
echo "Quick Start:"
echo "  1. Run regression:  ./Scripts/run_regression.sh fast"
echo "  2. Run coverage:    ./Scripts/run_coverage.sh verilator baseline"
echo "  3. Generate report: ./Scripts/generate_report.sh"
echo ""

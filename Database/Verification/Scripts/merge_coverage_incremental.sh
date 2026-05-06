#!/bin/bash
#============================================================================
# Incremental Coverage Merge Script
# Description: Merge new testcase coverage with existing merged coverage
# Usage: ./merge_coverage_incremental.sh <new_testcase_name>
# Example: ./merge_coverage_incremental.sh tc_new_feature
#============================================================================

set -e

# Check arguments
if [ $# -lt 1 ]; then
    echo "Usage: $0 <new_testcase_name>"
    echo "Example: $0 tc_new_feature"
    exit 1
fi

NEW_TC=$1
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
PROJECT_DIR="$SCRIPT_DIR/../../.."
TEMP_DIR="$PROJECT_DIR/Temp/Verilator"
COV_DIR="$TEMP_DIR/coverage"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "========================================"
echo "Incremental Coverage Merge"
echo "========================================"
echo "New testcase: $NEW_TC"
echo ""

# Check if new coverage data exists
if [ ! -f "$COV_DIR/${NEW_TC}.dat" ]; then
    echo "Error: Coverage data not found: $COV_DIR/${NEW_TC}.dat"
    echo "Please run the testcase first to generate coverage data."
    exit 1
fi

# Check if existing merged coverage exists
if [ ! -f "$COV_DIR/merged.info" ]; then
    echo "Warning: Existing merged.info not found."
    echo "Creating new merged coverage from all .dat files..."
    cd "$COV_DIR"
    verilator_coverage --write merged.info *.dat
    echo -e "${GREEN}Created new merged.info${NC}"
    exit 0
fi

# Backup existing merged coverage
echo "Backing up existing merged.info..."
cp "$COV_DIR/merged.info" "$COV_DIR/merged.info.backup"

# Merge new coverage with existing
echo "Merging ${NEW_TC}.dat into merged.info..."
cd "$COV_DIR"
verilator_coverage --write merged_new.info merged.info "${NEW_TC}.dat"

# Replace old merged with new
mv merged_new.info merged.info

# Count testcases
TC_COUNT=$(ls *.dat 2>/dev/null | wc -l)
echo ""
echo -e "${GREEN}Merge complete!${NC}"
echo "Total testcases in coverage: $TC_COUNT"
echo ""

# Optional: Generate HTML report
REPORT_DIR="$TEMP_DIR/html"
mkdir -p "$REPORT_DIR"
read -p "Generate HTML report? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Generating HTML report..."
    genhtml merged.info -o "$REPORT_DIR" --no-function-coverage 2>/dev/null || \
    genhtml merged.info -o "$REPORT_DIR" 2>/dev/null || \
    echo "HTML generation skipped (genhtml not available)"
    echo -e "${GREEN}HTML report: $REPORT_DIR/index.html${NC}"
fi

echo ""
echo "Backup saved as: merged.info.backup"
echo "========================================"

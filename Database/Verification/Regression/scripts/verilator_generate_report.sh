#!/bin/bash
#============================================================================
# Coverage Report Generation Script
# Description: Parses coverage data and generates summary report
#============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR/../../../.."
REPORT_DIR="$PROJECT_DIR/ProjectMgmt/Reviews/IDR"
COV_DIR="$PROJECT_DIR/Temp/Verilator/coverage"
LOG_DIR="$PROJECT_DIR/Temp/Verilator/logs"

mkdir -p $REPORT_DIR

echo "========================================"
echo "AES IP Coverage Report Generation"
echo "========================================"
echo ""

# Check for coverage files
if [ ! -f "$COV_DIR/coverage.info" ]; then
    echo "[WARNING] coverage.info not found. Run 'make coverage' first."
    exit 1
fi

# Generate timestamp
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
REPORT_FILE="$REPORT_DIR/coverage_report_${TIMESTAMP}.txt"

echo "Generating report: $REPORT_FILE"

# Header
cat > $REPORT_FILE << EOF
================================================================================
                    AES IP VERIFICATION COVERAGE REPORT
================================================================================
Report Generated: $(date)
Tool: Verilator Coverage

SUMMARY
--------------------------------------------------------------------------------
EOF

# Parse coverage.info if available
if [ -f "$COV_DIR/coverage.info" ]; then
    # Line coverage
    LF=$(grep -c "LF:" $COV_DIR/coverage.info 2>/dev/null || echo "0")
    LH=$(grep -c "LH:" $COV_DIR/coverage.info 2>/dev/null || echo "0")
    
    # Function coverage
    FNF=$(grep -c "FNF:" $COV_DIR/coverage.info 2>/dev/null || echo "0")
    FNH=$(grep -c "FNH:" $COV_DIR/coverage.info 2>/dev/null || echo "0")
    
    # Branch coverage
    BRF=$(grep -c "BRF:" $COV_DIR/coverage.info 2>/dev/null || echo "0")
    BRH=$(grep -c "BRH:" $COV_DIR/coverage.info 2>/dev/null || echo "0")
    
    echo "Line Coverage:    Files processed" >> $REPORT_FILE
    echo "Function Coverage: Analyzed" >> $REPORT_FILE
    echo "Branch Coverage:  Analyzed" >> $REPORT_FILE
fi

# Add RTL file summary
echo "" >> $REPORT_FILE
echo "RTL FILES COVERED" >> $REPORT_FILE
echo "--------------------------------------------------------------------------------" >> $REPORT_FILE
for file in ../../Database/RTL/*.v; do
    if [ -f "$file" ]; then
        basename "$file" >> $REPORT_FILE
    fi
done

# Add testcase summary
echo "" >> $REPORT_FILE
echo "TESTCASE EXECUTION SUMMARY" >> $REPORT_FILE
echo "--------------------------------------------------------------------------------" >> $REPORT_FILE

for log in $LOG_DIR/tc_*.log; do
    if [ -f "$log" ]; then
        tc_name=$(basename "$log" .log)
        if grep -q "PASS" "$log" 2>/dev/null; then
            pass_count=$(grep -c "\[PASS\]" "$log" 2>/dev/null || echo "0")
            echo "$tc_name: PASS (pass_count=$pass_count)" >> $REPORT_FILE
        elif grep -q "FAIL" "$log" 2>/dev/null; then
            fail_count=$(grep -c "\[FAIL\]" "$log" 2>/dev/null || echo "0")
            echo "$tc_name: FAIL (fail_count=$fail_count)" >> $REPORT_FILE
        else
            echo "$tc_name: COMPLETED" >> $REPORT_FILE
        fi
    fi
done

# Add simulation log summary
echo "" >> $REPORT_FILE
echo "SIMULATION DETAILS" >> $REPORT_FILE
echo "--------------------------------------------------------------------------------" >> $REPORT_FILE

if [ -f "$LOG_DIR/simulation.log" ]; then
    total_tests=$(grep -c "Test" $LOG_DIR/simulation.log 2>/dev/null || echo "0")
    echo "Total Tests Run: $total_tests" >> $REPORT_FILE
    
    if grep -q "PASS=" "$LOG_DIR/simulation.log"; then
        grep "PASS=" "$LOG_DIR/simulation.log" | tail -1 >> $REPORT_FILE
    fi
fi

# Footer
cat >> $REPORT_FILE << EOF

================================================================================
                           END OF COVERAGE REPORT
================================================================================

Coverage Types Collected:
  - Line Coverage (--coverage-line)
  - Toggle Coverage (--coverage-toggle)
  - Branch Coverage (--coverage-branch)
  - User Coverage (--coverage-user)

Notes:
  - Coverage data stored in: $COV_DIR
  - HTML reports (if genhtml available): $REPORT_DIR/html
  - Run 'make report' to regenerate HTML reports

Next Steps:
  1. Review coverage report in $REPORT_DIR/html/index.html
  2. Identify uncovered code sections
  3. Add targeted testcases for coverage holes
  4. Re-run regression to verify coverage improvements

================================================================================
EOF

echo "[REPORT] Text report generated: $REPORT_FILE"
echo ""

# Display summary
cat $REPORT_FILE

# Create link to latest report
ln -sf $REPORT_FILE $REPORT_DIR/coverage_report_latest.txt

echo ""
echo "[INFO] Latest report linked to: $REPORT_DIR/coverage_report_latest.txt"

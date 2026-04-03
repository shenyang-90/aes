#!/bin/bash
#============================================================================
# Unified Report Generation Script for AES IP
# Replaces: verilator_generate_report.sh + generate_report.py
# Usage: ./generate_report.sh [text|html|all]
#============================================================================

set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
VERIF_DIR=$(dirname "$SCRIPT_DIR")
PROJECT_DIR="$VERIF_DIR/../.."
REPORT_DIR="$PROJECT_DIR/ProjectMgmt/Reviews/IDR"
COV_DIR="$PROJECT_DIR/Temp/Coverage"
REG_DIR="$PROJECT_DIR/Temp/Regression"

# Colors
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

# Parse arguments
FORMAT="${1:-all}"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')

mkdir -p "$REPORT_DIR"

echo "========================================"
echo "AES IP Report Generation"
echo "Format: $FORMAT"
echo "========================================"

#============================================================================
# Generate Text Report
#============================================================================
generate_text_report() {
    local report_file="$REPORT_DIR/verification_report_${TIMESTAMP}.txt"
    
    cat > "$report_file" << EOF
================================================================================
                    AES IP VERIFICATION REPORT
================================================================================
Generated: $(date)

SUMMARY
--------------------------------------------------------------------------------
EOF

    # Coverage Summary
    if [ -f "$COV_DIR/merged/coverage.info" ]; then
        echo "Coverage Data: Available" >> "$report_file"
        local lines=$(grep -c "^DA:" "$COV_DIR/merged/coverage.info" 2>/dev/null || echo "0")
        echo "Coverage Points: $lines" >> "$report_file"
    else
        echo "Coverage Data: Not available" >> "$report_file"
    fi
    
    # Regression Summary
    echo "" >> "$report_file"
    echo "REGRESSION RESULTS" >> "$report_file"
    echo "--------------------------------------------------------------------------------" >> "$report_file"
    
    local latest_reg="$REPORT_DIR/regression_latest.txt"
    if [ -f "$latest_reg" ]; then
        grep -E "^(Total|Pass|Fail|Timeout):" "$latest_reg" >> "$report_file" 2>/dev/null || true
    else
        echo "No regression data available" >> "$report_file"
    fi
    
    # RTL Files
    echo "" >> "$report_file"
    echo "RTL FILES" >> "$report_file"
    echo "--------------------------------------------------------------------------------" >> "$report_file"
    find "$PROJECT_DIR/Database/RTL" -name "*.v" -exec basename {} \; | sort >> "$report_file"
    
    # Footer
    cat >> "$report_file" << EOF

================================================================================
                           END OF REPORT
================================================================================
EOF

    echo -e "${GREEN}Text report: $report_file${NC}"
    ln -sf "$report_file" "$REPORT_DIR/verification_report_latest.txt"
}

#============================================================================
# Generate HTML Report
#============================================================================
generate_html_report() {
    local html_file="$REPORT_DIR/verification_report_${TIMESTAMP}.html"
    local total=0; local pass=0; local fail=0
    
    # Parse latest regression
    local latest_reg="$REPORT_DIR/regression_latest.txt"
    if [ -f "$latest_reg" ]; then
        total=$(grep "^Total:" "$latest_reg" | awk '{print $2}' 2>/dev/null || echo "0")
        pass=$(grep "^Pass:" "$latest_reg" | awk '{print $2}' 2>/dev/null || echo "0")
        fail=$(grep "^Fail:" "$latest_reg" | awk '{print $2}' 2>/dev/null || echo "0")
    fi
    
    local pass_rate=0
    [ $total -gt 0 ] && pass_rate=$((pass * 100 / total))
    
    cat > "$html_file" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>AES IP Verification Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .header { background: #2c3e50; color: white; padding: 20px; border-radius: 5px; }
        .summary { background: white; padding: 20px; border-radius: 5px; margin: 20px 0; }
        .metric { display: inline-block; margin: 10px 30px; text-align: center; }
        .metric-value { font-size: 36px; font-weight: bold; }
        .pass { color: #27ae60; } .fail { color: #e74c3c; }
        table { width: 100%; border-collapse: collapse; background: white; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background: #34495e; color: white; }
        a { color: #2980b9; }
    </style>
</head>
<body>
    <div class="header">
        <h1>AES IP Verification Report</h1>
        <p>Generated: $(date)</p>
    </div>
    
    <div class="summary">
        <h2>Regression Summary</h2>
        <div class="metric">
            <div class="metric-value">$total</div>
            <div>Total Tests</div>
        </div>
        <div class="metric">
            <div class="metric-value pass">$pass</div>
            <div>Passed</div>
        </div>
        <div class="metric">
            <div class="metric-value fail">$fail</div>
            <div>Failed</div>
        </div>
        <div class="metric">
            <div class="metric-value ${pass_rate>=90?'pass':'fail'}">$pass_rate%</div>
            <div>Pass Rate</div>
        </div>
    </div>
    
    <div class="summary">
        <h2>Reports</h2>
        <table>
            <tr><th>Report Type</th><th>Location</th><th>Status</th></tr>
            <tr>
                <td>Coverage HTML</td>
                <td><a href="html/index.html">html/index.html</a></td>
                <td>$([ -f "$REPORT_DIR/html/index.html" ] && echo "Available" || echo "Not generated")</td>
            </tr>
            <tr>
                <td>Latest Regression</td>
                <td><a href="regression_latest.txt">regression_latest.txt</a></td>
                <td>$([ -f "$REPORT_DIR/regression_latest.txt" ] && echo "Available" || echo "Not available")</td>
            </tr>
        </table>
    </div>
</body>
</html>
EOF

    echo -e "${GREEN}HTML report: $html_file${NC}"
}

#============================================================================
# Main
#============================================================================
case "$FORMAT" in
    text) generate_text_report ;;
    html) generate_html_report ;;
    all) generate_text_report; generate_html_report ;;
    *) echo "Unknown format: $FORMAT. Use: text|html|all"; exit 1 ;;
esac

echo ""
echo "========================================"
echo "Report Generation Complete"
echo "========================================"
echo "Reports: $REPORT_DIR/"

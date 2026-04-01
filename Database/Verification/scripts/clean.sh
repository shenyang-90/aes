#!/bin/bash
#============================================================================
# Clean Script for AES IP Verification Environment
# Description: Clean generated files and temporary data
#============================================================================

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
VERIF_DIR=$(dirname "$SCRIPT_DIR")

echo "========================================"
echo "AES IP Verification Clean"
echo "========================================"

# Clean coverage data
echo "Cleaning coverage data..."
rm -f "$VERIF_DIR/Coverage/data"/*.txt
rm -f "$VERIF_DIR/Coverage/data"/*.db
rm -f "$VERIF_DIR/Coverage/html"/*.html
rm -f "$VERIF_DIR/Coverage/html"/*.css
echo "  ✓ Coverage data cleaned"

# Clean regression reports
echo "Cleaning regression reports..."
find "$VERIF_DIR/Regression/reports" -type f ! -name "README.md" -delete
echo "  ✓ Regression reports cleaned"

# Clean compiled outputs in testcases
echo "Cleaning compiled outputs..."
find "$VERIF_DIR/Testcases" -name "*.out" -delete
find "$VERIF_DIR/Testcases" -name "*.vvp" -delete
echo "  ✓ Compiled outputs cleaned"

# Clean waveform files
echo "Cleaning waveform files..."
find "$VERIF_DIR" -name "*.vcd" -delete 2>/dev/null
find "$VERIF_DIR" -name "*.fst" -delete 2>/dev/null
echo "  ✓ Waveform files cleaned"

echo ""
echo "========================================"
echo "Clean Complete"
echo "========================================"
echo "Note: Source files are preserved."
echo "      Only generated files are removed."

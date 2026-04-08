#!/bin/bash
#============================================================================
# Verdi Launch Script for AES IP
# Description: Open waveform or coverage in Verdi
# Usage: 
#   ./launch_verdi.sh waveform [testcase_name]
#   ./launch_verdi.sh coverage [vdb_path]
#============================================================================

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

# Directories
RTL_DIR="${PROJECT_ROOT}/Database/RTL"
VCS_DIR="${PROJECT_ROOT}/Temp/VCS"
VERILATOR_DIR="${PROJECT_ROOT}/Temp/Verilator"

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

# Check Verdi availability
if ! command -v verdi &> /dev/null; then
    echo -e "${RED}[ERROR] Verdi not found in PATH${NC}"
    echo "Please load Verdi environment:"
    echo "  source <vcs_install>/setup.sh"
    exit 1
fi

# Parse arguments
MODE="${1:-waveform}"
shift || true

case "${MODE}" in
    waveform|wave|w)
        TESTCASE="${1:-}"
        
        echo "========================================"
        echo "Launching Verdi - Waveform Viewer"
        echo "========================================"
        
        # Try to find waveform database
        if [ -n "${TESTCASE}" ] && [ -d "${VCS_DIR}/${TESTCASE}.vdb" ]; then
            echo "Opening VDB: ${TESTCASE}.vdb"
            verdi -dbdir "${VCS_DIR}/${TESTCASE}.vdb" &
        elif [ -d "${VCS_DIR}/simv.vdb" ]; then
            echo "Opening: simv.vdb"
            verdi -dbdir "${VCS_DIR}/simv.vdb" &
        elif [ -f "${VERILATOR_DIR}/waveform.vcd" ]; then
            echo "Opening VCD: waveform.vcd"
            # Need to convert or use with FSDB
            if command -v vcd2fsdb &> /dev/null; then
                echo "Converting VCD to FSDB..."
                vcd2fsdb "${VERILATOR_DIR}/waveform.vcd" -o "${VERILATOR_DIR}/waveform.fsdb"
                verdi -ssf "${VERILATOR_DIR}/waveform.fsdb" &
            else
                echo -e "${YELLOW}[WARN] vcd2fsdb not found, trying direct VCD open${NC}"
                verdi -ssf "${VERILATOR_DIR}/waveform.vcd" &
            fi
        else
            echo -e "${RED}[ERROR] No waveform database found${NC}"
            echo "Run simulation first:"
            echo "  make vcs-run"
            echo "  or"
            echo "  ./run_vcs.sh <testcase>"
            exit 1
        fi
        ;;
        
    coverage|cov|c)
        VDB_PATH="${1:-}"
        
        echo "========================================"
        echo "Launching Verdi - Coverage Viewer"
        echo "========================================"
        
        if [ -n "${VDB_PATH}" ] && [ -d "${VDB_PATH}" ]; then
            echo "Opening coverage: ${VDB_PATH}"
            verdi -cov -covdir "${VDB_PATH}" &
        elif [ -d "${VCS_DIR}/coverage/merged/merged.vdb" ]; then
            echo "Opening merged coverage"
            verdi -cov -covdir "${VCS_DIR}/coverage/merged/merged.vdb" &
        elif [ -d "${VCS_DIR}/simv.vdb" ]; then
            echo "Opening: simv.vdb"
            verdi -cov -covdir "${VCS_DIR}/simv.vdb" &
        else
            # Find any vdb directory
            VDB=$(find "${VCS_DIR}" -name "*.vdb" -type d | head -1)
            if [ -n "${VDB}" ]; then
                echo "Opening: ${VDB}"
                verdi -cov -covdir "${VDB}" &
            else
                echo -e "${RED}[ERROR] No coverage database found${NC}"
                echo "Run coverage collection first:"
                echo "  make vcs-cov"
                echo "  or"
                echo "  ./run_vcs_coverage_batch.sh"
                exit 1
            fi
        fi
        ;;
        
    debug|d)
        echo "========================================"
        echo "Launching Verdi - Interactive Debug"
        echo "========================================"
        
        # Open with RTL files loaded
        if [ -d "${VCS_DIR}/simv.vdb" ]; then
            verdi -dbdir "${VCS_DIR}/simv.vdb" -ssf "${VCS_DIR}/simv.vdb" &
        else
            # Open with just RTL
            RTL_FILES=$(find "${RTL_DIR}" -name "*.v" | tr '\n' ' ')
            verdi -sv ${RTL_FILES} &
        fi
        ;;
        
    *)
        echo "Usage:"
        echo "  $0 waveform [testcase]  - Open waveform viewer"
        echo "  $0 coverage [vdb_path]  - Open coverage viewer"
        echo "  $0 debug                - Open interactive debug"
        echo ""
        echo "Examples:"
        echo "  $0 waveform tc_smoke"
        echo "  $0 coverage"
        echo "  $0 coverage ${VCS_DIR}/tc_smoke.vdb"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}Verdi launched in background${NC}"
echo "Note: Verdi may take a moment to fully load..."

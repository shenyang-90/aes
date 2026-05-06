# AES IP Verification Scripts

## Overview

This directory contains verification scripts supporting multiple simulators:
- **Verilator** (default, open-source)
- **VCS** (Synopsys, commercial)
- **Verdi** (Synopsys, debug and coverage)

## Quick Start

### Verilator (Default)
```bash
# Run regression
./run_regression.sh fast

# Collect coverage
./run_coverage_batch.sh

# Or use Makefile
make cov
```

### VCS + Verdi
```bash
# Setup VCS environment first
source <vcs_install_path>/setup.sh

# Run single testcase with VCS
./run_vcs.sh tc_smoke

# Run batch coverage collection
./run_vcs_coverage_batch.sh

# Open waveform in Verdi
./launch_verdi.sh waveform tc_smoke

# Open coverage in Verdi
./launch_verdi.sh coverage

# Or use Makefile
make vcs-cov          # Full VCS flow
make verdi            # Open waveform
make verdi-cov        # Open coverage
```

## Scripts Reference

### Verilator Scripts

| Script | Description | Usage |
|--------|-------------|-------|
| `collect_coverage.sh` | Collect coverage with Verilator | `./collect_coverage.sh` |
| `run_coverage_batch.sh` | Batch coverage for all tests | `./run_coverage_batch.sh [test_list]` |
| `run_regression.sh` | Run regression tests | `./run_regression.sh [fast|full|cov]` |
| `merge_coverage_incremental.sh` | Merge coverage incrementally | `./merge_coverage_incremental.sh <tc>` |

### VCS Scripts

| Script | Description | Usage |
|--------|-------------|-------|
| `run_vcs.sh` | Run single testcase with VCS | `./run_vcs.sh [testcase]` |
| `run_vcs_coverage_batch.sh` | Batch coverage with VCS | `./run_vcs_coverage_batch.sh [test_list]` |

### Verdi Scripts

| Script | Description | Usage |
|--------|-------------|-------|
| `launch_verdi.sh` | Launch Verdi GUI | `./launch_verdi.sh [waveform|coverage|debug]` |

### Utility Scripts

| Script | Description | Usage |
|--------|-------------|-------|
| `setup_env.sh` | Environment setup | `./setup_env.sh` |

## Makefile Targets

### Verilator Targets
```bash
make compile      # Compile with Verilator
make run          # Run simulation
make coverage     # Collect coverage
make report       # Generate HTML report
make cov          # Full flow (compile+run+coverage+report)
make quick        # Quick run (no recompile)
```

### VCS Targets
```bash
make vcs-compile  # Compile with VCS
make vcs-run      # Run VCS simulation
make vcs-coverage # Collect VCS coverage
make vcs-cov      # Full VCS flow
```

### Verdi Targets
```bash
make verdi        # Open Verdi waveform viewer
make verdi-cov    # Open Verdi coverage viewer
```

### Utility Targets
```bash
make clean        # Clean Verilator artifacts
make clean-all    # Clean all
make clean-vcs    # Clean VCS artifacts
make view         # Open coverage report in browser
make list-tests   # List all testcases
make help         # Show help
```

## Coverage Output Structure

### Verilator
```
Temp/Verilator/
├── coverage/
│   ├── merged.info          # Merged coverage data
│   ├── rtl.info             # RTL-only coverage
│   └── tc_*.dat (66 files)  # Per-test coverage
├── html/
│   ├── index.html           # Coverage report
│   └── RTL/                 # RTL module reports
└── logs/                    # Build and run logs
```

### VCS
```
Temp/VCS/
├── coverage/
│   ├── merged/              # Merged coverage reports
│   └── tc_*/                # Per-test coverage
├── simv.vdb                 # Simulation database
├── simv                     # Compiled simulator
└── logs/                    # Build and run logs
```

### Reports
```
ProjectMgmt/Reviews/IDR/
├── COVERAGE_REPORT.md       # Verilator coverage summary
├── VCS_COVERAGE_REPORT.md   # VCS coverage summary
└── ...
```

## Tool Requirements

### Verilator (Open Source)
- verilator >= 5.0
- lcov/genhtml (optional, for HTML reports)
- gtkwave (optional, for waveform viewing)

### VCS + Verdi (Commercial)
- VCS (Synopsys)
- Verdi (Synopsys)
- URG (Unified Report Generator, included with VCS)

Load VCS environment before use:
```bash
source <synopsys_install>/vcs/setup.sh
source <synopsys_install>/verdi/setup.sh
```

## Coverage Comparison

| Feature | Verilator | VCS |
|---------|-----------|-----|
| Line Coverage | ✓ | ✓ |
| Toggle Coverage | ✓ | ✓ |
| FSM Coverage | Limited | ✓ |
| Branch Coverage | ✓ | ✓ |
| Condition Coverage | ✓ | ✓ |
| GUI Debugger | No | Verdi |
| Waveform Viewer | VCD/FSDB | Verdi |
| Coverage Merge | lcov | URG |
| License | Open Source | Commercial |

## Examples

### Run with Verilator
```bash
# Full coverage flow
cd Database/Verification
make cov

# View report
firefox ../../Temp/Verilator/html/index.html
```

### Run with VCS
```bash
# Setup
source /tools/synopsys/vcs/setup.sh

# Run single test
cd Database/Verification
./Scripts/run_vcs.sh tc_smoke

# Run batch coverage
./Scripts/run_vcs_coverage_batch.sh

# View in Verdi
./Scripts/launch_verdi.sh coverage
```

### Debug with Verdi
```bash
# After running VCS simulation
./Scripts/launch_verdi.sh waveform tc_smoke

# Or open specific VDB
./Scripts/launch_verdi.sh waveform Temp/VCS/tc_smoke.vdb
```

## Notes

1. **VCS License**: Ensure you have valid VCS/Verdi licenses before running
2. **Disk Space**: VCS generates larger files than Verilator (VDB databases)
3. **Runtime**: VCS is generally faster for large designs but has license overhead
4. **Coverage**: Both tools provide compatible coverage metrics

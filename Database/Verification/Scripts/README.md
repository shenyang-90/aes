# AES IP Verification Scripts

## Overview

This directory contains optimized verification scripts. The original 12 scripts have been consolidated into 4 core scripts for better maintainability.

## Quick Start

```bash
# 1. Setup environment
./setup_env.sh

# 2. Run regression (fast mode: 10 tests)
./run_regression.sh fast

# 3. Run full regression (32 tests)
./run_regression.sh full

# 4. Collect coverage with Verilator
./run_coverage.sh verilator baseline

# 5. Generate reports
./generate_report.sh
```

## Core Scripts

### 1. setup_env.sh
Environment setup and tool checking.
- Checks for verilator, iverilog, genhtml, make, python3
- Creates required directories
- Verifies RTL and testcase presence

### 2. run_regression.sh
Unified regression testing (replaces 3 scripts).
```bash
Usage: ./run_regression.sh [fast|full|coverage] [test_name]

Modes:
  fast     - 10 key tests with 60s timeout
  full     - 32 tests with 120s timeout  
  coverage - 20 tests with 180s timeout

Examples:
  ./run_regression.sh fast              # Quick regression
  ./run_regression.sh full              # Full regression
  ./run_regression.sh fast tc_smoke     # Single test
```

### 3. run_coverage.sh
Unified coverage collection (replaces 6 scripts).
```bash
Usage: ./run_coverage.sh [verilator|iverilog] [test_name|all|baseline|new]

Options:
  Tool: verilator | iverilog
  Test: all | baseline | new | <specific_test>

Examples:
  ./run_coverage.sh verilator baseline  # 5 baseline tests
  ./run_coverage.sh verilator new       # 4 new tests
  ./run_coverage.sh verilator all       # All 53 tests
  ./run_coverage.sh iverilog tc_smoke   # Single test with Icarus
```

### 4. generate_report.sh
Unified report generation (replaces 2 scripts).
```bash
Usage: ./generate_report.sh [text|html|all]

Formats:
  text - Plain text report
  html - HTML report with metrics
  all  - Both formats
```

## Deprecated Scripts

The following scripts have been archived to `deprecated/` directory:

| Old Script | Replaced By | Reason |
|------------|-------------|--------|
| collect_coverage.sh | run_coverage.sh | Function overlap |
| run_coverage.sh (old) | run_coverage.sh | Consolidated |
| run_iverilog_coverage.sh | run_coverage.sh iverilog | Merged |
| run_iverilog_cov.sh | run_coverage.sh iverilog | Merged |
| run_new_coverage_tests.sh | run_coverage.sh verilator new | Merged |
| run_regression_fast.sh | run_regression.sh fast | Merged |
| run_all_testcases_coverage.sh | run_coverage.sh verilator all | Merged |
| verilator_collect_coverage.sh | run_coverage.sh verilator | Merged |
| verilator_generate_report.sh | generate_report.sh | Consolidated |
| generate_report.py | generate_report.sh html | Replaced by bash |
| setup_verilator_cov.sh | setup_env.sh | Simplified |

## Output Structure

```
ProjectMgmt/Reviews/IDR/
├── regression_latest.txt         # Latest regression results
├── regression_<mode>_<time>.txt  # Timestamped regression
├── verification_report_latest.*  # Latest verification report
├── html/                         # Coverage HTML reports
└── coverage/                     # Coverage data

Temp/
├── Regression/                   # Regression logs
└── Coverage/                     # Coverage data
    ├── data/                     # Per-test coverage
    ├── merged/                   # Merged coverage
    └── html/                     # HTML reports
```

## Migration Guide

### Before (12 scripts)
```bash
./run_regression_fast.sh              # Fast regression
./run_new_coverage_tests.sh           # New tests
./verilator_generate_report.sh        # Report
```

### After (4 scripts)
```bash
./run_regression.sh fast              # Fast regression
./run_coverage.sh verilator new       # New tests
./generate_report.sh                  # Report
```

## Benefits of Consolidation

1. **Reduced Maintenance**: 4 scripts vs 12 scripts (67% reduction)
2. **Consistent Interface**: All scripts use similar argument patterns
3. **Unified Output**: All reports go to IDR directory
4. **Better Documentation**: Single README for all scripts
5. **No Redundancy**: Each script has a clear, distinct purpose

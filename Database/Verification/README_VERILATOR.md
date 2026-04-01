# AES IP Verilator Coverage Environment

## Overview
This directory contains the Verilator-based simulation environment for AES IP coverage collection and random testing.

## Directory Structure
```
Temp/Verilator/
├── Makefile                  # Main build configuration
├── sim_main.cpp             # C++ simulation wrapper
├── tb_coverage.sv           # Coverage testbench top
├── collect_coverage.sh      # Automated coverage collection script
├── generate_report.sh       # Coverage report generator
├── logs/                    # Simulation logs
├── coverage/                # Coverage data files
├── reports/                 # Generated reports
└── obj_dir/                 # Verilator build output
```

## Quick Start

### 1. Setup
```bash
cd Temp/Verilator
make setup
```

### 2. Compile and Run (Single Test)
```bash
make all
# This will: compile -> run -> collect coverage -> generate report
```

### 3. Run All Random Testcases
```bash
make run_all
```

### 4. Generate HTML Report
```bash
make report
```

## Available Make Targets

| Target | Description |
|--------|-------------|
| `make all` | Full flow: compile, run, coverage, report |
| `make setup` | Create output directories |
| `make compile` | Compile with Verilator |
| `make run` | Run simulation |
| `make coverage` | Collect coverage data |
| `make report` | Generate HTML/text reports |
| `make run_all` | Run all 5 random testcases |
| `make merge_cov` | Merge coverage from all runs |
| `make clean` | Clean build artifacts |
| `make clean_all` | Clean everything including reports |
| `make help` | Show help message |

## Coverage Collection

### Using collect_coverage.sh (Recommended)
```bash
./collect_coverage.sh
```

This script will:
1. Run all 5 random testcases individually
2. Collect coverage for each testcase
3. Merge coverage data
4. Generate HTML report

### Coverage Types Collected
- **Line Coverage** (`--coverage-line`): Code line execution
- **Toggle Coverage** (`--coverage-toggle`): Signal transitions
- **Branch Coverage** (`--coverage-branch`): Conditional branches
- **User Coverage** (`--coverage-user`): User-defined coverage

## Random Testcases

### 1. tc_random_modes
- Random mode switching (ECB/CBC/CTR/GCM/XTS/CTS)
- Cross coverage: mode × key_len × operation
- 50 random transactions

### 2. tc_random_keys
- Random key generation (128/192/256-bit)
- Special patterns: zeros, ones, alternating, incremental
- 80 key tests

### 3. tc_random_data
- Random plaintext patterns
- Walking 0/1 patterns (128-bit)
- Sparse/dense patterns
- Special data patterns

### 4. tc_random_errors
- Invalid address access
- Reserved bit handling
- Invalid mode/keylen values
- Interrupt toggle tests

### 5. tc_stress_random
- Back-to-back operations
- Rapid mode switching
- Key stress tests
- Mixed stress scenarios

## Viewing Coverage Reports

### HTML Report (requires lcov/genhtml)
```bash
cd coverage_runs_YYYYMMDD_HHMMSS/merged/html
firefox index.html
```

### Text Report
```bash
cat reports/coverage_report_latest.txt
```

### Coverage Data Files
- `coverage/merged.info` - Merged LCOV info file
- `coverage/merged.dat` - Verilator coverage database

## Integration with Regression

The random testcases are integrated into the regression flow:

```bash
# Run in regression mode
cd Database/Verification/Regression
./run_coverage.sh all
```

## Requirements

- Verilator >= 5.0
- GNU Make
- C++17 compiler (g++/clang++)
- lcov/genhtml (optional, for HTML reports)

## Troubleshooting

### Compilation Errors
1. Check Verilator version: `verilator --version`
2. Verify RTL files exist: `ls ../../Database/RTL/*.v`
3. Check C++ compiler: `g++ --version`

### Coverage Collection Issues
1. Ensure simulation completed successfully
2. Check `logs/*.log` for errors
3. Verify coverage data exists: `ls coverage/*.dat`

### Report Generation Issues
1. Install lcov for HTML reports: `apt-get install lcov`
2. Check permissions: `chmod +x *.sh`
3. Verify report directory exists: `ls reports/`

## Notes

- Coverage data is cumulative - run `make clean` to start fresh
- Each testcase runs independently for better isolation
- Merged coverage provides combined view of all testcases
- HTML reports provide interactive code coverage browsing

## References

- [Verilator User Guide](https://verilator.org/guide/)
- [LCOV Documentation](http://ltp.sourceforge.net/coverage/lcov.php)
- AES IP Verification Plan: `Database/Docs/Verification/Verification_Plan.md`

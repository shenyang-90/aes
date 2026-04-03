# Sourceme Script Guide

## Overview

The `sourceme` script sets up the complete environment for the AES IP verification project. It defines all necessary environment variables, tool paths, and utility functions.

## Usage

```bash
# Source the environment (run from project root)
cd /home/CALTERAH/yshen/sandbox/kimi/sandbox/aes
source sourceme

# Or directly
source /path/to/sandbox/aes/sourceme
```

## Environment Variables

### Directory Paths
| Variable | Description |
|----------|-------------|
| `AES_PROJECT_ROOT` | Project root directory |
| `AES_RTL_DIR` | RTL source files (14 modules) |
| `AES_VERIF_DIR` | Verification environment |
| `AES_TB_DIR` | Testbench files |
| `AES_SVA_DIR` | SystemVerilog Assertions |
| `AES_TC_DIR` | Testcases (53 tests) |
| `AES_SCRIPTS_DIR` | Verification scripts |
| `AES_IDR_DIR` | IDR review reports |
| `AES_TEMP_DIR` | Temporary/build files |

### Tool Paths
| Variable | Tool |
|----------|------|
| `VERILATOR` | Verilator compiler |
| `VERILATOR_COVERAGE` | Verilator coverage tool |
| `IVERILOG` | Icarus Verilog |
| `VVP` | Icarus Verilog runtime |
| `GTKWAVE` | Waveform viewer |
| `GENHTML` | LCOV HTML generator |

### Compilation Flags
| Variable | Description |
|----------|-------------|
| `VERILATOR_FLAGS` | Standard Verilator flags |
| `VERILATOR_WARNINGS` | Warning suppressions |
| `VERILATOR_CFLAGS` | C++ compiler flags |
| `IVERILOG_FLAGS` | Iverilog flags |

## Utility Functions

### Information
```bash
aes_info              # Display project information
aes_list_tests        # List all 53 testcases
```

### Execution
```bash
aes_regression [mode]     # Run regression (fast/full/coverage)
aes_coverage [tool] [test] # Collect coverage (verilator/iverilog)
aes_report [format]       # Generate reports (text/html/all)
aes_run_test <testname>   # Run single testcase
aes_full_flow             # Complete verification flow
```

### Navigation
```bash
rtl         # cd to RTL directory
verif       # cd to Verification directory
tc          # cd to Testcases directory
scripts     # cd to Scripts directory
idr         # cd to IDR reports directory
temp        # cd to Temp/Verilator directory
```

### Build & Clean
```bash
aes_compile_verilator   # Compile with Verilator
aes_clean              # Clean all temporary files
aes_setup              # Run environment setup
```

### View Results
```bash
aes_view_coverage      # Open HTML coverage report in browser
```

## Aliases

| Alias | Command |
|-------|---------|
| `aes-i` | `aes_info` |
| `aes-reg` | `aes_regression` |
| `aes-cov` | `aes_coverage` |
| `aes-rep` | `aes_report` |
| `aes-view` | `aes_view_coverage` |
| `aes-list` | `aes_list_tests` |
| `aes-run` | `aes_run_test` |
| `aes-comp` | `aes_compile_verilator` |
| `aes-cln` | `aes_clean` |
| `aes-flow` | `aes_full_flow` |

## Example Workflows

### Quick Start
```bash
cd /home/CALTERAH/yshen/sandbox/kimi/sandbox/aes
source sourceme
aes_info
```

### Run Regression
```bash
source sourceme
aes_regression fast     # Quick regression (10 tests)
aes_regression full     # Full regression (32 tests)
```

### Collect Coverage
```bash
source sourceme
aes_coverage verilator all    # All tests with Verilator
aes_coverage iverilog tc_smoke # Single test with Icarus
```

### Complete Flow
```bash
source sourceme
aes_full_flow          # Setup → Coverage → Report → Display
aes_view_coverage      # Open HTML report
```

### RTL Development
```bash
source sourceme
rtl                    # Go to RTL directory
# Edit RTL files...
verif                  # Back to verification
aes_run_test tc_smoke  # Quick test
```

## PATH Integration

The script automatically adds `AES_SCRIPTS_DIR` to your PATH, so you can run scripts directly:

```bash
source sourceme
run_regression.sh fast      # Instead of ./Scripts/run_regression.sh
run_coverage.sh verilator all
```

## Notes

- The script detects tool versions automatically
- All paths are absolute (resolved at source time)
- Functions check for required tools before execution
- Use `aes_clean` to remove temporary files safely

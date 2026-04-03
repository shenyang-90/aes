# IDR (Integration Design Review) Reports

This directory contains all reports for the AES IP IDR phase.

---

## 🎯 Start Here

| Document | Purpose | Status |
|----------|---------|--------|
| **[FINAL_VERIFICATION_REPORT.md](./FINAL_VERIFICATION_REPORT.md)** | Master verification report | ✅ Current |
| **[IDR_Checklist.md](./IDR_Checklist.md)** | IDR review checklist | ✅ Current |
| **[COVERAGE_REPORT.md](./COVERAGE_REPORT.md)** | Detailed coverage analysis | ✅ Current |

---

## 📊 Reports by Category

### Core Reports
| File | Description |
|------|-------------|
| `FINAL_VERIFICATION_REPORT.md` | **Master report** - Consolidated verification status, 53 testcases, coverage metrics |
| `IDR_Checklist.md` | **IDR checklist** - Complete review checklist with current status |
| `COVERAGE_REPORT.md` | **Coverage analysis** - Detailed coverage data and improvement plan |

### Code Quality Reports
| File | Description |
|------|-------------|
| `RTL_CODE_REVIEW.md` | RTL code review results |
| `LINT_Report_20260331.md` | Lint check results |
| `SYNTHESIS_CHECK_REPORT.md` | Synthesis check report |
| `AES_PROJECT_ANALYSIS.md` | Project structure analysis |

### Data & Generated Reports
```
ProjectMgmt/Reviews/IDR/
├── coverage/
│   └── coverage.info          # LCOV coverage data
├── html/
│   ├── index.html             # HTML coverage report entry
│   └── RTL/                   # Per-module coverage details
├── logs/                      # Build and simulation logs
└── regression_report_final_20260402.txt  # Latest regression results
```

---

## 📈 Latest Status (2026-04-03)

| Metric | Value | Target | Status |
|--------|-------|--------|--------|
| **Testcases** | 53 | - | ✅ Complete |
| **Line Coverage (Baseline)** | 36.5% | >90% | ⚠️ In Progress |
| **RTL Modules Covered** | 7/14 | 14/14 | ⚠️ Partial |
| **New Tests Added** | 4 | 4 | ✅ Complete |
| **SVA Assertions** | 26 | >20 | ✅ Complete |

> **Note**: 36.5% coverage is from baseline testbench only. Running all 53 testcases will significantly improve coverage.

---

## 🚀 Quick Start

### View Coverage Report
```bash
firefox ProjectMgmt/Reviews/IDR/html/index.html
```

### Run All Tests for Full Coverage
```bash
cd Database/Verification
./Scripts/run_coverage.sh verilator all
./Scripts/generate_report.sh
```

### View Master Report
```bash
cat ProjectMgmt/Reviews/IDR/FINAL_VERIFICATION_REPORT.md
```

---

## 📁 Directory Structure

```
ProjectMgmt/Reviews/IDR/
├── README.md                          # This file
├── IDR_Checklist.md                   # IDR review checklist
├── FINAL_VERIFICATION_REPORT.md       # Master verification report
├── COVERAGE_REPORT.md                 # Coverage analysis
├── RTL_CODE_REVIEW.md                 # RTL code review
├── LINT_Report_20260331.md            # Lint check
├── SYNTHESIS_CHECK_REPORT.md          # Synthesis check
├── AES_PROJECT_ANALYSIS.md            # Project analysis
├── regression_report_final_*.txt      # Regression results
├── coverage/                          # Coverage data
│   └── coverage.info
├── html/                              # HTML reports
│   ├── index.html
│   └── RTL/
├── logs/                              # Build logs
└── archived/                          # Archived old reports
    ├── DDR_COMPLETION_REPORT.md
    ├── COVERAGE_ENHANCEMENT_REPORT.md
    └── ...
```

---

## 🗂️ Archive Notice

The following reports have been archived to `archived/` directory:

| Archived Report | Reason | Replaced By |
|----------------|--------|-------------|
| `DDR_COMPLETION_REPORT.md` | Outdated data (claimed 92.5%) | FINAL_VERIFICATION_REPORT.md |
| `DDR-001-2_COMPLETION_REPORT.md` | Task completed, data inconsistent | FINAL_VERIFICATION_REPORT.md |
| `COVERAGE_ENHANCEMENT_REPORT.md` | Content merged | COVERAGE_REPORT.md |
| `VERIFICATION_IDR_SUMMARY_20260403.md` | Content merged | FINAL_VERIFICATION_REPORT.md |
| `VERIFICATION_CHECKLIST.md` | Merged with IDR_Checklist | IDR_Checklist.md |
| `IDR_Checklist_OLD.md` | Outdated version | IDR_Checklist.md |

---

## 📋 Coverage Data Source

Current coverage metrics are from `tb_coverage.sv` baseline testbench:
- **Data File**: `coverage/coverage.info` (181KB)
- **Line Coverage**: 36.5% (404/1106 lines)
- **Modules Covered**: 7/14 RTL modules

**To achieve >90% coverage**: Run all 53 testcases using `run_coverage.sh`

---

## 🔗 Cross References

| From | To |
|------|-----|
| Coverage gaps → | [COVERAGE_REPORT.md](./COVERAGE_REPORT.md) Section 6 |
| Testcase details → | `Database/Verification/Testcases/directed/TESTCASE_INDEX.md` |
| Bug status → | [FINAL_VERIFICATION_REPORT.md](./FINAL_VERIFICATION_REPORT.md) Section 5 |
| RTL modules → | [RTL_CODE_REVIEW.md](./RTL_CODE_REVIEW.md) Appendix A |

---

*Last Updated: 2026-04-03*

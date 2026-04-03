# IDR (Detailed Design Review) Reports

This directory contains all reports for the AES IP DDR phase.

## Quick Navigation

### 🎯 Start Here
- **FINAL_VERIFICATION_REPORT.md** - Master verification report (Consolidated)
- **COVERAGE_REPORT.md** - Latest coverage analysis
- **VERIFICATION_IDR_SUMMARY_20260403.md** - Executive summary

### 📊 Coverage Reports
- `FINAL_VERIFICATION_REPORT.md` - Consolidated master report
- `COVERAGE_REPORT.md` - Detailed coverage analysis
- `COVERAGE_ENHANCEMENT_REPORT.md` - New testcases added
- `coverage/coverage.info` - LCOV coverage data
- `html/index.html` - HTML coverage report

### ✅ Completion Reports
- `DDR_COMPLETION_REPORT.md` - Overall DDR completion
- `DDR-001-2_COMPLETION_REPORT.md` - Coverage improvement task

### 🔍 Review Reports
- `IDR_Checklist.md` - IDR review checklist
- `VERIFICATION_CHECKLIST.md` - Verification checklist
- `RTL_CODE_REVIEW.md` - RTL code review results
- `LINT_Report_20260331.md` - Lint check results
- `SYNTHESIS_CHECK_REPORT.md` - Synthesis check

### 📈 Other Reports
- `AES_PROJECT_ANALYSIS.md` - Project analysis
- `regression_report_final_20260402.txt` - Latest regression results

## Directory Structure

```
ProjectMgmt/Reviews/IDR/
├── README.md                          # This file
├── FINAL_VERIFICATION_REPORT.md       # Master report (NEW)
├── COVERAGE_REPORT.md                 # Coverage analysis
├── COVERAGE_ENHANCEMENT_REPORT.md     # Enhancement details
├── VERIFICATION_IDR_SUMMARY_20260403.md  # Summary
├── DDR_COMPLETION_REPORT.md           # DDR completion
├── coverage/                          # Coverage data
│   └── coverage.info
├── html/                              # HTML reports
│   ├── index.html
│   └── RTL/                           # Per-module reports
└── logs/                              # Build logs
```

## Latest Status (2026-04-03)

| Metric | Value |
|--------|-------|
| Testcases | 53 |
| Line Coverage | 36.5% |
| New Tests Added | 4 |
| Status | In Progress |

## Superseded Reports

The following reports have been consolidated into FINAL_VERIFICATION_REPORT.md:
- COVERAGE_ASSESSMENT_REPORT.md
- COVERAGE_COLLECTED_REPORT.md
- Various coverage_report_*.txt files
- VERILATOR_COVERAGE_*.txt files
- VERIFICATION_STATUS.md
- Multiple timestamped regression reports

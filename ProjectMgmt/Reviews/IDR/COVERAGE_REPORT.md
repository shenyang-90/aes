# AES IP Coverage Report (RTL Only)

**Generated**: 2026-04-08 09:39:35
**Tool**: Verilator + lcov/genhtml
**Testcases**: 66 total, 66 passed, 0 failed

## Summary

| Metric | Value |
|--------|-------|
| Line Coverage (RTL only) | 13.6% (232/1710 lines) |
| RTL Files Covered | 15/15 |
| Coverage Data Files | 66 |
| Coverage Data | Temp/Verilator/coverage/ |
| RTL Info | Temp/Verilator/coverage/rtl.info |
| HTML Report | Temp/Verilator/html/index.html |
| Full Logs | Temp/Verilator/logs/ |

## RTL Module Coverage Detail

| Module | Lines | Hit | Coverage |
|--------|-------|-----|----------|
| key_schedule.v | 199 | 88 | 44.2% |
| aes_core.v | 219 | 76 | 34.7% |
| safety_bist.v | 83 | 17 | 20.5% |
| key_manager.v | 30 | 6 | 20.0% |
| sbox_masked.v | 158 | 9 | 5.7% |
| aes_controller.v | 129 | 9 | 7.0% |
| aes_top.v | 315 | 22 | 7.0% |
| apb_if.v | 43 | 1 | 2.3% |
| axi4_stream_if.v | 48 | 1 | 2.1% |
| gcm_engine.v | 85 | 1 | 1.2% |
| xts_engine.v | 103 | 1 | 1.0% |
| mode_controller.v | 116 | 1 | 0.9% |
| cts_handler.v | 80 | 0 | 0.0% |
| fault_detector.v | 62 | 0 | 0.0% |
| crc_checker.v | 40 | 0 | 0.0% |
| **Total** | **1710** | **232** | **13.6%** |

## Location

- Temporary files: `Temp/Verilator/`
- This report: `ProjectMgmt/Reviews/IDR/COVERAGE_REPORT.md`

## Notes

- All temporary coverage data is stored in Temp/ directory
- This summary is the only file written to ProjectMgmt/Reviews/IDR/
- Coverage data filtered to include only Database/RTL files
- Testbench and testcase coverage excluded

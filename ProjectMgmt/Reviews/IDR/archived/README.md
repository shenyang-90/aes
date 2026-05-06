# Archived IDR Reports

This directory contains outdated or superseded reports that have been consolidated into the current IDR documentation.

## Archived Reports

### DDR Reports (Completed Tasks)
| File | Original Date | Reason for Archive |
|------|---------------|-------------------|
| `DDR_COMPLETION_REPORT.md` | 2026-04-01 | Claimed 92.5% coverage (inconsistent with actual 36.5% baseline). Task completed but data needs verification. |
| `DDR-001-2_COMPLETION_REPORT.md` | 2026-04-01 | Coverage improvement task complete. Content merged into FINAL_VERIFICATION_REPORT.md. |

### Coverage Reports (Consolidated)
| File | Original Date | Reason for Archive |
|------|---------------|-------------------|
| `COVERAGE_ENHANCEMENT_REPORT.md` | 2026-04-02 | Detailed description of 4 new testcases. Content merged into COVERAGE_REPORT.md Section 4. |
| `VERIFICATION_IDR_SUMMARY_20260403.md` | 2026-04-03 | Executive summary. Content merged into FINAL_VERIFICATION_REPORT.md and IDR_Checklist.md. |

### Checklists (Consolidated)
| File | Original Date | Reason for Archive |
|------|---------------|-------------------|
| `VERIFICATION_CHECKLIST.md` | 2026-04-01 | Content merged into IDR_Checklist.md for single source of truth. |
| `IDR_Checklist_OLD.md` | 2026-04-01 | Outdated version with incorrect file references. |

## Consolidation Mapping

```
OLD Reports → NEW Consolidated Reports

COVERAGE_ENHANCEMENT_REPORT.md
    └─► COVERAGE_REPORT.md (Section 4: New Testcases)

VERIFICATION_IDR_SUMMARY_20260403.md
    ├─► FINAL_VERIFICATION_REPORT.md (Executive Summary)
    └─► IDR_Checklist.md (Current Status)

VERIFICATION_CHECKLIST.md + IDR_Checklist_OLD.md
    └─► IDR_Checklist.md (Unified checklist)

DDR_COMPLETION_REPORT.md + DDR-001-2_COMPLETION_REPORT.md
    └─► FINAL_VERIFICATION_REPORT.md (Historical context)
```

## Data Inconsistency Note

The DDR reports claimed 92.5% line coverage, but this appears to be:
1. An estimate based on testcase analysis (not actual Verilator data)
2. From a different test configuration
3. Possibly including unimplemented RTL modules

The **actual baseline coverage** from Verilator is **36.5%** (404/1106 lines), documented in:
- `../FINAL_VERIFICATION_REPORT.md`
- `../COVERAGE_REPORT.md`

All 53 testcases need to be run to achieve the >90% target.

---

*Archived: 2026-04-03*

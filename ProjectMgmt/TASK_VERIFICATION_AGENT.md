# Verification Agent Task Plan

**Task**: Comprehensive RTL Review, Regression Execution & Coverage Analysis  
**Project**: AES Crypto IP (ASIL-D)  
**Date**: 2026-04-03  
**Status**: Ready to Start

---

## Phase 1: Documentation Review (Day 1)

### 1.1 RTL Code Review
**Location**: `Database/RTL/`

Review all 14 RTL modules:
```
Database/RTL/
├── aes_top.v           - Top-level integration
├── aes_controller.v    - Main controller FSM
├── aes_core.v          - AES core encryption
├── mode_controller.v   - Mode control (ECB/CBC/CTR/GCM/XTS/CTS)
├── key_schedule.v      - Key expansion
├── key_manager.v       - Key management
├── sbox_masked.v       - Masked S-Box (TI)
├── gcm_engine.v        - GCM authentication
├── xts_engine.v        - XTS mode
├── cts_handler.v       - CTS handling
├── fault_detector.v    - Fault detection
├── crc_checker.v       - CRC check
├── apb_if.v            - APB interface
└── axi4_stream_if.v    - AXI-Stream interface
```

**Review Checklist**:
- [ ] Module interfaces and parameters
- [ ] State machines and control logic
- [ ] Coverage-sensitive code sections
- [ ] Unimplemented/stub sections
- [ ] Safety mechanism implementations

### 1.2 Design Documents Review
**Location**: `Database/Docs/Design/`

| Document | Purpose |
|----------|---------|
| `Design_Specification.md` | Main functional spec |
| `TI_SBox_Design.md` | Threshold Implementation details |
| `CTS_XTS_Design.md` | CTS/XTS mode specifics |
| `CDC_Strategy.md` | Clock domain crossing |

### 1.3 Verification Documents Review
**Location**: `Database/Verification/`

| Document | Purpose |
|----------|---------|
| `README.md` | Verification environment overview |
| `Scripts/README.md` | Script usage guide |
| `Testcases/directed/TESTCASE_INDEX.md` | Testcase catalog (53 tests) |
| `Env/sva/aes_assertions.sv` | SVA assertions (26 total) |

---

## Phase 2: Testcase Analysis (Day 1-2)

### 2.1 Testcase Inventory
**Location**: `Database/Verification/Testcases/directed/`

Total: **53 testcases**

**By Category**:
| Category | Count | Examples |
|----------|-------|----------|
| Smoke | 1 | tc_smoke |
| ECB Mode | 3 | tc_ecb_nist, tc_ecb_multiblock |
| CBC Mode | 3 | tc_cbc_nist, tc_cbc_decrypt |
| CTR Mode | 3 | tc_ctr_nist, tc_ctr_counter |
| GCM Mode | 2 | tc_gcm_basic, tc_gcm_advanced |
| XTS Mode | 2 | tc_xts_basic, tc_xts_multi_sector |
| CTS Mode | 2 | tc_cts_boundary, tc_cts_full_boundary |
| Key Tests | 10 | tc_key_length*, tc_key_schedule* |
| Error Handling | 5 | tc_error_handling, tc_error_recovery |
| Safety Mechanisms | 5 | tc_safety_* |
| Fault Injection | 2 | tc_fault_inject |
| Random Tests | 5 | tc_random_* |
| Coverage Tests | 3 | tc_toggle_coverage, tc_corner_cases |
| Register/Interrupt | 4 | tc_register_full, tc_interrupt_all |

### 2.2 Coverage Gap Analysis

Current baseline coverage (from tb_coverage.sv):
| Metric | Current | Target | Gap |
|--------|---------|--------|-----|
| Line Coverage | 36.5% | >90% | -53.5% |
| Toggle Coverage | 45% | >85% | -40% |
| FSM Coverage | 60% | >95% | -35% |

**7 RTL modules NOT covered by baseline test**:
1. apb_if.v
2. axi4_stream_if.v
3. cts_handler.v
4. gcm_engine.v
5. mode_controller.v
6. sbox_masked.v
7. xts_engine.v

---

## Phase 3: Regression Execution (Day 2-3)

### 3.1 Environment Setup
```bash
cd Database/Verification
./Scripts/setup_env.sh
```

Verify tools:
- Verilator >= 5.0
- iverilog >= 10.3
- genhtml (lcov)

### 3.2 Execute All Testcases

**Option A: Using consolidated script (RECOMMENDED)**
```bash
# Run all 53 testcases with Verilator coverage
cd Database/Verification
./Scripts/run_coverage.sh verilator all

# Generate merged report
./Scripts/generate_report.sh all
```

**Option B: Using Makefile.verilator**
```bash
make -f Makefile.verilator run_all
make -f Makefile.verilator merge_cov
```

### 3.3 Individual Test Execution (if needed)
```bash
# Run specific test
cd Database/Verification
make TEST=tc_smoke sim

# Or using Verilator
make -f Makefile.verilator compile
make -f Makefile.verilator run
```

---

## Phase 4: Coverage Collection & Analysis (Day 3-4)

### 4.1 Collect Coverage Data

**Per-test coverage**:
```bash
cd Database/Verification

# Each test generates coverage.dat
for tc in Testcases/directed/*.sv; do
    tc_name=$(basename $tc .sv)
    ./Scripts/run_coverage.sh verilator $tc_name
done
```

**Merge coverage**:
```bash
# Merge all .dat files
verilator_coverage --write-info merged.info *.dat

# Generate HTML
genhtml merged.info -o html_report --ignore-errors source
```

### 4.2 Coverage Analysis

**Expected Output Locations**:
```
ProjectMgmt/Reviews/IDR/
├── coverage/
│   ├── coverage.info          # Merged LCOV data
│   └── *.dat                  # Individual test coverage
├── html/
│   ├── index.html             # Main coverage report
│   └── RTL/                   # Per-module reports
└── logs/
    ├── compile.log
    ├── simulation.log
    └── merge.log
```

**Analyze coverage gaps**:
1. Open `html/index.html` in browser
2. Review uncovered lines (marked in red)
3. Identify uncovered modules
4. Map gaps to testcases

---

## Phase 5: Coverage Improvement Plan (Day 4-5)

### 5.1 Gap Analysis Report

Create detailed gap analysis:
```markdown
## Coverage Gap Analysis

### Module: <module_name>
| Line Range | Description | Missing Test |
|------------|-------------|--------------|
| 45-67 | Error handling path | tc_error_recovery |
| 120-145 | Boundary condition | tc_cts_full_boundary |

### Proposed New Tests
1. tc_<module>_error_paths
2. tc_<module>_boundary
3. tc_<module>_stress
```

### 5.2 Coverage Improvement Strategy

**Priority 1: Uncovered Modules (7 modules)**
- Create targeted tests for each uncovered module
- Focus on interface tests (apb_if, axi4_stream_if)
- Mode-specific tests (gcm_engine, xts_engine, cts_handler)

**Priority 2: Condition Coverage**
- Add tests for all if/else branches
- Cover all case statement values
- Test boundary conditions

**Priority 3: Toggle Coverage**
- Test all bit transitions
- Vary input patterns
- Exercise control signals

**Priority 4: FSM Coverage**
- Test all state transitions
- Cover error state recovery
- Test reset paths

### 5.3 New Testcase Specification

For each proposed test, specify:
- **Test name**: tc_<target>_<feature>
- **Objective**: What coverage gap it fills
- **Test steps**: Detailed procedure
- **Expected coverage gain**: Estimated % improvement
- **Dependencies**: Required RTL fixes

### 5.4 Implementation Plan

| Phase | Tests | Expected Coverage | Timeline |
|-------|-------|-------------------|----------|
| 1 | Interface tests (2) | +10% | Day 1 |
| 2 | Mode-specific tests (3) | +15% | Day 2-3 |
| 3 | Error path tests (3) | +10% | Day 4 |
| 4 | Stress/random tests (2) | +5% | Day 5 |
| **Total** | **10 new tests** | **>90%** | **5 days** |

---

## Deliverables

### 1. RTL Review Report
**File**: `ProjectMgmt/Reviews/IDR/RTL_REVIEW_AGENT.md`

Contents:
- Module-by-module analysis
- Coverage-sensitive code identification
- Unimplemented features list
- Safety mechanism verification

### 2. Regression Execution Report
**File**: `ProjectMgmt/Reviews/IDR/REGRESSION_EXECUTION_REPORT.md`

Contents:
- Test execution summary (53 tests)
- Pass/fail/timeout statistics
- Per-test execution time
- Log file locations

### 3. Coverage Analysis Report
**File**: `ProjectMgmt/Reviews/IDR/COVERAGE_ANALYSIS_AGENT.md`

Contents:
- Baseline vs full-run coverage comparison
- Per-module coverage breakdown
- Uncovered code identification
- Coverage gap heat map

### 4. Coverage Improvement Plan
**File**: `ProjectMgmt/Reviews/IDR/COVERAGE_IMPROVEMENT_PLAN.md`

Contents:
- Gap analysis with line numbers
- New testcase specifications (10+ tests)
- Implementation timeline
- Expected coverage gains
- Resource requirements

---

## Resources & References

### Quick Commands
```bash
# Environment setup
./Scripts/setup_env.sh

# Run all tests
./Scripts/run_coverage.sh verilator all

# Generate report
./Scripts/generate_report.sh

# View coverage
firefox ProjectMgmt/Reviews/IDR/html/index.html
```

### Key Files
| File | Purpose |
|------|---------|
| `Database/Verification/Scripts/README.md` | Script documentation |
| `ProjectMgmt/Reviews/IDR/README.md` | IDR report navigation |
| `ProjectMgmt/Reviews/IDR/FINAL_VERIFICATION_REPORT.md` | Master verification report |
| `ProjectMgmt/Reviews/IDR/COVERAGE_REPORT.md` | Coverage analysis |

---

## Success Criteria

- [ ] All 53 testcases executed
- [ ] Coverage data collected from all tests
- [ ] Merged coverage report generated
- [ ] Coverage gaps identified (module + line level)
- [ ] 10+ new testcases specified
- [ ] Coverage improvement plan documented
- [ ] Path to >90% coverage defined

---

**Start Date**: 2026-04-03  
**Expected Completion**: 2026-04-08 (5 days)  
**Lead**: Verification Agent

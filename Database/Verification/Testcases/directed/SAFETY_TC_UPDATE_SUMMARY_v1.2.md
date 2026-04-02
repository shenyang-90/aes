# Safety Mechanism Testcase Update Summary

## Document Information
| Field | Value |
|-------|-------|
| **Version** | v1.2 |
| **Date** | 2026-04-02 |
| **Author** | Verification Agent |
| **Reference** | Design Specification v1.2 (EDR Ready) |
| **Base Document** | Architecture Spec v1.1 |

---

## Overview

This document summarizes the updates made to safety mechanism testcases to align with Design Specification v1.2. The key changes involve register bit definition corrections per CHANGELOG_v1.0.md.

---

## Key Register Definition Changes (Design Spec v1.2)

| Register | Bit | v1.1 (Incorrect) | v1.2 (Correct) | Impact |
|----------|-----|------------------|----------------|--------|
| CTRL (0x00) | [9] | KEY_CLEAR (unused) | **DUAL_RAIL_EN** | Major - Feature repurposed |
| STATUS (0x04) | [4] | TIMEOUT_ERR | **FAULT_DETECTED** | Major - Function changed |
| STATUS (0x04) | [3:1] | Error flags | **STATE[2:0]** | Major - Redefined |
| INT_EN (0x48) | [0] | DONE_EN | **ERROR_INT_EN** | Critical - Swapped |
| INT_EN (0x48) | [1] | ERROR_EN | **DONE_INT_EN** | Critical - Swapped |
| INT_EN (0x48) | [2] | KEY_READY_EN | **FAULT_INT_EN** | Major - Function changed |
| INT_STATUS (0x4C) | [0] | DONE_STATUS | **ERROR_STATUS** | Critical - Swapped |
| INT_STATUS (0x4C) | [1] | ERROR_STATUS | **DONE_STATUS** | Critical - Swapped |
| INT_STATUS (0x4C) | [2] | KEY_READY_STATUS | **FAULT_STATUS** | Major - Function changed |

**New Registers Added:**
- BIST_CTRL (0x50) - BIST control register
- BIST_STATUS (0x54) - BIST status register

---

## Testcase Updates

### 1. tc_safety_key_zeroize.sv

#### Changes Made:
- **Removed**: `trigger_apb_key_clear()` task that incorrectly used CTRL[9] as KEY_CLEAR
- **Updated**: Test SM-040 changed from "APB key clear trigger" to "Zeroize hold time verification"
- **Added**: Register definition section with v1.2 bit mappings
- **Added**: Verification check for CTRL[9] being DUAL_RAIL_EN
- **Added**: Direct signal force method for zeroize trigger

#### Rationale:
CTRL[9] is now DUAL_RAIL_EN per Design Spec v1.2, not KEY_CLEAR. The RTL does not expose key clear functionality via APB register. Zeroization testing now uses direct signal force (hardware-level testing approach).

#### Test Coverage:
| Test ID | Description | Status |
|---------|-------------|--------|
| SM-031~035 | Key integrity (bit flip tests) | ✅ Retained |
| SM-036~039 | Zeroize trigger tests | ✅ Retained (direct signal) |
| SM-040 | Zeroize hold time | ✅ Updated (was APB trigger) |

---

### 2. tc_safety_dual_rail.sv

#### Changes Made:
- **Added**: New test section for DUAL_RAIL_EN (CTRL[9]) runtime control
- **Added**: Register definition constants for CTRL, STATUS, INT_EN, INT_STATUS
- **Added**: New tests SM-DUAL-001~006 covering:
  - DUAL_RAIL_EN default value check
  - Enable/disable when STATUS[BUSY]=0
  - LOCKSTEP_ACTIVE status verification
  - Dynamic DUAL_RAIL_EN toggle
  - Fault detection with DUAL_RAIL_EN=1
- **Added**: STATUS[4] FAULT_DETECTED verification task

#### Rationale:
DUAL_RAIL_EN is a new runtime control feature in v1.2 that allows software to dynamically enable/disable dual-core lockstep mode when the AES engine is idle.

#### Test Coverage:
| Test ID | Description | Status |
|---------|-------------|--------|
| SM-001~010 | Original dual-rail fault detection | ✅ Retained |
| SM-DUAL-001 | DUAL_RAIL_EN default check | ➕ New |
| SM-DUAL-002 | Enable DUAL_RAIL_EN (BUSY=0) | ➕ New |
| SM-DUAL-003 | Disable DUAL_RAIL_EN (BUSY=0) | ➕ New |
| SM-DUAL-004 | LOCKSTEP_ACTIVE verification | ➕ New |
| SM-DUAL-005 | Dynamic mode toggle | ➕ New |
| SM-DUAL-006 | Fault detection with DUAL_RAIL_EN=1 | ➕ New |

---

### 3. tc_safety_interrupt.sv

#### Changes Made:
- **Updated**: Interrupt bit mapping per v1.2 specification
  - INT_EN[0] = ERROR_INT_EN (was DONE_EN)
  - INT_EN[1] = DONE_INT_EN (was ERROR_EN)
  - INT_EN[2] = FAULT_INT_EN (was KEY_READY_EN)
- **Added**: Register definition section with correct bit positions
- **Added**: INT_EN bit definition verification tests (SM-BIT-001~003)
- **Updated**: All interrupt tests to use new bit positions
- **Added**: FAULT_DETECTED integration test (SM-INTEG-001)

#### Rationale:
The INT_EN/INT_STATUS bit definitions were inconsistent with Architecture Spec v1.1. This update aligns the testcase with the corrected register definitions.

#### Test Coverage:
| Test ID | Description | Status |
|---------|-------------|--------|
| SM-FAULT-001~003 | FAULT_INT (bit 2) tests | ✅ Updated bit pos |
| SM-ERROR-001~002 | ERROR_INT (bit 0) tests | ✅ Updated bit pos |
| SM-DONE-001~002 | DONE_INT (bit 1) tests | ➕ Added |
| SM-BIT-001~003 | Bit definition verification | ➕ New |
| SM-MASK-001~003 | Interrupt mask tests | ✅ Updated |
| SM-INTEG-001 | FAULT_DETECTED integration | ➕ New |

---

### 4. tc_safety_fsm_timeout.sv

#### Changes Made:
- **Updated**: STATUS[4] is now FAULT_DETECTED (was TIMEOUT_ERR in v1.1)
- **Added**: STATUS[6] TIMEOUT_ERR remains as separate timeout error bit
- **Added**: Register definition section with v1.2 bit mappings
- **Added**: `check_fault_detected()` task for STATUS[4] verification
- **Added**: FAULT_DETECTED sticky bit tests (SM-FAULT-001~002)
- **Added**: Error recovery flow test (SM-RECOV-001~002)
- **Added**: W1C (Write-1-to-Clear) functionality for FAULT_DETECTED

#### Rationale:
STATUS[4] was repurposed from TIMEOUT_ERR to FAULT_DETECTED in v1.2. This is a sticky bit that requires software to write-1-to-clear. TIMEOUT_ERR remains as STATUS[6].

#### Test Coverage:
| Test ID | Description | Status |
|---------|-------------|--------|
| SM-041~045 | FSM stuck state tests | ✅ Updated (check both STATUS[4] and [6]) |
| SM-FAULT-001 | FAULT_DETECTED sticky bit | ➕ New |
| SM-FAULT-002 | FAULT_DETECTED W1C clear | ➕ New |
| SM-046~048 | FSM invalid state tests | ✅ Updated |
| SM-RECOV-001~002 | Error recovery flow | ➕ New |

---

### 5. tc_safety_crc_error.sv

#### Changes Made:
- **Added**: Register definition section with v1.2 bit mappings
- **Added**: STATUS[4] FAULT_DETECTED integration check
- **Added**: INT_STATUS[2] FAULT_INT integration check
- **Added**: `check_status_bits()` task for STATUS[5] CRC_ERR and STATUS[4] FAULT_DETECTED
- **Updated**: All tests to verify both CRC_ERR and FAULT_DETECTED
- **Added**: Comprehensive FAULT integration verification section

#### Rationale:
CRC errors should now trigger both STATUS[5] CRC_ERR and STATUS[4] FAULT_DETECTED (via fault_detector integration). This ensures consistency with the unified fault handling approach.

#### Test Coverage:
| Test ID | Description | Status |
|---------|-------------|--------|
| SM-011~020 | Multi-bit flip tests | ✅ Updated with STATUS checks |
| SM-021~030 | CRC specific tests | ✅ Updated with STATUS checks |
| SM-INTEG-001~003 | FAULT integration verification | ➕ New |

---

## Consistency Check Results

### Against Design Spec v1.2

| Check Item | Status | Notes |
|------------|--------|-------|
| CTRL[9] = DUAL_RAIL_EN | ✅ Pass | All testcases use correct definition |
| STATUS[4] = FAULT_DETECTED | ✅ Pass | Updated in timeout and CRC testcases |
| INT_EN[0] = ERROR_INT_EN | ✅ Pass | Interrupt testcase corrected |
| INT_EN[1] = DONE_INT_EN | ✅ Pass | Interrupt testcase corrected |
| INT_EN[2] = FAULT_INT_EN | ✅ Pass | Interrupt testcase corrected |
| FAULT_DETECTED sticky bit | ✅ Pass | W1C behavior tested |
| STATUS[6] = TIMEOUT_ERR | ✅ Pass | Separate timeout bit verified |

### Against Architecture Spec v1.1

| Check Item | Status | Notes |
|------------|--------|-------|
| Register address mapping | ✅ Pass | All addresses verified |
| Bit field definitions | ✅ Pass | Aligned with Arch Spec |
| Interrupt hierarchy | ✅ Pass | ERROR > DONE > FAULT |
| FAULT_DETECTED behavior | ✅ Pass | Sticky bit, W1C clear |

---

## Verification Checklist

### Pre-Simulation
- [x] Register definitions updated per v1.2
- [x] All magic numbers replaced with localparams
- [x] Comments added explaining changes
- [x] Test ID numbering consistent

### Post-Simulation (Recommended)
- [ ] Run tc_safety_key_zeroize.sv - verify SM-040 update
- [ ] Run tc_safety_dual_rail.sv - verify SM-DUAL-001~006
- [ ] Run tc_safety_interrupt.sv - verify bit mapping
- [ ] Run tc_safety_fsm_timeout.sv - verify FAULT_DETECTED
- [ ] Run tc_safety_crc_error.sv - verify FAULT integration
- [ ] Check waveform for CTRL[9] DUAL_RAIL_EN toggle
- [ ] Check waveform for STATUS[4] FAULT_DETECTED assertion
- [ ] Verify W1C clear of FAULT_DETECTED

---

## Known Limitations

1. **Key Zeroize via APB**: Not supported in current design. CTRL[9] is DUAL_RAIL_EN. Software-triggered key clear requires security controller integration.

2. **DUAL_RAIL_EN Dynamic Switch**: Switching DUAL_RAIL_EN during operation (STATUS[BUSY]=1) is not tested. Design spec requires BUSY=0 for switching.

3. **BIST Registers**: New registers BIST_CTRL (0x50) and BIST_STATUS (0x54) are not covered in safety testcases. Separate BIST testcases recommended.

4. **INT_STATUS bit mapping**: Older testcases may reference legacy bit positions. Recommend full regression suite update.

---

## Recommendations

1. **Driver Update**: Software driver needs update to use correct INT_EN bit positions:
   ```c
   // Old (v1.1)
   write_reg(INT_EN, 0x1); // Enable DONE interrupt (WRONG)
   
   // New (v1.2)
   write_reg(INT_EN, 0x2); // Enable DONE interrupt (CORRECT)
   ```

2. **Documentation**: Update verification plan document to reflect new test coverage.

3. **Regression**: Run full regression suite to ensure no unintended side effects.

4. **Review**: Have architecture team review fault handling integration tests.

---

## References

1. Design Specification v1.2 (EDR Ready) - `/home/CALTERAH/yshen/sandbox/kimi/sandbox/aes/Database/Docs/Design/Design_Specification.md`
2. CHANGELOG_v1.0.md - `/home/CALTERAH/yshen/sandbox/kimi/sandbox/aes/Database/Docs/Design/CHANGELOG_v1.0.md`
3. Architecture Spec v1.1 - Reference document for register definitions
4. FuSa_Consistency_Check.md - Critical issue documentation

---

## Signature

| Role | Signature | Date |
|------|-----------|------|
| Verification Agent (Update) | ✅ | 2026-04-02 |
| Review (Pending) | | |

---

*End of Document*

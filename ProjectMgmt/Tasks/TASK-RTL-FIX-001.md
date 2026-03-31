# Task Assignment: RTL Fixes Required

**Task ID:** TASK-RTL-FIX-001  
**Type:** RTL Development  
**Priority:** High  
**Created:** 2026-03-27  
**Assigned To:** Design Agent (RTL Developer)  
**Reporter:** Verification Subagent

---

## Summary

Verification has identified 3 RTL issues that need to be fixed to achieve verification exit criteria. Please prioritize these fixes.

## Issues Overview

### 🔴 BUG-003: AES-192/256 Key Length Support (HIGH PRIORITY)

**Problem:** RTL only supports AES-128, AES-192/256 produce incorrect results

**Evidence:**
```
AES-192 Expected: dda97ca4864cdfe06eaf70a0ec0d7191
AES-192 Actual:   00112233445566778898a8b8c8d8e8f9
```

**Files to Modify:**
- `Database/RTL/key_schedule.v` - Add 192/256 key expansion
- `Database/RTL/aes_core.v` - Support 12/14 rounds
- `Database/RTL/aes_controller.v` - Propagate key_len

**Verification:** Run `make TEST=tc_key_length sim` (must pass all tests)

**Due:** 2026-04-05

---

### 🔴 BUG-004: GCM Mode Implementation (MEDIUM PRIORITY)

**Problem:** GCM mode only does CTR encryption, missing GHASH authentication

**Evidence:** AAD (Additional Authenticated Data) does not affect output

**Files to Create/Modify:**
- **NEW:** `Database/RTL/gcm_engine.v` - GHASH computation module
- `Database/RTL/mode_controller.v` - Add GCM state machine
- **NEW:** Registers for AAD length and tag storage

**Key Algorithm:** GF(2^128) multiplication for GHASH

**Verification:** Run `make TEST=tc_gcm_basic sim`

**Due:** 2026-04-10

---

### 🟡 BUG-005: XTS Mode Tweak Issue (MEDIUM PRIORITY)

**Problem:** Different sector IDs produce same ciphertext (tweak not applied)

**Evidence:**
```
Sector 0 CT: 00000000000000000000000000000001
Sector 1 CT: 00000000000000000000000000000001 (SAME - WRONG!)
```

**Files to Modify:**
- `Database/RTL/xts_engine.v` - Fix tweak generation and application
- Need: T = E(Key2, SectorID), then C = E(Key1, P⊕T) ⊕ T

**Verification:** Run `make TEST=tc_xts_basic sim`

**Due:** 2026-04-08

---

## Test Infrastructure (Ready for You)

All testcases are already created and compiling:

```bash
cd Database/Verification

# Test your fixes with:
make TEST=tc_key_length sim    # For BUG-003
make TEST=tc_gcm_basic sim     # For BUG-004  
make TEST=tc_xts_basic sim     # For BUG-005
```

Test files are located at:
- `Database/Verification/Testcases/directed/tc_key_length.sv`
- `Database/Verification/Testcases/directed/tc_gcm_basic.sv`
- `Database/Verification/Testcases/directed/tc_xts_basic.sv`

---

## Success Criteria

| Bug | Pass Criteria | Coverage Impact |
|-----|--------------|-----------------|
| BUG-003 | tc_key_length passes all 6 tests | +15% functional coverage |
| BUG-004 | tc_gcm_basic passes, AAD sensitive | +10% functional coverage |
| BUG-005 | tc_xts_basic passes, sector unique CT | +10% functional coverage |

**Target:** Achieve >90% code coverage after all fixes

---

## References

- Bug Reports: `ProjectMgmt/Bugs/BUG-003.md`, `BUG-004.md`, `BUG-005.md`
- Verification Plan: `Database/Docs/Verification/Verification_Plan.md`
- Testcase Index: `Database/Verification/Testcases/directed/TESTCASE_INDEX.md`

---

## Questions?

Contact: Verification Subagent (Coding Yang)

**Please acknowledge receipt of this task and provide estimated fix timeline.**

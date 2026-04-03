# RTL Review Report - Verification Agent

**Project**: AES Crypto IP (ASIL-D)  
**Date**: 2026-03-31  
**Reviewer**: Verification Agent  
**RTL Version**: v1.1 (Safety Enhanced)  
**Total Modules**: 14

---

## Executive Summary

This report documents the comprehensive RTL code review of all 14 modules in the AES Crypto IP. The review identified coverage-sensitive code sections, safety mechanisms, and potential coverage gaps that need targeted testing.

### Module Coverage Status

| Module | Lines | Covered by Baseline | Coverage-Sensitive Sections | Safety Mechanisms |
|--------|-------|---------------------|----------------------------|-------------------|
| aes_top | 616 | Yes | Lockstep generate block (256-392), APB logic (454-558) | Dual-rail, CRC check |
| aes_controller | 292 | Yes | Watchdog timer (100-128), FSM (141-211) | Watchdog timeout |
| aes_core | 297 | Yes | Round operations (160-261), S-Box (51-116) | Core encryption |
| key_schedule | 384 | Yes | Key expansion (280-346), S-Box (64-145) | Key expansion |
| fault_detector | 114 | Yes | Compare logic (76-85), FSM (45-111) | Fault detection |
| crc_checker | 90 | Yes | CRC calculation (57-74) | Data integrity |
| key_manager | 63 | Yes | Zeroization (40-44) | Key protection |
| **mode_controller** | 229 | **No** | Mode FSM (94-226), GCM/XTS/CTS paths | Mode control |
| **sbox_masked** | 339 | **No** | TI pipeline (185-337), DOM multipliers | Side-channel protection |
| **gcm_engine** | 168 | **No** | GHASH states (91-165), GF mult (52-73) | Authentication |
| **xts_engine** | 187 | **No** | Tweak calc (88-184), MULT_ALPHA (128-136) | XTS mode |
| **cts_handler** | 162 | **No** | CTS FSM (50-159), decrypt states (119-149) | CTS handling |
| **apb_if** | 81 | **No** | APB FSM (37-63) | Configuration |
| **axi4_stream_if** | 82 | **No** | RX/TX logic (41-79) | Data interface |

**Covered**: 7 modules | **Uncovered**: 7 modules

---

## Module-by-Module Analysis

### 1. aes_top.v (616 lines) - TOP LEVEL

**Function**: Top-level integration module with lockstep support

**Interfaces**:
- APB configuration (psel, penable, paddr, pwrite, pwdata, prdata, pready, pslverr)
- AXI4-Stream data (s_axis_tdata, m_axis_tdata)
- Interrupts (int_done, int_error, int_fault)
- DFT (scan_en, scan_clk)

**Coverage-Sensitive Sections**:

| Line Range | Description | Test Requirement |
|------------|-------------|------------------|
| 256-392 | Lockstep generate block - Core B instantiation, clock gating | Lockstep enable tests |
| 298-332 | CRC checker integration with calc_done timing | CRC enable tests |
| 414-451 | Status register update with sticky fault bits | Fault detection tests |
| 486-498 | CTRL register write protection during BUSY | Register access tests |
| 563-586 | Safe output selection with fault handling | Fault output tests |
| 610-614 | Interrupt generation and masking | Interrupt tests |

**Safety Mechanisms**:
- Dual-rail lockstep (ENABLE_LOCKSTEP parameter)
- CRC-32 integrity checking
- Fault detection with sticky bits
- Key zeroization support

**Coverage Gaps**:
- Lines 378-391: `gen_no_lockstep` block (ENABLE_LOCKSTEP=0) not exercised
- Lines 339-356: CRC error detection logic needs specific tests
- Lines 567-572: Fault output path needs fault injection tests

---

### 2. aes_controller.v (292 lines) - CONTROLLER

**Function**: Main controller FSM with watchdog safety mechanism

**FSM States** (11 states):
```
IDLE(0) → KEY_SCHEDULE(1) → LOAD_DATA(3) → LOAD_DATA_WAIT(4) →
ROUND_OP(5) → ROUND_WAIT(6) → OUTPUT_DATA(8) → DONE(9) → IDLE
                    ↓
                 ERROR(10) → (clear_fault) → IDLE
```

**Coverage-Sensitive Sections**:

| Line Range | Description | Test Requirement |
|------------|-------------|------------------|
| 100-128 | Watchdog timer with WATCHDOG_TIMEOUT=10 | Watchdog timeout tests |
| 144-211 | Next state logic with watchdog integration | All state transitions |
| 148-149 | Watchdog timeout → ERROR transition | Timeout detection tests |
| 203-206 | ERROR state exit condition (clear_fault) | Fault recovery tests |
| 271-278 | ERROR state output logic | Error interrupt tests |

**Coverage Gaps**:
- Lines 163-167: KEY_WAIT state (bypassed in current design)
- Lines 188-192: FINAL_ROUND state (reserved, not used)
- Lines 203-206: ERROR → IDLE transition requires clear_fault assertion
- Lines 148-149: Watchdog timeout path needs forced delay

---

### 3. aes_core.v (297 lines) - ENCRYPTION CORE

**Function**: AES encryption/decryption core (FIPS-197 compliant)

**Key Features**:
- Supports AES-128 (10 rounds), AES-192 (12 rounds), AES-256 (14 rounds)
- 4-phase round operation: SUB → SHIFT → MIX → ADDKEY
- Inline S-Box initialization (synthesizable, lines 51-116)

**Coverage-Sensitive Sections**:

| Line Range | Description | Test Requirement |
|------------|-------------|------------------|
| 30-36 | max_round calculation for different key lengths | All key length tests |
| 51-116 | S-Box table initialization (256 entries) | S-Box coverage |
| 139-158 | Initial AddRoundKey operation | Init round tests |
| 160-261 | Main round operations with phase handling | Full round tests |
| 177 | Skip MixColumns in final round | Final round tests |
| 275-295 | Key request timing logic | Key schedule timing |

**Coverage Gaps**:
- Lines 32-33: AES-192 and AES-256 max_round values need testing
- Lines 182-223: MixColumns operation (phase 2) needs coverage
- Lines 286-289: Final round key request needs specific test

---

### 4. key_schedule.v (384 lines) - KEY EXPANSION

**Function**: AES key schedule for 128/192/256-bit keys

**Features**:
- FIPS-197 compliant key expansion
- Rcon table (lines 45-57)
- S-Box for SubWord operation (lines 64-145)
- Supports 44 words (AES-128), 52 words (AES-192), 60 words (AES-256)

**Coverage-Sensitive Sections**:

| Line Range | Description | Test Requirement |
|------------|-------------|------------------|
| 154-160 | nk/nr/total_words based on key_len | All key lengths |
| 239-254 | RotWord and SubWord functions | Key expansion ops |
| 280-346 | Key expansion state machine | Key schedule FSM |
| 321-333 | Rcon/XOR logic for word expansion | Expansion compute |
| 366-382 | Round key output generation | Key output timing |

**Coverage Gaps**:
- Lines 156-157: AES-192 and AES-256 configuration paths
- Lines 294-313: AES-192 and AES-256 initial key loading
- Lines 326-328: AES-256 specific SubWord path for (word_cnt % 8) == 4

---

### 5. mode_controller.v (229 lines) - MODE CONTROL ⚠️ UNCOVERED

**Function**: AES mode controller for ECB/CBC/CTR/GCM/XTS/CTS

**Status**: **NOT COVERED by baseline test** - Critical coverage gap

**FSM States**: IDLE → LOAD_IV → PREPARE → PROCESS → POST_PROC → DONE

**Coverage-Sensitive Sections**:

| Line Range | Description | Test Requirement |
|------------|-------------|------------------|
| 69-92 | GCM engine instantiation | GCM mode tests |
| 128-164 | PREPARE state: mode-specific input preparation | All modes |
| 147-157 | GCM mode: H calculation and CTR encryption | GCM tests |
| 174-216 | POST_PROC state: output processing per mode | All modes |
| 180-187 | CBC encryption/decryption feedback handling | CBC tests |
| 190-209 | CTR and GCM counter handling | CTR/GCM tests |

**Coverage Gaps**:
- **ENTIRE MODULE** - No baseline coverage
- Lines 128-164: MODE_ECB, MODE_CBC, MODE_CTR, MODE_GCM paths
- Lines 174-216: All mode-specific output processing
- GCM engine integration at lines 69-92

---

### 6. sbox_masked.v (339 lines) - TI MASKED S-BOX ⚠️ UNCOVERED

**Function**: Threshold Implementation (TI) 3-share masked S-Box

**Status**: **NOT COVERED by baseline test** - Security-critical gap

**Pipeline Stages**: STAGE_IDLE → IN → MAP → INV → IMAP → AFF → OUT

**Coverage-Sensitive Sections**:

| Line Range | Description | Test Requirement |
|------------|-------------|------------------|
| 65-121 | GF(2^4) operations: mul, square, inv, scale | GF arithmetic |
| 126-163 | Isomorphism mappings (iso_map, iso_inv_map) | Field conversion |
| 168-180 | Affine transformation | Linear operation |
| 185-245 | Pipeline control FSM | Pipeline stages |
| 253-326 | 3-share computation with DOM | Masked computation |
| 267-272 | STAGE_IN: Input share processing | Input handling |
| 275-289 | STAGE_MAP: GF operations | Core computation |
| 310-317 | STAGE_AFF: Affine with remasking | Output masking |

**Coverage Gaps**:
- **ENTIRE MODULE** - No baseline coverage
- All 7 pipeline stages need exercising
- DOM multiplier paths need coverage
- Random mask input paths need testing

---

### 7. gcm_engine.v (168 lines) - GCM AUTHENTICATION ⚠️ UNCOVERED

**Function**: GCM mode GHASH engine for authentication

**Status**: **NOT COVERED by baseline test**

**FSM States**: IDLE → INIT → AAD → CT → LEN → TAG_WAIT → TAG_FINAL → VERIFY

**Coverage-Sensitive Sections**:

| Line Range | Description | Test Requirement |
|------------|-------------|------------------|
| 52-73 | GF(2^128) multiplier function | GF multiplication |
| 101-165 | GHASH state machine | GCM protocol |
| 114-121 | AAD processing state | AAD tests |
| 123-130 | Ciphertext processing state | CT tests |
| 138-143 | TAG_WAIT: J0 wait state | Tag generation |
| 145-154 | TAG_FINAL: Tag computation | Tag output |
| 156-161 | VERIFY: Tag verification | Decrypt verify |

**Coverage Gaps**:
- **ENTIRE MODULE** - No baseline coverage
- All GHASH states need exercising
- GF(2^128) multiplication needs coverage
- Tag verification path (decrypt mode)

---

### 8. xts_engine.v (187 lines) - XTS MODE ⚠️ UNCOVERED

**Function**: XTS-AES mode engine with tweak calculation

**Status**: **NOT COVERED by baseline test**

**FSM States**: IDLE → CALC_TWEAK → WAIT_TWEAK → MULT_ALPHA → XOR_TWEAK → ENC_DATA → WAIT_ENC → XOR_OUT → DONE → NEXT_SECTOR

**Coverage-Sensitive Sections**:

| Line Range | Description | Test Requirement |
|------------|-------------|------------------|
| 63-72 | gf_mul_alpha function | Tweak multiplication |
| 75-86 | gf_pow_alpha function | Alpha exponentiation |
| 104-112 | IDLE: Sector ID + offset calculation | Multi-sector |
| 128-136 | MULT_ALPHA: Block number multiplication | Tweak calc |
| 156-158 | XOR_OUT: XTS output | Data output |
| 171-179 | NEXT_SECTOR: Sector increment handling | Multi-sector |

**Coverage Gaps**:
- **ENTIRE MODULE** - No baseline coverage
- MULT_ALPHA loop for block_num > 0 (lines 128-136)
- NEXT_SECTOR state for multi-sector handling
- gf_pow_alpha function (lines 75-86)

---

### 9. cts_handler.v (162 lines) - CTS HANDLING ⚠️ UNCOVERED

**Function**: Ciphertext Stealing for non-aligned data (1-127 bits)

**Status**: **NOT COVERED by baseline test**

**FSM States**: IDLE → CHECK_SIZE → FULL_BLOCK/PAD_BLOCK → PROCESS → STEAL_ENC → DEC_GET_PARTIAL → DEC_DECRYPT_2 → DEC_OUTPUT_1/2 → DONE

**Coverage-Sensitive Sections**:

| Line Range | Description | Test Requirement |
|------------|-------------|------------------|
| 71-93 | CHECK_SIZE: Full vs partial block decision | Block size |
| 79-84 | Encryption: PAD_BLOCK with C_{n-1} padding | CTS enc |
| 85-92 | Decryption: DEC_GET_PARTIAL init | CTS dec |
| 103-117 | PAD_BLOCK → STEAL_ENC: Encryption stealing | Stealing |
| 119-149 | Decryption states (BUG-013) | CTS decrypt |

**Coverage Gaps**:
- **ENTIRE MODULE** - No baseline coverage
- All valid_bits values from 1-127 need testing
- Decryption path (lines 85-92, 119-149)
- STEAL_ENC output logic

---

### 10. fault_detector.v (114 lines) - FAULT DETECTION

**Function**: Dual execution comparison for fault detection

**FSM States**: IDLE → EXEC_A → EXEC_B → COMPARE → CRC_CHECK → DONE/ERROR

**Coverage-Sensitive Sections**:

| Line Range | Description | Test Requirement |
|------------|-------------|------------------|
| 56-111 | Main FSM for fault detection | All states |
| 76-85 | COMPARE state: result comparison | Mismatch detect |
| 87-96 | CRC_CHECK state: CRC validation | CRC error |
| 103-108 | ERROR state: Hold until acknowledged | Error hold |

**Coverage Gaps**:
- Lines 76-85: Result mismatch path needs fault injection
- Lines 87-96: CRC failure path needs forced CRC error
- Lines 103-108: ERROR hold state needs testing

---

### 11. crc_checker.v (90 lines) - CRC CHECKER

**Function**: CRC-32 calculator for data integrity

**FSM States**: IDLE → CALC → DONE

**Coverage-Sensitive Sections**:

| Line Range | Description | Test Requirement |
|------------|-------------|------------------|
| 49-81 | CRC calculation state machine | CRC FSM |
| 57-69 | Bit-by-bit CRC calculation loop | All 128 bits |
| 62-68 | Polynomial XOR for feedback=1 | CRC math |

**Coverage Gaps**:
- All 128 bits of data_in need coverage for toggle
- Feedback=0 and feedback=1 paths in loop

---

### 12. key_manager.v (63 lines) - KEY MANAGEMENT

**Function**: Secure key storage with zeroization

**Coverage-Sensitive Sections**:

| Line Range | Description | Test Requirement |
|------------|-------------|------------------|
| 35-50 | Key loading and zeroization | Security tests |
| 40-44 | Zeroization on zeroize=1 | Key clear |
| 59-61 | Key length masking | Key masking |

**Coverage Gaps**:
- Zeroization path (lines 40-44) needs explicit test
- Key masking logic needs verification

---

### 13. apb_if.v (81 lines) - APB INTERFACE ⚠️ UNCOVERED

**Function**: APB slave interface for configuration

**Status**: **NOT COVERED by baseline test**

**FSM States**: IDLE → SETUP → ACCESS

**Coverage-Sensitive Sections**:

| Line Range | Description | Test Requirement |
|------------|-------------|------------------|
| 44-62 | APB state machine | APB protocol |
| 67-72 | Register interface sampling | Config timing |
| 76-78 | Read data output | APB read |

**Coverage Gaps**:
- **ENTIRE MODULE** - No baseline coverage
- All APB states need exercising
- PREADY timing variations

---

### 14. axi4_stream_if.v (82 lines) - AXI-STREAM INTERFACE ⚠️ UNCOVERED

**Function**: AXI4-Stream interface for data flow

**Status**: **NOT COVERED by baseline test**

**Coverage-Sensitive Sections**:

| Line Range | Description | Test Requirement |
|------------|-------------|------------------|
| 38 | s_axis_tready generation | Flow control |
| 41-59 | RX logic: Buffer and valid | RX handling |
| 63-79 | TX logic: Output and ready | TX handling |

**Coverage Gaps**:
- **ENTIRE MODULE** - No baseline coverage
- RX buffer full/empty conditions
- TX back-pressure handling

---

## Safety Mechanism Implementation Review

### SM-001 ~ SM-010: Dual-Rail Lockstep (aes_top.v)

| ID | Mechanism | Location | Implementation Status |
|----|-----------|----------|----------------------|
| SM-001 | Core A primary execution | Line 226-240 | ✓ Implemented |
| SM-002 | Core B lockstep execution | Line 278-292 | ✓ Implemented |
| SM-003 | Result comparison | fault_detector.v | ✓ Implemented |
| SM-004 | Clock gating for Core B | Line 261-275 | ✓ Implemented |
| SM-005 | Fault detection output | Line 369-376 | ✓ Implemented |

### SM-011 ~ SM-030: CRC Error Detection

| ID | Mechanism | Location | Implementation Status |
|----|-----------|----------|----------------------|
| SM-011 | CRC-32 calculation | crc_checker.v | ✓ Implemented |
| SM-012 | CRC error flag | aes_top.v:335-356 | ✓ Implemented |
| SM-013 | CRC interrupt | aes_top.v:608 | ✓ Implemented |

### SM-031 ~ SM-040: Key Protection

| ID | Mechanism | Location | Implementation Status |
|----|-----------|----------|----------------------|
| SM-031 | Key zeroization | key_manager.v:40-44 | ✓ Implemented |
| SM-032 | Key valid flag | key_manager.v:47-48 | ✓ Implemented |
| SM-033 | Key length masking | key_manager.v:59-61 | ✓ Implemented |

### SM-041 ~ SM-048: Timeout/FSM Safety

| ID | Mechanism | Location | Implementation Status |
|----|-----------|----------|----------------------|
| SM-041 | Watchdog timer | aes_controller.v:100-128 | ✓ Implemented |
| SM-042 | Timeout error flag | aes_controller.v:228,273-274 | ✓ Implemented |
| SM-043 | ERROR state | aes_controller.v:203-207 | ✓ Implemented |

---

## Unimplemented/Stub Sections

| Module | Line Range | Description | Impact |
|--------|------------|-------------|--------|
| aes_controller | 163-167 | KEY_WAIT state (bypassed) | None - design choice |
| aes_controller | 188-192 | FINAL_ROUND state (reserved) | Low - future use |
| mode_controller | 78 | j0_data/j0_valid unused | Medium - GCM limited |
| mode_controller | 91 | tag_mismatch unconnected | Low - debug only |
| sbox_masked | 291-296 | DOM multiplier simplified | Medium - security |
| gcm_engine | 138-143 | TAG_WAIT state (J0 unused) | Medium - GCM limited |

---

## Recommendations

### Priority 1: Uncovered Module Testing
1. **mode_controller**: Required for GCM/XTS/CTS mode coverage
2. **sbox_masked**: Critical for security validation
3. **gcm_engine**: Required for GCM mode authentication
4. **xts_engine**: Required for storage encryption
5. **cts_handler**: Required for non-aligned data
6. **apb_if**: Required for interface coverage
7. **axi4_stream_if**: Required for data flow coverage

### Priority 2: Coverage-Sensitive Code
1. Error state transitions in all FSMs
2. Watchdog timeout paths
3. CRC error detection paths
4. Fault injection response paths
5. Key zeroization paths

### Priority 3: Condition Coverage
1. All if/else branches in mode_controller
2. All case statement values in state machines
3. Boundary conditions (key_len, mode, valid_bits)

---

## Appendix: Line Count Summary

| Module | Total Lines | Code Lines | Coverage Target |
|--------|-------------|------------|-----------------|
| aes_top | 616 | ~450 | 90% |
| aes_controller | 292 | ~220 | 95% |
| aes_core | 297 | ~240 | 90% |
| key_schedule | 384 | ~300 | 90% |
| mode_controller | 229 | ~180 | 85% |
| sbox_masked | 339 | ~280 | 80% |
| gcm_engine | 168 | ~130 | 85% |
| xts_engine | 187 | ~150 | 85% |
| cts_handler | 162 | ~130 | 85% |
| fault_detector | 114 | ~90 | 95% |
| crc_checker | 90 | ~70 | 90% |
| key_manager | 63 | ~50 | 95% |
| apb_if | 81 | ~65 | 90% |
| axi4_stream_if | 82 | ~65 | 90% |
| **TOTAL** | **2904** | **~2420** | **>90%** |

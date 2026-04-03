# Coverage Improvement Plan

**Project**: AES Crypto IP (ASIL-D)  
**Date**: 2026-03-31  
**Author**: Verification Agent  
**Current Coverage**: 36.5%  
**Target Coverage**: >90%  
**Coverage Gap**: -53.5%

---

## Executive Summary

This plan outlines the strategy to achieve >90% line coverage for the AES IP. The plan is divided into 4 phases, requiring **12 new testcases** and estimated **5 days** of implementation effort.

### Improvement Summary

| Phase | Tests | Expected Gain | Timeline | Cumulative |
|-------|-------|---------------|----------|------------|
| 1 | Interface tests (2) | +4% | Day 1 | 40.5% |
| 2 | Mode-specific tests (5) | +22% | Day 2-3 | 62.5% |
| 3 | Error/safety tests (3) | +15% | Day 4 | 77.5% |
| 4 | Stress/random tests (2) | +8% | Day 5 | 85.5% |
| 5 | Existing tests completion | +5% | Day 5 | **90.5%** |
| **Total** | **12 new tests** | **+54%** | **5 days** | **>90%** |

---

## Phase 1: Interface Tests (Day 1)

### Test 1: tc_apb_interface_full

**Objective**: Cover apb_if.v module and APB protocol

**Coverage Gap**: 81 lines × 90% = 73 lines

**Test Steps**:
1. Test IDLE → SETUP → ACCESS → IDLE transitions
2. Test write transactions to all register addresses
3. Test read transactions from all register addresses
4. Test PREADY timing variations
5. Test PSLVERR generation

**Target Lines** (apb_if.v):
| Line Range | Description |
|------------|-------------|
| 44-48 | IDLE → SETUP |
| 50-53 | SETUP → ACCESS |
| 55-59 | ACCESS → IDLE |
| 67-72 | Register sampling |
| 76-78 | Read data output |

**Estimated Coverage Gain**: +2.5%

**Dependencies**: None

---

### Test 2: tc_axi_stream_flow

**Objective**: Cover axi4_stream_if.v and data flow control

**Coverage Gap**: 82 lines × 90% = 74 lines

**Test Steps**:
1. Test RX buffer full/empty conditions
2. Test TX back-pressure handling
3. Test TREADY generation with buffer states
4. Test TLAST handling
5. Test continuous data flow

**Target Lines** (axi4_stream_if.v):
| Line Range | Description |
|------------|-------------|
| 38 | s_axis_tready |
| 41-59 | RX logic |
| 63-79 | TX logic |

**Estimated Coverage Gain**: +2.5%

**Dependencies**: None

---

## Phase 2: Mode-Specific Tests (Day 2-3)

### Test 3: tc_mode_controller_full

**Objective**: Cover mode_controller.v all 6 modes

**Coverage Gap**: 229 lines × 85% = 195 lines

**Test Steps**:
1. ECB mode encryption/decryption
2. CBC mode with IV chaining
3. CTR mode with counter increment
4. GCM mode with H calculation
5. XTS mode with tweak
6. CTS mode handling

**Target Lines** (mode_controller.v):
| Line Range | Description | Mode |
|------------|-------------|------|
| 128-132 | PREPARE ECB | ECB |
| 134-139 | PREPARE CBC | CBC |
| 142-145 | PREPARE CTR | CTR |
| 147-157 | PREPARE GCM | GCM |
| 160-163 | PREPARE XTS | XTS |
| 176-178 | POST_PROC ECB | ECB |
| 180-187 | POST_PROC CBC | CBC |
| 190-193 | POST_PROC CTR | CTR |
| 195-209 | POST_PROC GCM | GCM |

**Estimated Coverage Gain**: +7%

**Dependencies**: GCM/XTS/CTS RTL integration

---

### Test 4: tc_sbox_masked_ti

**Objective**: Cover sbox_masked.v TI implementation

**Coverage Gap**: 339 lines × 80% = 271 lines

**Test Steps**:
1. Test all 7 pipeline stages
2. Test 3-share input processing
3. Test GF(2^4) operations
4. Test isomorphism mappings
5. Test affine transformation with remasking

**Target Lines** (sbox_masked.v):
| Line Range | Description |
|------------|-------------|
| 65-81 | gf16_mul |
| 86-93 | gf16_square |
| 98-108 | gf16_inv |
| 126-163 | iso_map/iso_inv_map |
| 168-180 | affine |
| 212-244 | Pipeline stages |
| 267-326 | Share computation |

**Estimated Coverage Gain**: +9%

**Dependencies**: TI S-Box integration

---

### Test 5: tc_gcm_ghash_full

**Objective**: Cover gcm_engine.v GHASH operations

**Coverage Gap**: 168 lines × 85% = 143 lines

**Test Steps**:
1. GF(2^128) multiplication
2. AAD processing
3. Ciphertext processing
4. Length block addition
5. Tag generation
6. Tag verification

**Target Lines** (gcm_engine.v):
| Line Range | Description |
|------------|-------------|
| 52-73 | gf_mul |
| 101-108 | IDLE → INIT |
| 114-121 | AAD state |
| 123-130 | CT state |
| 132-136 | LEN state |
| 145-154 | TAG_FINAL |
| 156-161 | VERIFY |

**Estimated Coverage Gain**: +5%

**Dependencies**: GCM engine integration

---

### Test 6: tc_xts_tweak_full

**Objective**: Cover xts_engine.v tweak calculation

**Coverage Gap**: 187 lines × 85% = 159 lines

**Test Steps**:
1. Single sector encryption
2. Multi-sector with increment
3. Alpha multiplication
4. Block number multiplication
5. Tweak XOR with data

**Target Lines** (xts_engine.v):
| Line Range | Description |
|------------|-------------|
| 63-72 | gf_mul_alpha |
| 75-86 | gf_pow_alpha |
| 104-112 | Sector calculation |
| 128-136 | MULT_ALPHA |
| 171-179 | NEXT_SECTOR |

**Estimated Coverage Gain**: +5%

**Dependencies**: XTS engine integration

---

### Test 7: tc_cts_stealing_full

**Objective**: Cover cts_handler.v all boundary conditions

**Coverage Gap**: 162 lines × 85% = 138 lines

**Test Steps**:
1. Full block (128 bits) - no stealing
2. Partial block 1-63 bits
3. Partial block 64-127 bits
4. Encryption with stealing
5. Decryption with stealing

**Target Lines** (cts_handler.v):
| Line Range | Description |
|------------|-------------|
| 71-77 | CHECK_SIZE full |
| 79-84 | PAD_BLOCK enc |
| 85-92 | DEC_GET_PARTIAL init |
| 103-117 | STEAL_ENC |
| 119-149 | Decrypt states |

**Estimated Coverage Gain**: +5%

**Dependencies**: CTS handler integration

---

## Phase 3: Error and Safety Tests (Day 4)

### Test 8: tc_error_states_full

**Objective**: Cover all error paths and FSM error states

**Coverage Gap**: Error paths in multiple modules

**Test Steps**:
1. Force watchdog timeout in aes_controller
2. Verify ERROR state entry
3. Test clear_fault recovery
4. Test sticky fault bits
5. Verify interrupt generation

**Target Lines**:
| Module | Line Range | Description |
|--------|------------|-------------|
| aes_controller | 148-149 | Watchdog timeout |
| aes_controller | 203-207 | ERROR → IDLE |
| aes_controller | 271-278 | ERROR outputs |
| aes_top | 422-435 | Sticky fault clearing |
| fault_detector | 76-111 | Compare FSM |

**Estimated Coverage Gain**: +5%

**Dependencies**: Fault injection capability

---

### Test 9: tc_safety_mechanisms

**Objective**: Cover all safety mechanisms (SM-001~048)

**Coverage Gap**: Safety mechanism paths

**Test Steps**:
1. Dual-rail mismatch detection (SM-001~010)
2. CRC error detection (SM-011~020)
3. Key zeroization (SM-031~040)
4. FSM timeout (SM-041~048)
5. Fault interrupt generation

**Target Lines**:
| Module | Line Range | Safety Mechanism |
|--------|------------|------------------|
| aes_top | 256-392 | Dual-rail lockstep |
| aes_top | 339-356 | CRC error |
| key_manager | 40-44 | Key zeroization |
| aes_controller | 100-128 | Watchdog timer |

**Estimated Coverage Gain**: +5%

**Dependencies**: Fault injection hooks

---

### Test 10: tc_key_zeroization

**Objective**: Cover key_manager zeroization and protection

**Coverage Gap**: 63 lines × 95% = 60 lines

**Test Steps**:
1. Normal key loading
2. Zeroize signal assertion
3. Verify key cleared
4. Verify key_valid deasserted
5. Test key length masking

**Target Lines** (key_manager.v):
| Line Range | Description |
|------------|-------------|
| 40-44 | Zeroization |
| 47-48 | key_valid |
| 59-61 | Key masking |

**Estimated Coverage Gain**: +2%

**Dependencies**: None

---

## Phase 4: Stress and Random Tests (Day 5)

### Test 11: tc_toggle_maximization

**Objective**: Maximize toggle coverage on wide buses

**Coverage Gap**: Toggle coverage on 128/256-bit signals

**Test Steps**:
1. Walking ones on data_in (128-bit)
2. Walking zeros on key (256-bit)
3. Alternating patterns
4. Single bit walk
5. Fast toggle burst

**Target Signals**:
| Signal | Width |
|--------|-------|
| s_axis_tdata | 128 |
| m_axis_tdata | 128 |
| key_in | 256 |
| pwdata | 32 |
| ctrl_reg | 32 |

**Estimated Coverage Gain**: +4%

**Dependencies**: None

---

### Test 12: tc_random_stress

**Objective**: Random stress testing for condition coverage

**Coverage Gap**: Condition coverage on if/else branches

**Test Steps**:
1. Random mode/key_len combinations
2. Rapid start/stop sequences
3. Back-to-back operations
4. Mode switching
5. Register read/write during operation

**Target Conditions**:
- All if/else in mode_controller
- All state transitions
- All boundary conditions

**Estimated Coverage Gain**: +4%

**Dependencies**: None

---

## Testcase Summary

### New Testcases Required (12)

| # | Testcase | Module | Coverage Gain | Phase |
|---|----------|--------|---------------|-------|
| 1 | tc_apb_interface_full | apb_if | +2.5% | 1 |
| 2 | tc_axi_stream_flow | axi4_stream_if | +2.5% | 1 |
| 3 | tc_mode_controller_full | mode_controller | +7% | 2 |
| 4 | tc_sbox_masked_ti | sbox_masked | +9% | 2 |
| 5 | tc_gcm_ghash_full | gcm_engine | +5% | 2 |
| 6 | tc_xts_tweak_full | xts_engine | +5% | 2 |
| 7 | tc_cts_stealing_full | cts_handler | +5% | 2 |
| 8 | tc_error_states_full | Multiple | +5% | 3 |
| 9 | tc_safety_mechanisms | Multiple | +5% | 3 |
| 10 | tc_key_zeroization | key_manager | +2% | 3 |
| 11 | tc_toggle_maximization | Data path | +4% | 4 |
| 12 | tc_random_stress | Condition | +4% | 4 |
| **Total** | **12 new** | **7 modules** | **+56%** | **4 phases** |

### Existing Tests to Complete (13)

The following existing tests will provide additional coverage when fully executed:

| Category | Tests | Est. Gain |
|----------|-------|-----------|
| ECB | tc_ecb_nist, tc_ecb_multiblock | +1% |
| CBC | tc_cbc_nist, tc_cbc_decrypt, tc_cbc_multiblock | +1% |
| CTR | tc_ctr_nist, tc_ctr_counter, tc_ctr_multiblock | +1% |
| Key | tc_key_length, tc_key_len_error, tc_key_schedule_* | +1% |
| Coverage | tc_toggle_coverage, tc_corner_cases, tc_reset_error_coverage | +1% |
| **Total** | **13 tests** | **+5%** |

---

## Implementation Timeline

### Day 1: Interface Tests
- [ ] Create tc_apb_interface_full
- [ ] Create tc_axi_stream_flow
- [ ] Run and verify both tests
- **Expected Coverage**: 36.5% → 41.5%

### Day 2: Mode Tests (Part 1)
- [ ] Create tc_mode_controller_full
- [ ] Create tc_sbox_masked_ti
- [ ] Create tc_gcm_ghash_full
- [ ] Run and verify tests
- **Expected Coverage**: 41.5% → 62.5%

### Day 3: Mode Tests (Part 2)
- [ ] Create tc_xts_tweak_full
- [ ] Create tc_cts_stealing_full
- [ ] Run all mode tests with coverage merge
- **Expected Coverage**: 62.5% → 72.5%

### Day 4: Error and Safety
- [ ] Create tc_error_states_full
- [ ] Create tc_safety_mechanisms
- [ ] Create tc_key_zeroization
- [ ] Run with fault injection
- **Expected Coverage**: 72.5% → 82.5%

### Day 5: Stress and Completion
- [ ] Create tc_toggle_maximization
- [ ] Create tc_random_stress
- [ ] Run existing 13 tests to completion
- [ ] Merge all coverage data
- [ ] Generate final report
- **Expected Coverage**: 82.5% → 90.5%

---

## Resource Requirements

### Tools Required

| Tool | Version | Purpose |
|------|---------|---------|
| Verilator | >= 5.0 | Coverage collection |
| genhtml | Latest | HTML report generation |
| lcov | Latest | Coverage merging |
| make | Standard | Build automation |

### Compute Resources

| Phase | Est. Time | Tests | Parallel |
|-------|-----------|-------|----------|
| 1 | 2 hours | 2 | Yes |
| 2 | 6 hours | 6 | Yes |
| 3 | 4 hours | 3 | Yes |
| 4 | 4 hours | 3 + 13 | Yes |
| **Total** | **16 hours** | **27** | **Full** |

### Personnel

| Role | Effort | Tasks |
|------|--------|-------|
| Verification Engineer | 5 days | Test implementation |
| RTL Designer | 1 day | Review and debug |
| Coverage Review | 0.5 day | Final analysis |

---

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Module integration issues | Medium | High | Verify instantiation in aes_top |
| Simulation timeouts | Medium | Medium | Use Verilator, add timeouts |
| Fault injection limitations | Low | Medium | Use RTL force statements |
| Coverage target miss | Low | Medium | Add more directed tests |

---

## Success Criteria

- [ ] All 12 new tests implemented
- [ ] All 53 tests executed
- [ ] Line coverage >90%
- [ ] FSM coverage >95%
- [ ] Toggle coverage >85%
- [ ] All 26 assertions passing
- [ ] Coverage report generated in `ProjectMgmt/Reviews/IDR/html/`

---

## Appendix: Test Template

### New Testcase Template

```systemverilog
//============================================================================
// Testcase: tc_<name>
// Description: <description>
// Coverage: <module>, lines <range>
//============================================================================

`include "../../Env/tb/tb_base.sv"

module tc_<name>;
    tb_base tb();
    
    initial begin
        $display("========================================");
        $display("Test: <name>");
        $display("========================================");
        
        @(posedge tb.rst_n);
        #100;
        
        // Test steps here
        
        tb.report_results();
        #100; $finish;
    end
endmodule
```

---

**Document Version**: 1.0  
**Last Updated**: 2026-03-31  
**Next Review**: After Phase 2 completion

# AES IP Functional Coverage Analysis

**Date**: 2026-04-01
**Purpose**: Identify missing functional coverage and RTL gaps

---

## 1. RTL Modules Inventory (14 modules)

| Module | Description | Current Test Coverage | Gap Analysis |
|--------|-------------|----------------------|--------------|
| aes_top | Top-level integration | tc_smoke | Basic only |
| apb_if | APB register interface | tc_smoke | Partial |
| axi4_stream_if | AXI4-Stream data interface | tc_smoke | Basic only |
| aes_controller | Main control logic | tc_smoke | Partial |
| aes_core | Core encryption/decryption | tc_ecb_nist, tc_cbc_nist, etc. | Covered |
| key_manager | Key management | tc_key_length | Partial |
| key_schedule | Key expansion | tc_key_schedule_simple | Partial |
| mode_controller | Mode switching (ECB/CBC/CTR/GCM/XTS/CTS) | tc_mode_coverage | Partial |
| gcm_engine | GCM authentication | tc_gcm_basic | Basic only |
| xts_engine | XTS tweak handling | tc_xts_basic | Basic only |
| cts_handler | CTS ciphertext stealing | tc_cts_boundary | Boundary only |
| sbox_masked | Masked S-Box (side-channel resistant) | tc_sbox_masked | Covered |
| fault_detector | Fault detection logic | tc_fault_inject | Partial |
| crc_checker | CRC check for data integrity | tc_fault_data_corr | Partial |

---

## 2. Function Coverage Matrix

### 2.1 Register Interface (apb_if)

| Register | Address | R/W | Current Coverage | Missing Tests |
|----------|---------|-----|------------------|---------------|
| CTRL | 0x000 | RW | tc_smoke | All bit fields |
| STATUS | 0x004 | R | tc_smoke | All status bits |
| KEY_LEN | 0x008 | RW | tc_smoke | Valid values only |
| MODE | 0x00C | RW | tc_smoke | ECB only |
| KEY_0-7 | 0x010-0x02C | W | tc_smoke | Partial |
| IV_0-3 | 0x030-0x03C | W | tc_cbc_nist | Partial |
| CTS_EN | 0x040 | RW | tc_cts_boundary | Basic |
| INT_EN | 0x048 | RW | tc_smoke | Basic |
| INT_STAT | 0x04C | RC | - | **NOT TESTED** |
| ERR_STAT | 0x044 | RC | tc_key_len_error | Partial |
| DATA_IN_0-3 | 0x100-0x10C | W | tc_smoke | Partial |
| DATA_OUT_0-3 | 0x110-0x11C | R | tc_smoke | Partial |

**Missing**: INT_STAT register coverage, all bit-field level tests

### 2.2 Mode Controller

| Mode | Encrypt | Decrypt | Multi-block | Current Test | Gap |
|------|---------|---------|-------------|--------------|-----|
| ECB | ✅ | ✅ | ✅ | tc_ecb_multiblock | None |
| CBC | ✅ | ✅ | ⚠️ | tc_cbc_decrypt | Multi-block missing |
| CTR | ✅ | ✅ | ⚠️ | tc_ctr_counter | Multi-block missing |
| GCM | ⚠️ | ⚠️ | ❌ | tc_gcm_basic | **Full implementation needed** |
| XTS | ⚠️ | ⚠️ | ❌ | tc_xts_basic | **Multi-sector missing** |
| CTS | ✅ | ⚠️ | ❌ | tc_cts_boundary | **Decrypt missing** |

### 2.3 Key Manager

| Feature | Current Test | Status | Gap |
|---------|--------------|--------|-----|
| Key load 128-bit | tc_key_length | ✅ | None |
| Key load 192-bit | tc_key_length_192_* | ✅ | None |
| Key load 256-bit | tc_key_length_256_* | ✅ | None |
| Key clear | - | ❌ | **NOT TESTED** |
| Key retention | - | ❌ | **NOT TESTED** |
| Key update during operation | - | ❌ | **NOT TESTED** |

### 2.4 Interrupt Controller

| Interrupt | Source | Current Test | Status |
|-----------|--------|--------------|--------|
| INT_DONE | Operation complete | Implicit | ⚠️ Partial |
| INT_ERROR | Error detected | tc_key_len_error | ⚠️ Partial |
| INT_FAULT | Fault detected | tc_fault_inject | ⚠️ Partial |
| INT_DMA | DMA complete | - | ❌ **NOT TESTED** |

**Missing**: Dedicated interrupt test

### 2.5 Error Handling

| Error Type | Detection | Reporting | Current Test | Status |
|------------|-----------|-----------|--------------|--------|
| Invalid mode | ✅ | ✅ | tc_error_injection | ✅ |
| Invalid key_len | ✅ | ✅ | tc_key_len_error | ✅ |
| GCM tag mismatch | ⚠️ | ⚠️ | tc_gcm_basic | ❌ **Missing** |
| CRC mismatch | ✅ | ⚠️ | tc_fault_data_corr | ⚠️ Partial |
| Fault detected | ✅ | ⚠️ | tc_fault_inject | ⚠️ Partial |

---

## 3. Missing Testcases

### Critical Missing (for IDR)

| Testcase | Description | RTL Dependency | Priority |
|----------|-------------|----------------|----------|
| tc_register_full | Full register bit-field coverage | None | High |
| tc_interrupt_all | All interrupt sources | INT_STAT working | High |
| tc_key_clear | Key clear functionality | Key clear logic | Medium |
| tc_cbc_multiblock | CBC multi-block chaining | Working RTL | Medium |
| tc_ctr_multiblock | CTR multi-block counter | Working RTL | Medium |
| tc_gcm_full | Full GCM with tag verify | **BUG-011** | High |
| tc_xts_multisector | XTS multi-sector | **BUG-012** | High |
| tc_cts_decrypt | CTS decryption | **BUG-013** | Medium |
| tc_crc_full | CRC checker full coverage | CRC module | Medium |
| tc_fault_full | Complete fault injection | Fault detector | Medium |

### Nice to Have (for DDR)

| Testcase | Description |
|----------|-------------|
| tc_dma_transfer | DMA mode transfer |
| tc_low_power | Clock gating / power modes |
| tc_performance | Throughput measurement |
| tc_stress_random | Random stress test |

---

## 4. RTL Bug Candidates

Based on test analysis, the following RTL features may need implementation:

| Bug ID | Description | Module | Evidence |
|--------|-------------|--------|----------|
| BUG-011 | GCM tag generation/verification incomplete | gcm_engine | tc_gcm_basic only tests basic flow |
| BUG-012 | XTS multi-sector tweak calculation incomplete | xts_engine | tc_xts_basic only tests single sector |
| BUG-013 | CTS decryption not implemented | cts_handler | tc_cts_boundary only tests encryption |
| BUG-014 | Interrupt status register (INT_STAT) not functional | apb_if | No test coverage |
| BUG-015 | Key clear functionality missing | key_manager | No way to clear keys |
| BUG-016 | CRC checker not fully integrated | crc_checker | Limited test coverage |

---

## 5. Recommendations

### For IDR Entry
1. Add tc_register_full for complete register coverage
2. Add tc_interrupt_all for interrupt verification
3. File BUG-011, BUG-012, BUG-013 for incomplete modes
4. File BUG-014 for INT_STAT register

### For DDR
1. Implement missing RTL features
2. Add comprehensive testcases for fixed bugs
3. Add performance and stress tests

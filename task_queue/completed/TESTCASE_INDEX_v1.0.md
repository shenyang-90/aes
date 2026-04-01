# AES Crypto IP - Directed Testcase Index

**文档版本**: v1.0  
**生成日期**: 2026-04-01  
**作者**: Verification Agent  

---

## 目录

1. [Basic Function Tests](#basic-function-tests)
2. [Mode Tests](#mode-tests)
3. [CTS Boundary Tests](#cts-boundary-tests)
4. [Safety Mechanism Tests](#safety-mechanism-tests)
5. [Fault Injection Tests](#fault-injection-tests)

---

## Basic Function Tests

| Testcase | Description | Coverage | Status |
|----------|-------------|----------|--------|
| tc_aes128_ecb | AES-128 ECB basic test | ECB mode | Planned |
| tc_aes192_ecb | AES-192 ECB basic test | ECB mode | Planned |
| tc_aes256_ecb | AES-256 ECB basic test | ECB mode | Planned |
| tc_basic_rst | Reset sequence test | Reset logic | Planned |
| tc_basic_reg | Register access test | APB interface | Planned |

## Mode Tests

| Testcase | Description | Coverage | Status |
|----------|-------------|----------|--------|
| tc_cbc_encrypt | CBC mode encryption | CBC mode | Planned |
| tc_cbc_decrypt | CBC mode decryption | CBC mode | Planned |
| tc_ctr_encrypt | CTR mode encryption | CTR mode | Planned |
| tc_gcm_encrypt | GCM mode encryption | GCM mode | Planned |
| tc_gcm_decrypt | GCM mode decryption | GCM mode | Planned |
| tc_xts_encrypt | XTS mode encryption | XTS mode | Planned |
| tc_xts_decrypt | XTS mode decryption | XTS mode | Planned |

## CTS Boundary Tests

| Testcase | Description | Coverage | Status |
|----------|-------------|----------|--------|
| tc_cts_1bit | CTS 1-bit boundary | CTS-B-001 | Planned |
| tc_cts_7bit | CTS 7-bit boundary | CTS-B-002 | Planned |
| tc_cts_8bit | CTS 8-bit boundary | CTS-B-003 | Planned |
| tc_cts_80bit | CTS 80-bit boundary | CTS-B-004 | Planned |
| tc_cts_127bit | CTS 127-bit boundary | CTS-B-005 | Planned |
| tc_cts_multiblock | CTS multi-block test | CTS-B-006~031 | Planned |

## Safety Mechanism Tests

| Testcase | Description | Coverage | Status |
|----------|-------------|----------|--------|
| tc_safety_dual_rail | Dual-rail mismatch detection | SM-001~010 | Planned |
| tc_safety_crc_error | CRC error detection | SM-011~020 | Planned |
| tc_safety_key_zeroize | Key zeroization verification | SM-021~030 | Planned |
| tc_safety_fsm_timeout | FSM timeout detection | SM-031~040 | Planned |
| tc_safety_interrupt | Interrupt reporting | SM-041~048 | Planned |

## Fault Injection Tests

| Testcase | Description | Coverage | Status |
|----------|-------------|----------|--------|
| tc_fi_clock_glitch | Clock glitch injection | FG-001~004 | Planned |
| tc_fi_data_corrupt | Data corruption injection | FD-001~004 | Planned |
| tc_fi_voltage_glitch | Voltage glitch injection | Planned |

---

## Testcase Details

### Safety Mechanism Test Details

#### tc_safety_dual_rail
- **Coverage**: SM-001 ~ SM-010
- **Description**: Verify dual-rail fault detection mechanism triggers fault_detected when result_a and result_b mismatch
- **Injection Points**: result_a[0,7,15,31,63,95,127], result_b[0,63,127]
- **Check Point**: fault_detected assertion

#### tc_safety_crc_error
- **Coverage**: SM-011 ~ SM-020 (Multi-bit), SM-021~030 (CRC)
- **Description**: Verify CRC checker detects data corruption and triggers fault
- **Injection Points**: data_in various bits, crc_valid signal
- **Check Point**: crc_valid=0, INT_STATUS[2]

#### tc_safety_key_zeroize
- **Coverage**: SM-031 ~ SM-040
- **Description**: Verify key zeroization mechanism clears key securely
- **Injection Points**: zeroize signal, key_clear via APB, key_in bits
- **Check Point**: key_out=0, key_valid=0

#### tc_safety_fsm_timeout
- **Coverage**: SM-041 ~ SM-048
- **Description**: Verify FSM timeout detection for stuck states
- **Injection Points**: Force state to IDLE, KEY_WAIT, LOAD_DATA, ROUND_OP, OUTPUT_DATA
- **Check Point**: INT_STATUS[3], watchdog timeout

#### tc_safety_interrupt
- **Coverage**: SM-041 ~ SM-048 (Interrupt aspects)
- **Description**: Verify interrupt generation and reporting for all fault types
- **Injection Points**: Various fault conditions
- **Check Point**: int_fault, INT_STATUS register

---

**文档结束**

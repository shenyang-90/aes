# AES Crypto IP - Architecture Specification

## 文档信息

| 字段 | 值 |
|------|-----|
| **版本** | v0.1 |
| **日期** | 2026-03-31 |
| **作者** | System Architect |
| **状态** | Draft |
| **评审** | Pending |

## 目录

1. [概述](#1-概述)
2. [系统架构](#2-系统架构)
3. [算法实现](#3-算法实现)
4. [Countermeasures](#4-countermeasures)
5. [Ciphertext Stealing (CTS)](#5-ciphertext-stealing-cts)
6. [接口定义](#6-接口定义)
7. [性能指标](#7-性能指标)
8. [功能安全](#8-功能安全)
9. [附录](#9-附录)

## 1. 概述

### 1.1 设计目标

设计一款车规级 AES 加密 IP，具备：
- 标准 AES-128/192/256 支持 (FIPS-197)
- 侧信道攻击防护 (DPA/CPA resistant)
- Ciphertext Stealing (XTS-AES) 支持
- ASIL-D 功能安全等级

### 1.2 应用场景

- 车载安全通信 (V2X)
- 存储器加密 (eMMC/UFS/SSD)
- 固件保护 (Secure Boot)
- 密钥管理 (HSM)

## 2. 系统架构

### 2.1 顶层架构

```
+------------------+        +------------------+
|   AXI4-Stream    |--------|   AES Controller  |
|     Slave        |        |                  |
+------------------+        +---------+--------+
                                      |
            +-------------------------+-------------------------+
            |                         |                         |
    +-------v-------+        +--------v--------+       +--------v--------+
    |  Key Manager  |        |   AES Core      |       |  Mode Controller |
    |  (w/ Masking) |        |  (Masked SBox)  |       |  (ECB/CBC/CTR/   |
    +---------------+        +-----------------+       |   GCM/XTS/CTS)  |
            |                         |                +-----------------+
            v                         v
    +----------------+      +------------------+
    | Key Schedule   |      |  Data Path       |
    | (Masked)       |      |  (Shuffled)      |
    +----------------+      +------------------+
```

### 2.2 模块划分

| 模块 | 功能 | 安全要求 |
|------|------|----------|
| `aes_controller` | 控制状态机、寄存器接口 | ASIL-D |
| `aes_core` | AES 轮运算核心 | ASIL-D |
| `key_manager` | 密钥存储、掩码管理 | ASIL-D |
| `key_schedule` | 密钥扩展 ( masked ) | ASIL-D |
| `sbox_masked` | 掩码 S-Box (TI方案) | ASIL-D |
| `mode_controller` | 模式控制 (含CTS) | ASIL-B |
| `fault_detector` | 故障检测逻辑 | ASIL-D |
| `crc_checker` | 数据完整性检查 | ASIL-B |

## 3. 算法实现

### 3.1 AES Core

| 参数 | 值 |
|------|-----|
| 密钥长度 | 128/192/256 bit |
| 轮数 | 10/12/14 |
| 数据宽度 | 128 bit |
| 架构 | Iterative (1 round/cycle) |

### 3.2 S-Box 实现

**方案**: Threshold Implementation (TI) with 3 shares

```
Input:  (x1, x2, x3)  // 3-share masked
Output: (y1, y2, y3)  // 3-share masked

Properties:
- Glitch-free
- Provable 1st-order DPA resistant
- Area: ~8K gates per S-Box
```

### 3.3 轮函数

| 操作 | 实现方式 | Countermeasure |
|------|----------|----------------|
| SubBytes | TI-SBox | Masking |
| ShiftRows | Routing | - |
| MixColumns | GF(2^8) 乘法 | Shuffling |
| AddRoundKey | XOR | Mask refreshing |

## 4. Countermeasures

### 4.1 防护策略

| 攻击类型 | 防护方案 | 实现模块 |
|----------|----------|----------|
| **DPA** | Boolean Masking (3 shares) | S-Box, KeySchedule |
| **CPA** | Random shuffling of operations | AES Core |
| **Template** | Higher-order masking | Full data path |
| **Fault** | Double execution + CRC | Fault Detector |
| **Glitch** | Glitch-free logic | TI S-Box |

### 4.2 Masking 方案

**Share Generation**:
```
Original: x
Masked: (x1, x2, x3) where x = x1 ⊕ x2 ⊕ x3
x1 = random()
x2 = random()
x3 = x ⊕ x1 ⊕ x2
```

**Mask Refreshing**:
- 每轮运算后刷新掩码
- 防止 2nd-order leakages

### 4.3 Shuffling

**Operation Order**:
```
Normal:  SubBytes → ShiftRows → MixColumns → AddKey
Shuffle: Random permutation of byte-wise operations
```

## 5. Ciphertext Stealing (CTS)

### 5.1 XTS-AES 模式

```
T = E_K2(i) ⊗ α^j
C = E_K1(P ⊕ T) ⊕ T
```

| 参数 | 描述 |
|------|------|
| K1 | AES 数据密钥 |
| K2 | AES tweak 密钥 |
| i | Sector number |
| j | Block index within sector |
| α | Galois field primitive element |

### 5.2 CTS 处理

**Ciphertext Stealing** for non-128-bit aligned data:

```
Input:  P_n (last block, |P_n| < 128)
Process:
1. Encrypt P_{n-1} → C_{n-1}
2. C_n = MSB(P_n) ⊕ MSB(C_{n-1})
3. P'_n = P_n || LSB(C_{n-1})
4. Encrypt P'_n → C'_n
5. Final C_{n-1} = C'_n
```

## 6. 接口定义

### 6.1 AXI4-Stream 接口

| 信号 | 方向 | 宽度 | 描述 |
|------|------|------|------|
| `aclk` | Input | 1 | 时钟 |
| `areset_n` | Input | 1 | 异步复位 |
| `s_axis_tvalid` | Input | 1 | 输入数据有效 |
| `s_axis_tready` | Output | 1 | 输入就绪 |
| `s_axis_tdata` | Input | 128 | 输入数据 |
| `s_axis_tlast` | Input | 1 | 输入最后 |
| `m_axis_tvalid` | Output | 1 | 输出数据有效 |
| `m_axis_tready` | Input | 1 | 输出就绪 |
| `m_axis_tdata` | Output | 128 | 输出数据 |
| `m_axis_tlast` | Output | 1 | 输出最后 |

### 6.2 配置寄存器 (APB)

| 地址 | 寄存器 | 描述 |
|------|--------|------|
| 0x00 | CTRL | 启动/模式选择 |
| 0x04 | STATUS | 状态/错误 |
| 0x08 | KEY_LEN | 密钥长度 |
| 0x0C | MODE | ECB/CBC/CTR/GCM/XTS |
| 0x10-0x1C | KEY_0-3 | 密钥 (128-bit) |
| 0x20-0x2C | KEY_4-7 | 密钥扩展 (256-bit) |
| 0x30-0x3C | IV_0-3 | 初始化向量 |
| 0x40 | CTS_EN | CTS 使能 |
| 0x44 | SECTOR_ID | XTS Sector ID |

## 7. 性能指标

| 指标 | 目标 | 备注 |
|------|------|------|
| 吞吐率 | >1 Gbps @ 100MHz | ECB模式 |
| 延迟 | 11 cycles/block | AES-128 |
| 面积 | <50K gates | 不含SRAM |
| 功耗 | <10mW @ 100MHz | 典型工况 |
| 安全等级 | 1st-order DPA resistant | TVLA passing |

## 8. 功能安全

### 8.1 FMEDA

| 安全机制 | DC | 备注 |
|----------|-----|------|
| Dual-core lockstep | 99% | AES Core |
| CRC-32 数据检查 | 99% | 输入/输出 |
| Watchdog | 90% | 超时检测 |
| Parity 检查 | 90% | 寄存器 |

### 8.2 Safety Goals

| ID | 描述 | ASIL |
|----|------|------|
| SG1 | 防止密钥泄露 | ASIL-D |
| SG2 | 防止错误加密结果 | ASIL-D |
| SG3 | 检测故障攻击 | ASIL-D |

## 9. 附录

### 9.1 缩略语

| 缩写 | 全称 |
|------|------|
| AES | Advanced Encryption Standard |
| CTS | Ciphertext Stealing |
| DPA | Differential Power Analysis |
| TI | Threshold Implementation |
| XTS | XEX-based Tweaked Codebook with Ciphertext Stealing |

### 9.2 参考文档

- FIPS-197: AES Specification
- IEEE P1619: XTS-AES Standard
- DPA Book: Mangard et al.
- TI Paper: Nikova et al.

## 变更历史

| 版本 | 日期 | 变更 | 作者 |
|------|------|------|------|
| v0.1 | 2026-03-31 | 初始版本 | System Architect |

# AES Crypto IP - Architecture Specification

## 文档信息

| 字段 | 值 |
|------|-----|
| **版本** | v1.1 |
| **日期** | 2026-04-01 |
| **作者** | System Architect |
| **状态** | Updated - Lockstep Integration |
| **评审** | AI Yang (Quality Gatekeeper) |
| **ASIL** | ASIL-D |
| **变更** | 新增双核锁步架构支持，可配置安全策略 |

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
                    +------------------------------------------+
                    |            aes_top                         |
                    |  +-----------------+    +---------------+ |
   Input       ---> |  |   Core A        |    |   Core B      | |
                    |  |  (Primary)      |    |  (Lockstep)   | |
                    |  +--------+--------+    +--------+------+ |
                    |           |                      |        |
                    |           v                      v        |
                    |  +--------+----------------------------------+
                    |  |        fault_detector                     |
                    |  |  (result_a vs result_b compare)          |
                    |  +------------------------------------------+
```

**说明**: 当 `ENABLE_LOCKSTEP=1` 时，双核锁步结构启用，Core A 和 Core B 执行相同运算，
fault_detector 比较两者结果以检测故障。

### 2.2 模块划分

| 模块 | 功能 | 安全要求 | 可配置性 |
|------|------|----------|----------|
| `aes_controller` | 控制状态机、寄存器接口 | ASIL-D | 固定 |
| `aes_core` × 2 | AES 轮运算核心 (主核+锁步核) | ASIL-D | `ENABLE_LOCKSTEP` 参数控制条件实例化 |
| `key_manager` | 密钥存储、掩码管理 | ASIL-D | 固定 |
| `key_schedule` | 密钥扩展 ( masked ) | ASIL-D | 固定 |
| `sbox_masked` | 掩码 S-Box (TI方案) | ASIL-D | 固定 |
| `mode_controller` | 模式控制 (含CTS) | ASIL-B | 固定 |
| `fault_detector` | 故障检测逻辑 (双核结果比较) | ASIL-D | `ENABLE_LOCKSTEP` 参数控制条件实例化 |
| `crc_checker` | 数据完整性检查 | ASIL-B | 固定 |

**可配置性说明**:
- `ENABLE_LOCKSTEP=0`: 单核模式，仅实例化 Core A，无 fault_detector，适用于非车规场景
- `ENABLE_LOCKSTEP=1`: 双核锁步模式，实例化 Core A + Core B + fault_detector，满足 ASIL-D 要求

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

| 地址 | 寄存器 | 描述 | 位定义 |
|------|--------|------|--------|
| 0x00 | CTRL | 控制寄存器 | [9] DUAL_RAIL_EN - 双核锁步使能<br>[8:1] MODE - 模式选择<br>[0] START - 启动 |
| 0x04 | STATUS | 状态寄存器 | [4] FAULT_DETECTED - 故障检测标志<br>[3:1] STATE - 状态机状态<br>[0] BUSY - 忙标志 |
| 0x08 | KEY_LEN | 密钥长度 | 密钥长度配置 |
| 0x0C | MODE | 加密模式 | ECB/CBC/CTR/GCM/XTS |
| 0x10-0x1C | KEY_0-3 | 密钥 (128-bit) | 密钥低128位 |
| 0x20-0x2C | KEY_4-7 | 密钥扩展 (256-bit) | 密钥扩展位 |
| 0x30-0x3C | IV_0-3 | 初始化向量 | 初始化向量 |
| 0x40 | CTS_EN | CTS 使能 | 密文窃取使能 |
| 0x44 | SECTOR_ID | XTS Sector ID | XTS扇区ID |
| 0x48 | INT_EN | 中断使能 | [2] FAULT_INT_EN - 故障中断使能<br>[1] DONE_INT_EN - 完成中断使能<br>[0] ERROR_INT_EN - 错误中断使能 |
| 0x4C | INT_STATUS | 中断状态 | [2] FAULT_STATUS - 故障中断状态<br>[1] DONE_STATUS - 完成中断状态<br>[0] ERROR_STATUS - 错误中断状态 |

## 7. 性能指标

### 7.1 基础性能指标

| 指标 | 目标 | 备注 |
|------|------|------|
| 吞吐率 | >1 Gbps @ 100MHz | ECB模式 |
| 延迟 | 11 cycles/block | AES-128 |
| 面积 | <50K gates | 不含SRAM |
| 功耗 | <10mW @ 100MHz | 典型工况 |
| 安全等级 | 1st-order DPA resistant | TVLA passing |

### 7.2 Lockstep 模式性能对比

| 模式 | 吞吐率 | 延迟 | 面积 | 功耗 |
|------|--------|------|------|------|
| 单核 (ENABLE_LOCKSTEP=0) | >1 Gbps | 11 cycles | ~35K gates | 基准 |
| 双核禁用 (DUAL_RAIL_EN=0) | >1 Gbps | 11 cycles | ~50K gates | 基准+漏电 |
| 双核启用 (DUAL_RAIL_EN=1) | >1 Gbps | 11 cycles | ~50K gates | 2×动态功耗 |

**说明**:
- 吞吐率和延迟在各模式下保持一致，锁步机制不引入额外性能开销
- 面积差异主要来自 Core B 和 fault_detector 的实例化
- 功耗差异:
  - 单核模式: 仅 Core A 运行，面积和功耗最优
  - 双核禁用模式: Core B 实例化但不运行，存在漏电功耗
  - 双核启用模式: 双核同时运行，动态功耗翻倍

## 8. 功能安全

### 8.1 FMEDA

| 安全机制 | DC | 可配置性 | 备注 |
|----------|-----|----------|------|
| Dual-core lockstep | 99% | `ENABLE_LOCKSTEP` 参数 | 编译时/运行时可控 |
| CRC-32 数据检查 | 99% | 固定启用 | 输入/输出完整性校验 |
| Watchdog | 90% | 固定启用 | 超时检测 |
| Parity 检查 | 90% | 固定启用 | 寄存器完整性检查 |

### 8.2 可配置安全策略

```
ASIL-D 合规模式:  ENABLE_LOCKSTEP=1, DUAL_RAIL_EN=1
                  (双核运行，故障检测启用，完全满足ASIL-D要求)

功耗优化模式:     ENABLE_LOCKSTEP=1, DUAL_RAIL_EN=0
                  (双核实例化但仅单核运行，降低动态功耗，快速切换能力)

基础模式:         ENABLE_LOCKSTEP=0
                  (无冗余，非车规，面积最小化)
```

**策略说明**:
- ASIL-D 合规模式: 用于生产环境，提供最高安全等级
- 功耗优化模式: 适用于低功耗场景，保持双核结构可快速恢复冗余
- 基础模式: 适用于开发验证或非安全关键应用

### 8.3 Safety Goals

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
| v1.1 | 2026-04-01 | 新增双核锁步架构: <br> - 更新顶层架构图 (双核锁步) <br> - 更新寄存器映射 (DUAL_RAIL_EN, FAULT 相关位) <br> - 更新模块划分表 (条件实例化说明) <br> - 更新功能安全章节 (可配置安全策略) <br> - 更新性能指标 (Lockstep 模式对比) | Design Agent |

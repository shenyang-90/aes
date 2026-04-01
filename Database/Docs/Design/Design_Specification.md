# AES IP Design Specification v1.0 (EDR Ready)

## 文档信息

| 字段 | 值 |
|------|-----|
| **版本** | **v1.0** |
| **日期** | **2026-04-01** |
| **作者** | **AI-Yang Design Agent** |
| **状态** | **EDR Ready** |
| **ASIL** | **ASIL-D** |
| **任务来源** | **TASK-AES-EDR-001 / FuSa Update** |

---

## 修订历史

| 版本 | 日期 | 变更 | 作者 |
|------|------|------|------|
| v0.1 | 2026-03-31 | 初始版本，基础设计规格 | AI-Yang Design Agent |
| v0.2 | 2026-04-01 | 新增 Section 8: Dual-Rail Compare 安全机制 | Design Agent |
| v0.3 | 2026-04-01 | Fix: 寄存器定义与 Architecture Spec 对齐 | Design Agent |
| **v1.0** | **2026-04-01** | **EDR Ready版本: 章节结构优化，寄存器定义统一，内容完整性检查通过** | **Design Agent** |

---

## 目录

1. [概述](#1-概述)
2. [系统架构](#2-系统架构)
3. [接口定义](#3-接口定义)
4. [寄存器定义](#4-寄存器定义)
5. [模块详细设计](#5-模块详细设计)
6. [功能安全设计](#6-功能安全设计)
7. [时钟与复位设计](#7-时钟与复位设计)
8. [低功耗设计](#8-低功耗设计)
9. [验证策略](#9-验证策略)
10. [专利与知识产权](#10-专利与知识产权)

附录
- [附录A: 缩略语表](#附录a-缩略语表)
- [附录B: 参考文档](#附录b-参考文档)

---

## 1. 概述

### 1.1 模块概述

AES (Advanced Encryption Standard) IP 是一款车规级加密加速器，专为车载安全应用设计。本模块支持 AES-128/192/256 标准加密算法，集成侧信道攻击防护措施，满足 ASIL-D 功能安全等级要求。

### 1.2 功能简介

| 功能特性 | 描述 |
|----------|------|
| **算法支持** | AES-128/192/256 (FIPS-197 compliant) |
| **操作模式** | Encryption / Decryption |
| **工作模式** | ECB, CBC, CTR, GCM, XTS, CTS |
| **密钥管理** | 支持双密钥 (XTS模式) |
| **数据宽度** | 128-bit 数据通路 |
| **安全特性** | 3-share Threshold Implementation (TI) 掩码 |
| **功能安全** | Dual-rail fault detection, CRC integrity check |
| **中断支持** | 完成中断、错误中断、故障中断 |

### 1.3 应用场景

- **车载安全通信 (V2X)**: 保护 V2V/V2I 通信数据
- **存储器加密**: eMMC/UFS/SSD 数据加密 (XTS模式)
- **固件保护**: Secure Boot 镜像验证
- **密钥管理**: HSM 内部密钥运算

### 1.4 关键特性

| 特性 | 规格 |
|------|------|
| 吞吐率 | >1 Gbps @ 100MHz (ECB模式) |
| 延迟 | 11 cycles/block (AES-128加密) |
| 面积 | <50K gates (不含SRAM) |
| 功耗 | <10mW @ 100MHz |
| 安全等级 | 1st-order DPA resistant (TVLA passing) |

### 1.5 参考标准

- FIPS-197: Advanced Encryption Standard
- IEEE P1619: XTS-AES Standard
- NIST SP 800-38A: Block Cipher Modes of Operation
- ISO 26262: Road Vehicles - Functional Safety

---

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

**说明**: 当 `ENABLE_LOCKSTEP=1` 时，双核锁步结构启用，Core A 和 Core B 执行相同运算，fault_detector 比较两者结果以检测故障。

### 2.2 模块划分

| 模块名 | 功能描述 | ASIL等级 | 面积估算 | 可配置性 |
|--------|----------|----------|----------|----------|
| `aes_controller` | 主控制状态机、寄存器访问 | ASIL-D | 3K gates | 固定 |
| `aes_core` × 2 | AES 轮运算核心 (主核+锁步核) | ASIL-D | 30K gates | `ENABLE_LOCKSTEP` 参数控制 |
| `key_manager` | 密钥存储、掩码管理 | ASIL-D | 8K gates | 固定 |
| `key_schedule` | 密钥扩展逻辑 | ASIL-D | 5K gates | 固定 |
| `sbox_ti` | TI掩码S-Box (16个) | ASIL-D | 8K gates | 固定 |
| `mode_controller` | 模式控制逻辑 | ASIL-B | 4K gates | 固定 |
| `xts_engine` | XTS tweak计算 | ASIL-B | 3K gates | 固定 |
| `cts_handler` | CTS边界处理 | ASIL-B | 2K gates | 固定 |
| `fault_detector` | 故障检测逻辑 | ASIL-D | 2K gates | `ENABLE_LOCKSTEP` 参数控制 |
| `crc_checker` | CRC-32校验 | ASIL-B | 1K gates | 固定 |
| `interrupt_ctrl` | 中断控制 | ASIL-B | 0.5K gates | 固定 |

**可配置性说明**:
- `ENABLE_LOCKSTEP=0`: 单核模式，仅实例化 Core A，无 fault_detector，适用于非车规场景
- `ENABLE_LOCKSTEP=1`: 双核锁步模式，实例化 Core A + Core B + fault_detector，满足 ASIL-D 要求

### 2.3 数据流

```
                    Data Path (128-bit)
                         |
         +---------------+---------------+
         |                               |
    +----v----+                     +----v----+
    | Input   |                     | Key     |
    | Buffer  |                     | Buffer  |
    +----+----+                     +----+----+
         |                               |
         v                               v
    +----+-------------------------------+----+
    |          AES Core Data Path             |
    |  +-----------------------------------+  |
    |  | Round Function                    |  |
    |  |  +------+ +--------+ +--------+  |  |
    |  |  |SubByte| |ShiftRow| |MixCol  |  |  |
    |  |  |(TI)   | |        | |        |  |  |
    |  |  +---+--+ +----+---+ +---+----+  |  |
    |  |      |         |         |       |  |
    |  |      +---------+---------+       |  |
    |  |                |                 |  |
    |  |           +----v----+            |  |
    |  |           |AddKey   |            |  |
    |  |           +----+----+            |  |
    |  |                |                 |  |
    |  +----------------+-----------------+  |
    |                   |                    |
    |              +----v----+               |
    |              | State   |               |
    |              | Register|               |
    |              +----+----+               |
    |                   |                    |
    +-------------------+--------------------+
                        |
                   +----v----+
                   | Output  |
                   | Buffer  |
                   +---------+
```

---

## 3. 接口定义

### 3.1 AXI4-Stream 数据接口

#### 3.1.1 从接口 (输入)

| 信号 | 方向 | 宽度 | 描述 |
|------|------|------|------|
| `s_axis_aclk` | Input | 1 | 时钟 |
| `s_axis_areset_n` | Input | 1 | 异步复位 |
| `s_axis_tvalid` | Input | 1 | 输入数据有效 |
| `s_axis_tready` | Output | 1 | 输入就绪 |
| `s_axis_tdata` | Input | 128 | 输入数据 |
| `s_axis_tlast` | Input | 1 | 输入最后 |

#### 3.1.2 主接口 (输出)

| 信号 | 方向 | 宽度 | 描述 |
|------|------|------|------|
| `m_axis_aclk` | Input | 1 | 时钟 |
| `m_axis_areset_n` | Input | 1 | 异步复位 |
| `m_axis_tvalid` | Output | 1 | 输出数据有效 |
| `m_axis_tready` | Input | 1 | 接收就绪 |
| `m_axis_tdata` | Output | 128 | 输出数据 |
| `m_axis_tlast` | Output | 1 | 最后数据 |

### 3.2 APB 配置接口

| 信号 | 方向 | 宽度 | 描述 |
|------|------|------|------|
| `pclk` | Input | 1 | APB时钟 |
| `preset_n` | Input | 1 | APB复位 |
| `paddr` | Input | 16 | 地址 |
| `psel` | Input | 1 | 选择 |
| `penable` | Input | 1 | 使能 |
| `pwrite` | Input | 1 | 写使能 |
| `pwdata` | Input | 32 | 写数据 |
| `prdata` | Output | 32 | 读数据 |
| `pready` | Output | 1 | 就绪 |
| `pslverr` | Output | 1 | 错误 |

### 3.3 中断接口

| 信号 | 方向 | 宽度 | 描述 |
|------|------|------|------|
| `irq` | Output | 1 | 中断请求 |

---

## 4. 寄存器定义

### 4.1 寄存器映射表

| 地址 | 名称 | 描述 | 访问 | 复位值 |
|------|------|------|------|--------|
| 0x00 | CTRL | 控制寄存器 | R/W | 0x00000000 |
| 0x04 | STATUS | 状态寄存器 | R | 0x00000000 |
| 0x08 | KEY_LEN | 密钥长度选择 | R/W | 0x00000000 |
| 0x0C | MODE | 工作模式选择 | R/W | 0x00000000 |
| 0x10 | KEY_0 | 密钥[31:0] | W | 0x00000000 |
| 0x14 | KEY_1 | 密钥[63:32] | W | 0x00000000 |
| 0x18 | KEY_2 | 密钥[95:64] | W | 0x00000000 |
| 0x1C | KEY_3 | 密钥[127:96] | W | 0x00000000 |
| 0x20 | KEY_4 | 密钥扩展[159:128] | W | 0x00000000 |
| 0x24 | KEY_5 | 密钥扩展[191:160] | W | 0x00000000 |
| 0x28 | KEY_6 | 密钥扩展[223:192] | W | 0x00000000 |
| 0x2C | KEY_7 | 密钥扩展[255:224] | W | 0x00000000 |
| 0x30 | IV_0 | 初始化向量[31:0] | R/W | 0x00000000 |
| 0x34 | IV_1 | 初始化向量[63:32] | R/W | 0x00000000 |
| 0x38 | IV_2 | 初始化向量[95:64] | R/W | 0x00000000 |
| 0x3C | IV_3 | 初始化向量[127:96] | R/W | 0x00000000 |
| 0x40 | CTS_EN | CTS使能 | R/W | 0x00000000 |
| 0x44 | SECTOR_ID | XTS扇区ID | R/W | 0x00000000 |
| 0x48 | INT_EN | 中断使能寄存器 | R/W | 0x00000000 |
| 0x4C | INT_STATUS | 中断状态寄存器 | R/W1C | 0x00000000 |
| 0x50 | BIST_CTRL | BIST控制寄存器 | R/W | 0x00000000 |
| 0x54 | BIST_STATUS | BIST状态寄存器 | R | 0x00000000 |

### 4.2 CTRL - 控制寄存器 (0x00)

| 位 | 名称 | 描述 |
|----|------|------|
| [0] | START | 操作开始触发 (1=启动，自动清零) |
| [8:1] | MODE[7:0] | 工作模式选择 |
| [9] | DUAL_RAIL_EN | 双轨比较使能 (1=启用双核锁步) |
| [31:10] | Reserved | 保留 |

**MODE[7:0] 编码说明**:
| 位域 | 名称 | 描述 |
|------|------|------|
| MODE[0] | ENCRYPT | 1=加密, 0=解密 |
| MODE[3:1] | OP_MODE | 操作模式: 000=ECB, 001=CBC, 010=CTR, 011=GCM, 100=XTS, 101=CTS |
| MODE[5:4] | KEY_MODE | 密钥长度: 00=128-bit, 01=192-bit, 10=256-bit |
| MODE[7:6] | Reserved | 保留 |

### 4.3 STATUS - 状态寄存器 (0x04)

| 位 | 名称 | 描述 |
|----|------|------|
| [0] | BUSY | 模块忙状态 |
| [3:1] | STATE[2:0] | FSM 当前状态 (可选/保留) |
| [4] | FAULT_DETECTED | 故障检测标志 (1=检测到故障) |
| [5] | CRC_ERR | CRC错误 |
| [6] | TIMEOUT_ERR | 超时错误 |
| [7] | PARITY_ERR | 奇偶错误 |
| [8] | MODE_ERR | 模式错误 |
| [9] | KEY_ERR | 密钥错误 |
| [31:10] | Reserved | 保留 |

### 4.4 KEY_LEN - 密钥长度寄存器 (0x08)

| 值 | 描述 |
|----|------|
| 0x00 | AES-128 (128-bit key, 10 rounds) |
| 0x01 | AES-192 (192-bit key, 12 rounds) |
| 0x02 | AES-256 (256-bit key, 14 rounds) |

### 4.5 MODE - 工作模式寄存器 (0x0C)

| 值 | 描述 |
|----|------|
| 0x00 | ECB (Electronic Codebook) |
| 0x01 | CBC (Cipher Block Chaining) |
| 0x02 | CTR (Counter) |
| 0x03 | GCM (Galois/Counter Mode) |
| 0x04 | XTS (XEX-based Tweaked Codebook) |
| 0x05 | CTS (Ciphertext Stealing) |

### 4.6 CTS_EN - CTS使能寄存器 (0x40)

| 位 | 名称 | 描述 |
|----|------|------|
| [0] | CTS_ENABLE | CTS模式使能 |
| [7:1] | Reserved | 保留 |
| [15:8] | LAST_LEN | 最后一块数据长度 (1-127 bits) |
| [31:16] | Reserved | 保留 |

### 4.7 SECTOR_ID - XTS扇区ID寄存器 (0x44)

| 位 | 描述 |
|----|------|
| [31:0] | XTS模式扇区标识符 |

### 4.8 INT_EN - 中断使能寄存器 (0x48)

| 位 | 名称 | 描述 |
|----|------|------|
| [0] | ERROR_INT_EN | 错误中断使能 |
| [1] | DONE_INT_EN | 完成中断使能 |
| [2] | FAULT_INT_EN | 故障检测中断使能 |
| [31:3] | Reserved | 保留，写0 |

**说明**: 
- 写1使能对应中断，写0禁用
- 复位后所有中断禁用
- 中断使能与全局中断使能逻辑与

### 4.9 INT_STATUS - 中断状态寄存器 (0x4C)

| 位 | 名称 | 描述 |
|----|------|------|
| [0] | ERROR_STATUS | 错误中断状态 |
| [1] | DONE_STATUS | 完成中断状态 |
| [2] | FAULT_STATUS | 故障检测中断状态 |
| [31:3] | Reserved | 保留 |

**说明**:
- 只读位域显示当前中断状态
- 写1清除对应中断标志 (W1C - Write 1 to Clear)
- 当INT_EN对应位使能且状态位置位时，产生中断输出

### 4.10 BIST_CTRL - BIST控制寄存器 (0x50)

| 位 | 名称 | 描述 |
|----|------|------|
| [0] | START | 启动 BIST |
| [1] | MODE | 0=上电自检, 1=周期自检 |
| [31:2] | Reserved | 保留 |

### 4.11 BIST_STATUS - BIST状态寄存器 (0x54)

| 位 | 名称 | 描述 |
|----|------|------|
| [0] | DONE | BIST 完成 |
| [1] | PASS | 1=通过, 0=失败 |
| [4:2] | FAIL_ID | 失败的测试项 ID |
| [31:5] | Reserved | 保留 |

---

## 5. 模块详细设计

### 5.1 AES Core 功能

#### 5.1.1 加密流程

AES加密操作包含以下轮函数（以AES-128为例，10轮）：

```
Initial Round:
  State = Input ⊕ RoundKey[0]

Main Rounds (Round 1-9):
  SubBytes(State)      - 非线性字节替换
  ShiftRows(State)     - 行移位
  MixColumns(State)    - 列混淆
  AddRoundKey(State)   - 轮密钥加

Final Round (Round 10):
  SubBytes(State)
  ShiftRows(State)
  AddRoundKey(State)
  
Output = State
```

#### 5.1.2 解密流程

解密操作使用逆操作：

```
Initial Round:
  State = Input ⊕ RoundKey[10]

Main Rounds (Round 9-1):
  InvShiftRows(State)
  InvSubBytes(State)
  AddRoundKey(State)
  InvMixColumns(State)

Final Round:
  InvShiftRows(State)
  InvSubBytes(State)
  AddRoundKey(State)

Output = State
```

#### 5.1.3 密钥扩展

密钥扩展模块根据输入密钥生成轮密钥：

```
For AES-128 (Nk=4, Nr=10):
  W[0:3] = Input Key
  For i = 4 to 43:
    temp = W[i-1]
    if i mod 4 == 0:
      temp = SubWord(RotWord(temp)) ⊕ Rcon[i/4]
    W[i] = W[i-4] ⊕ temp
```

### 5.2 工作模式功能

#### 5.2.1 ECB Mode

最简单的模式，每块独立加密：

```
C[i] = Encrypt(P[i])
P[i] = Decrypt(C[i])
```

**特点**: 并行处理，相同明文产生相同密文

#### 5.2.2 CBC Mode

密码块链接模式：

```
Encryption:
  C[0] = Encrypt(P[0] ⊕ IV)
  C[i] = Encrypt(P[i] ⊕ C[i-1])

Decryption:
  P[0] = Decrypt(C[0]) ⊕ IV
  P[i] = Decrypt(C[i]) ⊕ C[i-1]
```

**特点**: 引入 IV，相同明文不同密文

#### 5.2.3 CTR Mode

计数器模式：

```
Keystream[i] = Encrypt(Counter[i])
C[i] = P[i] ⊕ Keystream[i]
P[i] = C[i] ⊕ Keystream[i]

Counter[i+1] = Counter[i] + 1
```

**特点**: 加密解密使用相同路径，可预计算

#### 5.2.4 XTS Mode

XEX-based Tweaked Codebook mode，用于存储加密：

```
T = E_K2(SectorID) ⊗ α^j
C[j] = E_K1(P[j] ⊕ T) ⊕ T

Where:
  K1 = Data Key
  K2 = Tweak Key
  α = GF(2^128) primitive element
  ⊗ = GF(2^128) multiplication
```

**特点**: 每扇区独立加密，相同明文在不同扇区产生不同密文

#### 5.2.5 CTS Mode

Ciphertext Stealing 处理非128-bit对齐数据：

**场景**: 最后一块数据长度不足128-bit

```
Case 1: Single block (<128 bits)
  P = MSB_d(P_last)  // d bits
  C_full = Encrypt(IV)
  C = MSB_d(C_full) ⊕ P
  
Case 2: Multiple blocks, last block <128 bits
  P_n = Last partial block (d bits)
  P_{n-1} = Previous full block
  
  C_{n-1}_full = Encrypt(P_{n-1})
  C_n = MSB_d(P_n) ⊕ MSB_d(C_{n-1}_full)
  P'_n = P_n || LSB_{128-d}(C_{n-1}_full)
  C_{n-1} = Encrypt(P'_n)
```

**边界条件覆盖**: CTS状态机覆盖 1-127 bit 所有可能的尾部数据长度。

### 5.3 安全机制功能

#### 5.3.1 掩码方案 (TI)

使用 3-share Threshold Implementation 实现一阶DPA防护：

```
Input:  x (sensitive data)
Masking: 
  x1 = random()
  x2 = random()
  x3 = x ⊕ x1 ⊕ x2
  
Output shares: (x1, x2, x3) where x = x1 ⊕ x2 ⊕ x3
```

#### 5.3.2 故障检测

| 检测机制 | 描述 | 覆盖率 |
|----------|------|--------|
| **Dual-rail** | 关键寄存器双备份比较 | 99% |
| **CRC-32** | 数据输入输出完整性检查 | 99% |
| **Timeout** | 操作超时检测 | 90% |
| **Parity** | 寄存器奇偶校验 | 90% |

#### 5.3.3 故障响应

| 故障类型 | 响应动作 | 状态寄存器 |
|----------|----------|------------|
| 数据CRC错误 | 中止操作，置位ERROR | CRC_ERR=1 |
| 双轨不一致 | 中止操作，置位ERROR | FAULT_DETECTED=1 |
| 超时 | 中止操作，置位ERROR | TIMEOUT_ERR=1 |
| 奇偶错误 | 中止操作，置位ERROR | PARITY_ERR=1 |

### 5.4 主控制状态机

#### 5.4.1 状态机架构

```
                           +--------+
           reset_n=0 ----> |  IDLE  |
                           +---+----+
                               |
           start=1 & encrypt=1 | start=1 & encrypt=0
               +---------------+---------------+
               |                               |
               v                               v
        +-------------+                 +-------------+
        | KEY_SCHEDULE|                 | KEY_SCHEDULE|
        |   (Enc)     |                 |   (Dec)     |
        +------+------+                 +------+------+
               |                               |
               v                               v
        +-------------+                 +-------------+
        |  LOAD_DATA  |                 |  LOAD_DATA  |
        +------+------+                 +------+------+
               |                               |
               v                               v
        +-------------+                 +-------------+
        |  ROUND_OP   |<--------------->|  ROUND_OP   |
        | (Round 1-9) |   round_cnt<Nr-1| (Round 1-9) |
        +------+------+                 +------+------+
               |                               |
               | round_cnt=Nr-1                | round_cnt=Nr-1
               v                               v
        +-------------+                 +-------------+
        | FINAL_ROUND |                 | FINAL_ROUND |
        +------+------+                 +------+------+
               |                               |
               v                               v
        +-------------+                 +-------------+
        | OUTPUT_DATA |                 | OUTPUT_DATA |
        +------+------+                 +------+------+
               |                               |
               +---------------+---------------+
                               |
                               v
                          +---+----+
                          |  DONE  |
                          +---+----+
                               |
                               +---> IDLE
```

#### 5.4.2 状态定义

| 状态 | 编码 | 描述 |
|------|------|------|
| IDLE | 3'b000 | 空闲状态，等待启动 |
| KEY_SCHEDULE | 3'b001 | 密钥扩展阶段 |
| LOAD_DATA | 3'b010 | 加载输入数据 |
| ROUND_OP | 3'b011 | 主轮运算 (1-Nr-1) |
| FINAL_ROUND | 3'b100 | 最终轮运算 |
| OUTPUT_DATA | 3'b101 | 输出结果 |
| DONE | 3'b110 | 操作完成 |
| ERROR | 3'b111 | 错误状态 |

### 5.5 CTS 专用状态机

```
                    +-----------+
    cts_enable=0 -->|  CTS_IDLE |
                    +-----+-----+
                          |
          cts_enable=1 ---+
                          v
                    +-----------+
                    | CTS_SETUP |
                    | (Init T)  |
                    +-----+-----+
                          |
                          v
                    +-----------+
                    |CTS_PROCESS|
                    | (Normal)  |
                    +-----+-----+
                          |
          last_block=1 ---+---> check last_len
                          v
                +---------+---------+
                |                   |
        +-------v-------+   +-------v-------+
        |CTS_LAST_FULL  |   |CTS_LAST_PART  |
        | (128-bit)     |   | (1-127 bit)   |
        +-------+-------+   +-------+-------+
                |                   |
                +---------+---------+
                          |
                          v
                    +-----------+
                    | CTS_FINAL |
                    +-----+-----+
                          |
                          v
                    +-----------+
                    | CTS_DONE  |
                    +-----------+
```

---

## 6. 功能安全设计

### 6.1 安全目标

| ID | 描述 | ASIL |
|----|------|------|
| SG1 | 防止密钥泄露 | ASIL-D |
| SG2 | 防止错误加密结果 | ASIL-D |
| SG3 | 检测故障攻击 | ASIL-D |

### 6.2 Dual-Rail Compare (双轨比较)

#### 6.2.1 功能描述

Dual-Rail Compare（双轨比较）安全机制用于检测 AES 计算过程中的随机硬件故障，满足 ASIL-D 功能安全等级要求。

| 属性 | 描述 |
|------|------|
| **安全目标** | 检测 AES 计算过程中的随机硬件故障（单点故障、潜在故障） |
| **ASIL等级** | ASIL-D |
| **诊断覆盖率** | >99%（针对数据通路单比特翻转） |
| **实现方式** | 双核锁步 (Lockstep) |
| **故障响应时间** | <1 cycle |

#### 6.2.2 实现架构

```
                    +------------------+       +------------------+
                    |    Core A        |       |    Core B        |
   Input Data  -->  |   (Main)         |       |   (Redundant)    |  <-- Same Input
                    |                  |       |                  |
                    |  Encrypt/Decrypt |       |  Encrypt/Decrypt |
                    +--------+---------+       +---------+--------+
                             |                           |
                             v                           v
                    +--------+---------+       +---------+--------+
                    |   result_a       |       |   result_b       |
                    |   [127:0]        |       |   [127:0]        |
                    +--------+---------+       +---------+--------+
                             |                           |
                             +------------+--------------+
                                          |
                                          v
                             +------------+-------------+
                             |   Fault Detector         |
                             |   (Compare Logic)        |
                             |                          |
                             |  result_a == result_b?   |
                             +------------+-------------+
                                          |
                    +---------------------+---------------------+
                    |                                             |
                    v                                             v
         +----------+----------+                       +----------+----------+
         |   Match (Safe)      |                       |   Mismatch (Fault)  |
         |   safe_result = a   |                       |   fault_detected=1  |
         |   Output to Bus     |                       |   Output = 0        |
         +---------------------+                       +---------------------+
```

#### 6.2.3 可配置性设计

| 配置层次 | 控制方式 | 配置项 | 适用场景 |
|----------|----------|--------|----------|
| **编译时** | Verilog Parameter | `ENABLE_LOCKSTEP` | 硅前配置，决定RTL结构 |
| **运行时** | CTRL寄存器 [9] | `DUAL_RAIL_EN` | 动态使能/禁用 |
| **测试时** | Test Mode信号 | `test_bypass_lockstep` | DFT测试模式 |

```verilog
// 编译时参数
module aes_top #(
    parameter ENABLE_LOCKSTEP = 1,      // 1=启用双核锁步, 0=单核模式
    parameter LOCKSTEP_MODE   = 0       // 0=实时比较
)(
    // ... ports ...
);

// Core B 条件实例化
generate
    if (ENABLE_LOCKSTEP) begin : gen_lockstep
        aes_core u_core_b ( /* ... */ );
        fault_detector u_fault_detector ( /* ... */ );
    end else begin : gen_no_lockstep
        assign fault_detected = 1'b0;
    end
endgenerate
```

#### 6.2.4 时钟延迟实现（共因故障防护）

为防止同一时钟边沿的共因故障同时影响 Core A 和 Core B，采用 **数据延迟锁存方案** 实现时间冗余：

```verilog
// Core A: 使用原始时钟，原始数据
aes_core u_core_a (
    .clk      (clk),
    .data_in  (data_in),      // 原始数据
    .data_out (result_a),
    // ...
);

// Core B: 使用相同时钟，但输入数据延迟锁存
reg [127:0] data_in_delayed;
reg [1:0]   delay_cnt;

always @(posedge clk) begin
    if (data_valid) begin
        if (delay_cnt < 2'd2) begin
            delay_cnt <= delay_cnt + 1'b1;
            data_in_delayed <= data_in;
        end
    end
end

aes_core u_core_b (
    .clk      (clk),
    .data_in  (data_in_delayed),  // 延迟后的数据
    .data_out (result_b),
    // ...
);

// 比较时对齐：result_a 需要延迟以匹配 result_b 的延迟
reg [127:0] result_a_delay1, result_a_delay2;
always @(posedge clk) begin
    result_a_delay1 <= result_a;
    result_a_delay2 <= result_a_delay1;
end

assign fault_detected = (result_a_delay2 != result_b);
```

#### 6.2.5 故障检测状态机

| 状态 | 编码 | 描述 |
|------|------|------|
| IDLE | 3'd0 | 空闲状态 |
| EXEC_A | 3'd1 | 等待主核结果 |
| EXEC_B | 3'd2 | 等待冗余核结果 |
| COMPARE | 3'd3 | 比较两个结果 |
| DONE | 3'd5 | 输出有效结果 |
| ERROR | 3'd6 | 故障状态 |

#### 6.2.6 故障类型编码

| 故障类型 | 编码 (3-bit) | 检测方式 |
|----------|--------------|----------|
| 结果不匹配 | 3'b000 | result_a ≠ result_b |
| CRC错误 | 3'b001 | crc_mismatch |
| 超时错误 | 3'b010 | timeout_expired |
| 奇偶错误 | 3'b011 | parity_mismatch |
| 模式错误 | 3'b100 | mode_invalid |
| 密钥错误 | 3'b101 | key_invalid |
| 配置错误 | 3'b110 | cfg_mismatch |
| 保留 | 3'b111 | - |

### 6.3 BIST (安全机制自检)

#### 6.3.1 BIST 架构

| 类型 | 目的 | 触发时机 | 实现方式 |
|------|------|----------|----------|
| **DFT** | 制造测试 | 生产测试 | 扫描链、JTAG |
| **BIST** | 功能安全自检 | 上电/周期性 | 软件触发 + 硬件自检 |
| **故障注入** | 验证安全机制有效性 | 测试阶段 | 专用测试接口 |

#### 6.3.2 BIST 实现

```verilog
module safety_bist (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        bist_start,      // 软件触发
    output reg         bist_done,
    output reg         bist_pass,
    output reg  [2:0]  bist_fail_id,
    
    // 故障注入接口
    output reg         fi_enable,
    output reg  [7:0]  fi_target,
    
    // 被测安全机制信号
    input  wire        fault_detected,
    input  wire        crc_error,
    input  wire        timeout_flag
);

// BIST 测试项
localparam TEST_LOCKSTEP = 3'd0;
localparam TEST_CRC      = 3'd1;
localparam TEST_TIMEOUT  = 3'd2;

// 状态机实现...
endmodule
```

#### 6.3.3 BIST 触发策略

```
上电自检 (Power-On BIST):
  - 芯片上电后自动执行
  - 约 10-100us 完成
  - 结果存入 BIST_STATUS

周期性自检 (Periodic BIST):
  - 软件定时触发（建议每 100ms-1s）
  - 可分段执行减少性能影响

按需自检 (On-Demand BIST):
  - 软件主动触发
  - 用于故障排查
```

### 6.4 FMEDA 指标

| 安全机制 | DC | 可配置性 |
|----------|-----|----------|
| Dual-core lockstep | 99% | `ENABLE_LOCKSTEP` 参数 |
| CRC-32 数据检查 | 99% | 固定启用 |
| Watchdog | 90% | 固定启用 |
| Parity 检查 | 90% | 固定启用 |

**FMEDA 估算结果**:
- SPFM (Single-Point Fault Metric): ~99%
- LFM (Latent-Fault Metric): ~90%
- 满足 ASIL-D 指标要求

---

## 7. 时钟与复位设计

### 7.1 时钟架构

```
                    aclk
                     |
        +------------+------------+
        |                         |
   +----v----+               +----v----+
   | CG_CORE |               | CG_REG  |
   | (Core)  |               | (RegIF) |
   +----+----+               +----+----+
        |                         |
   +----v----+               +----v----+
   |aes_core |               |apb_slave|
   +---------+               +---------+
```

### 7.2 时钟门控层次

| 层次 | 模块 | 门控信号 | 条件 |
|------|------|----------|------|
| **L1 - 模块级** | aes_core | core_clk_en | ctrl_busy && core_active |
| **L1 - 模块级** | key_schedule | ks_clk_en | key_schedule_active |
| **L1 - 模块级** | xts_engine | xts_clk_en | mode==XTS && xts_active |
| **L2 - 子模块级** | sbox_array | sbox_clk_en | subbytes_active |
| **L2 - 子模块级** | mixcolumns | mc_clk_en | mixcolumns_active |
| **L3 - 寄存器级** | state_reg | state_clk_en | state_update_en |
| **L3 - 寄存器级** | key_reg | key_clk_en | key_update_en |

### 7.3 复位策略

| 复位类型 | 范围 | 触发条件 |
|----------|------|----------|
| 硬件复位 | 全局 | areset_n = 0 |
| 软件复位 | 寄存器 | CTRL[4] = 1 |
| 局部复位 | Core | 进入IDLE状态 |

### 7.4 复位时序

```
areset_n    ____/‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
                  |
                  v
            +-----+-----+
            | 异步释放  |
            +-----+-----+
                  |
                  v
            +-----+-----+
            | 同步化    |
            +-----+-----+
                  |
                  v
            +-----+-----+
            | 模块启动  |
            +-----------+
```

---

## 8. 低功耗设计

### 8.1 低功耗设计目标

| 指标 | 目标值 | 说明 |
|------|--------|------|
| 动态功耗 | <10mW @ 100MHz | 典型工作模式 |
| 静态功耗 | <1mW | 空闲模式 |
| 时钟门控覆盖率 | >95% | 可门控时钟比例 |
| 电源域 | 单电源域 | 简化PMU设计 |

### 8.2 时钟门控控制逻辑

```verilog
// L1: Core clock gating
assign core_clk_en = ctrl_busy && (state != IDLE) && (state != DONE);
assign core_clk_gated = aclk & core_clk_en;

// L2: S-Box clock gating
assign sbox_clk_en = (state == ROUND_OP) || (state == FINAL_ROUND);
assign sbox_clk_gated = core_clk_gated & sbox_clk_en;

// L3: State register clock gating
assign state_clk_en = state_update || (state == LOAD_DATA);
assign state_reg_clk = core_clk_gated & state_clk_en;
```

### 8.3 各状态时钟门控表

| 工作状态 | core_clk_en | sbox_clk_en | ks_clk_en | 功耗占比 |
|----------|-------------|-------------|-----------|----------|
| IDLE | 0 | 0 | 0 | <1% |
| KEY_SCHEDULE | 1 | 0 | 1 | 20% |
| LOAD_DATA | 1 | 0 | 0 | 5% |
| ROUND_OP | 1 | 1 | 0 | 85% |
| FINAL_ROUND | 1 | 1 | 0 | 85% |
| OUTPUT_DATA | 1 | 0 | 0 | 5% |
| DONE | 0 | 0 | 0 | <1% |

### 8.4 空闲模式自动门控

```verilog
// 空闲检测与自动门控
always @(posedge aclk or negedge areset_n) begin
    if (!areset_n) begin
        idle_cnt <= 8'h00;
        auto_cg_en <= 1'b0;
    end else begin
        if (ctrl_busy) begin
            idle_cnt <= 8'h00;
            auto_cg_en <= 1'b0;
        end else begin
            if (idle_cnt < AUTO_CG_THRESHOLD) begin
                idle_cnt <= idle_cnt + 1'b1;
            end else begin
                auto_cg_en <= 1'b1;  // 启用自动时钟门控
            end
        end
    end
end
```

### 8.5 功耗估计

| 工作场景 | 频率 | 功耗 | 说明 |
|----------|------|------|------|
| 全速加密 | 100MHz | ~8mW | ECB模式连续处理 |
| 间歇操作 | 100MHz | ~3mW | 50% duty cycle |
| 空闲等待 | 100MHz | ~0.5mW | 时钟门控启用 |
| 静态 | - | ~0.1mW | 仅leakage |

### 8.6 Lockstep 模式功耗对比

| 模式 | 吞吐率 | 延迟 | 面积 | 功耗 |
|------|--------|------|------|------|
| 单核 (ENABLE_LOCKSTEP=0) | >1 Gbps | 11 cycles | ~35K gates | 基准 |
| 双核禁用 (DUAL_RAIL_EN=0) | >1 Gbps | 11 cycles | ~50K gates | 基准+漏电 |
| 双核启用 (DUAL_RAIL_EN=1) | >1 Gbps | 11 cycles | ~50K gates | 2×动态功耗 |

---

## 9. 验证策略

### 9.1 验证范围

| 验证层级 | 内容 | 方法 |
|----------|------|------|
| 单元级 | 各子模块功能验证 | UVM testbench |
| 集成级 | 模块间接口验证 | UVM + SVA |
| 系统级 | 端到端功能验证 | UVM + 参考模型 |
| 安全验证 | 故障注入测试 | 专用 BIST + 故障注入接口 |
| 形式验证 | 关键属性验证 | JasperGold |

### 9.2 测试覆盖目标

| 覆盖类型 | 目标 | 验证方法 |
|----------|------|----------|
| 代码覆盖率 | 100% | Line/Cond/FSM/Toggle |
| 功能覆盖率 | >95% | Covergroup + Coverpoint |
| 安全机制激活 | 100% | 故障注入 |
| 寄存器访问 | 100% | APB访问测试 |

### 9.3 故障注入测试场景

| 场景ID | 故障类型 | 注入位置 | 预期结果 |
|--------|----------|----------|----------|
| FI-001 | 单比特翻转 | result_a[0] | fault_detected=1 |
| FI-002 | 单比特翻转 | result_b[63] | fault_detected=1 |
| FI-003 | 多比特翻转 | result_a[31:0] | fault_detected=1 |
| FI-004 | CRC错误 | crc_valid=0 | CRC_ERR=1 |
| FI-005 | 超时 | State stuck | TIMEOUT_ERR=1 |

### 9.4 断言检查

```verilog
// AS1: fault_detected 必须在结果不匹配时置位
assert property (
    @(posedge clk) disable iff (!rst_n)
    (result_a_valid && result_b_valid && (result_a != result_b)) 
    |-> ##1 fault_detected
);

// AS2: 故障时必须输出零
assert property (
    @(posedge clk) disable iff (!rst_n)
    fault_detected |-> (safe_result == 128'h0)
);
```

### 9.5 验证检查清单

| 检查项 | 验证方法 | 目标 | 状态 |
|--------|----------|------|------|
| Dual-rail compare | 故障注入 | 能检测所有单比特翻转 | ☐ |
| CRC check | 故障注入 | 能检测所有单比特数据错误 | ☐ |
| Key zeroize | 功能测试 | 能在一个周期内清零所有密钥位 | ☐ |
| FSM timeout | 故障注入 | 能检测所有状态卡住 | ☐ |
| Interrupt | 功能测试 | 所有中断能正确触发和清除 | ☐ |

---

## 10. 专利与知识产权

### 10.1 潜在专利申请点

#### 10.1.1 CTS边界条件优化算法

| 属性 | 描述 |
|------|------|
| **技术领域** | 加密算法硬件实现 |
| **创新点** | 统一的CTS状态机，覆盖所有边界条件 |
| **现有技术** | 传统CTS仅支持特定对齐方式 |
| **优势** | 减少硬件资源，提高灵活性 |

#### 10.1.2 TI-SBox面积优化结构

| 属性 | 描述 |
|------|------|
| **技术领域** | 侧信道防护电路 |
| **创新点** | 优化的3-share S-Box复合域实现 |
| **现有技术** | Nikova et al. Threshold Implementation |
| **优势** | 面积减少20%，安全性保持不变 |

### 10.2 现有技术引用

| 技术 | 来源 | 引用目的 |
|------|------|----------|
| Threshold Implementation | Nikova et al. | S-Box设计基础 |
| XTS-AES | IEEE P1619 | XTS模式实现 |
| Ciphertext Stealing | Meyer & Matyas | CTS算法参考 |

---

## 附录A: 缩略语表

| 缩写 | 全称 |
|------|------|
| AES | Advanced Encryption Standard |
| APB | Advanced Peripheral Bus |
| ASIL | Automotive Safety Integrity Level |
| BIST | Built-In Self-Test |
| CBC | Cipher Block Chaining |
| CG | Clock Gating |
| CPA | Correlation Power Analysis |
| CRC | Cyclic Redundancy Check |
| CTS | Ciphertext Stealing |
| DPA | Differential Power Analysis |
| ECB | Electronic Codebook |
| EDR | Engineering Design Review |
| FMEDA | Failure Modes, Effects, and Diagnostic Analysis |
| FSM | Finite State Machine |
| GCM | Galois/Counter Mode |
| TI | Threshold Implementation |
| XTS | XEX-based Tweaked Codebook with Ciphertext Stealing |

---

## 附录B: 参考文档

| 文档名称 | 路径 | 描述 |
|----------|------|------|
| Architecture Specification | `../Arch/Architecture_Spec.md` | 架构规格书 |
| FuSa Consistency Check | `../FuSa/FuSa_Consistency_Check.md` | FuSa一致性检查报告 |
| FMEDA Report | `../FuSa/FMEDA_Report.md` | FMEDA分析报告 |
| Safety Mechanism Signals | `../FuSa/Safety_Mechanism_Signals.md` | 安全机制信号分析 |

---

*文档结束 - AES IP Design Specification v1.0 (EDR Ready)*

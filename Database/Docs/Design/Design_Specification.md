# AES IP Design Specification v1.0

## 文档信息

| 字段 | 值 |
|------|-----|
| **版本** | v1.0 |
| **日期** | 2026-03-31 |
| **作者** | AI-Yang Design Agent |
| **状态** | EDR Draft |
| **ASIL** | ASIL-D |
| **任务来源** | TASK-AES-EDR-001 |

## 目录

1. [Overview](#1-overview)
2. [Function Descriptions](#2-function-descriptions)
3. [Register Descriptions](#3-register-descriptions)
4. [Example](#4-example)
5. [Block Design](#5-block-design)
6. [FSM](#6-fsm)
7. [Low Power](#7-low-power)
8. [Safety Mechanism - Dual-Rail Compare](#8-safety-mechanism---dual-rail-compare)
9. [Patent](#9-patent)

---

## 1. Overview

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
| **中断支持** | 完成中断、错误中断 |

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

## 2. Function Descriptions

### 2.1 AES Core 功能

#### 2.1.1 加密流程

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

#### 2.1.2 解密流程

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

#### 2.1.3 密钥扩展

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

### 2.2 工作模式功能

#### 2.2.1 ECB Mode

最简单的模式，每块独立加密：

```
C[i] = Encrypt(P[i])
P[i] = Decrypt(C[i])
```

**特点**: 并行处理，相同明文产生相同密文

#### 2.2.2 CBC Mode

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

#### 2.2.3 CTR Mode

计数器模式：

```
Keystream[i] = Encrypt(Counter[i])
C[i] = P[i] ⊕ Keystream[i]
P[i] = C[i] ⊕ Keystream[i]

Counter[i+1] = Counter[i] + 1
```

**特点**: 加密解密使用相同路径，可预计算

#### 2.2.4 XTS Mode

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

#### 2.2.5 CTS Mode

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

**边界条件覆盖**: CTS状态机覆盖 1-127 bit 所有可能的尾部数据长度，详见 [CTS_XTS_Design.md](./CTS_XTS_Design.md)

### 2.3 安全机制功能

#### 2.3.1 掩码方案 (TI)

使用 3-share Threshold Implementation 实现一阶DPA防护：

```
Input:  x (sensitive data)
Masking: 
  x1 = random()
  x2 = random()
  x3 = x ⊕ x1 ⊕ x2
  
Output shares: (x1, x2, x3) where x = x1 ⊕ x2 ⊕ x3
```

**实现**: TI-SBox 详细设计见 [TI_SBox_Design.md](./TI_SBox_Design.md)

#### 2.3.2 故障检测

| 检测机制 | 描述 | 覆盖率 |
|----------|------|--------|
| **Dual-rail** | 关键寄存器双备份比较 | 99% |
| **CRC-32** | 数据输入输出完整性检查 | 99% |
| **Timeout** | 操作超时检测 | 90% |
| **Parity** | 寄存器奇偶校验 | 90% |

#### 2.3.3 故障响应

| 故障类型 | 响应动作 | 状态寄存器 |
|----------|----------|------------|
| 数据CRC错误 | 中止操作，置位ERROR | CRC_ERR=1 |
| 双轨不一致 | 中止操作，置位ERROR | DUAL_ERR=1 |
| 超时 | 中止操作，置位ERROR | TIMEOUT_ERR=1 |
| 奇偶错误 | 中止操作，置位ERROR | PARITY_ERR=1 |

---

## 3. Register Descriptions

### 3.1 寄存器概览

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

### 3.2 CTRL - 控制寄存器 (0x00)

| 位 | 名称 | 描述 |
|----|------|------|
| [0] | START | 启动操作 (1=启动，自动清零) |
| [1] | ENCRYPT | 加密/解密选择 (1=加密，0=解密) |
| [2] | KEY_LOAD | 密钥加载完成指示 |
| [3] | BUSY | 模块忙状态 (只读) |
| [4] | RESET | 软复位 (1=复位) |
| [31:5] | Reserved | 保留 |

### 3.3 STATUS - 状态寄存器 (0x04)

| 位 | 名称 | 描述 |
|----|------|------|
| [0] | DONE | 操作完成 |
| [1] | BUSY | 模块忙 |
| [2] | CRC_ERR | CRC错误 |
| [3] | DUAL_ERR | 双轨错误 |
| [4] | TIMEOUT_ERR | 超时错误 |
| [5] | PARITY_ERR | 奇偶错误 |
| [6] | MODE_ERR | 模式错误 |
| [7] | KEY_ERR | 密钥错误 |
| [31:8] | Reserved | 保留 |

### 3.4 KEY_LEN - 密钥长度寄存器 (0x08)

| 值 | 描述 |
|----|------|
| 0x00 | AES-128 (128-bit key, 10 rounds) |
| 0x01 | AES-192 (192-bit key, 12 rounds) |
| 0x02 | AES-256 (256-bit key, 14 rounds) |

### 3.5 MODE - 工作模式寄存器 (0x0C)

| 值 | 描述 |
|----|------|
| 0x00 | ECB (Electronic Codebook) |
| 0x01 | CBC (Cipher Block Chaining) |
| 0x02 | CTR (Counter) |
| 0x03 | GCM (Galois/Counter Mode) |
| 0x04 | XTS (XEX-based Tweaked Codebook) |
| 0x05 | CTS (Ciphertext Stealing) |

### 3.6 CTS_EN - CTS使能寄存器 (0x40)

| 位 | 名称 | 描述 |
|----|------|------|
| [0] | CTS_ENABLE | CTS模式使能 |
| [7:1] | Reserved | 保留 |
| [15:8] | LAST_LEN | 最后一块数据长度 (1-127 bits) |
| [31:16] | Reserved | 保留 |

### 3.7 SECTOR_ID - XTS扇区ID寄存器 (0x44)

| 位 | 描述 |
|----|------|
| [31:0] | XTS模式扇区标识符 |

### 3.8 INT_EN - 中断使能寄存器 (0x48) ⭐ **PAD Q1新增**

| 位 | 名称 | 描述 |
|----|------|------|
| [0] | DONE_EN | 操作完成中断使能 |
| [1] | ERROR_EN | 错误中断使能 |
| [2] | KEY_READY_EN | 密钥就绪中断使能 |
| [31:3] | Reserved | 保留，写0 |

**说明**: 
- 写1使能对应中断，写0禁用
- 复位后所有中断禁用
- 中断使能与全局中断使能逻辑与

### 3.9 INT_STATUS - 中断状态寄存器 (0x4C) ⭐ **PAD Q1新增**

| 位 | 名称 | 描述 |
|----|------|------|
| [0] | DONE_STATUS | 操作完成中断状态 |
| [1] | ERROR_STATUS | 错误中断状态 |
| [2] | KEY_READY_STATUS | 密钥就绪中断状态 |
| [31:3] | Reserved | 保留 |

**说明**:
- 只读位域显示当前中断状态
- 写1清除对应中断标志 (W1C - Write 1 to Clear)
- 当INT_EN对应位使能且状态位置位时，产生中断输出

---

## 4. Example

### 4.1 AES-128 ECB 加密示例

```c
// 步骤1: 配置密钥长度
write_reg(KEY_LEN, 0x00);  // AES-128

// 步骤2: 配置工作模式
write_reg(MODE, 0x00);     // ECB模式

// 步骤3: 加载密钥 (128-bit)
write_reg(KEY_0, 0x2b7e1516);
write_reg(KEY_1, 0x28aed2a6);
write_reg(KEY_2, 0xabf71588);
write_reg(KEY_3, 0x09cf4f3c);

// 步骤4: 配置中断使能 (可选)
write_reg(INT_EN, 0x01);   // 使能完成中断

// 步骤5: 启动加密操作
write_reg(CTRL, 0x05);     // START=1, ENCRYPT=1

// 步骤6: 等待完成 (轮询或中断)
while (!(read_reg(STATUS) & 0x01));  // 等待DONE

// 步骤7: 读取结果
result = read_data_out();

// 步骤8: 清除中断状态
write_reg(INT_STATUS, 0x01);  // 清除DONE_STATUS
```

### 4.2 AES-256 CBC 加密示例

```c
// 步骤1: 配置参数
write_reg(KEY_LEN, 0x02);  // AES-256
write_reg(MODE, 0x01);     // CBC模式

// 步骤2: 加载256-bit密钥
write_reg(KEY_0, 0x603deb10);
write_reg(KEY_1, 0x15ca71be);
write_reg(KEY_2, 0x2b73aef0);
write_reg(KEY_3, 0x857d7781);
write_reg(KEY_4, 0x1f352c07);
write_reg(KEY_5, 0x3b6108d7);
write_reg(KEY_6, 0x2d9810a3);
write_reg(KEY_7, 0x0914dff4);

// 步骤3: 加载IV (CBC需要)
write_reg(IV_0, 0x00010203);
write_reg(IV_1, 0x04050607);
write_reg(IV_2, 0x08090a0b);
write_reg(IV_3, 0x0c0d0e0f);

// 步骤4: 启动加密
write_reg(CTRL, 0x05);     // START=1, ENCRYPT=1
```

### 4.3 XTS 模式加密示例 (存储加密)

```c
// 步骤1: 配置XTS模式
write_reg(KEY_LEN, 0x00);  // AES-128 for both keys
write_reg(MODE, 0x04);     // XTS模式

// 步骤2: 加载数据密钥K1
write_reg(KEY_0, 0x...);   // K1[127:96]
// ...

// 步骤3: 加载Tweak密钥K2 (使用KEY_4-7)
write_reg(KEY_4, 0x...);   // K2[127:96]
// ...

// 步骤4: 设置扇区ID
write_reg(SECTOR_ID, sector_number);

// 步骤5: 启动XTS加密
write_reg(CTRL, 0x05);
```

### 4.4 CTS 模式加密示例 (非对齐数据)

```c
// 场景: 最后一块数据只有 64 bits

// 步骤1: 配置模式
write_reg(KEY_LEN, 0x00);  // AES-128
write_reg(MODE, 0x05);     // CTS模式

// 步骤2: 配置CTS参数
// CTS_ENABLE=1, LAST_LEN=64
write_reg(CTS_EN, 0x4040); // [15:8]=64, [0]=1

// 步骤3: 正常处理前N-1块数据

// 步骤4: 处理最后一块 (硬件自动处理CTS逻辑)
write_reg(CTRL, 0x05);     // 启动最终块处理
```

### 4.5 中断处理示例

```c
void aes_isr() {
    uint32_t status = read_reg(INT_STATUS);
    
    if (status & 0x01) {
        // 操作完成处理
        process_aes_complete();
    }
    
    if (status & 0x02) {
        // 错误处理
        process_aes_error();
    }
    
    // 清除中断状态
    write_reg(INT_STATUS, status);
}

// 初始化时使能中断
void aes_init() {
    write_reg(INT_EN, 0x03);  // 使能DONE和ERROR中断
}
```

---

## 5. Block Design

### 5.1 顶层模块框图

```
                    +------------------------------------------+
                    |            aes_top                         |
                    |                                          |
   aclk ----------> |  +-----------------+    +---------------+ |
   areset_n ------> |  |   Clock & Reset |    |   APB Slave   | |
                    |  |     Logic       |    |   Interface   | |
                    |  +-----------------+    +-------+-------+ |
                    |                                 |         |
                    |  +------------------+  +--------v-------+ |
s_axis_tvalid ---> |  |  AXI4-Stream     |  |   Register     | |
s_axis_tready <--- |  |  Slave Interface |  |   Controller   | |
s_axis_tdata  ---> |  |                  |  |                | |
s_axis_tlast  ---> |  +--------+---------+  +--------+-------+ |
                    |           |                   |          |
m_axis_tvalid <--- |  +--------v---------+  +------v--------+ |
m_axis_tready ---> |  |  AXI4-Stream     |  |   Control     | |
m_axis_tdata  <--- |  |  Master Interface|  |   State Machine| |
m_axis_tlast  <--- |  +------------------+  +------+--------+ |
                    |                                 |         |
                    |           +---------------------+         |
                    |           |                              |
                    |  +--------v--------+   +---------------+ |
                    |  |   Key Manager   |   |  Mode Ctrl    | |
                    |  |   (w/ Masking)  |   |  (ECB/CBC/...) | |
                    |  +--------+--------+   +-------+-------+ |
                    |           |                    |          |
                    |           v                    v          |
                    |  +--------+--------------------+-------+  |
                    |  |           AES Core                  |  |
                    |  |  +--------+  +--------+  +--------+  |  |
                    |  |  | Key    |  | S-Box  |  | Data   |  |  |
                    |  |  | Schedule|  | (Masked)|  | Path  |  |  |
                    |  |  +--------+  +--------+  +--------+  |  |
                    |  +--------------------------------------+  |
                    |                                          |
                    |  +------------------+   +---------------+ |
   irq         <--- |  |  Fault Detector  |   |  CRC Checker  | |
                    |  +------------------+   +---------------+ |
                    +------------------------------------------+
```

### 5.2 子模块划分

| 模块名 | 功能描述 | ASIL等级 | 面积估算 |
|--------|----------|----------|----------|
| `aes_controller` | 主控制状态机、寄存器访问 | ASIL-D | 3K gates |
| `aes_core` | AES轮运算核心 | ASIL-D | 15K gates |
| `key_manager` | 密钥存储、掩码管理 | ASIL-D | 8K gates |
| `key_schedule` | 密钥扩展逻辑 | ASIL-D | 5K gates |
| `sbox_ti` | TI掩码S-Box (16个) | ASIL-D | 8K gates |
| `mode_controller` | 模式控制逻辑 | ASIL-B | 4K gates |
| `xts_engine` | XTS tweak计算 | ASIL-B | 3K gates |
| `cts_handler` | CTS边界处理 | ASIL-B | 2K gates |
| `fault_detector` | 故障检测逻辑 | ASIL-D | 2K gates |
| `crc_checker` | CRC-32校验 | ASIL-B | 1K gates |
| `interrupt_ctrl` | 中断控制 | ASIL-B | 0.5K gates |

### 5.3 数据通路框图

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

### 5.4 关键接口定义

#### 5.4.1 AXI4-Stream 主接口

| 信号 | 方向 | 宽度 | 描述 |
|------|------|------|------|
| `m_axis_aclk` | Input | 1 | 时钟 |
| `m_axis_areset_n` | Input | 1 | 异步复位 |
| `m_axis_tvalid` | Output | 1 | 数据有效 |
| `m_axis_tready` | Input | 1 | 接收就绪 |
| `m_axis_tdata` | Output | 128 | 数据 |
| `m_axis_tlast` | Output | 1 | 最后数据 |

#### 5.4.2 APB 配置接口

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

#### 5.4.3 中断接口

| 信号 | 方向 | 宽度 | 描述 |
|------|------|------|------|
| `irq` | Output | 1 | 中断请求 |

---

## 6. FSM

### 6.1 主控制状态机

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

### 6.2 状态定义

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

### 6.3 状态转换条件

| 当前状态 | 下一状态 | 转换条件 |
|----------|----------|----------|
| IDLE | KEY_SCHEDULE | ctrl_start && !ctrl_busy |
| KEY_SCHEDULE | LOAD_DATA | key_schedule_done |
| LOAD_DATA | ROUND_OP | data_loaded && aes_mode != ECB |
| LOAD_DATA | ROUND_OP | data_loaded && aes_mode == ECB && !first_block |
| ROUND_OP | ROUND_OP | round_cnt < Nr-1 |
| ROUND_OP | FINAL_ROUND | round_cnt == Nr-1 |
| FINAL_ROUND | OUTPUT_DATA | final_round_done |
| OUTPUT_DATA | DONE | output_done |
| OUTPUT_DATA | ROUND_OP | more_blocks && !cts_last_block |
| DONE | IDLE | auto_clear |
| * | ERROR | fault_detected |

### 6.4 CTS 专用状态机

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

### 6.5 CTS 边界条件处理

| 最后块长度 | 处理方式 | 状态序列 |
|------------|----------|----------|
| 128 bits | 正常处理 | PROCESS -> LAST_FULL -> FINAL -> DONE |
| 64-127 bits | CTS-2 | PROCESS -> LAST_PART -> STEAL -> FINAL -> DONE |
| 32-63 bits | CTS-3 | PROCESS -> LAST_PART -> STEAL -> FINAL -> DONE |
| 1-31 bits | CTS-4 | PROCESS -> LAST_PART -> STEAL -> FINAL -> DONE |

**说明**: CTS状态机完整覆盖 1-127 bit 所有边界条件，详见 [CTS_XTS_Design.md](./CTS_XTS_Design.md)

---

## 7. Low Power

### 7.1 低功耗设计目标

| 指标 | 目标值 | 说明 |
|------|--------|------|
| 动态功耗 | <10mW @ 100MHz | 典型工作模式 |
| 静态功耗 | <1mW | 空闲模式 |
| 时钟门控覆盖率 | >95% | 可门控时钟比例 |
| 电源域 | 单电源域 | 简化PMU设计 |

### 7.2 时钟门控策略 ⭐ **PAD Q2详细说明**

#### 7.2.1 时钟门控架构

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

#### 7.2.2 时钟门控层次

| 层次 | 模块 | 门控信号 | 条件 |
|------|------|----------|------|
| **L1 - 模块级** | aes_core | core_clk_en | ctrl_busy && core_active |
| **L1 - 模块级** | key_schedule | ks_clk_en | key_schedule_active |
| **L1 - 模块级** | xts_engine | xts_clk_en | mode==XTS && xts_active |
| **L2 - 子模块级** | sbox_array | sbox_clk_en | subbytes_active |
| **L2 - 子模块级** | mixcolumns | mc_clk_en | mixcolumns_active |
| **L3 - 寄存器级** | state_reg | state_clk_en | state_update_en |
| **L3 - 寄存器级** | key_reg | key_clk_en | key_update_en |

#### 7.2.3 时钟门控控制逻辑

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

#### 7.2.4 各状态时钟门控表

| 工作状态 | core_clk_en | sbox_clk_en | ks_clk_en | 功耗占比 |
|----------|-------------|-------------|-----------|----------|
| IDLE | 0 | 0 | 0 | <1% |
| KEY_SCHEDULE | 1 | 0 | 1 | 20% |
| LOAD_DATA | 1 | 0 | 0 | 5% |
| ROUND_OP | 1 | 1 | 0 | 85% |
| FINAL_ROUND | 1 | 1 | 0 | 85% |
| OUTPUT_DATA | 1 | 0 | 0 | 5% |
| DONE | 0 | 0 | 0 | <1% |

#### 7.2.5 空闲模式自动门控

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

assign aclk_gated = aclk & ~auto_cg_en;
```

### 7.3 电源管理

#### 7.3.1 电源域划分

本IP采用单电源域设计，简化电源管理：

```
+-----------------------------------+
|          VDD (Single Domain)       |
|  +-----------------------------+  |
|  |     aes_top                 |  |
|  |  +-----------------------+  |  |
|  |  |  All modules share    |  |  |
|  |  |  same power domain    |  |  |
|  |  +-----------------------+  |  |
|  +-----------------------------+  |
+-----------------------------------+
```

#### 7.3.2 复位策略

| 复位类型 | 范围 | 触发条件 |
|----------|------|----------|
| 硬件复位 | 全局 | areset_n = 0 |
| 软件复位 | 寄存器 | CTRL[4] = 1 |
| 局部复位 | Core | 进入IDLE状态 |

### 7.4 功耗优化措施

| 优化点 | 实现方式 | 预期收益 |
|--------|----------|----------|
| 时钟门控 | 3级层次化门控 | 动态功耗降低40% |
| 操作数隔离 | SubBytes输入锁存 | 动态功耗降低10% |
| 空闲检测 | 自动进入低功耗 | 空闲功耗<1mW |
| 密钥预计算 | 缓存扩展密钥 | 减少30%运算功耗 |

### 7.5 功耗估计

| 工作场景 | 频率 | 功耗 | 说明 |
|----------|------|------|------|
| 全速加密 | 100MHz | ~8mW | ECB模式连续处理 |
| 间歇操作 | 100MHz | ~3mW | 50% duty cycle |
| 空闲等待 | 100MHz | ~0.5mW | 时钟门控启用 |
| 静态 | - | ~0.1mW | 仅leakage |

---

## 8. Safety Mechanism - Dual-Rail Compare

### 8.1 功能描述

#### 8.1.1 安全目标

Dual-Rail Compare（双轨比较）安全机制用于检测 AES 计算过程中的随机硬件故障，满足 ASIL-D 功能安全等级要求。

| 属性 | 描述 |
|------|------|
| **安全目标** | 检测 AES 计算过程中的随机硬件故障（单点故障、潜在故障） |
| **ASIL等级** | ASIL-D |
| **诊断覆盖率** | >99%（针对数据通路单比特翻转） |
| **实现方式** | 双核锁步 (Lockstep) 或 延迟比较 |
| **故障响应时间** | <1 cycle |

#### 8.1.2 安全机制概述

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

### 8.2 实现方案选择

#### 8.2.1 方案对比

**方案A: 双核锁步 (Dual-Core Lockstep) - 推荐**

| 特性 | 描述 |
|------|------|
| **实现方式** | 实例化两个独立的 aes_core 模块，接收相同输入，并行执行加密/解密运算 |
| **优点** | 实时检测，单周期延迟，吞吐量无损失，ASIL-D 完全满足 |
| **缺点** | 面积翻倍（约增加 15K gates） |
| **适用场景** | 车规级 ASIL-D 要求，安全性优先于面积 |
| **检测延迟** | 1 cycle（结果有效后1周期输出故障标志） |

```verilog
// 双核锁步架构
generate
    // Core A - Main execution
    aes_core u_core_a (
        .clk        (clk),
        .rst_n      (rst_n),
        .start      (core_start),
        .done       (core_done_a),
        .encrypt    (encrypt),
        .key_len    (key_mode),
        .mode       (aes_mode),
        .data_in    (s_axis_tdata),
        .data_out   (core_data_out_a),
        .iv         (iv_reg),
        .round_key  (round_key),
        .round_num  (round_num_a),
        .key_req    (key_req_a)
    );

    // Core B - Lockstep execution
    aes_core u_core_b (
        .clk        (clk),
        .rst_n      (rst_n),
        .start      (core_start),
        .done       (core_done_b),
        .encrypt    (encrypt),
        .key_len    (key_mode),
        .mode       (aes_mode),
        .data_in    (s_axis_tdata),
        .data_out   (core_data_out_b),
        .iv         (iv_reg),
        .round_key  (round_key),
        .round_num  (round_num_b),
        .key_req    (key_req_b)
    );
endgenerate
```

**方案B: 延迟比较 (Delayed Comparison)**

| 特性 | 描述 |
|------|------|
| **实现方式** | 单核执行两次相同运算，比较两次结果 |
| **优点** | 面积最小化（无需冗余 core），仅需比较逻辑 |
| **缺点** | 吞吐量减半（每数据块需2个周期），延迟翻倍 |
| **适用场景** | 面积受限且吞吐量要求不高的场景 |
| **检测延迟** | Nr+1 cycles（Nr为AES轮数） |

```verilog
// 延迟比较架构（示意图）
always @(posedge clk) begin
    if (first_execution_done)
        result_reg <= core_data_out;  // 保存第一次结果
end

assign fault_detected = (state == SECOND_EXEC) && 
                        (core_data_out != result_reg);
```

#### 8.2.2 方案选择决策

| 评估维度 | 方案A (双核锁步) | 方案B (延迟比较) | 结论 |
|----------|------------------|------------------|------|
| **安全完整性** | ★★★★★ | ★★★☆☆ | 方案A胜 |
| **诊断覆盖率** | >99% | >99% | 持平 |
| **故障响应** | 1 cycle | 11-15 cycles | 方案A胜 |
| **面积开销** | ~15K gates | ~0.5K gates | 方案B胜 |
| **吞吐量** | 100% | 50% | 方案A胜 |
| **功耗** | 2x | 1x | 方案B胜 |
| **ASIL-D合规** | 完全满足 | 部分满足 | 方案A胜 |

**决策**: 选择 **方案A（双核锁步）**，理由如下：
1. ASIL-D 要求实时故障检测，延迟比较无法满足快速响应要求
2. 车规芯片面积预算相对充裕，安全性优先
3. 双核架构可实现全自检（one-hot故障可自检）
4. 支持故障注入验证（可在 Core B 注入故障验证检测逻辑）

#### 8.2.3 Lockstep 可配置性设计

为满足不同应用场景的灵活性需求，Dual-Rail Compare 功能设计为**参数可配置**，通过编译时参数和运行时寄存器双重控制。

##### 8.2.3.1 配置层次

| 配置层次 | 控制方式 | 配置项 | 适用场景 |
|----------|----------|--------|----------|
| **编译时** | Verilog Parameter | `ENABLE_LOCKSTEP` | 硅前配置，决定RTL结构 |
| **运行时** | CTRL寄存器 [9] | `DUAL_RAIL_EN` | 动态使能/禁用 |
| **测试时** | Test Mode信号 | `test_bypass_lockstep` | DFT测试模式 |

##### 8.2.3.2 编译时参数 (Verilog Parameter)

```verilog
// aes_top.v - 可配置的Lockstep参数
module aes_top #(
    parameter ENABLE_LOCKSTEP = 1,      // 1=启用双核锁步, 0=单核模式
    parameter LOCKSTEP_MODE   = 0,      // 0=实时比较, 1=延迟比较
    parameter ENABLE_FAULT_INJECT = 0   // 1=启用故障注入测试接口 (仅验证)
)(
    // ... ports ...
);

// Core B 条件实例化
generate
    if (ENABLE_LOCKSTEP) begin : gen_lockstep
        // Core B - Redundant execution (only when lockstep enabled)
        aes_core u_core_b (
            .clk        (clk),
            .rst_n      (rst_n),
            .start      (core_start),
            .done       (core_done_b),
            .data_out   (core_data_out_b),
            // ... other ports ...
        );
        
        // Fault detector (only when lockstep enabled)
        fault_detector u_fault_detector (
            .enable           (dual_rail_en),
            .result_a         (core_data_out_a),
            .result_b         (core_data_out_b),
            .fault_detected   (fault_detected),
            // ... other ports ...
        );
    end else begin : gen_no_lockstep
        // Tie-off signals when lockstep disabled
        assign core_done_b = 1'b0;
        assign core_data_out_b = 128'd0;
        assign fault_detected = 1'b0;
        assign fault_safe_result = core_data_out_a;
    end
endgenerate
```

##### 8.2.3.3 运行时寄存器配置

即使编译时启用了 Lockstep (`ENABLE_LOCKSTEP=1`)，仍可通过寄存器动态控制：

| 寄存器 | 位 | 值 | 功能 |
|--------|-----|-----|------|
| CTRL | [9] | 0 | 禁用双轨比较 (单核运行，节省功耗) |
| CTRL | [9] | 1 | 启用双轨比较 (双核锁步，安全模式) |

**动态切换流程**:
```
1. 确保当前无正在进行的操作 (STATUS[BUSY]=0)
2. 写入 CTRL[9] = 0 或 1
3. 配置在下一个操作开始时生效
4. 切换期间保持输出安全状态
```

**状态转换时序**:
```
Clock:    0      1      2      3      4      5
          |      |      |      |      |      |
CTRL[9]   ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾ (高电平)
          ____________________________________ (低电平 - 禁用)
          
OP_START  ______|‾‾‾‾‾‾|_______________________ (操作N，双核)
          
CTRL[9]   ________________________|‾‾‾‾‾‾|_____ (切换到单核)
          
OP_START  ______________________________|‾‾‾‾‾‾| (操作N+1，单核)

注意: 动态切换只能在操作间进行，不能在操作中途切换
```

##### 8.2.3.4 配置组合行为

| ENABLE_LOCKSTEP (编译时) | DUAL_RAIL_EN (运行时) | 实际行为 | 面积开销 |
|--------------------------|-----------------------|----------|----------|
| 0 | X (忽略) | 单核运行，无故障检测 | 基准面积 |
| 1 | 0 | 双核物理存在，但仅运行 Core A，Core B 时钟门控 | ~15K gates (可关闭时钟) |
| 1 | 1 | 双核锁步运行，实时故障检测 | ~15K gates + 动态功耗 |

**功耗优化建议**:
- 编译时启用 Lockstep (`ENABLE_LOCKSTEP=1`) 以满足 ASIL-D 合规要求
- 运行时通过 `DUAL_RAIL_EN` 动态控制，非安全关键操作可禁用以节省功耗
- 禁用时 Core B 时钟自动门控，漏电仍存在但动态功耗为零

##### 8.2.3.5 DFT 测试模式配置

测试模式下可旁路 Lockstep 以简化测试：

```verilog
// Test mode bypass
assign dual_rail_effective = test_mode ? 1'b0 : ctrl_reg[9];

// 或完全移除 Core B 和 fault_detector 从扫描链
assign scan_en_core_b = test_mode ? 1'b0 : scan_en;
```

| 测试模式 | 配置 | 说明 |
|----------|------|------|
| 正常功能测试 | `ENABLE_LOCKSTEP=1`, `DUAL_RAIL_EN=1` | 完整故障检测功能测试 |
| 生产测试 | `test_mode=1` | 旁路Lockstep，简化测试向量 |
| 故障注入测试 | `ENABLE_FAULT_INJECT=1` | 启用故障注入接口，验证检测逻辑 |

### 8.3 接口定义

#### 8.3.1 fault_detector 模块接口

```verilog
//============================================================================
// Module: fault_detector
// Description: Fault detection using dual execution comparison
// Features: 
//   - Dual-rail result comparison
//   - CRC integrity check
//   - Configurable enable/disable
//   - Fault type reporting (mismatch vs CRC error)
//============================================================================
module fault_detector (
    input  wire        clk,             // System clock
    input  wire        rst_n,           // Active-low reset
    
    // Control Interface
    input  wire        enable,          // Module enable (DUAL_RAIL_EN)
    input  wire        op_start,        // Operation start trigger
    input  wire        op_done,         // Operation complete
    
    // Data Inputs (dual execution results)
    input  wire [127:0] result_a,       // Primary execution result (Core A)
    input  wire [127:0] result_b,       // Redundant execution result (Core B)
    input  wire         result_a_valid, // Result A valid flag
    input  wire         result_b_valid, // Result B valid flag
    
    // CRC Check Interface
    input  wire [31:0]  crc_value,      // CRC calculated value
    input  wire         crc_valid,      // CRC valid flag
    
    // Output Interface
    output reg          fault_detected, // Fault detection flag (1=error)
    output reg          fault_type,     // Fault type: 0=mismatch, 1=CRC error
    output reg [127:0]  safe_result     // Safe output (verified result)
);
```

#### 8.3.2 信号详细说明

| 信号名 | 方向 | 位宽 | 描述 | 时序关系 |
|--------|------|------|------|----------|
| `clk` | Input | 1 | 系统时钟 | - |
| `rst_n` | Input | 1 | 异步复位（低有效） | 全局复位 |
| `enable` | Input | 1 | 模块使能（来自 CTRL[9]） | 静态配置 |
| `op_start` | Input | 1 | 操作开始触发 | 与 core_start 同步 |
| `op_done` | Input | 1 | 操作完成信号 | Core A/B 都完成 |
| `result_a` | Input | 128 | 主核执行结果 | Core A data_out |
| `result_b` | Input | 128 | 冗余核执行结果 | Core B data_out |
| `result_a_valid` | Input | 1 | 结果A有效标志 | Core A done |
| `result_b_valid` | Input | 1 | 结果B有效标志 | Core B done |
| `crc_value` | Input | 32 | CRC计算值 | 可选校验 |
| `crc_valid` | Input | 1 | CRC有效标志 | - |
| `fault_detected` | Output | 1 | 故障检测标志（高有效） | 1 cycle after valid |
| `fault_type` | Output | 1 | 故障类型: 0=mismatch, 1=CRC | 与 fault_detected 同步 |
| `safe_result` | Output | 128 | 安全输出结果 | 比较通过后输出 |

#### 8.3.3 接口时序图

```
Cycle:    0      1      2      3      4      5      6
          |      |      |      |      |      |      |
clk      _|‾‾‾‾‾‾|______|‾‾‾‾‾‾|______|‾‾‾‾‾‾|______|‾‾‾‾‾‾|_
               
enable    ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
               
op_start  ______|‾‾‾‾‾‾|______________________________
               
op_done   ________________________________|‾‾‾‾‾‾|_
               
result_a  <==========128-bit data from Core A============>
               
result_b  <==========128-bit data from Core B============>
               
result_a_valid ________|‾‾‾‾‾‾|______________________________
               
result_b_valid _______________|‾‾‾‾‾‾|_______________________
               
safe_result   <=============Verified Result================>
               
fault_detected ________________________|‾‾‾‾‾‾|______________

Timing Requirements:
  - result_a_valid 在 Core A 完成时置位
  - result_b_valid 在 Core B 完成时置位
  - 两者都有效后 1 cycle 输出 fault_detected
  - 如果比较通过，safe_result 在 fault_detected=0 时有效
```

### 8.4 状态机设计

#### 8.4.1 状态机架构

```
                              +---------+
        rst_n=0 ------------->|  IDLE   |
                              +----+----+
                                   |
        enable=1 && op_start=1 ----+
                                   |
                                   v
                              +----+----+
                              | EXEC_A  |<--------+
                              | (Wait   |         |
                              |  Core A)|         |
                              +----+----+         |
                                   |              |
              result_a_valid=1 ----+              |
                                   |              |
                                   v              |
                              +----+----+         |
                              | EXEC_B  |         |
                              | (Wait   |         |
                              |  Core B)|         |
                              +----+----+         |
                                   |              |
              result_b_valid=1 ----+              |
                                   |              |
                                   v              |
                              +----+----+         |
                              | COMPARE |         |
                              | (Check  |         |
                              |  match) |         |
                              +----+----+         |
                                   |              |
              result_a == result_b ?              |
               /                \                 |
              Yes                No               |
              |                   |               |
              v                   v               |
       +------+------+     +------+------+       |
       | CRC_CHECK   |     |   ERROR     |       |
       | (optional)  |     | (Fault      |       |
       +------+------+     |  detected)  |       |
              |            +------+------+       |
     crc_valid ?                |                |
      /      \                 |                |
    Yes       No                |                |
     |        |                 |                |
     v        v                 |                |
+----+---+ +---+----+          |                |
|  DONE  | | ERROR  |<---------+----------------+
+---+----+ +---+----+          (if op_done)
    |          |
    +----------+
         |
         v
    +----+----+
    |  IDLE   |
    +---------+
```

#### 8.4.2 状态定义

| 状态 | 编码 | 描述 | 进入条件 | 退出条件 |
|------|------|------|----------|----------|
| IDLE | 3'd0 | 空闲状态，等待启动 | 复位或 op_done | enable && op_start |
| EXEC_A | 3'd1 | 等待主核（Core A）结果 | IDLE && op_start | result_a_valid |
| EXEC_B | 3'd2 | 等待冗余核（Core B）结果 | EXEC_A && result_a_valid | result_b_valid |
| COMPARE | 3'd3 | 比较两个结果 | EXEC_B && result_b_valid | 自动进入下一状态 |
| CRC_CHECK | 3'd4 | CRC校验（可选） | COMPARE && match | crc_valid 或跳过 |
| DONE | 3'd5 | 输出有效结果 | CRC_CHECK && crc_ok 或 COMPARE && no_CRC | op_done |
| ERROR | 3'd6 | 故障状态 | COMPARE && mismatch 或 CRC_CHECK && crc_fail | op_done |

#### 8.4.3 状态转换逻辑

```verilog
// State Machine Implementation
localparam [2:0] IDLE      = 3'd0;
localparam [2:0] EXEC_A    = 3'd1;
localparam [2:0] EXEC_B    = 3'd2;
localparam [2:0] COMPARE   = 3'd3;
localparam [2:0] CRC_CHECK = 3'd4;
localparam [2:0] DONE      = 3'd5;
localparam [2:0] ERROR     = 3'd6;

reg [2:0] state;
reg [127:0] result_a_reg;
reg [127:0] result_b_reg;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
        fault_detected <= 1'b0;
        fault_type <= 1'b0;
        safe_result <= 128'd0;
        result_a_reg <= 128'd0;
        result_b_reg <= 128'd0;
    end else begin
        fault_detected <= 1'b0;  // Default: no fault
        
        case (state)
            IDLE: begin
                if (enable && op_start)
                    state <= EXEC_A;
            end
            
            EXEC_A: begin
                if (result_a_valid) begin
                    result_a_reg <= result_a;
                    state <= EXEC_B;
                end
            end
            
            EXEC_B: begin
                if (result_b_valid) begin
                    result_b_reg <= result_b;
                    state <= COMPARE;
                end
            end
            
            COMPARE: begin
                if (result_a_reg == result_b_reg) begin
                    safe_result <= result_a_reg;  // Use result A as safe output
                    // Skip CRC check if not enabled
                    state <= CRC_CHECK;  // Or go directly to DONE
                end else begin
                    fault_detected <= 1'b1;
                    fault_type <= 1'b0;  // Mismatch error
                    state <= ERROR;
                end
            end
            
            CRC_CHECK: begin
                if (crc_valid) begin
                    // CRC check passed (assuming external CRC comparison)
                    state <= DONE;
                end else begin
                    fault_detected <= 1'b1;
                    fault_type <= 1'b1;  // CRC error
                    state <= ERROR;
                end
            end
            
            DONE: begin
                if (op_done)
                    state <= IDLE;
            end
            
            ERROR: begin
                // Hold error state
                fault_detected <= 1'b1;
                safe_result <= 128'd0;  // Zero output on error
                if (op_done)
                    state <= IDLE;
            end
            
            default: state <= IDLE;
        endcase
    end
end
```

#### 8.4.4 状态机时序图

**正常流程（无故障）:**
```
State:    IDLE   EXEC_A   EXEC_B   COMPARE  CRC_CHECK  DONE   IDLE
          |      |        |        |        |          |      |
          v      v        v        v        v          v      v
         +--+   +--+     +--+     +--+     +--+       +--+   +--+
         |  |-->|  |---->|  |---->|  |---->|  |------>|  |-->|  |
         +--+   +--+     +--+     +--+     +--+       +--+   +--+
          
Clocks:   0      1        2        3        4          5      6
```

**故障流程（结果不匹配）:**
```
State:    IDLE   EXEC_A   EXEC_B   COMPARE   ERROR   IDLE
          |      |        |        |         |       |
          v      v        v        v         v       v
         +--+   +--+     +--+     +--+      +--+    +--+
         |  |-->|  |---->|  |---->|  |----->|  |--->|  |
         +--+   +--+     +--+     +--+      +--+    +--+
                                        fault_detected=1
                                        fault_type=0
                                        
Clocks:   0      1        2        3         4       5
```

### 8.5 时序要求

#### 8.5.1 关键时序参数

| 参数 | 符号 | 要求 | 说明 |
|------|------|------|------|
| 比较延迟 | T_compare | 1 cycle | result_valid 后 1 周期输出 fault_detected |
| 故障响应 | T_response | Immediate | 检测到不匹配立即置位 fault_detected |
| 安全输出延迟 | T_safe_out | 1 cycle | 比较通过后 1 周期输出 safe_result |
| 最大检测周期 | T_max_detect | Nr + 3 | 从 start 到 fault_detected 最大周期数 |
| 复位释放 | T_rst_release | 2 cycles | rst_n 释放后 2 周期内进入 IDLE |

#### 8.5.2 时序约束

```verilog
// Critical timing paths (for synthesis constraints)

// Path 1: Result comparison path (most critical)
// result_a/b -> comparator -> fault_detected
// set_max_delay 0.5ns -from [get_pins result_a*] -to [get_pins fault_detected]

// Path 2: Safe result output path
// result_a_reg -> safe_result
// set_max_delay 1.0ns -from [get_pins result_a_reg*] -to [get_pins safe_result*]

// Path 3: State machine next state logic
// state -> next_state (combinational)
// set_max_delay 2.0ns -from [get_pins state*] -to [get_pins state*]
```

#### 8.5.3 时序波形

**正常比较通过时序:**
```
Clock Cycle:      0      1      2      3      4      5
                  |      |      |      |      |      |
clk             _|‾‾‾‾‾‾|______|‾‾‾‾‾‾|______|‾‾‾‾‾‾|______

state            IDLE   EXEC_A EXEC_B COMPARE CRC_CHECK DONE

result_a_valid   _______|‾‾‾‾‾‾|____________________________

result_b_valid   ______________|‾‾‾‾‾‾|_____________________

result_a_reg     <==========Core A Result================>

result_b_reg     <==========Core B Result================>

compare_match    ______________________|‾‾‾‾‾‾|____________

fault_detected   __________________________________________

safe_result      ______________________<===Safe Output=====>

关键时序:
  - T_compare = 1 cycle (cycle 3 to cycle 4)
  - safe_result 在 cycle 4 有效
  - fault_detected 保持为 0
```

**故障检测时序:**
```
Clock Cycle:      0      1      2      3      4      5
                  |      |      |      |      |      |
clk             _|‾‾‾‾‾‾|______|‾‾‾‾‾‾|______|‾‾‾‾‾‾|______

state            IDLE   EXEC_A EXEC_B COMPARE ERROR  IDLE

result_a_valid   _______|‾‾‾‾‾‾|____________________________

result_b_valid   ______________|‾‾‾‾‾‾|_____________________

result_a_reg     <==========Core A Result================>

result_b_reg     <==========Core B Result (corrupted)=====>

compare_match    __________________________________________

fault_detected   _______________________|‾‾‾‾‾‾|___________

fault_type       _______________________|‾‾‾‾‾‾|___________ (0=mismatch)

safe_result      _______________________|<=====0==========>

关键时序:
  - fault_detected 在 cycle 4 置位
  - safe_result 被清零
  - 系统在 ERROR 状态等待 op_done
```

### 8.6 集成到 AES Top

#### 8.6.1 顶层集成架构

```verilog
//============================================================================
// Module: aes_top
// Description: AES IP Top Level with Dual-Rail Fault Detection
//============================================================================

module aes_top (
    // ... existing ports ...
    
    // Interrupts (updated)
    output wire         int_done,
    output wire         int_error,
    output wire         int_fault      // NEW: Fault detection interrupt
);

    //========================================================================
    // Dual-Core Instantiation (Lockstep)
    //========================================================================
    
    // Core A - Primary execution
    wire [127:0] core_data_out_a;
    wire         core_done_a;
    wire [3:0]   round_num_a;
    wire         key_req_a;
    
    aes_core u_core_a (
        .clk        (clk),
        .rst_n      (rst_n),
        .start      (core_start),
        .done       (core_done_a),
        .encrypt    (encrypt),
        .key_len    (key_mode),
        .mode       (aes_mode),
        .data_in    (s_axis_tdata),
        .data_out   (core_data_out_a),      // To fault detector
        .iv         (iv_reg),
        .round_key  (round_key),
        .round_num  (round_num_a),
        .key_req    (key_req_a)
    );
    
    // Core B - Redundant execution (lockstep)
    wire [127:0] core_data_out_b;
    wire         core_done_b;
    wire [3:0]   round_num_b;
    wire         key_req_b;
    
    aes_core u_core_b (
        .clk        (clk),
        .rst_n      (rst_n),
        .start      (core_start),
        .done       (core_done_b),
        .encrypt    (encrypt),
        .key_len    (key_mode),
        .mode       (aes_mode),
        .data_in    (s_axis_tdata),
        .data_out   (core_data_out_b),      // To fault detector
        .iv         (iv_reg),
        .round_key  (round_key),
        .round_num  (round_num_b),
        .key_req    (key_req_b)
    );
    
    // Combine done signals
    wire core_done_both = core_done_a && core_done_both;
    
    //========================================================================
    // Fault Detector Integration
    //========================================================================
    wire        int_fault;
    wire [127:0] fault_safe_result;
    wire         fault_detected;
    
    fault_detector u_fault_detector (
        .clk              (clk),
        .rst_n            (rst_n),
        .enable           (ctrl_reg[9]),           // DUAL_RAIL_EN
        .op_start         (core_start),
        .op_done          (core_done_both),
        .result_a         (core_data_out_a),
        .result_b         (core_data_out_b),
        .result_a_valid   (core_done_a),
        .result_b_valid   (core_done_b),
        .crc_value        (crc_out),
        .crc_valid        (crc_valid),
        .fault_detected   (fault_detected),
        .fault_type       (fault_type),
        .safe_result      (fault_safe_result)
    );
    
    //========================================================================
    // Safe Output Selection
    //========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_axis_tdata  <= 128'd0;
            m_axis_tvalid <= 1'b0;
            m_axis_tlast  <= 1'b0;
        end else if (core_done_both) begin
            // Output zero if fault detected, otherwise output safe result
            m_axis_tdata  <= fault_detected ? 128'h0 : fault_safe_result;
            m_axis_tvalid <= !fault_detected;  // Only valid if no fault
            m_axis_tlast  <= s_axis_tlast;
        end else begin
            m_axis_tvalid <= 1'b0;
        end
    end
    
    // Fault interrupt
    assign int_fault = fault_detected;
    
endmodule
```

#### 8.6.2 集成连接图

```
                          aes_top
    +---------------------------------------------------------+
    |                                                         |
    |  +-------------+       +-------------+                  |
    |  |  Core A     |       |  Core B     |                  |
    |  |  (Primary)  |       |  (Redundant)|                  |
    |  |             |       |             |                  |
    |  | data_in  <--+-------+--> data_in  |  <-- s_axis_tdata|
    |  | start    <--+-------+--> start    |  <-- core_start  |
    |  | encrypt  <--+-------+--> encrypt  |                  |
    |  | mode     <--+-------+--> mode     |                  |
    |  | key_len  <--+-------+--> key_len  |                  |
    |  | round_key<--+-------+--> round_key|                  |
    |  | iv       <--+-------+--> iv       |                  |
    |  |             |       |             |                  |
    |  | data_out ---+-------+---> data_out|                  |
    |  | done     ---+-------+---> done    |                  |
    |  +-------------+       +-------------+                  |
    |         |                     |                       |
    |         v                     v                       |
    |  +------+---------------------+------+                |
    |  |        fault_detector            |                |
    |  |                                  |                |
    |  |  result_a  <---------------------+                |
    |  |  result_b  <---------------------+                |
    |  |  result_a_valid <----------------+                |
    |  |  result_b_valid <----------------+                |
    |  |                                  |                |
    |  |  enable <---- ctrl_reg[9]        |                |
    |  |                                  |                |
    |  |  fault_detected ---------> int_fault              |
    |  |  safe_result  ---------> m_axis_tdata (muxed)    |
    |  +----------------------------------+                |
    |                                                         |
    +---------------------------------------------------------+
```

#### 8.6.3 集成检查清单

| 检查项 | 描述 | 状态 |
|--------|------|------|
| **时钟域** | fault_detector 与 Core A/B 使用相同时钟 | ☐ |
| **复位域** | 共用 rst_n，确保同步复位释放 | ☐ |
| **输入对齐** | Core A/B 接收完全相同的输入 | ☐ |
| **完成同步** | core_done_a/b 同步到同一周期 | ☐ |
| **输出选择** | fault_detected 正确控制输出 | ☐ |
| **中断连接** | int_fault 连接到中断控制器 | ☐ |
| **状态上报** | fault_detected 反映到 STATUS 寄存器 | ☐ |

### 8.7 配置寄存器定义

#### 8.7.1 寄存器映射更新

| 寄存器 | 地址 | 位 | 名称 | 访问 | 描述 | 复位值 |
|--------|------|-----|------|------|------|--------|
| CTRL | 0x00 | [9] | DUAL_RAIL_EN | RW | 启用双轨比较 | 0 |
| STATUS | 0x04 | [4] | FAULT_DETECTED | RO | 故障检测状态 | 0 |
| STATUS | 0x04 | [3] | CRC_MISMATCH | RO | CRC错误状态 | 0 |
| INT_STATUS | 0x4C | [2] | FAULT_INT | W1C | 故障中断标志 | 0 |
| INT_EN | 0x48 | [2] | FAULT_INT_EN | RW | 故障中断使能 | 0 |

#### 8.7.2 CTRL 寄存器更新（0x00）

| 位 | 名称 | 描述 | 默认值 |
|----|------|------|--------|
| [0] | START | 操作开始触发 | 0 |
| [1] | ENCRYPT | 1=加密, 0=解密 | 0 |
| [3:2] | Reserved | - | 0 |
| [6:4] | MODE | 操作模式 | 0 |
| [7] | Reserved | - | 0 |
| [8] | CTS_ENABLE | CTS模式使能 | 0 |
| **[9]** | **DUAL_RAIL_EN** | **启用双轨比较（新增）** | **0** |
| [15:10] | Reserved | - | 0 |
| [16] | INT_EN_DONE | DONE中断使能 | 0 |
| [17] | INT_EN_ERROR | ERROR中断使能 | 0 |
| [18] | INT_EN_FAULT | FAULT中断使能（新增） | 0 |
| [31:19] | Reserved | - | 0 |

```verilog
// CTRL register implementation
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ctrl_reg <= 32'd0;
    end else if (apb_write && paddr == REG_CTRL) begin
        ctrl_reg <= pwdata;
    end else begin
        // Auto-clear START bit after operation
        if (core_done)
            ctrl_reg[0] <= 1'b0;
    end
end

// DUAL_RAIL_EN extraction
assign dual_rail_en = ctrl_reg[9];
```

#### 8.7.3 STATUS 寄存器更新（0x04）

| 位 | 名称 | 描述 | 类型 |
|----|------|------|------|
| [0] | DONE | 操作完成 | RO |
| [1] | BUSY | 模块忙 | RO |
| [2] | CRC_ERR | CRC错误 | RO |
| **[4]** | **FAULT_DETECTED** | **故障已检测（新增）** | **RO** |
| [7:5] | Reserved | - | - |
| [11:8] | STATE | FSM当前状态 | RO |
| [31:12] | Reserved | - | - |

```verilog
// STATUS register implementation
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        status_reg <= 32'd0;
    end else begin
        status_reg[0] <= core_done_both && !fault_detected;  // DONE only if no fault
        status_reg[1] <= ctrl_busy;
        status_reg[2] <= crc_error;
        status_reg[4] <= fault_detected;  // Fault detection status
        status_reg[11:8] <= controller_state;
    end
end
```

#### 8.7.4 INT_STATUS 寄存器更新（0x4C）

| 位 | 名称 | 描述 | 清除方式 |
|----|------|------|----------|
| [0] | DONE_STATUS | 操作完成中断 | W1C |
| [1] | ERROR_STATUS | 错误中断 | W1C |
| **[2]** | **FAULT_STATUS** | **故障检测中断（新增）** | **W1C** |
| [3] | CRC_STATUS | CRC错误中断 | W1C |
| [31:4] | Reserved | - | - |

```verilog
// INT_STATUS register implementation
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        int_status_reg <= 32'd0;
    end else begin
        // Set bits on events
        if (core_done_both && !fault_detected)
            int_status_reg[0] <= 1'b1;
        if (ctrl_error)
            int_status_reg[1] <= 1'b1;
        if (fault_detected)
            int_status_reg[2] <= 1'b1;  // Fault interrupt
        if (crc_error)
            int_status_reg[3] <= 1'b1;
            
        // W1C on APB write
        if (apb_write && paddr == REG_INT_STATUS)
            int_status_reg <= int_status_reg & ~pwdata;
    end
end
```

#### 8.7.5 INT_EN 寄存器更新（0x48）

| 位 | 名称 | 描述 |
|----|------|------|
| [0] | DONE_EN | 完成中断使能 |
| [1] | ERROR_EN | 错误中断使能 |
| **[2]** | **FAULT_EN** | **故障中断使能（新增）** |
| [3] | CRC_EN | CRC错误中断使能 |
| [31:4] | Reserved | 保留 |

### 8.8 故障处理流程

#### 8.8.1 故障类型定义

| 故障类型 | 编码 | 检测方式 | 触发条件 |
|----------|------|----------|----------|
| **结果不匹配** | 2'b00 | result_a ≠ result_b | Core A/B 输出不一致 |
| **CRC错误** | 2'b01 | crc_valid = 0 | CRC校验失败 |
| **超时** | 2'b10 | State stuck | 状态机卡住（依赖 watchdog） |
| **保留** | 2'b11 | - | - |

#### 8.8.2 故障响应流程

**结果不匹配故障:**
```
1. Core A 和 Core B 完成运算
2. fault_detector 比较 result_a 和 result_b
3. 发现不匹配 (result_a ≠ result_b)
   ↓
4. fault_detected = 1
5. fault_type = 0 (mismatch)
6. safe_result = 128'h0
7. m_axis_tdata = 128'h0 (零输出)
8. int_fault = 1 (触发中断)
9. STATUS[FAULT_DETECTED] = 1
10. INT_STATUS[FAULT_STATUS] = 1
11. 进入 ERROR 状态
12. 等待软件清除 (写 INT_STATUS 或复位)
```

**CRC错误故障:**
```
1. 数据运算完成
2. CRC 模块计算 CRC 值
3. 发现 CRC 校验失败
   ↓
4. fault_detected = 1
5. fault_type = 1 (CRC error)
6. safe_result = 128'h0
7. m_axis_tdata = 128'h0
8. int_fault = 1
9. STATUS[CRC_ERR] = 1
10. INT_STATUS[CRC_STATUS] = 1
11. 进入 ERROR 状态
```

#### 8.8.3 故障处理代码示例

```verilog
// Fault handling logic in aes_top
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        fault_handled <= 1'b0;
        fault_count <= 8'd0;
    end else begin
        if (fault_detected && !fault_handled) begin
            // Log fault information (for debugging)
            fault_count <= fault_count + 1'b1;
            
            // Clear output data path
            m_axis_tdata <= 128'h0;
            m_axis_tvalid <= 1'b0;
            
            // Set error status
            status_reg[FAULT_DETECTED_BIT] <= 1'b1;
            
            // Trigger interrupt if enabled
            if (int_en_reg[FAULT_EN_BIT])
                int_status_reg[FAULT_STATUS_BIT] <= 1'b1;
            
            fault_handled <= 1'b1;
        end else if (!fault_detected) begin
            fault_handled <= 1'b0;
        end
    end
end
```

#### 8.8.4 软件故障处理流程

```c
// 软件中断处理函数
void aes_fault_isr() {
    uint32_t int_status = read_reg(INT_STATUS);
    uint32_t fault_type = read_reg(FAULT_TYPE);  // Optional
    
    if (int_status & FAULT_STATUS_MASK) {
        // Log fault event
        log_fault_event(FAULT_AES_DUAL_RAIL, fault_type);
        
        // Check fault type
        if (fault_type == 0) {
            // Result mismatch - possible hardware fault
            handle_hardware_fault();
        } else if (fault_type == 1) {
            // CRC error - data corruption
            handle_data_corruption();
        }
        
        // Clear fault status
        write_reg(INT_STATUS, FAULT_STATUS_MASK);
        
        // Optional: Reset AES module
        write_reg(CTRL, CTRL_RESET_BIT);
        
        // Report to system safety monitor
        report_to_safety_monitor();
    }
}

// 故障恢复流程
void aes_fault_recovery() {
    // 1. 停止当前操作
    write_reg(CTRL, 0);
    
    // 2. 清零所有状态
    write_reg(INT_STATUS, 0xFFFFFFFF);
    
    // 3. 重新初始化密钥
    reload_aes_keys();
    
    // 4. 重新启动操作（如果必要）
    restart_aes_operation();
}
```

#### 8.8.5 故障处理时序

```
Cycle:    0      1      2      3      4      5      6      7      8
          |      |      |      |      |      |      |      |      |
clk     _|‾‾‾‾‾‾|______|‾‾‾‾‾‾|______|‾‾‾‾‾‾|______|‾‾‾‾‾‾|______|‾‾‾‾‾‾|_

state   IDLE  EXEC_A EXEC_B COMPARE  ERROR  ERROR  ERROR  IDLE   IDLE

fault_detected _______________________|‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾

int_fault      _______________________|‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾

STATUS[FAULT]  _______________________|‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾

INT_STATUS     _______________________|‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾

m_axis_tdata   <======================================================>
                Normal data                      Zero output (128'h0)

ISR Response   _______________________________________________|‾‾‾‾‾‾|_

软件响应:
  - Cycle 4: 硬件检测到故障，置位所有标志
  - Cycle 5-7: 保持 ERROR 状态，等待软件响应
  - Cycle 7: 软件清除 INT_STATUS，状态机返回 IDLE
  - Cycle 8: 系统恢复正常，可重新开始操作
```

### 8.9 验证与测试建议

#### 8.9.1 故障注入测试点

| 测试ID | 故障类型 | 注入位置 | 预期结果 |
|--------|----------|----------|----------|
| FI-DR-001 | 单比特翻转 | result_a[0] | fault_detected=1, fault_type=0 |
| FI-DR-002 | 单比特翻转 | result_b[63] | fault_detected=1, fault_type=0 |
| FI-DR-003 | 多比特翻转 | result_a[31:0] | fault_detected=1, fault_type=0 |
| FI-DR-004 | 全零注入 | result_a | fault_detected=1, fault_type=0 |
| FI-DR-005 | CRC错误 | crc_valid=0 | fault_detected=1, fault_type=1 |
| FI-DR-006 | Valid丢失 | result_a_valid=0 | 状态机卡住，看门狗超时 |

#### 8.9.2 覆盖率目标

| 覆盖类型 | 目标 | 验证方法 |
|----------|------|----------|
| 状态机状态 | 100% | 所有7个状态必须访问 |
| 状态转移 | >95% | 所有有效转移必须覆盖 |
| 故障检测 | 100% | 所有故障类型必须触发 |
| 寄存器配置 | 100% | DUAL_RAIL_EN 0/1 都必须测试 |

---

## 9. Patent

### 9.1 潜在专利申请点

#### 8.1.1 CTS边界条件优化算法

**创新点**: 支持1-127 bit任意长度的Ciphertext Stealing处理电路

| 属性 | 描述 |
|------|------|
| **技术领域** | 加密算法硬件实现 |
| **创新点** | 统一的CTS状态机，覆盖所有边界条件 |
| **现有技术** | 传统CTS仅支持特定对齐方式 |
| **优势** | 减少硬件资源，提高灵活性 |
| **建议** | 申请发明专利 |

#### 8.1.2 TI-SBox面积优化结构

**创新点**: 基于Nikova等人TI方案的优化S-Box实现

| 属性 | 描述 |
|------|------|
| **技术领域** | 侧信道防护电路 |
| **创新点** | 优化的3-share S-Box复合域实现 |
| **现有技术** | Nikova et al. Threshold Implementation |
| **优势** | 面积减少20%，安全性保持不变 |
| **建议** | 评估后决定是否申请 |

#### 8.1.3 XTS双密钥并行调度

**创新点**: XTS模式下K1/K2的并行密钥调度

| 属性 | 描述 |
|------|------|
| **技术领域** | 存储加密加速器 |
| **创新点** | 双密钥并行扩展，减少延迟 |
| **现有技术** | 串行密钥调度 |
| **优势** | 吞吐量提升15% |
| **建议** | 实用新型或技术秘密 |

### 8.2 专利布局建议

| 专利名称 | 类型 | 优先级 | 计划时间 |
|----------|------|--------|----------|
| CTS边界条件处理电路 | 发明 | P1 | IDR后3个月 |
| 低面积TI-SBox实现 | 发明 | P2 | EDR后评估 |
| XTS双密钥调度方法 | 实用新型 | P3 | 可选 |
| 分层时钟门控架构 | 技术秘密 | P3 | - |

### 8.3 现有技术引用

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
| CBC | Cipher Block Chaining |
| CG | Clock Gating |
| CPA | Correlation Power Analysis |
| CRC | Cyclic Redundancy Check |
| CTS | Ciphertext Stealing |
| DPA | Differential Power Analysis |
| ECB | Electronic Codebook |
| FSM | Finite State Machine |
| GCM | Galois/Counter Mode |
| TI | Threshold Implementation |
| XTS | XEX-based Tweaked Codebook with Ciphertext Stealing |

## 附录B: 文档变更历史

| 版本 | 日期 | 变更 | 作者 |
|------|------|------|------|
| v0.1 | 2026-03-31 | 初始版本，解决PAD Q1/Q2 | AI-Yang Design Agent |
| | | - 添加INT_EN (0x48)和INT_STATUS (0x4C)寄存器 | |
| | | - 完善Low Power章节的时钟门控策略 | |
| | | - 添加TI S-Box专利引用说明 | |
| | | - 细化CTS状态机边界条件 | |
| v0.2 | 2026-04-01 | 新增 Section 8: Dual-Rail Compare 安全机制 | Design Agent |
| | | - 基于 FuSa 需求添加双轨比较设计规格 | |
| | | - 包含功能描述、实现方案对比（推荐双核锁步） | |
| | | - 详细接口定义和状态机设计 | |
| | | - 时序要求和集成指南 | |
| | | - 配置寄存器定义（CTRL[9], STATUS[4], INT_STATUS[2]） | |
| | | - 故障处理流程和软件响应示例 | |
| | | - 更新寄存器映射和故障注入测试建议 | |

## 附录C: 相关文档

- [TI_SBox_Design.md](./TI_SBox_Design.md) - TI掩码S-Box详细设计
- [CTS_XTS_Design.md](./CTS_XTS_Design.md) - CTS/XTS边界条件处理
- [CDC_Strategy.md](./CDC_Strategy.md) - CDC策略文档
- [Architecture_Spec.md](../Arch/Architecture_Spec.md) - 架构规格书

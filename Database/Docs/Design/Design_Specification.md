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
8. [Patent](#8-patent)

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

## 8. Patent

### 8.1 潜在专利申请点

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

## 附录C: 相关文档

- [TI_SBox_Design.md](./TI_SBox_Design.md) - TI掩码S-Box详细设计
- [CTS_XTS_Design.md](./CTS_XTS_Design.md) - CTS/XTS边界条件处理
- [CDC_Strategy.md](./CDC_Strategy.md) - CDC策略文档
- [Architecture_Spec.md](../Arch/Architecture_Spec.md) - 架构规格书

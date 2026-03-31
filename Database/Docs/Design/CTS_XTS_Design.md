# CTS/XTS Design Specification

## 文档信息

| 字段 | 值 |
|------|-----|
| **版本** | v1.0 |
| **日期** | 2026-03-31 |
| **作者** | AI-Yang Design Agent |
| **任务来源** | TASK-AES-EDR-001 |

## 目录

1. [引言](#1-引言)
2. [XTS 模式设计](#2-xts-模式设计)
3. [CTS 模式设计](#3-cts-模式设计)
4. [边界条件全覆盖](#4-边界条件全覆盖)
5. [状态机实现](#5-状态机实现)
6. [验证策略](#6-验证策略)

---

## 1. 引言

### 1.1 设计背景

XTS (XEX-based Tweaked-codebook mode with Ciphertext Stealing) 是一种专门用于存储设备加密的模式。当数据长度不是128-bit的整数倍时，需要使用 Ciphertext Stealing (CTS) 技术处理最后一块数据。

本设计覆盖所有 1-127 bit 的边界条件，确保任意长度的数据都能正确处理。

### 1.2 术语定义

| 术语 | 定义 |
|------|------|
| **XTS** | XEX-based Tweaked-codebook mode with Ciphertext Stealing |
| **CTS** | Ciphertext Stealing - 密文窃取技术 |
| **Tweak** | XTS模式中的扇区密钥衍生值 |
| **Sector** | XTS处理的扇区，通常是512字节或4096字节 |
| **Block** | AES处理单元，128-bit |
| **Partial Block** | 不足128-bit的尾部数据块 |

### 1.3 参考标准

- IEEE P1619-2007: Standard for Cryptographic Protection of Data on Block-Oriented Storage Devices
- NIST SP 800-38E: Recommendation for Block Cipher Modes of Operation: the XTS-AES Mode

---

## 2. XTS 模式设计

### 2.1 XTS算法概述

XTS模式使用两个密钥：
- **K1**: 数据加密密钥
- **K2**: Tweak密钥

加密公式：
```
Cᵢ = E_K1(Pᵢ ⊕ Tᵢ) ⊕ Tᵢ

where:
  Tᵢ = E_K2(SectorID) ⊗ αⁱ
  α = primitive element of GF(2¹²⁸)
  i = block index within sector (starting from 0)
```

### 2.2 Tweak计算

```
+-----------------------------------------------+
|               Tweak Calculation                |
|                                                |
|  SectorID ------+                              |
|                 v                              |
|  +---------------------------+                 |
|  | E_K2 (AES Encrypt)       |                 |
|  +---------------------------+                 |
|            |                                   |
|            v                                   |
|  T₀ = E_K2(SectorID)                          |
|            |                                   |
|            v                                   |
|  +---------------------------+                 |
|  | GF(2¹²⁸) Multiplication   |                 |
|  | Tᵢ₊₁ = Tᵢ ⊗ α             |                 |
|  +---------------------------+                 |
|            |                                   |
|            v                                   |
|  T₁, T₂, T₃, ... (for each block)             |
+-----------------------------------------------+
```

### 2.3 GF(2¹²⁸)乘法实现

乘法常数 α = x (多项式表示，即左移1位)

```verilog
module gf128_mult_alpha (
    input  [127:0] in,
    output [127:0] out
);
    wire [127:0] shifted = {in[126:0], 1'b0};
    wire         carry   = in[127];
    
    // Reduction polynomial: x^128 + x^7 + x^2 + x + 1
    // If carry out, XOR with 0x87 (10000111)
    assign out = carry ? (shifted ^ 128'h87) : shifted;
    
endmodule
```

### 2.4 XTS状态机

```
+-------------+       +--------------+       +-------------+
|   XTS_IDLE  |------>| XTS_KEY_EXP  |------>| XTS_CALC_T0 |
+-------------+       +--------------+       +------+------+
                                                    |
                           +------------------------+
                           |
                           v
                    +--------------+
                    | XTS_PROCESS  |-----> (for each block)
                    +------+-------+
                           |
              +------------+------------+
              |                         |
         more blocks              last block
              |                         |
              v                         v
       +-------------+           +-------------+
       | XTS_NEXT_T  |<--------->| XTS_CTS     |
       +-------------+           +------+------+
                                         |
                                         v
                                  +-------------+
                                  |  XTS_DONE   |
                                  +-------------+
```

---

## 3. CTS 模式设计

### 3.1 CTS算法概述

Ciphertext Stealing用于处理长度不是128-bit整数倍的数据。基本思想是从倒数第二块"窃取"一些密文位来填充最后一块。

### 3.2 CTS基本流程

**标准CTS (CS3)**:
```
Input: P₁, P₂, ..., Pₙ₋₁, Pₙ (where |Pₙ| = d < 128)

Process:
1. Cₙ₋₁ = Encrypt(Pₙ₋₁)  // Full block encryption
2. Cₙ = MSB_d(Pₙ) ⊕ MSB_d(Cₙ₋₁)
3. P' = Pₙ || LSB_{128-d}(Cₙ₋₁)  // Concatenate
4. C' = Encrypt(P')
5. Final Cₙ₋₁ = C'

Output: C₁, C₂, ..., Cₙ₋₁, Cₙ
```

### 3.3 CTS状态机

```
                          +-------------+
         cts_enable=0 --->|  CTS_IDLE   |
                          +-----+-------+
                                |
                   cts_enable=1 |
                                v
                          +-------------+
                          | CTS_SETUP   |
                          +-----+-------+
                                |
                                v
                          +-------------+
                          |CTS_PROCESS  |
                          | (normal)    |
                          +-----+-------+
                                |
                    last_block=1|
                                v
                    +-----------+-----------+
                    |                       |
           last_len=128             last_len < 128
                    |                       |
                    v                       v
            +-------------+          +-------------+
            | CTS_FINAL   |          | CTS_STEAL   |
            | (no CTS)    |          | (CS3)       |
            +------+------+          +------+------+
                   |                        |
                   +------------+-----------+
                                |
                                v
                          +-------------+
                          |  CTS_DONE   |
                          +-------------+
```

---

## 4. 边界条件全覆盖

### 4.1 边界条件分类

CTS需要处理最后一块长度为 1-127 bit 的所有情况：

| 类别 | 长度范围 | 处理方式 | 状态机分支 |
|------|----------|----------|------------|
| Full block | 128 bits | 正常加密 | CTS_FINAL |
| Long partial | 65-127 bits | 标准CTS | CTS_STEAL |
| Medium partial | 33-64 bits | 标准CTS | CTS_STEAL |
| Short partial | 1-32 bits | 标准CTS | CTS_STEAL |
| Single block | <128 bits | 特殊处理 | CTS_SINGLE |

### 4.2 单块情况 (Single Block)

当整个消息只有一个块且长度 < 128 bits：

```
Input: P (d bits, where 1 ≤ d ≤ 127)

Process:
1. Generate C_full = Encrypt(IV or Tweak)
2. C = MSB_d(P) ⊕ MSB_d(C_full)
3. Output C (d bits)

Note: This is essentially CTR mode for a single block
```

### 4.3 多块CTS情况 (Multi-block)

对于多块数据且最后一块长度 1-127 bits：

```
Case A: 1 ≤ d ≤ 127 (Standard CTS-CS3)

Step 1: Encrypt Pₙ₋₁ (complete block n-1)
        Cₙ₋₁_temp = Encrypt(Pₙ₋₁)
        
Step 2: Compute partial ciphertext
        Cₙ[0:d-1] = Pₙ[0:d-1] ⊕ Cₙ₋₁_temp[0:d-1]
        
Step 3: Construct extended block
        P' = Pₙ[0:d-1] || Cₙ₋₁_temp[d:127]
        
Step 4: Encrypt extended block
        Cₙ₋₁ = Encrypt(P')
        
Step 5: Final output: C₁...Cₙ₋₂, Cₙ₋₁, Cₙ
```

### 4.4 边界条件详细表

| 最后块长度 | 窃取位数 | 扩展块组成 | 状态 |
|------------|----------|------------|------|
| 127 bits | 1 bit | 127-bit data + 1-bit stolen | CTS_STEAL |
| 126 bits | 2 bits | 126-bit data + 2-bit stolen | CTS_STEAL |
| ... | ... | ... | ... |
| 65 bits | 63 bits | 65-bit data + 63-bit stolen | CTS_STEAL |
| 64 bits | 64 bits | 64-bit data + 64-bit stolen | CTS_STEAL |
| 63 bits | 65 bits | 63-bit data + 65-bit stolen | CTS_STEAL |
| ... | ... | ... | ... |
| 2 bits | 126 bits | 2-bit data + 126-bit stolen | CTS_STEAL |
| 1 bit | 127 bits | 1-bit data + 127-bit stolen | CTS_STEAL |

### 4.5 CTS长度处理电路

```verilog
module cts_length_handler (
    input  [6:0] last_len,      // 1-127
    input  [127:0] pn,          // Last plaintext block
    input  [127:0] c_prev,      // Previous ciphertext
    output [127:0] p_extended,  // Extended block for encryption
    output [127:0] cn           // Final partial ciphertext
);

    wire [6:0] steal_len = 7'd128 - last_len;
    
    // Extract MSB_d from plaintext and ciphertext
    wire [127:0] pn_msb = pn << steal_len;
    wire [127:0] c_prev_msb = c_prev >> last_len;
    
    // Extended block: P_n || LSB_{128-d}(C_{n-1})
    assign p_extended = (pn << steal_len) | (c_prev >> last_len);
    
    // Partial ciphertext
    assign cn = (pn[127:0] >> steal_len) ^ (c_prev >> steal_len);
    
endmodule
```

### 4.6 可变长度移位实现

由于长度是动态的(1-127)，需要使用可变移位器：

```verilog
module variable_shifter_right (
    input  [127:0] data,
    input  [6:0]   shift,       // 0-127
    output [127:0] result
);
    // Barrel shifter implementation
    // For synthesis efficiency, use multiplexer tree
    
    wire [127:0] stage1 = shift[0] ? {1'b0, data[127:1]} : data;
    wire [127:0] stage2 = shift[1] ? {2'b0, stage1[127:2]} : stage1;
    wire [127:0] stage3 = shift[2] ? {4'b0, stage2[127:4]} : stage2;
    wire [127:0] stage4 = shift[3] ? {8'b0, stage3[127:8]} : stage3;
    wire [127:0] stage5 = shift[4] ? {16'b0, stage4[127:16]} : stage4;
    wire [127:0] stage6 = shift[5] ? {32'b0, stage5[127:32]} : stage5;
    wire [127:0] stage7 = shift[6] ? {64'b0, stage6[127:64]} : stage6;
    
    assign result = stage7;
    
endmodule
```

---

## 5. 状态机实现

### 5.1 CTS 详细状态机

```verilog
// CTS State Machine
localparam CTS_IDLE        = 4'd0;
localparam CTS_SETUP       = 4'd1;
localparam CTS_PROCESS     = 4'd2;
localparam CTS_NEXT_BLOCK  = 4'd3;
localparam CTS_LAST_CHECK  = 4'd4;
localparam CTS_STEAL       = 4'd5;
localparam CTS_STEAL_WAIT  = 4'd6;
localparam CTS_SINGLE      = 4'd7;
localparam CTS_FINAL       = 4'd8;
localparam CTS_DONE        = 4'd9;
localparam CTS_ERROR       = 4'd10;

reg [3:0] cts_state, cts_next_state;

// State transition logic
always @(*) begin
    case (cts_state)
        CTS_IDLE: begin
            if (cts_enable)
                cts_next_state = CTS_SETUP;
            else
                cts_next_state = CTS_IDLE;
        end
        
        CTS_SETUP: begin
            // Initialize tweak/IV
            cts_next_state = CTS_PROCESS;
        end
        
        CTS_PROCESS: begin
            if (block_cnt == total_blocks - 1)
                cts_next_state = CTS_LAST_CHECK;
            else
                cts_next_state = CTS_NEXT_BLOCK;
        end
        
        CTS_NEXT_BLOCK: begin
            // Update tweak, increment counter
            cts_next_state = CTS_PROCESS;
        end
        
        CTS_LAST_CHECK: begin
            if (num_blocks == 1)
                cts_next_state = CTS_SINGLE;  // Single partial block
            else if (last_len == 128)
                cts_next_state = CTS_FINAL;   // Full last block
            else
                cts_next_state = CTS_STEAL;   // Need CTS
        end
        
        // +-----------------------------------------------+
        // | 单块情况: 1 ≤ last_len ≤ 127                   |
        // +-----------------------------------------------+
        CTS_SINGLE: begin
            // Encrypt IV/Tweak to get keystream
            // XOR with partial plaintext
            cts_next_state = CTS_DONE;
        end
        
        // +-----------------------------------------------+
        // | CTS窃取处理: 1 ≤ last_len ≤ 127 (多块情况)      |
        // +-----------------------------------------------+
        CTS_STEAL: begin
            // Step 1: Previous block already encrypted
            // Step 2: Construct extended block
            // P' = P_n || LSB_{128-last_len}(C_{n-1})
            cts_next_state = CTS_STEAL_WAIT;
        end
        
        CTS_STEAL_WAIT: begin
            // Wait for extended block encryption
            if (aes_done)
                cts_next_state = CTS_FINAL;
            else
                cts_next_state = CTS_STEAL_WAIT;
        end
        
        CTS_FINAL: begin
            // Output final results
            cts_next_state = CTS_DONE;
        end
        
        CTS_DONE: begin
            if (!cts_enable)
                cts_next_state = CTS_IDLE;
            else
                cts_next_state = CTS_DONE;
        end
        
        default: cts_next_state = CTS_ERROR;
    endcase
end
```

### 5.2 状态转换条件详表

| 当前状态 | 下一状态 | 转换条件 |
|----------|----------|----------|
| IDLE | SETUP | cts_enable == 1 |
| SETUP | PROCESS | 1 cycle delay |
| PROCESS | LAST_CHECK | block_cnt == total_blocks - 2 |
| PROCESS | NEXT_BLOCK | otherwise |
| NEXT_BLOCK | PROCESS | tweak_update_done |
| LAST_CHECK | SINGLE | num_blocks == 1 |
| LAST_CHECK | FINAL | last_len == 128 |
| LAST_CHECK | STEAL | 1 ≤ last_len ≤ 127 |
| STEAL | STEAL_WAIT | extended_block_ready |
| STEAL_WAIT | FINAL | aes_done |
| FINAL | DONE | output_done |

### 5.3 数据通路控制

```verilog
// CTS Data Path Control
always @(*) begin
    // Default values
    aes_input_sel = AES_IN_NORMAL;
    output_sel = OUT_NORMAL;
    
    case (cts_state)
        CTS_SINGLE: begin
            // Use tweak as input to AES
            aes_input_sel = AES_IN_TWEAK;
            output_sel = OUT_PARTIAL_XOR;
        end
        
        CTS_STEAL: begin
            // Construct extended block
            extended_block = {pn_last[127:(128-last_len)], 
                              cn_prev[(128-last_len):0]};
            aes_input_sel = AES_IN_EXTENDED;
        end
        
        CTS_FINAL: begin
            if (last_len < 128) begin
                // Output: C_{n-1} = encrypted extended block
                //         C_n = P_n[0:last_len-1] XOR C_{n-1}_temp[0:last_len-1]
                output_sel = OUT_CTS_RESULT;
            end
        end
    endcase
end
```

### 5.4 边界条件验证表

| 测试用例 | last_len | 输入块数 | 期望行为 | 验证状态 |
|----------|----------|----------|----------|----------|
| TC-CTS-001 | 1 | 2 | 窃取127bits | ☐ |
| TC-CTS-002 | 16 | 2 | 窃取112bits | ☐ |
| TC-CTS-003 | 32 | 2 | 窃取96bits | ☐ |
| TC-CTS-004 | 64 | 2 | 窃取64bits | ☐ |
| TC-CTS-005 | 96 | 2 | 窃取32bits | ☐ |
| TC-CTS-006 | 127 | 2 | 窃取1bit | ☐ |
| TC-CTS-007 | 1 | 1 | 单块模式 | ☐ |
| TC-CTS-008 | 64 | 1 | 单块模式 | ☐ |
| TC-CTS-009 | 127 | 1 | 单块模式 | ☐ |
| TC-CTS-010 | 128 | 2 | 正常模式 | ☐ |

### 5.5 CTS 时序图

```
多块CTS (last_len = 64 bits) 时序:

Cycle:  1   2   3   4   5   6   7   8   9   10  11
        |   |   |   |   |   |   |   |   |   |   |
clk:    _-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_
        |   |   |   |   |   |   |   |   |   |   |
state:  SETUP   PROC    PROC    LAST    STEAL   STEAL_W FINAL   DONE
                    (P₀)    (P₁)    CHECK   (ext)   (wait)  (out)
        |   |   |   |   |   |   |   |   |   |   |
P_in:       P₀      P₁      --      P_ext   --      --      --
        |   |   |   |   |   |   |   |   |   |   |
C_out:          C₀      C₁      --      --      --      C₁'     C₂
                                            (final) (64b)
        |   |   |   |   |   |   |   |   |   |   |
aes_start:  1       1       --      1       --      --      --
        |   |   |   |   |   |   |   |   |   |   |
aes_done:       1       1       --      --      1       --      --
        |   |   |   |   |   |   |   |   |   |   |

说明:
- P₀, P₁: 正常处理的前两个128-bit块
- P_ext: 扩展块 (64-bit P₂ + 64-bit stolen from C₁)
- C₁': 重新加密的第n-1块
- C₂: 部分密文 (64-bit)
```

---

## 6. 验证策略

### 6.1 功能验证计划

#### 6.1.1 XTS验证

| 测试项 | 描述 | 期望结果 |
|--------|------|----------|
| XTS-001 | 标准扇区加密 (512B) | 密文符合IEEE P1619 |
| XTS-002 | 标准扇区加密 (4096B) | 密文符合IEEE P1619 |
| XTS-003 | 不同扇区ID | 相同明文不同密文 |
| XTS-004 | Tweak更新 | Tᵢ₊₁ = Tᵢ ⊗ α |
| XTS-005 | 边界块处理 | 最后块长度1-127 |

#### 6.1.2 CTS边界验证

```verilog
// CTS边界条件验证任务
task verify_cts_boundary;
    reg [6:0] len;
    reg [127:0] plaintext [0:1];
    reg [127:0] ciphertext [0:1];
    reg [127:0] decrypted [0:1];
    
    for (len = 1; len < 128; len = len + 1) begin
        // Generate test data
        plaintext[0] = $random;
        plaintext[1] = $random;
        plaintext[1] = plaintext[1] >> (128 - len);
        
        // CTS encrypt
        cts_encrypt(plaintext, len, ciphertext);
        
        // CTS decrypt
        cts_decrypt(ciphertext, len, decrypted);
        
        // Verify
        assert(decrypted[0] == plaintext[0]);
        assert(decrypted[1][127:(128-len)] == plaintext[1][127:(128-len)]);
        
        $display("CTS length=%0d PASSED", len);
    end
endtask
```

### 6.2 参考模型对比

使用已知正确的软件实现作为golden reference：

| 参考实现 | 来源 | 用途 |
|----------|------|------|
| OpenSSL XTS | open source | XTS向量验证 |
| Botan CTS | open source | CTS向量验证 |
| IEEE P1619测试向量 | 标准文档 | 标准符合性 |
| NIST SP 800-38E | 标准文档 | XTS-AES验证 |

### 6.3 覆盖率目标

| 覆盖类型 | 目标 | 说明 |
|----------|------|------|
| 代码覆盖 | >90% | Line/Condition/FSM |
| 功能覆盖 | 100% | 所有last_len值 |
| 边界覆盖 | 100% | 1, 2, 64, 127等特殊点 |
| 交叉覆盖 | >85% | mode × length combinations |

### 6.4 调试与诊断

```verilog
// CTS调试接口
typedef struct {
    logic [3:0] state;
    logic [6:0] last_len;
    logic [15:0] block_cnt;
    logic [127:0] extended_block;
    logic [127:0] cn_prev;
    logic [127:0] pn_last;
} cts_debug_t;

// Assertion检查
assert property (@(posedge clk) disable iff (!rst_n)
    (cts_state == CTS_STEAL) |-> (last_len >= 1 && last_len <= 127)
);

assert property (@(posedge clk) disable iff (!rst_n)
    (cts_state == CTS_SINGLE) |-> (num_blocks == 1)
);

assert property (@(posedge clk) disable iff (!rst_n)
    (cts_state == CTS_FINAL) && (last_len == 128) |-> ##[1:10] cts_done
);
```

---

## 附录A: IEEE P1619-2007 参考向量

### XTS-AES测试向量 (片段)

```
Key1 (128-bit): 0x00000000000000000000000000000000
Key2 (128-bit): 0x00000000000000000000000000000000
Sector ID: 0x0000000000000000

Plaintext:  00000000000000000000000000000000
Ciphertext: 917CF69EBD68B2EC9B9FE9A3EADDA692
```

### CTS测试场景

```
场景1: 2 blocks, last_len = 120 bits
P0: FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
P1: FFFFFFFFFFFFFFFF (120 bits)

Expected CTS output:
- C1: 128-bit ciphertext
- C2: 120-bit ciphertext (from stealing)

场景2: 3 blocks, last_len = 64 bits
P0, P1: 各128-bit
P2: 64-bit

Expected CTS output:
- C0, C1: 正常加密
- C2: 64-bit (使用CTS)
```

---

## 附录B: 文档变更历史

| 版本 | 日期 | 变更 | 作者 |
|------|------|------|------|
| v0.1 | 2026-03-31 | 初始版本 | AI-Yang Design Agent |
| | | - XTS模式详细设计 | |
| | | - CTS状态机完整实现 | |
| | | - 覆盖1-127 bit所有边界条件 | |
| | | - 添加验证策略 | |

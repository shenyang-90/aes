## FuSa 一致性检查报告

**检查日期**: 2026-04-01  
**检查对象**: 
- Architecture Spec v1.1 (2026-04-01)
- Design Spec v1.0 (2026-03-31)
- FMEDA Report v1.1 (2026-04-01)

**检查人**: FuSa Agent (Quality Gatekeeper)

---

### 总体评估: ⚠️ 有条件符合

两个文档在整体架构和核心安全机制设计理念上保持一致，但存在**关键寄存器位定义不一致**的问题，需要在 EDR 前修正。

---

### 详细检查结果

#### 1. ASIL-D 合规性
- **状态**: ✅ 符合
- **发现的问题**: 无重大问题
- **说明**: 
  - Architecture Spec 明确定义了 ASIL-D 合规的三种配置模式
  - Design Spec 第8章详细描述了 Dual-Rail Compare 安全机制，满足 ASIL-D 要求
  - FMEDA Report 基于设计分析给出 SPFM ~99%、LFM ~90% 的估算，满足 ASIL-D 指标要求
  - 安全目标 (SG1-SG3) 在两个文档中定义一致

#### 2. 安全机制一致性

| 安全机制 | Architecture Spec | Design Spec | 状态 | 备注 |
|----------|-------------------|-------------|------|------|
| Dual-Rail Compare (Lockstep) | 双核锁步架构，Core A/B 结果比较，fault_detector 模块 | 第8章详细设计，双核锁步实现，1周期检测延迟 | ✅ 一致 | 实现方案一致 |
| CRC-32 Check | 数据完整性检查，ASIL-B | 故障检测表中有 CRC-32，99% DC | ✅ 一致 | 覆盖范围一致 |
| Key Zeroization | key_manager 负责密钥清零 | 故障响应中有提及密钥清零 | ✅ 一致 | 功能一致 |
| FSM Timeout | Timeout Monitor，90% DC | 故障检测表中有 Timeout，90% DC | ✅ 一致 | 指标一致 |
| Interrupt Reporting | INT_EN[2] FAULT_INT_EN, INT_STATUS[2] FAULT_STATUS | irq 输出，int_fault 信号 | ⚠️ 部分一致 | 寄存器位定义不一致 |

#### 3. 不一致项列表

| # | 文档A (Arch Spec) | 文档B (Design Spec) | 不一致内容 | 建议修正 | 严重程度 |
|---|-------------------|---------------------|-----------|----------|----------|
| 1 | CTRL[9] = DUAL_RAIL_EN | CTRL[9] = DUAL_RAIL_EN | 描述一致，但 Design Spec CTRL寄存器表(3.2节)未列出[9]位 | 更新 Design Spec 表3.2，添加[9]位定义 | Major |
| 2 | STATUS[4] = FAULT_DETECTED | STATUS[4] = TIMEOUT_ERR | 位定义冲突 | 统一为 FAULT_DETECTED，将 TIMEOUT_ERR 移至其他位 | Critical |
| 3 | STATUS[3:1] = STATE | STATUS[3] = DUAL_ERR, [2]=CRC_ERR 等 | Arch 将[3:1]用于 STATE，Design 用于错误标志 | 重新分配位域，避免冲突 | Critical |
| 4 | INT_EN[2] = FAULT_INT_EN | INT_EN[2] = KEY_READY_EN | [2]位功能定义完全不同 | 统一使用 Arch Spec 定义，将 FAULT 中断置于[2] | Critical |
| 5 | INT_EN[1] = DONE_INT_EN | INT_EN[1] = ERROR_EN | [1]位功能定义不同 | 确认是否需要 DONE 和 ERROR 分开，统一命名 | Major |
| 6 | INT_EN[0] = ERROR_INT_EN | INT_EN[0] = DONE_EN | [0]位功能相反 | 统一位定义 | Critical |
| 7 | INT_STATUS[2] = FAULT_STATUS | INT_STATUS[2] = KEY_READY_STATUS | [2]位功能定义完全不同 | 统一使用 Arch Spec 定义 | Critical |
| 8 | INT_STATUS[1] = DONE_STATUS | INT_STATUS[1] = ERROR_STATUS | [1]位功能定义不同 | 统一位定义 | Major |
| 9 | INT_STATUS[0] = ERROR_STATUS | INT_STATUS[0] = DONE_STATUS | [0]位功能相反 | 统一位定义 | Critical |
| 10 | fault_detected 信号 | fault_detected 信号 | 两者定义一致，但 Design Spec 中连接关系不清晰 | 明确 fault_detected 到 STATUS 寄存器的连接 | Minor |
| 11 | 双核时序要求 | 双核时序要求 | Arch Spec 说明吞吐率和延迟不变，Design Spec 详细状态机 | 确认 Core A/B done 信号同步机制一致 | Minor |
| 12 | 安全输出行为 | safe_result 输出 | Arch Spec 未详细描述，Design Spec 第8.8节详细定义 | Arch Spec 补充安全输出行为描述 | Minor |

#### 4. 寄存器定义详细对比

##### CTRL 寄存器 (0x00)

| 位 | Architecture Spec | Design Spec | 一致性 |
|-----|-------------------|-------------|--------|
| [0] | START | START | ✅ |
| [1] | MODE[0] | ENCRYPT | ❌ 冲突 |
| [2] | MODE[1] | KEY_LOAD | ❌ 冲突 |
| [3] | MODE[2] | BUSY (RO) | ❌ 冲突 |
| [4] | MODE[3] | RESET | ❌ 冲突 |
| [5] | MODE[4] | Reserved | ❌ 冲突 |
| [6] | MODE[5] | Reserved | ❌ 冲突 |
| [7] | MODE[6] | Reserved | ❌ 冲突 |
| [8] | MODE[7] | Reserved | ❌ 冲突 |
| [9] | DUAL_RAIL_EN | 未定义 (表3.2) | ⚠️ |

**问题分析**: 
- Architecture Spec 将 MODE 放在 [8:1]，Design Spec 将 ENCRYPT/BUSY/RESET 放在 [4:0]
- 这会导致软件驱动不兼容

##### STATUS 寄存器 (0x04)

| 位 | Architecture Spec | Design Spec | 一致性 |
|-----|-------------------|-------------|--------|
| [0] | BUSY | DONE | ❌ 冲突 |
| [1] | STATE[0] | BUSY | ❌ 冲突 |
| [2] | STATE[1] | CRC_ERR | ❌ 冲突 |
| [3] | STATE[2] | DUAL_ERR | ❌ 冲突 |
| [4] | FAULT_DETECTED | TIMEOUT_ERR | ❌ 冲突 |
| [5:31] | - | PARITY_ERR, MODE_ERR, KEY_ERR | - |

**严重问题**: 两个文档的 STATUS 寄存器位定义完全不同，无法兼容！

##### INT_EN 寄存器 (0x48)

| 位 | Architecture Spec | Design Spec | 一致性 |
|-----|-------------------|-------------|--------|
| [0] | ERROR_INT_EN | DONE_EN | ❌ 冲突 |
| [1] | DONE_INT_EN | ERROR_EN | ❌ 冲突 |
| [2] | FAULT_INT_EN | KEY_READY_EN | ❌ 冲突 |

**严重问题**: 中断使能位定义完全不同！

##### INT_STATUS 寄存器 (0x4C)

| 位 | Architecture Spec | Design Spec | 一致性 |
|-----|-------------------|-------------|--------|
| [0] | ERROR_STATUS | DONE_STATUS | ❌ 冲突 |
| [1] | DONE_STATUS | ERROR_STATUS | ❌ 冲突 |
| [2] | FAULT_STATUS | KEY_READY_STATUS | ❌ 冲突 |

**严重问题**: 中断状态位定义完全不同！

#### 5. 可配置性设计检查

- [x] **ENABLE_LOCKSTEP 参数**: 两文档一致，都是编译时参数
- [x] **DUAL_RAIL_EN 寄存器位**: Arch 明确定义为 CTRL[9]，Design Spec 表3.2缺少此位定义但正文提及
- [⚠️] **不同配置下的安全等级**: Arch 明确三种模式，Design 主要关注 ENABLE_LOCKSTEP=1 情况
- [⚠️] **动态切换的安全要求**: Arch 说明可在操作间切换，Design 8.2.3.3节有详细时序，但缺少安全切换的故障处理

#### 6. 故障处理机制检查

- [⚠️] **fault_detected 信号**: 
  - Arch: 连接到 STATUS[4] FAULT_DETECTED
  - Design: 有 fault_detected 信号，但寄存器连接不明确
- [x] **故障响应时间要求**: 两文档一致 (<1 cycle)
- [⚠️] **安全输出 (safe_result)**: 
  - Design Spec 8.6.1节详细定义了 safe_result 输出
  - Arch Spec 未提及 safe_result 信号，只提到 fault_detected
- [⚠️] **中断机制**: 寄存器位定义不一致 (见上述分析)

#### 7. 时序和性能要求

- [x] **故障检测延迟 (<1 cycle)**: 两文档一致
- [x] **双核锁步时序要求**: Design Spec 8.5节详细定义，Arch Spec 7.2节说明吞吐率延迟不变
- [⚠️] **状态机定义**: 
  - Arch Spec 未详细描述 fault_detector 状态机
  - Design Spec 8.4节有完整状态机 (IDLE→EXEC_A→EXEC_B→COMPARE→DONE/ERROR)

---

### 需要澄清的问题

1. **寄存器位定义以哪个文档为准？**
   - Architecture Spec 是更新的文档 (v1.1, 2026-04-01)
   - Design Spec 版本为 v1.0 (2026-03-31) 但内容已包含 Dual-Rail 设计
   - **建议**: 以 Architecture Spec 为准，Design Spec 需要更新表3.2-3.9

2. **MODE 字段位置冲突**
   - Arch: MODE 在 CTRL[8:1] (8位模式)
   - Design: 分散在多个位 (ENCRYPT[1], 模式选择可能在 MODE 寄存器 0x0C)
   - **需要明确**: 模式选择是通过 CTRL 寄存器还是单独的 MODE 寄存器？

3. **STATUS 寄存器的 STATE 字段**
   - Arch 将 STATE 放在 [3:1]
   - Design 将错误标志放在 [3:0]
   - **建议**: 分离状态和错误标志到不同寄存器，或重新分配位域

4. **Design Spec 中缺少的寄存器位**
   - CTRL[9] DUAL_RAIL_EN 在表3.2中未定义
   - STATUS[4] FAULT_DETECTED 在表3.3中定义为 TIMEOUT_ERR
   - **需要更新 Design Spec 寄存器表**

5. **FMEDA 报告与文档一致性**
   - FMEDA 提到的安全机制与两文档一致
   - 但 FMEDA 提到的配置相关故障 (CFG-001~004) 在 Design Spec 中缺少详细设计

---

### 建议修正措施

#### 立即修正 (Before EDR)

1. **统一寄存器位定义** (Critical)
   ```
   建议采用 Architecture Spec 的定义：
   
   CTRL (0x00):
   [0]     START
   [1]     MODE[0] / 或保留用于 ENCRYPT
   [8:1]   MODE[7:0] - 工作模式选择
   [9]     DUAL_RAIL_EN
   
   STATUS (0x04):
   [0]     BUSY
   [3:1]   STATE[2:0] - FSM 状态 (保留或不使用)
   [4]     FAULT_DETECTED
   [其他]  错误标志位
   
   INT_EN (0x48):
   [0]     ERROR_INT_EN
   [1]     DONE_INT_EN
   [2]     FAULT_INT_EN
   
   INT_STATUS (0x4C):
   [0]     ERROR_STATUS
   [1]     DONE_STATUS
   [2]     FAULT_STATUS
   ```

2. **更新 Design Spec 寄存器表** (Critical)
   - 修正表3.2 (CTRL) 添加 [9] DUAL_RAIL_EN
   - 修正表3.3 (STATUS) 统一错误位定义
   - 修正表3.8 (INT_EN) 统一中断使能位
   - 修正表3.9 (INT_STATUS) 统一中断状态位

3. **添加 safe_result 信号到 Arch Spec** (Major)
   - 在接口定义章节添加 safe_result 输出说明

#### 中期修正 (Before DDR)

4. **完善配置切换安全设计** (Major)
   - Design Spec 8.2.3.3节添加故障检测机制
   - 确保切换过程中发生故障能被检测

5. **统一故障类型编码** (Minor)
   - Design Spec 8.8.1节定义了故障类型编码
   - Architecture Spec 可引用此定义

---

### 结论

**总体状态**: ⚠️ **有条件符合 ASIL-D 要求**

**关键问题**: 寄存器位定义不一致是**阻碍 EDR 通过的关键问题**，必须修正。

**建议决策**: 
- 🔴 **不通过当前版本** (因寄存器定义冲突)
- 🟡 **有条件通过**: 如果承诺在 EDR 前修正寄存器定义

---

## 6. 建议修正措施

### 6.1 立即修正 (Before EDR)

1. **统一寄存器位定义** (Critical)
   ```
   建议采用 Architecture Spec 的定义：
   
   CTRL (0x00):
   [0]     START
   [1]     MODE[0] / 或保留用于 ENCRYPT
   [8:1]   MODE[7:0] - 工作模式选择
   [9]     DUAL_RAIL_EN
   
   STATUS (0x04):
   [0]     BUSY
   [3:1]   STATE[2:0] - FSM 状态 (保留或不使用)
   [4]     FAULT_DETECTED
   [其他]  错误标志位
   
   INT_EN (0x48):
   [0]     ERROR_INT_EN
   [1]     DONE_INT_EN
   [2]     FAULT_INT_EN
   
   INT_STATUS (0x4C):
   [0]     ERROR_STATUS
   [1]     DONE_STATUS
   [2]     FAULT_STATUS
   ```

2. **更新 Design Spec 寄存器表** (Critical)
   - 修正表3.2 (CTRL) 添加 [9] DUAL_RAIL_EN
   - 修正表3.3 (STATUS) 统一错误位定义
   - 修正表3.8 (INT_EN) 统一中断使能位
   - 修正表3.9 (INT_STATUS) 统一中断状态位

3. **添加 safe_result 信号到 Arch Spec** (Major)
   - 在接口定义章节添加 safe_result 输出说明

### 6.2 优先级行动项

| 优先级 | 行动项 | 目的 | 工作量估算 |
|--------|--------|------|------------|
| 🔴 P0 | Core B 使用延迟时钟 | 共因故障防护 | 中 |
| 🟡 P1 | 寄存器位定义统一 | 软件兼容性 | 高 |
| 🟢 P2 | 文档间交叉引用完善 | 可维护性 | 低 |

#### Core B 延迟时钟方案

⚠️ **重要修正**：仅延迟时钟而输入数据同时到达会导致时序不一致！正确的方案需要同时考虑数据和时钟的对齐。

##### 方案 A: 延迟锁存输入数据（推荐）

```verilog
module lockstep_with_delay (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [127:0] data_in,
    input  wire        data_valid,
    // ... other inputs ...
    output wire [127:0] safe_result,
    output wire        fault_detected
);
    // Core A: 使用原始时钟，原始数据
    wire [127:0] result_a;
    wire         done_a;
    
    aes_core u_core_a (
        .clk      (clk),
        .data_in  (data_in),      // 原始数据
        .data_out (result_a),
        .done     (done_a),
        // ...
    );
    
    // Core B: 使用相同时钟，但输入数据延迟锁存
    reg [127:0] data_in_delayed;
    reg         data_valid_delayed;
    reg [1:0]   delay_cnt;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            delay_cnt <= 2'd0;
            data_in_delayed <= 128'd0;
            data_valid_delayed <= 1'b0;
        end else if (data_valid) begin
            if (delay_cnt < 2'd2) begin  // 延迟2个周期
                delay_cnt <= delay_cnt + 1'b1;
                data_in_delayed <= data_in;  // 锁存输入
                data_valid_delayed <= 1'b0;
            end else begin
                data_valid_delayed <= 1'b1;
            end
        end else begin
            data_valid_delayed <= 1'b0;
        end
    end
    
    wire [127:0] result_b;
    wire         done_b;
    
    aes_core u_core_b (
        .clk      (clk),
        .data_in  (data_in_delayed),  // 延迟后的数据
        .data_out (result_b),
        .done     (done_b),
        // ...
    );
    
    // 比较时对齐：result_a 需要延迟以匹配 result_b 的延迟
    reg [127:0] result_a_delay1, result_a_delay2;
    reg         done_a_delay1, done_a_delay2;
    
    always @(posedge clk) begin
        result_a_delay1 <= result_a;
        result_a_delay2 <= result_a_delay1;
        done_a_delay1 <= done_a;
        done_a_delay2 <= done_a_delay1;
    end
    
    // 最终比较使用对齐后的信号
    wire [127:0] result_a_aligned = result_a_delay2;
    wire         done_a_aligned = done_a_delay2;
    
    assign fault_detected = done_a_aligned && done_b && (result_a_aligned != result_b);
    assign safe_result = fault_detected ? 128'd0 : result_a_aligned;
    
endmodule
```

**方案 A 特点**：
- Core B 处理的是延迟后的数据
- Core A 结果延迟对齐 Core B
- 同一时钟边沿故障影响时间错开
- 实现简单，时序清晰

##### 方案 B: 反相时钟（更简单的替代方案）

```verilog
// Core B 使用反相时钟（下降沿触发）
wire clk_inv = ~clk;

aes_core u_core_b (
    .clk      (clk_inv),  // 反相时钟
    .data_in  (data_in),  // 相同数据
    .data_out (result_b),
    .done     (done_b),
    // ...
);
```

**方案 B 特点**：
- 上升沿和下降沿不会同时受同一毛刺影响
- 实现最简单，资源最少
- 防护效果弱于方案 A，但优于无时钟分离

##### 比较逻辑说明

无论哪种方案，比较时都需要确保两核结果在时间上是同一笔数据的输出：

```
时序图（方案A，延迟2周期）：

Cycle:     0      1      2      3      4      5      6
           |      |      |      |      |      |      |
Data In    |<==== Data 0 =====>|      |      |      |
           |      |      |      |      |      |      |
Core A     |<==== 处理 Data 0 ========>|<=== Result A
           |      |      |      |      |      |      |
Data B     |      |      |<==== Data 0 =====>|      |
           |      |      |      |      |      |      |
Core B     |      |      |<==== 处理 Data 0 ========>|<== Result B
           |      |      |      |      |      |      |
Result A'  |      |      |      |      |      |<=== Result A (延迟对齐)
           |      |      |      |      |      |      |
Compare    |      |      |      |      |      |<=== Compare A' vs B
```

**建议**：采用方案 A，延迟 2 个时钟周期，平衡防护效果与复杂度。

---

#### 安全机制自检 (BIST) 实现方案

##### BIST vs DFT 的关系

| 类型 | 目的 | 触发时机 | 实现方式 |
|------|------|----------|----------|
| **DFT** | 制造测试 | 生产测试 | 扫描链、JTAG |
| **BIST** | 功能安全自检 | 上电/周期性 | 软件触发 + 硬件自检 |
| **故障注入** | 验证安全机制有效性 | 测试阶段 | 专用测试接口 |

**结论**：安全机制自检 (BIST) 需要**独立于 DFT 的故障注入功能**！

##### BIST 实现架构

```verilog
module safety_bist (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        bist_start,      // 软件触发
    output reg         bist_done,
    output reg         bist_pass,       // 1=通过, 0=失败
    output reg  [2:0]  bist_fail_id,    // 失败的测试项
    
    // 故障注入接口（仅测试模式使用）
    output reg         fi_enable,       // 故障注入使能
    output reg  [7:0]  fi_target,       // 故障目标选择
    output reg         fi_trigger,      // 故障触发
    
    // 被测安全机制信号
    input  wire        fault_detected,
    input  wire        crc_error,
    input  wire        timeout_flag
);

// BIST 测试项定义
localparam TEST_LOCKSTEP   = 3'd0;  // Dual-rail 比较器自检
localparam TEST_CRC        = 3'd1;  // CRC checker 自检
localparam TEST_TIMEOUT    = 3'd2;  // Timeout 监控自检
localparam TEST_INTERRUPT  = 3'd3;  // 中断上报自检

reg [2:0] test_state;
reg [15:0] test_cnt;

// BIST 状态机
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        test_state <= 3'd0;
        bist_done <= 1'b0;
        bist_pass <= 1'b0;
        fi_enable <= 1'b0;
    end else begin
        case (test_state)
            IDLE: begin
                if (bist_start) begin
                    test_state <= TEST_LOCKSTEP;
                    test_cnt <= 16'd0;
                    bist_done <= 1'b0;
                end
            end
            
            // ===== TEST 1: Lockstep 比较器自检 =====
            TEST_LOCKSTEP: begin
                // 注入故障：强制 Core B 输出与 Core A 不同
                fi_enable <= 1'b1;
                fi_target <= 8'h01;  // 选择 Core B 数据注入
                
                // 等待 fault_detected 置位
                if (fault_detected) begin
                    // 安全机制正确检测到故障
                    fi_enable <= 1'b0;
                    test_state <= TEST_CRC;
                end else if (test_cnt > 16'd1000) begin
                    // 超时未检测到故障 -> 自检失败
                    bist_pass <= 1'b0;
                    bist_fail_id <= TEST_LOCKSTEP;
                    bist_done <= 1'b1;
                    test_state <= IDLE;
                end
                test_cnt <= test_cnt + 1'b1;
            end
            
            // ===== TEST 2: CRC Checker 自检 =====
            TEST_CRC: begin
                // 注入错误 CRC 数据
                fi_enable <= 1'b1;
                fi_target <= 8'h02;  // 选择 CRC 数据注入
                
                if (crc_error) begin
                    fi_enable <= 1'b0;
                    test_state <= TEST_TIMEOUT;
                end else if (test_cnt > 16'd1000) begin
                    bist_pass <= 1'b0;
                    bist_fail_id <= TEST_CRC;
                    bist_done <= 1'b1;
                    test_state <= IDLE;
                end
                test_cnt <= test_cnt + 1'b1;
            end
            
            // ===== TEST 3: Timeout 监控自检 =====
            TEST_TIMEOUT: begin
                // 强制状态机停滞（通过 fi_target 控制）
                fi_enable <= 1'b1;
                fi_target <= 8'h04;  // 强制 FSM stall
                
                if (timeout_flag) begin
                    fi_enable <= 1'b0;
                    bist_pass <= 1'b1;  // 所有测试通过
                    bist_done <= 1'b1;
                    test_state <= IDLE;
                end else if (test_cnt > TIMEOUT_THRESHOLD + 16'd100) begin
                    bist_pass <= 1'b0;
                    bist_fail_id <= TEST_TIMEOUT;
                    bist_done <= 1'b1;
                    test_state <= IDLE;
                end
                test_cnt <= test_cnt + 1'b1;
            end
            
            default: test_state <= IDLE;
        endcase
    end
end

endmodule
```

##### 故障注入实现（无需 DFT）

```verilog
// 在 fault_detector 模块中添加测试接口
module fault_detector (
    // ... 正常接口 ...
    
    // BIST 测试接口（仅测试模式连接）
    input  wire        test_en,         // 测试使能
    input  wire [7:0]  test_target,     // 测试目标选择
    input  wire        test_trigger,    // 测试触发
    
    // 被测信号输出（用于 BIST 监控）
    output wire        fault_det_out,   // fault_detected 输出
    output wire        int_fault_out    // 中断输出
);

// 测试模式下的故障注入
wire [127:0] result_b_test;
assign result_b_test = test_en ? (result_b ^ test_mask) : result_b;

// 正常比较逻辑（使用可能被注入故障的 result_b_test）
assign fault_detected = (result_a != result_b_test);

// 输出监控
assign fault_det_out = fault_detected;
assign int_fault_out = int_fault;

endmodule
```

##### BIST 寄存器接口

| 寄存器 | 地址 | 位 | 名称 | 描述 |
|--------|------|-----|------|------|
| BIST_CTRL | 0x50 | [0] | START | 启动 BIST |
| | | [1] | MODE | 0=上电自检, 1=周期自检 |
| BIST_STATUS | 0x54 | [0] | DONE | BIST 完成 |
| | | [1] | PASS | 1=通过, 0=失败 |
| | | [4:2] | FAIL_ID | 失败的测试项 |

##### BIST 触发策略

```
上电自检 (Power-On BIST):
  - 芯片上电后自动执行
  - 约 10-100us 完成
  - 结果存入 BIST_STATUS
  - 失败可触发安全状态

周期性自检 (Periodic BIST):
  - 软件定时触发（建议每 100ms-1s）
  - 可分段执行减少性能影响
  - 后台执行，不阻塞正常运算

按需自检 (On-Demand BIST):
  - 软件主动触发
  - 用于故障排查
  - 可单独测试某个安全机制
```

**关键设计原则**：
1. BIST 故障注入接口与正常功能完全隔离（通过 test_en 控制）
2. BIST 不依赖 DFT 扫描链，独立实现
3. 故障注入只影响测试目标，不影响其他模块
4. 提供明确的通过/失败状态，便于软件决策

### 6.3 中期修正 (Before DDR)

1. **完善配置切换安全设计** (Major)
   - Design Spec 8.2.3.3节添加故障检测机制
   - 确保切换过程中发生故障能被检测

2. **统一故障类型编码** (Minor)
   - Design Spec 8.8.1节定义了故障类型编码
   - Architecture Spec 可引用此定义

**修正优先级**:
1. 🔴 Critical: STATUS/INT_EN/INT_STATUS 寄存器位定义统一
2. 🟡 Major: CTRL[9] DUAL_RAIL_EN 在 Design Spec 中补充
3. 🟢 Minor: 文档间交叉引用完善

**实体 Yang 需重点检查**:
1. 寄存器位定义的最终方案确认
2. MODE 字段放置位置 (CTRL vs 单独 MODE 寄存器)
3. 软件驱动的兼容性影响评估

---

### 附录: 文档版本信息

| 文档 | 版本 | 日期 | 作者 |
|------|------|------|------|
| Architecture Spec | v1.1 | 2026-04-01 | System Architect |
| Design Spec | v1.0 | 2026-03-31 | AI-Yang Design Agent |
| FMEDA Report | v1.1 | 2026-04-01 | FuSa Engineer Agent |

### 签名

| 角色 | 签名 | 日期 |
|------|------|------|
| FuSa Agent (检查人) | ✅ | 2026-04-01 |

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

为降低共因故障风险，Core B 使用相对于 Core A 延迟的时钟：

```verilog
// 时钟延迟实现（建议延迟 2-4 个时钟周期）
module clock_delay (
    input  wire clk_in,
    input  wire rst_n,
    output wire clk_delayed
);
    reg [1:0] delay_reg;
    
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n)
            delay_reg <= 2'b00;
        else
            delay_reg <= {delay_reg[0], 1'b1};
    end
    
    // 延迟后的时钟（或使用时钟分相）
    assign clk_delayed = delay_reg[1] ? clk_in : 1'b0;
endmodule
```

**延迟时钟的优势**：
1. 同一时钟边沿故障不会同时影响两核
2. 电源毛刺影响时间错开
3. EMI 干扰影响降低

**比较逻辑调整**：
- Core A 结果需延迟对齐 Core B 结果
- 或 Core B 结果提前采样

**建议延迟周期**：2-4 个时钟周期（平衡防护效果与复杂度）

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

# EDR Remediation Plan

## Document Information
- **Version**: v1.0
- **Date**: 2026-04-01
- **Target Document**: Design Spec v1.0
- **Status**: Draft for Review

---

## Executive Summary

This document provides a comprehensive remediation plan for the 38 issues identified during the EDR (Engineering Design Review) of Design Spec v1.0. The plan prioritizes fixes based on severity, dependencies, and impact.

| Priority Level | Issue Count | Target Completion |
|----------------|-------------|-------------------|
| P0 - Critical | 1 | 2026-04-02 |
| P1 - Major (High) | 10 | 2026-04-03 |
| P2 - Major (Medium) | 7 | 2026-04-04 |
| P3 - Minor | 20 | 2026-04-05 (Optional) |

---

## Remediation Priority Matrix

### P0 - Critical (Must Fix for EDR Pass)

| # | Issue ID | Chapter | Description | Est. Effort | Owner |
|---|----------|---------|-------------|-------------|-------|
| 1 | C1 | 6.2, 6.4 | Fix 99% DC coverage claim | 1h | FuSa Engineer |

### P1 - Major High Priority (Strongly Recommended)

| # | Issue ID | Chapter | Description | Est. Effort | Owner |
|---|----------|---------|-------------|-------------|-------|
| 2 | M1 | 4.2 | Unify MODE field definition | 1h | Design Agent |
| 3 | M14 | 2.2 | Rename sbox_ti to sbox_masked | 0.5h | Design Agent |
| 4 | M15 | 8.6, 2.2 | Clarify area estimation data | 1h | Design Agent |
| 5 | M4 | 6.2.3, 4.2 | Add DUAL_RAIL_EN security concept | 1.5h | FuSa Engineer |
| 6 | M2 | 5.4.2 | Add ERROR state to FSM diagram | 1h | Design Agent |
| 7 | M10 | 9.3 | Clarify fault injection scene scope | 1h | Verification Agent |
| 8 | M11 | 9.4 | Complete assertion list (AS27-AS34) | 2h | Verification Agent |
| 9 | M5 | 6.2.4 | Document clock monitoring for common cause | 1h | FuSa Engineer |
| 10 | M18 | 2.1, 2.2 | Add ASIL level assignment table | 1h | Design Agent |
| 11 | M3 | 6.2.4 | Specify clock delay cycles clearly | 0.5h | Design Agent |

### P2 - Major Medium Priority (Recommended)

| # | Issue ID | Chapter | Description | Est. Effort | Owner |
|---|----------|---------|-------------|-------------|-------|
| 12 | M6 | 6.3.3 | Add BIST detection latency analysis | 1.5h | FuSa Engineer |
| 13 | M7 | 4.3 | Specify FAULT_DETECTED as sticky bit | 0.5h | FuSa Engineer |
| 14 | M8 | 6.2.6 | Define fault type encoding 3'b111 | 0.5h | FuSa Engineer |
| 15 | M9 | 9.1 | Add UVM integration test description | 1h | Verification Agent |
| 16 | M12 | 9.5 | Clarify verification checklist timeline | 0.5h | Verification Agent |
| 17 | M13 | 5.4.2 | Align FSM with Verification Plan | 1h | Verification Agent |
| 18 | M16 | 7.1 | Document clock domain relationship | 0.5h | Design Agent |
| 19 | M17 | 2.1, 2.2 | Document ASIL decomposition rationale | 1h | Design Agent |
| 20 | M18 | 1.4 | Specify throughput test conditions | 0.5h | Design Agent |

---

## Detailed Remediation Steps

### Phase 1: Critical Fix (P0)

#### ISSUE-001 (C1): Fix 99% DC Coverage Claim

**Location**: 
- Chapter 6.2.1: "诊断覆盖率: >99%（针对数据通路单比特翻转）"
- Chapter 6.4: "Dual-core lockstep | 99%"
- Chapter 5.3.2: "Dual-rail | 99%"

**Current Text**:
```markdown
| 属性 | 描述 |
|------|------|
| **诊断覆盖率** | >99%（针对数据通路单比特翻转） |
```

**Modification**:
```markdown
| 属性 | 描述 |
|------|------|
| **诊断覆盖率** | 设计目标: 99% (待故障注入验证) |

**注意**: 当前99%覆盖率为基于设计的估算值，实际诊断覆盖率将通过故障注入验证确定。
参考: FMEDA Report v1.1, Section 4.2
```

**Also update Chapter 6.4**:
```markdown
| 安全机制 | DC | 备注 |
|----------|-----|------|
| Dual-core lockstep | 99%* | *设计目标值，待故障注入验证后更新 |
```

**Rationale**: FuSa Engineer Critical finding - FMEDA报告明确说明数据为"设计估算，非实测"

**Verification**:
- [ ] 所有99%声明已添加免责声明
- [ ] 与FMEDA报告引用一致
- [ ] FuSa Engineer确认修复

---

### Phase 2: Major High Priority Fixes (P1)

#### ISSUE-002 (M1): Unify MODE Field Definition

**Location**: Chapter 4.2 CTRL寄存器

**Current Text** (存在冲突):
```markdown
| 位 | 名称 | 描述 |
|----|------|------|
| [0] | START | 操作开始触发 (1=启动，自动清零) |
| [8:1] | MODE[7:0] | 工作模式选择 |
| [9] | DUAL_RAIL_EN | 双轨比较使能 (1=启用双核锁步) |

**MODE[7:0] 编码说明**:
| 位域 | 名称 | 描述 |
|------|------|------|
| MODE[0] | ENCRYPT | 1=加密, 0=解密 |
| MODE[3:1] | OP_MODE | 操作模式: 000=ECB, 001=CBC, 010=CTR, 011=GCM, 100=XTS, 101=CTS |
| MODE[5:4] | KEY_MODE | 密钥长度: 00=128-bit, 01=192-bit, 10=256-bit |
| MODE[7:6] | Reserved | 保留 |
```

**Modification**:
```markdown
| 位 | 名称 | 描述 |
|----|------|------|
| [0] | START | 操作开始触发 (1=启动，自动清零) |
| [1] | ENCRYPT | 1=加密, 0=解密 |
| [4:2] | OP_MODE | 操作模式: 000=ECB, 001=CBC, 010=CTR, 011=GCM, 100=XTS, 101=CTS |
| [6:5] | KEY_MODE | 密钥长度: 00=128-bit, 01=192-bit, 10=256-bit |
| [8:7] | Reserved | 保留 |
| [9] | DUAL_RAIL_EN | 双轨比较使能 (1=启用双核锁步) |
| [31:10] | Reserved | 保留 |

**注意**: MODE控制位对应位[6:1]，其中[1]=ENCRYPT, [4:2]=OP_MODE, [6:5]=KEY_MODE
```

**Rationale**: Design Agent finding - 删除模糊的[8:1]描述，采用统一的位域定义

**Verification**:
- [ ] 寄存器表格与位域表格一致
- [ ] 与Arch Spec v1.1对齐
- [ ] Design Agent确认修复

---

#### ISSUE-003 (M14): Rename sbox_ti to sbox_masked

**Location**: Chapter 2.2 模块划分

**Current Text**:
```markdown
| 模块名 | 功能描述 | ASIL等级 | 面积估算 | 可配置性 |
|--------|----------|----------|----------|----------|
| `sbox_ti` | TI掩码S-Box (16个) | ASIL-D | 8K gates | 固定 |
```

**Modification**:
```markdown
| 模块名 | 功能描述 | ASIL等级 | 面积估算 | 可配置性 |
|--------|----------|----------|----------|----------|
| `sbox_masked` | 掩码S-Box (16个), 采用3-share TI实现 | ASIL-D | 8K gates | 固定 |

**说明**: sbox_masked模块采用Threshold Implementation (TI)方案实现一阶DPA防护，
与Architecture Spec v1.1命名保持一致。
```

**Also update all occurrences**:
- Section 2.2: 模块划分表
- Section 5.1.3: "`sbox_ti`模块面积估算为8K gates"

**Rationale**: IP Architect finding - 与Architecture Spec v1.1保持一致

**Verification**:
- [ ] 全文`sbox_ti`已替换为`sbox_masked`
- [ ] 添加TI实现说明
- [ ] IP Architect确认修复

---

#### ISSUE-004 (M15): Clarify Area Estimation Data

**Location**: Chapter 8.6 Lockstep模式功耗对比, Chapter 2.2 模块划分

**Current Text**:
```markdown
| 模式 | 面积 |
|------|------|
| 单核 (ENABLE_LOCKSTEP=0) | ~35K gates |
```

模块面积和：3+30+8+5+8+4+3+2+1+0.5 = 64.5K gates

**Modification**:
```markdown
| 模式 | 综合后面积 | 门数估算* |
|------|-----------|----------|
| 单核 (ENABLE_LOCKSTEP=0) | ~35K gates | 45K±10K gates |
| 双核 (ENABLE_LOCKSTEP=1) | ~50K gates | 64K±10K gates |

*注: 门数估算包含布线面积和时钟树开销，实际面积以综合结果为准。
模块级估算与系统级综合面积存在差异属正常情况（布线、优化、共享资源等因素）。

**面积分解说明**:
- aes_core: 30K (可复用逻辑在综合后共享)
- key_schedule: 5K
- sbox_masked: 8K (TI实现，面积优化)
- 其他模块: ~12K
- 综合优化/布线开销: ~10K
```

**Rationale**: IP Architect finding - 澄清模块估算与综合面积的差异原因

**Verification**:
- [ ] 面积数据一致性说明已添加
- [ ] 增加面积估算范围(±10K)
- [ ] IP Architect确认修复

---

#### ISSUE-005 (M4): Add DUAL_RAIL_EN Security Concept

**Location**: Chapter 6.2.3 可配置性设计

**Current Text**:
```markdown
| 配置层次 | 控制方式 | 配置项 | 适用场景 |
|----------|----------|--------|----------|
| **运行时** | CTRL寄存器 [9] | `DUAL_RAIL_EN` | 动态使能/禁用 |
```

**Modification**:
```markdown
| 配置层次 | 控制方式 | 配置项 | 适用场景 | 安全要求 |
|----------|----------|--------|----------|----------|
| **运行时** | CTRL寄存器 [9]* | `DUAL_RAIL_EN` | 动态使能/禁用 | 仅特权模式可写 |

*安全概念说明*:
- DUAL_RAIL_EN动态禁用仅在特权模式(CPU mode)下允许
- 建议增加软件安全机制：禁用前需验证系统状态安全
- 增加状态指示位 STATUS[10] LOCKSTEP_ACTIVE (1=双核锁步运行中)

**误用防护**:
- 非特权模式写CTRL[9]将被忽略
- 状态寄存器LOCKSTEP_ACTIVE位可用于软件确认当前模式
```

**Also add to Chapter 4.3 STATUS寄存器**:
```markdown
| [10] | LOCKSTEP_ACTIVE | 双核锁步运行状态 (1=运行中，只读) |
```

**Rationale**: FuSa Engineer finding - 运行时禁用安全机制存在安全风险

**Verification**:
- [ ] 安全概念说明已添加
- [ ] 增加LOCKSTEP_ACTIVE状态位
- [ ] FuSa Engineer确认修复

---

#### ISSUE-006 (M2): Add ERROR State to FSM Diagram

**Location**: Chapter 5.4.1 状态机架构, 5.4.2 状态定义

**Current FSM Diagram** (文本描述):
```
IDLE -> KEY_SCHEDULE -> LOAD_DATA -> ROUND_OP -> FINAL_ROUND -> OUTPUT_DATA -> DONE -> IDLE
```

**Modification**:
```markdown
### 5.4.1 状态机架构

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
        ... (中间状态省略) ...
               |                               |
               +---------------+---------------+
                               |
                               v
                          +---+----+
                          |  DONE  |
                          +---+----+
                               |
          +--------------------+------------+
          |                                 |
          v                                 v
     +----+----+                      +-----+-----+
     |  IDLE   |                      |  ERROR    |
     | (正常)  |                      | (故障)    |
     +---------+                      +-----+-----+
                                            |
                                            | clear_err=1
                                            v
                                       +----+----+
                                       |  IDLE   |
                                       +---------+
```

**状态转换条件**:
- 任何状态检测到故障 → ERROR
- ERROR状态 → IDLE: 软件写STATUS[4]=1清零，或软件复位

### 5.4.2 状态定义 (更新)

| 状态 | 编码 | 描述 | 转换条件 |
|------|------|------|----------|
| IDLE | 3'b000 | 空闲状态，等待启动 | start=1 → KEY_SCHEDULE |
| ... | ... | ... | ... |
| ERROR | 3'b111 | 错误状态 | 故障清除 → IDLE |

### 5.4.3 错误恢复流程

**进入ERROR状态的条件**:
1. fault_detected = 1 (双轨不一致)
2. CRC错误
3. 超时
4. 其他安全机制触发

**退出ERROR状态的步骤**:
1. 软件读取STATUS寄存器确认故障类型
2. 软件清除故障源（如需要）
3. 软件写STATUS[4]=1清零FAULT_DETECTED位
4. 状态机自动返回IDLE

**注意**: ERROR状态为sticky状态，必须软件介入才能恢复。
```

**Rationale**: Design Agent finding - ERROR状态在图中缺失，恢复机制未说明

**Verification**:
- [ ] FSM图包含ERROR状态
- [ ] 状态转换条件明确
- [ ] 恢复流程步骤完整
- [ ] Design Agent确认修复

---

#### ISSUE-007 (M10): Clarify Fault Injection Scene Scope

**Location**: Chapter 9.3 故障注入测试场景

**Current Text**:
```markdown
| 场景ID | 故障类型 | 注入位置 | 预期结果 |
|--------|----------|----------|----------|
| FI-001 | 单比特翻转 | result_a[0] | fault_detected=1 |
| ... | ... | ... | ... |
| FI-005 | 超时 | State stuck | TIMEOUT_ERR=1 |
```

**Modification**:
```markdown
### 9.3 故障注入测试场景

**范围说明**: 本节列出Design Spec涵盖的高优先级故障注入场景(5个)。
完整故障注入测试场景(48个)定义于Verification Plan v1.0 Section 8，
场景编号SM-001~SM-048。

**Design Spec与Verification Plan场景映射**:

| Design Spec | Verification Plan | 说明 |
|-------------|-------------------|------|
| FI-001 | SM-001~SM-010 | 单比特翻转 - Core A |
| FI-002 | SM-011~SM-020 | 单比特翻转 - Core B |
| FI-003 | SM-021~SM-030 | 多比特翻转场景 |
| FI-004 | SM-031~SM-040 | CRC错误场景 |
| FI-005 | SM-041~SM-048 | 超时/FSM卡住场景 |

### 高优先级场景详情

| 场景ID | 故障类型 | 注入位置 | 注入方法 | 预期结果 |
|--------|----------|----------|----------|----------|
| FI-001 | 单比特翻转 | result_a[0] | Verilog force | fault_detected=1 |
| FI-002 | 单比特翻转 | result_b[63] | Verilog force | fault_detected=1 |
| FI-003 | 多比特翻转 | result_a[31:0] | Verilog force | fault_detected=1 |
| FI-004 | CRC错误 | crc_valid=0 | 软件注入 | CRC_ERR=1 |
| FI-005 | 超时 | State stuck at ROUND_OP | 时钟门控 | TIMEOUT_ERR=1 |

**注入方法说明**:
- **软件注入(Verilog force)**: 适用于仿真环境，通过force语句注入故障
- **硬件注入**: FPGA原型验证或EMFI(电磁故障注入)，适用于物理验证
- **时钟门控**: 通过暂停时钟模拟超时场景

**注**: 完整48个场景的实现计划参见Verification Plan v1.0。
```

**Rationale**: Verification Agent finding - 场景数量(5)与Verification Plan(48)不一致需澄清

**Verification**:
- [ ] 场景范围说明已添加
- [ ] 与Verification Plan映射关系明确
- [ ] 注入方法说明完整
- [ ] Verification Agent确认修复

---

#### ISSUE-008 (M11): Complete Assertion List (AS27-AS34)

**Location**: Chapter 9.4 断言检查

**Current Text**:
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

**Modification**:
```markdown
### 9.4 断言检查

**断言覆盖范围**: 本节断言覆盖Verification Plan v1.0 Chapter 8定义的安全属性AS1~AS34。
以下为Design Spec中定义的断言子集，完整断言列表参见Verification Plan。

#### 9.4.1 双轨比较断言 (AS1-AS10)

```verilog
// AS1: fault_detected 必须在结果不匹配后1-2 cycles置位
assert property (
    @(posedge clk) disable iff (!rst_n)
    (result_a_valid && result_b_valid && (result_a != result_b)) 
    |-> ##[1:2] fault_detected
);

// AS2: 故障时必须输出零
assert property (
    @(posedge clk) disable iff (!rst_n)
    fault_detected |-> (safe_result == 128'h0)
);

// AS3: Core A和Core B接收相同输入
assert property (
    @(posedge clk) disable iff (!rst_n)
    DUAL_RAIL_EN |-> (core_a_input == core_b_input)
);

// AS4: 双核结果在比较窗口内有效
assert property (
    @(posedge clk) disable iff (!rst_n)
    result_a_valid |-> ##[0:3] result_b_valid
);
```

#### 9.4.2 CRC检查断言 (AS11-AS20)

```verilog
// AS11: CRC错误必须触发CRC_ERR状态位
assert property (
    @(posedge clk) disable iff (!rst_n)
    crc_mismatch |-> ##1 CRC_ERR
);

// AS12: CRC错误必须中止当前操作
assert property (
    @(posedge clk) disable iff (!rst_n)
    CRC_ERR |-> ##1 (state == ERROR)
);
```

#### 9.4.3 超时检查断言 (AS21-AS26)

```verilog
// AS21: 状态卡住必须触发超时
assert property (
    @(posedge clk) disable iff (!rst_n)
    $stable(state) && state != IDLE && state != DONE 
    |-> ##MAX_TIMEOUT_CYCLES timeout_flag
);
```

#### 9.4.4 FSM安全断言 (AS27-AS34)

```verilog
// AS27: 无效状态转换必须进入ERROR
assert property (
    @(posedge clk) disable iff (!rst_n)
    !(state inside {IDLE, KEY_SCHEDULE, LOAD_DATA, ROUND_OP, 
                    FINAL_ROUND, OUTPUT_DATA, DONE, ERROR})
    |-> ##1 (state == ERROR)
);

// AS28: ERROR状态只能转换到IDLE
assert property (
    @(posedge clk) disable iff (!rst_n)
    $past(state) == ERROR && state != ERROR 
    |-> state == IDLE
);

// AS29: START触发后必须进入KEY_SCHEDULE
assert property (
    @(posedge clk) disable iff (!rst_n)
    (state == IDLE && START) |-> ##1 (state == KEY_SCHEDULE)
);

// AS30: 最后一轮后必须进入OUTPUT_DATA
assert property (
    @(posedge clk) disable iff (!rst_n)
    (state == FINAL_ROUND && round_complete) 
    |-> ##1 (state == OUTPUT_DATA)
);

// AS31: 忙状态时BUSY位必须置位
assert property (
    @(posedge clk) disable iff (!rst_n)
    (state != IDLE) |-> BUSY
);

// AS32: 操作完成后必须触发DONE中断或状态
assert property (
    @(posedge clk) disable iff (!rst_n)
    (state == DONE) |-> ##[0:2] DONE_STATUS
);

// AS33: 故障时必须清除输出
assert property (
    @(posedge clk) disable iff (!rst_n)
    FAULT_DETECTED |-> (output_data == 0)
);

// AS34: 双核锁步禁用时fault_detected必须为0
assert property (
    @(posedge clk) disable iff (!rst_n)
    !DUAL_RAIL_EN |-> !fault_detected
);
```

#### 9.4.5 断言与Verification Plan映射

| Design Spec | Verification Plan | 描述 |
|-------------|-------------------|------|
| AS1-AS10 | AS1-AS10 | 双轨比较断言 |
| AS11-AS20 | AS11-AS20 | CRC检查断言 |
| AS21-AS26 | AS21-AS26 | 超时检查断言 |
| AS27-AS34 | AS27-AS34 | FSM安全断言 |

**注**: AS1延迟从##1改为##[1:2]以匹配RTL实际时序。
```

**Rationale**: Verification Agent finding - 仅2个断言示例，缺少AS27~AS34

**Verification**:
- [ ] 断言列表完整(至少AS27-AS34)
- [ ] 与Verification Plan映射关系明确
- [ ] AS1延迟修正为##[1:2]
- [ ] Verification Agent确认修复

---

#### ISSUE-009 (M5): Document Clock Monitoring for Common Cause

**Location**: Chapter 6.2.4 时钟延迟实现（共因故障防护）

**Current Text**:
```markdown
为防止同一时钟边沿的共因故障同时影响 Core A 和 Core B，采用 **数据延迟锁存方案** 实现时间冗余
```

**Modification**:
```markdown
### 6.2.4 时钟延迟实现（共因故障防护）

为防止同一时钟边沿的共因故障同时影响 Core A 和 Core B，采用 **数据延迟锁存方案** 实现时间冗余。

**时钟源共因故障说明**:
本方案假设时钟源本身正常工作。时钟源故障（如时钟毛刺、时钟丢失）属于共因故障，
可能同时影响Core A和Core B，仅靠数据延迟无法检测。

**时钟源监控方案**:
时钟源共因故障通过以下机制覆盖：
1. **独立时钟监控**: 系统级独立时钟源比较（在SoC级实现）
2. **看门狗定时器(WDT)**: 独立于AES模块的WDT监控响应时间
3. **FMEDA评估**: 时钟源故障残余失效率在系统级FMEDA中评估，
   不纳入AES模块Dual-Rail Compare的DC计算

**模块级防护范围**:
- ✅ 覆盖: 时钟分布路径上的单点故障（时钟缓冲器、时钟门控单元）
- ✅ 覆盖: 时钟边沿毛刺（延迟方案可有效防护）
- ⚠️  不覆盖: 时钟源本身的共因故障（由系统级机制覆盖）

**延迟方案详情**:
...(保留原代码示例)...

**延迟量选择依据**:
- 延迟周期: 2 cycles
- 选择依据: 
  - 典型时钟毛刺持续时间 < 1 cycle
  - 工艺角下时钟抖动 < 0.5 cycle
  - 2 cycle延迟可确保Core A和Core B不在同一毛刺窗口内采样
```

**Rationale**: FuSa Engineer finding - 共因故障防护方案未覆盖时钟源故障

**Verification**:
- [ ] 时钟源共因故障风险已说明
- [ ] 系统级覆盖机制已记录
- [ ] 延迟选择定量分析已补充
- [ ] FuSa Engineer确认修复

---

#### ISSUE-010 (M18): Add ASIL Level Assignment Table

**Location**: Chapter 2.1 顶层架构, Chapter 2.2 模块划分

**Modification**:
```markdown
### 2.1.1 ASIL等级分配

| 模块 | ASIL等级 | 分配依据 | 安全目标追溯 |
|------|----------|----------|--------------|
| aes_controller | ASIL-D | 控制主状态机和寄存器访问 | SG1, SG2, SG3 |
| aes_core (A/B) | ASIL-D | 核心加密运算，故障直接影响结果 | SG1, SG2 |
| key_manager | ASIL-D | 密钥存储，泄露风险 | SG1 |
| key_schedule | ASIL-D | 密钥扩展，影响所有轮密钥 | SG1, SG2 |
| sbox_masked | ASIL-D | S-Box运算，核心安全功能 | SG1, SG2 |
| fault_detector | ASIL-D | 故障检测机制本身 | SG3 |
| mode_controller | ASIL-B | 模式控制，错误可检测 | SG2 |
| xts_engine | ASIL-B | XTS tweak计算，非核心安全 | SG2 |
| cts_handler | ASIL-B | CTS边界处理，可验证 | SG2 |
| crc_checker | ASIL-B | 数据完整性检查 | SG3 |
| interrupt_ctrl | ASIL-B | 中断控制 | SG2, SG3 |

**ASIL分解说明**:
- 核心加密路径(aes_core, key_manager, key_schedule, sbox_masked)为ASIL-D
- 故障检测机制(fault_detector)为ASIL-D（与受保护电路同等级）
- 辅助功能模块(mode_controller, xts_engine等)为ASIL-B
- 符合ISO 26262 ASIL分解原则
```

**Rationale**: IP Architect finding - ASIL等级分配未明确说明

**Verification**:
- [ ] ASIL分配表完整
- [ ] 与安全目标追溯关系明确
- [ ] IP Architect确认修复

---

#### ISSUE-011 (M3): Specify Clock Delay Cycles Clearly

**Location**: Chapter 6.2.4 时钟延迟实现

**Current Code**:
```verilog
if (delay_cnt < 2'd2) begin
    delay_cnt <= delay_cnt + 1'b1;
    data_in_delayed <= data_in;
end
```

**Modification**:
```markdown
**延迟周期说明**:
- Core B数据延迟: 2个时钟周期
- Core A结果对齐延迟: 2个时钟周期（匹配Core B延迟）
- 总比较延迟: result_valid后2 cycles触发比较

**代码实现**:
```verilog
// Core B: 输入数据延迟2 cycles
reg [127:0] data_in_delayed;
reg [1:0]   delay_cnt;

always @(posedge clk) begin
    if (data_valid) begin
        if (delay_cnt < 2'd2) begin  // 延迟2 cycles
            delay_cnt <= delay_cnt + 1'b1;
            data_in_delayed <= data_in;
        end
    end
end

// Core A: 结果延迟2 cycles以对齐Core B
reg [127:0] result_a_dly1, result_a_dly2;
always @(posedge clk) begin
    result_a_dly1 <= result_a;
    result_a_dly2 <= result_a_dly1;
end

// 比较（2 cycles延迟后）
assign fault_detected = (result_a_dly2 != result_b);
```

**延迟量选择依据**:
1. **共因故障防护**: 2 cycle延迟确保Core A和Core B不在同一时钟毛刺窗口内采样
2. **时钟抖动容限**: 典型工艺角下时钟抖动 < 0.5 cycle，2 cycle提供足够裕量
3. **性能影响**: 2 cycle延迟对吞吐率影响可忽略（11 cycle/block基础上+2 cycle）
4. **面积开销**: 延迟寄存器面积 < 0.1K gates，可接受
```

**Rationale**: Design Agent finding - 延迟cycle数不明确，缺少定量分析

**Verification**:
- [ ] 延迟cycle数明确(2 cycles)
- [ ] 延迟选择依据已补充
- [ ] Design Agent确认修复

---

## Phase 3: Major Medium Priority Fixes (P2)

### ISSUE-012 (M6): Add BIST Detection Latency Analysis

**Location**: Chapter 6.3.3 BIST触发策略

**Modification**:
```markdown
### 6.3.3 BIST触发策略与故障检测延迟分析

**触发策略**:
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

**故障检测延迟分析**:

| 触发方式 | 检测延迟 | FTTI影响 | 建议场景 |
|----------|----------|----------|----------|
| 上电自检 | N/A | 上电时执行 | 启动验证 |
| 周期性(100ms) | <200ms* | 需满足FTTI | 运行期监控 |
| 周期性(1s) | <2s* | 需满足FTTI | 低优先级监控 |
| 按需自检 | 即时 | 无 | 故障排查 |

*检测延迟 = 周期 + BIST执行时间(约10-100us)

**安全概念说明**:
- 周期性BIST的故障检测延迟必须小于系统FTTI(故障容忍时间间隔)
- 建议根据系统FTTI要求选择周期：周期 < FTTI/10
- 对于ASIL-D要求，建议采用100ms周期或连续后台自检
- 故障检测延迟 = BIST周期 + BIST执行时间
- 最坏情况：故障发生在BIST结束后立即，需等待下一周期

**BIST执行时间估算**:
- Lockstep测试: ~1us (10 cycle @ 100MHz)
- CRC测试: ~5us (500 cycle @ 100MHz)
- Timeout测试: ~10us (1000 cycle @ 100MHz)
- 完整BIST: ~100us
```

**Rationale**: FuSa Engineer finding - 周期性BIST故障检测延迟未分析

---

### ISSUE-013 (M7): Specify FAULT_DETECTED as Sticky Bit

**Location**: Chapter 4.3 STATUS寄存器

**Modification**:
```markdown
| [4] | FAULT_DETECTED | 故障检测标志 (1=检测到故障, sticky位) |

**FAULT_DETECTED位说明**:
- **类型**: Sticky位（需软件清零）
- **置位条件**: 检测到任何故障（双轨不一致、CRC错误、超时等）
- **清零方法**: 写1清零（W1C - Write 1 to Clear）
- **保留原因**: 防止瞬态故障被错过，确保软件能观测到

**软件处理流程**:
1. 中断服务程序读取STATUS寄存器
2. 保存FAULT_DETECTED状态和相关故障信息
3. 分析故障类型（结合其他STATUS位）
4. 写1清零FAULT_DETECTED
5. 根据故障类型执行恢复或报告

**注意**: 清零前必须先保存故障信息，清零后故障类型位可能不再有效。
```

**Rationale**: FuSa Engineer finding - FAULT_DETECTED位类型未说明

---

### ISSUE-014 (M8): Define Fault Type Encoding 3'b111

**Location**: Chapter 6.2.6 故障类型编码

**Modification**:
```markdown
| 故障类型 | 编码 (3-bit) | 检测方式 | 说明 |
|----------|--------------|----------|------|
| 结果不匹配 | 3'b000 | result_a ≠ result_b | 双轨比较故障 |
| CRC错误 | 3'b001 | crc_mismatch | 数据完整性错误 |
| 超时错误 | 3'b010 | timeout_expired | 状态机卡住 |
| 奇偶错误 | 3'b011 | parity_mismatch | 寄存器奇偶校验失败 |
| 模式错误 | 3'b100 | mode_invalid | 无效操作模式 |
| 密钥错误 | 3'b101 | key_invalid | 密钥格式/长度错误 |
| 配置错误 | 3'b110 | cfg_mismatch | 配置寄存器不匹配 |
| **多故障** | **3'b111** | multiple_faults | **多种故障同时发生** |

**3'b111编码说明**:
- 用途: 表示两种或多种故障同时发生
- 优先级: 当多种故障同时检测到时，优先报告3'b111
- 软件处理: 读到3'b111时应读取所有相关STATUS位确定具体故障组合
- 保留: 如无多故障场景，该编码保留，软件应忽略
```

**Rationale**: FuSa Engineer finding - 111编码用途未说明

---

### Remaining P2 Issues (Summary)

| Issue ID | Brief Fix Description | Est. Effort |
|----------|----------------------|-------------|
| M9 | Add UVM integration test description to Ch 9.1 | 1h |
| M12 | Clarify verification checklist timeline in Ch 9.5 | 0.5h |
| M13 | Align FSM with Verification Plan SM-041~048 | 1h |
| M16 | Document clock domain relationship in Ch 7.1 | 0.5h |
| M17 | Document ASIL decomposition rationale | 1h |
| M18 | Specify throughput test conditions in Ch 1.4 | 0.5h |

---

## Phase 4: Minor Issues (P3 - Optional)

Minor issues (m1-m20) are optional fixes that improve document quality but are not required for EDR pass. These can be addressed after the Critical and Major issues are resolved.

Key minor fixes to consider:
- m1: S-Box area clarification (5min)
- m4: Lockstep power quantification (10min)
- m10: BIST_FAIL_ID mapping table (15min)
- m19: Power PVT conditions (5min)

---

## Remediation Timeline

```
Day 1 (2026-04-02):
  ├─ 09:00-10:00  C1: Fix 99% DC coverage claim [P0 - Critical]
  ├─ 10:00-11:00  M1: Unify MODE field definition [P1]
  ├─ 11:00-11:30  M14: Rename sbox_ti [P1]
  └─ 13:00-14:00  M15: Clarify area estimation [P1]

Day 2 (2026-04-03):
  ├─ 09:00-10:30  M4: Add DUAL_RAIL_EN security concept [P1]
  ├─ 10:30-11:30  M2: Add ERROR state to FSM [P1]
  ├─ 13:00-14:00  M10: Clarify FI scene scope [P1]
  └─ 14:00-16:00  M11: Complete assertion list [P1]

Day 3 (2026-04-04):
  ├─ 09:00-10:00  M5: Document clock monitoring [P1]
  ├─ 10:00-11:00  M3: Specify clock delay cycles [P1]
  ├─ 11:00-12:00  M6: Add BIST latency analysis [P2]
  ├─ 13:00-14:00  M7, M8: Register bit clarifications [P2]
  └─ 14:00-16:00  M9, M12, M13: Verification updates [P2]

Day 4 (2026-04-05):
  ├─ 09:00-11:00  M16, M17, M18: Architecture updates [P2]
  ├─ 13:00-15:00  Minor issues (optional) [P3]
  └─ 15:00-17:00  Final review and document update
```

---

## Verification and Sign-off

### Pre-EDR Checklist

- [ ] C1 (Critical): 99% DC claim fixed with disclaimer
- [ ] P1 Major fixes (10 issues): All completed
- [ ] P2 Major fixes (7 issues): Completed or documented rationale for deferral
- [ ] Cross-reference check: All related issues aligned
- [ ] Consistency check: No new inconsistencies introduced
- [ ] Agent review: All Agents confirm fixes

### Agent Sign-off

| Agent | Role | Issues Reviewed | Sign-off |
|-------|------|-----------------|----------|
| FuSa Engineer | Safety | C1, M4, M5, M6, M7, M8 | ☐ |
| Design Agent | Design | M1, M2, M3, M14, M15 | ☐ |
| Verification Agent | Verification | M9, M10, M11, M12, M13 | ☐ |
| IP Architect | Architecture | M16, M17, M18 | ☐ |

### EDR Re-entry Criteria

1. Critical issue (C1) **must** be fixed
2. At least 80% of P1 Major issues **must** be fixed
3. All Agents **must** update review conclusion to "通过" or "有条件通过"
4. No new Critical/Major issues introduced

---

## Dependencies and Risks

### Dependencies

| Fix | Depends On | Impact |
|-----|------------|--------|
| M2 (ERROR state) | C1 (safety concept) | Should align fault handling |
| M11 (Assertions) | M2 (FSM states) | AS27-AS34 reference ERROR state |
| M5 (Clock monitoring) | C1 (DC disclaimer) | Related to coverage scope |
| M18 (ASIL table) | M4 (DUAL_RAIL_EN security) | Should be consistent |

### Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Fix introduces new inconsistencies | Medium | High | Review after each batch of fixes |
| Timeline slips | Low | Medium | Prioritize P0/P1, defer P2/P3 if needed |
| Agent disagreement on fix approach | Low | High | Escalate to PM Agent for decision |

---

## Appendix: Related Documents

| Document | Path | Version |
|----------|------|---------|
| Design Specification | `Database/Docs/Design/Design_Specification.md` | v1.0 (to be updated to v1.1) |
| EDR Issue Tracker | `ProjectMgmt/Reviews/EDR/EDR_Issue_Tracker.md` | v1.0 |
| Architecture Spec | `Database/Docs/Arch/Architecture_Spec.md` | v1.1 |
| FMEDA Report | `Database/Docs/FuSa/FMEDA_Report.md` | v1.1 |
| Verification Plan | `Database/Docs/Verification/Verification_Plan.md` | v1.0 |

---

## Revision History

| Version | Date | Description | Author |
|---------|------|-------------|--------|
| v1.0 | 2026-04-01 | Initial remediation plan | Design Agent |

---

*End of EDR Remediation Plan v1.0*

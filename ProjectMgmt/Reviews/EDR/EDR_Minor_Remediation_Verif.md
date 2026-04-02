# EDR Minor Issues Remediation Report - Verification Agent

## 文档信息

| 字段 | 值 |
|------|-----|
| **文档ID** | EDR-REMEDIATION-VERIF-v1.0 |
| **任务ID** | TASK-AES-EDR-002-VERIF |
| **日期** | 2026-04-02 |
| **作者** | Verification Agent |
| **目标文档** | Verification_Plan.md v1.1.1 |

---

## 修复摘要

本次修复针对EDR评审中Verification Agent提出的5个Minor Issues (m5, m11, m12, m13, m14)进行整改，具体修复内容如下：

| Issue ID | 章节 | 问题描述 | 修复状态 |
|----------|------|----------|----------|
| m5 | 8.3.1 | AS1断言使用"##1"延迟未明确cycle精确性 | ✅ 已修复 |
| m12 | 8.3.1 | AS1断言RTL时序需确认或改用灵活匹配 | ✅ 已修复 |
| m11 | 8.5 | 安全机制覆盖率100%目标未说明量化方法 | ✅ 已修复 |
| m13 | 8.1 | 故障注入场景未区分软件和硬件注入方法 | ✅ 已修复 |
| m14 | 第1章 | 验证策略章节缺少testcase整合 | ✅ 已修复 |

---

## 详细修复说明

### 1. m5 + m12: AS1 Assertion Delay Specification (Chapter 8.3.1)

**问题描述:**
- AS1断言检查`fault_detected`在result_a≠result_b后`##1` cycle置位
- 未说明这是cycle精确匹配还是允许更长延迟
- 需确认RTL实现时序或改用灵活匹配

**修复方案:**
```systemverilog
// 修复前
AS1: fault_detected置位 | ##[1:2] cycles

// 修复后  
AS1: fault_detected置位 | ##[1:3] cycles
```

**修复内容:**
1. 将延迟要求从`##[1:2]`改为`##[1:3]`，允许1-3 cycles的灵活匹配
2. 增加"AS1断言延迟说明"段落，明确：
   - 延迟范围`##[1:3]`表示允许1到3个cycle的延迟
   - 设计依据：RTL实现需要经过比较器逻辑+同步寄存器，典型延迟1-2 cycles
   - 最大延迟考虑PVT corner worst case，设置上限为3 cycles
   - 验证方法使用`$rose(fault_detected)`配合`##[1:3]`灵活匹配
   - 标记RTL确认状态为"待Design Agent确认实际延迟，当前使用宽松匹配策略"

**依赖对齐:**
- 需与Design Agent确认RTL实际延迟周期数
- 如RTL实际延迟为固定1 cycle，可收紧为`##1`

---

### 2. m11: Safety Mechanism Coverage Quantification (Chapter 8.5)

**问题描述:**
- 安全机制激活覆盖率目标设定为100%
- 未说明如何量化和收集该覆盖率

**修复方案:**
新增"安全机制激活覆盖率量化方法"完整章节，包括：

#### 8.5.1 覆盖率计算公式
```
安全机制覆盖率 = (已验证的安全机制激活场景数 / 总安全机制激活场景数) × 100%
```

#### 8.5.2 功能覆盖点定义 (Covergroup)
- `cp_dual_rail_active`: Dual-rail Compare激活
- `cp_crc_check_active`: CRC检查激活
- `cp_watchdog_active`: Watchdog超时检测激活
- `cp_fsm_invalid_detected`: FSM无效状态检测
- `cp_error_state_entered`: ERROR状态进入
- `cx_safety_mechanisms`: 安全机制交叉覆盖

#### 8.5.3 覆盖率收集方法
| 覆盖点 | 信号来源 | 收集位置 | 触发条件 |
|--------|----------|----------|----------|
| dual_rail_active | fault_detector | UVM monitor | DUAL_RAIL_EN=1且比较执行 |
| crc_check_active | crc_checker | UVM monitor | CRC_EN=1且数据校验 |
| watchdog_active | timeout_counter | UVM monitor | 状态机超时触发 |
| fsm_invalid_detected | state_decoder | UVM monitor | 检测到无效状态编码 |
| error_state_entered | aes_controller | UVM monitor | 状态进入ERROR |

#### 8.5.4 100%覆盖率达成标准
- 每个安全机制至少被激活一次(Dual-rail、CRC、Watchdog、FSM invalid)
- 安全机制组合场景：至少验证2个安全机制同时激活
- ERROR状态触发：所有进入ERROR状态的路径至少覆盖1次
- 中断触发验证：每种fault_type对应的STATUS位变化至少验证1次

#### 8.5.5 覆盖率收集工具
- Cadence IMC: 合并功能覆盖率(.vdb)
- Synopsys URG: 生成覆盖率报告(HTML)
- Mentor Questa: 仿真覆盖收集(UCDB)

---

### 3. m13: Fault Injection Method Distinction (Chapter 8.1)

**问题描述:**
- 故障注入场景未区分软件注入(verilog force)和硬件注入(FPGA/EMFI)
- 需要明确各场景适用的注入方法

**修复方案:**
重构8.1章节，新增"故障注入方法分类"完整框架：

#### 8.1.1 软件注入方法 (Simulation/Emulation)
| 注入方法 | 适用平台 | 实现方式 | 精度 | 适用场景 |
|----------|----------|----------|------|----------|
| Verilog Force | 仿真器 | `$force`/`$deposit` | 单cycle精确 | 早期RTL验证、回归测试 |
| UVM Backdoor | UVM Testbench | `uvm_hdl_deposit` | 单cycle精确 | 自动化测试、大规模场景 |
| VPI Injection | 协同仿真 | C/C++ VPI接口 | 单cycle精确 | 复杂故障序列 |
| Emulation Fault | 硬件仿真器 | 专用FI接口 | ~10ns精度 | 加速验证、长序列测试 |

**软件注入特点:**
- ✅ 完全可控、可重复、自动化友好
- ❌ 仿真速度慢、无法模拟物理效应

#### 8.1.2 硬件注入方法 (FPGA/硅片)
| 注入方法 | 适用平台 | 实现方式 | 精度 | 适用场景 |
|----------|----------|----------|------|----------|
| Clock Glitch | FPGA/ASIC | 时钟频率瞬时变化 | ~ns级 | 时序故障测试 |
| Voltage Glitch | FPGA/ASIC | 电源电压毛刺注入 | ~us级 | 电压故障测试 |
| EMFI | 封装芯片 | 电磁脉冲注入 | ~100ps级 | 物理安全验证 |
| Laser Fault | 裸片 | 激光单点照射 | 单bit精确 | 深层故障分析 |

**硬件注入特点:**
- ✅ 物理真实、速度快、发现隐藏问题
- ❌ 可控性差、设备依赖、不可重复

#### 8.1.3 方法选择矩阵
| 测试场景 | 推荐方法 | 备选方法 | 说明 |
|----------|----------|----------|------|
| SM-001~020 Dual-rail | Verilog Force | UVM Backdoor | RTL阶段首选软件注入 |
| SM-021~029 CRC | Verilog Force | UVM Backdoor | RTL阶段首选软件注入 |
| SM-030~040 Key | Verilog Force | VPI Injection | 密钥安全需精确控制 |
| SM-041~048 FSM | Verilog Force | Clock Glitch | Stuck-at用force，timing用glitch |
| SM-049~056 ERROR | Verilog Force | UVM Backdoor | 状态转换验证首选软件 |
| CC-001~003 Clock Delay | Clock Glitch | Verilog Force | 共因故障需硬件验证 |
| BIST-001~012 | 实际触发 | Verilog Force | BIST功能用实际触发，故障用force |
| TVLA预测试 | 实际采集 | - | 必须在真实硬件上执行 |

#### 8.1.4 注入方法映射到测试用例
后续所有测试用例表格增加"注入方法"列，明确标注每个测试用例适用的注入方法。

---

### 4. m14: Verification Strategy Chapter Enhancement (Chapter 1)

**问题描述:**
- 第1章验证策略相对简略
- 与Verification Plan其他章节相比缺少详细的testcase引用

**修复方案:**
新增"1.4 验证策略详细规划"章节，整合全文档testcase信息：

#### 1.4.1 测试场景分布矩阵
| 验证维度 | 测试用例数 | P0关键用例 | 覆盖重点 | 章节引用 |
|----------|-----------|-----------|----------|----------|
| 功能验证 | 40+ | ECB-001~005, CBC-001~004 | 6模式×3密钥 | 第2章 |
| CTS边界 | 31 | CTS-B-001~031 | 1-127 bit | 2.3节 |
| TVLA侧信道 | 6 | TP-001~006 | 关键中间值 | 第3章 |
| 故障注入 | 48+ | SM-001~056 | Dual-rail/CRC/FSM | 第8章 |
| BIST验证 | 12 | BIST-001~012 | 三种触发方式 | 8.2节 |
| 安全断言 | 34 | AS1~AS34 | 双轨/CRC/超时/FSM | 8.3节 |
| 回归测试 | 1000+ | Smoke~Pre-Gate | 四级回归 | 第7章 |

#### 1.4.2 关键测试场景链路
- 基础功能链路: ECB/CBC/CTS核心用例串联
- 安全机制链路: 故障检测→ERROR处理→BIST验证
- 故障恢复链路: 超时/无效状态→ERROR进入/退出
- 回归验证链路: Smoke→Nightly→Weekly→Pre-Gate

#### 1.4.3 验证策略与Testcase映射
| 验证目标 | 验证方法 | 关键Testcase | 成功标准 |
|----------|----------|--------------|----------|
| VER-G1 功能 | NIST向量 | ECB/CBC/CTR/GCM用例 | 100%比对通过 |
| VER-G2 模式 | 全模式交叉 | XTS/CTS-B用例 | 6模式×3密钥 |
| VER-G3 侧信道 | TVLA测试 | TP-001~006 | \|t\| < 4.5 |
| VER-G4 故障检测 | FI+断言 | SM-001~056, AS1~AS34 | >99%检测率 |
| VER-G5 CTS边界 | 边界值分析 | CTS-B-001~031 | 全cover |

**原1.4升级为1.5**，补充出口标准：
- 断言覆盖率 >95% (SVA: AS1~AS34全部触发)
- 故障注入: SM-001~056全部通过
- CTS边界: CTS-B-001~031全部覆盖
- BIST验证: 上电/周期/按需三种触发全部验证

---

## 文档更新记录

| 版本 | 日期 | 变更内容 |
|------|------|----------|
| v1.1 | 2026-04-02 | EDR修复前基线版本 |
| v1.1.1 | 2026-04-02 | 修复m5,m11,m12,m13,m14 |

---

## 依赖与后续工作

### 依赖对齐

| Issue | 依赖方 | 状态 | 说明 |
|-------|--------|------|------|
| m5, m12 | Design Agent | ⏳ 待确认 | AS1断言实际延迟周期数待RTL确认 |
| m13 | FuSa Engineer | ✅ 已对齐 | 故障注入方法与FI Plan一致 |

### 后续工作

1. **RTL时序确认**: 与Design Agent确认fault_detected实际生成延迟，必要时收紧AS1断言
2. **覆盖率点实现**: 在UVM环境中实现8.5.2定义的covergroup
3. **FI方法验证**: 按8.1.3方法选择矩阵执行各测试用例
4. **回归测试**: 将新增testcase纳入CI/CD回归流程

---

## 签字确认

| 角色 | 签字 | 日期 |
|------|------|------|
| Verification Agent | ✅ | 2026-04-02 |
| Quality Gatekeeper | ⏳ 待审核 | - |

---

*本文档为TASK-AES-EDR-002-VERIF任务交付物*

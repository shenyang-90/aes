# EDR Issue Tracker

## Document Information
- **Version**: v1.0
- **Date**: 2026-04-01
- **Target Document**: Design Spec v1.0
- **Status**: EDR Remediation Phase

---

## Summary

| Severity | Count | Status |
|----------|-------|--------|
| Critical | 1 | 🔴 Must Fix |
| Major | 17 | 🟡 Should Fix |
| Minor | 20 | 🟢 Optional |
| **Total** | **38** | - |

---

## Critical Issues (必须修复)

### ISSUE-001: 99% DC Coverage Claim vs FMEDA Status Conflict
- **ID**: C1
- **Source**: FuSa Engineer
- **Chapter**: 6.2 Dual-Rail, 6.4 FMEDA指标
- **Description**: 
  Design Spec声明Dual-Rail诊断覆盖率>99%，但FMEDA报告明确说明这是"基于设计估算，非实测数据"，且状态为"待硬件验证"。这种声明与验证状态不一致，可能误导读者认为安全机制已充分验证。
- **Impact**: 
  - 误导功能安全评估
  - EDR无法通过
  - 可能导致ASIL-D合规性问题
- **Proposed Fix**: 
  1. 将">99%"改为"设计目标: 99% (待故障注入验证)"
  2. 添加免责声明说明当前为设计估算值
  3. 增加实际验证后的更新机制说明
- **Related Issues**: FuSa-M1, FuSa-M4

---

## Major Issues (强烈建议修复)

### ISSUE-002: MODE Field Definition Inconsistency
- **ID**: M1
- **Source**: Design Agent
- **Chapter**: 4.2 CTRL寄存器
- **Description**:
  MODE字段在文档中有两处不同定义：
  1. 寄存器表格中说明"[8:1]是MODE[7:0]"
  2. 位域表格中说明MODE[0]是ENCRYPT，MODE[3:1]是OP_MODE
  两处定义存在冲突和不一致。
- **Impact**:
  - 可能导致RTL实现与文档不符
  - 软件编程接口定义模糊
- **Proposed Fix**:
  1. 统一采用详细位域定义（MODE[0]=ENCRYPT, MODE[3:1]=OP_MODE）
  2. 删除[8:1]的模糊描述
  3. 更新寄存器表格与位域表格保持一致
- **Related Issues**: Architect-M2 (寄存器定义相关)

### ISSUE-003: ERROR State Missing in FSM Diagram
- **ID**: M2
- **Source**: Design Agent
- **Chapter**: 5.4.2 状态机, 5.4.2 状态定义表
- **Description**:
  ERROR状态(3'b111)在状态定义表中有定义，但在状态机架构图中未显示，且未描述进入ERROR状态后的恢复机制（自动清零/手动清零）。
- **Impact**:
  - 状态机实现不完整
  - 错误恢复流程不明确
- **Proposed Fix**:
  1. 在状态机架构图中添加ERROR状态
  2. 添加从ERROR状态到IDLE的转换路径
  3. 补充错误恢复流程说明（软件清零步骤）
- **Related Issues**: Verification-M5 (FSM timeout场景)

### ISSUE-004: Clock Delay Cycles Not Specified
- **ID**: M3
- **Source**: Design Agent
- **Chapter**: 6.2.4 时钟延迟实现（共因故障防护）
- **Description**:
  代码示例中提到"delay_cnt < 2'd2"，但未明确说明这是几个cycle的延迟，也未解释为何选择该延迟量。
- **Impact**:
  - 共因故障防护的定量分析不完整
  - 实现时难以确定正确的延迟量
- **Proposed Fix**:
  1. 明确说明延迟为2个cycle
  2. 补充延迟选择的定量分析（时钟抖动、毛刺持续时间等）
  3. 说明Core A结果需要相应延迟对齐
- **Related Issues**: FuSa-M4 (共因故障防护缺口)

### ISSUE-005: Dynamic DUAL_RAIL_EN Disable Security Risk
- **ID**: M4 (FuSa-M1)
- **Source**: FuSa Engineer
- **Chapter**: 6.2.3 可配置性设计, 4.2 CTRL寄存器
- **Description**:
  运行时DUAL_RAIL_EN动态禁用功能存在安全风险：软件可能意外禁用安全机制，或在特权模式下被恶意禁用。
- **Impact**:
  - ASIL-D安全机制可被意外禁用
  - 不符合功能安全要求
- **Proposed Fix**:
  1. 增加安全概念说明：动态禁用仅在特权模式允许
  2. 或添加密钥授权机制（写特定解锁序列）
  3. 建议增加状态寄存器位指示当前安全模式（STATUS[10]: LOCKSTEP_ACTIVE）
- **Related Issues**: FuSa-C1 (安全声明相关)

### ISSUE-006: Common Cause Fault Protection Gap - Clock Source
- **ID**: M5 (FuSa-M2)
- **Source**: FuSa Engineer
- **Chapter**: 6.2.4 时钟延迟实现
- **Description**:
  共因故障防护方案中，Core B使用延迟数据但相同时钟。若时钟源故障（如时钟毛刺同时影响Core A和B），则延迟方案无法检测。
- **Impact**:
  - 时钟源共因故障无法被检测
  - SPFM指标可能受影响
- **Proposed Fix**:
  1. 补充时钟监控方案（如时钟双采样、独立时钟源比较）
  2. 或说明该风险已通过其他机制覆盖（如独立WDT）
  3. 在FMEDA中评估该风险的残余失效率
- **Related Issues**: M3 (时钟延迟说明), FuSa-C1

### ISSUE-007: Periodic BIST Detection Latency Not Analyzed
- **ID**: M6 (FuSa-M3)
- **Source**: FuSa Engineer
- **Chapter**: 6.3.3 BIST触发策略
- **Description**:
  周期性自检建议"每100ms-1s"触发，但未说明如何确保在故障发生时及时检测，缺少故障检测延迟分析。
- **Impact**:
  - 故障检测延迟无法满足FTTI要求
  - SPFM计算不完整
- **Proposed Fix**:
  1. 补充安全概念：周期性BIST的故障检测延迟分析
  2. 计算最坏情况检测延迟（考虑BIST执行时间）
  3. 建议采用连续后台自检或缩短周期
  4. 说明与FTTI的关系
- **Related Issues**: FuSa-m3 (BIST代码完整性)

### ISSUE-008: FAULT_DETECTED Bit Type Not Specified
- **ID**: M7 (FuSa-M4)
- **Source**: FuSa Engineer
- **Chapter**: 4.3 STATUS寄存器
- **Description**:
  FAULT_DETECTED位(位4)定义为"故障检测标志"，但未说明是sticky位(需软件清零)还是实时位(自动清零)。
- **Impact**:
  - 软件接口定义不完整
  - 可能错过瞬态故障
- **Proposed Fix**:
  1. 明确为sticky位（需软件清零）
  2. 添加清零机制说明：写1清零或写STATUS寄存器清零
  3. 说明清零前软件应保存故障信息
- **Related Issues**: AS1断言定义

### ISSUE-009: Fault Type Encoding 3'b111 Undefined
- **ID**: M8 (FuSa-M5)
- **Source**: FuSa Engineer
- **Chapter**: 6.2.6 故障类型编码
- **Description**:
  3-bit编码定义了8种故障类型(000-111)，但文档中仅使用了7种(000-110)，111编码用途未说明。
- **Impact**:
  - 解码存在歧义
  - 可能用于未来扩展但未说明
- **Proposed Fix**:
  1. 明确111编码的用途（如：多故障同时发生、保留、或未定义故障）
  2. 或说明为保留位，软件应忽略
  3. 补充解码逻辑说明
- **Related Issues**: 6.2.6节编码表

### ISSUE-010: UVM Environment Integration Test Missing
- **ID**: M9 (Verif-M1)
- **Source**: Verification Agent
- **Chapter**: 9.1 验证范围
- **Description**:
  验证策略章节缺少UVM环境集成测试的描述，未确认APB/AXI4-Stream agent与DUT的兼容性。
- **Impact**:
  - 验证环境开发缺少指导
  - 可能遗漏集成级问题
- **Proposed Fix**:
  1. 补充UVM agent集成测试计划
  2. 说明APB agent配置（地址宽度、时序）
  3. 说明AXI4-Stream agent配置（数据宽度、握手机制）
  4. 增加集成测试checklist
- **Related Issues**: Verif-m4 (验证策略完整性)

### ISSUE-011: Fault Injection Scene Count Mismatch
- **ID**: M10 (Verif-M2)
- **Source**: Verification Agent
- **Chapter**: 9.3 故障注入测试场景
- **Description**:
  故障注入场景表(FI-001~005)仅5个场景，远少于Verification Plan中的48个场景(SM-001~048)。
- **Impact**:
  - Design Spec与Verification Plan不一致
  - 验证覆盖范围不明确
- **Proposed Fix**:
  1. 扩展故障注入场景表至与Verification Plan一致
  2. 或明确说明Design Spec中的是高优先级子集
  3. 添加与Verification Plan的交叉引用
  4. 说明剩余场景的实现计划
- **Related Issues**: Verif-m3 (注入方法区分)

### ISSUE-012: Assertion List Incomplete
- **ID**: M11 (Verif-M3)
- **Source**: Verification Agent
- **Chapter**: 9.4 断言检查
- **Description**:
  仅提供了2个SVA断言示例(AS1, AS2)，未覆盖所有安全机制。缺少Verification Plan第8章的AS27~AS34断言。
- **Impact**:
  - 断言覆盖不完整
  - 无法验证所有安全属性
- **Proposed Fix**:
  1. 补充完整的断言列表（至少覆盖Verification Plan第8章的AS27~AS34）
  2. 按安全机制分类断言
  3. 增加断言与验证计划的交叉引用表
- **Related Issues**: Verif-m2 (AS1延迟确认)

### ISSUE-013: Verification Checklist Status Ambiguous
- **ID**: M12 (Verif-M4)
- **Source**: Verification Agent
- **Chapter**: 9.5 验证检查清单
- **Description**:
  所有检查项状态均为"☐"(未完成)，未明确这是需要在验证阶段完成的checklist，且缺少时间计划。
- **Impact**:
  - 验证计划不明确
  - 进度无法跟踪
- **Proposed Fix**:
  1. 明确说明这是需要在验证阶段完成的checklist
  2. 添加计划完成时间列
  3. 分配责任人
  4. 更新状态跟踪机制
- **Related Issues**: M9, M10, M11

### ISSUE-014: FSM Definition vs Verification Plan Consistency
- **ID**: M13 (Verif-M5)
- **Source**: Verification Agent
- **Chapter**: 5.4.2 状态机
- **Description**:
  状态机定义与Verification Plan中的FSM timeout测试场景(SM-041~048)可能存在差异，状态编码一致性未确认。
- **Impact**:
  - 验证场景与设计不一致
  - 可能导致验证遗漏或错误
- **Proposed Fix**:
  1. 确认状态机状态编码与Verification Plan SM-041~048的一致性
  2. 添加状态编码与验证场景映射表
  3. 更新Verification Plan或Design Spec以保持一致
- **Related Issues**: M2 (ERROR状态)

### ISSUE-015: Module Naming Inconsistency - sbox_ti vs sbox_masked
- **ID**: M14 (Arch-M1)
- **Source**: IP Architect
- **Chapter**: 2.2 模块划分
- **Description**:
  Architecture Spec中使用`sbox_masked`，但Design Spec中使用`sbox_ti`，命名不一致。
- **Impact**:
  - 文档间不一致
  - 可能导致实现混淆
- **Proposed Fix**:
  1. 统一模块命名为`sbox_masked`
  2. 在模块描述中说明采用TI(Threshold Implementation)实现
  3. 检查全文替换所有出现位置
- **Related Issues**: 2.2节模块划分表

### ISSUE-016: Area Estimation Data Inconsistency
- **ID**: M15 (Arch-M2)
- **Source**: IP Architect
- **Chapter**: 8.6 Lockstep模式功耗对比, 2.2 模块划分
- **Description**:
  单核模式面积估算为~35K gates，但各模块面积之和(3+30+8+5+8+4+3+2+1+0.5)=64.5K，数据矛盾。
- **Impact**:
  - 面积估算不可信
  - 影响资源规划
- **Proposed Fix**:
  1. 澄清面积估算：区分综合后净面积与门数估算（含布线）
  2. 提供面积分解表，说明各配置下的实际面积
  3. 统一面积估算方法（建议采用综合后面积）
- **Related Issues**: Arch-m2 (面积范围说明)

### ISSUE-017: Clock Domain Relationship Unclear
- **ID**: M16 (Arch-M3)
- **Source**: IP Architect
- **Chapter**: 7.1 时钟架构
- **Description**:
  时钟架构图显示CG_CORE和CG_REG分离，但未说明两路时钟的关系（同步/异步），也未说明时钟域交叉处理方案。
- **Impact**:
  - 时钟设计不明确
  - CDC问题风险
- **Proposed Fix**:
  1. 明确时钟关系：建议使用同源时钟
  2. 说明时钟域交叉处理方案（如有）
  3. 添加时钟树综合建议
- **Related Issues**: Design-m3 (时钟偏斜)

### ISSUE-018: ASIL Level Assignment Not Documented
- **ID**: M17 (Arch-M4)
- **Source**: IP Architect
- **Chapter**: 2.1 顶层架构, 2.2 模块划分
- **Description**:
  Architecture Spec中mode_controller为ASIL-B，但在Design Spec中未明确说明各模块的ASIL等级分配。
- **Impact**:
  - 安全目标追溯不完整
  - ASIL分解不清晰
- **Proposed Fix**:
  1. 补充各模块的ASIL等级分配表
  2. 说明ASIL分解依据
  3. 增加与安全目标的追溯关系
- **Related Issues**: 2.2节模块划分表

### ISSUE-019: Throughput Test Conditions Not Specified
- **ID**: M18 (Arch-M5)
- **Source**: IP Architect
- **Chapter**: 1.4 关键特性
- **Description**:
  吞吐率指标">1 Gbps @ 100MHz"未说明测试条件（模式/密钥长度）。
- **Impact**:
  - 性能指标不明确
  - 验证基准不清晰
- **Proposed Fix**:
  1. 明确吞吐率测试基准：注明"ECB模式, AES-128"
  2. 或提供各模式吞吐率对比表
  3. 说明峰值/平均吞吐率区别
- **Related Issues**: 1.4节关键特性表

---

## Minor Issues (可选修复)

### ISSUE-020: S-Box Area Clarification Needed
- **ID**: m1
- **Source**: Design Agent
- **Chapter**: 2.2 模块划分
- **Description**: sbox_ti模块面积估算为8K gates，但16个S-Box每个都8K的话总共128K，与整体<50K矛盾。
- **Proposed Fix**: 确认是每个S-Box还是S-Box阵列总面积，建议澄清说明。

### ISSUE-021: CTS State Branch Handling Not Shown
- **ID**: m2
- **Source**: Design Agent
- **Chapter**: 5.2.5 CTS Mode
- **Description**: CTS状态机图中CTS_LAST_FULL和CTS_LAST_PART分支后未显示具体处理差异。
- **Proposed Fix**: 补充两个分支的具体处理流程差异说明。

### ISSUE-022: Clock Skew in Gated Clock Hierarchy
- **ID**: m3
- **Source**: Design Agent
- **Chapter**: 7.2 时钟门控层次
- **Description**: L2/L3级门控信号依赖前级门控后的时钟，可能引入时钟偏斜问题。
- **Proposed Fix**: 建议说明时钟树综合时对门控时钟的处理建议。

### ISSUE-023: Lockstep Power Quantification Missing
- **ID**: m4
- **Source**: Design Agent
- **Chapter**: 8.6 Lockstep模式功耗对比
- **Description**: 表格中"双核禁用"和"双核启用"的功耗描述不够量化。
- **Proposed Fix**: 建议给出具体功耗数值或相对于基准的百分比。

### ISSUE-024: AS1 Assertion Delay Specification
- **ID**: m5
- **Source**: Design Agent
- **Chapter**: 9.4 断言检查
- **Description**: AS1断言使用"##1"延迟，但未说明这是cycle精确还是允许更长的延迟。
- **Proposed Fix**: 明确延迟要求，或改用[*1:$]表示1到任意cycle。

### ISSUE-025: FMEDA DC Update Mechanism
- **ID**: m6 (FuSa-m1)
- **Source**: FuSa Engineer
- **Chapter**: 6.4 FMEDA指标
- **Description**: 表格中安全机制DC为设计目标值，建议增加实际验证后的更新机制。
- **Proposed Fix**: 增加注释说明：实际DC值将在故障注入验证后更新。

### ISSUE-026: Fault Detection Path Timing Not Detailed
- **ID**: m7 (FuSa-m2)
- **Source**: FuSa Engineer
- **Chapter**: 6.2.2 实现架构
- **Description**: Fault Detector输出到总线的路径未详细说明。
- **Proposed Fix**: 补充故障检测到中断/错误输出的完整路径时序。

### ISSUE-027: Timeout Detection Rate Explanation
- **ID**: m8 (FuSa-m3)
- **Source**: FuSa Engineer
- **Chapter**: 5.3.2 故障检测
- **Description**: Timeout检测率90%低于其他机制99%，建议说明原因。
- **Proposed Fix**: 补充Timeout检测率计算依据（如：超时阈值设置考虑）。

### ISSUE-028: BIST Code Example Incomplete
- **ID**: m9 (FuSa-m4)
- **Source**: FuSa Engineer
- **Chapter**: 6.3.2 BIST实现
- **Description**: BIST代码示例中的状态机实现不完整(注释"...")。
- **Proposed Fix**: 补充完整的状态机代码或伪代码。

### ISSUE-029: BIST_FAIL_ID Mapping Table Missing
- **ID**: m10 (FuSa-m5)
- **Source**: FuSa Engineer
- **Chapter**: 4.11 BIST_STATUS寄存器
- **Description**: FAIL_ID字段(位4:2)说明"失败的测试项ID"，但未定义ID映射表。
- **Proposed Fix**: 补充BIST测试项ID映射表（如：0=Lockstep, 1=CRC, 2=Timeout）。

### ISSUE-030: Safety Mechanism Coverage Quantification
- **ID**: m11 (Verif-m1)
- **Source**: Verification Agent
- **Chapter**: 9.2 测试覆盖目标
- **Description**: 安全机制激活覆盖率目标100%，但未说明如何量化。
- **Proposed Fix**: 建议增加覆盖率收集方法（如功能覆盖率点定义）。

### ISSUE-031: AS1 Assertion RTL Timing Confirmation
- **ID**: m12 (Verif-m2)
- **Source**: Verification Agent
- **Chapter**: 9.4 断言检查
- **Description**: AS1断言检查fault_detected在结果不匹配后##1 cycle置位，需确认RTL实现时序。
- **Proposed Fix**: 建议与RTL设计确认实际延迟cycle数，或改用灵活匹配。

### ISSUE-032: Fault Injection Method Distinction
- **ID**: m13 (Verif-m3)
- **Source**: Verification Agent
- **Chapter**: 9.3 故障注入测试场景
- **Description**: 故障注入场景未区分软件注入(verilog force)和硬件注入(FPGA/EMFI)。
- **Proposed Fix**: 明确各场景适用的注入方法。

### ISSUE-033: Verification Strategy Chapter Brief
- **ID**: m14 (Verif-m4)
- **Source**: Verification Agent
- **Chapter**: 第9章整体
- **Description**: 验证策略章节相对简略，与Verification Plan相比缺少详细testcase。
- **Proposed Fix**: 考虑将Verification Plan的testcase引用或摘要整合到Design Spec。

### ISSUE-034: AXI4-Stream Timing Diagram Missing
- **ID**: m15 (Verif-m5)
- **Source**: Verification Agent
- **Chapter**: 3.1 AXI4-Stream数据接口
- **Description**: 接口时序图缺失(如valid/ready握手时序)。
- **Proposed Fix**: 补充关键接口时序图，便于验证环境开发。

### ISSUE-035: XTS Operator Definition Missing
- **ID**: m16 (Arch-m1)
- **Source**: IP Architect
- **Chapter**: 5.2.4 XTS Mode
- **Description**: XTS公式中使用的⊗符号未在文档中定义（是GF乘法还是普通乘法）。
- **Proposed Fix**: 明确运算符定义，建议采用标准符号或添加说明。

### ISSUE-036: Area Estimation Confidence Interval
- **ID**: m17 (Arch-m2)
- **Source**: IP Architect
- **Chapter**: 2.2 模块划分
- **Description**: 模块面积估算缺乏confidence interval，建议增加范围说明。
- **Proposed Fix**: 增加面积估算范围，如"30K±5K gates"，并说明估算方法。

### ISSUE-037: L3 Clock Gating Enable Logic Not Detailed
- **ID**: m18 (Arch-m3)
- **Source**: IP Architect
- **Chapter**: 7.2 时钟门控层次
- **Description**: L3级门控(state_clk_en等)的使能信号生成逻辑未详细说明。
- **Proposed Fix**: 补充L3门控使能信号的来源和生成逻辑。

### ISSUE-038: Power PVT Conditions Missing
- **ID**: m19 (Arch-m4)
- **Source**: IP Architect
- **Chapter**: 8.5 功耗估计
- **Description**: 功耗数据缺少工艺/电压/温度(PVT)条件说明。
- **Proposed Fix**: 增加PVT条件，如"典型工艺角, 1.0V, 25°C"。

### ISSUE-039: Patent Technical Details Insufficient
- **ID**: m20 (Arch-m5)
- **Source**: IP Architect
- **Chapter**: 10.1 潜在专利申请点
- **Description**: 专利申请点描述较笼统，建议增加技术细节。
- **Proposed Fix**: 补充CTS状态机和TI-SBox的具体技术创新点。

---

## Issue Cross-Reference Matrix

| Issue ID | Related Issues | Category |
|----------|----------------|----------|
| C1 | M4, M5 | Safety Analysis |
| M1 | M14 | Design Definition |
| M2 | M13 | Design Definition |
| M3 | M5 | Design Definition |
| M4 | C1, M5 | Safety Analysis |
| M5 | C1, M3, M6 | Safety Analysis |
| M6 | C1 | Safety Analysis |
| M7 | - | Design Definition |
| M8 | - | Design Definition |
| M9 | m11, m12, m13, m14 | Verification Method |
| M10 | m13 | Data Consistency |
| M11 | m12, m14 | Data Consistency |
| M12 | m11, m14 | Data Consistency |
| M13 | M2 | Data Consistency |
| M14 | M1, m17 | Data Consistency |
| M15 | m17, M18 | Data Consistency |
| M16 | m3, M15 | Data Consistency |
| M17 | m3 | Data Consistency |
| M18 | M15 | Safety Analysis |

---

## Revision History

| Version | Date | Description | Author |
|---------|------|-------------|--------|
| v1.0 | 2026-04-01 | Initial issue tracker from EDR reviews | Design Agent |

---

*End of EDR Issue Tracker v1.0*

# TASK: EDR Minor Issues Remediation

## 任务信息

| 字段 | 值 |
|------|-----|
| **任务ID** | TASK-AES-EDR-002 |
| **任务名称** | EDR Minor Issues Remediation |
| **负责人** | Design Agent |
| **优先级** | P2 |
| **截止日期** | 2026-04-04 |
| **状态** | 🟡 ASSIGNED |

---

## 任务背景

EDR (Engineering Design Review) 已完成 Critical 和 Major 问题的修复，但仍有 20 个 Minor 问题待处理。根据项目质量要求，Minor 问题也需要修复以确保文档完整性。

**参考文档**:
- Issue Tracker: `ProjectMgmt/Reviews/EDR/EDR_Issue_Tracker.md`
- Design Spec: `Database/Docs/Design/Design_Specification.md` (v1.1)

---

## 待修复 Minor Issues (20个)

### Design 相关 (m1-m4)

#### m1: S-Box Area Clarification
- **位置**: Chapter 2.2 模块划分
- **问题**: sbox_ti模块面积估算为8K gates，但16个S-Box每个都8K的话总共128K，与整体<50K矛盾
- **修复要求**: 确认是每个S-Box还是S-Box阵列总面积，建议澄清说明

#### m2: CTS State Branch Handling
- **位置**: Chapter 5.2.5 CTS Mode
- **问题**: CTS状态机图中CTS_LAST_FULL和CTS_LAST_PART分支后未显示具体处理差异
- **修复要求**: 补充两个分支的具体处理流程差异说明

#### m3: Clock Skew in Gated Clock Hierarchy
- **位置**: Chapter 7.2 时钟门控层次
- **问题**: L2/L3级门控信号依赖前级门控后的时钟，可能引入时钟偏斜问题
- **修复要求**: 建议说明时钟树综合时对门控时钟的处理建议

#### m4: Lockstep Power Quantification
- **位置**: Chapter 8.6 Lockstep模式功耗对比
- **问题**: 表格中"双核禁用"和"双核启用"的功耗描述不够量化
- **修复要求**: 建议给出具体功耗数值或相对于基准的百分比

### Verification 相关 (m5-m13)

#### m5: AS1 Assertion Delay Specification
- **位置**: Chapter 9.4 断言检查
- **问题**: AS1断言使用"##1"延迟，但未说明这是cycle精确还是允许更长的延迟
- **修复要求**: 明确延迟要求，或改用[*1:$]表示1到任意cycle

#### m6: FMEDA DC Update Mechanism
- **位置**: Chapter 6.4 FMEDA指标
- **问题**: 表格中安全机制DC为设计目标值，建议增加实际验证后的更新机制
- **修复要求**: 增加注释说明：实际DC值将在故障注入验证后更新

#### m7: Fault Detection Path Timing
- **位置**: Chapter 6.2.2 实现架构
- **问题**: Fault Detector输出到总线的路径未详细说明
- **修复要求**: 补充故障检测到中断/错误输出的完整路径时序

#### m8: Timeout Detection Rate Explanation
- **位置**: Chapter 5.3.2 故障检测
- **问题**: Timeout检测率90%低于其他机制99%，建议说明原因
- **修复要求**: 补充Timeout检测率计算依据（如：超时阈值设置考虑）

#### m9: BIST Code Example Incomplete
- **位置**: Chapter 6.3.2 BIST实现
- **问题**: BIST代码示例中的状态机实现不完整(注释"...")
- **修复要求**: 补充完整的状态机代码或伪代码

#### m10: BIST_FAIL_ID Mapping Table
- **位置**: Chapter 4.11 BIST_STATUS寄存器
- **问题**: FAIL_ID字段(位4:2)说明"失败的测试项ID"，但未定义ID映射表
- **修复要求**: 补充BIST测试项ID映射表（如：0=Lockstep, 1=CRC, 2=Timeout）

#### m11: Safety Mechanism Coverage Quantification
- **位置**: Chapter 9.2 测试覆盖目标
- **问题**: 安全机制激活覆盖率目标100%，但未说明如何量化
- **修复要求**: 建议增加覆盖率收集方法（如功能覆盖率点定义）

#### m12: AS1 Assertion RTL Timing Confirmation
- **位置**: Chapter 9.4 断言检查
- **问题**: AS1断言检查fault_detected在结果不匹配后##1 cycle置位，需确认RTL实现时序
- **修复要求**: 建议与RTL设计确认实际延迟cycle数，或改用灵活匹配

#### m13: Fault Injection Method Distinction
- **位置**: Chapter 9.3 故障注入测试场景
- **问题**: 故障注入场景未区分软件注入(verilog force)和硬件注入(FPGA/EMFI)
- **修复要求**: 明确各场景适用的注入方法

#### m14: Verification Strategy Chapter Brief
- **位置**: 第9章整体
- **问题**: 验证策略章节相对简略，与Verification Plan相比缺少详细testcase
- **修复要求**: 考虑将Verification Plan的testcase引用或摘要整合到Design Spec

#### m15: AXI4-Stream Timing Diagram Missing
- **位置**: Chapter 3.1 AXI4-Stream数据接口
- **问题**: 接口时序图缺失(如valid/ready握手时序)
- **修复要求**: 补充关键接口时序图，便于验证环境开发

### Architecture 相关 (m16-m20)

#### m16: XTS Operator Definition
- **位置**: Chapter 5.2.4 XTS Mode
- **问题**: XTS公式中使用的⊗符号未在文档中定义（是GF乘法还是普通乘法）
- **修复要求**: 明确运算符定义，建议采用标准符号或添加说明

#### m17: Area Estimation Confidence Interval
- **位置**: Chapter 2.2 模块划分
- **问题**: 模块面积估算缺乏confidence interval，建议增加范围说明
- **修复要求**: 增加面积估算范围，如"30K±5K gates"，并说明估算方法

#### m18: L3 Clock Gating Enable Logic
- **位置**: Chapter 7.2 时钟门控层次
- **问题**: L3级门控(state_clk_en等)的使能信号生成逻辑未详细说明
- **修复要求**: 补充L3门控使能信号的来源和生成逻辑

#### m19: Power PVT Conditions
- **位置**: Chapter 8.5 功耗估计
- **问题**: 功耗数据缺少工艺/电压/温度(PVT)条件说明
- **修复要求**: 增加PVT条件，如"典型工艺角, 1.0V, 25°C"

#### m20: Patent Technical Details
- **位置**: Chapter 10.1 潜在专利申请点
- **问题**: 专利申请点描述较笼统，建议增加技术细节
- **修复要求**: 补充CTS状态机和TI-SBox的具体技术创新点

---

## 交付物

### 1. 更新 Design Specification.md
- **目标版本**: v1.2
- **修改范围**: 根据上述20个Minor issues进行修复
- **保持**: 已完成v1.1的Critical和Major修复不变

### 2. 修复总结文档
- **文件**: `ProjectMgmt/Reviews/EDR/EDR_Minor_Remediation.md`
- **内容**: 
  - 每个Minor issue的修复摘要
  - 修改的章节和行号
  - 验证检查表

---

## 验收标准

- [ ] 所有20个Minor issues均已修复或有明确说明
- [ ] Design Spec版本更新为v1.2
- [ ] 修复总结文档已提交
- [ ] 无新增问题引入

---

## 参考信息

### EDR Issue Tracker 位置
```
ProjectMgmt/Reviews/EDR/EDR_Issue_Tracker.md
```

### 相关提交
- EDR Remediation Complete: `661537f` (修复了Critical + Major)

### 质量要求
- 遵循质量红线：零容忍虚假数据
- 所有修改必须有可追溯来源
- 完整输出，不省略关键细节

---

## 任务创建

- **创建时间**: 2026-04-02
- **创建人**: PM Agent
- **指派给**: Design Agent
- **审核人**: AI Yang

---

*任务创建完成，等待Design Agent确认并开始执行*

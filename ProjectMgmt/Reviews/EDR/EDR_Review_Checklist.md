# EDR Review - Engineering Design Review

## 基本信息

| 字段 | 值 |
|------|-----|
| **项目名称** | AES_Crypto (IP_20260331_001) |
| **评审类型** | EDR Gate |
| **前置阶段** | PAD Gate (Conditional Pass) |
| **评审日期** | TBD |
| **项目类型** | IP - Digital |
| **ASIL等级** | ASIL-D |

## 参与人员

| 角色 | 姓名 | 职责 |
|------|------|------|
| 主持人 | PM Agent | 进度管控 |
| 设计工程师 | Design Agent | Design Spec 编写 |
| 验证工程师 | Verification Agent | Verification Plan |
| 架构师 | System Architect | 架构一致性检查 |
| DFT工程师 | DFT Agent | DFT策略 |
| 质量守门员 | AI Yang | Gate检查 |

## EDR Gate 交付物检查清单

### 1. Design Specification (设计规格文档)

| 章节 | 必需 | 状态 | 负责人 | 检查内容 |
|------|------|------|--------|----------|
| **1. Overview** | ✅ | ⏳ | Design Agent | 模块概述、功能简介、应用场景 |
| **2. Function Descriptions** | ✅ | ⏳ | Design Agent | 详细功能、工作流程、算法说明 |
| **3. Register Descriptions** | ✅ | ⏳ | Design Agent | 寄存器列表、位域定义、复位值 |
| **4. Example** | ✅ | ⏳ | Design Agent | 使用示例、配置流程 |
| **5. Block Design** | ✅ | ⏳ | Design Agent | 模块框图、子模块划分、数据流 |
| **6. FSM** | ✅ | ⏳ | Design Agent | 状态机定义、状态转换图、转换条件 |
| **7. Low Power** | ✅ | ⏳ | Design Agent | 低功耗模式、时钟门控、电源域 |
| **8. Patent** | ⚠️ | ⏳ | Design Agent | 专利申请点、创新点说明 |

**特殊要求 (AES IP)**:
- [ ] S-Box TI 实现详细设计 (3-share 布尔掩码)
- [ ] Mask Refreshing 机制实现
- [ ] Shuffling 算法硬件实现
- [ ] CTS 处理状态机
- [ ] XTS Tweak 计算模块设计
- [ ] Fault Detector 双执行比较逻辑
- [ ] CRC-32 计算单元设计

### 2. Verification Plan (验证计划)

| 检查项 | 状态 | 负责人 | 检查内容 |
|--------|------|--------|----------|
| **验证策略** | ⏳ | Verification Agent | 验证方法学、工具选择 |
| **测试点分解** | ⏳ | Verification Agent | 功能覆盖点、断言规划 |
| **UVM环境架构** | ⏳ | Verification Agent | Agent/Sequence/Scoreboard设计 |
| **参考模型** | ⏳ | Verification Agent | C/SystemVerilog参考模型 |
| **覆盖率计划** | ⏳ | Verification Agent | Code/Function/Assert覆盖率目标 |
| **安全验证** | ⏳ | Verification Agent | TVLA侧信道测试计划 |
| **回归策略** | ⏳ | Verification Agent | 回归测试流程、稳定性标准 |

**特殊要求 (AES IP)**:
- [ ] NIST SP 800-38A 测试向量覆盖
- [ ] XTS-AES 向量测试 (IEEE P1619)
- [ ] CTS 边界条件测试 (1-127 bit)
- [ ] TVLA t-test 测试流程
- [ ] 故障注入测试场景

### 3. CDC/RDC Strategy (跨时钟域策略)

| 检查项 | 状态 | 负责人 | 检查内容 |
|--------|------|--------|----------|
| **时钟域分析** | ⏳ | Design Agent | 单时钟/多时钟设计说明 |
| **CDC处理** | ⏳ | Design Agent | 同步器设计、Handshake协议 |
| **RDC处理** | ⏳ | Design Agent | 复位域交叉处理 |
| **Spyglass检查** | ⏳ | Design Agent | CDC规则检查通过 |

**AES IP 说明**: 单时钟设计 (aclk)，CDC策略简单

### 4. Power Intent (低功耗意图)

| 检查项 | 状态 | 负责人 | 检查内容 |
|--------|------|--------|----------|
| **UPF/CPF** | ⏳ | Design Agent | 电源域定义 (如需要) |
| **时钟门控** | ⏳ | Design Agent | ICG插入策略 |
| **功耗目标** | ⏳ | Design Agent | <10mW @ 100MHz |

### 5. DFT Strategy (可测性策略)

| 检查项 | 状态 | 负责人 | 检查内容 |
|--------|------|--------|----------|
| **Scan Chain** | ⏳ | DFT Agent | 扫描链规划 |
| **BIST** | ⏳ | DFT Agent | 存储器BIST (如适用) |
| **测试模式** | ⏳ | DFT Agent | Testmode/Agingmode设计 |
| **DFT指标** | ⏳ | DFT Agent | 覆盖率目标、ATPG策略 |

### 6. 从 PAD 继承的待解决问题 (Q1-Q4)

| ID | 问题 | PAD状态 | EDR要求 | 责任人 |
|----|------|---------|---------|--------|
| Q1 | 中断寄存器定义 | Minor | 必须在Design Spec中定义 | Design Agent |
| Q2 | 电源域划分 | Minor | 必须在Low Power章节说明 | Design Agent |
| Q3 | FMEDA分析 | Minor | 可延后至IDR | FuSa Engineer |
| Q4 | CTS边界条件 | Minor | 必须在Verification Plan中覆盖 | Verification Agent |

## EDR Review 会议流程 (6个Phase)

### Phase 1-2: 设计文档Review与修改
- [ ] Design Spec 发送 Verification Agent review
- [ ] Verification Agent 提出修改意见
- [ ] Design Agent 完成修改并关闭意见

### Phase 3: Reference Manual External章节
- [ ] **Overview** - 模块概述完整
- [ ] **Function Descriptions** - 功能描述详细
- [ ] **Register Descriptions** - 寄存器定义完整
- [ ] **Example** - 使用示例明确
- [ ] **复用模块改动说明** - 强调TI S-Box/CTS等创新点

### Phase 4: Codebeamer跟踪检查
- [ ] **HWE2全部内容** - 已在Codebeamer完整记录
- [ ] **Release标记** - v0.5/v0.7/v0.9版本标记
- [ ] **HWE1追溯检查** - 需求追溯关系正确
- [ ] **第三方IP** - 无第三方IP (纯自研)

**参数与配置检查**:
- [ ] **Parameter与配置选项** - 密钥长度、工作模式配置
- [ ] **FIFO大小配置** - 数据缓冲FIFO深度

**接口与异步检查**:
- [ ] **Interface** - AXI4-Stream/APB接口定义
- [ ] **Async** - 单时钟，无需特殊处理

**DFT检查**:
- [ ] **DFT特殊处理** - 扫描链时钟、复位处理

### Phase 5: Reference Manual Internal章节
- [ ] **状态机** - AES状态机、CTS状态机、XTS状态机
- [ ] **关键接口时序图** - AXI4-Stream读写时序
- [ ] **专利** - TI S-Box实现、CTS优化算法

### Phase 6: 第三方IP文档
- [ ] **Standard Cell** - tsmc28nm标准单元
- [ ] **Release Notes** - 工艺库版本
- [ ] **Errata** - 工艺库已知问题评估

## 评审检查点

### AI Yang 质量检查 (Pre-Gate)

| 检查项 | 标准 | 当前状态 |
|--------|------|----------|
| **交付物完整性** | Design Spec + Vplan + CDC/DFT策略 | ⏳ 待开始 |
| **内部一致性** | 架构 ↔ 设计 ↔ 验证无矛盾 | ⏳ 待检查 |
| **可追溯性** | PAD架构 → EDR设计链路完整 | ⏳ 待检查 |
| **质量底线** | 无明显设计缺陷 | ⏳ 待检查 |
| **规范性** | 符合 IP Workflow 模板 | ⏳ 待检查 |

### EDR Gate 通过标准

| 类别 | 要求 | 当前 |
|------|------|------|
| Design Spec | 8个章节完整 | ⏳ |
| Verification Plan | 测试点、覆盖率、TVLA计划 | ⏳ |
| CDC Strategy | 单时钟也需说明 | ⏳ |
| Power Intent | 时钟门控策略 | ⏳ |
| DFT Strategy | Scan/BIST规划 | ⏳ |
| PAD遗留问题 | Q1/Q2必须解决 | ⏳ |

## 评审决策

| 决策项 | 建议 |
|--------|------|
| **EDR Gate** | ⏳ **待评审** |
| **下一步** | 文档冻结，进入IDR实现阶段 |
| **风险** | TVLA验证计划复杂度、CTS边界条件 |

## 行动项

| 序号 | 行动项 | 责任人 | 截止日期 |
|------|--------|--------|---------|
| 1 | 编写 Design Specification v1.0 | Design Agent | TBD |
| 2 | 编写 Verification Plan | Verification Agent | TBD |
| 3 | 解决PAD遗留Q1/Q2 | Design Agent | EDR前 |
| 4 | 制定DFT Strategy | DFT Agent | TBD |
| 5 | 创建EDR Review材料 | PM Agent | TBD |

## 附件清单

- [ ] Design Specification (TBD)
- [ ] Verification Plan (TBD)
- [ ] CDC Strategy (TBD)
- [ ] Power Intent (TBD)
- [ ] DFT Strategy (TBD)
- [ ] PAD Review Checklist (参考)

---

*文档版本: v1.0*  
*创建日期: 2026-03-31*  
*状态: Draft - 待EDR阶段填充*  
*模板: IP_DESIGN_WORKFLOW.md EDR Review*

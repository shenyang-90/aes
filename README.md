# AES_Crypto - Advanced Encryption Standard IP

## 项目概览

| 字段 | 内容 |
|------|------|
| **项目ID** | IP_20260331_001 |
| **项目名称** | AES Crypto IP with Countermeasures & CTS |
| **项目类型** | IP |
| **算法标准** | AES-128/192/256 (FIPS-197) |
| **工艺节点** | tsmc28nm |
| **ASIL等级** | ASIL-D |
| **项目经理** | PM Agent |
| **创建日期** | 2026-03-31 |

## 核心功能

| 功能 | 描述 | 优先级 |
|------|------|--------|
| **AES Core** | 128/192/256-bit 密钥支持 | P0 |
| **Countermeasures** | 侧信道防护 (DPA/CPA抵抗) | P0 |
| **Ciphertext Stealing (CTS)** | XTS-AES 模式支持 | P0 |
| **Modes** | ECB/CBC/CTR/GCM/XTS | P1 |
| **Performance** | >1Gbps @ 100MHz | P1 |
| **Interface** | AXI4-Stream | P1 |

## 项目阶段

```
PCD ──────→ PAD ──────→ EDR ──────→ IDR ──────→ FDR ──────→ Post Silicon
概念阶段    架构阶段    文档阶段    实现阶段    后端阶段      硅后阶段

当前阶段: [████░░░░░░░░░░░░░░░░] PCD (0%)
```

## 快速导航

### 项目管理 (ProjectMgmt/)
- [Planning](./ProjectMgmt/Planning/) - 项目计划、Schedule
- [Reviews](./ProjectMgmt/Reviews/) - 阶段评审记录
- [Bugs](./ProjectMgmt/Bugs/) - Bug跟踪
- [MeetingMinutes](./ProjectMgmt/MeetingMinutes/) - 会议记录
- [Milestones](./ProjectMgmt/Milestones/) - 阶段交付物
- [RiskMgmt](./ProjectMgmt/RiskMgmt/) - 风险管理
- [ChangeMgmt](./ProjectMgmt/ChangeMgmt/) - ECO/CR记录
- [StatusReports](./ProjectMgmt/StatusReports/) - 周报月报

### 设计数据 (Database/)
- [Docs](./Database/Docs/) - 设计文档
  - [Arch](./Database/Docs/Arch/) - 架构规格
  - [Design](./Database/Docs/Design/) - 模块设计
  - [Verification](./Database/Docs/Verification/) - 验证计划
  - [FuSa](./Database/Docs/FuSa/) - 功能安全
- [DesignData](./Database/DesignData/) - RTL/Netlist/GDS
- [Verification](./Database/Verification/) - 验证环境
- [Validation](./Database/Validation/) - FPGA/硅后验证
- [Scripts](./Database/Scripts/) - EDA脚本
- [Reference](./Database/Reference/) - 参考资料

## 安全特性

| 防护机制 | 描述 | ASIL相关性 |
|----------|------|------------|
| **Masking** | 随机掩码对抗DPA | ASIL-D |
| **Shuffling** | 操作乱序 | ASIL-D |
| **Hiding** | 功耗平衡 | ASIL-B |
| **Fault Detection** | 故障注入检测 | ASIL-D |
| **CRC Check** | 密钥/数据完整性 | ASIL-B |

## 团队角色

| 角色 | Agent | 职责 | 状态 |
|------|-------|------|------|
| 质量守门员 | AI Yang | Gate检查、质量把关 | 🟢 待命 |
| 项目经理 | PM Agent | 进度管理、资源协调 | 🟢 活跃 |
| 系统架构师 | System Architect | 架构设计、安全策略 | 🟡 待分配 |
| 设计工程师 | Design Agent | RTL实现、Countermeasures | 🟡 待分配 |
| 验证工程师 | Verification Agent | 验证环境、安全测试 | 🟡 待分配 |
| DFT工程师 | DFT Agent | 可测性设计 | ⚪ 待分配 |
| 后端工程师 | Physical Agent | 物理实现 | ⚪ 待分配 |

## 关键交付物

| 阶段 | 交付物 | 负责人 | 截止日期 |
|------|--------|--------|----------|
| PCD | MRD, 可行性分析 | PM Agent | TBD |
| PAD | Architecture Spec, 安全概念 | System Architect | TBD |
| EDR | Design Spec, 验证计划 | Design/Verification | TBD |
| IDR | RTL, Testbench, 覆盖率 | Design/Verification | TBD |
| FDR | Netlist, GDS, ATPG | Physical/DFT | TBD |

## 最近活动

| 日期 | 活动 | 负责人 |
|------|------|--------|
| 2026-03-31 | 项目初始化，模板生成 | PM Agent |
| 2026-03-31 | PAD Gate通过，进入EDR | AI Yang |
| 2026-03-31 | EDR Gate通过，进入IDR | 实体 Yang |
| 2026-03-31 | RTL开发完成 (12模块) | Coding Yang |
| 2026-03-31 | UVM环境搭建完成 | Coding Yang |

## 参考文档

- [AES Specification (FIPS-197)](./Database/Reference/FIPS-197.pdf)
- [XTS-AES Mode (IEEE P1619)](./Database/Reference/IEEE-P1619.pdf)
- [DPA Countermeasures Survey](./Database/Reference/DPA_Countermeasures.pdf)
- [SOC_DESIGN_WORKFLOW.md](../../../workflow/SOC_DESIGN_WORKFLOW.md)

---

*项目模板版本: v2.0*  
*AES Crypto IP - Confidential*
ow/SOC_DESIGN_WORKFLOW.md)

---

*项目模板版本: v2.0*  
*AES Crypto IP - Confidential*

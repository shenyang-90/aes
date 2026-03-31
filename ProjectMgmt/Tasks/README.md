# AES_Crypto - 全局任务索引

## 项目信息

| 字段 | 值 |
|------|-----|
| **项目ID** | IP_20260331_001 |
| **项目类型** | IP |
| **当前阶段** | IDR (Implementation Design Review) |
| **创建日期** | 2026-03-31 |

---

## 项目阶段状态

```
PCD ──────→ PAD ──────→ EDR ──────→ IDR ──────→ Post Silicon
概念阶段    架构阶段    文档阶段    实现阶段      硅后阶段
   ✅          ✅          ✅          🚀            ⚪
  已完成      已完成      已完成      进行中        未开始
```

---

## 团队任务分配

| Agent | 任务清单 | 主要职责 | 当前状态 |
|-------|----------|----------|----------|
| **PM Agent** | [TASK_LIST](./PM_Agent/TASK_LIST.md) | 项目进度管控、Gate评审组织 | 🟢 活跃 |
| **AI Yang** | [TASK_LIST](./AI_Yang/TASK_LIST.md) | Gate前质量检查、节点状态总结 | 🟢 待命 |
| **Coding Yang** | [TASK_LIST](./Coding_Yang/TASK_LIST.md) | RTL编码、UVM环境、EDA工具执行 | 🟡 待获取任务 |
| **IP Architect** | [TASK_LIST](./IP_Architect/TASK_LIST.md) | IP架构设计 (已完成) | ✅ 已完成 |
| **Design Agent** | [TASK_LIST](./Design_Agent/TASK_LIST.md) | Design Spec (已完成) | ✅ 已完成 |
| **Verification Agent** | [TASK_LIST](./Verification_Agent/TASK_LIST.md) | Verification Plan (已完成) | ✅ 已完成 |
| **DFT Agent** | [TASK_LIST](./DFT_Agent/TASK_LIST.md) | 可测性设计 | ⏳ 待开始 |
| **FuSa Engineer** | [TASK_LIST](./FuSa_Engineer/TASK_LIST.md) | 功能安全 (FMEDA进行中) | 🟡 进行中 |

---

## 阶段任务总览

### Phase 1: PCD (Project Concept Definition) ✅ 已完成
- **目标**: 完成项目概念定义，确认可行性
- **主导**: PM Agent
- **状态**: 已完成

### Phase 2: PAD (Product Architecture Definition) ✅ 已完成
- **目标**: 完成架构设计，冻结架构规格
- **主导**: IP Architect
- **状态**: 已完成 (AI Yang有条件通过)
- **遗留**: Q3 (FMEDA) IDR阶段解决

### Phase 3: EDR (Engineering Document Review) ✅ 已完成
- **目标**: 完成设计/验证文档，冻结文档基线
- **主导**: Design Agent + Verification Agent
- **状态**: 已完成 (实体Yang批准进入IDR)
- **决策**: TVLA实测豁免，验证重点调整为功能验证

### Phase 4: IDR (Implementation Design Review) 🚀 进行中
- **目标**: 完成RTL和验证，Code Freeze
- **主导**: Coding Yang
- **状态**: **进行中**

#### Task Queue 状态
| 任务ID | 类型 | 负责人 | 内容 | 截止日期 | 状态 |
|--------|------|--------|------|----------|------|
| **TASK-AES-RTL-001** | RTL | Coding Yang | 12模块RTL开发 | 2026-04-14 | 🟢 **active** |
| **TASK-AES-UVM-001** | UVM | Coding Yang | 验证环境搭建 | 2026-04-07 | 🟢 **active** |
| **TASK-AES-LINT-001** | LINT | Coding Yang | Lint/CDC清理 | 2026-04-11 | ⏳ waiting |
| **TASK-AES-TC-001** | TC | Coding Yang | Testcase开发 | 2026-04-11 | ⏳ waiting |
| **TASK-AES-COV-001** | COV | Coding Yang | 覆盖率收敛 | 2026-04-21 | ⏳ waiting |
| **TASK-AES-FMEDA-001** | FuSa | FuSa Engineer | FMEDA分析 | 2026-04-18 | ⏳ incoming |

#### 时间线
| 周次 | 日期 | 任务 | 里程碑 |
|------|------|------|--------|
| Week 1 | 03/31-04/06 | RTL(模块1-6) + UVM环境 | UVM完成 (04/07) |
| Week 2 | 04/07-04/13 | RTL(模块7-12) + Lint + TC | RTL完成 (04/14) |
| Week 3 | 04/14-04/20 | 验证执行 + 覆盖率迭代 | FMEDA完成 (04/18) |
| Week 4 | 04/21-04/28 | 回归测试 + Bug清理 | **Code Freeze** |

#### 任务依赖
```
IDR Kickoff
    │
    ├─► RTL-001 (🟢 active) ──┬─► LINT-001 (⏳ waiting)
    │                          │
    │                          └─► FMEDA-001 (⏳ incoming)
    │
    └─► UVM-001 (🟢 active) ──► TC-001 (⏳ waiting) ──► COV-001 (⏳ waiting) ──► Code Freeze
```

---

## Agent 分工速查

| 阶段 | 文档编写 | 代码实现 | 质量检查 | 决策 |
|------|----------|----------|----------|------|
| PAD | IP Architect | - | AI Yang | AI Yang |
| EDR | Design Agent + Verification Agent | - | AI Yang | 实体 Yang |
| IDR | - | **Coding Yang** | AI Yang | 实体 Yang |

---

## 任务状态速查

| 状态图标 | 含义 |
|----------|------|
| 🟡 | 待开始/准备中 |
| 🟢 | 进行中/active |
| ✅ | 已完成 |
| ⚪ | 未开始 |
| ⏳ | 等待依赖 |
| ❌ | 阻塞/问题 |

---

## 关键提醒

> **Coding Yang 获取任务方式:**
> ```bash
> cd /path/to/task_queue
> git pull origin master
> cat notification/IDR_2026-03-31.md
> ```
> 
> **任务来源**: `sandbox/task_queue/active/`
> - TASK-AES-RTL-001.json
> - TASK-AES-UVM-001.json

---

*最后更新: 2026-03-31 11:55*
*项目阶段: IDR (进行中)*

# IDR Phase Kickoff - AES Crypto IP

## 基本信息

| 字段 | 值 |
|------|-----|
| **项目** | AES Crypto IP (IP_20260331_001) |
| **阶段** | IDR - Implementation Design Review |
| **启动日期** | 2026-03-31 |
| **目标日期** | 2026-04-28 (Code Freeze) |
| **前置条件** | EDR Gate通过 ✅ |

---

## 🎯 阶段目标

完成RTL实现、验证环境搭建、覆盖率收敛，达到Code Freeze标准。

---

## 📋 任务清单与依赖

### 激活的任务 (Active)

| 任务ID | 类型 | 负责人 | 内容 | 截止日期 | 状态 |
|--------|------|--------|------|----------|------|
| **TASK-AES-RTL-001** | RTL | Coding Yang | 12模块RTL开发 | 2026-04-14 | 🟢 **已激活** |
| **TASK-AES-UVM-001** | UVM | Coding Yang | 验证环境搭建 | 2026-04-07 | 🟢 **已激活** |

### 等待激活的任务 (Incoming)

| 任务ID | 类型 | 负责人 | 内容 | 截止日期 | 依赖 |
|--------|------|--------|------|----------|------|
| **TASK-AES-LINT-001** | LINT | Coding Yang | Lint/CDC清理 | 2026-04-11 | RTL-001 |
| **TASK-AES-TC-001** | TC | Coding Yang | Testcase开发 | 2026-04-11 | UVM-001 |
| **TASK-AES-COV-001** | COV | Coding Yang | 覆盖率收敛 | 2026-04-21 | TC-001 |
| **TASK-AES-FMEDA-001** | FuSa | FuSa Engineer | FMEDA分析 | 2026-04-18 | RTL-001 |

---

## 🔗 依赖关系

```
IDR Kickoff
    │
    ├─► RTL-001 ──┬─► LINT-001
    │             │
    │             └─► FMEDA-001
    │
    └─► UVM-001 ──► TC-001 ──► COV-001 ──► Code Freeze
```

---

## 📅 时间线

| 周次 | 日期 | 任务 | 里程碑 |
|------|------|------|--------|
| Week 1 | 03/31-04/06 | RTL开发(模块1-6) + UVM环境 | UVM环境完成 |
| Week 2 | 04/07-04/13 | RTL开发(模块7-12) + Lint + TC | RTL完成 |
| Week 3 | 04/14-04/20 | 验证执行 + 覆盖率迭代 | FMEDA完成 |
| Week 4 | 04/21-04/28 | 回归测试 + Bug清理 | **Code Freeze** |

---

## ✅ Code Freeze 标准

| 检查项 | 目标 | 责任人 |
|--------|------|--------|
| RTL Lint Clean | 无Critical/Major | Coding Yang |
| Code Coverage | >90% | Coding Yang |
| Func Coverage | >85% | Coding Yang |
| Assert Coverage | >95% | Coding Yang |
| P1/P2 Bug | 全部关闭 | Coding Yang |
| 回归测试 | 连续2周100% | Coding Yang |
| FMEDA | SPFM>99%, LFM>90% | FuSa Engineer |

---

## 📁 工作目录

```
sandbox/aes/
├── Database/
│   ├── RTL/               # RTL代码
│   └── Verification/
│       └── uvm/           # UVM环境
├── ProjectMgmt/
│   └── Reviews/
│       └── IDR/           # IDR Review文档
└── task_queue/
    ├── active/            # 进行中任务
    └── incoming/          # 等待中任务
```

---

## 🚀 立即开始

**Coding Yang** 现在可以开始：
1. 阅读 `Database/Docs/Design/Design_Specification.md`
2. 创建 `Database/RTL/` 目录
3. 开始实现 `aes_controller.v`

---

*IDR Phase Kickoff - 2026-03-31*

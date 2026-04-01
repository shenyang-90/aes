# 📢 所有 Agent 注意：任务目录结构变更

**生效日期**: 2026-04-01
**通知人**: PM Agent

---

## 变更摘要

任务管理目录结构已重新组织，请所有 Agent 按新规则执行任务。

---

## 新目录结构

### 1. Coding Yang 任务队列（保持不变）

```
sandbox/task_queue/
├── incoming/      ← 新任务放入此处
├── active/        ← 进行中任务
├── completed/     ← 已完成任务
└── archive/       ← 归档任务
```

**用途**: 与 Coding Yang 进行任务交互的唯一通道

---

### 2. AI Agent 任务目录（新）

```
sandbox/aes/ProjectMgmt/Tasks/
├── AI_Yang/              ← AI Yang 主代理
├── Design_Agent/         ← Design Agent
├── DFT_Agent/            ← DFT Agent  
├── FuSa_Engineer/        ← 功能安全工程师
├── IP_Architect/         ← 架构师
├── PM_Agent/             ← PM Agent
├── Verification_Agent/   ← 验证工程师
└── Coding_Yang/          ← Coding Yang 任务记录副本
```

**用途**: AI Agent 任务记录和管理

---

## Agent 职责对照表

| Agent | 任务目录 | 输出位置 |
|-------|----------|----------|
| **AI Yang** | `ProjectMgmt/Tasks/AI_Yang/` | 文档更新、任务协调 |
| **Design Agent** | `ProjectMgmt/Tasks/Design_Agent/` | `Database/Docs/Design/` |
| **DFT Agent** | `ProjectMgmt/Tasks/DFT_Agent/` | `Database/Docs/DFT/` |
| **FuSa Engineer** | `ProjectMgmt/Tasks/FuSa_Engineer/` | `Database/Docs/FuSa/` |
| **IP Architect** | `ProjectMgmt/Tasks/IP_Architect/` | `Database/Docs/Arch/` |
| **PM Agent** | `ProjectMgmt/Tasks/PM_Agent/` | `ProjectMgmt/` |
| **Verification Agent** | `ProjectMgmt/Tasks/Verification_Agent/` | `Database/Verification/` |
| **Coding Yang** | `task_queue/` | `Database/RTL/` |

---

## 任务流转规则

### For AI Agents:

1. **接收任务**: 从 PM Agent 接收任务分配
2. **执行任务**: 在各自专业领域工作
3. **记录结果**: 将完成报告放入 `ProjectMgmt/Tasks/{Agent}/Completed/`
4. **提交代码**: `git commit` 并 `git push`

### For Coding Yang:

1. **接收任务**: 从 `task_queue/incoming/` 获取任务
2. **执行任务**: RTL 开发、验证环境搭建
3. **记录结果**: 完成后任务移至 `task_queue/completed/`
4. **提交代码**: `git commit` 并 `git push`

---

## 文件命名规范

### 任务文件
```
TASK-{PROJECT}-{TYPE}-{SEQ}.json
例: TASK-AES-RTL-004.json
```

### 结果报告
```
RESULT-TASK-{ID}-{STATUS}.md
例: RESULT-TASK-AES-FMEDA-001.md
```

---

## 重要提醒

1. ⚠️ **Coding Yang 任务必须通过 `sandbox/task_queue/` 交互**
2. ⚠️ **AI Agent 任务直接在 `ProjectMgmt/Tasks/` 管理**
3. ⚠️ **所有文件修改后必须提交到 Git**
4. ⚠️ **不要混淆两种任务路径**

---

## 🔴 重要更新：质量红线规则 (2026-04-01)

### 规则 1: 完整输出原则
**所有交付内容必须完整输出，不得省略！**

| ❌ 禁止 | ✅ 必须 |
|--------|--------|
| "详见xxx文件"、"参考xxx章节" | 每个交付物自包含、可独立理解 |
| 省略代码、省略表格、省略关键细节 | 代码示例完整、可综合 |
| 用摘要代替完整内容 | 表格数据完整、无省略 |

### 规则 2: 质量第一原则
**质量优先于速度，绝不妥协！**

| ❌ 禁止 | ✅ 必须 |
|--------|--------|
| 为了"完成任务"而降低质量标准 | 所有数据有明确来源 |
| 虚假数据、夸大声明 | 所有声明可验证 |
| 未经核实的假设 | 代码经过语法检查 |

### 规则 3: 可追溯性原则
**所有内容必须可追溯！**
- 设计决策 → 需求来源
- 技术参数 → 计算依据
- 代码实现 → 设计文档

### ⚠️ 违规后果
违反上述规则的任务将被 **直接打回**，不得进入下一阶段。

**质量第一，完整输出，绝不妥协！**

---

## 参考文档

- `ProjectMgmt/Tasks/AGENT_TASK_GUIDE.md` - 详细任务管理指南
- `sandbox/task_queue/protocol.md` - Coding Yang 任务协议

---

**如有疑问，请联系 PM Agent**


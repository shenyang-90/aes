# AI Agent 任务管理说明

**更新时间**: 2026-04-01

## 目录结构变更

### 任务队列分离

| 路径 | 用途 | 说明 |
|------|------|------|
| `sandbox/task_queue/` | **Coding Yang 任务队列** | 与 Coding Yang 进行任务交互的专用队列 |
| `sandbox/aes/ProjectMgmt/Tasks/` | **AI Agent 任务管理** | AI Yang 各子代理的任务记录 |

### AI Agent 任务目录

```
sandbox/aes/ProjectMgmt/Tasks/
├── AI_Yang/           # AI Yang 主代理任务
├── Design_Agent/      # Design Agent 任务
├── DFT_Agent/         # DFT Agent 任务
├── FuSa_Engineer/     # 功能安全工程师任务
├── IP_Architect/      # 架构师任务
├── PM_Agent/          # PM Agent 任务
├── Verification_Agent/ # 验证工程师任务
└── Coding_Yang/       # Coding Yang 任务记录（副本）
```

### 任务文件命名规范

```
TASK-{PROJECT}-{TYPE}-{SEQ}.json      # 任务文件
RESULT-TASK-{ID}-{STATUS}.md          # 结果报告
```

## 任务流转规则

### Coding Yang 任务
```
sandbox/task_queue/incoming/    ← 新任务放入
                ↓
sandbox/task_queue/active/      ← 进行中任务
                ↓
sandbox/task_queue/completed/   ← 已完成任务
                ↓
sandbox/task_queue/archive/     ← 归档任务
```

### AI Agent 任务
```
sandbox/aes/ProjectMgmt/Tasks/{Agent}/
├── TASK_LIST.md          # 任务清单
├── Completed/            # 已完成任务
│   ├── RESULT-TASK-xxx.md
│   └── ...
└── ...
```

## 注意事项

1. **Coding Yang 任务必须通过 `sandbox/task_queue/` 交互**
2. **AI Agent 任务直接在项目文件夹内管理**
3. **所有任务完成后需要提交到 Git**

## 相关文档

- `sandbox/task_queue/protocol.md` - Coding Yang 任务协议
- `sandbox/aes/ProjectMgmt/Tasks/README.md` - 任务管理总览

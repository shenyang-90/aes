# AES IP Bug Tracking

## Active Bugs

| Bug ID | Severity | Status | Title | Assignee | Due Date |
|--------|----------|--------|-------|----------|----------|
| BUG-002 | Critical | ✅ CLOSED | Unpacked structs not supported | Coding Yang | Done |
| BUG-003 | Major | ✅ CLOSED | AES-192/256 key length incomplete | Design Agent | 2026-03-31 |
| BUG-004 | Major | 🟡 PARTIAL | GCM mode implementation incomplete | Design Agent | 2026-04-10 |
| BUG-005 | Minor | 🟡 PARTIAL | XTS mode tweak implementation issue | Design Agent | 2026-04-08 |

## Bug Status Legend

| Symbol | Status | Description |
|--------|--------|-------------|
| 🔴 | **OPEN** | Bug confirmed, fix pending |
| 🟡 | **IN PROGRESS** / **PARTIAL** | Fix being implemented or partially applied |
| 🟢 | **FIXED** | Fix committed, verification pending |
| ✅ | **CLOSED** | Fix verified, bug closed |

## Priority Guidelines

| Priority | Response Time | Fix Target | Escalation |
|----------|--------------|------------|------------|
| Critical | 4 hours | 1 day | Auto-escalate to lead |
| Major | 1 day | 3 days | Daily tracking |
| Minor | 3 days | 1 week | Weekly review |

## Bug Flow

```
Found → Logged → Triage → Assigned → Fixed → Verified → Closed
   ↑                                                  |
   └──────────────── Re-open if regression ────────────┘
```

## Bug 文件命名规范

- 格式：`BUG-<编号>.md`
- 示例：`BUG-003.md`, `BUG-004.md`
- 所有修复详情、状态更新、验证结果直接写入对应文件

## 查看 Bug 详情

点击上方表格中的 Bug ID 查看完整信息：
- [BUG-003.md](./BUG-003.md) - AES-192/256 密钥长度支持
- [BUG-004.md](./BUG-004.md) - GCM 模式实现
- [BUG-005.md](./BUG-005.md) - XTS 模式 tweak 实现

---

## ⚠️ 重要说明

**所有 Bug 相关信息必须直接记录在对应的 BUG-XXX.md 文件中。**

> ❌ **禁止**在 Bugs 文件夹下新建其他状态文件、报告文件或汇总文件
> - ~~BUG-FIX-STATUS.md~~ ❌
> - ~~BUG-FIX-REPORT.md~~ ❌
> - ~~BUG-PROGRESS.md~~ ❌
> - 任何其他汇总/状态文件 ❌

> ✅ **正确做法**：所有内容直接写入对应的 BUG-XXX.md
> - 修复状态 → 写入 BUG-003.md 的 Status 字段
> - 修复历史 → 写入 BUG-003.md 的 Fixes Applied 章节
> - 验证结果 → 写入 BUG-003.md 的 Verification Results 章节
> - 时间线 → 写入 BUG-003.md 的 Timeline 章节

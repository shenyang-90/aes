# AES IP Bug Tracking

## Active Bugs

| Bug ID | Severity | Status | Title | Assignee | Due Date |
|--------|----------|--------|-------|----------|----------|
| BUG-002 | Critical | ✅ CLOSED | Unpacked structs not supported | Coding Yang | Done |
| BUG-003 | Major | ✅ CLOSED | AES-192/256 key length incomplete | Design Agent | 2026-03-31 |
| BUG-004 | Major | 🟢 FIXED | GCM mode implementation incomplete | Design Agent | 2026-03-31 |
| BUG-005 | Minor | 🟢 FIXED | XTS mode tweak implementation issue | Design Agent | 2026-03-31 |
| BUG-006 | **Major** | 🟢 FIXED | sbox_masked placeholder implementation | Design Agent | 2026-03-31 |
| BUG-007 | Low | 🔴 OPEN | State machine naming inconsistency | Design Agent | 2026-04-15 |
| BUG-008 | Low | 🟢 FIXED | XTS tweak block_num simplification | Design Agent | 2026-03-31 |
| BUG-009 | Low | 🟢 FIXED | GCM multi-block AAD/CT processing | Design Agent | 2026-03-31 |
| BUG-010 | Low | 🟢 FIXED | CRC checker not using data_in | Design Agent | 2026-03-31 |
| BUG-011 | HIGH | 🟢 FIXED | GCM tag generation incomplete | Design Agent | 2026-04-01 |
| BUG-012 | HIGH | 🟢 FIXED | XTS multi-sector tweak incomplete | Design Agent | 2026-04-01 |
| BUG-013 | MEDIUM | 🟢 FIXED | CTS decryption not implemented | Design Agent | 2026-04-01 |
| BUG-014 | HIGH | 🟢 FIXED | INT_STAT register not functional | Design Agent | 2026-04-01 |
| BUG-015 | MEDIUM | 🟢 FIXED | Key clear functionality missing | Design Agent | 2026-04-01 |
| BUG-016 | MEDIUM | 🟢 FIXED | CRC checker not fully integrated | Design Agent | 2026-04-01 |

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

### 功能 Bug
- [BUG-003.md](./BUG-003.md) - AES-192/256 密钥长度支持 ✅ CLOSED
- [BUG-004.md](./BUG-004.md) - GCM 模式实现 🟡 PARTIAL
- [BUG-005.md](./BUG-005.md) - XTS 模式 tweak 实现 🟡 PARTIAL

### RTL 代码审查发现的问题 (已修复)
- [BUG-006.md](./BUG-006.md) - sbox_masked placeholder 实现 🟢 FIXED
- [BUG-007.md](./BUG-007.md) - 状态机命名不一致 🔴 OPEN
- [BUG-008.md](./BUG-008.md) - XTS tweak block_num 简化 🟢 FIXED
- [BUG-009.md](./BUG-009.md) - GCM 多块 AAD/CT 处理 🟢 FIXED
- [BUG-010.md](./BUG-010.md) - CRC checker 未使用 data_in 🟢 FIXED

### 功能覆盖率发现的问题 (已修复)
- [BUG-011.md](./BUG-011.md) - GCM Tag 生成不完整 🟢 FIXED
- [BUG-012.md](./BUG-012.md) - XTS 多Sector tweak 不完整 🟢 FIXED
- [BUG-013.md](./BUG-013.md) - CTS 解密未实现 🟢 FIXED
- [BUG-014.md](./BUG-014.md) - INT_STAT 寄存器不工作 🟢 FIXED
- [BUG-015.md](./BUG-015.md) - Key 清除功能缺失 🟢 FIXED
- [BUG-016.md](./BUG-016.md) - CRC 检查器未集成 🟢 FIXED

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

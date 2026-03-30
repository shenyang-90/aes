# Reviews - 各阶段评审记录

此目录包含各阶段评审记录，按阶段分子目录。

## 子目录

| 目录 | 阶段 | 描述 |
|------|------|------|
| [PCD](./PCD/) | 概念阶段 | 项目概念评审 |
| [PAD](./PAD/) | 架构阶段 | 架构设计评审 (ADR) |
| [EDR](./EDR/) | 文档阶段 | 工程文档评审 |
| [IDR](./IDR/) | 实现阶段 | 实现设计评审 (Code Freeze) |
| [FDR](./FDR/) | 后端阶段 | 最终设计评审 (Tapeout) |
| [PostSilicon](./PostSilicon/) | 硅后阶段 | 量产评审 |

## 评审模板

每个阶段评审应包含：
- 评审会议记录 (Meeting Minutes)
- Checklist 检查表
- 评审结论 (Pass/Conditional Pass/Fail)
- 行动项跟踪

## 文件命名规范

```
[Phase]_Review_Meeting_Minutes_YYYYMMDD.md
[Phase]_Checklist_[Module]_v[Version]_YYYYMMDD.md

示例:
- PAD_Review_Meeting_Minutes_20260327.md
- IDR_Checklist_CPU_v1.0_20260327.md
```

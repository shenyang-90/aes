# AES IP Bug Tracking

## Active Bugs

| Bug ID | Severity | Status | Title | Assignee | Due Date |
|--------|----------|--------|-------|----------|----------|
| BUG-002 | Critical | ✅ FIXED | Unpacked structs not supported | Coding Yang | Done |
| BUG-003 | Major | 🔴 OPEN | AES-192/256 key length incomplete | Design Agent | 2026-04-05 |
| BUG-004 | Major | 🔴 OPEN | GCM mode implementation incomplete | Design Agent | 2026-04-10 |
| BUG-005 | Minor | 🟡 OPEN | XTS mode tweak implementation issue | Design Agent | 2026-04-08 |

## Bug Status Legend

- 🔴 **OPEN**: Bug confirmed, fix pending
- 🟡 **IN PROGRESS**: Fix being implemented
- 🟢 **FIXED**: Fix committed, verification pending
- ✅ **CLOSED**: Fix verified, bug closed

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

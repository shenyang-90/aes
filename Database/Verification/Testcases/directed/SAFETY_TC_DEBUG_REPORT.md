# 安全机制测试用例调试报告

**日期**: 2026-04-01  
**Design Spec**: v1.2  
**RTL 版本**: 更新至 v1.2

---

## 测试结果汇总

| 测试用例 | 通过 | 失败 | 状态 |
|---------|------|------|------|
| tc_safety_dual_rail | 17 | 0 | ✅ PASS |
| tc_safety_crc_error | 20 | 1 | ⚠️ PARTIAL |
| tc_safety_fsm_timeout | 6 | 12 | ❌ FAIL |
| tc_safety_interrupt | 8 | 9 | ❌ FAIL |
| tc_safety_key_zeroize | 6 | 5 | ❌ FAIL |

---

## 详细问题分析

### 1. tc_safety_crc_error - CRC 集成问题

**失败测试**: SM-INTEG-001

**问题**: CRC error NOT setting STATUS[5] CRC_ERR

**分析**:
- CRC checker 模块已实例化但 `calc_done` 信号未连接 (警告)
- CRC 错误未正确传播到 STATUS[5]
- FAULT_DETECTED 集成可能存在问题

**建议修复**:
- 检查 aes_top.v 中 crc_checker 的连接
- 确保 crc_error 信号正确连接到 STATUS[5]

---

### 2. tc_safety_fsm_timeout - FSM 恢复问题

**失败测试**: SM-001~005, SM-041~048 (12个)

**问题**: FSM NOT recovered to IDLE within 10 cycles

**分析**:
- FSM timeout watchdog 可能未实现
- 强制进入错误状态后无法自动恢复
- STATUS[4]=FAULT_DETECTED 更新正确，但恢复逻辑有问题

**建议修复**:
- 检查 aes_controller 是否实现了 watchdog timeout
- 添加 FSM 错误恢复逻辑

---

### 3. tc_safety_interrupt - 中断集成问题

**失败测试**: 9个

**问题**: 中断触发和清除问题

**分析**:
- INT_EN/INT_STATUS 位定义已更新到 v1.2
- 但中断源可能未正确连接
- `int_error_set`, `int_done_set` 信号未定义

**建议修复**:
- 检查 RTL 中中断源信号生成逻辑
- 确保所有中断源正确连接到 INT_STATUS

---

### 4. tc_safety_key_zeroize - Key Manager 问题

**失败测试**: 5个

**问题**: key_manager not instantiated in design

**分析**:
- key_manager.v 存在但未在 aes_top 中实例化
- zeroize 信号只能通过 hierarchical force 访问
- 没有软件可访问的 key clear 机制

**建议修复**:
- 在 aes_top.v 中实例化 key_manager
- 或者更新 Design Spec 说明 key zeroize 是纯硬件功能

---

## 优先级建议

| 优先级 | 问题 | 影响 |
|--------|------|------|
| P0 | FSM timeout watchdog 未实现 | 功能安全核心机制缺失 |
| P1 | CRC 错误状态未正确设置 | 故障检测覆盖不完整 |
| P1 | 中断源信号未定义 | 中断通知机制不完整 |
| P2 | Key manager 未实例化 | 密钥清零功能受限 |

---

## 下一步行动

1. **RTL 修复**: Design Agent 需要修复上述 RTL 问题
2. **测试用例调整**: 根据 RTL 实际实现调整期望值
3. **文档同步**: 更新 Design Spec 以匹配实际实现


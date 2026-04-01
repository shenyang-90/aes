# Verification Plan Update Summary

## Document Information
- **Version**: v1.0
- **Date**: 2026-04-02
- **Source**: Design Spec v1.1 (EDR Remediation)
- **Status**: Complete

---

## Executive Summary

本报告记录Verification Agent根据Design Spec v1.1 EDR修复内容更新Verification Plan的完成情况。

| 更新类别 | 新增内容 | 状态 |
|----------|----------|------|
| ERROR状态测试 | 8个测试场景 (SM-049~056) | ✅ 完成 |
| Clock Delay测试 | 3个测试场景 (CC-001~003) | ✅ 完成 |
| BIST验证计划 | 12个测试场景 (BIST-001~012) | ✅ 完成 |
| 断言验证映射 | AS1-AS34完整映射表 | ✅ 完成 |
| 覆盖率目标更新 | BIST覆盖率100% | ✅ 完成 |

---

## Update Details

### 1. ERROR State Recovery Tests (新增)

基于Design Spec v1.1第5.4.3节错误恢复流程：

| Test ID | 测试场景 | 验证目标 |
|---------|----------|----------|
| SM-049 | ERROR状态进入 - fault_detected | 验证故障触发ERROR状态 |
| SM-050 | ERROR状态进入 - CRC_ERR | 验证CRC错误触发ERROR状态 |
| SM-051 | ERROR状态进入 - TIMEOUT_ERR | 验证超时触发ERROR状态 |
| SM-052 | ERROR状态保持 | 验证ERROR状态sticky行为 |
| SM-053 | ERROR状态退出 | 验证写STATUS[4]=1清零恢复 |
| SM-054 | FAULT_DETECTED sticky位 | 验证W1C行为 |
| SM-055 | LOCKSTEP_ACTIVE状态 (EN=1) | 验证STATUS[10]正确指示 |
| SM-056 | LOCKSTEP_ACTIVE状态 (EN=0) | 验证STATUS[10]正确指示 |

### 2. Clock Delay Common Cause Tests (新增)

基于Design Spec v1.1第6.2.4节时钟延迟实现：

| Test ID | 测试场景 | 验证目标 |
|---------|----------|----------|
| CC-001 | 2-cycle延迟验证 | 验证result_a/b正确对齐 |
| CC-002 | Clock glitch检测 | 验证延迟方案有效防护 |
| CC-003 | Clock edge skew容错 | 验证>0.5 cycle抖动容限 |

### 3. BIST Verification Plan (新增)

基于Design Spec v1.1第6.3.3节BIST触发策略：

#### 3.1 BIST功能测试

| Test ID | 测试场景 | 验证目标 |
|---------|----------|----------|
| BIST-001 | Power-On BIST | 验证上电自检自动执行 |
| BIST-002 | Periodic BIST (100ms) | 验证100ms周期自检 |
| BIST-003 | Periodic BIST (1s) | 验证1s周期自检 |
| BIST-004 | On-Demand BIST | 验证软件触发自检 |
| BIST-005 | BIST执行时间 | 验证<100us完成 |

#### 3.2 BIST故障检测延迟验证

| Test ID | 测试场景 | 验证目标 |
|---------|----------|----------|
| BIST-006 | 故障在BIST前发生 | 验证检测延迟<200ms |
| BIST-007 | 故障在BIST后发生 | 验证检测延迟<200ms |
| BIST-008 | 最坏情况延迟 | 验证<2s (1s周期) |
| BIST-009 | FTTI满足性 | 验证周期<FTTI/10 |

#### 3.3 BIST各测试项验证

| Test ID | 测试项 | 验证目标 |
|---------|--------|----------|
| BIST-010 | Lockstep测试 | 验证FAIL_ID=0 |
| BIST-011 | CRC测试 | 验证FAIL_ID=1 |
| BIST-012 | Timeout测试 | 验证FAIL_ID=2 |

### 4. Assertion Verification Mapping (更新)

基于Design Spec v1.1第9.4节完整断言列表：

#### 4.1 断言分类映射

| Design Spec Section | Verification Plan | 断言范围 |
|---------------------|-------------------|----------|
| 9.4.1 双轨比较断言 | 8.3.1 | AS1-AS10 |
| 9.4.2 CRC检查断言 | 8.3.2 | AS11-AS20 |
| 9.4.3 超时检查断言 | 8.3.3 | AS21-AS26 |
| 9.4.4 FSM安全断言 | 8.3.4 | AS27-AS34 |

#### 4.2 新增断言验证 (AS27-AS34)

| ID | 断言描述 | 验证方法 | 优先级 |
|----|----------|----------|--------|
| AS27 | 无效状态转ERROR | FSM coverage + assertion | P0 |
| AS28 | ERROR只能转IDLE | FSM coverage + assertion | P0 |
| AS29 | START触发KEY_SCHEDULE | FSM transition check | P0 |
| AS30 | FINAL_ROUND后OUTPUT_DATA | FSM transition check | P0 |
| AS31 | 忙状态BUSY置位 | Functional check | P0 |
| AS32 | DONE触发DONE_STATUS | Interrupt check | P0 |
| AS33 | 故障时输出清零 | Safety check | P0 |
| AS34 | 禁用锁步无故障 | DUAL_RAIL_EN=0 check | P0 |

### 5. Coverage Targets Update

| 覆盖率类型 | 原目标 | 更新后目标 | 变更说明 |
|------------|--------|------------|----------|
| 断言覆盖率 | >95% | >95% | 基准更新为AS1-AS34 |
| 故障注入场景 | 100% (48) | 100% (48+20) | 新增ERROR/BIST/CC测试 |
| FSM状态覆盖 | 100% | 100% | 包含ERROR状态 |
| **BIST覆盖率** | - | **100% (12场景)** | **v1.1新增** |

### 6. Safety Mechanism Checklist Update

新增检查项：
- [ ] ERROR状态进入和退出正确 (SM-049~054) - v1.1新增
- [ ] LOCKSTEP_ACTIVE状态正确 (SM-055~056) - v1.1新增
- [ ] Clock delay共因故障防护验证 (CC-001~003) - v1.1新增
- [ ] BIST功能正确 (BIST-001~012) - v1.1新增

---

## Reference Updates

| 文档ID | 名称 | 原版本 | 更新版本 |
|--------|------|--------|----------|
| REF-006 | Design Spec | v1.0 | **v1.1** |
| REF-008 | EDR Remediation | - | **v1.0 (新增)** |

---

## Document Version Update

**Verification Plan Updated**: v1.0 → v1.1

**Key Changes**:
1. Version updated to v1.1
2. Date updated to 2026-04-02
3. Status changed to "Updated for Design Spec v1.1"
4. Task updated to TASK-AES-VER-002
5. Revision history updated

---

## Sign-off

| Agent | Role | Reviewed | Sign-off |
|-------|------|----------|----------|
| Verification Agent | Verification | All updates | ✅ |

---

## Git Commit

```bash
git add Database/Docs/Verification/Verification_Plan.md
git add ProjectMgmt/Tasks/Verification_Agent/Completed/RESULT-TESTPLAN-UPDATE-SUMMARY.md
git commit -m "Verification Plan v1.1: Update for Design Spec EDR Remediation

- Add ERROR state recovery tests (SM-049~056)
- Add Clock delay common cause tests (CC-001~003)  
- Add BIST verification plan (BIST-001~012)
- Update assertion mapping AS1-AS34
- Update coverage targets for BIST
- Update reference documents to v1.1

Fixes #VER-Update-001"
```

---

## Next Steps

1. **Testplan Review**: 组织Design Agent, FuSa Engineer, IP Architect评审
2. **Review Comments**: 收集各Agent反馈
3. **Final Update**: 根据评审意见修改Testplan
4. **EDR Re-entry**: 提交完整文档包进行EDR复审

---

*End of Verification Plan Update Summary v1.0*

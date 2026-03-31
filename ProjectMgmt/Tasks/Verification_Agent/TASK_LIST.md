# AES_Crypto - Verification Agent 任务清单

> **Verification Agent 负责执行**

## 项目信息

| 字段 | 值 |
|------|-----|
| **项目ID** | IP_20260331_001 |
| **当前阶段** | IDR (EDR 已完成) |

---

## 职责范围
- Verification Plan 编写
- Testbench 架构设计
- 测试策略制定
- 覆盖率计划
- 参考模型设计
- 验证环境搭建指导

---

## EDR 阶段任务 ✅ 已完成

| 任务ID | 任务名称 | 交付物 | 状态 | 优先级 |
|--------|----------|--------|------|--------|
| TASK-AES-VER-001 | Verification Plan | Verification_Plan.md (7章节) | ✅ 已完成 | P0 |
| VER-IP_20260331_001-002 | Testbench架构 | TB_Architecture.md | ✅ 已完成 | P0 |
| VER-IP_20260331_001-003 | 测试策略 | Test_Strategy.md | ✅ 已完成 | P0 |
| VER-IP_20260331_001-004 | 覆盖率计划 | Coverage_Plan.md | ✅ 已完成 | P0 |
| VER-IP_20260331_001-005 | 参考模型设计 | Ref_Model_Design.md | ✅ 已完成 | P1 |

---

## 已完成交付物

### Verification Plan v1.0 ✅
**文件**: `Database/Docs/Verification/Verification_Plan.md`
**状态**: 已冻结 (v1.0)
**Git Commit**: `57252a5` [TASK-AES-VER-001] Complete AES IP Verification Plan v1.0

| 章节 | 内容 | 状态 |
|------|------|------|
| Ch1 | Overview | ✅ |
| Ch2 | Testbench Architecture | ✅ |
| Ch3 | Test Strategy | ✅ |
| Ch4 | Test Cases | ✅ (含Q4解决: CTS边界测试) |
| Ch5 | Coverage Plan | ✅ |
| Ch6 | Regression Plan | ✅ |
| Ch7 | Safety Verification | ✅ |

### NIST测试向量 ✅
**位置**: `Database/Verification/testvectors/`
- 58个测试用例
- ECB/CBC/CTR/GCM/XTS/CTS模式

### TVLA计划 ✅
**文件**: `Database/Docs/Verification/TVLA_Plan.md`
**方法**: Welch's t-test
**标准**: |t|<4.5
**状态**: 理论方案保留，IP阶段实测豁免 (实体Yang批准)

### CTS边界测试 ✅
**覆盖**: 11个测试用例 (1-127 bit)
**关联**: Q4解决

---

## 覆盖率目标

| 类型 | 目标 | 当前状态 |
|------|------|----------|
| Code Coverage | >90% | ⏳ IDR阶段达成 |
| Function Coverage | >85% | ⏳ IDR阶段达成 |
| Assertion Coverage | >95% | ⏳ IDR阶段达成 |

---

## 验证重点调整

**原始计划**: TVLA侧信道测试 (实际板测试)  
**调整后**: 功能验证为主 (实体Yang决策)

| 验证类型 | 原计划 | 调整后 | 状态 |
|----------|--------|--------|------|
| 功能验证 | P0 | P0 | ✅ 计划不变 |
| TVLA实测 | P0 | 豁免 | ⚠️ IDR阶段不测 |
| TVLA理论 | P1 | P0 | ✅ 保留方案 |
| 故障注入 | P0 | P0 | ✅ 计划不变 |

---

## 与 Design Agent 协作

| 协作点 | 状态 |
|--------|------|
| 验证计划 ↔ Design Spec 功能点 | ✅ 已对齐 |
| CTS边界测试 ↔ CTS_XTS_Design.md | ✅ Q4已解决 |
| 覆盖率 Function Point ↔ 功能描述 | ✅ 已对应 |

---

## 与 Coding Yang 协作

| 交付物 | 状态 | 用途 |
|--------|------|------|
| UVM环境设计 | ✅ | Coding Yang 实现 |
| 测试用例规格 | ✅ | Coding Yang 开发 |
| 覆盖率计划 | ✅ | Coding Yang 收敛 |

---

*最后更新: 2026-03-31 11:55*

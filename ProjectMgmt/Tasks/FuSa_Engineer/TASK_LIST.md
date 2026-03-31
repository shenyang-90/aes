# AES_Crypto - FuSa Engineer 任务清单

## 项目信息

| 字段 | 值 |
|------|-----|
| **项目ID** | IP_20260331_001 |
| **ASIL等级** | ASIL-D |
| **当前阶段** | IDR |

---

## 全程任务

| 任务ID | 任务名称 | 交付物 | 阶段 | 状态 | 优先级 |
|--------|----------|--------|------|------|--------|
| FUSA-IP_20260331_001-001 | Safety Concept | Safety_Concept.md | PAD | ✅ 已完成 | P0 |
| FUSA-IP_20260331_001-002 | FTA分析 | FTA_Report.pdf | PAD | ✅ 已完成 | P0 |
| FUSA-IP_20260331_001-003 | FMEDA分析 | FMEDA.xlsx | PAD/IDR | 🟡 进行中 | P0 |
| FUSA-IP_20260331_001-004 | 安全机制设计 | Safety_Mechanisms.md | EDR | ✅ 已完成 | P0 |
| FUSA-IP_20260331_001-005 | 故障注入测试计划 | Fault_Injection_Plan.md | EDR | ✅ 已完成 | P1 |
| FUSA-IP_20260331_001-006 | 执行故障注入测试 | FI_Test_Report | IDR | ⏳ 待开始 | P0 |
| FUSA-IP_20260331_001-007 | 安全案例分析 | Safety_Case.pdf | IDR | ⏳ 待开始 | P0 |

---

## 已完成交付物

### Safety Concept ✅
**文件**: `Database/Docs/FuSa/Safety_Concept.md`
**状态**: v1.0 已冻结

### FTA分析 ✅
**文件**: `Database/Docs/FuSa/FTA_Report.pdf`

### 安全机制设计 ✅
**文件**: `Database/Docs/FuSa/Safety_Mechanisms.md`

| 机制 | 实现 | ASIL |
|------|------|------|
| Masking (3-share) | TI S-Box | ASIL-D |
| Fault Detection | Lockstep双核 | ASIL-D |
| CRC Check | 密钥/数据校验 | ASIL-B |

### 故障注入测试计划 ✅
**文件**: `Database/Docs/FuSa/Fault_Injection_Plan.md`
**目标**: 99%故障检测率

---

## 进行中任务

### FMEDA分析 🟡
**任务ID**: TASK-AES-FMEDA-001 (incoming)  
**交付物**: `Database/Docs/FuSa/FMEDA_Report.xlsx`  
**截止日期**: 2026-04-18  
**依赖**: RTL-001 (RTL代码)

**ASIL目标**:
| 指标 | 目标 | 当前 |
|------|------|------|
| SPFM | >99% | ⏳ 计算中 |
| LFM | >90% | ⏳ 计算中 |

---

## 待开始任务

### 故障注入测试执行 ⏳
**计划**: IDR阶段后期  
**前置**: UVM环境 + Testcases完成

### 安全案例分析 ⏳
**计划**: IDR阶段后期  
**前置**: FMEDA + 故障注入测试完成

---

## ASIL目标汇总

| 指标 | 目标 | 任务ID |
|------|------|--------|
| SPFM | >99% | FUSA-IP_20260331_001-008 |
| LFM | >90% | FUSA-IP_20260331_001-009 |
| 故障检测率 | >99% | FUSA-IP_20260331_001-010 |

---

*最后更新: 2026-03-31 11:55*

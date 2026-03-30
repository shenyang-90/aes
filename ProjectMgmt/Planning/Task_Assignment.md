# AES IP 开发任务分配

## 项目信息
- **项目**: AES_Crypto (IP_20260331_001)
- **日期**: 2026-03-31
- **阶段**: PCD → PAD

---

## Agent 任务清单

### 1. System Architect
**职责**: 架构设计、安全策略定义

| 任务ID | 任务 | 优先级 | 依赖 | 交付物 |
|--------|------|--------|------|--------|
| ARCH-001 | 完成 Architecture Spec v1.0 | P0 | - | `Database/Docs/Arch/Architecture_Spec.md` |
| ARCH-002 | 定义 Countermeasure 策略 | P0 | ARCH-001 | `Database/Docs/Arch/Countermeasure_Strategy.md` |
| ARCH-003 | 定义 CTS/XTS 实现方案 | P0 | ARCH-001 | `Database/Docs/Arch/XTS_CTS_Design.md` |
| ARCH-004 | 完成 Safety Concept | P1 | ARCH-001 | `Database/Docs/FuSa/Safety_Concept.md` |
| ARCH-005 | PAD Review 准备 | P1 | ARCH-004 | `ProjectMgmt/Reviews/PAD/PAD_Review_Material.md` |

**关键要求**:
- S-Box 必须采用 Threshold Implementation (3 shares)
- XTS-AES 必须支持 Ciphertext Stealing
- 故障检测覆盖率 >90%

---

### 2. Design Agent (Coding Yang)
**职责**: RTL 实现、Countermeasure 集成

| 任务ID | 任务 | 优先级 | 依赖 | 交付物 |
|--------|------|--------|------|--------|
| RTL-001 | 搭建 RTL 目录结构 | P0 | - | `Database/DesignData/rtl/` |
| RTL-002 | 实现 `aes_controller.sv` | P0 | RTL-001 | `rtl/aes_controller.sv` |
| RTL-003 | 实现 `sbox_masked.sv` (TI) | P0 | ARCH-002 | `rtl/sbox/sbox_masked.sv` |
| RTL-004 | 实现 `key_schedule_masked.sv` | P0 | RTL-003 | `rtl/key/key_schedule_masked.sv` |
| RTL-005 | 实现 `aes_core.sv` (1轮/周期) | P0 | RTL-003, RTL-004 | `rtl/core/aes_core.sv` |
| RTL-006 | 实现 `mode_controller.sv` | P0 | ARCH-003 | `rtl/mode/mode_controller.sv` |
| RTL-007 | 实现 `xts_engine.sv` | P0 | ARCH-003 | `rtl/mode/xts_engine.sv` |
| RTL-008 | 实现 `cts_handler.sv` | P0 | RTL-007 | `rtl/mode/cts_handler.sv` |
| RTL-009 | 实现 `fault_detector.sv` | P1 | ARCH-002 | `rtl/safety/fault_detector.sv` |
| RTL-010 | 实现 `crc_checker.sv` | P1 | - | `rtl/safety/crc_checker.sv` |
| RTL-011 | 实现顶层 `aes_top.sv` | P0 | RTL-002~RTL-010 | `rtl/top/aes_top.sv` |
| RTL-012 | Lint/CDC Clean | P1 | RTL-011 | Lint 报告 |

**关键要求**:
- 所有 S-Box 必须使用 3-share TI 方案
- 支持 ECB/CBC/CTR/GCM/XTS/CTS 模式
- 代码覆盖率目标: >95%

---

### 3. Verification Agent
**职责**: 验证环境、安全测试

| 任务ID | 任务 | 优先级 | 依赖 | 交付物 |
|--------|------|--------|------|--------|
| VER-001 | 搭建 UVM 验证环境 | P0 | RTL-001 | `Database/Verification/Env/` |
| VER-002 | 编写参考模型 (C/SystemVerilog) | P0 | VER-001 | `tb/ref/aes_ref_model.c` |
| VER-003 | 实现基础测试用例 (smoke) | P0 | VER-002 | `tb/tests/aes_smoke_test.sv` |
| VER-004 | 实现 NIST 向量测试 | P0 | VER-003 | `tb/tests/aes_nist_test.sv` |
| VER-005 | 实现模式测试 (ECB/CBC/CTR/GCM/XTS) | P0 | VER-004 | `tb/tests/aes_modes_test.sv` |
| VER-006 | 实现 CTS 专项测试 | P0 | RTL-008 | `tb/tests/aes_cts_test.sv` |
| VER-007 | 实现故障注入测试 | P1 | RTL-009 | `tb/tests/aes_fault_test.sv` |
| VER-008 | 实现侧信道测试框架 (TVLA) | P1 | RTL-003 | `tb/tvla/` |
| VER-009 | 覆盖率收敛 (>>90%) | P1 | VER-005~VER-008 | 覆盖率报告 |
| VER-010 | EDR Review 准备 | P1 | VER-009 | `ProjectMgmt/Reviews/EDR/` |

**关键要求**:
- NIST 测试向量 100% 通过
- TVLA 测试通过 (1st-order DPA)
- 功能覆盖率 >90%

---

### 4. DFT Agent
**职责**: 可测性设计

| 任务ID | 任务 | 优先级 | 依赖 | 交付物 |
|--------|------|--------|------|--------|
| DFT-001 | 编写 DFT Specification | P2 | RTL-011 | `Database/Docs/DFT/DFT_Spec.md` |
| DFT-002 | 插入 Scan Chain | P2 | DFT-001 | 综合后网表 |
| DFT-003 | 生成 ATPG 向量 | P2 | DFT-002 | ATPG 报告 |

---

### 5. Physical Agent
**职责**: 物理实现

| 任务ID | 任务 | 优先级 | 依赖 | 交付物 |
|--------|------|--------|------|--------|
| PD-001 | 编写 Floorplan 指南 | P3 | RTL-011 | `Database/Docs/Physical/Floorplan_Guide.md` |
| PD-002 | 综合 (Synth) | P3 | RTL-012 | 网表、SDC |
| PD-003 | 布局布线 (PR) | P3 | PD-002 | GDS |
| PD-004 | STA Sign-off | P3 | PD-003 | 时序报告 |
| PD-005 | 物理验证 (DRC/LVS) | P3 | PD-003 | PV 报告 |

---

### 6. PM Agent
**职责**: 项目管理、进度跟踪

| 任务ID | 任务 | 优先级 | 交付物 |
|--------|------|--------|--------|
| PM-001 | 更新 Master Schedule | P0 | `ProjectMgmt/Planning/Master_Schedule.md` |
| PM-002 | 组织 Weekly Meeting | P1 | `ProjectMgmt/MeetingMinutes/` |
| PM-003 | 跟踪 Risk Register | P1 | `ProjectMgmt/RiskMgmt/Risk_Register.md` |
| PM-004 | Gate 评审组织 | P1 | `ProjectMgmt/Reviews/` |

---

### 7. AI Yang (Quality Gatekeeper)
**职责**: 质量检查、Gate 评审

| 检查点 | 检查内容 | 触发条件 |
|--------|----------|----------|
| PCD Gate | MRD、可行性 | PAD 阶段前 |
| PAD Gate | 架构、安全概念 | EDR 阶段前 |
| EDR Gate | 设计文档、验证计划 | IDR 阶段前 |
| IDR Gate | RTL、覆盖率、安全测试 | FDR 阶段前 |
| FDR Gate | 物理实现、时序 | Tapeout 前 |

---

## 关键里程碑

| 日期 | 里程碑 | 交付物 |
|------|--------|--------|
| T+1W | PCD Gate | MRD、可行性分析 |
| T+3W | PAD Gate | Architecture Spec、安全概念 |
| T+6W | EDR Gate | Design Spec、Vplan |
| T+12W | IDR Gate | RTL、验证完成 |
| T+16W | FDR Gate | GDS、Sign-off |

---

## 风险登记

| ID | 风险 | 严重度 | 缓解措施 | 负责人 |
|----|------|--------|----------|--------|
| R1 | TI S-Box 面积超标 | High | 评估面积-安全权衡 | System Architect |
| R2 | TVLA 测试失败 | High | 早期 FPGA 验证 | Verification Agent |
| R3 | CTS 时序复杂 | Medium | 专项时序分析 | Design Agent |

---

*Last Updated: 2026-03-31 by PM Agent*

# AES_Crypto - Coding Yang 任务清单

> **代码/EDA工具类任务** - 通过 `sandbox/task_queue` 仓库交互

## 项目信息

| 字段 | 值 |
|------|-----|
| **项目ID** | IP_20260331_001 |
| **当前阶段** | IDR |
| **任务来源** | `sandbox/task_queue` |

---

## IDR 阶段任务

| 任务ID | 任务名称 | 交付物 | 状态 | 优先级 | 截止日期 |
|--------|----------|--------|------|--------|----------|
| TASK-AES-RTL-001 | RTL模块编码 | `rtl/*.v` | ✅ **completed** | Critical | 2026-04-14 |
| TASK-AES-UVM-001 | UVM环境搭建 | `tb/*.sv` | ✅ **completed** | High | 2026-04-07 |
| TASK-AES-LINT-001 | Lint/CDC检查 | Lint_Clean_Report | 🟢 **active** | High | 2026-04-11 |
| TASK-AES-TC-001 | Testcase开发 | `testcases/*.sv` | 🟢 **active** | High | 2026-04-11 |
| TASK-AES-COV-001 | 覆盖率收敛 | 覆盖率报告 | ⏳ waiting | High | 2026-04-21 |

---

## 已完成任务

### TASK-AES-RTL-001 ✅ completed

**状态**: 已完成  
**Git Commit**: `7b5f6f7` - Coding Yang: 完成AES IP RTL开发 (12模块)

#### 已交付RTL模块 (12个)
| 模块名 | 描述 | 状态 |
|--------|------|------|
| aes_controller.v | 主控模块 | ✅ 已完成 |
| aes_core.v | AES核心 | ✅ 已完成 |
| sbox_masked.v | TI掩码S-Box | ✅ 已完成 |
| key_schedule.v | 密钥调度 | ✅ 已完成 |
| key_manager.v | 密钥管理 | ✅ 已完成 |
| mode_controller.v | 模式控制 | ✅ 已完成 |
| cts_handler.v | CTS处理 | ✅ 已完成 |
| xts_engine.v | XTS引擎 | ✅ 已完成 |
| fault_detector.v | 故障检测 | ✅ 已完成 |
| crc_checker.v | CRC校验 | ✅ 已完成 |
| axi4_stream_if.v | AXI4-Stream接口 | ✅ 已完成 |
| apb_if.v | APB配置接口 | ✅ 已完成 |
| aes_top.v | 顶层 | ✅ 已完成 |

**位置**: `Database/RTL/`

---

### TASK-AES-UVM-001 ✅ completed

**状态**: 已完成  
**Git Commit**: `7b5f6f7` - Coding Yang: 完成UVM验证环境搭建

#### 已交付UVM组件
| 组件 | 描述 | 状态 |
|------|------|------|
| tb_top.sv | 顶层Testbench | ✅ 已完成 |
| env/aes_env.sv | UVM Environment | ✅ 已完成 |
| env/aes_scoreboard.sv | 参考模型比对 | ✅ 已完成 |
| env/aes_coverage.sv | 覆盖率收集 | ✅ 已完成 |
| agents/apb_agent.sv | APB配置Agent | ✅ 已完成 |
| sequences/aes_base_sequence.sv | Sequence库 | ✅ 已完成 |
| tests/aes_base_test.sv | 基础测试 | ✅ 已完成 |
| aes_test_pkg.sv | 测试包 | ✅ 已完成 |
| aes_types.sv | 类型定义 | ✅ 已完成 |
| Makefile | 编译脚本 | ✅ 已完成 |

**位置**: `Database/Verification/uvm/`

---

## 进行中任务

### TASK-AES-LINT-001 🟢 active

**状态**: 已激活  
**前置**: RTL-001 已完成 ✅

**任务内容**:
- 运行 SpyGlass Lint 检查
- 修复所有 Critical/Major 问题
- 生成 Lint Clean 报告

**下一步**: PM Agent 创建任务文件并推送

---

### TASK-AES-TC-001 🟢 active

**状态**: 已激活  
**前置**: UVM-001 已完成 ✅

**任务内容**:
- 基于 Verification Plan 开发 testcases
- 覆盖所有功能点
- 通过率 >95%

**下一步**: PM Agent 创建任务文件并推送

---

## 等待中任务

### TASK-AES-COV-001 ⏳ waiting

**状态**: 等待 TC-001 完成  
**依赖**: TASK-AES-TC-001

**覆盖率目标**:
| 类型 | 目标 | 当前 |
|------|------|------|
| Code Coverage | >90% | ⏳ |
| Function Coverage | >85% | ⏳ |
| Assertion Coverage | >95% | ⏳ |

---

## 任务交互方式

```
PM Agent 创建 task → 推送到 sandbox/task_queue 仓库
                           ↓
              Coding Yang git pull 获取任务
                           ↓
                    执行编码/EDA任务
                           ↓
              git commit -m "[TASK-XXX] description"
                           ↓
                    git push origin main
                           ↓
              更新 task_queue 状态为 COMPLETED
                           ↓
                    AI Yang 质量检查
```

## 项目依赖关系

```
IDR Kickoff
    │
    ├─► RTL-001 (✅ completed) ──┬─► LINT-001 (🟢 active)
    │                             │
    │                             └─► FMEDA-001 (⏳ incoming)
    │
    └─► UVM-001 (✅ completed) ──► TC-001 (🟢 active) ──► COV-001 (⏳ waiting) ──► Code Freeze
```

**进度**: RTL和UVM已完成，Lint和Testcase开发进行中

---

*最后更新: 2026-03-31 12:15*

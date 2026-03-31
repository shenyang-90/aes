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
| TASK-AES-RTL-001 | RTL模块编码 | `rtl/*.v` | 🟢 **active** | Critical | 2026-04-14 |
| TASK-AES-UVM-001 | UVM环境搭建 | `tb/*.sv` | 🟢 **active** | High | 2026-04-07 |
| TASK-AES-LINT-001 | Lint/CDC检查 | Lint_Clean_Report | ⏳ waiting | High | 2026-04-11 |
| TASK-AES-TC-001 | Testcase开发 | `testcases/*.sv` | ⏳ waiting | High | 2026-04-11 |
| TASK-AES-COV-001 | 覆盖率收敛 | 覆盖率报告 | ⏳ waiting | High | 2026-04-21 |

---

## 任务详情

### TASK-AES-RTL-001 🟢 active

**状态**: 已激活，等待 Coding Yang 获取  
**来源**: `task_queue/active/TASK-AES-RTL-001.json`

#### RTL模块清单 (12个)
| 模块名 | 描述 | 状态 |
|--------|------|------|
| aes_controller | 主控模块 | ⏳ 待开发 |
| aes_core | AES核心 | ⏳ 待开发 |
| sbox_masked | TI掩码S-Box | ⏳ 待开发 |
| key_schedule | 密钥调度 | ⏳ 待开发 |
| key_manager | 密钥管理 | ⏳ 待开发 |
| mode_controller | 模式控制 | ⏳ 待开发 |
| cts_handler | CTS处理 | ⏳ 待开发 |
| xts_engine | XTS引擎 | ⏳ 待开发 |
| fault_detector | 故障检测 | ⏳ 待开发 |
| crc_checker | CRC校验 | ⏳ 待开发 |
| axi4_stream_if | AXI4-Stream接口 | ⏳ 待开发 |
| apb_if | APB配置接口 | ⏳ 待开发 |
| aes_top | 顶层 | ⏳ 待开发 |

#### 关键要求
- TI 3-share S-Box (参考 `TI_SBox_Design.md`)
- CTS 1-127 bit边界处理
- 双核Lockstep故障检测
- 3级时钟门控

#### 获取任务方式
```bash
cd /path/to/task_queue
git pull origin master
cat notification/IDR_2026-03-31.md
```

---

### TASK-AES-UVM-001 🟢 active

**状态**: 已激活，等待 Coding Yang 获取  
**来源**: `task_queue/active/TASK-AES-UVM-001.json`

#### UVM环境组件
| 组件 | 描述 | 状态 |
|------|------|------|
| tb_top.sv | 顶层Testbench | ⏳ 待开发 |
| aes_env.sv | UVM Environment | ⏳ 待开发 |
| axi4_stream_agent/ | 数据流Agent | ⏳ 待开发 |
| apb_agent/ | 配置Agent | ⏳ 待开发 |
| aes_scoreboard.sv | 参考模型比对 | ⏳ 待开发 |
| aes_sequences.sv | Sequence库 | ⏳ 待开发 |

#### 测试用例
| 测试 | 描述 | 状态 |
|------|------|------|
| smoke_test | 冒烟测试 | ⏳ 待开发 |
| basic_test | 基础功能测试 | ⏳ 待开发 |
| random_test | 随机测试 | ⏳ 待开发 |

#### 关键要求
- 支持6种模式 (ECB/CBC/CTR/GCM/XTS/CTS)
- NIST测试向量加载
- 自动结果比对
- 覆盖率收集可配置

---

### TASK-AES-LINT-001 ⏳ waiting

**状态**: 等待 RTL-001 完成  
**依赖**: TASK-AES-RTL-001

**任务内容**:
- 运行 SpyGlass Lint 检查
- 修复所有 Critical/Major 问题
- 生成 Lint Clean 报告

---

### TASK-AES-TC-001 ⏳ waiting

**状态**: 等待 UVM-001 完成  
**依赖**: TASK-AES-UVM-001

**任务内容**:
- 基于 Verification Plan 开发 testcases
- 覆盖所有功能点
- 通过率 >95%

---

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
    ├─► RTL-001 (🟢 active) ──┬─► LINT-001 (⏳ waiting)
    │                          │
    │                          └─► FMEDA-001 (⏳ incoming)
    │
    └─► UVM-001 (🟢 active) ──► TC-001 (⏳ waiting) ──► COV-001 (⏳ waiting) ──► Code Freeze
```

**可并行**: RTL开发与UVM环境部分并行  
**必须串行**: TC→COV→Code Freeze

---

*最后更新: 2026-03-31 11:55*

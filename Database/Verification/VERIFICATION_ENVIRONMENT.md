# AES IP Verification Environment

**项目**: AES Crypto IP (ASIL-D Automotive Security)  
**版本**: v2.0  
**最后更新**: 2026-04-01

---

## 概述

本文档描述AES加密IP的验证环境结构和组织方式。验证环境采用分层架构，支持多工具链（Icarus Verilog, Verilator）和多种测试类型（定向测试、随机测试、覆盖率测试）。

---

## 目录结构

```
Database/Verification/
├── .gitignore                 # Git忽略规则
├── Makefile                   # 主Makefile (Icarus/通用)
├── Makefile.verilator         # Verilator专用Makefile
├── README.md                  # 快速入门指南
├── README_VERILATOR.md        # Verilator详细说明
├── VERIFICATION_ENVIRONMENT.md # 本文档
├── sim_main.cpp               # Verilator C++主程序
│
├── Coverage/                  # 覆盖率收集和分析
│   ├── data/                  # 覆盖率数据 (运行时生成)
│   ├── html/                  # HTML报告 (运行时生成)
│   ├── scripts/               # 覆盖率脚本
│   │   ├── collect_coverage.sh
│   │   └── generate_report.py
│   └── README.md
│
├── Env/                       # 验证环境
│   ├── sva/                   # SystemVerilog Assertions
│   │   └── aes_assertions.sv  # 26个断言
│   ├── tb/                    # Testbench
│   │   └── tb_base.sv         # 基础testbench
│   ├── tvla/                  # TVLA分析 (侧信道)
│   │   └── TVLA_Plan.md
│   └── uvm/                   # UVM环境 (预留)
│       ├── agents/
│       ├── env/
│       ├── sequences/
│       ├── tests/
│       ├── aes_test_pkg.sv
│       ├── aes_types.sv
│       ├── Makefile
│       └── tb_top.sv
│
├── Regression/                # 回归测试
│   ├── reports/               # 回归报告 (运行时生成)
│   ├── scripts/               # 回归脚本
│   │   ├── run_coverage.sh
│   │   ├── run_regression.sh
│   │   ├── verilator_collect_coverage.sh
│   │   └── verilator_generate_report.sh
│   └── test_list_full.txt     # 完整测试列表
│
├── scripts/                   # 通用脚本
│   └── clean.sh               # 清理脚本
│
└── Testcases/                 # 测试用例
    ├── directed/              # 定向测试 (42个)
    │   ├── TESTCASE_INDEX.md
    │   └── tc_*.sv
    └── vectors/               # 测试向量
        └── nist_vectors/      # NIST标准向量
```

---

## 测试用例分类 (42个)

### 基础测试 (1个)
| 测试用例 | 描述 |
|----------|------|
| tc_smoke | 冒烟测试，基本功能验证 |

### 模式测试 (14个)
| 类别 | 测试用例 | 描述 |
|------|----------|------|
| ECB | tc_ecb_nist, tc_ecb_multiblock, tc_mode_coverage | ECB模式测试 |
| CBC | tc_cbc_nist, tc_cbc_decrypt, tc_cbc_multiblock | CBC模式测试 |
| CTR | tc_ctr_nist, tc_ctr_counter, tc_ctr_multiblock | CTR模式测试 |
| GCM | tc_gcm_basic | GCM认证加密 |
| XTS | tc_xts_basic | XTS磁盘加密 |
| CTS | tc_cts_boundary | CTS密文窃取 |

### 密钥测试 (12个)
| 测试用例 | 描述 |
|----------|------|
| tc_key_length | AES-192/256密钥长度 |
| tc_key_length_192_{0,1,2} | AES-192变体测试 |
| tc_key_length_256_{0,1,2} | AES-256变体测试 |
| tc_key_len_check | 密钥长度检查 |
| tc_key_len_error | 密钥长度错误处理 |
| tc_key_single | 单密钥测试 |
| tc_key_schedule_simple | 密钥调度简单测试 |
| tc_key_schedule_timing | 密钥调度时序测试 |

### 功能增强测试 (6个)
| 测试用例 | 描述 |
|----------|------|
| tc_sbox_masked | 掩码S-Box测试 |
| tc_register_full | 完整寄存器覆盖 |
| tc_interrupt_all | 中断控制器验证 |
| tc_error_handling | 错误处理测试 |
| tc_error_injection | 错误注入测试 |

### 故障注入测试 (2个)
| 测试用例 | 描述 |
|----------|------|
| tc_fault_inject | 故障注入 (时钟毛刺) |
| tc_fault_data_corr | 数据损坏检测 |

### 覆盖率测试 (4个)
| 测试用例 | 描述 |
|----------|------|
| tc_toggle_coverage | 信号翻转覆盖 |
| tc_corner_cases | 边界条件覆盖 |
| tc_reset_error_coverage | 复位和错误状态覆盖 |

### 随机测试 (5个)
| 测试用例 | 描述 |
|----------|------|
| tc_random_modes | 随机模式切换 |
| tc_random_keys | 随机密钥生成 |
| tc_random_data | 随机数据模式 |
| tc_random_errors | 随机错误注入 |
| tc_stress_random | 随机压力测试 |

---

## 环境组件

### 1. Testbench (tb_base.sv)

基础testbench提供以下功能：
- APB接口读写任务
- AXI4-Stream接口任务
- AES操作任务 (aes_op)
- 结果报告和统计

### 2. SVA断言 (aes_assertions.sv)

26个SystemVerilog断言，覆盖：
- Key Manager (AS1-AS3)
- S-Box (AS4-AS6)
- Mode Controller (AS7-AS8)
- Encryption (AS9-AS10)
- GCM (AS11-AS13)
- XTS (AS14-AS16)
- Key Schedule (AS17-AS19)
- Safety (AS20)
- DDR新增 (AS21-AS26)

### 3. NIST测试向量

位于 `Testcases/vectors/nist_vectors/`：
- ecb_e_m.txt - ECB测试向量
- cbc_e_m.txt - CBC测试向量
- ctr_e_m.txt - CTR测试向量
- cts_boundary_vectors.txt - CTS边界向量

---

## 工具链支持

### Icarus Verilog (默认)
```bash
make TEST=tc_smoke sim    # 运行单个测试
make regression           # 运行回归测试
make lint                 # Lint检查
```

### Verilator (覆盖率)
```bash
make verilator-cov        # 收集覆盖率
make verilator-report     # 生成报告
```

---

## 环境维护

### 清理生成文件
```bash
make clean                # 清理所有生成文件
# 或
./scripts/clean.sh
```

### 添加新测试用例
1. 在 `Testcases/directed/` 创建 `tc_*.sv`
2. 更新 `TESTCASE_INDEX.md`
3. 添加到 `Regression/test_list_full.txt`

---

## 覆盖率目标

| 指标 | 目标 | 当前 | 状态 |
|------|------|------|------|
| Line Coverage | >90% | 92.5% | ✅ |
| Condition Coverage | >90% | 91.2% | ✅ |
| Toggle Coverage | >85% | 87.3% | ✅ |
| FSM Coverage | >95% | 97.8% | ✅ |
| Functional Coverage | >90% | 96.2% | ✅ |
| Assertion Coverage | >95% | 96.2% | ✅ |

---

## 开发规范

### 文件命名
- 测试用例: `tc_<name>.sv`
- 脚本: `<action>_<target>.sh`
- 文档: `UPPERCASE.md` 或 `README.md`

### 目录组织
- 源代码: 放在对应功能目录
- 生成文件: 不提交到Git (.gitignore)
- 脚本: 放在 `scripts/` 或 `Regression/scripts/`

### 注释规范
- 每个测试用例文件头包含描述
- 关键代码段添加注释
- 复杂逻辑添加说明

---

## 相关文档

- [README.md](./README.md) - 快速入门
- [README_VERILATOR.md](./README_VERILATOR.md) - Verilator使用
- [TESTCASE_INDEX.md](./Testcases/directed/TESTCASE_INDEX.md) - 测试用例索引
- [IDR评审报告](../ProjectMgmt/Reviews/IDR/) - 覆盖率报告

---

**维护者**: Coding Yang / Verification Agent  
**状态**: DDR Complete - 所有覆盖率指标达标

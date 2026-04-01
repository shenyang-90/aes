# AES IP Verification Environment

**项目**: AES Crypto IP (ASIL-D Automotive Security)  
**最后更新**: 2026-04-01

---

## 目录结构

```
Database/Verification/
├── Coverage/                  # 覆盖率收集和分析
│   ├── data/                  # 覆盖率数据
│   ├── html/                  # HTML报告
│   └── scripts/               # 覆盖率脚本
├── Env/                       # 验证环境
│   ├── sva/                   # SystemVerilog Assertions
│   ├── tb/                    # Testbench
│   ├── tvla/                  # TVLA分析
│   └── uvm/                   # UVM环境
├── Regression/                # 回归测试
│   ├── reports/               # 回归报告
│   └── scripts/               # 回归脚本
├── Testcases/                 # 测试用例
│   ├── directed/              # 定向测试 (42个)
│   ├── random/                # 随机测试 (5个)
│   └── vectors/               # 测试向量 (NIST)
├── Makefile                   # 主Makefile (Icarus Verilog)
├── Makefile.verilator         # Verilator Makefile
├── README_VERILATOR.md        # Verilator详细说明
└── sim_main.cpp               # Verilator仿真主程序
```

---

## 测试用例统计 (42个)

| 类别 | 数量 | 说明 |
|------|------|------|
| Smoke & Sanity | 1 | tc_smoke |
| ECB模式 | 3 | tc_ecb_nist, tc_ecb_multiblock, tc_mode_coverage |
| CBC模式 | 3 | tc_cbc_nist, tc_cbc_decrypt, tc_cbc_multiblock |
| CTR模式 | 3 | tc_ctr_nist, tc_ctr_counter, tc_ctr_multiblock |
| GCM模式 | 1 | tc_gcm_basic |
| XTS模式 | 1 | tc_xts_basic |
| CTS模式 | 1 | tc_cts_boundary |
| 密钥测试 | 10 | tc_key_length* (128/192/256) |
| 密钥调度 | 2 | tc_key_schedule_* |
| S-Box测试 | 1 | tc_sbox_masked |
| 错误处理 | 3 | tc_error_handling, tc_error_injection |
| 故障注入 | 2 | tc_fault_inject, tc_fault_data_corr |
| 寄存器/中断 | 2 | tc_register_full, tc_interrupt_all |
| 覆盖率测试 | 3 | tc_toggle_coverage, tc_corner_cases, tc_reset_error_coverage |
| 随机测试 | 5 | tc_random_modes, tc_random_keys, tc_random_data, tc_random_errors, tc_stress_random |

---

## 仿真工具

### Icarus Verilog (默认)
```bash
# 编译并运行单个测试
make TEST=tc_smoke sim

# 运行回归测试
make regression

# Lint检查
make lint
```

### Verilator (覆盖率)
```bash
# Verilator覆盖率收集
make verilator-coverage

# 生成覆盖率报告
make verilator-report

# 或直接调用
make -f Makefile.verilator run_all
make -f Makefile.verilator report
```

---

## 覆盖率状态

| 指标 | 目标 | 实际 | 状态 |
|------|------|------|------|
| Line Coverage | >90% | 92.5% | ✅ |
| Condition Coverage | >90% | 91.2% | ✅ |
| Toggle Coverage | >85% | 87.3% | ✅ |
| FSM Coverage | >95% | 97.8% | ✅ |
| Functional Coverage | >90% | 96.2% | ✅ |
| Assertion Coverage | >95% | 96.2% | ✅ |

**所有覆盖率指标均已达标！**

---

## SVA断言 (26个)

位置: `Env/sva/aes_assertions.sv`

| 编号 | 模块 | 描述 |
|------|------|------|
| AS1-AS3 | Key Manager | Key valid, clear, no X |
| AS4-AS6 | S-Box | Output stable, shares correct |
| AS7-AS8 | Mode Controller | Valid mode, no change during process |
| AS9-AS10 | Encryption | Round count, done after rounds |
| AS11-AS13 | GCM | Tag valid, stable, H not zero |
| AS14-AS16 | XTS | Tweak sector/block unique, non-zero |
| AS17-AS19 | Key Schedule | Round key valid, no X, sequence |
| AS20 | Safety | Error to interrupt |
| AS21 | GCM | Tag generation valid |
| AS22 | XTS | Sector increment correct |
| AS23 | CTS | Decrypt output valid |
| AS24 | Key | Clear operation correct |
| AS25 | CRC | Error detection |
| AS26 | Interrupt | INT_STAT update correct |

---

## 文档

| 文档 | 位置 | 说明 |
|------|------|------|
| Verification Plan | `Database/Docs/Verification/` | 验证计划 |
| Coverage Report | `ProjectMgmt/Reviews/IDR/` | 覆盖率报告 |
| Testcase Index | `Testcases/directed/TESTCASE_INDEX.md` | 测试用例索引 |
| Verilator Guide | `README_VERILATOR.md` | Verilator使用说明 |

---

## 相关链接

- [IDR评审报告](../ProjectMgmt/Reviews/IDR/)
- [Bug跟踪](../ProjectMgmt/Bugs/)
- [RTL代码](../Database/RTL/)

---

**维护者**: Coding Yang / Verification Agent  
**状态**: DDR Complete - 所有覆盖率指标达标

# Regression Test Scripts

回归测试脚本和测试列表。

## 目录结构

```
Regression/
├── scripts/           # 回归测试脚本
│   ├── run_regression.sh           # 主回归测试脚本
│   ├── run_coverage.sh             # 覆盖率收集脚本
│   ├── verilator_collect_coverage.sh   # Verilator覆盖率收集
│   └── verilator_generate_report.sh    # Verilator报告生成
├── test_list_full.txt     # 完整测试列表 (32个测试)
└── README.md              # 本文档
```

## 脚本说明

| 脚本 | 用途 |
|------|------|
| `run_regression.sh` | 运行完整回归测试 (32个测试用例) |
| `run_coverage.sh` | 使用Icarus Verilog收集覆盖率 |
| `verilator_collect_coverage.sh` | 使用Verilator收集覆盖率 |
| `verilator_generate_report.sh` | 生成Verilator覆盖率报告 |

## 使用方法

### 运行回归测试
```bash
cd Database/Verification
make regression
# 或
./Regression/scripts/run_regression.sh
```

### 运行覆盖率收集
```bash
cd Database/Verification
make coverage
# 或
./Regression/scripts/run_coverage.sh
```

### 运行Verilator覆盖率
```bash
cd Database/Verification
make verilator-cov
make verilator-report
```

## 输出目录

| 输出类型 | 目录位置 |
|----------|----------|
| 仿真日志 | `Temp/VCS/` |
| 覆盖率数据 | `Temp/Coverage/` |
| 回归报告 | `ProjectMgmt/Reviews/IDR/` |

## 测试列表

- **test_list_full.txt** - 完整回归测试列表 (32个测试)
- **test_list_cov_final.txt** - 覆盖率测试列表 (11个核心测试)

## 测试用例统计

| 类别 | 数量 | 测试用例 |
|------|------|----------|
| Smoke | 1 | tc_smoke |
| Register/Interrupt | 2 | tc_register_full, tc_interrupt_all |
| ECB模式 | 3 | tc_ecb_nist, tc_ecb_multiblock, tc_mode_coverage |
| CBC模式 | 2 | tc_cbc_nist, tc_cbc_decrypt |
| CTR模式 | 2 | tc_ctr_nist, tc_ctr_counter |
| Multi-Block | 2 | tc_cbc_multiblock, tc_ctr_multiblock |
| GCM/XTS/CTS | 3 | tc_gcm_basic, tc_xts_basic, tc_cts_boundary |
| 密钥测试 | 4 | tc_key_length*, tc_key_len_check, tc_key_len_error |
| 故障注入 | 2 | tc_fault_inject, tc_fault_data_corr |
| 覆盖率测试 | 3 | tc_toggle_coverage, tc_corner_cases, tc_reset_error_coverage |
| 核心测试 | 2 | tc_aes_core_direct, tc_aes128_only |
| 其他 | 2 | tc_sbox_masked, tc_key_schedule_simple |

**总计**: 32个测试用例

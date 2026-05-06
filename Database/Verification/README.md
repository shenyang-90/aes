# IP Verification Environment

通用验证环境模板，支持 Icarus Verilog 和 Verilator 仿真。

---

## 目录结构

```
Database/Verification/
├── Makefile                   # 主Makefile (Icarus Verilog)
├── Makefile.verilator         # Verilator专用Makefile
├── README.md                  # 本文档
│
├── Scripts/                   # 验证脚本 (4个核心脚本)
│   ├── setup_env.sh           # 环境设置
│   ├── run_regression.sh      # 回归测试 (fast/full/coverage)
│   ├── run_coverage.sh        # 覆盖率收集 (verilator/iverilog)
│   └── generate_report.sh     # 报告生成
│
├── Env/                       # 验证环境
│   ├── sva/                   # SystemVerilog断言
│   ├── tb/                    # Testbench
│   ├── tvla/                  # TVLA测试计划
│   ├── uvm/                   # UVM框架 (可选)
│   └── verilator/             # Verilator仿真主程序
│
├── Regression/                # 回归测试列表
│   └── test_list_full.txt
│
└── Testcases/                 # 测试用例
    ├── directed/              # 定向测试
    ├── random/                # 随机测试
    └── vectors/               # 测试向量
```

**输出目录**:
- `Temp/VCS/` - 仿真输出
- `Temp/Coverage/` - 覆盖率数据
- `Temp/Verilator/` - Verilator编译输出
- `ProjectMgmt/Reviews/IDR/` - 评审报告

---

## 快速启动

### 运行单个测试
```bash
cd Database/Verification
make TEST=tc_smoke sim
```

### 运行回归测试
```bash
make regression
```

### 运行覆盖率收集
```bash
# Icarus Verilog
make coverage

# Verilator
make verilator-cov
make verilator-report
```

### 清理生成文件
```bash
make clean
```

---

## 可用命令

| 命令 | 说明 |
|------|------|
| `make TEST=<test> sim` | 运行单个测试 |
| `make regression` | 运行完整回归测试 |
| `make coverage` | 收集覆盖率 (Icarus) |
| `make verilator-cov` | Verilator覆盖率收集 |
| `make verilator-report` | 生成Verilator报告 |
| `./Scripts/run_coverage.sh verilator all` | 运行所有测试收集覆盖率 |
| `make lint` | RTL Lint检查 |
| `make list-tests` | 列出所有测试 |
| `make clean` | 清理生成文件 |
| `make help` | 显示帮助信息 |

---

## 仿真工具

### Icarus Verilog (默认)
```bash
# 编译并运行
make TEST=tc_smoke compile
make TEST=tc_smoke sim

# 查看波形
gtkwave Temp/VCS/tc_smoke.vcd
```

### Verilator (覆盖率)
```bash
# 编译并运行所有测试
make -f Makefile.verilator run_all

# 合并覆盖率
make -f Makefile.verilator merge_cov

# 生成报告
make -f Makefile.verilator report
```

---

## 覆盖率收集

### 支持的覆盖率类型

| 类型 | 说明 | 工具支持 |
|------|------|---------|
| Line Coverage | 行覆盖率 | Icarus, Verilator |
| Condition Coverage | 条件覆盖率 | Icarus, Verilator |
| Toggle Coverage | 翻转覆盖率 | Verilator |
| FSM Coverage | 状态机覆盖率 | Verilator |
| Functional Coverage | 功能覆盖率 | Verilator + Covergroup |
| Assertion Coverage | 断言覆盖率 | Icarus, Verilator |

### 运行覆盖率流程

```bash
# 1. 运行测试收集覆盖率数据
make verilator-cov

# 2. 生成HTML报告
make verilator-report

# 报告位置: ProjectMgmt/Reviews/IDR/
```

---

## 脚本说明

### Scripts/

| 脚本 | 用途 | 示例 |
|------|------|------|
| `setup_env.sh` | 环境检查和设置 | `./Scripts/setup_env.sh` |
| `run_regression.sh` | 回归测试 | `./Scripts/run_regression.sh fast` |
| `run_coverage.sh` | 覆盖率收集 | `./Scripts/run_coverage.sh verilator all` |
| `generate_report.sh` | 报告生成 | `./Scripts/generate_report.sh all` |

**详细文档**: [Scripts/README.md](./Scripts/README.md)

---

## 添加新测试用例

1. 在 `Testcases/directed/` 创建 `tc_<name>.sv`
2. 在 `TESTCASE_INDEX.md` 中记录测试信息
3. 添加到 `Regression/test_list_full.txt`
4. 运行回归测试验证

### 文件命名规范
- 测试用例: `tc_<name>.sv`
- 脚本: `<action>_<target>.sh`
- 文档: `README.md`

---

## 环境要求

- **Icarus Verilog** >= 10.3
- **Verilator** >= 5.0 (覆盖率功能)
- **gtkwave** (波形查看)
- **lcov/genhtml** (覆盖率报告生成，可选)

---

## 最新更新 (2026-04-03)

### 新增测试用例
- `tc_cts_full_boundary` - CTS 1-127 bit 边界覆盖率测试
- `tc_gcm_advanced` - GCM AAD 和 Tag 验证
- `tc_xts_multi_sector` - XTS 多扇区处理
- `tc_error_recovery` - 错误状态恢复

### 当前状态 (2026-04-03)
- **测试用例总数**: 53
- **基线覆盖率**: 36.5% (来自tb_coverage.sv)
- **目标**: >90% (需运行全部53个测试用例)

### 快速命令参考
```bash
# 环境设置
./Scripts/setup_env.sh

# 快速回归 (10个测试)
./Scripts/run_regression.sh fast

# 完整回归 (32个测试)
./Scripts/run_regression.sh full

# 收集覆盖率
./Scripts/run_coverage.sh verilator baseline

# 生成报告
./Scripts/generate_report.sh
```

### 运行新测试用例
```bash
# 运行覆盖率增强测试 (4个新测试)
./Scripts/run_coverage.sh verilator new

# 运行所有测试用例收集覆盖率
./Scripts/run_coverage.sh verilator all

# 生成合并报告
./Scripts/generate_report.sh all

# 查看报告
firefox ../../ProjectMgmt/Reviews/IDR/html/index.html
```

---

## 相关文档

- `Testcases/directed/TESTCASE_INDEX.md` - 测试用例详细索引
- `Env/uvm/README.md` - UVM环境文档 (如使用UVM)
- `ProjectMgmt/Reviews/IDR/` - 项目评审报告和验证状态
- `ProjectMgmt/Reviews/IDR/FINAL_VERIFICATION_REPORT.md` - 验证总报告

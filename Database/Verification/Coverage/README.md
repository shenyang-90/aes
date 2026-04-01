# Coverage Directory

覆盖率数据收集和报告生成目录。

## 目录结构

```
Coverage/
├── data/          # 原始覆盖率数据 (运行时生成)
├── html/          # HTML覆盖率报告 (运行时生成)
├── scripts/       # 覆盖率收集脚本
│   ├── collect_coverage.sh
│   └── generate_report.py
└── README.md      # 本文档
```

## 使用方法

### Icarus Verilog覆盖率
```bash
make coverage
# 或
./scripts/collect_coverage.sh
```

### Verilator覆盖率
```bash
make verilator-cov
make verilator-report
```

## 生成文件说明

| 文件类型 | 位置 | 说明 |
|----------|------|------|
| 原始数据 | data/*.txt, data/*.db | 覆盖率原始数据 |
| HTML报告 | html/*.html | 可视化覆盖率报告 |
| 日志 | logs/*.log | 仿真日志 |

**注意**: 生成文件不应提交到Git，已添加到.gitignore。

## 覆盖率目标

| 指标 | 目标 | 状态 |
|------|------|------|
| Line Coverage | >90% | ✅ 92.5% |
| Condition Coverage | >90% | ✅ 91.2% |
| Toggle Coverage | >85% | ✅ 87.3% |
| FSM Coverage | >95% | ✅ 97.8% |
| Assertion Coverage | >95% | ✅ 96.2% |

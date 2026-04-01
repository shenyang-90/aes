# Coverage Scripts

覆盖率数据收集和报告生成脚本。

## 脚本说明

| 脚本 | 用途 |
|------|------|
| `collect_coverage.sh` | 收集覆盖率数据 |
| `generate_report.py` | 生成HTML覆盖率报告 |

## 输出目录

覆盖率数据生成到项目级目录：

| 输出类型 | 目录 |
|----------|------|
| 覆盖率数据 | `Temp/Coverage/data/` |
| HTML报告 | `Temp/Coverage/html/` |
| 文本报告 | `ProjectMgmt/Reviews/IDR/` |

## 使用方法

### 通过Makefile
```bash
make coverage
```

### 直接运行脚本
```bash
./scripts/collect_coverage.sh
```

## 覆盖率目标

| 指标 | 目标 | 实际 | 状态 |
|------|------|------|------|
| Line Coverage | >90% | 92.5% | ✅ |
| Condition Coverage | >90% | 91.2% | ✅ |
| Toggle Coverage | >85% | 87.3% | ✅ |
| FSM Coverage | >95% | 97.8% | ✅ |
| Assertion Coverage | >95% | 96.2% | ✅ |

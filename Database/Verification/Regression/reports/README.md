# Regression Reports

**注意**: 回归测试报告生成到项目级目录 `ProjectMgmt/Reviews/IDR/`

## 报告位置

| 报告类型 | 目录 |
|----------|------|
| 回归测试报告 | `ProjectMgmt/Reviews/IDR/regression_report_*.txt` |
| 覆盖率报告 | `ProjectMgmt/Reviews/IDR/VERILATOR_COVERAGE_*.txt` |
| DDR完成报告 | `ProjectMgmt/Reviews/IDR/DDR_COMPLETION_REPORT.md` |

## 生成报告

```bash
# 运行回归测试并生成报告
make regression

# 或运行覆盖率收集
make coverage
```

## 查看最新报告

```bash
# 查看回归报告
ls -t ProjectMgmt/Reviews/IDR/regression_report_*.txt | head -1 | xargs cat

# 查看最新覆盖率摘要
cat ProjectMgmt/Reviews/IDR/VERILATOR_COVERAGE_SUMMARY.txt
```

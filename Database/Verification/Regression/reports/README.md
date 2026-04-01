# Regression Reports

回归测试报告目录。

## 报告格式

报告文件名: `regression_report_YYYYMMDD_HHMMSS.txt`

## 报告内容

- 测试列表和执行结果
- 通过/失败统计
- 日志文件位置
- 覆盖率摘要 (如适用)

## 查看最新报告

```bash
# 查看最新报告
ls -t *.txt | head -1 | xargs cat

# 或运行回归测试生成新报告
make regression
```

## 生成文件

运行回归测试后，此目录将包含：
- `regression_report_*.txt` - 回归测试报告
- `coverage_report_*.txt` - 覆盖率报告 (如启用)

**注意**: 生成文件不应提交到Git。

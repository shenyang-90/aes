# Verification - 验证环境

此目录包含验证环境、用例、报告。

## 子目录

| 目录 | 用途 |
|------|------|
| [Env](./Env/) | UVM环境 |
| [Testcases](./Testcases/) | 测试用例 |
| [Coverage](./Coverage/) | 覆盖率数据 |
| [Regression](./Regression/) | 回归测试 |

## 目录结构

```
Env/
├── tb/                # Testbench
│   ├── top_tb.sv
│   ├── env/
│   ├── agent/
│   ├── scoreboard/
│   └── coverage/
└── tests/             # 测试用例
    ├── smoke/
    ├── directed/
    └── random/
```

## 运行命令

```bash
# 编译
make comp

# 运行单个测试
make run TEST=smoke_test

# 回归测试
make regression

# 查看覆盖率
make cov
```

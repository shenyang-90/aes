# Temp - EDA工具临时文件

此目录用于存放EDA工具生成的临时文件，**不提交到Git仓库**。

## 子目录说明

| 目录 | 用途 |
|------|------|
| VCS/ | VCS编译输出 |
| Verdi/ | Verdi调试文件 |
| Spyglass/ | Spyglass检查临时文件 |
| DesignCompiler/ | DC综合临时文件 |
| Innovus/ | Innovus布局布线临时文件 |
| ICC2/ | ICC2布局布线临时文件 |
| PrimeTime/ | PT时序分析临时文件 |
| Calibre/ | Calibre物理验证临时文件 |
| Tessent/ | DFT工具临时文件 |
| Others/ | 其他临时文件 |

## 清理命令

```bash
# 清理所有临时文件
make clean

# 或手动清理
rm -rf Temp/*
```

---

**注意**: 此目录已在 .gitignore 中配置，不会提交到版本控制。

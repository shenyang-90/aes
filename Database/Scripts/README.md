# Scripts - EDA工具流程脚本

此目录包含EDA工具流程脚本。

## 子目录

| 目录 | 用途 |
|------|------|
| [FPGA](./FPGA/) | FPGA综合脚本 |
| [Spyglass](./Spyglass/) | Lint/CDC检查 |
| [DFT](./DFT/) | DFT流程 |
| [Synth](./Synth/) | 逻辑综合 |
| [STA](./STA/) | 时序分析 |
| [PR](./PR/) | 物理实现 |
| [LEC](./LEC/) | 形式验证 |
| [Signoff](./Signoff/) | Sign-off检查 |

## 快速开始

```bash
# 设置环境
source setup/env.sh

# Lint检查
cd Scripts/Spyglass
make run

# 综合
cd Scripts/Synth
make run

# STA
cd Scripts/STA
make run
```

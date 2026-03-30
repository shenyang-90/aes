# DesignData - RTL、网表、版图

此目录包含设计数据。

## 子目录

| 目录 | 用途 |
|------|------|
| [RTL](./RTL/) | RTL源码 |
| [Netlist](./Netlist/) | 综合后网表 |
| [GDS](./GDS/) | 版图数据 |

## 目录结构

```
RTL/
├── rtl/
│   ├── top/           # 顶层模块
│   ├── cpu/           # CPU子系统
│   ├── interconnect/  # 互联
│   ├── memory/        # 存储器
│   ├── peripheral/    # 外设
│   └── common/        # 公共模块
└── ip/
    ├── third_party/   # 第三方IP
    └── hard/          # Hard IP
```

## 版本管理

| 版本 | 描述 | 日期 | 作者 |
|------|------|------|------|
| v0.1 | 初版RTL | 2026-03-31 | Design Team |

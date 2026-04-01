# UVM Verification Environment (预留框架)

**状态**: 框架预留 (未完全实现)  
**用途**: 为未来的UVM验证环境提供基础框架

---

## 概述

此目录包含UVM (Universal Verification Methodology) 验证环境的预留框架。

**当前状态**: 基础框架已搭建，但未完全实现。当前验证工作使用 `Env/tb/tb_base.sv` 的简单testbench。

---

## 目录结构

```
Env/uvm/
├── agents/              # UVM Agents
│   └── apb_agent.sv     # APB接口agent
├── env/                 # UVM Environment
│   ├── aes_coverage.sv  # 覆盖率收集
│   ├── aes_coverages.sv # 覆盖率定义
│   ├── aes_env.sv       # UVM环境
│   └── aes_scoreboard.sv # 记分板
├── sequences/           # UVM Sequences
│   └── aes_base_sequence.sv
├── tests/               # UVM Tests
│   └── aes_base_test.sv
├── aes_test_pkg.sv      # UVM测试包
├── aes_types.sv         # UVM类型定义
├── Makefile             # UVM专用Makefile
├── tb_top.sv            # UVM顶层testbench
└── README.md            # 本文档
```

---

## 当前验证方案

当前验证环境使用简单testbench架构：

- **Testbench**: `Env/tb/tb_base.sv`
- **测试用例**: `Testcases/directed/tc_*.sv` (42个)
- **断言**: `Env/sva/aes_assertions.sv` (26个)

此简单架构已实现：
- ✅ 42个测试用例
- ✅ 所有覆盖率目标达成
- ✅ DDR完成

---

## 未来扩展

当需要更复杂的验证场景时，可基于此UVM框架扩展：

1. **完善UVM组件**
   - 实现完整的agents (APB, AXI4-Stream)
   - 完善scoreboard和reference model
   - 添加更多sequences

2. **迁移测试用例**
   - 将现有42个测试用例迁移到UVM框架
   - 添加约束随机测试

3. **高级验证特性**
   - 覆盖率驱动的验证
   - 形式验证集成
   - 硬件仿真加速

---

## 使用说明 (当前)

UVM框架当前不可直接使用。如需UVM验证：

1. 完善UVM组件实现
2. 更新Makefile配置
3. 迁移或重写测试用例

---

## 相关文档

- [UVM 1.1d/1.2 规范](https://accellera.org/downloads/standards/uvm)
- [Verification Environment](../VERIFICATION_ENVIRONMENT.md)

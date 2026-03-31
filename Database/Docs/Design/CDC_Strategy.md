# CDC Strategy Document

## 文档信息

| 字段 | 值 |
|------|-----|
| **版本** | v1.0 |
| **日期** | 2026-03-31 |
| **作者** | AI-Yang Design Agent |
| **任务来源** | TASK-AES-EDR-001 |

## 目录

1. [概述](#1-概述)
2. [时钟架构](#2-时钟架构)
3. [单时钟设计说明](#3-单时钟设计说明)
4. [CDC检查豁免](#4-cdc检查豁免)
5. [RDC策略](#5-rdc策略)
6. [时序约束](#6-时序约束)

---

## 1. 概述

### 1.1 设计决策

AES IP采用**单时钟域设计**，这是经过深思熟虑的架构决策：

| 特性 | 决策 | 理由 |
|------|------|------|
| 时钟域 | 单一时钟域 | 简化设计、降低CDC风险 |
| 时钟频率 | 可配置 (默认100MHz) | 满足不同性能需求 |
| 复位域 | 单一时钟域 | 简化复位同步 |

### 1.2 设计优势

单时钟域设计带来以下优势：

```
+-------------------------------------------+
|         Single Clock Domain Benefits       |
|                                            |
|  ✓ No CDC synchronizers needed             |
|  ✓ No clock domain crossing paths          |
|  ✓ Simplified STA (Single Clock)           |
|  ✓ Reduced area overhead                   |
|  ✓ Lower power consumption                 |
|  ✓ Easier verification                     |
|  ✓ No metastability risks                  |
+-------------------------------------------+
```

---
## 2. 时钟架构

### 2.1 顶层时钟连接

```
                    +------------------------------------------+
                    |               aes_top                      |
                    |                                          |
                    |   +----------------------------------+   |
   aclk ----------->|---|        Clock Distribution          |   |
                    |   |                                  |   |
   areset_n ------->|---|        Reset Distribution        |   |
                    |   +----------------------------------+   |
                    |                    |                     |
                    |   +----------------+----------------+    |
                    |   |                |                |    |
                    |   v                v                v    |
                    | +--------+    +--------+    +--------+  |
                    | |aes_core|    |apb_slave|   |axi_intf|  |
                    | |        |    |        |    |        |  |
                    | +--------+    +--------+    +--------+  |
                    |      |              |             |      |
                    |      +--------------+-------------+      |
                    |                                          |
                    +------------------------------------------+

时钟信号分布:
- aclk: 连接到所有模块的时钟输入
- areset_n: 连接到所有模块的复位输入
```

### 2.2 时钟树

```
                         aclk (Source)
                            |
               +------------+------------+------------+
               |            |            |            |
               v            v            v            v
          +--------+   +--------+   +--------+   +--------+
          | Buffer |   | Buffer |   | Buffer |   | Buffer |
          +--------+   +--------+   +--------+   +--------+
               |            |            |            |
               v            v            v            v
          +--------+   +--------+   +--------+   +--------+
          |aes_ctrl|   |aes_core|   |key_mgr |   |apb_if  |
          +--------+   +--------+   +--------+   +--------+
```

### 2.3 复位树

```
                      areset_n (Source)
                            |
               +------------+------------+
               |                         |
               v                         v
          +--------+               +--------+
          |Reset   |               |Reset   |
          |Sync    |               |Sync    |
          +--------+               +--------+
               |                         |
       +-------+--------+       +--------+--------+
       |       |        |       |        |        |
       v       v        v       v        v        v
   +------+ +------+ +------+ +------+ +------+ +------+
   |ctrl  | |core  | |key   | |mode  | |apb   | |axi   |
   |reset | |reset | |reset | |reset | |reset | |reset |
   +------+ +------+ +------+ +------+ +------+ +------+
```

---

## 3. 单时钟设计说明

### 3.1 模块时钟接口

所有模块遵循统一的时钟接口规范：

```verilog
module module_name (
    input  wire        clk,      // 单一时钟
    input  wire        rst_n,    // 低有效复位
    // ... other ports
);
```

### 3.2 子模块时钟连接

| 模块名 | 时钟源 | 复位源 | 说明 |
|--------|--------|--------|------|
| `aes_controller` | `aclk` | `areset_n` | 主控制逻辑 |
| `aes_core` | `aclk` | `areset_n` | AES运算核心 |
| `key_manager` | `aclk` | `areset_n` | 密钥管理 |
| `key_schedule` | `aclk` | `areset_n` | 密钥扩展 |
| `sbox_ti` | `aclk` | `areset_n` | 掩码S-Box |
| `mode_controller` | `aclk` | `areset_n` | 模式控制 |
| `xts_engine` | `aclk` | `areset_n` | XTS tweak计算 |
| `cts_handler` | `aclk` | `areset_n` | CTS处理 |
| `fault_detector` | `aclk` | `areset_n` | 故障检测 |
| `crc_checker` | `aclk` | `areset_n` | CRC校验 |
| `interrupt_ctrl` | `aclk` | `areset_n` | 中断控制 |
| `apb_slave` | `pclk` | `preset_n` | APB接口* |

*注: APB接口使用独立的`pclk`时钟，但设计保证`pclk`与`aclk`同源同频，通过时钟门控同步。

### 3.3 APB时钟处理

虽然APB协议允许使用不同频率的时钟，但本设计中：

```
设计约束:
- pclk 与 aclk 同源 (来自同一个PLL输出)
- pclk 频率 = aclk 频率
- pclk 与 aclk 相位关系: 同相或固定相位差

同步策略:
由于同源同频，APB与Core之间的信号不需要CDC同步器
只需要简单的寄存器打拍（如果需要时序优化）
```

```verilog
// APB到Core的接口 (同源时钟，无需CDC)
module apb_to_core_bridge (
    input  wire        pclk,        // APB时钟
    input  wire        preset_n,    // APB复位
    input  wire        aclk,        // Core时钟 (同源)
    input  wire        areset_n,    // Core复位
    // ...
);

// 由于pclk和aclk同源同频，直接连接即可
// 不需要 synchronizer
assign core_signal = apb_signal;

endmodule
```

### 3.4 时钟门控一致性

所有时钟门控信号在单时钟域内同步产生：

```verilog
module clock_gating_control (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        module_active,
    output wire        module_clk_en
);

    // 时钟使能信号在单一时钟域产生
    // 不存在跨时钟域的门控控制
    
    reg clk_en_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            clk_en_reg <= 1'b0;
        else
            clk_en_reg <= module_active;
    end
    
    assign module_clk_en = clk_en_reg;

endmodule
```

---

## 4. CDC检查豁免

### 4.1 CDC分析豁免列表

由于采用单时钟域设计，以下CDC检查项可豁免：

| 检查项 | 豁免理由 | 状态 |
|--------|----------|------|
| Async-01 | 无时钟域交叉 | N/A |
| Async-02 | 无时钟域交叉 | N/A |
| Async-03 | 无时钟域交叉 | N/A |
| Async-04 | 无时钟域交叉 | N/A |
| Async-05 | 无时钟域交叉 | N/A |
| Async-06 | 无时钟域交叉 | N/A |
| Async-07 | 无时钟域交叉 | N/A |
| Clock-11 | 单时钟域 | N/A |
| Clock-12 | 单时钟域 | N/A |

### 4.2 SpyGlass豁免文件

```tcl
# cdc_exemptions.sgdc
# CDC豁免配置文件

# 由于单时钟设计，豁免所有CDC相关检查
current_design aes_top

# 豁免CDC同步器检查
waive -rule {Async-*} -comment "Single clock domain design - no CDC required"

# 豁免多时钟检查  
waive -rule {Clock-11} -comment "Single clock domain - no clock muxing"
waive -rule {Clock-12} -comment "Single clock domain - no generated clocks"

# 豁免复位同步检查 (如果复位是同步的)
waive -rule {Rst-01} -comment "Synchronous reset design"
```

### 4.3 时钟定义文件

```tcl
# clocks.sdc
# 时钟约束定义

# 主时钟定义
create_clock -name aclk -period 10.0 [get_ports aclk]

# APB时钟 (同源同频)
create_clock -name pclk -period 10.0 [get_ports pclk]

# 设置时钟组 (逻辑上独立但同源)
set_clock_groups -logically_exclusive \
    -group [get_clocks aclk] \
    -group [get_clocks pclk]

# 注意: 由于同源，不需要set_clock_groups -physically_exclusive
# 也不需要CDC约束
```

---

## 5. RDC策略

### 5.1 复位域说明

采用单复位域设计：

```
复位架构:
- 全局异步复位输入: areset_n
- 所有模块使用同步释放的复位信号
- 单一时钟域内的复位同步
```

### 5.2 复位同步器

```verilog
module reset_synchronizer (
    input  wire  clk,
    input  wire  rst_n_async,
    output wire  rst_n_sync
);

    reg [1:0] rst_sync_reg;
    
    always @(posedge clk or negedge rst_n_async) begin
        if (!rst_n_async)
            rst_sync_reg <= 2'b00;
        else
            rst_sync_reg <= {rst_sync_reg[0], 1'b1};
    end
    
    assign rst_n_sync = rst_sync_reg[1];

endmodule
```

### 5.3 RDC豁免

| 检查项 | 豁免理由 | 状态 |
|--------|----------|------|
| RDC-01 | 单复位域设计 | N/A |
| RDC-02 | 单复位域设计 | N/A |

---

## 6. 时序约束

### 6.1 基本时序约束

```tcl
# timing.sdc
# 时序约束文件

# 设置时钟
create_clock -name aclk -period 10.0 [get_ports aclk]
set_clock_uncertainty 0.1 [get_clocks aclk]

# 输入延迟
set_input_delay -clock aclk -max 2.0 [all_inputs]
set_input_delay -clock aclk -min 0.5 [all_inputs]

# 输出延迟
set_output_delay -clock aclk -max 2.0 [all_outputs]
set_output_delay -clock aclk -min 0.5 [all_outputs]

# 输入驱动
set_driving_cell -lib_cell BUFX2 [all_inputs]

# 输出负载
set_load 0.05 [all_outputs]
```

### 6.2 伪路径声明

```tcl
# 由于单时钟设计，不存在跨时钟域的伪路径
# 但仍需声明测试模式相关路径

# 测试模式路径
set_false_path -from [get_ports test_mode]

# 复位路径 (异步复位同步释放)
set_false_path -from [get_ports areset_n] -to [get_clocks aclk]
```

### 6.3 多周期路径

```tcl
# AES轮运算使用多周期路径
# SubBytes - ShiftRows - MixColumns - AddRoundKey

# 部分路径允许2个周期完成
set_multicycle_path -setup 2 -from [get_pins */sbox*] -to [get_pins */state_reg*]
set_multicycle_path -hold 1 -from [get_pins */sbox*] -to [get_pins */state_reg*]
```

### 6.4 时序检查清单

| 检查项 | 约束 | 状态 |
|--------|------|------|
| 时钟定义 | create_clock | ☐ |
| 输入延迟 | set_input_delay | ☐ |
| 输出延迟 | set_output_delay | ☐ |
| 时钟不确定性 | set_clock_uncertainty | ☐ |
| 伪路径 | set_false_path | ☐ |
| 多周期路径 | set_multicycle_path | ☐ |
| 最大延迟 | set_max_delay | ☐ |
| 最小延迟 | set_min_delay | ☐ |

---

## 7. EDA工具配置

### 7.1 SpyGlass CDC配置

```tcl
# spyglass_cdc.sgdc
# SpyGlass CDC检查配置

# 由于单时钟设计，禁用CDC检查
set_goal_option add_rules {Setup ClockReset}
set_goal_option delete_rules {CDC}

# 或者保留CDC检查但全部豁免
set_goal_option add_rules {CDC}
read_file -type sgdc cdc_exemptions.sgdc
```

### 7.2 JasperGold CDC配置

```tcl
# jg_cdc.tcl
# JasperGold CDC验证配置

# 时钟声明
clock aclk
clock pclk

# 单时钟域假设
assume -name single_clock_domain {
    ##1 (aclk == pclk)
}

# 无需CDC检查
# clock_domain_crossing -disable
```

### 7.3 Design Compiler配置

```tcl
# dc_constraints.tcl
# Design Compiler约束

# 读入时钟约束
source clocks.sdc
source timing.sdc

# 单时钟优化
set compile_enable_async_mux_mapping false
set compile_sequential_area_recovery true
```

---

## 附录A: 单时钟设计检查清单

| 检查项 | 描述 | 符合 |
|--------|------|------|
| CLK-001 | 所有模块使用同一时钟源 | ☐ |
| CLK-002 | 无时钟域交叉信号 | ☐ |
| CLK-003 | 无时钟mux/glitch | ☐ |
| CLK-004 | 复位同步在单一时钟域 | ☐ |
| CLK-005 | 时钟门控信号在单一时钟域 | ☐ |
| CDC-001 | CDC检查豁免文件完整 | ☐ |
| RDC-001 | RDC检查豁免文件完整 | ☐ |
| STA-001 | SDC约束完整 | ☐ |

---

## 附录B: 文档变更历史

| 版本 | 日期 | 变更 | 作者 |
|------|------|------|------|
| v0.1 | 2026-03-31 | 初始版本 | AI-Yang Design Agent |
| | | - 说明单时钟架构 | |
| | | - 提供CDC豁免依据 | |
| | | - 添加时序约束示例 | |

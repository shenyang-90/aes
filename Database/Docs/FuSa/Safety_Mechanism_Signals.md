# AES IP 安全机制信号分析文档

**文档版本**: 1.0  
**生成日期**: 2026-04-01  
**FuSa 工程师**: AI Assistant  

---

## 1. 概述

本文档详细描述了 AES IP 中实现的安全机制信号，用于功能安全（FuSa）验证和故障注入测试。

### 安全机制清单

| 序号 | 安全机制 | 实现模块 | 安全目标 |
|------|----------|----------|----------|
| 1 | Dual-rail Compare | fault_detector | 检测计算故障 |
| 2 | CRC-32 Check | crc_checker | 数据完整性校验 |
| 3 | Key Zeroization | key_manager | 密钥安全清除 |
| 4 | FSM Timeout | aes_controller | 状态机异常检测 |
| 5 | Interrupt Reporting | aes_top | 故障通知机制 |

---

## 2. 安全机制信号列表

### 2.1 Fault Detector - 双轨故障检测

| 安全机制 | 模块 | 信号名 | 方向 | 位宽 | 描述 | 验证方法 |
|---------|------|--------|------|------|------|----------|
| Dual-rail compare | fault_detector | clk | input | 1 | 系统时钟 | - |
| Dual-rail compare | fault_detector | rst_n | input | 1 | 异步复位（低有效） | - |
| Dual-rail compare | fault_detector | enable | input | 1 | 模块使能 | Force 0/1 |
| Dual-rail compare | fault_detector | op_start | input | 1 | 操作开始触发 | Force pulse |
| Dual-rail compare | fault_detector | op_done | input | 1 | 操作完成信号 | Force early |
| Dual-rail compare | fault_detector | result_a | input | 128 | 第一执行结果（主路径） | Force mismatch |
| Dual-rail compare | fault_detector | result_b | input | 128 | 第二执行结果（锁步路径） | Force mismatch |
| Dual-rail compare | fault_detector | result_a_valid | input | 1 | 结果A有效标志 | Force invalid |
| Dual-rail compare | fault_detector | result_b_valid | input | 1 | 结果B有效标志 | Force invalid |
| Dual-rail compare | fault_detector | crc_value | input | 32 | CRC计算值 | Force error CRC |
| Dual-rail compare | fault_detector | crc_valid | input | 1 | CRC有效标志 | Force 0 |
| Dual-rail compare | fault_detector | fault_detected | output | 1 | 故障检测标志（高有效） | Check assertion |
| Dual-rail compare | fault_detector | fault_type | output | 1 | 故障类型: 0=mismatch, 1=CRC error | Check value |
| Dual-rail compare | fault_detector | safe_result | output | 128 | 安全输出结果（通过校验） | Check propagation |

### 2.2 CRC Checker - CRC校验

| 安全机制 | 模块 | 信号名 | 方向 | 位宽 | 描述 | 验证方法 |
|---------|------|--------|------|------|------|----------|
| CRC check | crc_checker | clk | input | 1 | 系统时钟 | - |
| CRC check | crc_checker | rst_n | input | 1 | 异步复位（低有效） | - |
| CRC check | crc_checker | calc_start | input | 1 | CRC计算开始 | Force trigger |
| CRC check | crc_checker | calc_done | input | 1 | 外部计算完成 | Force early |
| CRC check | crc_checker | data_in | input | 128 | 输入数据（明文/密文） | Flip任意bit |
| CRC check | crc_checker | crc_out | output | 32 | CRC计算结果 | Check value |
| CRC check | crc_checker | crc_valid | output | 1 | CRC计算完成标志 | Check assertion |

**CRC参数说明**:
- 多项式: 0x04C11DB7 (IEEE 802.3 CRC-32)
- 初始值: 0xFFFFFFFF
- 输出取反: 是
- 处理位宽: 128位 MSB-first

### 2.3 Key Manager - 密钥管理

| 安全机制 | 模块 | 信号名 | 方向 | 位宽 | 描述 | 验证方法 |
|---------|------|--------|------|------|------|----------|
| Key zeroize | key_manager | clk | input | 1 | 系统时钟 | - |
| Key zeroize | key_manager | rst_n | input | 1 | 异步复位（低有效） | - |
| Key zeroize | key_manager | key_load | input | 1 | 密钥加载使能 | Force glitch |
| Key zeroize | key_manager | key_len | input | 2 | 密钥长度: 00=128, 01=192, 10=256 | Force invalid |
| Key zeroize | key_manager | key_in | input | 256 | 输入密钥数据 | Flip任意bit |
| Key zeroize | key_manager | zeroize | input | 1 | 密钥清零触发（安全） | Trigger check |
| Key zeroize | key_manager | key_out | output | 256 | 输出密钥数据 | Check zeroized |
| Key zeroize | key_manager | key_valid | output | 1 | 密钥有效标志 | Check cleared |
| Key zeroize | key_manager | key_ready | output | 1 | 密钥就绪标志 | Check cleared |

**密钥长度编码**:
- 2'd0 (00): AES-128
- 2'd1 (01): AES-192  
- 2'd2 (10): AES-256
- 2'd3 (11): Reserved

### 2.4 AES Controller - 主控FSM

| 安全机制 | 模块 | 信号名 | 方向 | 位宽 | 描述 | 验证方法 |
|---------|------|--------|------|------|------|----------|
| FSM control | aes_controller | clk | input | 1 | 系统时钟 | - |
| FSM control | aes_controller | rst_n | input | 1 | 异步复位（低有效） | - |
| FSM control | aes_controller | ctrl_reg | input | 32 | 控制寄存器 | Force invalid |
| FSM control | aes_controller | status_reg | input | 32 | 状态寄存器 | Read check |
| FSM control | aes_controller | key_len_reg | input | 32 | 密钥长度配置 | Force invalid |
| FSM control | aes_controller | mode_reg | input | 32 | 模式配置寄存器 | Force invalid |
| FSM control | aes_controller | config_valid | input | 1 | 配置有效脉冲 | Force glitch |
| FSM control | aes_controller | data_in_valid | input | 1 | 输入数据有效 | Force early |
| FSM control | aes_controller | data_in_ready | output | 1 | 准备接收数据 | Check stuck |
| FSM control | aes_controller | data_out_ready | input | 1 | 输出就绪 | Force delay |
| FSM control | aes_controller | data_out_valid | output | 1 | 输出数据有效 | Check stuck |
| FSM control | aes_controller | core_start | output | 1 | AES核启动 | Check pulse |
| FSM control | aes_controller | core_done | input | 1 | AES核完成 | Force stuck |
| FSM control | aes_controller | key_load | output | 1 | 加载密钥 | Check timing |
| FSM control | aes_controller | iv_load | output | 1 | 加载IV | Check timing |
| FSM control | aes_controller | key_ready | input | 1 | 密钥调度就绪 | Force 0 |
| FSM control | aes_controller | aes_mode | output | 3 | AES模式: ECB/CBC/CTR/GCM/XTS/CTS | Check encoding |
| FSM control | aes_controller | key_mode | output | 2 | 密钥模式: 128/192/256 | Check encoding |
| FSM control | aes_controller | encrypt | output | 1 | 1=加密, 0=解密 | Force flip |
| FSM control | aes_controller | cts_enable | output | 1 | CTS模式使能 | Force glitch |
| Interrupt | aes_controller | int_done | output | 1 | 操作完成中断 | Check assertion |
| Interrupt | aes_controller | int_error | output | 1 | 错误中断 | Check assertion |

**FSM状态定义** (4-bit):

| 状态值 | 状态名 | 描述 |
|--------|--------|------|
| 4'd0 | IDLE | 空闲状态 |
| 4'd1 | KEY_SCHEDULE | 密钥调度阶段 |
| 4'd2 | KEY_WAIT | 等待密钥就绪 |
| 4'd3 | LOAD_DATA | 加载输入数据 |
| 4'd4 | LOAD_DATA_WAIT | 等待数据输入 |
| 4'd5 | ROUND_OP | 轮运算执行 |
| 4'd6 | ROUND_WAIT | 等待运算完成 |
| 4'd7 | FINAL_ROUND | 最终轮运算 |
| 4'd8 | OUTPUT_DATA | 输出结果 |
| 4'd9 | DONE | 操作完成 |
| 4'd10 | ERROR | 错误状态 |

**AES模式编码** (3-bit):

| 编码 | 模式 | 描述 |
|------|------|------|
| 3'd0 | ECB | 电子密码本 |
| 3'd1 | CBC | 密码块链接 |
| 3'd2 | CTR | 计数器模式 |
| 3'd3 | GCM | 伽罗瓦计数器模式 |
| 3'd4 | XTS | XEX可调分组密码 |
| 3'd5 | CTS | 密文窃取模式 |

### 2.5 AES Top - 顶层集成

| 安全机制 | 模块 | 信号名 | 方向 | 位宽 | 描述 | 验证方法 |
|---------|------|--------|------|------|------|----------|
| APB IF | aes_top | clk | input | 1 | 系统时钟 | - |
| APB IF | aes_top | rst_n | input | 1 | 异步复位（低有效） | - |
| APB IF | aes_top | psel | input | 1 | APB选择 | Force glitch |
| APB IF | aes_top | penable | input | 1 | APB使能 | Force glitch |
| APB IF | aes_top | paddr | input | 12 | APB地址 (4KB空间) | Force invalid |
| APB IF | aes_top | pwrite | input | 1 | APB写使能 | Force flip |
| APB IF | aes_top | pwdata | input | 32 | APB写数据 | Flip bits |
| APB IF | aes_top | prdata | output | 32 | APB读数据 | Check value |
| APB IF | aes_top | pready | output | 1 | APB就绪 | Check timing |
| APB IF | aes_top | pslverr | output | 1 | APB错误 | Check assertion |
| AXIS RX | aes_top | s_axis_tdata | input | 128 | 输入数据流 | Flip bits |
| AXIS RX | aes_top | s_axis_tvalid | input | 1 | 输入有效 | Force glitch |
| AXIS RX | aes_top | s_axis_tready | output | 1 | 输入就绪 | Check stuck |
| AXIS RX | aes_top | s_axis_tlast | input | 1 | 输入最后 | Force early |
| AXIS TX | aes_top | m_axis_tdata | output | 128 | 输出数据流 | Check value |
| AXIS TX | aes_top | m_axis_tvalid | output | 1 | 输出有效 | Check timing |
| AXIS TX | aes_top | m_axis_tready | input | 1 | 输出就绪 | Force 0 |
| AXIS TX | aes_top | m_axis_tlast | output | 1 | 输出最后 | Check timing |
| Interrupt | aes_top | int_done | output | 1 | 完成中断 | Check assertion |
| Interrupt | aes_top | int_error | output | 1 | 错误中断 | Check assertion |
| DFT | aes_top | scan_en | input | 1 | 扫描使能 | Test mode only |
| DFT | aes_top | scan_clk | input | 1 | 扫描时钟 | Test mode only |

**内部寄存器信号**:

| 寄存器 | 位宽 | 描述 | 安全属性 |
|--------|------|------|----------|
| ctrl_reg | 32 | 控制寄存器 | RW |
| status_reg | 32 | 状态寄存器 | RO |
| key_len_reg | 32 | 密钥长度 | RW |
| mode_reg | 32 | 模式配置 | RW |
| key_reg | 256 | 密钥存储 | Secure RW |
| iv_reg | 128 | IV存储 | Secure RW |
| cts_en_reg | 32 | CTS使能 | RW |
| sector_id_reg | 32 | XTS扇区ID | RW |
| int_en_reg | 32 | 中断使能 | RW |
| int_status_reg | 32 | 中断状态 | W1C/RC |

---

## 3. 注错场景详细列表

### 3.1 Fault Detector 注错场景

| 场景ID | 故障类型 | 注入模块 | 注入信号 | 注入值 | 预期检测信号 | 预期行为 |
|--------|----------|----------|----------|--------|--------------|----------|
| FI-FD-001 | 单比特翻转 | fault_detector | result_a[0] | ~result_a[0] | fault_detected=1 | 进入ERROR状态 |
| FI-FD-002 | 单比特翻转 | fault_detector | result_a[63] | ~result_a[63] | fault_detected=1 | 进入ERROR状态 |
| FI-FD-003 | 单比特翻转 | fault_detector | result_a[127] | ~result_a[127] | fault_detected=1 | 进入ERROR状态 |
| FI-FD-004 | 多比特翻转 | fault_detector | result_a[31:0] | ~result_a[31:0] | fault_detected=1 | 进入ERROR状态 |
| FI-FD-005 | 全零注入 | fault_detector | result_a | 128'h0 | fault_detected=1 | 进入ERROR状态 |
| FI-FD-006 | 全一注入 | fault_detector | result_a | 128'hFFFF... | fault_detected=1 | 进入ERROR状态 |
| FI-FD-007 | 单比特翻转 | fault_detector | result_b[0] | ~result_b[0] | fault_detected=1 | 进入ERROR状态 |
| FI-FD-008 | 结果A有效丢失 | fault_detector | result_a_valid | 1'b0 | state stuck in EXEC_A | 超时检测 |
| FI-FD-009 | 结果B有效丢失 | fault_detector | result_b_valid | 1'b0 | state stuck in EXEC_B | 超时检测 |
| FI-FD-010 | CRC错误注入 | fault_detector | crc_valid | 1'b0 | fault_detected=1, fault_type=1 | 进入ERROR状态 |
| FI-FD-011 | Enable毛刺 | fault_detector | enable | ~enable | state异常跳转 | 需FSM保护 |

### 3.2 CRC Checker 注错场景

| 场景ID | 故障类型 | 注入模块 | 注入信号 | 注入值 | 预期检测信号 | 预期行为 |
|--------|----------|----------|----------|--------|--------------|----------|
| FI-CRC-001 | 数据单比特错 | crc_checker | data_in[0] | ~data_in[0] | crc_out变化 | CRC值改变 |
| FI-CRC-002 | 数据多比特错 | crc_checker | data_in[31:0] | ~data_in[31:0] | crc_out变化 | CRC值改变 |
| FI-CRC-003 | 全零数据 | crc_checker | data_in | 128'h0 | crc_out=0xFFFFFFFF | 特定CRC值 |
| FI-CRC-004 | 全一数据 | crc_checker | data_in | 128'hFFFF... | crc_out=计算值 | 验证多项式 |
| FI-CRC-005 | Calc stuck | crc_checker | calc_start | 1'b0 | crc_valid=0 | 无CRC输出 |
| FI-CRC-006 | Bit counter错 | crc_checker | bit_cnt[内部] | Force +1 | crc_out错误 | CRC不匹配 |
| FI-CRC-007 | CRC reg损坏 | crc_checker | crc_reg[内部] | Flip bit | crc_out错误 | CRC不匹配 |
| FI-CRC-008 | State跳转错 | crc_checker | state[内部] | Force invalid | crc_valid异常 | 需FSM保护 |

### 3.3 Key Manager 注错场景

| 场景ID | 故障类型 | 注入模块 | 注入信号 | 注入值 | 预期检测信号 | 预期行为 |
|--------|----------|----------|----------|--------|--------------|----------|
| FI-KEY-001 | 密钥单比特错 | key_manager | key_in[0] | ~key_in[0] | key_out变化 | 密文变化 |
| FI-KEY-002 | 密钥单比特错 | key_manager | key_in[255] | ~key_in[255] | key_out变化 | 密文变化 |
| FI-KEY-003 | 密钥全零 | key_manager | key_in | 256'h0 | key_out=0 | 已知密文攻击 |
| FI-KEY-004 | Zeroize触发 | key_manager | zeroize | 1'b1 | key_out=0, key_valid=0 | 密钥清除 |
| FI-KEY-005 | Zeroize毛刺 | key_manager | zeroize | Glitch | key_out=0 | 意外清除 |
| FI-KEY-006 | Key load冲突 | key_manager | key_load+zeroize | Both 1 | key_out=0 | 安全优先 |
| FI-KEY-007 | 密钥长度错 | key_manager | key_len | 2'b11 | key_masked异常 | 保留位处理 |
| FI-KEY-008 | Key valid stuck | key_manager | key_valid | Stuck 1 | 无检测 | 需外部检查 |

### 3.4 AES Controller 注错场景

| 场景ID | 故障类型 | 注入模块 | 注入信号 | 注入值 | 预期检测信号 | 预期行为 |
|--------|----------|----------|----------|--------|--------------|----------|
| FI-CTL-001 | FSM stuck-0 | aes_controller | state | Force 4'd0 (IDLE) | 无操作 | 看门狗超时 |
| FI-CTL-002 | FSM stuck-3 | aes_controller | state | Force 4'd3 (LOAD_DATA) | 等待数据 | 看门狗超时 |
| FI-CTL-003 | FSM跳转错 | aes_controller | state | Force invalid (4'd11) | 未知状态 | Default→IDLE |
| FI-CTL-004 | Core done毛刺 | aes_controller | core_done | Early pulse | 提前完成 | 数据错误 |
| FI-CTL-005 | Encrypt flip | aes_controller | encrypt | ~encrypt | 解密而非加密 | 功能错误 |
| FI-CTL-006 | Mode错配 | aes_controller | aes_mode | 3'd6 (invalid) | 依赖core处理 | 需core保护 |
| FI-CTL-007 | Key mode错 | aes_controller | key_mode | 2'b11 (invalid) | 依赖key_schedule | 需检查 |
| FI-CTL-008 | Start毛刺 | aes_controller | ctrl_start | Glitch | 意外启动 | 需debounce |
| FI-CTL-009 | Interrupt stuck | aes_controller | int_done | Stuck 1 | 持续中断 | 需软件处理 |
| FI-CTL-010 | CTS enable错 | aes_controller | cts_enable | Force 1 | 模式切换 | 功能变化 |

### 3.5 AES Top 注错场景

| 场景ID | 故障类型 | 注入模块 | 注入信号 | 注入值 | 预期检测信号 | 预期行为 |
|--------|----------|----------|----------|--------|--------------|----------|
| FI-TOP-001 | APB地址错 | aes_top | paddr | 12'hFFF | prdata=DEAD_BEEF | 默认返回 |
| FI-TOP-002 | 密钥清除 | aes_top | pwdata[9] | 1'b1 (REG_CTRL) | key_reg=0 | 密钥清零 |
| FI-TOP-003 | 状态W1C错 | aes_top | pwdata | 写INT_STATUS | int_status被清 | W1C验证 |
| FI-TOP-004 | CRC使能错 | aes_top | mode_reg[8] | 1'b1 | crc_en=1 | CRC计算启动 |
| FI-TOP-005 | 中断状态错 | aes_top | int_status_reg | Flip bits | 中断误报 | 需软件过滤 |
| FI-TOP-006 | DMA输入错 | aes_top | s_axis_tdata | Flip bits | m_axis_tdata错误 | 数据错误 |
| FI-TOP-007 | TVALID毛刺 | aes_top | s_axis_tvalid | Glitch | 意外数据 | 需握手保护 |
| FI-TOP-008 | Scan模式误启 | aes_top | scan_en | 1'b1 | DFT模式 | 功能禁用 |
| FI-TOP-009 | Pready stuck | aes_top | pready | Stuck 0 | APB hang | 超时检测 |
| FI-TOP-010 | Pslverr误报 | aes_top | pslverr | Force 1 | 总线错误 | 需检查 |

---

## 4. 中断寄存器映射

### 4.1 寄存器地址映射

| 寄存器名 | 地址 | 访问类型 | 描述 |
|----------|------|----------|------|
| REG_CTRL | 0x000 | RW | 控制寄存器 |
| REG_STATUS | 0x004 | RO | 状态寄存器 |
| REG_KEY_LEN | 0x008 | RW | 密钥长度配置 |
| REG_MODE | 0x00C | RW | 模式配置 |
| REG_KEY_0 | 0x010 | RW | 密钥[255:224] |
| REG_KEY_1 | 0x014 | RW | 密钥[223:192] |
| REG_KEY_2 | 0x018 | RW | 密钥[191:160] |
| REG_KEY_3 | 0x01C | RW | 密钥[159:128] |
| REG_KEY_4 | 0x020 | RW | 密钥[127:96] |
| REG_KEY_5 | 0x024 | RW | 密钥[95:64] |
| REG_KEY_6 | 0x028 | RW | 密钥[63:32] |
| REG_KEY_7 | 0x02C | RW | 密钥[31:0] |
| REG_IV_0 | 0x030 | RW | IV[127:96] |
| REG_IV_1 | 0x034 | RW | IV[95:64] |
| REG_IV_2 | 0x038 | RW | IV[63:32] |
| REG_IV_3 | 0x03C | RW | IV[31:0] |
| REG_CTS_EN | 0x040 | RW | CTS使能 |
| REG_SECTOR_ID | 0x044 | RW | XTS扇区ID |
| REG_INT_EN | 0x048 | RW | 中断使能 |
| **REG_INT_STATUS** | **0x04C** | **W1C/RC** | **中断状态** |

### 4.2 中断状态寄存器 (0x04C) 位定义

| 位 | 名称 | 中断类型 | 触发条件 | 清除方式 | 使能位 |
|----|------|----------|----------|----------|--------|
| [0] | DONE_INT | 操作完成 | 加密/解密操作完成 | W1C | int_en_reg[0] |
| [1] | ERROR_INT | 一般错误 | 控制器检测到错误状态 | W1C | int_en_reg[1] |
| [2] | FAULT_INT | 故障检测 | fault_detected=1 | W1C | int_en_reg[2] |
| [3] | CRC_INT | CRC错误 | crc_error=1 | W1C | int_en_reg[3] |
| [4] | DMA_INT | DMA完成 | DMA传输完成 | W1C | int_en_reg[4] |
| [5] | KEY_ERR_INT | 密钥错误 | 密钥加载异常 | W1C | int_en_reg[5] |
| [31:6] | Reserved | - | - | - | - |

### 4.3 控制寄存器 (0x000) 位定义

| 位 | 名称 | 描述 | 默认值 |
|----|------|------|--------|
| [0] | START | 操作开始触发 | 0 |
| [1] | ENCRYPT | 1=加密, 0=解密 | 0 |
| [3:2] | Reserved | - | 0 |
| [6:4] | MODE | 操作模式 (ECB/CBC/CTR/GCM/XTS/CTS) | 0 |
| [7] | Reserved | - | 0 |
| [8] | CTS_ENABLE | CTS模式使能 | 0 |
| [9] | KEY_CLEAR | 密钥清零 (W1S) | 0 |
| [15:10] | Reserved | - | 0 |
| [16] | INT_EN_DONE | DONE中断使能 | 0 |
| [17] | INT_EN_ERROR | ERROR中断使能 | 0 |
| [18] | INT_EN_FAULT | FAULT中断使能 | 0 |
| [19] | INT_EN_CRC | CRC中断使能 | 0 |
| [31:20] | Reserved | - | 0 |

### 4.4 状态寄存器 (0x004) 位定义

| 位 | 名称 | 描述 | 类型 |
|----|------|------|------|
| [0] | BUSY | 操作进行中 | RO |
| [1] | ERROR | 错误状态 | RO |
| [2] | FAULT_DETECTED | 故障已检测 | RO |
| [3] | CRC_MISMATCH | CRC不匹配 | RO |
| [4] | KEY_VALID | 密钥有效 | RO |
| [7:5] | Reserved | - | - |
| [11:8] | STATE | FSM当前状态 | RO |
| [15:12] | Reserved | - | - |
| [31:16] | Reserved | - | - |

---

## 5. 故障注入测试建议

### 5.1 测试优先级

| 优先级 | 场景ID | 安全机制 | 测试方法 |
|--------|--------|----------|----------|
| P0 | FI-FD-001~007 | Dual-rail compare | 强制result_a/b不匹配 |
| P0 | FI-KEY-004 | Key zeroize | 触发zeroize信号 |
| P0 | FI-CTL-001~003 | FSM timeout | Force state stuck |
| P1 | FI-CRC-001~004 | CRC check | Flip data bits |
| P1 | FI-TOP-002 | Key clear via APB | 写CTRL[9] |
| P1 | FI-CTL-005 | Encrypt/decrypt flip | Force encrypt翻转 |
| P2 | FI-FD-008~011 | Valid信号测试 | Glitch注入 |
| P2 | FI-KEY-001~003 | Key integrity | Flip key bits |
| P2 | FI-TOP-004~010 | Top-level集成 | 寄存器/接口测试 |

### 5.2 推荐测试流程

```
1. 基线测试 (无故障)
   └─ 确认正常操作流程

2. 单点故障注入
   ├─ Fault Detector: result_a/b 单比特翻转
   ├─ CRC: data_in 单比特翻转
   ├─ Key Manager: zeroize触发
   └─ Controller: FSM stuck检测

3. 多点故障注入
   ├─ 同时翻转多个比特
   └─ 组合故障场景

4. 时序故障注入
   ├─ Setup/hold violation
   ├─ Glitch注入
   └─ 时钟域交叉故障

5. 恢复测试
   └─ 故障清除后系统恢复
```

### 5.3 覆盖率目标

| 覆盖类型 | 目标 | 检查点 |
|----------|------|--------|
| 安全机制激活率 | 100% | 所有fault_detected触发 |
| FSM状态覆盖 | 100% | 所有11个状态 |
| 中断触发 | 100% | 所有中断类型 |
| 寄存器访问 | 100% | 所有APB寄存器 |
| 关键信号翻转 | >95% | result/key/data信号 |

---

## 6. 安全机制验证检查清单

- [ ] Dual-rail compare 能检测所有单比特翻转
- [ ] Dual-rail compare 能检测所有多比特翻转
- [ ] CRC check 能检测所有单比特数据错误
- [ ] CRC check 能检测所有双比特数据错误
- [ ] CRC check 能检测所有奇数比特错误
- [ ] CRC check 能检测所有突发错误 < 32bit
- [ ] Key zeroize 能在一个周期内清零所有密钥位
- [ ] Key zeroize 优先级高于 key_load
- [ ] FSM timeout 能检测所有状态卡住
- [ ] FSM 无效状态能安全回到IDLE
- [ ] 所有中断能正确触发和清除
- [ ] 中断使能/屏蔽功能正常
- [ ] 密钥清除功能通过APB和zeroize信号都能触发
- [ ] 故障检测后能正确进入ERROR状态
- [ ] ERROR状态能被正确清除

---

## 7. 附录

### 7.1 信号命名约定

| 前缀 | 含义 | 示例 |
|------|------|------|
| clk_ | 时钟 | clk_core |
| rst_n | 复位（低有效） | rst_n |
| i_ / input | 输入 | i_data |
| o_ / output | 输出 | o_result |
| reg_ | 寄存器 | reg_status |
| int_ | 中断 | int_done |

### 7.2 缩写表

| 缩写 | 全称 | 中文 |
|------|------|------|
| FuSa | Functional Safety | 功能安全 |
| FSM | Finite State Machine | 有限状态机 |
| CRC | Cyclic Redundancy Check | 循环冗余校验 |
| APB | Advanced Peripheral Bus | 高级外设总线 |
| AXIS | AXI Stream | AXI流接口 |
| W1C | Write-1-to-Clear | 写1清除 |
| RC | Read-Clear | 读清除 |
| TI | Trojan Immune | 抗木马 |
| DFT | Design For Test | 可测试性设计 |

---

**文档结束**

*本文档由 FuSa Engineer Agent 基于 RTL 代码分析自动生成*

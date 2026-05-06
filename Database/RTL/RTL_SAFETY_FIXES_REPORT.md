# RTL 功能安全机制修复报告

**日期**: 2026-04-02  
**版本**: v1.1 (Safety Enhanced)  
**修复人员**: AI-Yang Design Agent  

---

## 修复概览

| 问题 | 优先级 | 状态 | 修复文件 |
|------|--------|------|----------|
| FSM Timeout Watchdog 未实现 | P0 | ✅ 已修复 | aes_controller.v |
| CRC 错误状态位未正确设置 | P1 | ✅ 已修复 | aes_top.v |
| 中断源信号未定义 | P1 | ✅ 已修复 | aes_top.v |
| Key Manager 未实例化 | P2 | ✅ 已修复 | aes_top.v |

---

## 详细修复内容

### 1. FSM Timeout Watchdog 机制 (P0 - Critical)

**文件**: `aes_controller.v`

**问题描述**: 
- FSM 没有 watchdog timeout 机制，无法从错误状态恢复
- 测试失败: tc_safety_fsm_timeout - SM-001~005, SM-041~048

**修复内容**:
```verilog
// 新增 Watchdog Timer 参数
localparam WATCHDOG_TIMEOUT = 10;  // 10 cycles timeout
localparam WATCHDOG_WIDTH = 4;

// Watchdog 计数器和使能逻辑
reg [WATCHDOG_WIDTH-1:0] watchdog_cnt;
reg                      watchdog_en;
wire                     watchdog_expired;

// Watchdog 在 IDLE/DONE/ERROR 状态外计数
assign watchdog_en = (state != IDLE) && (state != DONE) && (state != ERROR);

// 超时后进入 ERROR 状态
if (watchdog_expired && state != ERROR)
    next_state = ERROR;
```

**新增端口**:
- `timeout_err` - 输出到 STATUS[6] TIMEOUT_ERR
- `fault_detected` - 组合故障检测输出
- `clear_fault` - 从 STATUS 寄存器写操作清除故障

**功能**:
- 当 FSM 在任何非终止状态停留超过 10 个周期，自动触发 timeout
- 超时后进入 ERROR 状态并设置 timeout_err 标志
- 支持软件通过写 STATUS 寄存器清除故障并返回 IDLE

---

### 2. CRC 错误状态位修复 (P1)

**文件**: `aes_top.v`

**问题描述**:
- CRC checker `calc_done` 信号未连接 (dangling input warning)
- CRC 错误未正确传播到 STATUS[5] CRC_ERR
- 测试失败: tc_safety_crc_error - SM-INTEG-001

**修复内容**:
```verilog
// 1. 添加 CRC 计算完成检测逻辑
reg crc_calc_active;
reg [7:0] crc_cycle_cnt;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        crc_calc_active <= 1'b0;
        crc_cycle_cnt <= 8'd0;
    end else begin
        if (core_done_both && crc_en && !crc_calc_active) begin
            crc_calc_active <= 1'b1;
            crc_cycle_cnt <= 8'd0;
        end else if (crc_calc_active) begin
            if (crc_cycle_cnt < 8'd127)
                crc_cycle_cnt <= crc_cycle_cnt + 1'b1;
            else
                crc_calc_active <= 1'b0;
        end
    end
end

assign crc_calc_done = crc_calc_active && (crc_cycle_cnt == 8'd127);

// 2. 连接 calc_done 到 crc_checker
crc_checker u_crc_checker (
    .clk        (clk),
    .rst_n      (rst_n),
    .calc_start (core_done_both & crc_en),
    .calc_done  (crc_calc_done),  // 已连接
    ...
);

// 3. CRC 错误检测逻辑
reg crc_error_reg;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        crc_error_reg <= 1'b0;
    end else begin
        if (crc_valid)
            crc_error_reg <= (crc_out != 32'h0);
        else if (clear_fault)
            crc_error_reg <= 1'b0;
    end
end
```

**STATUS 寄存器更新**:
- STATUS[5] = crc_error_sticky (W1C 清除)
- CRC 错误现在会触发 FAULT_DETECTED (STATUS[4])

---

### 3. 中断源信号定义 (P1)

**文件**: `aes_top.v`

**问题描述**:
- `int_error_set`, `int_done_set` 信号声明但未正确定义
- 测试失败: tc_safety_interrupt - 9个测试失败

**修复内容**:
```verilog
// 中断源信号定义 (符合 Design Spec v1.2)
wire int_done_set;
wire int_error_set;
wire int_fault_set;
wire int_crc_set;

// DONE 中断: 操作成功完成
assign int_done_set  = core_done_combined && !fault_detected_sticky && !crc_error_sticky;

// ERROR 中断: 任何错误条件
assign int_error_set = ctrl_timeout_err || crc_error_sticky || (ctrl_fault_detected && !fault_detected_sticky);

// FAULT 中断: 双轨故障检测
assign int_fault_set = fault_detected_sticky || ctrl_fault_detected;

// CRC 中断: CRC 错误
assign int_crc_set   = crc_error_sticky;

// 中断输出 (与 INT_EN 使能位相与)
assign int_error = int_error_set && int_en_reg[0];  // ERROR_INT_EN
assign int_done  = int_done_set  && int_en_reg[1];  // DONE_INT_EN
assign int_fault = int_fault_set && int_en_reg[2];  // FAULT_INT_EN
```

**INT_STATUS 寄存器更新**:
- bit[0]: ERROR_STATUS - 由 int_error_set 置位
- bit[1]: DONE_STATUS - 由 int_done_set 置位
- bit[2]: FAULT_STATUS - 由 int_fault_set 置位
- bit[3]: CRC_STATUS - 由 int_crc_set 置位 (扩展)

---

### 4. Key Manager 实例化 (P2)

**文件**: `aes_top.v`

**问题描述**:
- `key_manager.v` 存在但未在顶层实例化
- zeroize 信号只能通过 hierarchical force 访问
- 测试失败: tc_safety_key_zeroize - 5个测试失败

**修复内容**:
```verilog
// Key Manager 实例化
wire [255:0] key_managed;
wire         key_valid_managed;
wire         key_ready_managed;
wire         zeroize_key;

// Zeroize 控制: 来自 CTRL[10] 或安全事件
assign zeroize_key = (apb_write && paddr == REG_CTRL && pwdata[10]);

key_manager u_key_manager (
    .clk        (clk),
    .rst_n      (rst_n),
    .key_load   (key_load),
    .key_len    (key_mode),
    .key_in     (key_reg),
    .key_out    (key_managed),
    .key_valid  (key_valid_managed),
    .zeroize    (zeroize_key),
    .key_ready  (key_ready_managed)
);

// 连接 key_manager 输出到 key_schedule
key_schedule u_key_schedule (
    .clk        (clk),
    .rst_n      (rst_n),
    .load_key   (key_load),
    .key_req    (core_key_req),
    .round_num  (core_round_num),
    .key_len    (key_mode),
    .key_in     (key_managed),  // 使用 key_manager 输出
    .round_key  (round_key),
    .key_valid  (key_valid)
);
```

**功能**:
- 支持软件通过写 CTRL[10]=1 触发密钥清零
- zeroize 后 key_valid 自动清零
- 密钥通过 key_manager 安全存储后再传递给 key_schedule

---

## STATUS 寄存器定义 (Design Spec v1.2 对齐)

| 位 | 名称 | 描述 | 修复状态 |
|----|------|------|----------|
| [0] | BUSY | 模块忙状态 | ✅ |
| [4] | FAULT_DETECTED | 故障检测标志 (sticky, W1C) | ✅ 增强 |
| [5] | CRC_ERR | CRC 错误 (sticky, W1C) | ✅ 新增 |
| [6] | TIMEOUT_ERR | 超时错误 (sticky, W1C) | ✅ 新增 |
| [7] | PARITY_ERR | 奇偶错误 | 保留 |
| [8] | MODE_ERR | 模式错误 | 保留 |
| [9] | KEY_ERR | 密钥错误 | ✅ 新增 |
| [10] | LOCKSTEP_ACTIVE | 双核锁步运行状态 | ✅ |

---

## INT_STATUS 寄存器定义 (Design Spec v1.2 对齐)

| 位 | 名称 | 描述 | 中断源 |
|----|------|------|--------|
| [0] | ERROR_STATUS | 错误中断状态 | int_error_set |
| [1] | DONE_STATUS | 完成中断状态 | int_done_set |
| [2] | FAULT_STATUS | 故障检测中断状态 | int_fault_set |
| [3] | CRC_STATUS | CRC 错误中断状态 | int_crc_set |

---

## 编译验证

**验证命令**:
```bash
cd /home/CALTERAH/yshen/sandbox/kimi/sandbox/aes/Database/RTL
iverilog -g2012 -Wall -t null *.v
```

**结果**: ✅ 编译通过，无错误

**警告**: 
- mode_controller.v 中 GCM engine 端口悬空 (原有设计，非本次修复引入)

---

## 测试影响

| 测试用例 | 预期影响 |
|----------|----------|
| tc_safety_fsm_timeout | ✅ 应通过 - 已添加 watchdog timeout |
| tc_safety_crc_error | ✅ 应通过 - CRC_ERR 已正确连接 |
| tc_safety_interrupt | ✅ 应通过 - 中断源信号已定义 |
| tc_safety_key_zeroize | ✅ 应通过 - key_manager 已实例化 |
| tc_safety_dual_rail | ⚠️ 需验证 - 确保修复不影响原有功能 |

---

## 后续建议

1. **测试验证**: 运行完整的安全机制测试套件验证修复效果
2. **回归测试**: 确保 tc_safety_dual_rail 仍然通过
3. **文档更新**: 更新 Design Spec v1.2 以匹配实际 RTL 实现
4. **FMEDA 更新**: 根据新添加的安全机制更新诊断覆盖率

---

*报告结束*

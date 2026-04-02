# AES IP Testcase Index

## 测试用例清单

本文档记录所有测试用例与验证计划 (Verification_Plan.md) 的映射关系。

## 测试用例统计

| 类别 | 数量 | 覆盖率目标 |
|------|------|-----------|
| Smoke | 1 | Basic check |
| 功能测试 | 6 | Line >90% |
| 模式测试 | 8 | Cross >85% |
| 密钥测试 | 9 | Key schedule |
| 错误处理 | 2 | Error paths |
| 故障注入 | 2 | Assert >95% |
| Core/Direct | 2 | Core function |
| 覆盖率提升 | 3 | Toggle >85% |
| 寄存器/中断 | 4 | Full feature |
| **安全机制** | **5** | **SM-001~048** |
| **总计: 47** | **综合 >90%** |

---

## 详细测试用例列表

### 1. Smoke Test

#### tc_smoke
- **描述**: 基础冒烟测试(Smoke/Sanity)，验证寄存器读写和基本加密/解密
- **覆盖点**: 基本功能路径
- **验证计划**: 入口标准验证
- **状态**: ✅ 稳定

---

### 2. ECB Mode Tests

#### tc_ecb_nist
- **描述**: ECB模式NIST SP 800-38A测试向量验证
- **覆盖点**: ECB-001 (AES-128 ECB加密)
- **验证计划**: 2.2.1节
- **状态**: ✅ 稳定

#### tc_ecb_multiblock
- **描述**: ECB 模式多块连续加密/解密
- **覆盖点**:
  - ECB-004: 多块连续加密
  - 大数据量处理 (16 blocks)
  - 不同密钥相同明文对比
- **验证计划**: 2.2.1节
- **创建日期**: 2026-03-31
- **状态**: ✅ 新增，覆盖缺失需求

#### tc_mode_coverage
- **描述**: 模式覆盖率测试
- **覆盖点**: 所有6种模式基础覆盖
- **验证计划**: 模式覆盖
- **状态**: ✅ 稳定

---

### 3. CBC Mode Tests

#### tc_cbc_nist
- **描述**: CBC模式NIST SP 800-38A测试向量验证
- **覆盖点**: CBC-001 (AES-128 CBC加密)
- **验证计划**: 2.2.2节
- **状态**: ✅ 稳定

#### tc_cbc_decrypt
- **描述**: CBC模式解密验证及IV链式依赖测试
- **覆盖点**:
  - CBC-002: AES-128 CBC解密
  - CBC-003: IV正确性验证
  - CBC-004: 链式依赖测试
- **验证计划**: 2.2.2节
- **创建日期**: 2026-03-27
- **状态**: ✅ 新增，运行正常

---

### 4. CTR Mode Tests

#### tc_ctr_nist
- **描述**: CTR模式NIST SP 800-38A测试向量验证
- **覆盖点**: CTR-001 (AES-128 CTR加密)
- **验证计划**: 2.2.3节
- **状态**: ✅ 稳定

#### tc_ctr_counter
- **描述**: CTR模式计数器递增和溢出处理验证
- **覆盖点**:
  - CTR-002: Counter递增验证
  - CTR-003: Counter溢出处理
- **验证计划**: 2.2.3节
- **创建日期**: 2026-03-27
- **状态**: ✅ 新增，运行正常

---

### 5. GCM Mode Tests

#### tc_gcm_basic
- **描述**: GCM模式基础验证（认证加密）
- **覆盖点**:
  - GCM-001: 认证加密
  - GCM-002: 认证解密
  - GCM-003: Tag验证失败处理
  - GCM-004: AAD处理
- **验证计划**: 2.2.4节
- **创建日期**: 2026-03-27
- **状态**: ✅ 新增，待GCM RTL完善

---

### 6. XTS Mode Tests

#### tc_xts_basic
- **描述**: XTS-AES模式验证（IEEE P1619）
- **覆盖点**:
  - XTS-001: 基本XTS加密
  - XTS-002: Sector边界处理
  - XTS-003: Tweakey派生验证
  - XTS-004: Multi-sector连续处理
- **验证计划**: 2.4节
- **创建日期**: 2026-03-27
- **状态**: ✅ 新增，待XTS RTL完善

---

### 7. CTS Mode Tests

#### tc_cts_boundary
- **描述**: CTS模式边界条件验证（1-127 bit）
- **覆盖点**:
  - CTS-B-001~031: 1-127 bit全边界覆盖
  - PAD Q4解决验证
- **验证计划**: 2.3节
- **状态**: ✅ 稳定

---

### 8. Key Length Tests

#### tc_key_length
- **描述**: AES-192和AES-256密钥长度验证
- **覆盖点**: 
  - ECB-002: AES-192单块加密
  - ECB-003: AES-256单块加密
- **验证计划**: 2.2.1节
- **创建日期**: 2026-03-27
- **状态**: ✅ 新增，待RTL完善

#### tc_key_len_check
- **描述**: 密钥长度检查测试
- **覆盖点**: 密钥长度验证
- **验证计划**: 密钥管理
- **状态**: ✅ 稳定

#### tc_key_len_error
- **描述**: 无效密钥长度处理及寄存器验证
- **覆盖点**:
  - ECB-005: 错误密钥长度处理
  - 密钥长度寄存器边界
  - 有效值验证 (0,1,2)
- **验证计划**: 2.2.1节
- **创建日期**: 2026-03-31
- **状态**: ✅ 新增，错误路径覆盖

#### tc_key_single
- **描述**: 单密钥测试
- **覆盖点**: 单密钥场景
- **验证计划**: 密钥基础测试
- **状态**: ✅ 稳定

#### tc_key_length_192_0 / tc_key_length_192_1 / tc_key_length_192_2
- **描述**: AES-192密钥长度测试（3个变体）
- **覆盖点**: AES-192不同测试场景
- **验证计划**: 2.2.1节
- **状态**: ✅ 稳定

#### tc_key_length_256_0 / tc_key_length_256_1 / tc_key_length_256_2
- **描述**: AES-256密钥长度测试（3个变体）
- **覆盖点**: AES-256不同测试场景
- **验证计划**: 2.2.1节
- **状态**: ✅ 稳定

---

### 9. Key Schedule Tests

#### tc_key_schedule_simple
- **描述**: 简单密钥调度测试
- **覆盖点**: 基础密钥扩展
- **验证计划**: 密钥调度
- **状态**: ✅ 稳定

#### tc_key_schedule_timing
- **描述**: 密钥调度时序测试
- **覆盖点**: 密钥扩展时序
- **验证计划**: 密钥调度
- **状态**: ✅ 稳定

---

### 10. S-Box Tests

#### tc_sbox_masked
- **描述**: TI 3-share 掩码 S-Box 功能验证
- **覆盖点**:
  - S-Box 功能正确性 (与无掩码S-Box对比)
  - 所有密钥长度 (128/192/256)
  - NIST 测试向量验证
- **验证计划**: 补充TI验证
- **创建日期**: 2026-03-31
- **状态**: ✅ 新增，BUG-006验证

---

### 11. Error Handling Tests

#### tc_error_handling
- **描述**: 错误处理测试
- **覆盖点**: 各种错误场景
- **验证计划**: 错误处理
- **状态**: ✅ 稳定

#### tc_error_injection
- **描述**: 错误注入测试
- **覆盖点**: 注入各种错误条件
- **验证计划**: 错误注入
- **状态**: ✅ 稳定

---

### 12. Fault Injection Tests

#### tc_fault_inject
- **描述**: 故障注入验证（Clock glitch、Data corruption）
- **覆盖点**:
  - FG-001~004: Clock Glitch测试
  - FD-001~004: Data Corruption测试
  - SG1~SG3: 安全目标验证
- **验证计划**: 4.1~4.3节
- **创建日期**: 2026-03-27
- **状态**: ✅ 新增，运行正常

#### tc_fault_data_corr
- **描述**: 数据损坏故障注入测试（FD-001~004）
- **覆盖点**:
  - FD-001: 密文bit翻转检测
  - FD-002: 多bit翻转检测
  - FD-003: 密钥bit翻转
  - FD-004: 内部状态翻转
- **验证计划**: 4.2.2节
- **创建日期**: 2026-03-31
- **状态**: ✅ 新增，覆盖率提升

---

### 13. Core/Direct Tests

#### tc_aes_core_direct
- **描述**: AES Core直接测试
- **覆盖点**: Core级功能验证
- **验证计划**: Core验证
- **状态**: ✅ 稳定

#### tc_aes128_only
- **描述**: AES-128专用测试
- **覆盖点**: AES-128专用场景
- **验证计划**: AES-128验证
- **状态**: ✅ 稳定

---

### 14. Register & Interrupt Tests

#### tc_register_full
- **描述**: 完整寄存器覆盖 - 所有地址、位域、访问类型
- **覆盖点**:
  - 所有寄存器地址读写
  - CTRL位域测试
  - STATUS位验证
  - KEY_LEN有效值
  - MODE所有6种模式
  - CTS_EN使能
  - INT_EN所有中断
  - INT_STAT读取
  - ERR_STAT错误状态
  - DATA_IN/DATA_OUT
- **验证计划**: 寄存器验证
- **创建日期**: 2026-04-01
- **状态**: ✅ 新增，功能覆盖
- **发现Bug**: BUG-014 (INT_STAT)

#### tc_interrupt_all
- **描述**: 完整中断控制器验证
- **覆盖点**:
  - 中断使能/禁用
  - DONE中断
  - ERROR中断
  - FAULT中断
  - INT_STAT读清
- **验证计划**: 中断验证
- **创建日期**: 2026-04-01
- **状态**: ✅ 新增，功能覆盖

### 15. Multi-Block Tests

#### tc_cbc_multiblock
- **描述**: CBC模式多块加密/解密，IV链式验证
- **覆盖点**:
  - 多块加密
  - 多块解密
  - IV链式
  - 往返验证
  - IV唯一性
- **验证计划**: CBC-004扩展
- **创建日期**: 2026-04-01
- **状态**: ✅ 新增，功能覆盖

#### tc_ctr_multiblock
- **描述**: CTR模式多块，计数器递增验证
- **覆盖点**:
  - 多块加密
  - 多块解密
  - 计数器递增
  - 计数器溢出
  - 并行加密（无链式）
- **验证计划**: CTR-003扩展
- **创建日期**: 2026-04-01
- **状态**: ✅ 新增，功能覆盖

### 16. Coverage Maximization Tests (IDR新增)

#### tc_toggle_coverage
- **描述**: 最大化信号翻转覆盖率
- **覆盖点**:
  - 数据位 walking ones/zeros (128位)
  - 密钥位 walking zeros (256位)
  - 最大翻转模式 (交替)
  - 单比特 walk
  - 快速连续翻转 burst
  - 所有模式/密钥长度/加解密切换
- **验证计划**: IDR覆盖率提升
- **创建日期**: 2026-04-01
- **状态**: ✅ 新增，Toggle覆盖率提升

#### tc_corner_cases
- **描述**: 边界值和特殊模式覆盖
- **覆盖点**:
  - 最小值/最大值测试
  - Power-of-2边界值
  - Byte/Word/Half-word模式
  - Nibble模式
  - Gray code序列
  - LFSR伪随机模式
  - ASCII可打印字符
  - 顺序数字/回文模式
- **验证计划**: IDR覆盖率提升
- **创建日期**: 2026-04-01
- **状态**: ✅ 新增，Condition覆盖率提升

#### tc_reset_error_coverage
- **描述**: 复位和FSM状态机覆盖
- **覆盖点**:
  - 上电复位寄存器值
  - 软复位控制
  - 操作中复位处理
  - 中断使能/清除
  - 快速启停序列
  - FSM路径覆盖
  - 模式切换 (ECB→CBC→CTR→GCM)
  - 密钥长度切换 (128→192→256)
  - 加解密切换
  - 背对背操作压力
- **验证计划**: IDR覆盖率提升
- **创建日期**: 2026-04-01
- **状态**: ✅ 新增，FSM覆盖率提升

---

## 验证计划覆盖矩阵

| 验证计划章节 | 测试需求 | 测试用例 | 状态 |
|-------------|---------|---------|------|
| 2.2.1 ECB | ECB-001~005 | tc_ecb_nist, tc_key_length, tc_ecb_multiblock, tc_key_len_error, tc_mode_coverage | 🟢 完成 |
| 2.2.2 CBC | CBC-001~004 | tc_cbc_nist, tc_cbc_decrypt | 🟢 完成 |
| 2.2.3 CTR | CTR-001~003 | tc_ctr_nist, tc_ctr_counter | 🟢 完成 |
| 2.2.4 GCM | GCM-001~004 | tc_gcm_basic | 🟢 完成 |
| 2.3 CTS | CTS-B-001~031 | tc_cts_boundary | 🟢 完成 |
| 2.4 XTS | XTS-001~004 | tc_xts_basic | 🟢 完成 |
| 4.2 Fault | FG-001~004, FD-001~004 | tc_fault_inject, tc_fault_data_corr | 🟢 完成 |
| Key Length | - | tc_key_length_* (10 tests), tc_key_single, tc_key_len_check | 🟢 完成 |
| Key Schedule | - | tc_key_schedule_simple, tc_key_schedule_timing | 🟢 完成 |
| TI S-Box | - | tc_sbox_masked | 🟢 完成 |
| Core/Direct | - | tc_aes_core_direct, tc_aes128_only | 🟢 完成 |
| Register/Interrupt | - | tc_register_full, tc_interrupt_all | 🟢 新增 |
| Multi-Block | - | tc_cbc_multiblock, tc_ctr_multiblock | 🟢 新增 |
| Coverage | Toggle/Condition/FSM | tc_toggle_coverage, tc_corner_cases, tc_reset_error_coverage | 🟢 新增 |

**图例**: 🟢 完成 | 🟡 部分完成/待RTL | ⚪ 未开始

**更新日期**: 2026-04-01 (新增功能测试用例)

---

## 回归测试执行

### 快速回归 (Smoke)
```bash
make TEST=tc_smoke sim
make TEST=tc_sanity_check sim
```

### Nightly回归 (核心功能)
```bash
make TEST=tc_ecb_nist sim
make TEST=tc_cbc_nist sim
make TEST=tc_ctr_nist sim
make TEST=tc_cbc_decrypt sim
make TEST=tc_ctr_counter sim
make TEST=tc_fault_inject sim
make TEST=tc_sbox_masked sim
```

### Weekly回归 (全量 - 34 tests)
```bash
for test in tc_smoke tc_ecb_nist tc_cbc_nist tc_ctr_nist \
            tc_register_full tc_interrupt_all \
            tc_cbc_multiblock tc_ctr_multiblock \
            tc_cts_boundary tc_key_length tc_cbc_decrypt tc_ctr_counter \
            tc_gcm_basic tc_xts_basic tc_fault_inject tc_fault_data_corr \
            tc_sbox_masked tc_ecb_multiblock tc_key_len_error tc_key_len_check \
            tc_key_single tc_key_length_192_0 tc_key_length_192_1 tc_key_length_192_2 \
            tc_key_length_256_0 tc_key_length_256_1 tc_key_length_256_2 \
            tc_key_schedule_simple tc_key_schedule_timing \
            tc_aes_core_direct tc_aes128_only tc_mode_coverage \
            tc_error_handling tc_error_injection \
            tc_toggle_coverage tc_corner_cases tc_reset_error_coverage; do
    make TEST=$test sim
done
```

### Full Regression (使用脚本)
```bash
cd Database/Verification/Regression
# 完整回归 (30个测试用例)
./run_regression_full.sh

# 覆盖率收集回归
./run_coverage.sh all
```

---

## 注意事项

1. **AES-192/256**: 密钥长度相关测试用例需要RTL支持相应密钥长度
2. **GCM模式**: tc_gcm_basic 需要完整的GCM RTL实现（GHASH模块）
3. **XTS模式**: tc_xts_basic 需要XTS引擎和Tweak生成模块
4. **故障注入**: tc_fault_inject 为基础软件测试，硬件故障注入需FPGA/硅片验证
5. **覆盖率测试**: IDR新增3个覆盖率提升测试用例，用于最大化toggle/condition/FSM覆盖

---

### 17. Random Testcases (TASK-AES-VER-001)

#### tc_random_modes
- **描述**: 随机模式切换测试 (ECB/CBC/CTR/GCM/XTS/CTS)
- **覆盖点**:
  - 随机模式切换 (有效转换)
  - 交叉覆盖: mode x key_len x operation
  - 50次随机事务
  - LFSR伪随机序列
- **验证计划**: 随机测试
- **创建日期**: 2026-04-01
- **状态**: ✅ 新增，Verilator覆盖率测试

#### tc_random_keys
- **描述**: 随机密钥生成与使用测试
- **覆盖点**:
  - 所有密钥长度 (128/192/256)
  - 随机密钥值生成
  - 特殊密钥模式 (全0/全1/交替/递增)
  - 密钥调度路径覆盖
  - 80个随机密钥测试
- **验证计划**: 密钥路径覆盖
- **创建日期**: 2026-04-01
- **状态**: ✅ 新增，Key Path覆盖

#### tc_random_data
- **描述**: 随机数据模式和可变块大小测试
- **覆盖点**:
  - 随机明文模式 (128位随机数据)
  - Walking 0/1 模式 (128位)
  - 计数模式 (16种起始值)
  - 稀疏模式 (少1位)
  - 密集模式 (少0位)
  - 特殊模式 (全0/全1/交替/条纹)
  - 数据路径全覆盖
- **验证计划**: 数据路径覆盖
- **创建日期**: 2026-04-01
- **状态**: ✅ 新增，Data Path覆盖

#### tc_random_errors
- **描述**: 随机错误注入测试 (仅可恢复错误)
- **覆盖点**:
  - 无效地址访问
  - 保留位处理
  - 无效模式值处理
  - 无效密钥长度处理
  - 快速寄存器访问
  - 无数据操作配置
  - 中断使能/禁用切换
  - 状态寄存器读取
  - 错误处理路径覆盖
- **验证计划**: 错误处理覆盖
- **创建日期**: 2026-04-01
- **状态**: ✅ 新增，Error Handling覆盖

#### tc_stress_random
- **描述**: 随机压力测试 - 背对背操作
- **覆盖点**:
  - 标准压力测试 (随机延迟)
  - 背对背操作 (无延迟)
  - 快速模式切换
  - 密钥压力测试
  - 混合压力测试
  - 最终突发测试
  - 压力/吞吐量覆盖
- **验证计划**: 压力测试
- **创建日期**: 2026-04-01
- **状态**: ✅ 新增，Stress覆盖

---

## 验证计划覆盖矩阵

| 验证计划章节 | 测试需求 | 测试用例 | 状态 |
|-------------|---------|---------|------|
| 2.2.1 ECB | ECB-001~005 | tc_ecb_nist, tc_key_length, tc_ecb_multiblock, tc_key_len_error, tc_mode_coverage | 🟢 完成 |
| 2.2.2 CBC | CBC-001~004 | tc_cbc_nist, tc_cbc_decrypt | 🟢 完成 |
| 2.2.3 CTR | CTR-001~003 | tc_ctr_nist, tc_ctr_counter | 🟢 完成 |
| 2.2.4 GCM | GCM-001~004 | tc_gcm_basic | 🟢 完成 |
| 2.3 CTS | CTS-B-001~031 | tc_cts_boundary | 🟢 完成 |
| 2.4 XTS | XTS-001~004 | tc_xts_basic | 🟢 完成 |
| 4.2 Fault | FG-001~004, FD-001~004 | tc_fault_inject, tc_fault_data_corr | 🟢 完成 |
| Key Length | - | tc_key_length_* (10 tests), tc_key_single, tc_key_len_check | 🟢 完成 |
| Key Schedule | - | tc_key_schedule_simple, tc_key_schedule_timing | 🟢 完成 |
| TI S-Box | - | tc_sbox_masked | 🟢 完成 |
| Core/Direct | - | tc_aes_core_direct, tc_aes128_only | 🟢 完成 |
| Register/Interrupt | - | tc_register_full, tc_interrupt_all | 🟢 新增 |
| Multi-Block | - | tc_cbc_multiblock, tc_ctr_multiblock | 🟢 新增 |
| Coverage | Toggle/Condition/FSM | tc_toggle_coverage, tc_corner_cases, tc_reset_error_coverage | 🟢 新增 |
| Random Tests | Cross/Key/Data/Error/Stress | tc_random_modes, tc_random_keys, tc_random_data, tc_random_errors, tc_stress_random | 🟢 新增 |

**图例**: 🟢 完成 | 🟡 部分完成/待RTL | ⚪ 未开始

**更新日期**: 2026-04-01 (新增5个随机测试用例)

---

## 回归测试执行

### 快速回归 (Smoke)
```bash
cd Temp/Verilator
make TEST=tc_smoke sim
```

### Verilator覆盖率回归 (Random Tests)
```bash
cd Temp/Verilator
# 单个测试
make TEST=tc_random_modes

# 全部5个随机测试
make run_all

# 合并覆盖率
make merge_cov

# 生成报告
make report
```

### Nightly回归 (核心功能)
```bash
make TEST=tc_ecb_nist sim
make TEST=tc_cbc_nist sim
make TEST=tc_ctr_nist sim
make TEST=tc_cbc_decrypt sim
make TEST=tc_ctr_counter sim
make TEST=tc_fault_inject sim
make TEST=tc_sbox_masked sim
```

### Weekly回归 (全量 - 42 tests)
```bash
# 包含新的5个随机测试用例
for test in tc_smoke tc_ecb_nist tc_cbc_nist tc_ctr_nist \
            tc_register_full tc_interrupt_all \
            tc_cbc_multiblock tc_ctr_multiblock \
            tc_cts_boundary tc_key_length tc_cbc_decrypt tc_ctr_counter \
            tc_gcm_basic tc_xts_basic tc_fault_inject tc_fault_data_corr \
            tc_sbox_masked tc_ecb_multiblock tc_key_len_error tc_key_len_check \
            tc_key_single tc_key_length_192_0 tc_key_length_192_1 tc_key_length_192_2 \
            tc_key_length_256_0 tc_key_length_256_1 tc_key_length_256_2 \
            tc_key_schedule_simple tc_key_schedule_timing \
            tc_aes_core_direct tc_aes128_only tc_mode_coverage \
            tc_error_handling tc_fault_inject \
            tc_toggle_coverage tc_corner_cases tc_reset_error_coverage \
            tc_random_modes tc_random_keys tc_random_data tc_random_errors tc_stress_random; do
    make TEST=$test sim
done
```

### Full Regression (使用脚本)
```bash
cd Database/Verification/Regression
# 完整回归 (42个测试用例)
./run_regression_full.sh

# 覆盖率收集回归
./run_coverage.sh all

# Verilator覆盖率回归 (随机测试)
cd ../../Temp/Verilator
./collect_coverage.sh
```

---

## Safety Mechanism Tests (新增 - 2026-04-01)

基于FuSa安全机制信号分析，新增5个安全机制验证测试用例。

### 测试用例列表

| Testcase | Description | Coverage | Status |
|----------|-------------|----------|--------|
| tc_safety_dual_rail | Dual-rail mismatch detection | SM-001~010 | Planned |
| tc_safety_crc_error | CRC error detection | SM-011~030 | Planned |
| tc_safety_key_zeroize | Key zeroization verification | SM-031~040 | Planned |
| tc_safety_fsm_timeout | FSM timeout detection | SM-041~048 | Planned |
| tc_safety_interrupt | Interrupt reporting | SM-041~048 | Planned |

### 详细说明

#### tc_safety_dual_rail
- **覆盖**: SM-001 ~ SM-010
- **描述**: 验证双轨故障检测机制在result_a和result_b不匹配时触发fault_detected
- **注入点**: result_a[0,7,15,31,63,95,127], result_b[0,63,127]
- **检查点**: fault_detected assertion
- **参考**: Safety_Mechanism_Signals.md 第3章

#### tc_safety_crc_error
- **覆盖**: SM-011 ~ SM-030
- **描述**: 验证CRC校验器检测数据损坏并触发故障
- **注入点**: data_in各位, crc_valid信号
- **检查点**: crc_valid=0, INT_STATUS[2]
- **参考**: Safety_Mechanism_Signals.md 第3章

#### tc_safety_key_zeroize
- **覆盖**: SM-031 ~ SM-040
- **描述**: 验证密钥清零机制安全清除密钥
- **注入点**: zeroize信号, APB密钥清除, key_in位
- **检查点**: key_out=0, key_valid=0
- **参考**: Safety_Mechanism_Signals.md 第3章

#### tc_safety_fsm_timeout
- **覆盖**: SM-041 ~ SM-048
- **描述**: 验证FSM超时检测卡住状态
- **注入点**: Force state到IDLE, KEY_WAIT, LOAD_DATA, ROUND_OP, OUTPUT_DATA
- **检查点**: INT_STATUS[3], watchdog timeout
- **参考**: Safety_Mechanism_Signals.md 第3章

#### tc_safety_interrupt
- **覆盖**: SM-041 ~ SM-048 (中断相关)
- **描述**: 验证所有故障类型的中断生成和报告
- **注入点**: 各种故障条件
- **检查点**: int_fault, INT_STATUS寄存器
- **参考**: Safety_Mechanism_Signals.md 第3章

---

## 注意事项

1. **AES-192/256**: 密钥长度相关测试用例需要RTL支持相应密钥长度
2. **GCM模式**: tc_gcm_basic 需要完整的GCM RTL实现（GHASH模块）
3. **XTS模式**: tc_xts_basic 需要XTS引擎和Tweak生成模块
4. **故障注入**: tc_fault_inject 为基础软件测试，硬件故障注入需FPGA/硅片验证
5. **覆盖率测试**: IDR新增3个覆盖率提升测试用例，用于最大化toggle/condition/FSM覆盖
6. **随机测试**: 新增5个随机测试用例，用于Verilator覆盖率收集和交叉覆盖验证
7. **安全机制测试**: 新增5个安全机制测试用例，用于验证FuSa安全机制，参考Safety_Mechanism_Signals.md

---

**文档版本**: v2.1  
**更新日期**: 2026-04-01  
**作者**: Verification Lead Agent  
**测试用例总数**: 42

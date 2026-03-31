# AES Crypto IP - Verification Plan

## 文档信息

| 字段 | 值 |
|------|-----|
| **版本** | v1.0 |
| **日期** | 2026-03-31 |
| **作者** | AI-Yang Verification Agent |
| **评审** | AI Yang (Quality Gatekeeper) |
| **任务** | TASK-AES-VER-001 |
| **ASIL** | ASIL-D |
| **状态** | Ready for Review |

## 文档控制

| 版本 | 日期 | 变更内容 | 作者 |
|------|------|---------|------|
| v0.1 | 2026-03-31 | 初始框架 | Verification Lead |
| v1.0 | 2026-03-31 | 完整验证计划，含TVLA、故障注入、CTS边界验证 | AI-Yang Verification Agent |

## 1. 验证策略

### 1.1 验证目标

本验证计划旨在确保AES Crypto IP达到车规级(ASIL-D)质量要求：

| 目标ID | 描述 | ASIL | 验证方法 |
|--------|------|------|----------|
| VER-G1 | 功能正确性: FIPS-197标准合规 | D | NIST测试向量、参考模型对比 |
| VER-G2 | 模式支持: ECB/CBC/CTR/GCM/XTS/CTS | B | 全模式覆盖验证 |
| VER-G3 | 侧信道防护: 1阶DPA抵抗 | D | TVLA测试通过 |
| VER-G4 | 故障检测: 安全机制有效性 | D | 故障注入验证 |
| VER-G5 | CTS边界: 1-127 bit非对齐数据 | B | 边界条件验证 |

### 1.2 验证层级

```
┌─────────────────────────────────────────────────────────────────┐
│                     验证层级金字塔                                │
├─────────────────────────────────────────────────────────────────┤
│  Level 5: Silicon Validation (硅后验证)                         │
│         └── 在真实芯片上进行验证                                  │
├─────────────────────────────────────────────────────────────────┤
│  Level 4: FPGA Prototyping (FPGA原型)                          │
│         └── 在FPGA上运行真实场景                                  │
├─────────────────────────────────────────────────────────────────┤
│  Level 3: System Test (系统级)    ← 当前文档重点                 │
│         └── Top-Level Integration Tests                         │
├─────────────────────────────────────────────────────────────────┤
│  Level 2: Subsystem Test (子系统级)                             │
│         ├── Mode Controller Test                                │
│         ├── Key Manager Test                                    │
│         └── Fault Detector Test                                 │
├─────────────────────────────────────────────────────────────────┤
│  Level 1: Unit Test (模块级)                                    │
│         ├── AES Core Test                                       │
│         ├── S-Box Test                                          │
│         ├── Key Schedule Test                                   │
│         └── CTS Logic Test                                      │
└─────────────────────────────────────────────────────────────────┘
```

### 1.3 验证方法学

| 方法 | 应用层级 | 覆盖率贡献 | 工具 |
|------|----------|-----------|------|
| **Directed Tests** | L1-L3 | 40% | UVM + NIST Vectors |
| **Constrained Random** | L2-L3 | 35% | SystemVerilog + UVM |
| **Formal Verification** | L1 | 15% | JasperGold/VC Formal |
| **Fault Injection** | L2-L3 | 10% | UVM + SVA |

### 1.4 验证入口/出口标准

**入口标准 (Entry Criteria):**
- [x] Architecture Spec v1.0 批准
- [x] 设计文档 (Design Spec) 完成
- [x] RTL Freeze (Lint/CDC clean)
- [x] UVM环境框架搭建完成

**出口标准 (Exit Criteria):**
- [ ] 代码覆盖率 >90% (Line/Condition/FSM/Toggle)
- [ ] 功能覆盖率 >85% (Covergroup/Cross)
- [ ] 断言覆盖率 >95% (SVA)
- [ ] TVLA测试通过 (|t| < 4.5)
- [ ] 故障注入测试: 安全机制检测率 >99%
- [ ] CTS边界条件: 1-127 bit全部覆盖
- [ ] 回归测试连续2周100%通过

---

## 2. 功能验证

### 2.1 测试向量来源

#### 2.1.1 NIST SP 800-38A 测试向量

所有标准模式的已知答案测试(KAT)向量必须来自NIST CAVP:

| 模式 | 测试向量文件 | 数量 | 来源 |
|------|-------------|------|------|
| ECB | `ecb_e_m.txt` | 400 | NIST CAVP AESVS |
| CBC | `cbc_e_m.txt` | 400 | NIST CAVP AESVS |
| CTR | `ctr_e_m.txt` | 400 | NIST CAVP AESVS |
| GCM | `gcmEncryptExtIV128.rsp` | 1000 | NIST CAVP GCMVS |
| XTS | 见2.2.3节 | 200 | IEEE P1619 |

#### 2.1.2 边界条件测试向量

| 边界类型 | 测试场景 | 预期结果 |
|----------|----------|----------|
| 最小数据 | 1 byte加密/解密 | 正确执行 |
| 最大数据 | 64KB连续加密 | 性能达标 |
| 密钥长度 | 128/192/256-bit | 正确派生 |
| IV/Nonce | 全0/全1/随机 | 正确初始化 |

### 2.2 功能测试计划

#### 2.2.1 ECB模式验证

| 测试ID | 描述 | 参考 | 优先级 |
|--------|------|------|--------|
| ECB-001 | AES-128 单块加密 | NIST SP 800-38A A.1 | P0 |
| ECB-002 | AES-192 单块加密 | NIST SP 800-38A A.1 | P0 |
| ECB-003 | AES-256 单块加密 | NIST SP 800-38A A.1 | P0 |
| ECB-004 | 多块连续加密 | - | P1 |
| ECB-005 | 错误密钥长度处理 | - | P1 |

#### 2.2.2 CBC模式验证

| 测试ID | 描述 | 参考 | 优先级 |
|--------|------|------|--------|
| CBC-001 | AES-128 CBC加密 | NIST SP 800-38A A.2 | P0 |
| CBC-002 | AES-128 CBC解密 | NIST SP 800-38A A.2 | P0 |
| CBC-003 | IV正确性验证 | - | P0 |
| CBC-004 | 链式依赖测试 | - | P1 |

#### 2.2.3 CTR模式验证

| 测试ID | 描述 | 参考 | 优先级 |
|--------|------|------|--------|
| CTR-001 | AES-128 CTR加密 | NIST SP 800-38A A.5 | P0 |
| CTR-002 | Counter递增验证 | - | P0 |
| CTR-003 | Counter溢出处理 | - | P1 |

#### 2.2.4 GCM模式验证

| 测试ID | 描述 | 参考 | 优先级 |
|--------|------|------|--------|
| GCM-001 | 认证加密 | NIST SP 800-38D | P0 |
| GCM-002 | 认证解密 | NIST SP 800-38D | P0 |
| GCM-003 | Tag验证失败处理 | - | P0 |
| GCM-004 | AAD处理 | - | P1 |

### 2.3 Ciphertext Stealing (CTS) 验证

#### 2.3.1 PAD Q4 解决: CTS边界条件覆盖

**问题描述**: 需验证CTS模式对1-127 bit非对齐数据的处理正确性。

**验证策略**:

| 数据长度(bit) | 测试场景 | 验证点 |
|---------------|----------|--------|
| 1-7 | 最小数据块 |  stealing逻辑正确性 |
| 8-31 | 短数据块 | 边界寄存器处理 |
| 32-63 | 中等数据块 | 中间值状态 |
| 64-95 | 较长数据块 | 数据对齐逻辑 |
| 96-127 | 近满块 | 最大stealing场景 |

**CTS验证用例设计**:

```
CTS Boundary Test Matrix:
├── Single Block (1-127 bit)
│   ├── Encrypt: P_n → C_n with stealing
│   └── Decrypt: C_n → P_n recovery
├── Two Blocks (1-127 bit final)
│   ├── Block n-1: 128-bit
│   └── Block n: 1-127 bit
├── Multi-block (variable final)
│   ├── N-1 full blocks
│   └── Final 1-127 bit with stealing
└── Error Cases
    ├── Zero length (error)
    └── >127 bit (error)
```

**测试向量生成方法**:

```python
# CTS Test Vector Generation Algorithm
def generate_cts_vectors():
    for final_len in range(1, 128):  # 1-127 bit coverage
        # Generate plaintext
        pt = random_bytes(16 * n + final_len // 8)
        if final_len % 8 != 0:
            pt += random_bits(final_len % 8)
        
        # Generate expected ciphertext using reference model
        ct_expected = xts_aes_encrypt(pt, key1, key2, sector_id)
        
        # Output test vector
        yield {
            'final_block_bits': final_len,
            'plaintext': pt.hex(),
            'ciphertext': ct_expected.hex(),
            'key1': key1.hex(),
            'key2': key2.hex(),
            'sector_id': sector_id
        }
```

| 测试ID | 描述 | 数据长度 | 优先级 |
|--------|------|----------|--------|
| CTS-B-001 | 最小stealing (1 bit) | 1 bit | P0 |
| CTS-B-002 | 奇数字节 (7 bit) | 7 bit | P0 |
| CTS-B-003 | 单字节 (8 bit) | 8 bit | P0 |
| CTS-B-004 | 十字节 (80 bit) | 80 bit | P0 |
| CTS-B-005 | 最大stealing (127 bit) | 127 bit | P0 |
| CTS-B-006~CTS-B-031 | 边界覆盖 (16,32,48,64,96 bit) | 多种 | P1 |

### 2.4 XTS-AES模式验证

| 测试ID | 描述 | 参考 | 优先级 |
|--------|------|------|--------|
| XTS-001 | 基本XTS加密 | IEEE P1619 | P0 |
| XTS-002 | Sector边界处理 | - | P0 |
| XTS-003 | Tweakey派生验证 | - | P1 |
| XTS-004 | Multi-sector连续处理 | - | P1 |

---

## 3. TVLA侧信道测试

### 3.1 测试目标

验证AES IP的侧信道防护机制（Boolean Masking + Shuffling）是否达到1阶DPA抵抗目标。

### 3.2 测试方法: Welch's t-test

#### 3.2.1 测试原理

TVLA (Test Vector Leakage Assessment) 使用Welch's t-test检测功耗轨迹中的信息泄露:

$$t = \frac{\mu_1 - \mu_2}{\sqrt{\frac{\sigma_1^2}{n_1} + \frac{\sigma_2^2}{n_2}}}$$

其中:
- $\mu_1$, $\mu_2$: 两组功耗轨迹的均值
- $\sigma_1^2$, $\sigma_2^2$: 两组功耗轨迹的方差  
- $n_1$, $n_2$: 样本数量

#### 3.2.2 通过标准

| 评估标准 | 阈值 | 说明 |
|----------|------|------|
| **通过** | $|t| < 4.5$ | 无显著泄露 |
| **警告** | $4.5 \leq |t| < 5.0$ | 可能泄露，需分析 |
| **失败** | $|t| \geq 5.0$ | 确认泄露，需修复 |

#### 3.2.3 样本数量要求

| 置信度 | 最小样本数 | 推荐样本数 |
|--------|-----------|-----------|
| 90% | 100,000 | - |
| 95% | 500,000 | 1,000,000 |
| 99% | 1,000,000 | 5,000,000 |

**本项目要求**: 至少1,000,000条功耗轨迹

### 3.3 测试配置

#### 3.3.1 固定vs随机测试 (Fixed vs Random)

```
Test Type: Non-Specific (Fixed vs Random)
├── Fixed Group: 固定明文，固定密钥
│   └── 测量功耗轨迹 S_fixed
├── Random Group: 随机明文，固定密钥
│   └── 测量功耗轨迹 S_random
└── t-test: 比较 S_fixed vs S_random
```

#### 3.3.2 特定测试 (Specific)

```
Test Type: Specific (Intermediate Value)
├── Group A: 第1轮S-Box输出LSB = 0
├── Group B: 第1轮S-Box输出LSB = 1
└── t-test: 比较 Group A vs Group B
```

### 3.4 测试点覆盖

| 测试点 | 描述 | 测试类型 | 样本数 |
|--------|------|----------|--------|
| TP-001 | 第1轮AddRoundKey输出 | Specific | 1M |
| TP-002 | 第1轮SubBytes输入 | Specific | 1M |
| TP-003 | 第1轮SubBytes输出 | Specific | 1M |
| TP-004 | 最后1轮输出 | Specific | 1M |
| TP-005 | KeySchedule输出 | Specific | 1M |
| TP-006 | 整体功耗轨迹 | Non-Specific | 1M |

### 3.5 TVLA测试流程

```
TVLA Test Flow:
├── Phase 1: 数据采集
│   ├── 配置DUT为TVLA测试模式
│   ├── 采集1,000,000条功耗轨迹
│   └── 存储为.trc格式
├── Phase 2: t-test分析
│   ├── 导入功耗轨迹
│   ├── 执行Welch's t-test
│   └── 生成t-value曲线
├── Phase 3: 结果判定
│   ├── 检查max(|t|) < 4.5
│   ├── 分析峰值位置
│   └── 输出TVLA报告
└── Phase 4: 回归测试
    ├── 修复后重新采集
    └── 验证问题关闭
```

### 3.6 测试设备

| 设备 | 型号 | 用途 |
|------|------|------|
| 示波器 | R&S RTO6 | 功耗轨迹采集 |
| 探针 | R&S RT-ZPR40 | 电源轨测量 |
| 电磁探头 | Langer EMV-Technik ICR HH 500-6 | EM侧信道 |
| 分析软件 | ChipWhisperer / Riscure Inspector | 轨迹分析 |

---

## 4. 故障注入验证

### 4.1 安全机制验证

#### 4.1.1 故障检测机制

| 机制ID | 描述 | 检测率目标 | 验证方法 |
|--------|------|-----------|----------|
| FD-001 | 双核Lockstep比较 | 99% | Clock glitch注入 |
| FD-002 | CRC-32数据完整性 | 99% | Data corruption |
| FD-003 | Watchdog超时检测 | 90% | Stall注入 |
| FD-004 | Parity寄存器检查 | 90% | Bit flip注入 |

#### 4.1.2 故障注入类型

```
Fault Injection Types:
├── Clock Glitch
│   ├── Single cycle glitch
│   ├── Multi-cycle glitch
│   └── Duty cycle variation
├── Voltage Glitch
│   ├── Undervoltage
│   └── Overvoltage
├── Laser/EM Fault
│   ├── Targeted bit flip
│   └── Row/column hammer
└── Data Corruption
    ├── Input data flip
    ├── Key bit flip
    └── Internal signal flip
```

### 4.2 故障注入测试用例

#### 4.2.1 Clock Glitch测试

| 测试ID | 注入时机 | 持续时间 | 预期检测 |
|--------|----------|----------|----------|
| FG-001 | Round 1 SubBytes | 1 cycle | 报警 |
| FG-002 | Round 5 MixColumns | 2 cycles | 报警 |
| FG-003 | Key Schedule | 1 cycle | 报警 |
| FG-004 | 空闲状态 | 1 cycle | 正常恢复 |

#### 4.2.2 Data Corruption测试

| 测试ID | 目标信号 | 翻转位数 | 预期检测 |
|--------|----------|----------|----------|
| FD-001 | ciphertext[0] | 1 | CRC错误 |
| FD-002 | ciphertext[63:32] | 8 | CRC错误 |
| FD-003 | key[127:0] | 1 | Lockstep错误 |
| FD-004 | internal_state | 1 | Lockstep错误 |

### 4.3 安全目标验证

| 安全目标 | ASIL | 验证方法 | 通过标准 |
|----------|------|----------|----------|
| SG1: 防止密钥泄露 | D | 故障注入+TVLA | 无密钥泄露 |
| SG2: 防止错误加密结果 | D | 双核Lockstep | 100%错误检测 |
| SG3: 检测故障攻击 | D | 各类故障注入 | >99%检测率 |

---

## 5. 覆盖率计划

### 5.1 覆盖率目标

| 覆盖率类型 | 目标 | 当前 | 状态 |
|------------|------|------|------|
| **代码覆盖率** | | | |
| Line Coverage | >90% | - | ⚪ |
| Condition Coverage | >90% | - | ⚪ |
| FSM Coverage | >95% | - | ⚪ |
| Toggle Coverage | >85% | - | ⚪ |
| **功能覆盖率** | >85% | - | ⚪ |
| **断言覆盖率** | >95% | - | ⚪ |

### 5.2 代码覆盖率细分

#### 5.2.1 模块级覆盖率目标

| 模块 | Line | Condition | FSM | Toggle |
|------|------|-----------|-----|--------|
| aes_controller | 95% | 95% | 100% | 90% |
| aes_core | 92% | 90% | 100% | 88% |
| key_manager | 95% | 95% | 100% | 90% |
| key_schedule | 90% | 90% | 100% | 85% |
| sbox_masked | 90% | 85% | - | 80% |
| mode_controller | 92% | 90% | 100% | 88% |
| fault_detector | 95% | 95% | 100% | 90% |
| crc_checker | 95% | 95% | - | 90% |

### 5.3 功能覆盖点定义

#### 5.3.1 Covergroup定义

```systemverilog
// AES Mode Coverage
covergroup cg_aes_mode;
    cp_mode: coverpoint mode {
        bins ecb = {MODE_ECB};
        bins cbc = {MODE_CBC};
        bins ctr = {MODE_CTR};
        bins gcm = {MODE_GCM};
        bins xts = {MODE_XTS};
        bins cts = {MODE_CTS};
        bins other = default;
    }
    
    cp_key_len: coverpoint key_len {
        bins aes128 = {KEY_128};
        bins aes192 = {KEY_192};
        bins aes256 = {KEY_256};
    }
    
    cx_mode_key: cross cp_mode, cp_key_len;
endgroup

// CTS Coverage
covergroup cg_cts_boundary;
    cp_final_len: coverpoint final_block_len {
        bins bit_1_7 = {[1:7]};
        bins bit_8_31 = {[8:31]};
        bins bit_32_63 = {[32:63]};
        bins bit_64_95 = {[64:95]};
        bins bit_96_127 = {[96:127]};
    }
endgroup
```

### 5.4 断言覆盖点

| 断言ID | 描述 | 覆盖类型 |
|--------|------|----------|
| AST-001 | 密钥长度有效性 | 条件覆盖 |
| AST-002 | 模式有效性 | 条件覆盖 |
| AST-003 | CTS使能与模式匹配 | 交叉覆盖 |
| AST-004 | 忙信号正确性 | 时序覆盖 |
| AST-005 | 数据完整性 | 时序覆盖 |

---

## 6. UVM环境设计

### 6.1 环境架构

```
UVM Environment Architecture:
└── tb_top
    ├── clk_rst_if (时钟复位接口)
    ├── axi4_stream_if (数据流接口)
    ├── apb_if (配置接口)
    ├── dut (AES IP)
    └── uvm_test_top
        └── aes_test
            └── aes_env
                ├── axi4_stream_agent (数据Agent)
                │   ├── axi4_stream_driver
                │   ├── axi4_stream_sequencer
                │   ├── axi4_stream_monitor
                │   └── axi4_stream_agent_config
                ├── apb_agent (配置Agent)
                │   ├── apb_driver
                │   ├── apb_sequencer
                │   └── apb_monitor
                ├── scoreboard (参考模型对比)
                │   ├── golden_model (Python C reference)
                │   └── comparator
                └── coverage_collector
```

### 6.2 Golden Reference Model

| 模型 | 语言 | 来源 | 用途 |
|------|------|------|------|
| PyCryptodome | Python | NIST验证 | 主参考模型 |
| OpenSSL | C | 开源 | 交叉验证 |
| TinyAES | C | 开源 | 嵌入式对比 |

### 6.3 Sequence Library

| Sequence | 描述 | 使用场景 |
|----------|------|----------|
| `aes_nist_seq` | NIST测试向量Sequence | 回归测试 |
| `aes_random_seq` | 随机数据Sequence | 随机验证 |
| `aes_cts_boundary_seq` | CTS边界测试Sequence | PAD Q4验证 |
| `aes_error_seq` | 错误注入Sequence | 故障验证 |
| `aes_stress_seq` | 压力测试Sequence | 稳定性 |

### 6.4 Testcase列表

| Testcase | 描述 | 模式 | 覆盖率 |
|----------|------|------|--------|
| `test_aes128_ecb` | AES-128 ECB基础测试 | ECB | Line/FSM |
| `test_aes256_xts` | AES-256 XTS测试 | XTS | Line/FSM |
| `test_cts_boundary` | CTS边界测试 | CTS | PAD Q4 |
| `test_all_modes` | 全模式回归 | ALL | Cross |
| `test_fault_inject` | 故障注入测试 | ALL | Assert |

---

## 7. 回归策略

### 7.1 回归测试层级

```
Regression Levels:
├── Level 1: Smoke Test (5分钟)
│   ├── 基础功能快速验证
│   └── 关键路径覆盖
├── Level 2: Nightly (2小时)
│   ├── 全功能测试
│   ├── NIST向量验证
│   └── CTS边界测试
├── Level 3: Weekly (8小时)
│   ├── 全回归测试
│   ├── 随机约束测试
│   └── 覆盖率收敛
└── Level 4: Pre-Gate (24小时)
    ├── 全量回归
    ├── 故障注入
    ├── TVLA预测试
    └── 最终覆盖率检查
```

### 7.2 回归执行计划

| 回归类型 | 频率 | 测试数 | 目标 | 负责人 |
|----------|------|--------|------|--------|
| Smoke | 每次提交 | 10 | 快速验证 | CI |
| Nightly | 每日02:00 | 100 | 功能验证 | CI |
| Weekly | 周六00:00 | 500 | 覆盖率收敛 | Verification |
| Pre-Gate | 里程碑前 | 1000 | Sign-off | Verification Lead |

### 7.3 回归通过标准

| 回归级别 | 通过率 | 覆盖率 | Bug允许 |
|----------|--------|--------|---------|
| Smoke | 100% | N/A | 0 |
| Nightly | 100% | >80% | P3/P4 |
| Weekly | 100% | >90% | P4 only |
| Pre-Gate | 100% | 目标达成 | 0 |

### 7.4 CI/CD集成

```yaml
# .gitlab-ci.yml 示例
stages:
  - lint
  - smoke
  - nightly
  - coverage

smoke_test:
  stage: smoke
  script:
    - make smoke_test
  only:
    - merge_requests

nightly_regression:
  stage: nightly
  script:
    - make nightly_regression
  schedule:
    - cron: "0 2 * * *"

coverage_report:
  stage: coverage
  script:
    - make coverage_report
  artifacts:
    reports:
      coverage_report: coverage_report.html
```

---

## 附录A: 参考文档

| 文档ID | 名称 | 版本 | 位置 |
|--------|------|------|------|
| REF-001 | FIPS-197 | - | NIST标准 |
| REF-002 | NIST SP 800-38A | - | NIST标准 |
| REF-003 | NIST SP 800-38D | - | NIST标准 |
| REF-004 | IEEE P1619 | - | IEEE标准 |
| REF-005 | Architecture Spec | v1.0 | `Database/Docs/Arch/` |
| REF-006 | Design Spec | v1.0 | `Database/Docs/Design/` |

## 附录B: 缩略语

| 缩写 | 全称 |
|------|------|
| AES | Advanced Encryption Standard |
| ASIL | Automotive Safety Integrity Level |
| CTS | Ciphertext Stealing |
| DPA | Differential Power Analysis |
| KAT | Known Answer Test |
| TVLA | Test Vector Leakage Assessment |
| UVM | Universal Verification Methodology |

---

**文档结束**

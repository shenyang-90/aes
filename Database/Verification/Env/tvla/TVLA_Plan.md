# AES IP TVLA (Test Vector Leakage Assessment) Plan

## 文档信息

| 字段 | 值 |
|------|-----|
| **版本** | v1.0 |
| **日期** | 2026-03-31 |
| **作者** | AI-Yang Verification Agent |
| **任务** | TASK-AES-VER-001 |
| **ASIL** | ASIL-D |
| **参考标准** | NIST IR 8319, ISO/IEC 17825 |

## 1. 概述

### 1.1 目的

本文档定义AES Crypto IP的侧信道泄露评估测试计划，确保防护机制（Boolean Masking + Threshold Implementation + Shuffling）达到**1阶DPA抵抗**目标。

### 1.2 适用范围

| 组件 | 测试内容 | ASIL |
|------|----------|------|
| aes_core | 轮运算侧信道 | D |
| sbox_masked | TI-SBox泄露 | D |
| key_schedule | 密钥扩展泄露 | D |
| key_manager | 密钥存储泄露 | D |

### 1.3 通过标准

| 评估等级 | t-value阈值 | 判定 |
|----------|-------------|------|
| **通过** | $|t| < 4.5$ | 无显著泄露 |
| **警告** | $4.5 \leq |t| < 5.0$ | 需分析 |
| **失败** | $|t| \geq 5.0$ | 确认泄露 |

---

## 2. TVLA方法论

### 2.1 Welch's t-test原理

TVLA使用Welch's t-test比较两组功耗轨迹的统计差异：

$$t = \frac{\bar{X}_1 - \bar{X}_2}{\sqrt{\frac{s_1^2}{n_1} + \frac{s_2^2}{n_2}}}$$

其中：
- $\bar{X}_1$, $\bar{X}_2$：两组样本均值
- $s_1^2$, $s_2^2$：两组样本方差
- $n_1$, $n_2$：样本数量（本项目要求 $n_1 = n_2 \geq 500,000$）

### 2.2 测试类型

```
TVLA Test Classification:
│
├── Non-Specific Tests (非特定测试)
│   ├── Fixed vs Random
│   │   └── Group 1: 固定输入
│   │   └── Group 2: 随机输入
│   └── Random vs Random
│       └── 用于基线校准
│
└── Specific Tests (特定测试)
    ├── Intermediate Value Tests
    │   └── 基于算法中间值分组
    ├── Hamming Weight Tests
    │   └── 基于汉明重量分组
    └── Transition Tests
        └── 基于状态转换分组
```

### 2.3 样本数量要求

| 置信水平 | 最小样本数 | 推荐样本数 | 用途 |
|----------|-----------|-----------|------|
| 90% | 100,000 | 200,000 | 快速筛选 |
| 95% | 500,000 | 1,000,000 | 标准验证 |
| 99% | 1,000,000 | 5,000,000 | 高置信度 |

**本项目要求**: 每测试点至少 **1,000,000** 条轨迹

---

## 3. 测试配置

### 3.1 设备配置

| 设备类型 | 型号/规格 | 用途 | 参数 |
|----------|-----------|------|------|
| 示波器 | R&S RTO6 | 功耗采集 | 2.5 GSa/s, 12-bit |
| 差分探头 | R&S RT-ZD40 | VDD测量 | 4 GHz, 1.0 pF |
| 电源探头 | R&S RT-ZPR40 | 电源轨测量 | 2 GHz, 50 Ω |
| EM探头 | Langer ICR HH 500-6 | 电磁泄露 | 1.5 MHz - 6 GHz |
| 放大器 | Langer PA 303 | 信号放大 | 30 dB |
| FPGA平台 | CW305 / Sakura-G | DUT平台 | Xilinx Artix-7 |
| 分析软件 | ChipWhisperer | 轨迹分析 | v5.6+ |

### 3.2 DUT配置

```python
# TVLA Test Configuration
tvla_config = {
    'dut': 'AES_IP',
    'clock_freq': '100MHz',
    'voltage': '1.0V',
    'temperature': '25°C',
    'sampling_rate': '1 GSa/s',
    'trigger': 'encryption_start',
    'trace_length': '2000 samples',
    'pre_trigger': '100 samples',
    'post_trigger': '1900 samples'
}
```

### 3.3 测试点选择

| 测试点ID | 描述 | 敏感操作 | 测试类型 |
|----------|------|----------|----------|
| TP-SB-01 | 第1轮S-Box输入 | 明文⊕密钥 | Specific |
| TP-SB-02 | 第1轮S-Box输出 | SubBytes结果 | Specific |
| TP-SB-03 | 第10轮S-Box输出 | 密文前状态 | Specific |
| TP-KS-01 | KeySchedule输出 | 轮密钥 | Specific |
| TP-MC-01 | MixColumns输出 | 列混淆结果 | Specific |
| TP-AR-01 | AddRoundKey输出 | 密钥加结果 | Specific |
| TP-GLB-01 | 全加密过程 | 整体泄露 | Non-Specific |

---

## 4. 测试用例

### 4.1 Non-Specific Test: Fixed vs Random

#### 测试配置

| 参数 | 值 |
|------|-----|
| 测试ID | TVLA-NS-001 |
| 类型 | Fixed vs Random |
| 固定组 | KEY=固定, PT=固定 |
| 随机组 | KEY=固定, PT=随机 |
| 样本数 | 1,000,000 per group |
| 迭代次数 | 3次 |

#### 测试步骤

```
TVLA-NS-001 Procedure:
1. 固定DUT密钥: KEY_FIXED = 0x0123...CDEF
2. 固定DUT明文: PT_FIXED = 0xAABB...0011
3. 采集轨迹:
   FOR i = 1 to 1,000,000:
       IF random_bit() == 0:
           PT = PT_FIXED    (Fixed group)
       ELSE:
           PT = RANDOM()    (Random group)
       Trigger encryption
       Capture power trace
       Store (trace, group_id)
4. 执行t-test
5. 检查 max(|t|) < 4.5
```

### 4.2 Specific Test: 1st Round S-Box Output

#### 测试配置

| 参数 | 值 |
|------|-----|
| 测试ID | TVLA-SP-001 |
| 类型 | Specific (LSB based) |
| 中间值 | Round 1 S-Box Output |
| 分组依据 | S-Box Output[0] (LSB) |
| 样本数 | 1,000,000 per group |

#### 测试步骤

```
TVLA-SP-001 Procedure:
1. 固定DUT密钥: KEY_FIXED
2. 定义中间值函数: f(PT) = S-Box(PT ⊕ KEY)[0]
3. 采集轨迹:
   WHILE |group_0| < 500,000 OR |group_1| < 500,000:
       PT = RANDOM()
       IF f(PT) == 0:
           Add to Group 0
       ELSE:
           Add to Group 1
       Trigger encryption
       Capture power trace
4. 执行t-test on Group 0 vs Group 1
5. 检查 max(|t|) < 4.5
```

### 4.3 Specific Test: Hamming Weight

| 参数 | 值 |
|------|-----|
| 测试ID | TVLA-SP-002 |
| 类型 | Specific (Hamming Weight) |
| 目标 | S-Box输出汉明重量 |
| 分组 | HW=4 vs HW=5 |
| 样本数 | 500,000 per group |

---

## 5. 测试矩阵

### 5.1 完整测试矩阵

| 测试ID | 目标模块 | 测试类型 | 样本数 | 优先级 | 状态 |
|--------|----------|----------|--------|--------|------|
| TVLA-NS-001 | Full AES | Fixed-Random | 1M×2 | P0 | ⚪ |
| TVLA-NS-002 | Full AES | Random-Random | 1M×2 | P1 | ⚪ |
| TVLA-SP-001 | S-Box R1 | LSB分组 | 500K×2 | P0 | ⚪ |
| TVLA-SP-002 | S-Box R1 | HW分组 | 500K×2 | P0 | ⚪ |
| TVLA-SP-003 | S-Box R10 | LSB分组 | 500K×2 | P0 | ⚪ |
| TVLA-SP-004 | KeySchedule | LSB分组 | 500K×2 | P0 | ⚪ |
| TVLA-SP-005 | MixColumns | LSB分组 | 500K×2 | P1 | ⚪ |
| TVLA-SP-006 | AddRoundKey | LSB分组 | 500K×2 | P1 | ⚪ |
| TVLA-EM-001 | EM泄露 | Fixed-Random | 1M×2 | P1 | ⚪ |

### 5.2 回归测试矩阵

| 阶段 | 测试项 | 频率 | 样本数 |
|------|--------|------|--------|
| Nightly | TVLA-NS-001 (快速) | Daily | 100K×2 |
| Weekly | Full TVLA Suite | Weekly | 完整配置 |
| Pre-Gate | All P0 Tests | Gate前 | 1M×2 |

---

## 6. 数据分析

### 6.1 分析流程

```
TVLA Data Analysis Pipeline:
├── 1. 数据预处理
│   ├── 对齐 (Alignment)
│   ├── 滤波 (Filtering)
│   └── 归一化 (Normalization)
├── 2. 统计计算
│   ├── 计算各点均值
│   ├── 计算各点方差
│   └── 计算t-value
├── 3. 峰值检测
│   ├── 找出max(|t|)
│   ├── 定位泄露点
│   └── 分析泄露原因
└── 4. 报告生成
    ├── t-value曲线图
    ├── 泄露点标注
    └── 通过/失败判定
```

### 6.2 可视化要求

| 图表类型 | 内容 | 用途 |
|----------|------|------|
| t-value曲线 | t-value vs 时间 | 直观显示泄露位置 |
| 轨迹均值 | Group均值对比 | 可视化差异 |
| 直方图 | t-value分布 | 统计分布验证 |
| 热力图 | 多轮次结果 | 趋势分析 |

### 6.3 分析脚本

```python
# tvla_analysis.py - 伪代码
def analyze_tvla(traces_file):
    # 加载数据
    traces = load_traces(traces_file)
    group_0 = traces.filter(group=0)
    group_1 = traces.filter(group=1)
    
    # 计算统计量
    mean_0 = np.mean(group_0, axis=0)
    mean_1 = np.mean(group_1, axis=0)
    var_0 = np.var(group_0, axis=0, ddof=1)
    var_1 = np.var(group_1, axis=0, ddof=1)
    
    # Welch's t-test
    n0, n1 = len(group_0), len(group_1)
    t_values = (mean_0 - mean_1) / np.sqrt(var_0/n0 + var_1/n1)
    
    # 结果判定
    max_t = np.max(np.abs(t_values))
    if max_t < 4.5:
        result = "PASS"
    elif max_t < 5.0:
        result = "WARNING"
    else:
        result = "FAIL"
    
    return {
        'max_t': max_t,
        't_values': t_values,
        'result': result
    }
```

---

## 7. 报告模板

### 7.1 测试报告结构

```markdown
# TVLA Test Report - [Test ID]

## 1. 测试信息
- 测试日期: YYYY-MM-DD
- 测试人员: [Name]
- DUT版本: [Version]
- 环境条件: 25°C, 1.0V, 100MHz

## 2. 测试配置
- 样本数量: 1,000,000 × 2
- 采样率: 1 GSa/s
- 轨迹长度: 2000 samples

## 3. 结果汇总
| 指标 | 值 | 阈值 | 判定 |
|------|-----|------|------|
| max(\|t\|) | [Value] | 4.5 | [Pass/Fail] |
| 泄露点数 | [Count] | 0 | [Pass/Fail] |
| 置信度 | 95% | >90% | Pass |

## 4. t-value曲线
[Attach plot]

## 5. 结论
- 判定结果: [Pass/Warning/Fail]
- 建议措施: [If applicable]
```

### 7.2 结果归档

| 文件类型 | 命名规范 | 存储位置 |
|----------|----------|----------|
| 原始轨迹 | `TVLA_[ID]_[DATE].trc` | `Database/Verification/tvla/traces/` |
| 分析报告 | `TVLA_[ID]_Report_[DATE].pdf` | `Database/Verification/tvla/reports/` |
| t-value数据 | `TVLA_[ID]_tvalues_[DATE].npz` | `Database/Verification/tvla/data/` |
| 配置文件 | `TVLA_[ID]_config_[DATE].json` | `Database/Verification/tvla/config/` |

---

## 8. 问题处理流程

### 8.1 失败处理流程

```
TVLA Failure Handling:
├── Step 1: 复现验证
│   └── 重新采集样本，确认非偶然
├── Step 2: 根因分析
│   ├── 检查测试配置
│   ├── 检查DUT配置
│   └── 分析泄露位置
├── Step 3: 设计修复
│   ├── 增强masking
│   ├── 优化shuffling
│   └── 增加dummy cycles
├── Step 4: 回归验证
│   └── 重新执行TVLA测试
└── Step 5: 报告更新
    └── 记录修复措施和验证结果
```

### 8.2 常见问题

| 问题 | 可能原因 | 解决方案 |
|------|----------|----------|
| |t| > 5.0 | Masking不足 | 增加share数 |
| 特定点泄露 | 毛刺 | 添加registers |
| 随机高t值 | 样本不足 | 增加样本数 |
| 对齐错误 | Trigger不稳 | 优化trigger |

---

## 9. 时间安排

| 阶段 | 任务 | 时间 | 负责人 |
|------|------|------|--------|
| Week 1 | 设备setup | 5天 | Verification |
| Week 2 | 基线测试 | 5天 | Verification |
| Week 3-4 | 全TVLA测试 | 10天 | Verification |
| Week 5 | 数据分析 | 5天 | Verification |
| Week 6 | 报告生成 | 5天 | Verification Lead |

---

## 10. 参考文档

| 文档 | 版本 | 说明 |
|------|------|------|
| NIST IR 8319 | 2020 | TVLA Guidelines |
| ISO/IEC 17825 | 2016 | Test methods for side-channel |
| FIPS 140-3 | 2019 | Security requirements |
| AES IP Arch Spec | v1.0 | 设计规格 |

---

**文档结束**

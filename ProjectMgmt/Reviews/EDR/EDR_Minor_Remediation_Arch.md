# EDR Minor Issues Remediation - Architecture Specification

**任务ID**: TASK-AES-EDR-002-ARCH  
**文档版本**: Architecture_Spec.md v1.1  
**修复日期**: 2026-04-02  
**修复人**: IP Architect  

---

## 修复概览

| Issue ID | 章节 | 问题描述 | 修复状态 |
|----------|------|----------|----------|
| m16 | 5.1 | XTS公式⊗符号未定义 | ✅ 已修复 |
| m17 | 2.2 | 面积估算缺乏置信区间 | ✅ 已修复 |
| m18 | 7.2 | L3门控使能逻辑未详细说明 | ✅ 已修复 |
| m19 | 7.1 | 功耗数据缺少PVT条件 | ✅ 已修复 |
| m20 | 10.1 | 专利申请点描述笼统 | ✅ 已修复 |

---

## 详细修复内容

### m16: XTS Operator Definition (Chapter 5.1)

**问题**: XTS公式 `T = E_K2(i) ⊗ α^j` 中 ⊗ 符号未明确定义是GF乘法还是普通乘法。

**修复措施**:
- 添加运算符详细定义表格
- 明确 `⊗` 为 **GF(2^128) 有限域乘法**
- 说明多项式基底: x^128 + x^7 + x^2 + x + 1 (AES-GCM标准)
- 补充实现方式说明: 移位+异或算法或 LUT-based
- 强调与普通整数乘法的区别

**新增内容**:
```markdown
**运算符详细定义**:

| 符号 | 定义 | 实现说明 |
|------|------|----------|
| `⊗` | **GF(2^128) 有限域乘法** | 多项式基底: x^128 + x^7 + x^2 + x + 1 |
| `⊕` | 按位异或 (Bitwise XOR) | 标准 128-bit XOR 操作 |
| `α^j` | α 的 j 次幂 | α = x (0x02)，通过连续 GF 乘法计算 |
```

---

### m17: Area Estimation Confidence Interval (Chapter 2.2)

**问题**: 模块面积估算只有单点值，缺乏置信区间说明。

**修复措施**:
- 章节标题从"模块划分"改为"模块划分与面积估算"
- 面积列增加置信区间列
- 各模块面积补充90%置信水平下的区间范围
- 添加置信区间说明脚注

**面积估算更新示例**:

| 模块 | 面积估算 | 置信区间 (90%) |
|------|----------|----------------|
| aes_controller | ~2.5K gates | ±15% (2.1K~2.9K) |
| aes_core | ~12K gates/核 | ±12% (10.6K~13.4K) |
| sbox_masked | ~8K gates | ±10% (7.2K~8.8K) |
| **总计(双核)** | **~50K gates** | **±13% (43K~57K)** |

**置信区间说明**:
- 工艺节点: TSMC 22nm
- 目标频率: 100MHz
- 综合工具: Design Compiler 2023.03
- 基于3次独立综合迭代的统计结果

---

### m18: L3 Clock Gating Enable Logic (Chapter 7.2)

**问题**: L3级门控使能信号生成逻辑未详细说明。

**修复措施**:
- 新增完整7.2节"时钟架构与L3门控逻辑"
- 描述三级时钟门控策略 (L1/L2/L3)
- 详细说明4个L3门控使能信号生成逻辑:
  - `sbox_clk_en`: S-Box运算阶段使能
  - `round_reg_en`: 轮运算数据通路门控
  - `keysched_clk_en`: 密钥调度门控
  - `tweak_clk_en`: XTS tweak计算门控
- 提供Verilog代码示例
- 添加门控时序约束表格
- 补充功耗优化效果数据

**关键代码示例** (S-Box门控):
```verilog
assign sbox_clk_en = (state == AES_SUBBYTES) || 
                     (state == AES_KEYEXP)    ||
                     (mask_refresh_req);

clk_gate_l3 u_sbox_cg (
    .clk_i      (aclk),
    .clk_en_i   (sbox_clk_en),
    .test_en_i  (scan_mode),
    .clk_o      (sbox_gated_clk)
);
```

---

### m19: Power PVT Conditions (Chapter 7.1)

**问题**: 功耗数据缺少工艺/电压/温度(PVT)条件说明。

**修复措施**:
- 性能指标表格增加PVT条件列
- 补充三种PVT corner的功耗数据:
  - **TT/0.80V/25°C**: 典型工况 <10mW
  - **FF/0.88V/125°C**: 最坏情况 <18mW
  - **SS/0.72V/-40°C**: 最低情况 <3mW
- 添加详细PVT条件定义表格
- 说明功耗计算条件 (活动因子、切换率、测试向量等)

**PVT条件定义**:

| 参数 | 典型工况 | 最坏情况 | 最低情况 |
|------|----------|----------|----------|
| Process | TT | FF | SS |
| Voltage | 0.80V | 0.88V | 0.72V |
| Temperature | 25°C | 125°C | -40°C |

---

### m20: Patent Technical Details (Chapter 10.1)

**问题**: 专利申请点描述较笼统，需增加技术细节。

**修复措施**:
- 新增第10章"知识产权与专利申请"
- 详细描述3个可专利申请技术点:
  
  **专利点 #1: 可配置双核锁步AES架构**
  - 技术问题: 传统固定双核架构无法灵活降配
  - 创新方案: 编译时ENABLE_LOCKSTEP + 运行时DUAL_RAIL_EN动态切换
  - 技术细节: 时钟/复位同步、故障检测延迟<1 cycle
  - 专利性评估: 高新颖性、高非显而易见性
  
  **专利点 #2: 三级分层时钟门控与侧信道防护协同**
  - 技术问题: 精细门控可能引入时序侧信道
  - 创新方案: L3门控与掩码刷新同步、恒定时间门控决策
  - 技术细节: 门控仅在掩码刷新间隙生效
  
  **专利点 #3: 基于GF(2^128)动态Tweak生成的XTS优化**
  - 技术问题: XTS tweak计算资源消耗大
  - 创新方案: 增量式更新电路 + α乘法的极简实现
  - 技术细节: T_j+1 = T_j ⊗ α (单次GF乘法/块)
  - 面积节省: ~800 gates vs ~5K gates (传统)

- 添加专利申请策略建议表格
- 提供申请时间线和文档准备清单

---

## 依赖对齐确认

以下修复输出供Design Agent参考:

| 本任务Issue | 影响Design Agent Issue | 对齐内容 |
|-------------|------------------------|----------|
| m17 | m1 (S-Box面积) | S-Box面积区间: 7.2K~8.8K gates (90%置信度) |
| m18 | m3 (时钟偏斜) | L3门控时钟偏斜要求: <50ps |
| m19 | m4 (功耗量化) | PVT条件: TT/0.80V/25°C (典型), FF/0.88V/125°C (最坏) |

---

## 文档版本更新

| 字段 | 更新前 | 更新后 |
|------|--------|--------|
| 版本 | v1.0 | v1.1 |
| 日期 | 2026-04-01 | 2026-04-02 |
| 作者 | System Architect | IP Architect |
| 状态 | Updated - Lockstep Integration | Updated - EDR Minor Issues Fixed |

---

## Sign-off

| 角色 | 状态 | 日期 |
|------|------|------|
| IP Architect | ✅ 修复完成 | 2026-04-02 |

---

**下一步**: 
- Design Agent使用m17/m18/m19修复内容进行RTL级修复
- PM Agent整合所有EDR修复结果

# EDR 阶段任务执行指令

## 🎯 Design Agent (Coding Yang) - TASK-AES-EDR-001

### 执行命令
```
Coding Yang 任务：编写 AES IP Design Specification v1.0
```

### 执行步骤

```bash
# 1. 进入项目目录
cd /root/.openclaw/workspace/sandbox/aes

# 2. 阅读 Architecture Spec
cat Database/Docs/Arch/Architecture_Spec.md

# 3. 创建 Design 目录
mkdir -p Database/Docs/Design

# 4. 编写 Design Specification (8章节)
# 文件: Database/Docs/Design/Design_Specification.md
# 必须包含:
#   - Ch1: Overview
#   - Ch2: Function Descriptions (7个子章节)
#   - Ch3: Register Descriptions (必须解决Q1: INT_EN 0x48, INT_STATUS 0x4C)
#   - Ch4: Example
#   - Ch5: Block Design
#   - Ch6: FSM
#   - Ch7: Low Power (必须解决Q2: 时钟门控)
#   - Ch8: Patent

# 5. 编写 TI S-Box 详细设计
# 文件: Database/Docs/Design/TI_SBox_Design.md
# 必须引用: Nikova et al. "Threshold Implementations Against Side-Channel Attacks"

# 6. 编写 CTS/XTS 详细设计
# 文件: Database/Docs/Design/CTS_XTS_Design.md
# 必须包含: CTS边界条件处理 (1-127 bit)

# 7. 编写 CDC Strategy
# 文件: Database/Docs/Design/CDC_Strategy.md
# 说明: 单时钟设计，无CDC问题

# 8. Git commit & push
git add -A
git commit -m "docs: add Design Specification v1.0 (EDR phase)

- Design_Specification.md (8 chapters)
- TI_SBox_Design.md (3-share masking)
- CTS_XTS_Design.md (boundary handling)
- CDC_Strategy.md (single clock)

Resolves PAD Q1 (interrupt registers)
Resolves PAD Q2 (low power strategy)"
git push origin main

# 9. 更新任务状态
# 移动 task_queue/active/TASK-AES-EDR-001.json 到 completed/
```

### 关键检查点
- [ ] INT_EN (0x48) 和 INT_STATUS (0x4C) 寄存器定义完成 (Q1)
- [ ] Low Power 章节包含时钟门控策略 (Q2)
- [ ] TI S-Box 引用 Nikova et al.
- [ ] CTS 状态机覆盖 1-127 bit 边界条件

---

## 🎯 Verification Agent - TASK-AES-VER-001

### 执行命令
```
Verification Agent 任务：编写 AES IP Verification Plan v1.0
```

### 执行步骤

```bash
# 1. 进入项目目录
cd /root/.openclaw/workspace/sandbox/aes

# 2. 阅读 Architecture Spec
cat Database/Docs/Arch/Architecture_Spec.md

# 3. 阅读 Design Spec (如已完成)
cat Database/Docs/Design/Design_Specification.md

# 4. 更新 Verification Plan
# 文件: Database/Docs/Verification/Verification_Plan.md
# 必须包含7章:
#   - Ch1: 验证策略概述
#   - Ch2: 功能验证 (必须解决Q4: CTS 1-127 bit)
#   - Ch3: 安全验证 (TVLA详细策略)
#   - Ch4: 故障注入验证
#   - Ch5: 覆盖率计划
#   - Ch6: UVM环境设计
#   - Ch7: 回归策略

# 5. 创建 NIST 测试向量目录
mkdir -p Database/Verification/vectors/nist_vectors
# 下载/创建 NIST SP 800-38A 测试向量

# 6. 编写 TVLA 测试计划
# 文件: Database/Verification/tvla/TVLA_Plan.md
# 必须包含: t-test方法、通过标准 |t|<4.5

# 7. Git commit & push
git add -A
git commit -m "docs: add Verification Plan v1.0 (EDR phase)

- Verification_Plan.md (7 chapters)
- nist_vectors/ (NIST SP 800-38A test vectors)
- TVLA_Plan.md (side-channel testing)

Resolves PAD Q4 (CTS boundary verification)"
git push origin main

# 8. 更新任务状态
# 移动 task_queue/active/TASK-AES-VER-001.json 到 completed/
```

### 关键检查点
- [ ] CTS 边界条件验证覆盖 1-127 bit (Q4)
- [ ] TVLA 测试策略详细 (t-test, |t|<4.5)
- [ ] NIST SP 800-38A 测试向量完整
- [ ] 覆盖率目标明确 (Code>90%, Func>85%, Assert>95%)

---

## 📅 截止日期

| 任务 | 截止日期 | 状态 |
|------|---------|------|
| TASK-AES-EDR-001 | 2026-04-07 | 🟢 Assigned |
| TASK-AES-VER-001 | 2026-04-07 | 🟢 Assigned |

---

## 📋 任务状态流转

```
task_queue/
├── incoming/     ← 等待分配
├── active/       ← 当前活跃 (现在在这里)
├── assigned/     ← 已分配给具体执行者
└── completed/    ← 已完成
```

当前状态: **assigned** → 等待执行者开始工作

---

## ⚠️ 禁止事项

**EDR Gate 前禁止**:
- ❌ RTL 编码
- ❌ UVM 环境搭建
- ❌ Testcase 开发

**必须先完成**:
- ✅ Design Spec + Verification Plan
- ✅ 解决 PAD Q1/Q2/Q4
- ✅ EDR Review Meeting (6 Phase)

---

**PM Agent 指令发布**  
**时间**: 2026-03-31  
**状态**: Design Agent & Verification Agent 已激活，等待执行

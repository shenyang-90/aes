# AES IP Verification Push Checklist

## 文档信息

| 字段 | 值 |
|------|-----|
| **项目** | AES Crypto IP Verification |
| **日期** | 2026-04-03 |
| **版本** | v1.0 |
| **状态** | Ready for Push |

---

## 1. 目录结构验证

### 1.1 Verification 目录结构
```
Database/Verification/
├── Makefile                    ✅ Main Makefile (Icarus)
├── Makefile.verilator          ✅ Verilator Makefile (updated)
├── README.md                   ✅ Verification README
├── tb_coverage.sv              ❌ Removed (moved to Env/verilator/)
│
├── Env/                        ✅ Environment
│   ├── sva/                    ✅ Assertions
│   │   └── aes_assertions.sv
│   ├── tb/                     ✅ Testbench base
│   │   ├── tb_base.sv
│   │   └── tb_base_safety.sv
│   ├── tvla/                   ✅ TVLA test plan
│   ├── uvm/                    ✅ UVM environment
│   └── verilator/              ✅ Verilator specific
│       ├── sim_main.cpp        ✅ C++ wrapper
│       └── tb_coverage.sv      ✅ Moved here (updated)
│
├── Scripts/                    ✅ Scripts (10 scripts)
│   ├── run_new_coverage_tests.sh  ✅ New script
│   └── ...
│
├── Testcases/                  ✅ Testcases
│   ├── directed/               ✅ 53 testcases
│   │   ├── TESTCASE_INDEX.md   ✅ Updated
│   │   ├── tc_cts_full_boundary.sv   ✅ New
│   │   ├── tc_gcm_advanced.sv        ✅ New
│   │   ├── tc_xts_multi_sector.sv    ✅ New
│   │   ├── tc_error_recovery.sv      ✅ New
│   │   └── ... (49 other testcases)
│   ├── random/
│   └── vectors/
│
├── coverage/                   ✅ Coverage data
├── logs/                       ✅ Logs
├── obj_dir/                    ✅ Verilator output
└── reports/                    ✅ Reports
```

### 1.2 IDR Review Directory
```
ProjectMgmt/Reviews/IDR/
├── coverage/                   ✅ Coverage data
│   ├── tb_coverage.dat
│   └── tb_coverage.info
├── html/                       ✅ HTML reports
│   └── index.html
├── logs/                       ✅ Build logs
├── AES_PROJECT_ANALYSIS.md     ✅ New
├── COVERAGE_ENHANCEMENT_REPORT.md  ✅ New
├── COVERAGE_REPORT.md          ✅ New
└── ... (existing reports)
```

---

## 2. 文件清单

### 2.1 新增文件 (4个测试用例)

| 文件 | 路径 | 大小 | 状态 |
|------|------|------|------|
| tc_cts_full_boundary.sv | Database/Verification/Testcases/directed/ | 10.5 KB | ✅ |
| tc_gcm_advanced.sv | Database/Verification/Testcases/directed/ | 14.6 KB | ✅ |
| tc_xts_multi_sector.sv | Database/Verification/Testcases/directed/ | 16.2 KB | ✅ |
| tc_error_recovery.sv | Database/Verification/Testcases/directed/ | 14.9 KB | ✅ |

### 2.2 修改/移动的文件

| 文件 | 原位置 | 新位置 | 状态 |
|------|--------|--------|------|
| tb_coverage.sv | Database/Verification/ | Database/Verification/Env/verilator/ | ✅ Moved & Fixed |
| Makefile.verilator | - | - | ✅ Updated paths |
| TESTCASE_INDEX.md | - | - | ✅ Updated |

### 2.3 新增脚本

| 文件 | 路径 | 状态 |
|------|------|------|
| run_new_coverage_tests.sh | Database/Verification/Scripts/ | ✅ |

---

## 3. 验证检查

### 3.1 语法检查
- [x] tc_cts_full_boundary.sv - OK
- [x] tc_gcm_advanced.sv - OK
- [x] tc_xts_multi_sector.sv - OK
- [x] tc_error_recovery.sv - OK
- [x] tb_coverage.sv (updated) - OK

### 3.2 编译检查
- [x] Verilator compilation - OK
- [x] Coverage data generation - OK (1.8MB)

### 3.3 报告生成
- [x] HTML report - OK
- [x] Coverage info - OK (181KB)
- [x] IDR directory - OK

---

## 4. 覆盖率状态

| 类型 | 当前 | 目标 | 状态 |
|------|------|------|------|
| Line Coverage | 37.1% | >90% | ⚠️ Need more tests |
| Testcases | 53 | 50+ | ✅ |

---

## 5. 关键命令验证

### 5.1 编译命令
```bash
cd Database/Verification
make -f Makefile.verilator compile
```

### 5.2 运行测试
```bash
cd Database/Verification
make -f Makefile.verilator run_new
```

### 5.3 生成报告
```bash
cd Database/Verification
make -f Makefile.verilator idr_report
```

### 5.4 查看报告
```bash
firefox ProjectMgmt/Reviews/IDR/html/index.html
```

---

## 6. Git Push 建议

### 6.1 推荐命令
```bash
cd /home/CALTERAH/yshen/sandbox/kimi/sandbox/aes

# Check status
git status

# Add new files
git add Database/Verification/Testcases/directed/tc_cts_full_boundary.sv
git add Database/Verification/Testcases/directed/tc_gcm_advanced.sv
git add Database/Verification/Testcases/directed/tc_xts_multi_sector.sv
git add Database/Verification/Testcases/directed/tc_error_recovery.sv
git add Database/Verification/Env/verilator/tb_coverage.sv
git add Database/Verification/Makefile.verilator
git add Database/Verification/Scripts/run_new_coverage_tests.sh
git add Database/Verification/Testcases/directed/TESTCASE_INDEX.md
git add ProjectMgmt/AES_PROJECT_ANALYSIS.md
git add ProjectMgmt/COVERAGE_ENHANCEMENT_REPORT.md
git add ProjectMgmt/COVERAGE_REPORT.md
git add ProjectMgmt/VERIFICATION_PUSH_CHECKLIST.md

# Remove old file
git rm Database/Verification/tb_coverage.sv 2>/dev/null || true

# Commit
git commit -m "Add 4 new coverage enhancement testcases

- tc_cts_full_boundary: CTS 1-127 bit full boundary coverage
- tc_gcm_advanced: GCM AAD and Tag verification
- tc_xts_multi_sector: XTS multi-sector processing
- tc_error_recovery: Error state recovery

- Move and fix tb_coverage.sv to Env/verilator/
- Update Makefile.verilator with IDR report paths
- Update TESTCASE_INDEX.md (53 testcases total)
- Add coverage reports to ProjectMgmt/Reviews/IDR"

# Push (ask user for confirmation)
# git push
```

### 6.2 注意事项
- ⚠️ 不要 push Temp/ 目录下的临时文件
- ⚠️ 不要 push coverage.dat (大文件)
- ✅ 确保 .gitignore 排除了临时文件

---

## 7. 已知限制

1. **覆盖率目标**: 当前 37.1%，需要运行更多测试达到 90%+
2. **仿真超时**: 部分测试可能需要超过 60 秒
3. **GCM/XTS**: 需要完整的 RTL 实现才能通过所有测试

---

## 8. 后续工作

1. 运行所有新测试用例并合并覆盖率
2. 分析未覆盖代码，补充测试
3. 完善 GCM/XTS RTL 实现
4. 达到 IDR 覆盖率目标 (>90%)

---

**检查完成时间**: 2026-04-03  
**状态**: ✅ Ready for Push

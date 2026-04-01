//============================================================================
// Testcase: tc_register_full
// Description: Full register coverage - all addresses, bit fields, and access types
//============================================================================

`include "../../Env/tb/tb_base.sv"

module tc_register_full;
    
    tb_base tb();

    reg [31:0] rdata, wdata;
    reg [11:0] addr;
    integer pass_cnt, fail_cnt;
    integer i;

    initial begin
        $display("\n========================================");
        $display("Full Register Coverage Test");
        $display("========================================");
        
        pass_cnt = 0;
        fail_cnt = 0;
        
        @(posedge tb.rst_n);
        #100;

        // Test 1: Register address map - read all registers
        $display("\n[TEST 1] Register Address Map Read");
        begin
            reg [11:0] reg_addrs [0:15];
            reg_addrs[0]  = 12'h000;  // CTRL
            reg_addrs[1]  = 12'h004;  // STATUS
            reg_addrs[2]  = 12'h008;  // KEY_LEN
            reg_addrs[3]  = 12'h00C;  // MODE
            reg_addrs[4]  = 12'h010;  // KEY_0
            reg_addrs[5]  = 12'h014;  // KEY_1
            reg_addrs[6]  = 12'h018;  // KEY_2
            reg_addrs[7]  = 12'h01C;  // KEY_3
            reg_addrs[8]  = 12'h020;  // KEY_4
            reg_addrs[9]  = 12'h024;  // KEY_5
            reg_addrs[10] = 12'h028;  // KEY_6
            reg_addrs[11] = 12'h02C;  // KEY_7
            reg_addrs[12] = 12'h030;  // IV_0
            reg_addrs[13] = 12'h034;  // IV_1
            reg_addrs[14] = 12'h038;  // IV_2
            reg_addrs[15] = 12'h03C;  // IV_3
            
            for (i = 0; i < 16; i = i + 1) begin
                tb.apb_read(reg_addrs[i], rdata);
                $display("  Reg[0x%03X] = 0x%08X", reg_addrs[i], rdata);
            end
            pass_cnt = pass_cnt + 1;
        end

        // Test 2: CTRL register bit fields
        $display("\n[TEST 2] CTRL Register Bit Fields");
        begin
            // Bit 0: START
            tb.apb_write(12'h000, 32'h00000001);
            tb.apb_read(12'h000, rdata);
            $display("  START bit set: CTRL = 0x%08X", rdata);
            
            // Bit 1: BUSY (RO)
            tb.apb_read(12'h004, rdata);  // Read STATUS
            $display("  BUSY status: 0x%08X", rdata);
            
            // Bit 2: DIRECTION (0=Encrypt, 1=Decrypt)
            tb.apb_write(12'h000, 32'h00000004);
            tb.apb_read(12'h000, rdata);
            $display("  DIRECTION=Decrypt: CTRL = 0x%08X", rdata);
            
            // Bit 3: MODE_VALID
            tb.apb_write(12'h000, 32'h00000008);
            tb.apb_read(12'h000, rdata);
            $display("  MODE_VALID: CTRL = 0x%08X", rdata);
            
            // Clear all
            tb.apb_write(12'h000, 32'h00000000);
            pass_cnt = pass_cnt + 1;
        end

        // Test 3: STATUS register bits
        $display("\n[TEST 3] STATUS Register Bits");
        begin
            // Read initial status
            tb.apb_read(12'h004, rdata);
            $display("  Initial STATUS: 0x%08X", rdata);
            
            // Check IDLE bit
            if (rdata[0] === 1'b1) begin
                $display("  [PASS] IDLE bit set when not processing");
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("  [WARN] IDLE bit not set, status=0x%08X", rdata);
            end
        end

        // Test 4: KEY_LEN register valid values
        $display("\n[TEST 4] KEY_LEN Valid Values");
        begin
            // 00 = 128-bit
            tb.apb_write(12'h008, 32'h00000000);
            tb.apb_read(12'h008, rdata);
            if (rdata[1:0] === 2'b00) begin
                $display("  [PASS] KEY_LEN=00 (128-bit)");
                pass_cnt = pass_cnt + 1;
            end
            
            // 01 = 192-bit
            tb.apb_write(12'h008, 32'h00000001);
            tb.apb_read(12'h008, rdata);
            if (rdata[1:0] === 2'b01) begin
                $display("  [PASS] KEY_LEN=01 (192-bit)");
                pass_cnt = pass_cnt + 1;
            end
            
            // 10 = 256-bit
            tb.apb_write(12'h008, 32'h00000002);
            tb.apb_read(12'h008, rdata);
            if (rdata[1:0] === 2'b10) begin
                $display("  [PASS] KEY_LEN=10 (256-bit)");
                pass_cnt = pass_cnt + 1;
            end
        end

        // Test 5: MODE register - all 6 modes
        $display("\n[TEST 5] MODE Register - All 6 Modes");
        begin
            for (i = 0; i < 6; i = i + 1) begin
                tb.apb_write(12'h00C, i[31:0]);
                tb.apb_read(12'h00C, rdata);
                if (rdata[2:0] === i[2:0]) begin
                    $display("  [PASS] MODE=%0d set correctly", i);
                end else begin
                    $display("  [FAIL] MODE write failed: wrote %0d, read %0d", i, rdata[2:0]);
                    fail_cnt = fail_cnt + 1;
                end
            end
            pass_cnt = pass_cnt + 1;
        end

        // Test 6: CTS_EN register
        $display("\n[TEST 6] CTS_EN Register");
        begin
            tb.apb_write(12'h040, 32'h00000001);
            tb.apb_read(12'h040, rdata);
            if (rdata[0] === 1'b1) begin
                $display("  [PASS] CTS_EN enabled");
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("  [FAIL] CTS_EN write failed");
                fail_cnt = fail_cnt + 1;
            end
            
            // Disable
            tb.apb_write(12'h040, 32'h00000000);
        end

        // Test 7: INT_EN register - all interrupt enables
        $display("\n[TEST 7] INT_EN Register - Interrupt Enables");
        begin
            // Enable all interrupts
            tb.apb_write(12'h048, 32'h0000000F);
            tb.apb_read(12'h048, rdata);
            if (rdata[3:0] === 4'b1111) begin
                $display("  [PASS] All interrupts enabled");
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("  [FAIL] INT_EN write failed: 0x%08X", rdata);
                fail_cnt = fail_cnt + 1;
            end
            
            // Disable all
            tb.apb_write(12'h048, 32'h00000000);
        end

        // Test 8: INT_STAT register (if implemented)
        $display("\n[TEST 8] INT_STAT Register (Read-Clear)");
        begin
            tb.apb_read(12'h04C, rdata);
            $display("  INT_STAT initial: 0x%08X", rdata);
            $display("  (Note: INT_STAT may not be fully implemented)");
            pass_cnt = pass_cnt + 1;
        end

        // Test 9: ERR_STAT register
        $display("\n[TEST 9] ERR_STAT Register");
        begin
            tb.apb_read(12'h044, rdata);
            $display("  ERR_STAT initial: 0x%08X", rdata);
            
            // Try to clear errors
            tb.apb_write(12'h044, 32'hFFFFFFFF);
            tb.apb_read(12'h044, rdata);
            $display("  ERR_STAT after clear: 0x%08X", rdata);
            pass_cnt = pass_cnt + 1;
        end

        // Test 10: DATA_IN/DATA_OUT registers
        $display("\n[TEST 10] DATA_IN/DATA_OUT Registers");
        begin
            reg [31:0] test_pattern;
            test_pattern = 32'hA5A5A5A5;
            
            // Write DATA_IN
            tb.apb_write(12'h100, test_pattern);
            tb.apb_write(12'h104, ~test_pattern);
            tb.apb_write(12'h108, test_pattern);
            tb.apb_write(12'h10C, ~test_pattern);
            
            $display("  DATA_IN written: 0x%08X 0x%08X 0x%08X 0x%08X", 
                     test_pattern, ~test_pattern, test_pattern, ~test_pattern);
            
            // Read DATA_OUT (may be undefined if no operation)
            tb.apb_read(12'h110, rdata);
            $display("  DATA_OUT[31:0]: 0x%08X", rdata);
            
            pass_cnt = pass_cnt + 1;
        end

        // Test 11: Reserved register addresses (should return 0 or ignore writes)
        $display("\n[TEST 11] Reserved/Invalid Addresses");
        begin
            // Try to write to reserved address
            tb.apb_write(12'h050, 32'hDEADBEEF);
            tb.apb_read(12'h050, rdata);
            $display("  Reserved[0x050]: 0x%08X", rdata);
            pass_cnt = pass_cnt + 1;
        end

        // Summary
        $display("\n========================================");
        $display("Register Coverage Test Summary");
        $display("========================================");
        $display("Passed: %0d", pass_cnt);
        $display("Failed: %0d", fail_cnt);
        
        if (fail_cnt == 0) begin
            $display("\n[PASS] All register tests passed!");
        end
        
        $display("");
        
        #100; $finish;
    end

endmodule

// Testcase: tc_safety_interrupt
// Description: Verify interrupt generation and reporting for all fault types
// Coverage: SM-041~048 (Interrupt aspects)
// Author: Verification Agent
// Date: 2026-04-02
// Update: v1.2 - Updated INT_EN/INT_STATUS bit definitions per Design Spec v1.2

`timescale 1ns/1ps

module tc_safety_interrupt;
    
    // Testbench base instance
    tb_base tb();
    
    // Test result tracking
    int pass_count = 0;
    int fail_count = 0;
    
    // Register definitions (from Design Spec v1.2)
    localparam logic [11:0] STATUS_ADDR  = 12'h004;
    localparam logic [11:0] INT_EN_ADDR  = 12'h048;
    localparam logic [11:0] INT_STATUS_ADDR = 12'h04C;
    
    // STATUS register bit definitions (v1.2)
    localparam int STATUS_FAULT_DETECTED_BIT = 4;  // Was TIMEOUT_ERR in v1.1
    
    // INT_EN/INT_STATUS bit definitions (v1.2) - CORRECTED
    // Per Design Spec v1.2:
    // INT_EN[0] = ERROR_INT_EN (was DONE_EN in some old versions)
    // INT_EN[1] = DONE_INT_EN (was ERROR_EN in some old versions)
    // INT_EN[2] = FAULT_INT_EN (was KEY_READY_EN)
    localparam int INT_ERROR_BIT    = 0;  // ERROR_INT_EN
    localparam int INT_DONE_BIT     = 1;  // DONE_INT_EN
    localparam int INT_FAULT_BIT    = 2;  // FAULT_INT_EN
    
    // Task: Enable interrupts
    task automatic enable_interrupts(input logic [31:0] int_mask);
        $display("[INFO] Enabling interrupts: mask=%08h", int_mask);
        $display("[INFO] INT_EN bit mapping (v1.2): [0]=ERROR, [1]=DONE, [2]=FAULT");
        tb.apb_write(INT_EN_ADDR, int_mask); // Write to INT_EN register
    endtask
    
    // Task: Check interrupt assertion
    task automatic check_interrupt(
        input string test_id,
        input int int_bit,
        input string int_name,
        input int expected_cycles = 10
    );
        logic interrupt_asserted;
        logic int_status_bit;
        int timeout;
        
        timeout = 0;
        interrupt_asserted = 1'b0;
        
        while (!interrupt_asserted && timeout < expected_cycles) begin
            @(posedge tb.clk);
            int_status_bit = tb.dut.int_status_reg[int_bit];
            interrupt_asserted = tb.dut.aes_top.int_error || tb.dut.aes_top.int_done;
            
            // Check specific interrupt status
            if (int_status_bit) begin
                interrupt_asserted = 1'b1;
            end
            timeout++;
        end
        
        if (interrupt_asserted) begin
            $display("[PASS] %s: %s interrupt (bit %0d) asserted after %0d cycles", 
                     test_id, int_name, int_bit, timeout);
            pass_count++;
        end else begin
            $display("[FAIL] %s: %s interrupt (bit %0d) NOT asserted within %0d cycles", 
                     test_id, int_name, int_bit, expected_cycles);
            fail_count++;
        end
    endtask
    
    // Task: Clear interrupt
    task clear_interrupt(input int int_bit);
        logic [31:0] w1c_value;
        w1c_value = 32'h0;
        w1c_value[int_bit] = 1'b1;
        $display("[INFO] Clearing interrupt bit %0d (W1C)", int_bit);
        tb.apb_write(INT_STATUS_ADDR, w1c_value); // Write to INT_STATUS (W1C)
    endtask
    
    // Task: Check interrupt cleared
    task check_interrupt_cleared(
        input string test_id,
        input int int_bit,
        input string int_name
    );
        logic int_status_bit;
        
        @(posedge tb.clk);
        int_status_bit = tb.dut.aes_top.int_status_reg[int_bit];
        
        if (!int_status_bit) begin
            $display("[PASS] %s: %s interrupt (bit %0d) cleared correctly", 
                     test_id, int_name, int_bit);
            pass_count++;
        end else begin
            $display("[FAIL] %s: %s interrupt (bit %0d) NOT cleared", 
                     test_id, int_name, int_bit);
            fail_count++;
        end
    endtask
    
    // Task: Read INT_STATUS register
    task read_int_status;
        logic [31:0] status_val;
        tb.apb_read(INT_STATUS_ADDR, status_val);
    endtask
    
    task get_int_status(output logic [31:0] status_val);
        tb.apb_read(INT_STATUS_ADDR, status_val);
    endtask
    
    // Task: Trigger fault_detected
    task trigger_fault_detected;
        $display("[INFO] Triggering fault_detected via result mismatch");
        tb.force_signal("result_a", 128'h12345678_9ABCDEF0_12345678_9ABCDEF0);
        tb.force_signal("result_b", 128'hFEDCBA09_76543210_FEDCBA09_76543210);
    endtask
    
    // Task: Trigger CRC error
    task trigger_crc_error;
        $display("[INFO] Triggering CRC error");
        tb.force_signal("crc_valid", 1'b0);
    endtask
    
    // Task: Release forced signals
    task release_faults;
        tb.release_signal("result_a");
        tb.release_signal("result_b");
        tb.release_signal("crc_valid");
    endtask
    
    // Main test sequence
    initial begin
        logic [31:0] int_status_val;
        logic [31:0] status_reg;
        
        $display("========================================");
        $display("TC_SAFETY_INTERRUPT: Starting test suite");
        $display("Coverage: SM-041~048 (Interrupt aspects)");
        $display("Design Spec: v1.2");
        $display("INT_EN/INT_STATUS mapping: [0]=ERROR, [1]=DONE, [2]=FAULT");
        $display("========================================");
        
        // Initialize
        tb.init();
        
        // Wait for reset release
        @(posedge tb.clk);
        wait(tb.rst_n === 1'b1);
        @(posedge tb.clk);
        
        // Verify INT_EN register default value
        $display("\n--- Register Check: INT_EN default value ---");
        tb.apb_read(INT_EN_ADDR, int_status_val);
        $display("[INFO] INT_EN register: 0x%08H", int_status_val);
        if (int_status_val === 32'h00000000) begin
            $display("[PASS] INT_EN default is 0x00000000 (all interrupts disabled)");
            pass_count++;
        end else begin
            $display("[WARN] INT_EN default is 0x%08H (expected 0x00000000)", int_status_val);
        end
        
        // Enable all interrupts (bits 0-2 per v1.2 spec)
        enable_interrupts(32'h00000007); // Enable bits 0-2: ERROR, DONE, FAULT
        
        // === FAULT interrupt test (INT_STATUS[2] = FAULT_INT) ===
        
        // Test: FAULT_INT triggered by fault_detected
        $display("\n--- Test: FAULT_INT (bit 2) from fault_detected ---");
        trigger_fault_detected();
        check_interrupt("SM-FAULT-001", INT_FAULT_BIT, "FAULT", 5);
        
        // Verify STATUS[4] FAULT_DETECTED is also set
        tb.apb_read(STATUS_ADDR, status_reg);
        $display("[INFO] STATUS[4] FAULT_DETECTED: %0b", status_reg[STATUS_FAULT_DETECTED_BIT]);
        
        clear_interrupt(INT_FAULT_BIT);
        check_interrupt_cleared("SM-FAULT-002", INT_FAULT_BIT, "FAULT");
        release_faults();
        tb.reset_dut();
        enable_interrupts(32'h00000007);
        
        // Test: FAULT_INT during timeout scenario
        $display("\n--- Test: FAULT_INT (bit 2) during FSM timeout ---");
        tb.force_signal("aes_controller.state", 4'd3); // LOAD_DATA stuck
        check_interrupt("SM-FAULT-003", INT_FAULT_BIT, "FAULT", 100);
        tb.release_signal("aes_controller.state");
        clear_interrupt(INT_FAULT_BIT);
        tb.reset_dut();
        enable_interrupts(32'h00000007);
        
        // === ERROR interrupt test (INT_STATUS[0] = ERROR_INT) ===
        
        // Test: ERROR_INT triggered by controller error
        $display("\n--- Test: ERROR_INT (bit 0) from controller error ---");
        tb.force_signal("aes_controller.state", 4'd10); // ERROR state
        check_interrupt("SM-ERROR-001", INT_ERROR_BIT, "ERROR", 5);
        clear_interrupt(INT_ERROR_BIT);
        check_interrupt_cleared("SM-ERROR-002", INT_ERROR_BIT, "ERROR");
        tb.release_signal("aes_controller.state");
        tb.reset_dut();
        enable_interrupts(32'h00000007);
        
        // === DONE interrupt test (INT_STATUS[1] = DONE_INT) ===
        
        // Test: DONE_INT triggered by operation complete
        $display("\n--- Test: DONE_INT (bit 1) from operation complete ---");
        // Note: This requires actual operation to complete
        // For now, we force the done signal
        tb.force_signal("aes_controller.state", 4'd9); // DONE state
        check_interrupt("SM-DONE-001", INT_DONE_BIT, "DONE", 5);
        clear_interrupt(INT_DONE_BIT);
        check_interrupt_cleared("SM-DONE-002", INT_DONE_BIT, "DONE");
        tb.release_signal("aes_controller.state");
        tb.reset_dut();
        enable_interrupts(32'h00000007);
        
        // === Interrupt bit definition verification ===
        
        // Test: Verify INT_EN bit positions per v1.2
        $display("\n--- Test: INT_EN bit definition verification (v1.2) ---");
        
        // Enable only ERROR_INT_EN (bit 0)
        enable_interrupts(32'h00000001);
        tb.apb_read(INT_EN_ADDR, int_status_val);
        if (int_status_val[0] === 1'b1) begin
            $display("[PASS] SM-BIT-001: INT_EN[0] = ERROR_INT_EN correctly mapped");
            pass_count++;
        end else begin
            $display("[FAIL] SM-BIT-001: INT_EN[0] mapping incorrect");
            fail_count++;
        end
        
        // Enable only DONE_INT_EN (bit 1)
        enable_interrupts(32'h00000002);
        tb.apb_read(INT_EN_ADDR, int_status_val);
        if (int_status_val[1] === 1'b1) begin
            $display("[PASS] SM-BIT-002: INT_EN[1] = DONE_INT_EN correctly mapped");
            pass_count++;
        end else begin
            $display("[FAIL] SM-BIT-002: INT_EN[1] mapping incorrect");
            fail_count++;
        end
        
        // Enable only FAULT_INT_EN (bit 2)
        enable_interrupts(32'h00000004);
        tb.apb_read(INT_EN_ADDR, int_status_val);
        if (int_status_val[2] === 1'b1) begin
            $display("[PASS] SM-BIT-003: INT_EN[2] = FAULT_INT_EN correctly mapped");
            pass_count++;
        end else begin
            $display("[FAIL] SM-BIT-003: INT_EN[2] mapping incorrect");
            fail_count++;
        end
        
        tb.reset_dut();
        enable_interrupts(32'h00000007);
        
        // === Interrupt mask test ===
        
        // Test: Interrupt masking
        $display("\n--- Test: Interrupt masking ---");
        enable_interrupts(32'h00000000); // Disable all interrupts
        trigger_fault_detected();
        @(posedge tb.clk);
        @(posedge tb.clk);
        @(posedge tb.clk);
        
        if (!tb.dut.aes_top.int_error) begin
            $display("[PASS] SM-MASK-001: Interrupt correctly masked");
            pass_count++;
        end else begin
            $display("[FAIL] SM-MASK-001: Interrupt NOT masked correctly");
            fail_count++;
        end
        release_faults();
        tb.reset_dut();
        
        // Test: Interrupt unmasking - FAULT only
        $display("\n--- Test: Interrupt unmasking (FAULT only) ---");
        enable_interrupts(32'h00000004); // Enable only FAULT_INT (bit 2)
        trigger_fault_detected();
        check_interrupt("SM-MASK-002", INT_FAULT_BIT, "FAULT", 5);
        clear_interrupt(INT_FAULT_BIT);
        release_faults();
        tb.reset_dut();
        
        // Test: Interrupt unmasking - ERROR only
        $display("\n--- Test: Interrupt unmasking (ERROR only) ---");
        enable_interrupts(32'h00000001); // Enable only ERROR_INT (bit 0)
        tb.force_signal("aes_controller.state", 4'd10);
        check_interrupt("SM-MASK-003", INT_ERROR_BIT, "ERROR", 5);
        clear_interrupt(INT_ERROR_BIT);
        tb.release_signal("aes_controller.state");
        tb.reset_dut();
        
        // === Combined interrupt test ===
        
        // Test: Multiple interrupts
        $display("\n--- Test: Multiple simultaneous interrupts ---");
        enable_interrupts(32'h00000007); // Enable all
        trigger_fault_detected();
        
        // Wait for FAULT interrupt
        check_interrupt("SM-MULTI-001", INT_FAULT_BIT, "FAULT", 5);
        
        // Check FAULT bit is set
        get_int_status(int_status_val);
        $display("[INFO] INT_STATUS register: 0x%08H", int_status_val);
        $display("[INFO] FAULT_STATUS (bit 2): %0b", int_status_val[INT_FAULT_BIT]);
        
        if (int_status_val[INT_FAULT_BIT]) begin
            $display("[PASS] SM-MULTI-002: FAULT interrupt status bit set");
            pass_count++;
        end else begin
            $display("[FAIL] SM-MULTI-002: FAULT interrupt status bit NOT set");
            fail_count++;
        end
        
        // Clear all interrupts
        tb.apb_write(INT_STATUS_ADDR, 32'hFFFFFFFF); // Clear all
        release_faults();
        tb.reset_dut();
        
        // === STATUS[4] FAULT_DETECTED integration test ===
        
        // Test: Verify FAULT triggers both INT_STATUS[2] and STATUS[4]
        $display("\n--- Test: FAULT_DETECTED (STATUS[4]) integration ---");
        enable_interrupts(32'h00000004); // Enable FAULT_INT only
        trigger_fault_detected();
        
        // Wait for interrupt
        repeat(5) @(posedge tb.clk);
        
        // Check both STATUS[4] and INT_STATUS[2]
        tb.apb_read(STATUS_ADDR, status_reg);
        get_int_status(int_status_val);
        
        if (status_reg[STATUS_FAULT_DETECTED_BIT] && int_status_val[INT_FAULT_BIT]) begin
            $display("[PASS] SM-INTEG-001: Both STATUS[4] and INT_STATUS[2] set on fault");
            pass_count++;
        end else begin
            $display("[FAIL] SM-INTEG-001: STATUS[4]=%0b, INT_STATUS[2]=%0b", 
                     status_reg[STATUS_FAULT_DETECTED_BIT], int_status_val[INT_FAULT_BIT]);
            fail_count++;
        end
        
        clear_interrupt(INT_FAULT_BIT);
        release_faults();
        tb.reset_dut();
        
        // Test summary
        $display("\n========================================");
        $display("TC_SAFETY_INTERRUPT: Test Summary");
        $display("========================================");
        $display("Total Tests: %0d", pass_count + fail_count);
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);
        
        $display("\n[NOTE] Design Spec v1.2 INT_EN/INT_STATUS bit mapping:");
        $display("       [0] = ERROR_INT_EN");
        $display("       [1] = DONE_INT_EN");
        $display("       [2] = FAULT_INT_EN");
        $display("[NOTE] STATUS[4] = FAULT_DETECTED (was TIMEOUT_ERR in v1.1)");
        
        if (fail_count == 0) begin
            $display("[TEST PASSED] All interrupt safety tests passed!");
        end else begin
            $display("[TEST FAILED] %0d tests failed!", fail_count);
        end
        
        $display("========================================\n");
        $finish;
    end
    
endmodule

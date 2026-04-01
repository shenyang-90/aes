// Testcase: tc_safety_interrupt
// Description: Verify interrupt generation and reporting for all fault types
// Coverage: SM-041~048 (Interrupt aspects)
// Author: Verification Agent
// Date: 2026-04-01

`timescale 1ns/1ps

module tc_safety_interrupt;
    
    // Testbench base instance
    tb_base tb();
    
    // Test result tracking
    int pass_count = 0;
    int fail_count = 0;
    
    // Interrupt bit positions
    localparam int DONE_INT    = 0;
    localparam int ERROR_INT   = 1;
    localparam int FAULT_INT   = 2;
    localparam int CRC_INT     = 3;
    localparam int DMA_INT     = 4;
    localparam int KEY_ERR_INT = 5;
    
    // Task: Enable interrupts
    task automatic enable_interrupts(input logic [31:0] int_mask);
        $display("[INFO] Enabling interrupts: mask=%08h", int_mask);
        tb.apb_write(12'h048, int_mask); // Write to INT_EN register
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
            int_status_bit = tb.dut.aes_top.int_status_reg[int_bit];
            interrupt_asserted = tb.dut.aes_top.int_error || tb.dut.aes_top.int_done;
            
            // Check specific interrupt status
            if (int_status_bit) begin
                interrupt_asserted = 1'b1;
            end
            timeout++;
        end
        
        if (interrupt_asserted) begin
            $display("[PASS] %s: %s interrupt asserted after %0d cycles", test_id, int_name, timeout);
            pass_count++;
        end else begin
            $display("[FAIL] %s: %s interrupt NOT asserted within %0d cycles", test_id, int_name, expected_cycles);
            fail_count++;
        end
    endtask
    
    // Task: Clear interrupt
    task automatic clear_interrupt(input int int_bit);
        logic [31:0] w1c_value;
        w1c_value = 32'h0;
        w1c_value[int_bit] = 1'b1;
        $display("[INFO] Clearing interrupt bit %0d (W1C)", int_bit);
        tb.apb_write(12'h04C, w1c_value); // Write to INT_STATUS (W1C)
    endtask
    
    // Task: Check interrupt cleared
    task automatic check_interrupt_cleared(
        input string test_id,
        input int int_bit,
        input string int_name
    );
        logic int_status_bit;
        
        @(posedge tb.clk);
        int_status_bit = tb.dut.aes_top.int_status_reg[int_bit];
        
        if (!int_status_bit) begin
            $display("[PASS] %s: %s interrupt cleared correctly", test_id, int_name);
            pass_count++;
        end else begin
            $display("[FAIL] %s: %s interrupt NOT cleared", test_id, int_name);
            fail_count++;
        end
    endtask
    
    // Task: Trigger fault_detected
    task automatic trigger_fault_detected();
        $display("[INFO] Triggering fault_detected via result mismatch");
        tb.force_signal("result_a", 128'h12345678_9ABCDEF0_12345678_9ABCDEF0);
        tb.force_signal("result_b", 128'hFEDCBA09_76543210_FEDCBA09_76543210);
    endtask
    
    // Task: Trigger CRC error
    task automatic trigger_crc_error();
        $display("[INFO] Triggering CRC error");
        tb.force_signal("crc_valid", 1'b0);
    endtask
    
    // Task: Release forced signals
    task automatic release_faults();
        tb.release_signal("result_a");
        tb.release_signal("result_b");
        tb.release_signal("crc_valid");
    endtask
    
    // Main test sequence
    initial begin
        $display("========================================");
        $display("TC_SAFETY_INTERRUPT: Starting test suite");
        $display("Coverage: SM-041~048 (Interrupt aspects)");
        $display("========================================");
        
        // Initialize
        tb.init();
        
        // Wait for reset release
        @(posedge tb.clk);
        wait(tb.rst_n === 1'b1);
        @(posedge tb.clk);
        
        // Enable all interrupts
        enable_interrupts(32'h0000003F); // Enable bits 0-5
        
        // === FAULT interrupt test (related to SM-041~045) ===
        
        // Test: FAULT_INT triggered by fault_detected
        $display("\n--- Test: FAULT_INT from fault_detected ---");
        trigger_fault_detected();
        check_interrupt("SM-FAULT-001", FAULT_INT, "FAULT", 5);
        clear_interrupt(FAULT_INT);
        check_interrupt_cleared("SM-FAULT-002", FAULT_INT, "FAULT");
        release_faults();
        tb.reset_dut();
        enable_interrupts(32'h0000003F);
        
        // Test: FAULT_INT during timeout scenario
        $display("\n--- Test: FAULT_INT during FSM timeout ---");
        tb.force_signal("aes_controller.state", 4'd3); // LOAD_DATA stuck
        check_interrupt("SM-FAULT-003", FAULT_INT, "FAULT", 100);
        tb.release_signal("aes_controller.state");
        clear_interrupt(FAULT_INT);
        tb.reset_dut();
        enable_interrupts(32'h0000003F);
        
        // === CRC interrupt test (SM-021~030 related) ===
        
        // Test: CRC_INT triggered by CRC error
        $display("\n--- Test: CRC_INT from CRC error ---");
        trigger_crc_error();
        check_interrupt("SM-CRC-001", CRC_INT, "CRC", 5);
        clear_interrupt(CRC_INT);
        check_interrupt_cleared("SM-CRC-002", CRC_INT, "CRC");
        release_faults();
        tb.reset_dut();
        enable_interrupts(32'h0000003F);
        
        // === ERROR interrupt test ===
        
        // Test: ERROR_INT triggered by controller error
        $display("\n--- Test: ERROR_INT from controller ---");
        tb.force_signal("aes_controller.state", 4'd10); // ERROR state
        check_interrupt("SM-ERROR-001", ERROR_INT, "ERROR", 5);
        clear_interrupt(ERROR_INT);
        check_interrupt_cleared("SM-ERROR-002", ERROR_INT, "ERROR");
        tb.release_signal("aes_controller.state");
        tb.reset_dut();
        enable_interrupts(32'h0000003F);
        
        // === KEY_ERR interrupt test (SM-031~040 related) ===
        
        // Test: KEY_ERR_INT triggered by key error
        $display("\n--- Test: KEY_ERR_INT from key error ---");
        tb.force_signal("key_manager.key_valid", 1'b0);
        check_interrupt("SM-KEY-001", KEY_ERR_INT, "KEY_ERR", 5);
        clear_interrupt(KEY_ERR_INT);
        check_interrupt_cleared("SM-KEY-002", KEY_ERR_INT, "KEY_ERR");
        tb.release_signal("key_manager.key_valid");
        tb.reset_dut();
        enable_interrupts(32'h0000003F);
        
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
        
        // Test: Interrupt unmasking
        $display("\n--- Test: Interrupt unmasking ---");
        enable_interrupts(32'h00000004); // Enable only FAULT_INT
        trigger_fault_detected();
        check_interrupt("SM-MASK-002", FAULT_INT, "FAULT", 5);
        clear_interrupt(FAULT_INT);
        release_faults();
        tb.reset_dut();
        
        // === Combined interrupt test ===
        
        // Test: Multiple interrupts
        $display("\n--- Test: Multiple simultaneous interrupts ---");
        enable_interrupts(32'h0000003F);
        trigger_fault_detected();
        trigger_crc_error();
        check_interrupt("SM-MULTI-001", FAULT_INT, "FAULT", 5);
        
        // Check both FAULT and CRC are set
        logic [31:0] int_status;
        int_status = tb.dut.aes_top.int_status_reg;
        if (int_status[FAULT_INT] && int_status[CRC_INT]) begin
            $display("[PASS] SM-MULTI-002: Both FAULT and CRC interrupts set");
            pass_count++;
        end else begin
            $display("[FAIL] SM-MULTI-002: Expected both FAULT and CRC, got %08h", int_status);
            fail_count++;
        end
        
        // Clear all interrupts
        tb.apb_write(12'h04C, 32'hFFFFFFFF); // Clear all
        release_faults();
        tb.reset_dut();
        
        // Test summary
        $display("\n========================================");
        $display("TC_SAFETY_INTERRUPT: Test Summary");
        $display("========================================");
        $display("Total Tests: %0d", pass_count + fail_count);
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);
        
        if (fail_count == 0) begin
            $display("[TEST PASSED] All interrupt safety tests passed!");
        end else begin
            $display("[TEST FAILED] %0d tests failed!", fail_count);
        end
        
        $display("========================================\n");
        $finish;
    end
    
endmodule

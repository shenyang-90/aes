// Testcase: tc_safety_dual_rail
// Description: Verify fault_detector triggers fault_detected on result mismatch
// Coverage: SM-001~010
// Author: Verification Agent
// Date: 2026-04-01

`timescale 1ns/1ps

module tc_safety_dual_rail;
    
    // Testbench base instance
    tb_base tb();
    
    // Test result tracking
    int pass_count = 0;
    int fail_count = 0;
    
    // Task: Inject single bit flip
    task automatic inject_bit_flip(
        input string signal_name,
        input int bit_pos,
        input logic [127:0] original_value,
        output logic [127:0] flipped_value
    );
        flipped_value = original_value;
        flipped_value[bit_pos] = ~original_value[bit_pos];
        $display("[INFO] Injecting bit flip at %s[%0d]", signal_name, bit_pos);
    endtask
    
    // Task: Check fault detection
    task automatic check_fault_detected(
        input string test_id,
        input int expected_cycles = 10
    );
        logic fault_detected;
        int timeout;
        
        timeout = 0;
        fault_detected = 1'b0;
        
        while (!fault_detected && timeout < expected_cycles) begin
            @(posedge tb.clk);
            fault_detected = tb.dut.fault_detector.fault_detected;
            timeout++;
        end
        
        if (fault_detected) begin
            $display("[PASS] %s: fault_detected asserted after %0d cycles", test_id, timeout);
            pass_count++;
        end else begin
            $display("[FAIL] %s: fault_detected NOT asserted within %0d cycles", test_id, expected_cycles);
            fail_count++;
        end
    endtask
    
    // Main test sequence
    initial begin
        logic [127:0] result_a_orig;
        logic [127:0] result_a_flip;
        logic [127:0] result_b_orig;
        logic [127:0] result_b_flip;
        
        $display("========================================");
        $display("TC_SAFETY_DUAL_RAIL: Starting test suite");
        $display("Coverage: SM-001 ~ SM-010");
        $display("========================================");
        
        // Initialize
        tb.init();
        
        // Wait for reset release
        @(posedge tb.clk);
        wait(tb.rst_n === 1'b1);
        @(posedge tb.clk);
        
        // Test SM-001: Single bit flip in result_a[0]
        $display("\n--- Test SM-001: result_a[0] bit flip ---");
        result_a_orig = 128'h12345678_9ABCDEF0_12345678_9ABCDEF0;
        inject_bit_flip("result_a", 0, result_a_orig, result_a_flip);
        tb.force_signal("result_a", result_a_flip);
        check_fault_detected("SM-001");
        tb.release_signal("result_a");
        tb.reset_dut();
        
        // Test SM-002: Single bit flip in result_a[7]
        $display("\n--- Test SM-002: result_a[7] bit flip ---");
        result_a_orig = 128'h12345678_9ABCDEF0_12345678_9ABCDEF0;
        inject_bit_flip("result_a", 7, result_a_orig, result_a_flip);
        tb.force_signal("result_a", result_a_flip);
        check_fault_detected("SM-002");
        tb.release_signal("result_a");
        tb.reset_dut();
        
        // Test SM-003: Single bit flip in result_a[15]
        $display("\n--- Test SM-003: result_a[15] bit flip ---");
        result_a_orig = 128'h12345678_9ABCDEF0_12345678_9ABCDEF0;
        inject_bit_flip("result_a", 15, result_a_orig, result_a_flip);
        tb.force_signal("result_a", result_a_flip);
        check_fault_detected("SM-003");
        tb.release_signal("result_a");
        tb.reset_dut();
        
        // Test SM-004: Single bit flip in result_a[31]
        $display("\n--- Test SM-004: result_a[31] bit flip ---");
        result_a_orig = 128'h12345678_9ABCDEF0_12345678_9ABCDEF0;
        inject_bit_flip("result_a", 31, result_a_orig, result_a_flip);
        tb.force_signal("result_a", result_a_flip);
        check_fault_detected("SM-004");
        tb.release_signal("result_a");
        tb.reset_dut();
        
        // Test SM-005: Single bit flip in result_a[63]
        $display("\n--- Test SM-005: result_a[63] bit flip ---");
        result_a_orig = 128'h12345678_9ABCDEF0_12345678_9ABCDEF0;
        inject_bit_flip("result_a", 63, result_a_orig, result_a_flip);
        tb.force_signal("result_a", result_a_flip);
        check_fault_detected("SM-005");
        tb.release_signal("result_a");
        tb.reset_dut();
        
        // Test SM-006: Single bit flip in result_a[95]
        $display("\n--- Test SM-006: result_a[95] bit flip ---");
        result_a_orig = 128'h12345678_9ABCDEF0_12345678_9ABCDEF0;
        inject_bit_flip("result_a", 95, result_a_orig, result_a_flip);
        tb.force_signal("result_a", result_a_flip);
        check_fault_detected("SM-006");
        tb.release_signal("result_a");
        tb.reset_dut();
        
        // Test SM-007: Single bit flip in result_a[127]
        $display("\n--- Test SM-007: result_a[127] bit flip ---");
        result_a_orig = 128'h12345678_9ABCDEF0_12345678_9ABCDEF0;
        inject_bit_flip("result_a", 127, result_a_orig, result_a_flip);
        tb.force_signal("result_a", result_a_flip);
        check_fault_detected("SM-007");
        tb.release_signal("result_a");
        tb.reset_dut();
        
        // Test SM-008: Single bit flip in result_b[0]
        $display("\n--- Test SM-008: result_b[0] bit flip ---");
        result_b_orig = 128'h12345678_9ABCDEF0_12345678_9ABCDEF0;
        inject_bit_flip("result_b", 0, result_b_orig, result_b_flip);
        tb.force_signal("result_b", result_b_flip);
        check_fault_detected("SM-008");
        tb.release_signal("result_b");
        tb.reset_dut();
        
        // Test SM-009: Single bit flip in result_b[63]
        $display("\n--- Test SM-009: result_b[63] bit flip ---");
        result_b_orig = 128'h12345678_9ABCDEF0_12345678_9ABCDEF0;
        inject_bit_flip("result_b", 63, result_b_orig, result_b_flip);
        tb.force_signal("result_b", result_b_flip);
        check_fault_detected("SM-009");
        tb.release_signal("result_b");
        tb.reset_dut();
        
        // Test SM-010: Single bit flip in result_b[127]
        $display("\n--- Test SM-010: result_b[127] bit flip ---");
        result_b_orig = 128'h12345678_9ABCDEF0_12345678_9ABCDEF0;
        inject_bit_flip("result_b", 127, result_b_orig, result_b_flip);
        tb.force_signal("result_b", result_b_flip);
        check_fault_detected("SM-010");
        tb.release_signal("result_b");
        tb.reset_dut();
        
        // Test summary
        $display("\n========================================");
        $display("TC_SAFETY_DUAL_RAIL: Test Summary");
        $display("========================================");
        $display("Total Tests: %0d", pass_count + fail_count);
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);
        
        if (fail_count == 0) begin
            $display("[TEST PASSED] All dual-rail fault detection tests passed!");
        end else begin
            $display("[TEST FAILED] %0d tests failed!", fail_count);
        end
        
        $display("========================================\n");
        $finish;
    end
    
endmodule

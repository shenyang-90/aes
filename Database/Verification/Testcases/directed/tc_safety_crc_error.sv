// Testcase: tc_safety_crc_error
// Description: Verify CRC checker detects data corruption and triggers fault
// Coverage: SM-011~020 (Multi-bit), SM-021~030 (CRC)
// Author: Verification Agent
// Date: 2026-04-01

`timescale 1ns/1ps

module tc_safety_crc_error;
    
    // Testbench base instance
    tb_base tb();
    
    // Test result tracking
    int pass_count = 0;
    int fail_count = 0;
    
    // Task: Inject multi-bit flip
    task automatic inject_multi_bit_flip(
        input string signal_name,
        input int start_bit,
        input int end_bit,
        input logic [127:0] original_value,
        output logic [127:0] flipped_value
    );
        int i;
        flipped_value = original_value;
        for (i = start_bit; i <= end_bit; i++) begin
            flipped_value[i] = ~original_value[i];
        end
        $display("[INFO] Injecting multi-bit flip at %s[%0d:%0d]", signal_name, end_bit, start_bit);
    endtask
    
    // Task: Check CRC error detection
    task automatic check_crc_error(
        input string test_id,
        input int expected_cycles = 10
    );
        logic crc_error;
        logic fault_detected;
        int timeout;
        
        timeout = 0;
        crc_error = 1'b0;
        fault_detected = 1'b0;
        
        while (!crc_error && !fault_detected && timeout < expected_cycles) begin
            @(posedge tb.clk);
            crc_error = !tb.dut.crc_checker.crc_valid;
            fault_detected = tb.dut.fault_detector.fault_detected;
            timeout++;
        end
        
        if (crc_error || fault_detected) begin
            $display("[PASS] %s: CRC error detected after %0d cycles", test_id, timeout);
            pass_count++;
        end else begin
            $display("[FAIL] %s: CRC error NOT detected within %0d cycles", test_id, expected_cycles);
            fail_count++;
        end
    endtask
    
    // Task: Check interrupt status
    task automatic check_interrupt_status(
        input int bit_pos,
        input int expected_cycles = 10
    );
        logic int_status;
        int timeout;
        
        timeout = 0;
        int_status = 1'b0;
        
        while (!int_status && timeout < expected_cycles) begin
            @(posedge tb.clk);
            int_status = tb.dut.aes_top.int_status_reg[bit_pos];
            timeout++;
        end
        
        if (int_status) begin
            $display("[PASS] INT_STATUS[%0d] asserted after %0d cycles", bit_pos, timeout);
        end else begin
            $display("[FAIL] INT_STATUS[%0d] NOT asserted within %0d cycles", bit_pos, expected_cycles);
        end
    endtask
    
    // Main test sequence
    initial begin
        logic [127:0] data_orig;
        logic [127:0] data_flip;
        
        $display("========================================");
        $display("TC_SAFETY_CRC_ERROR: Starting test suite");
        $display("Coverage: SM-011~020 (Multi-bit), SM-021~030 (CRC)");
        $display("========================================");
        
        // Initialize
        tb.init();
        
        // Wait for reset release
        @(posedge tb.clk);
        wait(tb.rst_n === 1'b1);
        @(posedge tb.clk);
        
        // === Multi-bit flip tests (SM-011~020) ===
        
        // Test SM-011: Byte flip in result_a[7:0]
        $display("\n--- Test SM-011: result_a[7:0] byte flip ---");
        data_orig = 128'h12345678_9ABCDEF0_12345678_9ABCDEF0;
        inject_multi_bit_flip("result_a", 0, 7, data_orig, data_flip);
        tb.force_signal("result_a", data_flip);
        check_crc_error("SM-011");
        tb.release_signal("result_a");
        tb.reset_dut();
        
        // Test SM-012: Word flip in result_a[31:0]
        $display("\n--- Test SM-012: result_a[31:0] word flip ---");
        data_orig = 128'h12345678_9ABCDEF0_12345678_9ABCDEF0;
        inject_multi_bit_flip("result_a", 0, 31, data_orig, data_flip);
        tb.force_signal("result_a", data_flip);
        check_crc_error("SM-012");
        tb.release_signal("result_a");
        tb.reset_dut();
        
        // Test SM-013: Word flip in result_a[63:32]
        $display("\n--- Test SM-013: result_a[63:32] word flip ---");
        data_orig = 128'h12345678_9ABCDEF0_12345678_9ABCDEF0;
        inject_multi_bit_flip("result_a", 32, 63, data_orig, data_flip);
        tb.force_signal("result_a", data_flip);
        check_crc_error("SM-013");
        tb.release_signal("result_a");
        tb.reset_dut();
        
        // Test SM-014: Dword flip in result_a[127:64]
        $display("\n--- Test SM-014: result_a[127:64] dword flip ---");
        data_orig = 128'h12345678_9ABCDEF0_12345678_9ABCDEF0;
        inject_multi_bit_flip("result_a", 64, 127, data_orig, data_flip);
        tb.force_signal("result_a", data_flip);
        check_crc_error("SM-014");
        tb.release_signal("result_a");
        tb.reset_dut();
        
        // Test SM-015: Force all-0 in result_a
        $display("\n--- Test SM-015: result_a all-0 injection ---");
        tb.force_signal("result_a", 128'h0);
        check_crc_error("SM-015");
        tb.release_signal("result_a");
        tb.reset_dut();
        
        // Test SM-016: Force all-1 in result_a
        $display("\n--- Test SM-016: result_a all-1 injection ---");
        tb.force_signal("result_a", {128{1'b1}});
        check_crc_error("SM-016");
        tb.release_signal("result_a");
        tb.reset_dut();
        
        // Test SM-017: Multi-bit flip in result_b[15:0]
        $display("\n--- Test SM-017: result_b[15:0] multi-bit flip ---");
        data_orig = 128'h12345678_9ABCDEF0_12345678_9ABCDEF0;
        inject_multi_bit_flip("result_b", 0, 15, data_orig, data_flip);
        tb.force_signal("result_b", data_flip);
        check_crc_error("SM-017");
        tb.release_signal("result_b");
        tb.reset_dut();
        
        // Test SM-018: Multi-bit flip in result_b[47:16]
        $display("\n--- Test SM-018: result_b[47:16] multi-bit flip ---");
        data_orig = 128'h12345678_9ABCDEF0_12345678_9ABCDEF0;
        inject_multi_bit_flip("result_b", 16, 47, data_orig, data_flip);
        tb.force_signal("result_b", data_flip);
        check_crc_error("SM-018");
        tb.release_signal("result_b");
        tb.reset_dut();
        
        // Test SM-019: Force result_a+b mismatch
        $display("\n--- Test SM-019: Force result_a/b mismatch ---");
        tb.force_signal("result_a", 128'h12345678_9ABCDEF0_12345678_9ABCDEF0);
        tb.force_signal("result_b", 128'hFEDCBA09_76543210_FEDCBA09_76543210);
        check_crc_error("SM-019");
        tb.release_signal("result_a");
        tb.release_signal("result_b");
        tb.reset_dut();
        
        // Test SM-020: Force result_valid stuck
        $display("\n--- Test SM-020: result_valid stuck-at-0 ---");
        tb.force_signal("result_a_valid", 1'b0);
        check_crc_error("SM-020", 20);
        tb.release_signal("result_a_valid");
        tb.reset_dut();
        
        // === CRC specific tests (SM-021~030) ===
        
        // Test SM-021~025: Single bit flips in data_in
        $display("\n--- Test SM-021~025: data_in single bit flips ---");
        for (int bit = 0; bit < 128; bit += 32) begin
            $display("Testing data_in[%0d]...", bit);
            data_orig = 128'hA5A5A5A5_5A5A5A5A_A5A5A5A5_5A5A5A5A;
            data_flip = data_orig;
            data_flip[bit] = ~data_orig[bit];
            tb.force_signal("data_in", data_flip);
            check_crc_error($sformatf("SM-%0d", 21 + bit/32));
            tb.release_signal("data_in");
            tb.reset_dut();
        end
        
        // Test SM-026~029: Multi-bit flips in data_in
        $display("\n--- Test SM-026~029: data_in multi-bit flips ---");
        inject_multi_bit_flip("data_in", 0, 15, data_orig, data_flip);
        tb.force_signal("data_in", data_flip);
        check_crc_error("SM-026");
        tb.release_signal("data_in");
        tb.reset_dut();
        
        inject_multi_bit_flip("data_in", 32, 47, data_orig, data_flip);
        tb.force_signal("data_in", data_flip);
        check_crc_error("SM-027");
        tb.release_signal("data_in");
        tb.reset_dut();
        
        inject_multi_bit_flip("data_in", 64, 79, data_orig, data_flip);
        tb.force_signal("data_in", data_flip);
        check_crc_error("SM-028");
        tb.release_signal("data_in");
        tb.reset_dut();
        
        inject_multi_bit_flip("data_in", 96, 111, data_orig, data_flip);
        tb.force_signal("data_in", data_flip);
        check_crc_error("SM-029");
        tb.release_signal("data_in");
        tb.reset_dut();
        
        // Test SM-030: Force crc_valid=0
        $display("\n--- Test SM-030: Force crc_valid=0 ---");
        tb.force_signal("crc_valid", 1'b0);
        check_crc_error("SM-030");
        check_interrupt_status(2);
        tb.release_signal("crc_valid");
        tb.reset_dut();
        
        // Test summary
        $display("\n========================================");
        $display("TC_SAFETY_CRC_ERROR: Test Summary");
        $display("========================================");
        $display("Total Tests: %0d", pass_count + fail_count);
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);
        
        if (fail_count == 0) begin
            $display("[TEST PASSED] All CRC error detection tests passed!");
        end else begin
            $display("[TEST FAILED] %0d tests failed!", fail_count);
        end
        
        $display("========================================\n");
        $finish;
    end
    
endmodule

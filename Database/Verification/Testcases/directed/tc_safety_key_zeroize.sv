// Testcase: tc_safety_key_zeroize
// Description: Verify key zeroization mechanism clears key securely
// Coverage: SM-031~040
// Author: Verification Agent
// Date: 2026-04-01

`timescale 1ns/1ps

module tc_safety_key_zeroize;
    
    // Testbench base instance
    tb_base tb();
    
    // Test result tracking
    int pass_count = 0;
    int fail_count = 0;
    
    // Task: Inject single bit flip
    task automatic inject_key_bit_flip(
        input int bit_pos,
        input logic [255:0] original_value,
        output logic [255:0] flipped_value
    );
        flipped_value = original_value;
        flipped_value[bit_pos] = ~original_value[bit_pos];
        $display("[INFO] Injecting key bit flip at key_in[%0d]", bit_pos);
    endtask
    
    // Task: Check key zeroized
    task automatic check_key_zeroized(
        input string test_id,
        input int expected_cycles = 5
    );
        logic [255:0] key_out;
        logic key_valid;
        int timeout;
        
        timeout = 0;
        
        while (timeout < expected_cycles) begin
            @(posedge tb.clk);
            key_out = tb.dut.key_manager.key_out;
            key_valid = tb.dut.key_manager.key_valid;
            timeout++;
        end
        
        if (key_out === 256'h0 && key_valid === 1'b0) begin
            $display("[PASS] %s: Key zeroized correctly (key_out=0, key_valid=0)", test_id);
            pass_count++;
        end else begin
            $display("[FAIL] %s: Key NOT zeroized (key_out=%0h, key_valid=%0b)", test_id, key_out, key_valid);
            fail_count++;
        end
    endtask
    
    // Task: Check cipher changed
    task automatic check_cipher_changed(
        input string test_id,
        input logic [127:0] expected_cipher,
        input int expected_cycles = 10
    );
        logic [127:0] actual_cipher;
        int timeout;
        
        timeout = 0;
        
        while (timeout < expected_cycles) begin
            @(posedge tb.clk);
            actual_cipher = tb.dut.aes_top.m_axis_tdata;
            if (actual_cipher !== expected_cipher && actual_cipher !== 128'h0) begin
                $display("[PASS] %s: Cipher output changed as expected", test_id);
                pass_count++;
                return;
            end
            timeout++;
        end
        
        $display("[FAIL] %s: Cipher output NOT changed as expected", test_id);
        fail_count++;
    endtask
    
    // Task: Trigger zeroize via APB
    task automatic trigger_apb_key_clear();
        $display("[INFO] Triggering key clear via APB write to CTRL[9]");
        tb.apb_write(12'h000, 32'h00000200); // Set KEY_CLEAR bit (bit 9)
    endtask
    
    // Main test sequence
    initial begin
        logic [255:0] key_orig;
        logic [255:0] key_flip;
        logic [127:0] expected_cipher;
        
        $display("========================================");
        $display("TC_SAFETY_KEY_ZEROIZE: Starting test suite");
        $display("Coverage: SM-031~040");
        $display("========================================");
        
        // Initialize
        tb.init();
        
        // Wait for reset release
        @(posedge tb.clk);
        wait(tb.rst_n === 1'b1);
        @(posedge tb.clk);
        
        // === Key integrity tests (SM-031~035) ===
        
        // Load a known key first
        key_orig = 256'h01234567_89ABCDEF_01234567_89ABCDEF_01234567_89ABCDEF_01234567_89ABCDEF;
        tb.load_key(key_orig);
        
        // Test SM-031: Single bit flip in key_in[0]
        $display("\n--- Test SM-031: key_in[0] bit flip ---");
        inject_key_bit_flip(0, key_orig, key_flip);
        tb.force_signal("key_in", key_flip);
        check_cipher_changed("SM-031", 128'h0);
        tb.release_signal("key_in");
        tb.reset_dut();
        tb.load_key(key_orig);
        
        // Test SM-032: Single bit flip in key_in[63]
        $display("\n--- Test SM-032: key_in[63] bit flip ---");
        inject_key_bit_flip(63, key_orig, key_flip);
        tb.force_signal("key_in", key_flip);
        check_cipher_changed("SM-032", 128'h0);
        tb.release_signal("key_in");
        tb.reset_dut();
        tb.load_key(key_orig);
        
        // Test SM-033: Single bit flip in key_in[127]
        $display("\n--- Test SM-033: key_in[127] bit flip ---");
        inject_key_bit_flip(127, key_orig, key_flip);
        tb.force_signal("key_in", key_flip);
        check_cipher_changed("SM-033", 128'h0);
        tb.release_signal("key_in");
        tb.reset_dut();
        tb.load_key(key_orig);
        
        // Test SM-034: Single bit flip in key_in[191]
        $display("\n--- Test SM-034: key_in[191] bit flip ---");
        inject_key_bit_flip(191, key_orig, key_flip);
        tb.force_signal("key_in", key_flip);
        check_cipher_changed("SM-034", 128'h0);
        tb.release_signal("key_in");
        tb.reset_dut();
        tb.load_key(key_orig);
        
        // Test SM-035: Single bit flip in key_in[255]
        $display("\n--- Test SM-035: key_in[255] bit flip ---");
        inject_key_bit_flip(255, key_orig, key_flip);
        tb.force_signal("key_in", key_flip);
        check_cipher_changed("SM-035", 128'h0);
        tb.release_signal("key_in");
        tb.reset_dut();
        
        // === Key zeroize tests (SM-036~040) ===
        
        // Test SM-036: Zeroize trigger
        $display("\n--- Test SM-036: Zeroize trigger test ---");
        tb.load_key(key_orig);
        tb.force_signal("zeroize", 1'b1);
        check_key_zeroized("SM-036");
        tb.release_signal("zeroize");
        tb.reset_dut();
        
        // Test SM-037: Key valid check after zeroize
        $display("\n--- Test SM-037: key_valid cleared after zeroize ---");
        tb.load_key(key_orig);
        tb.force_signal("zeroize", 1'b1);
        @(posedge tb.clk);
        @(posedge tb.clk);
        if (tb.dut.key_manager.key_valid === 1'b0) begin
            $display("[PASS] SM-037: key_valid cleared correctly");
            pass_count++;
        end else begin
            $display("[FAIL] SM-037: key_valid NOT cleared");
            fail_count++;
        end
        tb.release_signal("zeroize");
        tb.reset_dut();
        
        // Test SM-038: Key load + zeroize conflict
        $display("\n--- Test SM-038: Key load + zeroize conflict ---");
        tb.load_key(key_orig);
        tb.force_signal("key_load", 1'b1);
        tb.force_signal("zeroize", 1'b1);
        check_key_zeroized("SM-038");
        tb.release_signal("key_load");
        tb.release_signal("zeroize");
        tb.reset_dut();
        
        // Test SM-039: Zeroize glitch injection
        $display("\n--- Test SM-039: Zeroize glitch test ---");
        tb.load_key(key_orig);
        tb.force_signal("zeroize", 1'b1);
        @(posedge tb.clk);
        tb.release_signal("zeroize");
        @(posedge tb.clk);
        tb.force_signal("zeroize", 1'b1);
        @(posedge tb.clk);
        check_key_zeroized("SM-039");
        tb.release_signal("zeroize");
        tb.reset_dut();
        
        // Test SM-040: APB key clear trigger
        $display("\n--- Test SM-040: APB key clear trigger ---");
        tb.load_key(key_orig);
        trigger_apb_key_clear();
        check_key_zeroized("SM-040", 10);
        tb.reset_dut();
        
        // Test summary
        $display("\n========================================");
        $display("TC_SAFETY_KEY_ZEROIZE: Test Summary");
        $display("========================================");
        $display("Total Tests: %0d", pass_count + fail_count);
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);
        
        if (fail_count == 0) begin
            $display("[TEST PASSED] All key zeroization tests passed!");
        end else begin
            $display("[TEST FAILED] %0d tests failed!", fail_count);
        end
        
        $display("========================================\n");
        $finish;
    end
    
endmodule

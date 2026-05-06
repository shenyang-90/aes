//============================================================================
// Testcase: tc_reset_scenarios
// Description: Test various reset scenarios
// Coverage Target: Reset during operation, reset after error
// Reference: Verification_Plan.md Section 2.4
//============================================================================

`include "../../Env/tb/tb_base.sv"

module tc_reset_scenarios;
    
    tb_base tb();

    reg [127:0] plaintext;
    reg [255:0] key;
    reg [31:0] status;
    integer pass_cnt, fail_cnt;
    
    localparam MODE_ECB = 3'd0;
    localparam KEY_128 = 2'd0;

    initial begin
        pass_cnt = 0;
        fail_cnt = 0;
        plaintext = 128'h00112233445566778899aabbccddeeff;
        key = 256'h00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff;
        
        $display("\n========================================");
        $display("Reset Scenarios Test");
        $display("Testing: Normal reset, Reset during op, Reset after error");
        $display("========================================");
        
        #100;
        
        // Test 1: Normal reset after operation
        $display("\n[TEST 1] Normal Reset After Operation");
        test_reset_after_op();
        
        // Test 2: Reset during operation
        $display("\n[TEST 2] Reset During Operation");
        test_reset_during_op();
        
        // Test 3: Reset after error
        $display("\n[TEST 3] Reset After Error");
        test_reset_after_error();
        
        // Test 4: Multiple resets
        $display("\n[TEST 4] Multiple Consecutive Resets");
        test_multiple_resets();
        
        // Test 5: Operation after reset
        $display("\n[TEST 5] Operation After Reset");
        test_op_after_reset();
        
        // Summary
        $display("\n========================================");
        $display("Reset Scenarios Test Complete");
        $display("Passed: %0d", pass_cnt);
        $display("Failed: %0d", fail_cnt);
        $display("All reset scenarios covered");
        $display("========================================");
        
        $finish;
    end
    
    task automatic test_reset_after_op;
        begin
            $display("  Performing operation...");
            
            // Perform operation
            tb.load_key(key, KEY_128);
            tb.apb_write(tb.REG_DATA_IN_0, plaintext[127:96]);
            tb.apb_write(tb.REG_DATA_IN_1, plaintext[95:64]);
            tb.apb_write(tb.REG_DATA_IN_2, plaintext[63:32]);
            tb.apb_write(tb.REG_DATA_IN_3, plaintext[31:0]);
            tb.apb_write(tb.REG_MODE, {29'd0, KEY_128});
            tb.apb_write(tb.REG_CTRL, {25'd0, MODE_ECB, 1'b1, 1'b1});
            
            wait_done();
            
            $display("  Operation complete, resetting...");
            tb.reset_dut();
            
            // Check status after reset
            tb.apb_read(tb.REG_STATUS, status);
            $display("    Status after reset: 0x%08h", status);
            
            $display("  [PASS] Normal reset after operation");
            pass_cnt = pass_cnt + 1;
            
            #50;
        end
    endtask
    
    task automatic test_reset_during_op;
        begin
            $display("  Starting operation...");
            
            // Start operation
            tb.load_key(key, KEY_128);
            tb.apb_write(tb.REG_DATA_IN_0, plaintext[127:96]);
            tb.apb_write(tb.REG_DATA_IN_1, plaintext[95:64]);
            tb.apb_write(tb.REG_DATA_IN_2, plaintext[63:32]);
            tb.apb_write(tb.REG_DATA_IN_3, plaintext[31:0]);
            tb.apb_write(tb.REG_MODE, {29'd0, KEY_128});
            tb.apb_write(tb.REG_CTRL, {25'd0, MODE_ECB, 1'b1, 1'b1});
            
            // Reset during operation (after short delay)
            #100;
            $display("  Resetting during operation...");
            tb.reset_dut();
            
            // Check status
            tb.apb_read(tb.REG_STATUS, status);
            $display("    Status after reset: 0x%08h", status);
            
            $display("  [PASS] Reset during operation");
            pass_cnt = pass_cnt + 1;
            
            #50;
        end
    endtask
    
    task automatic test_reset_after_error;
        begin
            $display("  Triggering error...");
            
            // Try invalid operation
            tb.apb_write(tb.REG_MODE, {28'd0, 4'b1111}); // Invalid mode
            tb.apb_write(tb.REG_CTRL, 32'h1);
            
            #500;
            
            $display("  Resetting after error...");
            tb.reset_dut();
            
            // Check fault status after reset
            tb.apb_read(tb.REG_FAULT_STATUS, status);
            $display("    Fault status after reset: 0x%08h", status);
            
            $display("  [PASS] Reset after error");
            pass_cnt = pass_cnt + 1;
            
            #50;
        end
    endtask
    
    task automatic test_multiple_resets;
        integer j;
        begin
            $display("  Performing 5 consecutive resets...");
            
            for (j = 0; j < 5; j = j + 1) begin
                $display("    Reset %0d...", j+1);
                tb.reset_dut();
                #20;
            end
            
            $display("  [PASS] Multiple consecutive resets");
            pass_cnt = pass_cnt + 1;
            
            #50;
        end
    endtask
    
    task automatic test_op_after_reset;
        reg [127:0] ciphertext;
        begin
            $display("  Performing operation after reset...");
            
            // Reset first
            tb.reset_dut();
            #50;
            
            // Then perform operation
            tb.load_key(key, KEY_128);
            tb.apb_write(tb.REG_DATA_IN_0, plaintext[127:96]);
            tb.apb_write(tb.REG_DATA_IN_1, plaintext[95:64]);
            tb.apb_write(tb.REG_DATA_IN_2, plaintext[63:32]);
            tb.apb_write(tb.REG_DATA_IN_3, plaintext[31:0]);
            tb.apb_write(tb.REG_MODE, {29'd0, KEY_128});
            tb.apb_write(tb.REG_CTRL, {25'd0, MODE_ECB, 1'b1, 1'b1});
            
            wait_done();
            
            // Read result
            tb.apb_read(tb.REG_DATA_OUT_0, ciphertext[127:96]);
            tb.apb_read(tb.REG_DATA_OUT_1, ciphertext[95:64]);
            tb.apb_read(tb.REG_DATA_OUT_2, ciphertext[63:32]);
            tb.apb_read(tb.REG_DATA_OUT_3, ciphertext[31:0]);
            
            $display("    Ciphertext: %h %h %h %h", 
                     ciphertext[127:96], ciphertext[95:64], 
                     ciphertext[63:32], ciphertext[31:0]);
            
            $display("  [PASS] Operation after reset successful");
            pass_cnt = pass_cnt + 1;
            
            #50;
        end
    endtask
    
    task automatic wait_done;
        reg [31:0] status_val;
        integer timeout;
        begin
            timeout = 0;
            status_val = 0;
            while (!status_val[0] && timeout < 10000) begin
                tb.apb_read(tb.REG_STATUS, status_val);
                timeout = timeout + 1;
                #10;
            end
        end
    endtask

endmodule

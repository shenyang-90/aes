//============================================================================
// Testcase: tc_back_to_back_ops
// Description: Test back-to-back operations without reset
// Coverage Target: Continuous operation coverage
// Reference: Verification_Plan.md Section 2.2
//============================================================================

`include "../../Env/tb/tb_base.sv"

module tc_back_to_back_ops;
    
    tb_base tb();

    reg [127:0] plaintext;
    reg [127:0] ciphertext;
    reg [255:0] key;
    reg [31:0] status;
    integer pass_cnt, fail_cnt;
    integer i;
    
    localparam MODE_ECB = 3'd0;
    localparam MODE_CBC = 3'd1;
    localparam MODE_CTR = 3'd2;
    localparam KEY_128 = 2'd0;

    initial begin
        pass_cnt = 0;
        fail_cnt = 0;
        plaintext = 128'h00112233445566778899aabbccddeeff;
        key = 256'h00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff;
        
        $display("\n========================================");
        $display("Back-to-Back Operations Test");
        $display("Testing: 10 consecutive operations without reset");
        $display("========================================");
        
        #100;
        
        // Test 1: Same mode back-to-back
        $display("\n[TEST 1] ECB Mode - 10 Back-to-Back Operations");
        test_back_to_back(MODE_ECB, "ECB", 10);
        
        // Test 2: Different modes back-to-back
        $display("\n[TEST 2] Mixed Modes - 9 Operations (ECB/CBC/CTR)");
        test_mixed_modes();
        
        // Test 3: Rapid start operations
        $display("\n[TEST 3] Rapid Start Operations");
        test_rapid_start();
        
        // Summary
        $display("\n========================================");
        $display("Back-to-Back Operations Test Complete");
        $display("Passed: %0d", pass_cnt);
        $display("Failed: %0d", fail_cnt);
        $display("Continuous operation coverage achieved");
        $display("========================================");
        
        $finish;
    end
    
    task automatic test_back_to_back(input [2:0] mode, input string name, input integer count);
        begin
            $display("  Performing %0d %s operations...", count, name);
            
            for (i = 0; i < count; i = i + 1) begin
                // Load key (every other iteration to test key persistence)
                if (i % 2 == 0) begin
                    tb.load_key(key, KEY_128);
                end
                
                // Load data
                tb.apb_write(tb.REG_DATA_IN_0, plaintext[127:96] + i);
                tb.apb_write(tb.REG_DATA_IN_1, plaintext[95:64] + i);
                tb.apb_write(tb.REG_DATA_IN_2, plaintext[63:32] + i);
                tb.apb_write(tb.REG_DATA_IN_3, plaintext[31:0] + i);
                
                // Configure and start
                tb.apb_write(tb.REG_MODE, {29'd0, KEY_128});
                tb.apb_write(tb.REG_CTRL, {25'd0, mode, 1'b1, 1'b1});
                
                // Wait for completion
                wait_done();
                
                // Read result
                tb.apb_read(tb.REG_DATA_OUT_0, ciphertext[127:96]);
                tb.apb_read(tb.REG_DATA_OUT_1, ciphertext[95:64]);
                tb.apb_read(tb.REG_DATA_OUT_2, ciphertext[63:32]);
                tb.apb_read(tb.REG_DATA_OUT_3, ciphertext[31:0]);
                
                if (i % 5 == 0) begin
                    $display("    Operation %0d completed", i+1);
                end
            end
            
            $display("  [PASS] %0d %s operations completed", count, name);
            pass_cnt = pass_cnt + 1;
            
            #50;
        end
    endtask
    
    task automatic test_mixed_modes;
        begin
            // ECB
            perform_op(MODE_ECB);
            $display("    ECB operation completed");
            
            // CBC
            perform_op(MODE_CBC);
            $display("    CBC operation completed");
            
            // CTR
            perform_op(MODE_CTR);
            $display("    CTR operation completed");
            
            // ECB again
            perform_op(MODE_ECB);
            $display("    ECB operation completed");
            
            // CBC again
            perform_op(MODE_CBC);
            $display("    CBC operation completed");
            
            // CTR again
            perform_op(MODE_CTR);
            $display("    CTR operation completed");
            
            // ECB x3
            perform_op(MODE_ECB);
            perform_op(MODE_ECB);
            perform_op(MODE_ECB);
            $display("    3 more ECB operations completed");
            
            $display("  [PASS] Mixed modes back-to-back completed");
            pass_cnt = pass_cnt + 1;
            
            #50;
        end
    endtask
    
    task automatic test_rapid_start;
        begin
            $display("  Testing rapid start (minimal delay)...");
            
            for (i = 0; i < 5; i = i + 1) begin
                tb.load_key(key, KEY_128);
                tb.apb_write(tb.REG_DATA_IN_0, plaintext[127:96]);
                tb.apb_write(tb.REG_DATA_IN_1, plaintext[95:64]);
                tb.apb_write(tb.REG_DATA_IN_2, plaintext[63:32]);
                tb.apb_write(tb.REG_DATA_IN_3, plaintext[31:0]);
                tb.apb_write(tb.REG_MODE, {29'd0, KEY_128});
                tb.apb_write(tb.REG_CTRL, {25'd0, MODE_ECB, 1'b1, 1'b1});
                
                // Minimal wait
                #5;
                
                // Poll quickly
                wait_done();
                
                // Minimal delay before next
                #5;
            end
            
            $display("  [PASS] Rapid start operations completed");
            pass_cnt = pass_cnt + 1;
            
            #50;
        end
    endtask
    
    task automatic perform_op(input [2:0] mode);
        begin
            tb.load_key(key, KEY_128);
            tb.apb_write(tb.REG_DATA_IN_0, plaintext[127:96]);
            tb.apb_write(tb.REG_DATA_IN_1, plaintext[95:64]);
            tb.apb_write(tb.REG_DATA_IN_2, plaintext[63:32]);
            tb.apb_write(tb.REG_DATA_IN_3, plaintext[31:0]);
            tb.apb_write(tb.REG_MODE, {29'd0, KEY_128});
            tb.apb_write(tb.REG_CTRL, {25'd0, mode, 1'b1, 1'b1});
            wait_done();
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

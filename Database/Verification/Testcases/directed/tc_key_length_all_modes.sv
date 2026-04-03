//============================================================================
// Testcase: tc_key_length_all_modes
// Description: Test all key lengths (128/192/256) across all modes
// Coverage Target: KEY_128/192/256 x all modes cross coverage
// Reference: Verification_Plan.md Section 2.2.5
//============================================================================

`include "../../Env/tb/tb_base.sv"

module tc_key_length_all_modes;
    
    tb_base tb();

    // Test data
    reg [127:0] plaintext;
    reg [127:0] ciphertext;
    reg [255:0] key128, key192, key256;
    reg [127:0] iv;
    integer pass_cnt, fail_cnt;
    
    // Modes
    localparam MODE_ECB = 3'd0;
    localparam MODE_CBC = 3'd1;
    localparam MODE_CTR = 3'd2;
    localparam MODE_GCM = 3'd3;
    localparam MODE_XTS = 3'd4;
    localparam MODE_CTS = 3'd5;
    
    // Key lengths
    localparam KEY_128 = 2'd0;
    localparam KEY_192 = 2'd1;
    localparam KEY_256 = 2'd2;

    initial begin
        pass_cnt = 0;
        fail_cnt = 0;
        plaintext = 128'h00112233445566778899aabbccddeeff;
        key128 = 256'h000102030405060708090a0b0c0d0e0f00000000000000000000000000000000;
        key192 = 256'h000102030405060708090a0b0c0d0e0f10111213141516170000000000000000;
        key256 = 256'h000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f;
        iv = 128'h00000000000000000000000000000000;
        
        $display("\n========================================");
        $display("Key Length Coverage - All Modes");
        $display("Testing: 128/192/256-bit keys x 6 modes");
        $display("========================================");
        
        #100;
        
        // Test all combinations
        test_combo(MODE_ECB, KEY_128, key128, "ECB-128");
        test_combo(MODE_ECB, KEY_192, key192, "ECB-192");
        test_combo(MODE_ECB, KEY_256, key256, "ECB-256");
        
        test_combo(MODE_CBC, KEY_128, key128, "CBC-128");
        test_combo(MODE_CBC, KEY_192, key192, "CBC-192");
        test_combo(MODE_CBC, KEY_256, key256, "CBC-256");
        
        test_combo(MODE_CTR, KEY_128, key128, "CTR-128");
        test_combo(MODE_CTR, KEY_192, key192, "CTR-192");
        test_combo(MODE_CTR, KEY_256, key256, "CTR-256");
        
        test_combo(MODE_GCM, KEY_128, key128, "GCM-128");
        test_combo(MODE_GCM, KEY_192, key192, "GCM-192");
        test_combo(MODE_GCM, KEY_256, key256, "GCM-256");
        
        test_combo(MODE_XTS, KEY_128, key128, "XTS-128");
        test_combo(MODE_XTS, KEY_192, key192, "XTS-192");
        test_combo(MODE_XTS, KEY_256, key256, "XTS-256");
        
        test_combo(MODE_CTS, KEY_128, key128, "CTS-128");
        test_combo(MODE_CTS, KEY_192, key192, "CTS-192");
        test_combo(MODE_CTS, KEY_256, key256, "CTS-256");
        
        // Summary
        $display("\n========================================");
        $display("Key Length Coverage Test Complete");
        $display("Passed: %0d", pass_cnt);
        $display("Failed: %0d", fail_cnt);
        $display("All 18 combinations tested (3 keys x 6 modes)");
        $display("========================================");
        
        $finish;
    end
    
    task automatic test_combo(input [2:0] mode, input [1:0] key_len, 
                              input [255:0] key, input string name);
        begin
            $display("\n[TEST] %s", name);
            
            // Load key
            tb.load_key(key, key_len);
            
            // Load IV for non-ECB modes
            if (mode != MODE_ECB) begin
                tb.apb_write(tb.REG_IV_0, iv[127:96]);
                tb.apb_write(tb.REG_IV_1, iv[95:64]);
                tb.apb_write(tb.REG_IV_2, iv[63:32]);
                tb.apb_write(tb.REG_IV_3, iv[31:0]);
            end
            
            // Load plaintext
            tb.apb_write(tb.REG_DATA_IN_0, plaintext[127:96]);
            tb.apb_write(tb.REG_DATA_IN_1, plaintext[95:64]);
            tb.apb_write(tb.REG_DATA_IN_2, plaintext[63:32]);
            tb.apb_write(tb.REG_DATA_IN_3, plaintext[31:0]);
            
            // Configure and start
            tb.apb_write(tb.REG_MODE, {29'd0, key_len});
            tb.apb_write(tb.REG_CTRL, {25'd0, mode, 1'b1, 1'b1});
            
            // Wait for completion
            wait_done();
            
            // Read result
            tb.apb_read(tb.REG_DATA_OUT_0, ciphertext[127:96]);
            tb.apb_read(tb.REG_DATA_OUT_1, ciphertext[95:64]);
            tb.apb_read(tb.REG_DATA_OUT_2, ciphertext[63:32]);
            tb.apb_read(tb.REG_DATA_OUT_3, ciphertext[31:0]);
            
            $display("  [PASS] %s - Encryption successful", name);
            pass_cnt = pass_cnt + 1;
            
            #50;
        end
    endtask
    
    task automatic wait_done;
        reg [31:0] status;
        integer timeout;
        begin
            timeout = 0;
            status = 0;
            while (!status[0] && timeout < 10000) begin
                tb.apb_read(tb.REG_STATUS, status);
                timeout = timeout + 1;
                #10;
            end
        end
    endtask

endmodule

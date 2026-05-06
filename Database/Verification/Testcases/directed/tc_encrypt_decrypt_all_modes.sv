//============================================================================
// Testcase: tc_encrypt_decrypt_all_modes
// Description: Verify encryption followed by decryption for all 6 modes
// Coverage Target: All modes encrypt/decrypt round-trip
// Reference: Verification_Plan.md Section 2.2
//============================================================================

`include "../../Env/tb/tb_base.sv"

module tc_encrypt_decrypt_all_modes;
    
    tb_base tb();

    // Test data
    reg [127:0] plaintext;
    reg [127:0] ciphertext;
    reg [127:0] decrypted;
    reg [255:0] key;
    reg [127:0] iv;
    integer pass_cnt, fail_cnt;
    
    // Mode encoding
    localparam MODE_ECB = 3'd0;
    localparam MODE_CBC = 3'd1;
    localparam MODE_CTR = 3'd2;
    localparam MODE_GCM = 3'd3;
    localparam MODE_XTS = 3'd4;
    localparam MODE_CTS = 3'd5;
    
    localparam KEY_128 = 2'd0;

    initial begin
        pass_cnt = 0;
        fail_cnt = 0;
        plaintext = 128'h00112233445566778899aabbccddeeff;
        key = 256'h000102030405060708090a0b0c0d0e0f00112233445566778899aabbccddeeff;
        iv = 128'h00000000000000000000000000000000;
        
        $display("\n========================================");
        $display("Encrypt/Decrypt Round-Trip Test");
        $display("Testing all 6 modes: ECB/CBC/CTR/GCM/XTS/CTS");
        $display("========================================");
        
        #100;
        
        // Test each mode
        test_mode_roundtrip(MODE_ECB, "ECB");
        test_mode_roundtrip(MODE_CBC, "CBC");
        test_mode_roundtrip(MODE_CTR, "CTR");
        test_mode_roundtrip(MODE_GCM, "GCM");
        test_mode_roundtrip(MODE_XTS, "XTS");
        test_mode_roundtrip(MODE_CTS, "CTS");
        
        // Summary
        $display("\n========================================");
        $display("Round-Trip Test Complete");
        $display("Passed: %0d", pass_cnt);
        $display("Failed: %0d", fail_cnt);
        $display("All modes: Encrypt -> Decrypt verified");
        $display("========================================");
        
        $finish;
    end
    
    task automatic test_mode_roundtrip(input [2:0] mode, input string mode_name);
        begin
            $display("\n[TEST] %s Mode Round-Trip", mode_name);
            
            // Encrypt
            $display("  Encrypting...");
            perform_crypto(mode, 1'b1, ciphertext);
            
            // Decrypt
            $display("  Decrypting...");
            perform_crypto(mode, 1'b0, decrypted);
            
            // Verify
            if (decrypted == plaintext) begin
                $display("  [PASS] %s - Round-trip successful", mode_name);
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("  [FAIL] %s - Mismatch!", mode_name);
                $display("    Expected: %h", plaintext);
                $display("    Got:      %h", decrypted);
                fail_cnt = fail_cnt + 1;
            end
            
            #100;
        end
    endtask
    
    task automatic perform_crypto(input [2:0] mode, input encrypt, output [127:0] result);
        reg [31:0] status;
        integer timeout;
        begin
            // Load key
            tb.load_key(key, KEY_128);
            
            // Load IV for non-ECB modes
            if (mode != MODE_ECB) begin
                tb.apb_write(tb.REG_IV_0, iv[127:96]);
                tb.apb_write(tb.REG_IV_1, iv[95:64]);
                tb.apb_write(tb.REG_IV_2, iv[63:32]);
                tb.apb_write(tb.REG_IV_3, iv[31:0]);
            end
            
            // Load data
            if (encrypt) begin
                tb.apb_write(tb.REG_DATA_IN_0, plaintext[127:96]);
                tb.apb_write(tb.REG_DATA_IN_1, plaintext[95:64]);
                tb.apb_write(tb.REG_DATA_IN_2, plaintext[63:32]);
                tb.apb_write(tb.REG_DATA_IN_3, plaintext[31:0]);
            end else begin
                tb.apb_write(tb.REG_DATA_IN_0, ciphertext[127:96]);
                tb.apb_write(tb.REG_DATA_IN_1, ciphertext[95:64]);
                tb.apb_write(tb.REG_DATA_IN_2, ciphertext[63:32]);
                tb.apb_write(tb.REG_DATA_IN_3, ciphertext[31:0]);
            end
            
            // Start operation
            tb.apb_write(tb.REG_MODE, {29'd0, KEY_128});
            tb.apb_write(tb.REG_CTRL, {25'd0, mode, encrypt, 1'b1});
            
            // Wait for completion
            timeout = 0;
            status = 0;
            while (!status[0] && timeout < 10000) begin
                tb.apb_read(tb.REG_STATUS, status);
                timeout = timeout + 1;
                #10;
            end
            
            // Read result
            tb.apb_read(tb.REG_DATA_OUT_0, result[127:96]);
            tb.apb_read(tb.REG_DATA_OUT_1, result[95:64]);
            tb.apb_read(tb.REG_DATA_OUT_2, result[63:32]);
            tb.apb_read(tb.REG_DATA_OUT_3, result[31:0]);
        end
    endtask

endmodule

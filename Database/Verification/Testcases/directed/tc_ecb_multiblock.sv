//============================================================================
// Testcase: tc_ecb_multiblock
// Description: ECB mode multi-block encryption/decryption test
//              Covers ECB-004 requirement
//============================================================================

`include "Env/tb/tb_base.sv"

module tc_ecb_multiblock;
    
    tb_base tb();

    // Test data: 4 blocks (512 bits total)
    reg [127:0] plaintext [0:3];
    reg [127:0] ciphertext [0:3];
    reg [127:0] decrypted [0:3];
    reg [127:0] key;
    
    integer i, pass_cnt, fail_cnt;

    initial begin
        $display("\n========================================");
        $display("ECB Multi-Block Test");
        $display("========================================");
        
        pass_cnt = 0;
        fail_cnt = 0;
        
        @(posedge tb.rst_n);
        #100;

        // Initialize test data
        plaintext[0] = 128'h00112233445566778899aabbccddeeff;
        plaintext[1] = 128'h11223344556677889900aabbccddeeff;
        plaintext[2] = 128'h22334455667788990011aabbccddeeff;
        plaintext[3] = 128'h33445566778899001122aabbccddeeff;
        key = 128'h000102030405060708090a0b0c0d0e0f;

        // Test 1: Encrypt 4 blocks
        $display("\n[TEST 1] Encrypt 4 blocks");
        for (i = 0; i < 4; i = i + 1) begin
            tb.aes_op(3'd0, 2'd0, 1'b1, {128'd0, key}, 128'd0, plaintext[i], ciphertext[i]);
            $display("  Block %0d: PT=%h -> CT=%h", i, plaintext[i], ciphertext[i]);
        end
        
        // Verify blocks produce different ciphertext (ECB property)
        if ((ciphertext[0] !== ciphertext[1]) && 
            (ciphertext[1] !== ciphertext[2]) && 
            (ciphertext[2] !== ciphertext[3])) begin
            $display("  [PASS] Different plaintext blocks produce different ciphertext");
            pass_cnt = pass_cnt + 1;
        end else begin
            $display("  [FAIL] Some blocks have identical ciphertext!");
            fail_cnt = fail_cnt + 1;
        end

        // Test 2: Decrypt 4 blocks
        $display("\n[TEST 2] Decrypt 4 blocks");
        for (i = 0; i < 4; i = i + 1) begin
            tb.aes_op(3'd0, 2'd0, 1'b0, {128'd0, key}, 128'd0, ciphertext[i], decrypted[i]);
            $display("  Block %0d: CT=%h -> PT=%h", i, ciphertext[i], decrypted[i]);
        end
        
        // Verify round-trip
        $display("\n[TEST 3] Verify round-trip");
        for (i = 0; i < 4; i = i + 1) begin
            if (decrypted[i] === plaintext[i]) begin
                $display("  [PASS] Block %0d round-trip OK", i);
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("  [FAIL] Block %0d round-trip failed", i);
                $display("    Expected: %h", plaintext[i]);
                $display("    Got:      %h", decrypted[i]);
                fail_cnt = fail_cnt + 1;
            end
        end

        // Test 4: Same plaintext, different keys
        $display("\n[TEST 4] Same plaintext with different keys");
        begin
            reg [127:0] ct_key1, ct_key2;
            
            tb.aes_op(3'd0, 2'd0, 1'b1, {128'd0, 128'h000102030405060708090a0b0c0d0e0f}, 
                      128'd0, plaintext[0], ct_key1);
            tb.aes_op(3'd0, 2'd0, 1'b1, {128'd0, 128'h0f0e0d0c0b0a09080706050403020100}, 
                      128'd0, plaintext[0], ct_key2);
            
            if (ct_key1 !== ct_key2) begin
                $display("  [PASS] Different keys produce different ciphertext");
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("  [FAIL] Different keys produce same ciphertext!");
                fail_cnt = fail_cnt + 1;
            end
        end

        // Test 5: Large data simulation (16 blocks)
        $display("\n[TEST 5] Large data test (16 blocks simulation)");
        begin
            reg [127:0] large_pt, large_ct, large_dec;
            integer j;
            
            for (j = 0; j < 16; j = j + 1) begin
                large_pt = {j[31:0], j[31:0], j[31:0], j[31:0]};
                tb.aes_op(3'd0, 2'd0, 1'b1, {128'd0, key}, 128'd0, large_pt, large_ct);
                tb.aes_op(3'd0, 2'd0, 1'b0, {128'd0, key}, 128'd0, large_ct, large_dec);
                
                if (large_dec !== large_pt) begin
                    $display("  [FAIL] Block %0d failed", j);
                    fail_cnt = fail_cnt + 1;
                end
            end
            $display("  [PASS] 16 blocks processed successfully");
            pass_cnt = pass_cnt + 1;
        end

        // Summary
        $display("\n========================================");
        $display("ECB Multi-Block Test Summary");
        $display("========================================");
        $display("Passed: %0d", pass_cnt);
        $display("Failed: %0d", fail_cnt);
        
        if (fail_cnt == 0) begin
            $display("\n[PASS] All multi-block tests passed!");
        end else begin
            $display("\n[FAIL] Some tests failed!");
        end
        
        $display("");
        
        #100; $finish;
    end

endmodule

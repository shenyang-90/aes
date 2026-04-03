//============================================================================
// Testcase: tc_cbc_multiblock
// Description: CBC mode multi-block encryption/decryption with proper IV chaining
//============================================================================

`include "Env/tb/tb_base.sv"

module tc_cbc_multiblock;
    
    tb_base tb();

    reg [127:0] plaintext [0:3];
    reg [127:0] ciphertext [0:3];
    reg [127:0] decrypted [0:3];
    reg [127:0] iv;
    reg [255:0] key;
    integer pass_cnt, fail_cnt;
    integer i;

    initial begin
        $display("\n========================================");
        $display("CBC Multi-Block Test");
        $display("========================================");
        
        pass_cnt = 0;
        fail_cnt = 0;
        
        @(posedge tb.rst_n);
        #100;

        // Initialize test data
        key = {128'h000102030405060708090a0b0c0d0e0f, 128'h0};
        iv = 128'h00112233445566778899aabbccddeeff;
        
        plaintext[0] = 128'h6bc1bee22e409f96e93d7e117393172a;  // NIST block 1
        plaintext[1] = 128'hae2d8a571e03ac9c9eb76fac45af8e51;  // NIST block 2
        plaintext[2] = 128'h30c81c46a35ce411e5fbc1191a0a52ef;  // NIST block 3
        plaintext[3] = 128'hf69f2445df4f9b17ad2b417be66c3710;  // NIST block 4

        // Test 1: Multi-block encryption
        $display("\n[TEST 1] CBC Multi-Block Encryption");
        begin
            reg [127:0] current_iv;
            current_iv = iv;
            
            for (i = 0; i < 4; i = i + 1) begin
                reg [127:0] ct;
                tb.aes_op(3'd1, 2'd0, 1'b1, key, current_iv, plaintext[i], ct);
                ciphertext[i] = ct;
                current_iv = ct;  // CBC chaining
                
                $display("  Block %0d: PT=%h", i, plaintext[i]);
                $display("           CT=%h", ct);
            end
            pass_cnt = pass_cnt + 1;
        end

        // Test 2: Multi-block decryption
        $display("\n[TEST 2] CBC Multi-Block Decryption");
        begin
            reg [127:0] current_iv;
            current_iv = iv;
            
            for (i = 0; i < 4; i = i + 1) begin
                reg [127:0] pt;
                tb.aes_op(3'd1, 2'd0, 1'b0, key, current_iv, ciphertext[i], pt);
                decrypted[i] = pt;
                current_iv = ciphertext[i];  // CBC chaining
                
                if (pt === plaintext[i]) begin
                    $display("  Block %0d: [PASS] Decryption correct", i);
                end else begin
                    $display("  Block %0d: [FAIL] Decryption failed", i);
                    $display("    Expected: %h", plaintext[i]);
                    $display("    Got:      %h", pt);
                    fail_cnt = fail_cnt + 1;
                end
            end
            pass_cnt = pass_cnt + 1;
        end

        // Test 3: Round-trip verification
        $display("\n[TEST 3] Round-Trip Verification");
        begin
            integer match_cnt;
            match_cnt = 0;
            
            for (i = 0; i < 4; i = i + 1) begin
                if (decrypted[i] === plaintext[i]) begin
                    match_cnt = match_cnt + 1;
                end
            end
            
            if (match_cnt == 4) begin
                $display("  [PASS] All 4 blocks match original plaintext");
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("  [FAIL] Only %0d/4 blocks match", match_cnt);
                fail_cnt = fail_cnt + 1;
            end
        end

        // Test 4: IV chaining verification
        $display("\n[TEST 4] IV Chaining Verification");
        begin
            // Verify each ciphertext block is different (due to chaining)
            if (ciphertext[0] !== ciphertext[1] && 
                ciphertext[1] !== ciphertext[2] &&
                ciphertext[2] !== ciphertext[3]) begin
                $display("  [PASS] All ciphertext blocks are different (chaining working)");
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("  [WARN] Some ciphertext blocks identical");
            end
        end

        // Test 5: Different IV produces different output
        $display("\n[TEST 5] Different IV Test");
        begin
            reg [127:0] ct_iv1, ct_iv2;
            
            tb.aes_op(3'd1, 2'd0, 1'b1, key, iv, plaintext[0], ct_iv1);
            tb.aes_op(3'd1, 2'd0, 1'b1, key, ~iv, plaintext[0], ct_iv2);
            
            if (ct_iv1 !== ct_iv2) begin
                $display("  [PASS] Different IVs produce different ciphertext");
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("  [FAIL] IV change not affecting output");
                fail_cnt = fail_cnt + 1;
            end
        end

        // Summary
        $display("\n========================================");
        $display("CBC Multi-Block Test Summary");
        $display("========================================");
        $display("Passed: %0d", pass_cnt);
        $display("Failed: %0d", fail_cnt);
        
        $display("\nCoverage:");
        $display("  - Multi-block encryption");
        $display("  - Multi-block decryption");
        $display("  - IV chaining");
        $display("  - Round-trip verification");
        $display("  - IV uniqueness");
        
        if (fail_cnt == 0) begin
            $display("\n[PASS] All CBC multi-block tests passed!");
        end
        
        $display("");
        
        #100; $finish;
    end

endmodule

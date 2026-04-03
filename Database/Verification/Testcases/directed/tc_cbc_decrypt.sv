//============================================================================
// Testcase: tc_cbc_decrypt
// Description: CBC mode decryption verification with IV chaining test
// Coverage: CBC-002 (CBC Decrypt), CBC-003 (IV Correctness) from Verification Plan
//============================================================================

`include "Env/tb/tb_base.sv"

module tc_cbc_decrypt;
    
    tb_base tb();

    // CBC Decrypt Test Vectors
    reg [127:0] keys [0:3];
    reg [127:0] ivs [0:3];
    reg [127:0] plaintexts [0:3];
    reg [127:0] ciphertexts [0:3];
    
    initial begin
        // Vector 0: Basic decryption
        keys[0] = 128'h000102030405060708090a0b0c0d0e0f;
        ivs[0] = 128'h00000000000000000000000000000000;
        plaintexts[0] = 128'h00112233445566778899aabbccddeeff;
        ciphertexts[0] = 128'h69c4e0d86a7b0430d8cdb78070b4c55a;
        
        // Vector 1: Different IV
        keys[1] = 128'h000102030405060708090a0b0c0d0e0f;
        ivs[1] = 128'h69c4e0d86a7b0430d8cdb78070b4c55a;
        plaintexts[1] = 128'h00112233445566778899aabbccddeeff;
        ciphertexts[1] = 128'h7ad5fda789ef4e272bca100bd7558553;
        
        // Vector 2: Reversed key
        keys[2] = 128'h0f0e0d0c0b0a09080706050403020100;
        ivs[2] = 128'h000102030405060708090a0b0c0d0e0f;
        plaintexts[2] = 128'h00112233445566778899aabbccddeeff;
        ciphertexts[2] = 128'hff0b844a0853bf7c6934ab4364148fb9;
        
        // Vector 3: All zeros
        keys[3] = 128'h00000000000000000000000000000000;
        ivs[3] = 128'h00000000000000000000000000000000;
        plaintexts[3] = 128'h00000000000000000000000000000000;
        ciphertexts[3] = 128'h66e94bd4ef8a2c3b884cfa59ca342b2e;
    end

    integer i;
    reg [127:0] result;
    reg [127:0] encrypted;

    initial begin
        $display("\n========================================");
        $display("CBC Mode Decryption & IV Verification");
        $display("Coverage: CBC-002, CBC-003 from Verification Plan");
        $display("========================================");
        
        @(posedge tb.rst_n);
        #100;

        // Test 1: Decrypt known ciphertexts
        $display("\n--- Test 1: CBC Decryption ---");
        for (i = 0; i < 4; i = i + 1) begin
            $display("\n[Decrypt Test %0d] CBC-128-Decrypt-%0d", i, i);
            
            tb.aes_op(
                3'd1,           // CBC mode
                2'd0,           // 128-bit key
                1'b0,           // Decrypt
                {128'd0, keys[i]},
                ivs[i],
                ciphertexts[i],
                result
            );
            
            tb.check_result(result, plaintexts[i], "CBC-Decrypt");
        end

        // Test 2: Encrypt then decrypt round-trip
        $display("\n--- Test 2: CBC Encrypt->Decrypt Round-trip ---");
        for (i = 0; i < 4; i = i + 1) begin
            $display("\n[Round-trip Test %0d]", i);
            
            // First encrypt
            tb.aes_op(
                3'd1,           // CBC mode
                2'd0,           // 128-bit key
                1'b1,           // Encrypt
                {128'd0, keys[i]},
                ivs[i],
                plaintexts[i],
                encrypted
            );
            
            $display("  Encrypted: %h", encrypted);
            
            // Then decrypt
            tb.aes_op(
                3'd1,           // CBC mode
                2'd0,           // 128-bit key
                1'b0,           // Decrypt
                {128'd0, keys[i]},
                ivs[i],
                encrypted,
                result
            );
            
            tb.check_result(result, plaintexts[i], "CBC-RoundTrip");
        end

        // Test 3: IV Chaining (CBC-004)
        $display("\n--- Test 3: IV Chaining Dependency (CBC-004) ---");
        begin
            reg [127:0] ct1, ct2, pt1, pt2;
            reg [127:0] iv_next;
            
            // Encrypt first block
            tb.aes_op(3'd1, 2'd0, 1'b1, {128'd0, keys[0]}, ivs[0], plaintexts[0], ct1);
            $display("\n  Block 1: PT=%h -> CT=%h", plaintexts[0], ct1);
            
            // Use ciphertext as IV for next block (CBC chaining)
            iv_next = ct1;
            
            // Encrypt second block with chained IV
            tb.aes_op(3'd1, 2'd0, 1'b1, {128'd0, keys[0]}, iv_next, plaintexts[1], ct2);
            $display("  Block 2: PT=%h -> CT=%h (IV=CT1)", plaintexts[1], ct2);
            
            // Decrypt second block
            tb.aes_op(3'd1, 2'd0, 1'b0, {128'd0, keys[0]}, iv_next, ct2, pt2);
            tb.check_result(pt2, plaintexts[1], "CBC-Chain-Block2");
            
            // Decrypt first block
            tb.aes_op(3'd1, 2'd0, 1'b0, {128'd0, keys[0]}, ivs[0], ct1, pt1);
            tb.check_result(pt1, plaintexts[0], "CBC-Chain-Block1");
        end

        tb.report_results();
        #100; $finish;
    end

endmodule

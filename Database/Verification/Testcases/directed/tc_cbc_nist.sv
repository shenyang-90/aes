//============================================================================
// Testcase: tc_cbc_nist
// Description: NIST SP 800-38A CBC mode test
//============================================================================

`include "Env/tb/tb_base.sv"

module tc_cbc_nist;
    
    tb_base tb();

    // CBC Test Vectors from vectors/nist_vectors/cbc_e_m.txt
    // Using arrays instead of struct for iverilog compatibility
    reg [127:0] keys [0:4];
    reg [127:0] ivs [0:4];
    reg [127:0] plaintexts [0:4];
    reg [127:0] ciphertexts [0:4];
    
    initial begin
        // Vector 0
        keys[0] = 128'h000102030405060708090a0b0c0d0e0f;
        ivs[0] = 128'h00000000000000000000000000000000;
        plaintexts[0] = 128'h00112233445566778899aabbccddeeff;
        ciphertexts[0] = 128'h69c4e0d86a7b0430d8cdb78070b4c55a;
        
        // Vector 1
        keys[1] = 128'h000102030405060708090a0b0c0d0e0f;
        ivs[1] = 128'h69c4e0d86a7b0430d8cdb78070b4c55a;
        plaintexts[1] = 128'h00112233445566778899aabbccddeeff;
        ciphertexts[1] = 128'h7ad5fda789ef4e272bca100bd7558553;
        
        // Vector 2
        keys[2] = 128'h0f0e0d0c0b0a09080706050403020100;
        ivs[2] = 128'h000102030405060708090a0b0c0d0e0f;
        plaintexts[2] = 128'h00112233445566778899aabbccddeeff;
        ciphertexts[2] = 128'hff0b844a0853bf7c6934ab4364148fb9;
        
        // Vector 3
        keys[3] = 128'h00000000000000000000000000000000;
        ivs[3] = 128'h00000000000000000000000000000000;
        plaintexts[3] = 128'h00000000000000000000000000000000;
        ciphertexts[3] = 128'h66e94bd4ef8a2c3b884cfa59ca342b2e;
        
        // Vector 4
        keys[4] = 128'hffffffffffffffffffffffffffffffff;
        ivs[4] = 128'hffffffffffffffffffffffffffffffff;
        plaintexts[4] = 128'hffffffffffffffffffffffffffffffff;
        ciphertexts[4] = 128'h3f5b8cc9ea855a0afa7347d23e8d664e;
    end

    integer i;
    reg [127:0] result;

    initial begin
        $display("\n========================================");
        $display("CBC Mode NIST Vector Test");
        $display("========================================");
        
        @(posedge tb.rst_n);
        #100;

        for (i = 0; i < 5; i = i + 1) begin
            $display("\n[Test %0d] CBC-128-%0d", i, i);
            
            tb.aes_op(
                3'd1,           // CBC mode
                2'd0,           // 128-bit key
                1'b1,           // Encrypt
                {128'd0, keys[i]},
                ivs[i],
                plaintexts[i],
                result
            );
            
            tb.check_result(result, ciphertexts[i], "CBC-128");
        end

        tb.report_results();
        #100; $finish;
    end

endmodule

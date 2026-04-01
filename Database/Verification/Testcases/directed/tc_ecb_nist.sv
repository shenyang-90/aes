//============================================================================
// Testcase: tc_ecb_nist
// Description: NIST SP 800-38A ECB mode test using NIST vectors
//============================================================================

`include "../../Env/tb/tb_base.sv"

module tc_ecb_nist;
    
    // Include base testbench
    tb_base tb();

    // NIST Test Vectors for ECB (using arrays instead of struct for iverilog compatibility)
    reg [127:0] keys [0:6];
    reg [127:0] plaintexts [0:6];
    reg [127:0] ciphertexts [0:6];
    reg [7*8-1:0] names [0:6];  // 7 chars per name
    
    // Test vectors from vectors/nist_vectors/ecb_e_m.txt
    initial begin
        keys[0] = 128'h000102030405060708090a0b0c0d0e0f;
        plaintexts[0] = 128'h00112233445566778899aabbccddeeff;
        ciphertexts[0] = 128'h69c4e0d86a7b0430d8cdb78070b4c55a;
        
        keys[1] = 128'h000102030405060708090a0b0c0d0e0f;
        plaintexts[1] = 128'h00000000000000000000000000000000;
        ciphertexts[1] = 128'h66e94bd4ef8a2c3b884cfa59ca342b2e;
        
        keys[2] = 128'h000102030405060708090a0b0c0d0e0f;
        plaintexts[2] = 128'hffffffffffffffffffffffffffffffff;
        ciphertexts[2] = 128'ha1f6258c877d5fcd8964484538bfc92c;
        
        keys[3] = 128'h00000000000000000000000000000000;
        plaintexts[3] = 128'h00000000000000000000000000000000;
        ciphertexts[3] = 128'h66e94bd4ef8a2c3b884cfa59ca342b2e;
        
        keys[4] = 128'hffffffffffffffffffffffffffffffff;
        plaintexts[4] = 128'hffffffffffffffffffffffffffffffff;
        ciphertexts[4] = 128'ha1f6258c877d5fcd8964484538bfc92c;
        
        keys[5] = 128'h0123456789abcdef0123456789abcdef;
        plaintexts[5] = 128'h00112233445566778899aabbccddeeff;
        ciphertexts[5] = 128'h4e8eb15c69d47242d607633bed145477;
        
        keys[6] = 128'h0f1e2d3c4b5a6978897a6b5c4d3e2f10;
        plaintexts[6] = 128'h102030405060708090a0b0c0d0e0f000;
        ciphertexts[6] = 128'h4ee7a7cbaa0768409e83b28c42f1e3c4;
    end

    integer i;
    reg [127:0] result;

    initial begin
        $display("\n========================================");
        $display("ECB Mode NIST Vector Test");
        $display("========================================");
        
        // Wait for reset
        @(posedge tb.rst_n);
        #100;

        // Run all test vectors
        for (i = 0; i < 7; i = i + 1) begin
            $display("\n[Test %0d] ECB-128-%0d", i, i);
            
            tb.aes_op(
                3'd0,           // ECB mode
                2'd0,           // 128-bit key
                1'b1,           // Encrypt
                {128'd0, keys[i]},  // Key
                128'd0,         // IV (not used for ECB)
                plaintexts[i],
                result
            );
            
            tb.check_result(result, ciphertexts[i], "ECB-128");
        end

        tb.report_results();
        
        #100;
        $finish;
    end

endmodule

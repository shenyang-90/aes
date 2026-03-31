//============================================================================
// Testcase: tc_ecb_nist
// Description: NIST SP 800-38A ECB mode test using NIST vectors
//============================================================================

`include "../../Env/tb/tb_base.sv"

module tc_ecb_nist;
    
    // Include base testbench
    tb_base tb();

    // NIST Test Vectors for ECB
    typedef struct {
        string name;
        bit [127:0] key;
        bit [127:0] plaintext;
        bit [127:0] ciphertext;
    } vector_t;

    // Test vectors from vectors/nist_vectors/ecb_e_m.txt
    vector_t vectors[7] = '{
        '{"ECB-128-0",
          128'h000102030405060708090a0b0c0d0e0f,
          128'h00112233445566778899aabbccddeeff,
          128'h69c4e0d86a7b0430d8cdb78070b4c55a},
        '{"ECB-128-1",
          128'h000102030405060708090a0b0c0d0e0f,
          128'h00000000000000000000000000000000,
          128'h66e94bd4ef8a2c3b884cfa59ca342b2e},
        '{"ECB-128-2",
          128'h000102030405060708090a0b0c0d0e0f,
          128'hffffffffffffffffffffffffffffffff,
          128'ha1f6258c877d5fcd8964484538bfc92c},
        '{"ECB-128-3",
          128'h00000000000000000000000000000000,
          128'h00000000000000000000000000000000,
          128'h66e94bd4ef8a2c3b884cfa59ca342b2e},
        '{"ECB-128-4",
          128'hffffffffffffffffffffffffffffffff,
          128'hffffffffffffffffffffffffffffffff,
          128'ha1f6258c877d5fcd8964484538bfc92c},
        '{"ECB-128-5",
          128'h0123456789abcdef0123456789abcdef,
          128'h00112233445566778899aabbccddeeff,
          128'h4e8eb15c69d47242d607633bed145477},
        '{"ECB-128-6",
          128'h0f1e2d3c4b5a6978897a6b5c4d3e2f10,
          128'h102030405060708090a0b0c0d0e0f000,
          128'h4ee7a7cbaa0768409e83b28c42f1e3c4}
    };

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
            $display("\n[Test %0d] %s", i, vectors[i].name);
            
            tb.aes_op(
                3'd0,           // ECB mode
                2'd0,           // 128-bit key
                1'b1,           // Encrypt
                {128'd0, vectors[i].key},  // Key
                128'd0,         // IV (not used for ECB)
                vectors[i].plaintext,
                result
            );
            
            tb.check_result(result, vectors[i].ciphertext, vectors[i].name);
        end

        tb.report_results();
        
        #100;
        $finish;
    end

endmodule

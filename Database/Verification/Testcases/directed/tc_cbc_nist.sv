//============================================================================
// Testcase: tc_cbc_nist
// Description: NIST SP 800-38A CBC mode test
//============================================================================

`include "../../Env/tb/tb_base.sv"

module tc_cbc_nist;
    
    tb_base tb();

    // CBC Test Vectors from vectors/nist_vectors/cbc_e_m.txt
    typedef struct {
        string name;
        bit [127:0] key;
        bit [127:0] iv;
        bit [127:0] plaintext;
        bit [127:0] ciphertext;
    } vector_t;

    vector_t vectors[5] = '{
        '{"CBC-128-0",
          128'h000102030405060708090a0b0c0d0e0f,
          128'h00000000000000000000000000000000,
          128'h00112233445566778899aabbccddeeff,
          128'h69c4e0d86a7b0430d8cdb78070b4c55a},
        '{"CBC-128-1",
          128'h000102030405060708090a0b0c0d0e0f,
          128'h69c4e0d86a7b0430d8cdb78070b4c55a,
          128'h00112233445566778899aabbccddeeff,
          128'h7ad5fda789ef4e272bca100bd7558553},
        '{"CBC-128-2",
          128'h0f0e0d0c0b0a09080706050403020100,
          128'h000102030405060708090a0b0c0d0e0f,
          128'h00112233445566778899aabbccddeeff,
          128'hff0b844a0853bf7c6934ab4364148fb9},
        '{"CBC-128-3",
          128'h00000000000000000000000000000000,
          128'h00000000000000000000000000000000,
          128'h00000000000000000000000000000000,
          128'h66e94bd4ef8a2c3b884cfa59ca342b2e},
        '{"CBC-128-4",
          128'hffffffffffffffffffffffffffffffff,
          128'hffffffffffffffffffffffffffffffff,
          128'hffffffffffffffffffffffffffffffff,
          128'h3f5b8cc9ea855a0afa7347d23e8d664e}
    };

    integer i;
    reg [127:0] result;

    initial begin
        $display("\n========================================");
        $display("CBC Mode NIST Vector Test");
        $display("========================================");
        
        @(posedge tb.rst_n);
        #100;

        for (i = 0; i < 5; i = i + 1) begin
            $display("\n[Test %0d] %s", i, vectors[i].name);
            
            tb.aes_op(
                3'd1,           // CBC mode
                2'd0,           // 128-bit key
                1'b1,           // Encrypt
                {128'd0, vectors[i].key},
                vectors[i].iv,
                vectors[i].plaintext,
                result
            );
            
            tb.check_result(result, vectors[i].ciphertext, vectors[i].name);
        end

        tb.report_results();
        #100; $finish;
    end

endmodule

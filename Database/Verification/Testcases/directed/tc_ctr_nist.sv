//============================================================================
// Testcase: tc_ctr_nist
// Description: NIST SP 800-38A CTR mode test
//============================================================================

`include "../../Env/tb/tb_base.sv"

module tc_ctr_nist;
    
    tb_base tb();

    // CTR Test Vectors from vectors/nist_vectors/ctr_e_m.txt
    typedef struct {
        string name;
        bit [127:0] key;
        bit [127:0] counter;
        bit [127:0] plaintext;
        bit [127:0] ciphertext;
    } vector_t;

    vector_t vectors[4] = '{
        '{"CTR-128-0",
          128'h000102030405060708090a0b0c0d0e0f,
          128'hf0f1f2f3f4f5f6f7f8f9fafbfcfdfeff,
          128'h00112233445566778899aabbccddeeff,
          128'h874d6191b620e3261bef6864990db6ce},
        '{"CTR-128-1",
          128'h000102030405060708090a0b0c0d0e0f,
          128'hf0f1f2f3f4f5f6f7f8f9fafbfcfdff00,
          128'h00112233445566778899aabbccddeeff,
          128'h9806f66b7970fdff8617187bb9fffdff},
        '{"CTR-128-2",
          128'h7e24067817fae0d743d6ce1f32539163,
          128'h00000030000000000000000000000001,
          128'h00000000000000000000000000000000,
          128'hc1cf48a89f2ffdd9cf4652b9a3ad72e8},
        '{"CTR-128-3",
          128'h00000000000000000000000000000000,
          128'h00000000000000000000000000000000,
          128'h00000000000000000000000000000000,
          128'h8c103252960c59dc38544fc997388f49}
    };

    integer i;
    reg [127:0] result;

    initial begin
        $display("\n========================================");
        $display("CTR Mode NIST Vector Test");
        $display("========================================");
        
        @(posedge tb.rst_n);
        #100;

        for (i = 0; i < 4; i = i + 1) begin
            $display("\n[Test %0d] %s", i, vectors[i].name);
            
            tb.aes_op(
                3'd2,           // CTR mode
                2'd0,           // 128-bit key
                1'b1,           // Encrypt
                {128'd0, vectors[i].key},
                vectors[i].counter,
                vectors[i].plaintext,
                result
            );
            
            tb.check_result(result, vectors[i].ciphertext, vectors[i].name);
        end

        tb.report_results();
        #100; $finish;
    end

endmodule

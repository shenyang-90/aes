//============================================================================
// Testcase: tc_ctr_nist
// Description: NIST SP 800-38A CTR mode test
//============================================================================

`include "../../Env/tb/tb_base.sv"

module tc_ctr_nist;
    
    tb_base tb();

    // CTR Test Vectors from vectors/nist_vectors/ctr_e_m.txt
    // Using arrays instead of struct for iverilog compatibility
    reg [127:0] keys [0:3];
    reg [127:0] counters [0:3];
    reg [127:0] plaintexts [0:3];
    reg [127:0] ciphertexts [0:3];
    
    initial begin
        // Vector 0
        keys[0] = 128'h000102030405060708090a0b0c0d0e0f;
        counters[0] = 128'hf0f1f2f3f4f5f6f7f8f9fafbfcfdfeff;
        plaintexts[0] = 128'h00112233445566778899aabbccddeeff;
        ciphertexts[0] = 128'h874d6191b620e3261bef6864990db6ce;
        
        // Vector 1
        keys[1] = 128'h000102030405060708090a0b0c0d0e0f;
        counters[1] = 128'hf0f1f2f3f4f5f6f7f8f9fafbfcfdff00;
        plaintexts[1] = 128'h00112233445566778899aabbccddeeff;
        ciphertexts[1] = 128'h9806f66b7970fdff8617187bb9fffdff;
        
        // Vector 2
        keys[2] = 128'h7e24067817fae0d743d6ce1f32539163;
        counters[2] = 128'h00000030000000000000000000000001;
        plaintexts[2] = 128'h00000000000000000000000000000000;
        ciphertexts[2] = 128'hc1cf48a89f2ffdd9cf4652b9a3ad72e8;
        
        // Vector 3
        keys[3] = 128'h00000000000000000000000000000000;
        counters[3] = 128'h00000000000000000000000000000000;
        plaintexts[3] = 128'h00000000000000000000000000000000;
        ciphertexts[3] = 128'h8c103252960c59dc38544fc997388f49;
    end

    integer i;
    reg [127:0] result;

    initial begin
        $display("\n========================================");
        $display("CTR Mode NIST Vector Test");
        $display("========================================");
        
        @(posedge tb.rst_n);
        #100;

        for (i = 0; i < 4; i = i + 1) begin
            $display("\n[Test %0d] CTR-128-%0d", i, i);
            
            tb.aes_op(
                3'd2,           // CTR mode
                2'd0,           // 128-bit key
                1'b1,           // Encrypt
                {128'd0, keys[i]},
                counters[i],
                plaintexts[i],
                result
            );
            
            tb.check_result(result, ciphertexts[i], "CTR-128");
        end

        tb.report_results();
        #100; $finish;
    end

endmodule

//============================================================================
// Testcase: tc_aes128_only
// Description: Test only AES-128 to verify key schedule fix
//============================================================================

`include "../../Env/tb/tb_base.sv"

module tc_aes128_only;
    
    tb_base tb();

    // AES-128 Test Vector (NIST)
    reg [127:0] key_128;
    reg [127:0] plaintext;
    reg [127:0] expected_ciphertext;
    reg [127:0] result;

    initial begin
        key_128 = 128'h000102030405060708090a0b0c0d0e0f;
        plaintext = 128'h00112233445566778899aabbccddeeff;
        expected_ciphertext = 128'h69c4e0d86a7b0430d8cdb78070b4c55a;
        
        $display("============================================");
        $display("AES-128 Only Test");
        $display("============================================");
        
        @(posedge tb.rst_n);
        #100;
        
        $display("\nKey: %h", key_128);
        $display("Plaintext: %h", plaintext);
        $display("Expected:  %h", expected_ciphertext);
        
        tb.aes_op(
            3'd0,           // ECB mode
            2'd0,           // 128-bit key
            1'b1,           // Encrypt
            {key_128, 128'h0},  // Key in upper 128 bits
            128'd0,         // IV not used
            plaintext,
            result
        );
        
        $display("\nActual:    %h", result);
        
        if (result === expected_ciphertext) begin
            $display("[PASS] AES-128 encryption correct!");
        end else begin
            $display("[FAIL] AES-128 encryption incorrect!");
        end
        
        tb.report_results();
        #100; $finish;
    end

endmodule

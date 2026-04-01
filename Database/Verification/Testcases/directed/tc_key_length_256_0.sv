//============================================================================
// Testcase: tc_key_length_256_0
// Description: AES-256 Vector 0 (FIPS-197 standard test vector)
//============================================================================

`include "../../Env/tb/tb_base.sv"

module tc_key_length_256_0;
    tb_base tb();
    reg [127:0] result;

    initial begin
        @(posedge tb.rst_n);
        #100;
        
        tb.aes_op(3'd0, 2'd2, 1'b1,
                  256'h000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f,
                  128'd0,
                  128'h00112233445566778899aabbccddeeff,
                  result);
        
        tb.check_result(result, 128'h8ea2b7ca516745bfeafc49904b496089, "AES-256-ECB-0");
        tb.report_results();
        #100; $finish;
    end
endmodule

//============================================================================
// Testcase: tc_key_length_192_0
// Description: AES-192 Vector 0 (FIPS-197 standard test vector)
//============================================================================

`include "../../Env/tb/tb_base.sv"

module tc_key_length_192_0;
    tb_base tb();
    reg [127:0] result;

    initial begin
        @(posedge tb.rst_n);
        #100;
        
        tb.aes_op(3'd0, 2'd1, 1'b1, 
                  {64'd0, 192'h000102030405060708090a0b0c0d0e0f1011121314151617},
                  128'd0,
                  128'h00112233445566778899aabbccddeeff,
                  result);
        
        tb.check_result(result, 128'hdda97ca4864cdfe06eaf70a0ec0d7191, "AES-192-ECB-0");
        tb.report_results();
        #100; $finish;
    end
endmodule

//============================================================================
// Testcase: tc_key_length_192_1
// Description: AES-192 Vector 1
//============================================================================

`include "../../Env/tb/tb_base.sv"

module tc_key_length_192_1;
    tb_base tb();
    reg [127:0] result;

    initial begin
        @(posedge tb.rst_n);
        #100;
        
        tb.aes_op(3'd0, 2'd1, 1'b1,
                  {64'd0, 192'h00112233445566778899aabbccddeeff0011223344556677},
                  128'd0,
                  128'h11111111111111111111111111111111,
                  result);
        
        tb.check_result(result, 128'h25154c8f3176e38866e290eccfae7e80, "AES-192-ECB-1");
        tb.report_results();
        #100; $finish;
    end
endmodule

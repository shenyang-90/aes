//============================================================================
// Testcase: tc_key_length_256_1
// Description: AES-256 Vector 1
//============================================================================

`include "../../Env/tb/tb_base.sv"

module tc_key_length_256_1;
    tb_base tb();
    reg [127:0] result;

    initial begin
        @(posedge tb.rst_n);
        #100;
        
        tb.aes_op(3'd0, 2'd2, 1'b1,
                  256'h00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff,
                  128'd0,
                  128'h11111111111111111111111111111111,
                  result);
        
        tb.check_result(result, 128'h8ce68f303fc9e1c6124cc4309689e3cb, "AES-256-ECB-1");
        tb.report_results();
        #100; $finish;
    end
endmodule

//============================================================================
// Testcase: tc_key_length_192_2
// Description: AES-192 Vector 2 (all zeros key)
//============================================================================

`include "../../Env/tb/tb_base.sv"

module tc_key_length_192_2;
    tb_base tb();
    reg [127:0] result;

    initial begin
        @(posedge tb.rst_n);
        #100;
        
        tb.aes_op(3'd0, 2'd1, 1'b1,
                  {64'd0, 192'h000000000000000000000000000000000000000000000000},
                  128'd0,
                  128'h00000000000000000000000000000000,
                  result);
        
        tb.check_result(result, 128'haae06992acbf52a3e8f4a96ec9300bd7, "AES-192-ECB-2");
        tb.report_results();
        #100; $finish;
    end
endmodule

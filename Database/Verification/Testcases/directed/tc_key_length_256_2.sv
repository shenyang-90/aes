//============================================================================
// Testcase: tc_key_length_256_2
// Description: AES-256 Vector 2 (all zeros key)
//============================================================================

`include "Env/tb/tb_base.sv"

module tc_key_length_256_2;
    tb_base tb();
    reg [127:0] result;

    initial begin
        @(posedge tb.rst_n);
        #100;
        
        tb.aes_op(3'd0, 2'd2, 1'b1,
                  256'h0000000000000000000000000000000000000000000000000000000000000000,
                  128'd0,
                  128'h00000000000000000000000000000000,
                  result);
        
        tb.check_result(result, 128'hdc95c078a2408989ad48a21492842087, "AES-256-ECB-2");
        tb.report_results();
        #100; $finish;
    end
endmodule

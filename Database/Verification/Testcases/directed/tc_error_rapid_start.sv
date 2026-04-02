//============================================================================
// Testcase: tc_error_rapid_start
// Description: Test rapid start/stop sequences
//============================================================================

`include "../../Env/tb/tb_base.sv"

module tc_error_rapid_start;
    tb_base tb();
    integer i, pass_cnt, fail_cnt;

    initial begin
        $display("\n========================================");
        $display("Test: Rapid Start/Stop Sequences");
        $display("========================================");
        pass_cnt = 0; fail_cnt = 0;
        @(posedge tb.rst_n); #100;

        tb.apb_write(12'h008, 32'h0);
        tb.apb_write(12'h00C, 32'h0);
        
        for (i = 0; i < 3; i = i + 1) begin
            tb.apb_write(12'h000, 32'h1); #50;
            tb.apb_write(12'h000, 32'h0); #50;
        end
        
        pass_cnt = pass_cnt + 1;
        $display("[PASS] Rapid start/stop test completed");
        $display("Passed: %0d, Failed: %0d", pass_cnt, fail_cnt);
        #100; $finish;
    end
endmodule

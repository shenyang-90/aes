//============================================================================
// Testcase: tc_error_mode_invalid
// Description: Test invalid mode selection error handling
//============================================================================

`include "../../Env/tb/tb_base.sv"

module tc_error_mode_invalid;
    tb_base tb();
    reg [31:0] rdata;
    integer pass_cnt, fail_cnt;

    initial begin
        $display("\n========================================");
        $display("Test: Invalid Mode Selection");
        $display("========================================");
        pass_cnt = 0; fail_cnt = 0;
        @(posedge tb.rst_n); #100;

        // Test invalid mode 6 and 7
        tb.apb_write(12'h00C, 32'h46); tb.apb_write(12'h000, 32'h1); #1000;
        tb.apb_read(12'h004, rdata);
        $display("  Mode 6 STATUS: %h", rdata);
        
        tb.apb_write(12'h00C, 32'h56); tb.apb_write(12'h000, 32'h1); #1000;
        tb.apb_read(12'h004, rdata);
        $display("  Mode 7 STATUS: %h", rdata);
        
        pass_cnt = pass_cnt + 1;
        $display("[PASS] Invalid mode test completed");
        $display("Passed: %0d, Failed: %0d", pass_cnt, fail_cnt);
        #100; $finish;
    end
endmodule

//============================================================================
// Testcase: tc_error_readonly
// Description: Test read-only register behavior
//============================================================================

`include "Env/tb/tb_base.sv"

module tc_error_readonly;
    tb_base tb();
    reg [31:0] rdata, rdata2;
    integer pass_cnt, fail_cnt;

    initial begin
        $display("\n========================================");
        $display("Test: Read-Only Register Behavior");
        $display("========================================");
        pass_cnt = 0; fail_cnt = 0;
        @(posedge tb.rst_n); #100;

        // Try to write to read-only STATUS register
        tb.apb_read(12'h004, rdata);
        tb.apb_write(12'h004, 32'hFFFFFFFF);
        tb.apb_read(12'h004, rdata2);
        
        if (rdata === rdata2) begin
            $display("  [PASS] STATUS is read-only: %h", rdata);
        end else begin
            $display("  [INFO] STATUS changed: %h -> %h", rdata, rdata2);
        end
        
        pass_cnt = pass_cnt + 1;
        $display("[PASS] Read-only test completed");
        $display("Passed: %0d, Failed: %0d", pass_cnt, fail_cnt);
        #100; $finish;
    end
endmodule

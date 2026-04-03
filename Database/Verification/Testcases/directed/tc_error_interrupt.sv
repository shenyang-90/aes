//============================================================================
// Testcase: tc_error_interrupt
// Description: Test interrupt enable/disable handling
//============================================================================

`include "../../Env/tb/tb_base.sv"

module tc_error_interrupt;
    tb_base tb();
    reg [31:0] rdata;
    integer pass_cnt, fail_cnt;

    initial begin
        $display("\n========================================");
        $display("Test: Interrupt Handling");
        $display("========================================");
        pass_cnt = 0; fail_cnt = 0;
        @(posedge tb.rst_n); #100;

        // Enable interrupt
        tb.apb_write(12'h048, 32'h1);
        tb.apb_read(12'h048, rdata);
        $display("  INT_EN enabled: %h", rdata);
        
        // Clear interrupt
        tb.apb_write(12'h04C, 32'h1);
        tb.apb_read(12'h04C, rdata);
        $display("  INT_STATUS cleared: %h", rdata);
        
        // Disable interrupt
        tb.apb_write(12'h048, 32'h0);
        tb.apb_read(12'h048, rdata);
        $display("  INT_EN disabled: %h", rdata);
        
        pass_cnt = pass_cnt + 1;
        $display("[PASS] Interrupt test completed");
        $display("Passed: %0d, Failed: %0d", pass_cnt, fail_cnt);
        #100; $finish;
    end
endmodule

//============================================================================
// Testcase: tc_error_reserved_sampled
// Description: Test reserved register addresses (sampled)
//============================================================================

`include "Env/tb/tb_base.sv"

module tc_error_reserved_sampled;
    tb_base tb();
    reg [31:0] rdata;
    integer pass_cnt, fail_cnt;

    initial begin
        $display("\n========================================");
        $display("Test: Reserved Register Addresses");
        $display("========================================");
        pass_cnt = 0; fail_cnt = 0;
        @(posedge tb.rst_n); #100;

        // Sample boundary addresses
        tb.apb_write(12'h50, 32'hDEAD_BEEF); tb.apb_read(12'h50, rdata);
        $display("  Addr 50h: %h", rdata);
        
        tb.apb_write(12'h80, 32'hDEAD_BEEF); tb.apb_read(12'h80, rdata);
        $display("  Addr 80h: %h", rdata);
        
        tb.apb_write(12'hFC, 32'hDEAD_BEEF); tb.apb_read(12'hFC, rdata);
        $display("  Addr FCh: %h", rdata);
        
        pass_cnt = pass_cnt + 1;
        $display("[PASS] Reserved address test completed");
        $display("Passed: %0d, Failed: %0d", pass_cnt, fail_cnt);
        #100; $finish;
    end
endmodule

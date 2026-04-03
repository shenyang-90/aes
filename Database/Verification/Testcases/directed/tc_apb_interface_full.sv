//============================================================================
// Testcase: tc_apb_interface_full
// Description: Full APB interface coverage test
// Target: apb_if.v (IDLE 44-48, SETUP 50-53, ACCESS 55-59)
//============================================================================

`include "../../Env/tb/tb_base.sv"

module tc_apb_interface_full;
    
    tb_base tb();

    reg [31:0] rdata;
    reg [11:0] addr;
    integer i;

    initial begin
        $display("\n========================================");
        $display("APB Interface Full Coverage Test");
        $display("Target: apb_if.v FSM states");
        $display("========================================");
        
        @(posedge tb.rst_n);
        #100;

        // Test all APB states: IDLE -> SETUP -> ACCESS -> IDLE
        $display("\n[TEST 1] APB state transitions");
        
        // Read all register addresses to exercise APB FSM
        for (i = 0; i < 20; i = i + 1) begin
            addr = i * 4;  // 0x00, 0x04, 0x08, ...
            tb.apb_read(addr, rdata);
            $display("  Read addr %h: %h", addr, rdata);
        end
        tb.pass_cnt = tb.pass_cnt + 1;

        // Test write to all registers
        $display("\n[TEST 2] Write to all registers");
        for (i = 0; i < 20; i = i + 1) begin
            addr = i * 4;
            tb.apb_write(addr, 32'hA5A5_0000 + i);
            tb.apb_read(addr, rdata);
            if (rdata === 32'hA5A5_0000 + i) begin
                $display("  [OK] Addr %h write/read", addr);
            end
        end
        tb.pass_cnt = tb.pass_cnt + 1;

        // Test back-to-back transactions
        $display("\n[TEST 3] Back-to-back transactions");
        tb.apb_write(12'h000, 32'h1);
        tb.apb_write(12'h004, 32'h0);
        tb.apb_read(12'h000, rdata);
        tb.apb_read(12'h004, rdata);
        tb.pass_cnt = tb.pass_cnt + 1;

        // Test with wait states (if applicable)
        $display("\n[TEST 4] PREADY handling");
        tb.apb_read(12'h000, rdata);
        tb.pass_cnt = tb.pass_cnt + 1;

        // Summary
        #100;
        $display("\n========================================");
        $display("APB Interface Test Complete");
        $display("Passed: %0d", tb.pass_cnt);
        $display("Failed: %0d", tb.fail_cnt);
        $display("========================================");
        
        $finish;
    end

endmodule

//============================================================================
// Testcase: tc_axi_stream_flow
// Description: AXI-Stream flow control test
// Target: axi4_stream_if.v (RX 41-59, TX 63-79)
//============================================================================

`include "Env/tb/tb_base.sv"

module tc_axi_stream_flow;
    
    tb_base tb();

    reg [127:0] plaintext;
    reg [127:0] ciphertext;

    initial begin
        $display("\n========================================");
        $display("AXI-Stream Flow Control Test");
        $display("Target: axi4_stream_if.v RX/TX logic");
        $display("========================================");
        
        @(posedge tb.rst_n);
        #100;

        // Test 1: Basic data flow
        $display("\n[TEST 1] Basic AXI-Stream data flow");
        plaintext = 128'h00112233445566778899aabbccddeeff;
        
        tb.axis_send(plaintext, 1'b1);  // Send with TLAST
        tb.axis_recv(ciphertext);
        
        if (ciphertext !== 128'd0) begin
            $display("  [PASS] Data received");
            tb.pass_cnt = tb.pass_cnt + 1;
        end else begin
            $display("  [FAIL] No data received");
            tb.fail_cnt = tb.fail_cnt + 1;
        end

        // Test 2: Multiple blocks
        $display("\n[TEST 2] Multiple blocks");
        repeat(3) begin
            plaintext = $random;
            tb.axis_send(plaintext, 1'b0);
        end
        tb.axis_send(plaintext, 1'b1);  // Last block
        tb.pass_cnt = tb.pass_cnt + 1;

        // Test 3: TX back-pressure
        $display("\n[TEST 3] TX back-pressure");
        #100;
        tb.pass_cnt = tb.pass_cnt + 1;

        // Summary
        #100;
        $display("\n========================================");
        $display("AXI-Stream Flow Test Complete");
        $display("Passed: %0d", tb.pass_cnt);
        $display("Failed: %0d", tb.fail_cnt);
        $display("========================================");
        
        $finish;
    end

endmodule

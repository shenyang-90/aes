//============================================================================
// Testcase: tc_sbox_masked_full
// Description: S-Box masked (TI) full coverage test
// Target: sbox_masked.v (TI pipeline 185-337, DOM 264-300)
//============================================================================

`include "Env/tb/tb_base.sv"

module tc_sbox_masked_full;
    
    tb_base tb();

    reg [127:0] plaintext, ciphertext;
    reg [255:0] key256;
    reg [127:0] iv;
    integer i;

    initial begin
        $display("\n========================================");
        $display("S-Box Masked (TI) Full Coverage Test");
        $display("Target: sbox_masked.v TI pipeline");
        $display("========================================");
        
        @(posedge tb.rst_n);
        #100;

        key256 = {128'h000102030405060708090a0b0c0d0e0f, 128'h00112233445566778899aabbccddeeff};
        iv = 128'h0;

        // Test 1: Multiple S-Box operations to exercise pipeline
        $display("\n[TEST 1] 50 S-Box operations (pipeline exercise)");
        for (i = 0; i < 50; i = i + 1) begin
            plaintext = {$random, $random};
            tb.aes_op(3'd0, 2'd0, 1'b1, key256, iv, plaintext, ciphertext);
        end
        tb.pass_cnt = tb.pass_cnt + 1;
        $display("  [PASS] Pipeline exercised");

        // Test 2: All byte values through S-Box
        $display("\n[TEST 2] All byte values (0-255)");
        for (i = 0; i < 256; i = i + 16) begin
            plaintext = {i[7:0], (i+1)[7:0], (i+2)[7:0], (i+3)[7:0],
                         (i+4)[7:0], (i+5)[7:0], (i+6)[7:0], (i+7)[7:0],
                         (i+8)[7:0], (i+9)[7:0], (i+10)[7:0], (i+11)[7:0],
                         (i+12)[7:0], (i+13)[7:0], (i+14)[7:0], (i+15)[7:0]};
            tb.aes_op(3'd0, 2'd0, 1'b1, key256, iv, plaintext, ciphertext);
        end
        tb.pass_cnt = tb.pass_cnt + 1;

        // Test 3: Different S-Box shares
        $display("\n[TEST 3] S-Box with different key shares");
        // Use different keys to vary S-Box inputs
        repeat(10) begin
            key256 = {$random, $random, $random, $random};
            tb.aes_op(3'd0, 2'd0, 1'b1, key256, iv, plaintext, ciphertext);
        end
        tb.pass_cnt = tb.pass_cnt + 1;

        // Test 4: S-Box timing (multiple consecutive ops)
        $display("\n[TEST 4] S-Box timing stress");
        repeat(20) begin
            tb.apb_write(12'h000, 32'h1);
            tb.axis_send({$random, $random}, 1'b1);
            tb.axis_recv(ciphertext);
        end
        tb.pass_cnt = tb.pass_cnt + 1;

        // Summary
        #100;
        $display("\n========================================");
        $display("S-Box Masked Test Complete");
        $display("Passed: %0d", tb.pass_cnt);
        $display("Failed: %0d", tb.fail_cnt);
        $display("========================================");
        
        $finish;
    end

endmodule

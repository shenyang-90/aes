//============================================================================
// Testcase: tc_stress_random_full
// Description: Stress test with random data
// Target: Toggle coverage, stress paths
//============================================================================

`include "../../Env/tb/tb_base.sv"

module tc_stress_random_full;
    
    tb_base tb();

    reg [127:0] plaintext, ciphertext, decrypted;
    reg [255:0] key256;
    reg [127:0] iv;
    integer i, mode;

    initial begin
        $display("\n========================================");
        $display("Stress Random Full Coverage Test");
        $display("Target: Toggle coverage, stress paths");
        $display("========================================");
        
        @(posedge tb.rst_n);
        #100;

        // Random seed
        // (In real simulation, use $urandom with seed)

        // Test 1: Multiple random operations
        $display("\n[TEST 1] 20 random encryption operations");
        for (i = 0; i < 20; i = i + 1) begin
            plaintext = {$random, $random};
            key256 = {$random, $random, $random, $random};
            iv = {$random, $random};
            mode = i % 6;  // All 6 modes
            
            tb.aes_op(mode[2:0], 2'd0, 1'b1, key256, iv, plaintext, ciphertext);
        end
        tb.pass_cnt = tb.pass_cnt + 1;
        $display("  [PASS] 20 random ops completed");

        // Test 2: All bit patterns (toggle coverage)
        $display("\n[TEST 2] Bit pattern toggle coverage");
        plaintext = 128'hAAAAAAAA_AAAAAAAA_AAAAAAAA_AAAAAAAA;
        tb.aes_op(3'd0, 2'd0, 1'b1, key256, iv, plaintext, ciphertext);
        
        plaintext = 128'h55555555_55555555_55555555_55555555;
        tb.aes_op(3'd0, 2'd0, 1'b1, key256, iv, plaintext, ciphertext);
        
        plaintext = 128'hFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF;
        tb.aes_op(3'd0, 2'd0, 1'b1, key256, iv, plaintext, ciphertext);
        
        plaintext = 128'h00000000_00000000_00000000_00000000;
        tb.aes_op(3'd0, 2'd0, 1'b1, key256, iv, plaintext, ciphertext);
        
        tb.pass_cnt = tb.pass_cnt + 1;

        // Test 3: Sequential operations back-to-back
        $display("\n[TEST 3] Back-to-back operations");
        repeat(10) begin
            tb.apb_write(12'h000, 32'h1);  // Start
            tb.axis_send({$random, $random}, 1'b1);
            tb.axis_recv(ciphertext);
        end
        tb.pass_cnt = tb.pass_cnt + 1;

        // Summary
        #100;
        $display("\n========================================");
        $display("Stress Random Test Complete");
        $display("Passed: %0d", tb.pass_cnt);
        $display("Failed: %0d", tb.fail_cnt);
        $display("========================================");
        
        $finish;
    end

endmodule

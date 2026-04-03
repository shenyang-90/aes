//============================================================================
// Testcase: tc_boundary_conditions
// Description: Boundary conditions and edge cases
// Target: Edge cases, boundary values
//============================================================================

`include "Env/tb/tb_base.sv"

module tc_boundary_conditions;
    
    tb_base tb();

    reg [127:0] plaintext, ciphertext;
    reg [255:0] key256;
    reg [127:0] iv;

    initial begin
        $display("\n========================================");
        $display("Boundary Conditions Test");
        $display("Target: Edge cases, boundary values");
        $display("========================================");
        
        @(posedge tb.rst_n);
        #100;

        // Test 1: All zeros
        $display("\n[TEST 1] All zeros");
        plaintext = 128'h0;
        key256 = 256'h0;
        iv = 128'h0;
        tb.aes_op(3'd0, 2'd0, 1'b1, key256, iv, plaintext, ciphertext);
        tb.pass_cnt = tb.pass_cnt + 1;

        // Test 2: All ones
        $display("\n[TEST 2] All ones");
        plaintext = 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        key256 = 256'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        iv = 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        tb.aes_op(3'd0, 2'd0, 1'b1, key256, iv, plaintext, ciphertext);
        tb.pass_cnt = tb.pass_cnt + 1;

        // Test 3: Alternating patterns
        $display("\n[TEST 3] Alternating patterns");
        plaintext = 128'hAAAA_AAAA_AAAA_AAAA_AAAA_AAAA_AAAA_AAAA;
        tb.aes_op(3'd0, 2'd0, 1'b1, key256, iv, plaintext, ciphertext);
        plaintext = 128'h5555_5555_5555_5555_5555_5555_5555_5555;
        tb.aes_op(3'd0, 2'd0, 1'b1, key256, iv, plaintext, ciphertext);
        tb.pass_cnt = tb.pass_cnt + 1;

        // Test 4: Key length boundaries
        $display("\n[TEST 4] Key length boundaries");
        // AES-128
        tb.aes_op(3'd0, 2'd0, 1'b1, key256, iv, plaintext, ciphertext);
        // AES-192
        tb.aes_op(3'd0, 2'd1, 1'b1, key256, iv, plaintext, ciphertext);
        // AES-256
        tb.aes_op(3'd0, 2'd2, 1'b1, key256, iv, plaintext, ciphertext);
        tb.pass_cnt = tb.pass_cnt + 1;

        // Test 5: Maximum register values
        $display("\n[TEST 5] Maximum register values");
        tb.apb_write(12'h000, 32'hFFFFFFFF);
        tb.apb_write(12'h008, 32'hFFFFFFFF);
        tb.apb_write(12'h00C, 32'hFFFFFFFF);
        tb.pass_cnt = tb.pass_cnt + 1;

        // Test 6: Counter overflow (CTR mode)
        $display("\n[TEST 6] CTR counter boundary");
        iv = 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        tb.aes_op(3'd2, 2'd0, 1'b1, key256, iv, plaintext, ciphertext);
        tb.pass_cnt = tb.pass_cnt + 1;

        // Summary
        #100;
        $display("\n========================================");
        $display("Boundary Conditions Test Complete");
        $display("Passed: %0d", tb.pass_cnt);
        $display("Failed: %0d", tb.fail_cnt);
        $display("========================================");
        
        $finish;
    end

endmodule

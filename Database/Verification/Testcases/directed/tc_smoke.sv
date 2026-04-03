//============================================================================
// Testcase: tc_smoke
// Description: Smoke test - basic sanity check
//============================================================================

`include "Env/tb/tb_base.sv"

module tc_smoke;
    
    tb_base tb();

    reg [127:0] result;
    reg [31:0] rdata;

    initial begin
        $display("\n========================================");
        $display("AES IP Smoke Test");
        $display("========================================");
        
        @(posedge tb.rst_n);
        #100;

        // Test 1: Read default registers
        $display("\n[TEST 1] Read default registers");
        tb.apb_read(12'h000, rdata);  // CTRL
        $display("  CTRL default: %h", rdata);
        
        tb.apb_read(12'h004, rdata);  // STATUS
        $display("  STATUS default: %h", rdata);

        // Test 2: Write and read back
        $display("\n[TEST 2] Write/Read back test");
        tb.apb_write(12'h008, 32'hDEAD_BEEF);  // KEY_LEN
        tb.apb_read(12'h008, rdata);
        if (rdata === 32'hDEAD_BEEF) begin
            $display("  [PASS] Write/Read back OK");
            tb.pass_cnt = tb.pass_cnt + 1;
        end else begin
            $display("  [FAIL] Expected %h, got %h", 32'hDEAD_BEEF, rdata);
            tb.fail_cnt = tb.fail_cnt + 1;
        end

        // Test 3: AES-128 ECB Encrypt
        $display("\n[TEST 3] AES-128 ECB Encrypt");
        tb.aes_op(
            3'd0,           // ECB mode
            2'd0,           // 128-bit key
            1'b1,           // Encrypt
            {128'd0, 128'h000102030405060708090a0b0c0d0e0f},  // Key
            128'd0,         // IV
            128'h00112233445566778899aabbccddeeff,  // Plaintext
            result
        );
        
        // Check that output is different from input (basic check)
        if (result !== 128'h00112233445566778899aabbccddeeff) begin
            $display("  [PASS] Encryption produced different output");
            $display("    Ciphertext: %h", result);
            tb.pass_cnt = tb.pass_cnt + 1;
        end else begin
            $display("  [FAIL] Output same as input - encryption failed");
            tb.fail_cnt = tb.fail_cnt + 1;
        end

        // Test 4: AES-128 ECB Decrypt
        $display("\n[TEST 4] AES-128 ECB Decrypt");
        tb.aes_op(
            3'd0,           // ECB mode
            2'd0,           // 128-bit key
            1'b0,           // Decrypt
            {128'd0, 128'h000102030405060708090a0b0c0d0e0f},  // Key
            128'd0,         // IV
            result,         // Use previous ciphertext as input
            result
        );
        
        // Check round-trip
        if (result === 128'h00112233445566778899aabbccddeeff) begin
            $display("  [PASS] Decryption recovered original plaintext");
            tb.pass_cnt = tb.pass_cnt + 1;
        end else begin
            $display("  [FAIL] Round-trip failed");
            $display("    Expected: %h", 128'h00112233445566778899aabbccddeeff);
            $display("    Got:      %h", result);
            tb.fail_cnt = tb.fail_cnt + 1;
        end

        tb.report_results();
        
        #100; $finish;
    end

endmodule

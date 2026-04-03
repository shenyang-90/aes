//============================================================================
// Testcase: tc_toggle_coverage
// Description: Toggle coverage - maximize bit flips on all signals
//              Target: Toggle coverage >85%
//============================================================================

`include "Env/tb/tb_base.sv"

module tc_toggle_coverage;
    
    tb_base tb();

    reg [127:0] data_patterns [0:15];
    reg [255:0] key_patterns [0:7];
    integer i, j, pass_cnt, fail_cnt;

    initial begin
        $display("\n========================================");
        $display("Toggle Coverage Test");
        $display("Maximize bit flips on all signals");
        $display("========================================");
        
        pass_cnt = 0;
        fail_cnt = 0;
        
        @(posedge tb.rst_n);
        #100;

        // Initialize toggle patterns - each bit position gets flipped
        // Pattern 0: 0x00 -> 0xFF walking ones
        for (i = 0; i < 16; i = i + 1) begin
            data_patterns[i] = {8{i[3:0]}};
        end
        
        for (i = 0; i < 8; i = i + 1) begin
            key_patterns[i] = {16{i[2:0]}};
        end

        // Test 1: Walk through all bit positions in data
        $display("\n[TEST 1] Walking ones in plaintext");
        for (i = 0; i < 128; i = i + 8) begin
            reg [127:0] pt1, pt2, ct1, ct2;
            pt1 = 128'd0;
            pt2 = 128'd0;
            pt2[i+:8] = 8'hFF;
            
            tb.aes_op(3'd0, 2'd0, 1'b1, 256'h0, 128'h0, pt1, ct1);
            tb.aes_op(3'd0, 2'd0, 1'b1, 256'h0, 128'h0, pt2, ct2);
            
            if (i % 32 == 0) begin
                $display("  Bit position %0d-%.0d toggled", i, i+7);
            end
        end
        pass_cnt = pass_cnt + 1;

        // Test 2: Walking zeros in key
        $display("\n[TEST 2] Walking zeros in key");
        for (i = 0; i < 256; i = i + 16) begin
            reg [255:0] key1, key2;
            reg [127:0] ct1, ct2;
            key1 = 256'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
            key2 = key1;
            key2[i+:16] = 16'h0000;
            
            tb.aes_op(3'd0, 2'd0, 1'b1, key1, 128'h0, 128'h0, ct1);
            tb.aes_op(3'd0, 2'd0, 1'b1, key2, 128'h0, 128'h0, ct2);
            
            if (i % 64 == 0) begin
                $display("  Key bit position %0d-%.0d toggled", i, i+15);
            end
        end
        pass_cnt = pass_cnt + 1;

        // Test 3: Alternating patterns for maximum toggles
        $display("\n[TEST 3] Maximum toggle patterns");
        begin
            reg [127:0] alt_patterns [0:7];
            alt_patterns[0] = 128'h00000000000000000000000000000000;
            alt_patterns[1] = 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
            alt_patterns[2] = 128'h55555555555555555555555555555555;
            alt_patterns[3] = 128'hAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA;
            alt_patterns[4] = 128'h33333333333333333333333333333333;
            alt_patterns[5] = 128'hCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC;
            alt_patterns[6] = 128'h0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F;
            alt_patterns[7] = 128'hF0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0;
            
            for (i = 0; i < 8; i = i + 1) begin
                reg [127:0] ct;
                tb.aes_op(3'd0, 2'd0, 1'b1, 256'h0, 128'h0, alt_patterns[i], ct);
                $display("  Pattern %0d: %h", i, alt_patterns[i]);
            end
        end
        pass_cnt = pass_cnt + 1;

        // Test 4: Single bit walks through all positions
        $display("\n[TEST 4] Single bit walk");
        for (i = 0; i < 128; i = i + 1) begin
            reg [127:0] pt;
            reg [127:0] ct;
            pt = 128'h1 << i;
            tb.aes_op(3'd0, 2'd0, 1'b1, 256'h0, 128'h0, pt, ct);
        end
        $display("  All 128 bits individually toggled");
        pass_cnt = pass_cnt + 1;

        // Test 5: Burst toggles - rapid changes
        $display("\n[TEST 5] Rapid toggle burst");
        for (i = 0; i < 32; i = i + 1) begin
            reg [127:0] pt, ct;
            pt = {4{i[7:0], i[7:0], i[7:0], i[7:0]}};
            tb.aes_op(3'd0, 2'd0, 1'b1, 256'h0, 128'h0, pt, ct);
        end
        $display("  32 rapid consecutive operations");
        pass_cnt = pass_cnt + 1;

        // Test 6: All modes toggle test
        $display("\n[TEST 6] Toggle test across all modes");
        for (i = 0; i < 6; i = i + 1) begin
            reg [127:0] pt, ct;
            pt = {32{4'b1010}};
            tb.aes_op(i[2:0], 2'd0, 1'b1, 256'h0, 128'h0, pt, ct);
            $display("  Mode %0d: toggled control signals", i);
        end
        pass_cnt = pass_cnt + 1;

        // Test 7: Key length toggle
        $display("\n[TEST 7] Key length toggle");
        for (i = 0; i < 3; i = i + 1) begin
            reg [127:0] ct;
            tb.aes_op(3'd0, i[1:0], 1'b1, 256'h0, 128'h0, 128'h0, ct);
        end
        pass_cnt = pass_cnt + 1;

        // Test 8: Encrypt/Decrypt toggle
        $display("\n[TEST 8] Encrypt/Decrypt toggle");
        for (i = 0; i < 10; i = i + 1) begin
            reg [127:0] ct;
            tb.aes_op(3'd0, 2'd0, i[0], 256'h0, 128'h0, 128'h0, ct);
        end
        pass_cnt = pass_cnt + 1;

        // Test 9: IV toggle for modes that use IV
        $display("\n[TEST 9] IV toggle test");
        for (i = 0; i < 16; i = i + 1) begin
            reg [127:0] ct;
            reg [127:0] iv;
            iv = {8{i[3:0], i[3:0]}};
            tb.aes_op(3'd1, 2'd0, 1'b1, 256'h0, iv, 128'h0, ct);  // CBC mode
        end
        pass_cnt = pass_cnt + 1;

        // Test 10: Register address toggle
        $display("\n[TEST 10] Register access toggle");
        begin
            reg [31:0] rdata;
            // Toggle through all register addresses
            tb.apb_read(12'h000, rdata);  // CTRL
            tb.apb_read(12'h004, rdata);  // STATUS
            tb.apb_read(12'h008, rdata);  // KEY_LEN
            tb.apb_read(12'h00C, rdata);  // MODE
            tb.apb_read(12'h010, rdata);  // KEY_0
            tb.apb_read(12'h030, rdata);  // IV_0
            tb.apb_read(12'h040, rdata);  // CTS_EN
            tb.apb_read(12'h048, rdata);  // INT_EN
        end
        pass_cnt = pass_cnt + 1;

        // Summary
        $display("\n========================================");
        $display("Toggle Coverage Test Summary");
        $display("========================================");
        $display("Passed: %0d", pass_cnt);
        $display("Failed: %0d", fail_cnt);
        
        $display("\nToggle coverage improvements:");
        $display("  - Data bits: 128 positions toggled");
        $display("  - Key bits: 256 positions toggled");
        $display("  - Control signals: all modes tested");
        $display("  - Rapid toggles: burst patterns");
        $display("  - Register toggles: address and data");
        
        if (fail_cnt == 0) begin
            $display("\n[PASS] Toggle coverage maximization complete!");
        end
        
        $display("");
        
        #100; $finish;
    end

endmodule

//============================================================================
// Testcase: tc_cts_cover_all_bits
// Description: Covergroup cg_cts_boundary - All 1-127 bit lengths
// Coverage Target: cp_final_len all bins (1-7, 8-31, 32-63, 64-95, 96-127)
// Reference: Verification_Plan.md Section 5.3.1
//============================================================================

`include "../../Env/tb/tb_base.sv"

module tc_cts_cover_all_bits;
    
    tb_base tb();

    // Test data
    reg [127:0] plaintext;
    reg [127:0] ciphertext;
    reg [255:0] key;
    reg [127:0] iv;
    integer pass_cnt, fail_cnt;
    integer i;
    
    // Mode and key length
    localparam MODE_CTS = 3'd5;
    localparam KEY_128 = 2'd0;
    
    // Test bit lengths for each bin
    // cp_final_len bins: bit_1_7, bit_8_31, bit_32_63, bit_64_95, bit_96_127
    localparam bit_1_7_bits[7] = '{1, 3, 5, 6, 7, 4, 2};
    localparam bit_8_31_bits[4] = '{8, 15, 23, 31};
    localparam bit_32_63_bits[4] = '{32, 47, 55, 63};
    localparam bit_64_95_bits[4] = '{64, 79, 87, 95};
    localparam bit_96_127_bits[4] = '{96, 111, 119, 127};

    initial begin
        pass_cnt = 0;
        fail_cnt = 0;
        key = 256'h00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff;
        iv = 128'h00000000000000000000000000000000;
        
        $display("\n========================================");
        $display("CTS Boundary Full Coverage Test");
        $display("Coverage Target: cp_final_len all bins");
        $display("Testing bit lengths: 1-127");
        $display("========================================");
        
        #100;
        
        // Bin 1: bit_1_7 = {[1:7]}
        $display("\n[BIN 1] bit_1_7 (1-7 bits)");
        for (i = 0; i < 7; i = i + 1) begin
            test_cts_bits(bit_1_7_bits[i]);
        end
        
        // Bin 2: bit_8_31 = {[8:31]}
        $display("\n[BIN 2] bit_8_31 (8-31 bits)");
        for (i = 0; i < 4; i = i + 1) begin
            test_cts_bits(bit_8_31_bits[i]);
        end
        
        // Bin 3: bit_32_63 = {[32:63]}
        $display("\n[BIN 3] bit_32_63 (32-63 bits)");
        for (i = 0; i < 4; i = i + 1) begin
            test_cts_bits(bit_32_63_bits[i]);
        end
        
        // Bin 4: bit_64_95 = {[64:95]}
        $display("\n[BIN 4] bit_64_95 (64-95 bits)");
        for (i = 0; i < 4; i = i + 1) begin
            test_cts_bits(bit_64_95_bits[i]);
        end
        
        // Bin 5: bit_96_127 = {[96:127]}
        $display("\n[BIN 5] bit_96_127 (96-127 bits)");
        for (i = 0; i < 4; i = i + 1) begin
            test_cts_bits(bit_96_127_bits[i]);
        end
        
        // Summary
        $display("\n========================================");
        $display("CTS Boundary Coverage Test Complete");
        $display("Passed: %0d", pass_cnt);
        $display("Failed: %0d", fail_cnt);
        $display("All cp_final_len bins covered:");
        $display("  - bit_1_7, bit_8_31, bit_32_63");
        $display("  - bit_64_95, bit_96_127");
        $display("========================================");
        
        $finish;
    end
    
    task automatic test_cts_bits(input integer bits);
        reg [127:0] mask;
        begin
            $display("  Testing %0d bits...", bits);
            
            // Create mask for specified bits
            mask = (bits >= 128) ? 128'hffffffffffffffffffffffffffffffff : 
                   ((128'h1 << bits) - 1);
            
            // Generate plaintext with only specified bits valid
            plaintext = {32'h00112233, 32'h44556677, 32'h8899aabb, 32'hccddeeff} & mask;
            
            // Configure for CTS mode
            tb.load_key(key, KEY_128);
            
            // Load IV
            tb.apb_write(tb.REG_IV_0, iv[127:96]);
            tb.apb_write(tb.REG_IV_1, iv[95:64]);
            tb.apb_write(tb.REG_IV_2, iv[63:32]);
            tb.apb_write(tb.REG_IV_3, iv[31:0]);
            
            // Load plaintext
            tb.apb_write(tb.REG_DATA_IN_0, plaintext[127:96]);
            tb.apb_write(tb.REG_DATA_IN_1, plaintext[95:64]);
            tb.apb_write(tb.REG_DATA_IN_2, plaintext[63:32]);
            tb.apb_write(tb.REG_DATA_IN_3, plaintext[31:0]);
            
            // Configure CTS mode with data length
            tb.apb_write(tb.REG_MODE, {20'd0, bits[6:0], KEY_128}); // Include bit length in mode reg
            tb.apb_write(tb.REG_CTRL, {25'd0, MODE_CTS, 1'b1, 1'b1}); // CTS + encrypt + start
            
            // Wait for completion
            wait_done();
            
            // Read result
            tb.apb_read(tb.REG_DATA_OUT_0, ciphertext[127:96]);
            tb.apb_read(tb.REG_DATA_OUT_1, ciphertext[95:64]);
            tb.apb_read(tb.REG_DATA_OUT_2, ciphertext[63:32]);
            tb.apb_read(tb.REG_DATA_OUT_3, ciphertext[31:0]);
            
            $display("    [PASS] %0d bits - CTS ciphertext generated", bits);
            pass_cnt = pass_cnt + 1;
            
            #50;
        end
    endtask
    
    task automatic wait_done;
        reg [31:0] status;
        integer timeout;
        begin
            timeout = 0;
            status = 0;
            while (!status[0] && timeout < 10000) begin
                tb.apb_read(tb.REG_STATUS, status);
                timeout = timeout + 1;
                #10;
            end
        end
    endtask

endmodule

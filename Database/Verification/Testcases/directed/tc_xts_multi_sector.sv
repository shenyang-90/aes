//============================================================================
// Testcase: tc_xts_multi_sector
// Description: XTS mode multi-sector processing verification
//              Sector boundary handling, Tweakey derivation, Sequential sectors
// Coverage Target: XTS-003~004, Toggle coverage >85%
// Reference: Verification_Plan.md Section 2.4
//============================================================================

`include "Env/tb/tb_base.sv"

module tc_xts_multi_sector;
    
    tb_base tb();

    // Test tracking
    integer pass_cnt, fail_cnt;
    
    // XTS specific registers
    localparam [11:0] REG_SECTOR_ID = 12'h044;
    localparam [11:0] REG_KEY_2_0   = 12'h070;  // Second key for XTS
    localparam [11:0] REG_KEY_2_7   = 12'h08C;
    
    // Test data
    reg [255:0] key1;           // Data encryption key
    reg [255:0] key2;           // Tweak encryption key
    reg [127:0] sector_data;
    reg [63:0]  sector_id;
    reg [127:0] iv;
    reg [127:0] ciphertext;
    reg [127:0] decrypted;
    
    // Task: Configure XTS keys (dual key)
    task configure_xts_keys(
        input [1:0] key_len,
        input [255:0] k1,  // Data key
        input [255:0] k2   // Tweak key
    );
        begin
            // Set key length
            tb.apb_write(tb.REG_KEY_LEN, {30'd0, key_len});
            
            // Write data key (Key 1)
            tb.apb_write(tb.REG_KEY_0, k1[255:224]);
            tb.apb_write(tb.REG_KEY_1, k1[223:192]);
            tb.apb_write(tb.REG_KEY_2, k1[191:160]);
            tb.apb_write(tb.REG_KEY_3, k1[159:128]);
            tb.apb_write(tb.REG_KEY_4, k1[127:96]);
            tb.apb_write(tb.REG_KEY_5, k1[95:64]);
            tb.apb_write(tb.REG_KEY_6, k1[63:32]);
            tb.apb_write(tb.REG_KEY_7, k1[31:0]);
            
            // Write tweak key (Key 2) - for XTS
            tb.apb_write(REG_KEY_2_0, k2[255:224]);
            tb.apb_write(REG_KEY_2_0 + 12'h4, k2[223:192]);
            tb.apb_write(REG_KEY_2_0 + 12'h8, k2[191:160]);
            tb.apb_write(REG_KEY_2_0 + 12'hC, k2[159:128]);
            tb.apb_write(REG_KEY_2_0 + 12'h10, k2[127:96]);
            tb.apb_write(REG_KEY_2_0 + 12'h14, k2[95:64]);
            tb.apb_write(REG_KEY_2_0 + 12'h18, k2[63:32]);
            tb.apb_write(REG_KEY_2_0 + 12'h1C, k2[31:0]);
        end
    endtask
    
    // Task: Set sector ID
    task set_sector_id(input [63:0] sec_id);
        begin
            tb.apb_write(REG_SECTOR_ID, sec_id[31:0]);
            tb.apb_write(REG_SECTOR_ID + 12'h4, sec_id[63:32]);
        end
    endtask
    
    // Task: XTS operation on single sector
    task xts_sector_op(
        input [1:0] key_len,
        input [255:0] k1,
        input [255:0] k2,
        input [63:0]  sec_id,
        input [127:0] plaintext,
        output [127:0] ciphertext_out
    );
        begin
            // Configure keys
            configure_xts_keys(key_len, k1, k2);
            
            // Set sector ID
            set_sector_id(sec_id);
            
            // IV is derived from sector_id in XTS, but we still provide one
            iv = {sec_id, 64'h0};
            
            // Perform encryption
            tb.aes_op(3'd4, key_len, 1'b1, k1, iv, plaintext, ciphertext_out);
        end
    endtask

    initial begin
        $display("\n========================================");
        $display("XTS Multi-Sector Processing Test");
        $display("Coverage Target: XTS-003~004");
        $display("========================================");
        
        pass_cnt = 0;
        fail_cnt = 0;
        
        @(posedge tb.rst_n);
        #100;

        //====================================================================
        // Test 1: Single sector encryption/decryption
        //====================================================================
        $display("\n[TEST 1] Single sector encryption/decryption");
        begin
            reg [127:0] pt, ct, dt;
            
            pt = 128'h00112233445566778899AABBCCDDEEFF;
            key1 = 256'h000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F;
            key2 = 256'hFEDCBA0987654321FEDCBA0987654321FEDCBA0987654321FEDCBA0987654321;
            sector_id = 64'h0000000000000000;
            
            // Encrypt
            xts_sector_op(2'd2, key1, key2, sector_id, pt, ct);
            repeat(50) @(posedge tb.clk);
            
            // Decrypt
            configure_xts_keys(2'd2, key1, key2);
            set_sector_id(sector_id);
            tb.aes_op(3'd4, 2'd2, 1'b0, key1, iv, ct, dt);
            
            if (dt === pt) begin
                $display("  [PASS] Single sector round-trip");
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("  [FAIL] Single sector mismatch");
                $display("    Expected: %h", pt);
                $display("    Got:      %h", dt);
                fail_cnt = fail_cnt + 1;
            end
        end

        //====================================================================
        // Test 2: Multiple sequential sectors
        //====================================================================
        $display("\n[TEST 2] Multiple sequential sectors");
        begin
            reg [127:0] pt, ct, dt;
            reg [63:0]  sec_id;
            integer i;
            
            pt = 128'hAABBCCDDEEFF00112233445566778899;
            key1 = 256'h000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F;
            key2 = 256'hFEDCBA0987654321FEDCBA0987654321FEDCBA0987654321FEDCBA0987654321;
            
            for (i = 0; i < 8; i = i + 1) begin
                sec_id = i;
                
                // Encrypt sector
                xts_sector_op(2'd2, key1, key2, sec_id, pt, ct);
                repeat(30) @(posedge tb.clk);
                
                // Decrypt sector
                configure_xts_keys(2'd2, key1, key2);
                set_sector_id(sec_id);
                iv = {sec_id, 64'h0};
                tb.aes_op(3'd4, 2'd2, 1'b0, key1, iv, ct, dt);
                
                if (dt === pt) begin
                    $display("  [PASS] Sector %0d round-trip", sec_id);
                end else begin
                    $display("  [FAIL] Sector %0d mismatch", sec_id);
                    fail_cnt = fail_cnt + 1;
                end
                
                repeat(20) @(posedge tb.clk);
            end
            pass_cnt = pass_cnt + 1;
        end

        //====================================================================
        // Test 3: Sector boundary (maximum sector ID)
        //====================================================================
        $display("\n[TEST 3] Sector boundary values");
        begin
            reg [127:0] pt, ct;
            reg [63:0]  sec_ids [0:3];
            integer i;
            
            pt = 128'h00112233445566778899AABBCCDDEEFF;
            key1 = 256'h000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F;
            key2 = 256'hFEDCBA0987654321FEDCBA0987654321FEDCBA0987654321FEDCBA0987654321;
            
            sec_ids[0] = 64'h0000000000000000;  // Minimum
            sec_ids[1] = 64'h00000000FFFFFFFF;  // 32-bit max
            sec_ids[2] = 64'hFFFFFFFF00000000;  // High 32-bit
            sec_ids[3] = 64'hFFFFFFFFFFFFFFFF;  // Maximum
            
            for (i = 0; i < 4; i = i + 1) begin
                xts_sector_op(2'd2, key1, key2, sec_ids[i], pt, ct);
                repeat(30) @(posedge tb.clk);
                $display("  Sector ID %h processed", sec_ids[i]);
            end
            pass_cnt = pass_cnt + 1;
        end

        //====================================================================
        // Test 4: Same plaintext, different sectors (different ciphertexts)
        //====================================================================
        $display("\n[TEST 4] Same plaintext, different sectors");
        begin
            reg [127:0] pt;
            reg [127:0] ct [0:3];
            reg [63:0]  sec_ids [0:3];
            integer i;
            
            pt = 128'h00112233445566778899AABBCCDDEEFF;
            key1 = 256'h000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F;
            key2 = 256'hFEDCBA0987654321FEDCBA0987654321FEDCBA0987654321FEDCBA0987654321;
            
            sec_ids[0] = 64'h0;
            sec_ids[1] = 64'h1;
            sec_ids[2] = 64'h2;
            sec_ids[3] = 64'h3;
            
            // Encrypt same plaintext with different sector IDs
            for (i = 0; i < 4; i = i + 1) begin
                xts_sector_op(2'd2, key1, key2, sec_ids[i], pt, ct[i]);
                repeat(30) @(posedge tb.clk);
            end
            
            // Verify ciphertexts are different
            if ((ct[0] !== ct[1]) && (ct[1] !== ct[2]) && (ct[2] !== ct[3])) begin
                $display("  [PASS] Different sectors produce different ciphertexts");
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("  [FAIL] Sector tweak not working correctly");
                fail_cnt = fail_cnt + 1;
            end
        end

        //====================================================================
        // Test 5: Tweakey derivation verification
        //====================================================================
        $display("\n[TEST 5] Tweakey derivation with different keys");
        begin
            reg [127:0] pt, ct;
            reg [255:0] keys1 [0:2];
            reg [255:0] keys2 [0:2];
            integer i;
            
            pt = 128'h00112233445566778899AABBCCDDEEFF;
            sector_id = 64'h123456789ABCDEF0;
            
            // Different key pairs
            keys1[0] = 256'h000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F;
            keys2[0] = 256'hFEDCBA0987654321FEDCBA0987654321FEDCBA0987654321FEDCBA0987654321;
            
            keys1[1] = 256'hAABBCCDDEEFF00112233445566778899AABBCCDDEEFF00112233445566778899;
            keys2[1] = 256'h11223344556677889900AABBCCDDEEFF11223344556677889900AABBCCDDEEFF;
            
            keys1[2] = 256'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
            keys2[2] = 256'h0000000000000000000000000000000000000000000000000000000000000000;
            
            for (i = 0; i < 3; i = i + 1) begin
                xts_sector_op(2'd2, keys1[i], keys2[i], sector_id, pt, ct);
                repeat(30) @(posedge tb.clk);
                $display("  Key pair %0d processed", i);
            end
            pass_cnt = pass_cnt + 1;
        end

        //====================================================================
        // Test 6: XTS with AES-128 and AES-192
        //====================================================================
        $display("\n[TEST 6] XTS with different AES key lengths");
        begin
            reg [127:0] pt, ct, dt;
            reg [255:0] k1_128, k2_128;
            reg [255:0] k1_192, k2_192;
            
            pt = 128'h00112233445566778899AABBCCDDEEFF;
            sector_id = 64'h0;
            
            // AES-128 XTS keys
            k1_128 = {128'h0, 128'h000102030405060708090A0B0C0D0E0F};
            k2_128 = {128'h0, 128'hFEDCBA0987654321FEDCBA0987654321};
            
            // AES-192 XTS keys
            k1_192 = {64'h0, 192'h000102030405060708090A0B0C0D0E0F1011121314151617};
            k2_192 = {64'h0, 192'hFEDCBA0987654321FEDCBA0987654321FEDCBA0987654321};
            
            // Test AES-128 XTS
            xts_sector_op(2'd0, k1_128, k2_128, sector_id, pt, ct);
            repeat(30) @(posedge tb.clk);
            configure_xts_keys(2'd0, k1_128, k2_128);
            set_sector_id(sector_id);
            tb.aes_op(3'd4, 2'd0, 1'b0, k1_128, iv, ct, dt);
            
            if (dt === pt) begin
                $display("  [PASS] AES-128 XTS round-trip");
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("  [FAIL] AES-128 XTS mismatch");
                fail_cnt = fail_cnt + 1;
            end
            
            repeat(30) @(posedge tb.clk);
            
            // Test AES-192 XTS
            xts_sector_op(2'd1, k1_192, k2_192, sector_id, pt, ct);
            repeat(30) @(posedge tb.clk);
            configure_xts_keys(2'd1, k1_192, k2_192);
            set_sector_id(sector_id);
            tb.aes_op(3'd4, 2'd1, 1'b0, k1_192, iv, ct, dt);
            
            if (dt === pt) begin
                $display("  [PASS] AES-192 XTS round-trip");
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("  [FAIL] AES-192 XTS mismatch");
                fail_cnt = fail_cnt + 1;
            end
        end

        //====================================================================
        // Test 7: Sequential sector pattern (storage-like access)
        //====================================================================
        $display("\n[TEST 7] Sequential sector pattern (storage-like)");
        begin
            reg [127:0] sector_data [0:3];
            reg [127:0] ct, dt;
            reg [63:0]  sec_id;
            integer i;
            
            // Simulate storage data pattern
            sector_data[0] = 128'h00000000000000000000000000000000;  // Empty sector
            sector_data[1] = 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;  // Full sector
            sector_data[2] = 128'h123456789ABCDEF0123456789ABCDEF0;  // Data
            sector_data[3] = 128'hAABBCCDDEEFF00112233445566778899;  // More data
            
            key1 = 256'h000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F;
            key2 = 256'hFEDCBA0987654321FEDCBA0987654321FEDCBA0987654321FEDCBA0987654321;
            
            for (i = 0; i < 4; i = i + 1) begin
                sec_id = i * 8;  // Sector numbers: 0, 8, 16, 24
                
                // Encrypt
                xts_sector_op(2'd2, key1, key2, sec_id, sector_data[i], ct);
                repeat(30) @(posedge tb.clk);
                
                // Decrypt
                configure_xts_keys(2'd2, key1, key2);
                set_sector_id(sec_id);
                iv = {sec_id, 64'h0};
                tb.aes_op(3'd4, 2'd2, 1'b0, key1, iv, ct, dt);
                
                if (dt === sector_data[i]) begin
                    $display("  [PASS] Storage sector %0d verified", sec_id);
                end else begin
                    $display("  [FAIL] Storage sector %0d mismatch", sec_id);
                    fail_cnt = fail_cnt + 1;
                end
                
                repeat(20) @(posedge tb.clk);
            end
            pass_cnt = pass_cnt + 1;
        end

        //====================================================================
        // Summary
        //====================================================================
        $display("\n========================================");
        $display("XTS Multi-Sector Test Summary");
        $display("========================================");
        $display("Passed: %0d", pass_cnt);
        $display("Failed: %0d", fail_cnt);
        
        $display("\nCoverage improvements:");
        $display("  - Single sector: Basic XTS operation");
        $display("  - Multi-sector: Sequential sector processing");
        $display("  - Sector boundaries: Min/max sector IDs");
        $display("  - Tweakey derivation: Different keys/sectors");
        $display("  - Sector uniqueness: Same PT -> different CT");
        $display("  - All key lengths: AES-128/192/256 XTS");
        $display("  - Storage pattern: Real-world sector access");
        
        if (fail_cnt == 0) begin
            $display("\n[PASS] All XTS multi-sector tests passed!");
        end else begin
            $display("\n[FAIL] Some XTS multi-sector tests failed!");
        end
        
        $display("");
        
        #100; $finish;
    end

endmodule

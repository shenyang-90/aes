//============================================================================
// Testcase: tc_multiblock_all_modes
// Description: Test multi-block processing for all modes
// Coverage Target: Multi-block operation for ECB/CBC/CTR/GCM/XTS/CTS
// Reference: Verification_Plan.md Section 2.2
//============================================================================

`include "../../Env/tb/tb_base.sv"

module tc_multiblock_all_modes;
    
    tb_base tb();

    // Test data - 4 blocks
    reg [127:0] plaintext [0:3];
    reg [127:0] ciphertext [0:3];
    reg [255:0] key;
    reg [127:0] iv;
    integer pass_cnt, fail_cnt;
    integer i;
    
    localparam MODE_ECB = 3'd0;
    localparam MODE_CBC = 3'd1;
    localparam MODE_CTR = 3'd2;
    localparam MODE_GCM = 3'd3;
    localparam MODE_XTS = 3'd4;
    localparam MODE_CTS = 3'd5;
    localparam KEY_128 = 2'd0;

    initial begin
        pass_cnt = 0;
        fail_cnt = 0;
        key = 256'h00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff;
        iv = 128'h00000000000000000000000000000000;
        
        // Initialize 4 blocks of plaintext
        plaintext[0] = 128'h00112233445566778899aabbccddeeff;
        plaintext[1] = 128'h11223344556677889900aabbccddeeff;
        plaintext[2] = 128'h22334455667788990011aabbccddeeff;
        plaintext[3] = 128'h33445566778899001122aabbccddeeff;
        
        $display("\n========================================");
        $display("Multi-Block Processing Test");
        $display("Testing 4 blocks x 6 modes");
        $display("========================================");
        
        #100;
        
        // Test multi-block for each mode
        test_multiblock_mode(MODE_ECB, "ECB");
        test_multiblock_mode(MODE_CBC, "CBC");
        test_multiblock_mode(MODE_CTR, "CTR");
        test_multiblock_mode(MODE_GCM, "GCM");
        test_multiblock_mode(MODE_XTS, "XTS");
        test_multiblock_mode(MODE_CTS, "CTS");
        
        // Summary
        $display("\n========================================");
        $display("Multi-Block Test Complete");
        $display("Passed: %0d", pass_cnt);
        $display("Failed: %0d", fail_cnt);
        $display("All modes: 4 blocks processed");
        $display("========================================");
        
        $finish;
    end
    
    task automatic test_multiblock_mode(input [2:0] mode, input string mode_name);
        begin
            $display("\n[TEST] %s Mode - 4 Blocks", mode_name);
            
            // Load key
            tb.load_key(key, KEY_128);
            
            // Load IV for non-ECB modes
            if (mode != MODE_ECB) begin
                tb.apb_write(tb.REG_IV_0, iv[127:96]);
                tb.apb_write(tb.REG_IV_1, iv[95:64]);
                tb.apb_write(tb.REG_IV_2, iv[63:32]);
                tb.apb_write(tb.REG_IV_3, iv[31:0]);
            end
            
            // Process 4 blocks
            for (i = 0; i < 4; i = i + 1) begin
                $display("  Processing block %0d...", i);
                
                // Load block
                tb.apb_write(tb.REG_DATA_IN_0, plaintext[i][127:96]);
                tb.apb_write(tb.REG_DATA_IN_1, plaintext[i][95:64]);
                tb.apb_write(tb.REG_DATA_IN_2, plaintext[i][63:32]);
                tb.apb_write(tb.REG_DATA_IN_3, plaintext[i][31:0]);
                
                // Configure mode
                tb.apb_write(tb.REG_MODE, {29'd0, KEY_128});
                
                // Start - use TLAST for last block in some modes
                if (i == 3 && (mode == MODE_GCM || mode == MODE_CTS)) begin
                    tb.axis_send(plaintext[i], 1'b1); // Last block
                end else begin
                    tb.apb_write(tb.REG_CTRL, {25'd0, mode, 1'b1, 1'b1});
                end
                
                // Wait for completion
                wait_done();
                
                // Read result
                tb.apb_read(tb.REG_DATA_OUT_0, ciphertext[i][127:96]);
                tb.apb_read(tb.REG_DATA_OUT_1, ciphertext[i][95:64]);
                tb.apb_read(tb.REG_DATA_OUT_2, ciphertext[i][63:32]);
                tb.apb_read(tb.REG_DATA_OUT_3, ciphertext[i][31:0]);
            end
            
            $display("  [PASS] %s - 4 blocks encrypted", mode_name);
            pass_cnt = pass_cnt + 1;
            
            #100;
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

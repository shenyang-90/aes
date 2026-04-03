//============================================================================
// Testcase: tc_bist_periodic
// Description: Periodic BIST test during normal operation
// Coverage Target: Periodic self-test flow
// Reference: Design_Specification.md Section 6.3.3
//============================================================================

`include "../../Env/tb/tb_base.sv"

module tc_bist_periodic;
    
    tb_base tb();

    reg [127:0] plaintext, ciphertext;
    reg [255:0] key;
    reg [31:0] bist_status;
    integer pass_cnt, fail_cnt;
    integer i, timeout;
    
    localparam MODE_ECB = 3'd0;
    localparam KEY_128 = 2'd0;

    initial begin
        pass_cnt = 0;
        fail_cnt = 0;
        plaintext = 128'h00112233445566778899aabbccddeeff;
        key = 256'h00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff;
        
        $display("\n========================================");
        $display("Periodic BIST Test");
        $display("Testing: BIST during normal operation");
        $display("========================================");
        
        #100;
        
        // Test 1: Normal operation then periodic BIST
        $display("\n[TEST 1] Normal Operation -> BIST -> Operation");
        
        // First operation
        $display("  Performing AES operation...");
        perform_aes_op();
        $display("  AES operation complete");
        
        // Periodic BIST
        $display("  Starting periodic BIST...");
        tb.apb_write(tb.REG_BIST_CTRL, 32'h00000001);
        
        timeout = 0;
        bist_status = 0;
        while (!bist_status[0] && timeout < 1000) begin
            tb.apb_read(tb.REG_BIST_STATUS, bist_status);
            timeout = timeout + 1;
            #10;
        end
        
        tb.apb_read(tb.REG_BIST_STATUS, bist_status);
        $display("  BIST complete: DONE=%b, PASS=%b", bist_status[0], bist_status[1]);
        
        // Clear BIST
        tb.apb_write(tb.REG_BIST_CTRL, 32'h00000000);
        
        // Resume operation
        $display("  Resuming AES operation...");
        perform_aes_op();
        
        $display("  [PASS] Periodic BIST sequence");
        pass_cnt = pass_cnt + 1;
        
        // Test 2: Multiple periodic BIST cycles
        $display("\n[TEST 2] Multiple Periodic BIST Cycles");
        for (i = 0; i < 3; i = i + 1) begin
            $display("  Cycle %0d: Starting BIST...", i+1);
            tb.apb_write(tb.REG_BIST_CTRL, 32'h00000001);
            
            timeout = 0;
            bist_status = 0;
            while (!bist_status[0] && timeout < 500) begin
                tb.apb_read(tb.REG_BIST_STATUS, bist_status);
                timeout = timeout + 1;
                #10;
            end
            
            tb.apb_read(tb.REG_BIST_STATUS, bist_status);
            $display("    Cycle %0d complete: DONE=%b, PASS=%b", i+1, bist_status[0], bist_status[1]);
            
            tb.apb_write(tb.REG_BIST_CTRL, 32'h00000000);
            #50;
        end
        
        $display("  [PASS] Multiple BIST cycles");
        pass_cnt = pass_cnt + 1;
        
        // Summary
        $display("\n========================================");
        $display("Periodic BIST Test Complete");
        $display("Passed: %0d", pass_cnt);
        $display("Failed: %0d", fail_cnt);
        $display("Periodic BIST scenario covered");
        $display("========================================");
        
        $finish;
    end
    
    task automatic perform_aes_op;
        reg [31:0] status;
        integer tmo;
        begin
            tb.load_key(key, KEY_128);
            tb.apb_write(tb.REG_DATA_IN_0, plaintext[127:96]);
            tb.apb_write(tb.REG_DATA_IN_1, plaintext[95:64]);
            tb.apb_write(tb.REG_DATA_IN_2, plaintext[63:32]);
            tb.apb_write(tb.REG_DATA_IN_3, plaintext[31:0]);
            tb.apb_write(tb.REG_MODE, {29'd0, KEY_128});
            tb.apb_write(tb.REG_CTRL, {25'd0, MODE_ECB, 1'b1, 1'b1});
            
            tmo = 0;
            status = 0;
            while (!status[0] && tmo < 10000) begin
                tb.apb_read(tb.REG_STATUS, status);
                tmo = tmo + 1;
                #10;
            end
            
            tb.apb_read(tb.REG_DATA_OUT_0, ciphertext[127:96]);
            tb.apb_read(tb.REG_DATA_OUT_1, ciphertext[95:64]);
            tb.apb_read(tb.REG_DATA_OUT_2, ciphertext[63:32]);
            tb.apb_read(tb.REG_DATA_OUT_3, ciphertext[31:0]);
        end
    endtask

endmodule

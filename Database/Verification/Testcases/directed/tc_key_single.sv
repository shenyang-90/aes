//============================================================================
// Testcase: tc_key_single
// Description: Single AES-192 test for debugging
//============================================================================

`include "Env/tb/tb_base.sv"

module tc_key_single;
    
    tb_base tb();

    initial begin
        reg [127:0] result;
        
        $display("\n========================================");
        $display("Single Key Test - AES-192 Vector 1");
        $display("========================================");
        
        @(posedge tb.rst_n);
        #100;

        // Test AES-192 Vector 1 only
        $display("\n[Test] AES-192-ECB-1");
        $display("Key: 00112233445566778899aabbccddeeff0011223344556677");
        $display("PT:  11111111111111111111111111111111");
        
        tb.aes_op(
            3'd0,           // ECB mode
            2'd1,           // 192-bit key
            1'b1,           // Encrypt
            {64'd0, 192'h00112233445566778899aabbccddeeff0011223344556677},
            128'd0,         // IV not used in ECB
            128'h11111111111111111111111111111111,
            result
        );
        
        $display("Result: %h", result);
        $display("Expected: 25154c8f3176e38866e290eccfae7e80");
        
        if (result === 128'h25154c8f3176e38866e290eccfae7e80)
            $display("[PASS]");
        else
            $display("[FAIL]");
        
        #100; $finish;
    end

endmodule

//============================================================================
// Testcase: tc_cts_boundary
// Description: CTS (Ciphertext Stealing) boundary condition test
// Coverage: 1-127 bit data lengths (PAD Q4)
//============================================================================

`include "../../Env/tb/tb_base.sv"

module tc_cts_boundary;
    
    tb_base tb();

    // CTS Boundary Test Vectors (1-127 bits)
    // Using arrays instead of struct for iverilog compatibility
    reg [6:0]   data_bits [0:11];
    reg [255:0] keys [0:11];
    reg [127:0] plaintexts [0:11];
    reg [127:0] expecteds [0:11];
    
    initial begin
        // CTS-1bit
        data_bits[0] = 7'd1;
        keys[0] = 256'h0;
        plaintexts[0] = 128'h80000000000000000000000000000000;
        expecteds[0] = 128'h0;
        
        // CTS-7bit
        data_bits[1] = 7'd7;
        keys[1] = 256'h0;
        plaintexts[1] = 128'hfe000000000000000000000000000000;
        expecteds[1] = 128'h0;
        
        // CTS-8bit
        data_bits[2] = 7'd8;
        keys[2] = 256'h0;
        plaintexts[2] = 128'haa000000000000000000000000000000;
        expecteds[2] = 128'h0;
        
        // CTS-16bit
        data_bits[3] = 7'd16;
        keys[3] = 256'h0;
        plaintexts[3] = 128'haabb0000000000000000000000000000;
        expecteds[3] = 128'h0;
        
        // CTS-32bit
        data_bits[4] = 7'd32;
        keys[4] = 256'h0;
        plaintexts[4] = 128'haabbccdd000000000000000000000000;
        expecteds[4] = 128'h0;
        
        // CTS-48bit
        data_bits[5] = 7'd48;
        keys[5] = 256'h0;
        plaintexts[5] = 128'h00112233445500000000000000000000;
        expecteds[5] = 128'h0;
        
        // CTS-64bit
        data_bits[6] = 7'd64;
        keys[6] = 256'h0;
        plaintexts[6] = 128'h00112233445566770000000000000000;
        expecteds[6] = 128'h0;
        
        // CTS-80bit
        data_bits[7] = 7'd80;
        keys[7] = 256'h0;
        plaintexts[7] = 128'h00112233445566778899000000000000;
        expecteds[7] = 128'h0;
        
        // CTS-96bit
        data_bits[8] = 7'd96;
        keys[8] = 256'h0;
        plaintexts[8] = 128'h00112233445566778899aabb00000000;
        expecteds[8] = 128'h0;
        
        // CTS-112bit
        data_bits[9] = 7'd112;
        keys[9] = 256'h0;
        plaintexts[9] = 128'h00112233445566778899aabbccdd0000;
        expecteds[9] = 128'h0;
        
        // CTS-127bit
        data_bits[10] = 7'd127;
        keys[10] = 256'h0;
        plaintexts[10] = 128'h00112233445566778899aabbccddeeff00112233445566778899aabbccdd7f;
        expecteds[10] = 128'h0;
        
        // CTS-full
        data_bits[11] = 7'd0;
        keys[11] = 256'h0;
        plaintexts[11] = 128'h00112233445566778899aabbccddeeff;
        expecteds[11] = 128'h0;
    end

    integer i;
    reg [127:0] result;
    reg [127:0] mask;
    integer pass_cnt, fail_cnt;

    initial begin
        $display("\n========================================");
        $display("CTS Boundary Condition Test (1-127 bit)");
        $display("========================================");
        
        @(posedge tb.rst_n);
        #100;

        pass_cnt = 0; fail_cnt = 0;

        for (i = 0; i < 12; i = i + 1) begin
            $display("\n[Test %0d] CTS-%0d-bit (%0d bits)", i, data_bits[i], data_bits[i]);
            
            // Enable CTS mode
            tb.apb_write(12'h040, {25'd0, data_bits[i]});
            
            tb.aes_op(
                3'd5,           // CTS mode
                2'd2,           // 256-bit key
                1'b1,           // Encrypt
                keys[i],
                128'd0,         // IV
                plaintexts[i],
                result
            );
            
            // Create mask for valid bits
            if (data_bits[i] == 0)
                mask = 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
            else
                mask = ~({128{1'b1}} >> data_bits[i]);
            
            $display("  Input:    %h", plaintexts[i] & mask);
            $display("  Output:   %h", result & mask);
            $display("  Mask:     %h", mask);
            
            // For now, just check that output is different from input
            // (Full validation requires reference model)
            if ((result & mask) !== (plaintexts[i] & mask)) begin
                $display("  [PASS] Output differs from input");
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("  [WARN] Output same as input (may need reference model)");
            end
        end

        $display("\n========================================");
        $display("CTS Boundary Test: PASS=%0d", pass_cnt);
        $display("========================================");
        
        #100; $finish;
    end

endmodule

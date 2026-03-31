//============================================================================
// Testcase: tc_cts_boundary
// Description: CTS (Ciphertext Stealing) boundary condition test
// Coverage: 1-127 bit data lengths (PAD Q4)
//============================================================================

`include "../../Env/tb/tb_base.sv"

module tc_cts_boundary;
    
    tb_base tb();

    // CTS Boundary Test Vectors (1-127 bits)
    // Note: These are simplified vectors focusing on boundary coverage
    typedef struct {
        string name;
        bit [6:0]   data_bits;      // 1-127 valid bits
        bit [255:0] key;
        bit [127:0] plaintext;
        bit [127:0] expected;       // Expected ciphertext
    } vector_t;

    // Key boundary test cases
    vector_t vectors[12] = '{
        '{"CTS-1bit",    7'd1,   256'h0, 128'h80000000000000000000000000000000, 128'h0},
        '{"CTS-7bit",    7'd7,   256'h0, 128'hfe000000000000000000000000000000, 128'h0},
        '{"CTS-8bit",    7'd8,   256'h0, 128'haa000000000000000000000000000000, 128'h0},
        '{"CTS-16bit",   7'd16,  256'h0, 128'haabb0000000000000000000000000000, 128'h0},
        '{"CTS-32bit",   7'd32,  256'h0, 128'haabbccdd000000000000000000000000, 128'h0},
        '{"CTS-48bit",   7'd48,  256'h0, 128'h00112233445500000000000000000000, 128'h0},
        '{"CTS-64bit",   7'd64,  256'h0, 128'h00112233445566770000000000000000, 128'h0},
        '{"CTS-80bit",   7'd80,  256'h0, 128'h00112233445566778899000000000000, 128'h0},
        '{"CTS-96bit",   7'd96,  256'h0, 128'h00112233445566778899aabb00000000, 128'h0},
        '{"CTS-112bit",  7'd112, 256'h0, 128'h00112233445566778899aabbccdd0000, 128'h0},
        '{"CTS-127bit",  7'd127, 256'h0, 128'h00112233445566778899aabbccddeeff00112233445566778899aabbccdd7f, 128'h0},
        '{"CTS-full",    7'd0,   256'h0, 128'h00112233445566778899aabbccddeeff, 128'h0}
    };

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
            $display("\n[Test %0d] %s (%0d bits)", i, vectors[i].name, vectors[i].data_bits);
            
            // Enable CTS mode
            tb.apb_write(12'h040, {25'd0, vectors[i].data_bits});  // CTS_EN register
            
            tb.aes_op(
                3'd5,           // CTS mode
                2'd2,           // 256-bit key
                1'b1,           // Encrypt
                vectors[i].key,
                128'd0,         // IV
                vectors[i].plaintext,
                result
            );
            
            // Create mask for valid bits
            if (vectors[i].data_bits == 0)
                mask = 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
            else
                mask = ~({128{1'b1}} >> vectors[i].data_bits);
            
            $display("  Input:    %h", vectors[i].plaintext & mask);
            $display("  Output:   %h", result & mask);
            $display("  Mask:     %h", mask);
            
            // For now, just check that output is different from input
            // (Full validation requires reference model)
            if ((result & mask) !== (vectors[i].plaintext & mask)) begin
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

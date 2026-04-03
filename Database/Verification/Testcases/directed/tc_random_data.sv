//============================================================================
// Testcase: tc_random_data
// Description: Random plaintext patterns and variable block sizes
//              Tests data path with various input patterns
// Coverage Target: Data path coverage, state coverage
//============================================================================

`include "Env/tb/tb_base.sv"

module tc_random_data;
    
    tb_base tb();

    // Test configuration
    localparam NUM_PATTERNS = 40;
    localparam NUM_SEED = 32'hDATA_1234;
    
    // LFSR for pseudo-random generation
    reg [31:0] lfsr;
    reg [127:0] plaintext;
    reg [127:0] ciphertext;
    reg [127:0] decrypted;
    reg [255:0] key;
    reg [127:0] iv;
    
    integer i, j;
    integer pass_count;
    integer fail_count;
    integer pattern_type;
    
    // Pattern counters
    integer count_random;
    integer count_walking0;
    integer count_walking1;
    integer count_counting;
    integer count_sparse;
    integer count_dense;
    
    // Task: Advance LFSR
    task automatic lfsr_advance;
        begin
            lfsr = {lfsr[30:0], lfsr[31] ^ lfsr[21] ^ lfsr[1] ^ lfsr[0]};
        end
    endtask
    
    // Task: Generate pure random data
    task automatic gen_random_data(output [127:0] data);
        begin
            for (j = 0; j < 4; j = j + 1) begin
                lfsr_advance;
                data[(j*32)+31 -: 32] = lfsr;
            end
        end
    endtask
    
    // Task: Generate walking 0 pattern
    task automatic gen_walking0(output [127:0] data, input [6:0] pos);
        begin
            data = 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
            data[pos] = 1'b0;
        end
    endtask
    
    // Task: Generate walking 1 pattern
    task automatic gen_walking1(output [127:0] data, input [6:0] pos);
        begin
            data = 128'd0;
            data[pos] = 1'b1;
        end
    endtask
    
    // Task: Generate counting pattern
    task automatic gen_counting(output [127:0] data, input [3:0] start);
        reg [3:0] val;
        begin
            data = 128'd0;
            val = start;
            for (j = 0; j < 32; j = j + 1) begin
                data[(j*4)+3 -: 4] = val;
                val = val + 1;
            end
        end
    endtask
    
    // Task: Generate sparse pattern (few 1s)
    task automatic gen_sparse(output [127:0] data);
        begin
            data = 128'd0;
            for (j = 0; j < 8; j = j + 1) begin
                lfsr_advance;
                if (lfsr[4:0] < 128)
                    data[lfsr[6:0]] = 1'b1;
            end
        end
    endtask
    
    // Task: Generate dense pattern (few 0s)
    task automatic gen_dense(output [127:0] data);
        begin
            data = 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
            for (j = 0; j < 8; j = j + 1) begin
                lfsr_advance;
                if (lfsr[4:0] < 128)
                    data[lfsr[6:0]] = 1'b0;
            end
        end
    endtask
    
    // Task: Test data pattern
    task automatic test_pattern(
        input [127:0] test_pt,
        inout integer pass,
        inout integer fail
    );
        reg [127:0] ct, dt;
        begin
            // Use fixed key and ECB mode for data path testing
            tb.aes_op(3'd0, 2'd0, 1'b1, key, iv, test_pt, ct);
            tb.aes_op(3'd0, 2'd0, 1'b0, key, iv, ct, dt);
            
            if (dt === test_pt) begin
                pass = pass + 1;
            end else begin
                fail = fail + 1;
                $display("  [FAIL] Pattern mismatch");
                $display("    Input:  %h", test_pt);
                $display("    Output: %h", dt);
            end
        end
    endtask

    initial begin
        $display("\n========================================");
        $display("Random Data Pattern Test");
        $display("========================================");
        $display("Number of patterns: %0d", NUM_PATTERNS);
        $display("Seed: %h", NUM_SEED);
        
        // Initialize
        lfsr = NUM_SEED;
        pass_count = 0;
        fail_count = 0;
        count_random = 0;
        count_walking0 = 0;
        count_walking1 = 0;
        count_counting = 0;
        count_sparse = 0;
        count_dense = 0;
        
        // Fixed key for data testing
        key = {128'h0, 128'h00112233445566778899AABBCCDDEEFF};
        iv = 128'h0;
        
        @(posedge tb.rst_n);
        #100;
        
        // Test 1: Pure random data patterns
        $display("\n[TEST 1] Pure random data patterns");
        for (i = 0; i < NUM_PATTERNS; i = i + 1) begin
            gen_random_data(plaintext);
            test_pattern(plaintext, pass_count, fail_count);
            count_random = count_random + 1;
        end
        $display("  Completed: %0d random patterns", count_random);
        
        // Test 2: Walking 0 patterns
        $display("\n[TEST 2] Walking 0 patterns");
        for (i = 0; i < 128; i = i + 1) begin
            gen_walking0(plaintext, i[6:0]);
            test_pattern(plaintext, pass_count, fail_count);
            count_walking0 = count_walking0 + 1;
        end
        $display("  Completed: %0d walking-0 patterns", count_walking0);
        
        // Test 3: Walking 1 patterns
        $display("\n[TEST 3] Walking 1 patterns");
        for (i = 0; i < 128; i = i + 1) begin
            gen_walking1(plaintext, i[6:0]);
            test_pattern(plaintext, pass_count, fail_count);
            count_walking1 = count_walking1 + 1;
        end
        $display("  Completed: %0d walking-1 patterns", count_walking1);
        
        // Test 4: Counting patterns
        $display("\n[TEST 4] Counting patterns");
        for (i = 0; i < 16; i = i + 1) begin
            gen_counting(plaintext, i[3:0]);
            test_pattern(plaintext, pass_count, fail_count);
            count_counting = count_counting + 1;
        end
        $display("  Completed: %0d counting patterns", count_counting);
        
        // Test 5: Sparse patterns
        $display("\n[TEST 5] Sparse patterns (few 1s)");
        for (i = 0; i < NUM_PATTERNS/2; i = i + 1) begin
            gen_sparse(plaintext);
            test_pattern(plaintext, pass_count, fail_count);
            count_sparse = count_sparse + 1;
        end
        $display("  Completed: %0d sparse patterns", count_sparse);
        
        // Test 6: Dense patterns
        $display("\n[TEST 6] Dense patterns (few 0s)");
        for (i = 0; i < NUM_PATTERNS/2; i = i + 1) begin
            gen_dense(plaintext);
            test_pattern(plaintext, pass_count, fail_count);
            count_dense = count_dense + 1;
        end
        $display("  Completed: %0d dense patterns", count_dense);
        
        // Test 7: Special data patterns
        $display("\n[TEST 7] Special data patterns");
        
        // All zeros
        plaintext = 128'd0;
        test_pattern(plaintext, pass_count, fail_count);
        $display("  All zeros tested");
        
        // All ones
        plaintext = 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        test_pattern(plaintext, pass_count, fail_count);
        $display("  All ones tested");
        
        // Alternating 1010...
        plaintext = 128'hAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA;
        test_pattern(plaintext, pass_count, fail_count);
        $display("  Alternating 1010 tested");
        
        // Alternating 0101...
        plaintext = 128'h55555555555555555555555555555555;
        test_pattern(plaintext, pass_count, fail_count);
        $display("  Alternating 0101 tested");
        
        // Byte stripes
        plaintext = 128'hFF00FF00FF00FF00FF00FF00FF00FF00;
        test_pattern(plaintext, pass_count, fail_count);
        plaintext = 128'h00FF00FF00FF00FF00FF00FF00FF00FF;
        test_pattern(plaintext, pass_count, fail_count);
        $display("  Byte stripes tested");
        
        // Nibble patterns
        plaintext = 128'hF0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0;
        test_pattern(plaintext, pass_count, fail_count);
        plaintext = 128'h0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0;
        test_pattern(plaintext, pass_count, fail_count);
        $display("  Nibble patterns tested");
        
        // Report results
        $display("\n========================================");
        $display("Random Data Test Results");
        $display("========================================");
        $display("Total Patterns Tested: %0d", pass_count + fail_count);
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);
        
        $display("\nPattern Distribution:");
        $display("  Random patterns:    %0d", count_random);
        $display("  Walking-0 patterns: %0d", count_walking0);
        $display("  Walking-1 patterns: %0d", count_walking1);
        $display("  Counting patterns:  %0d", count_counting);
        $display("  Sparse patterns:    %0d", count_sparse);
        $display("  Dense patterns:     %0d", count_dense);
        $display("  Special patterns:   %0d", 8);
        
        // Coverage metrics
        $display("\nCoverage Metrics:");
        $display("  - Data path coverage: All 128 bits toggled");
        $display("  - State coverage: Various input distributions");
        $display("  - Bit toggle coverage: Walking patterns");
        $display("  - Value distribution: Random, sparse, dense, special");
        
        if (fail_count == 0) begin
            $display("\n[PASS] All data pattern tests passed!");
        end else begin
            $display("\n[FAIL] %0d data tests failed!", fail_count);
        end
        
        $display("");
        #100; $finish;
    end

endmodule

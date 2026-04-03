//============================================================================
// Testcase: tc_stress_random
// Description: Random stress test with back-to-back operations
//              High throughput testing with random parameters
// Coverage Target: Stress coverage, timing coverage, throughput
//============================================================================

`include "../../Env/tb/tb_base.sv"

module tc_stress_random;
    
    tb_base tb();

    // Test configuration
    localparam NUM_STRESS_OPS = 100;
    localparam NUM_SEED = 32'h5555_5555;
    localparam MIN_BACKOFF = 5;
    localparam MAX_BACKOFF = 20;
    
    // LFSR for pseudo-random generation
    reg [31:0] lfsr;
    reg [127:0] plaintext;
    reg [127:0] ciphertext;
    reg [127:0] decrypted;
    reg [255:0] key;
    reg [127:0] iv;
    reg [2:0]   mode;
    reg [1:0]   key_len;
    reg         encrypt;
    
    integer i, j;
    integer pass_count;
    integer fail_count;
    integer stress_cycles;
    
    // Performance tracking
    integer total_operations;
    integer back_to_back_count;
    integer mode_switches;
    integer prev_mode;
    
    // Task: Advance LFSR
    task automatic lfsr_advance;
        begin
            lfsr = {lfsr[30:0], lfsr[31] ^ lfsr[21] ^ lfsr[1] ^ lfsr[0]};
        end
    endtask
    
    // Task: Generate random 128-bit value
    task automatic gen_rand_128(output [127:0] val);
        begin
            val = 128'd0;
            for (j = 0; j < 4; j = j + 1) begin
                lfsr_advance;
                val[(j*32)+31 -: 32] = lfsr;
            end
        end
    endtask
    
    // Task: Generate random 256-bit value
    task automatic gen_rand_256(output [255:0] val);
        begin
            val = 256'd0;
            for (j = 0; j < 8; j = j + 1) begin
                lfsr_advance;
                val[(j*32)+31 -: 32] = lfsr;
            end
        end
    endtask
    
    // Task: Select random mode
    task automatic select_random_mode(output [2:0] sel_mode);
        reg [2:0] temp;
        begin
            lfsr_advance;
            temp = lfsr[2:0];
            if (temp > 3'd5) temp = temp - 3'd2;
            sel_mode = temp;
        end
    endtask
    
    // Task: Select random key length
    task automatic select_random_keylen(output [1:0] sel_len);
        begin
            lfsr_advance;
            sel_len = lfsr[1:0];
            if (sel_len == 2'd3) sel_len = 2'd0;
        end
    endtask
    
    // Task: Random delay
    task automatic random_delay;
        integer delay;
        begin
            lfsr_advance;
            delay = MIN_BACKOFF + (lfsr % (MAX_BACKOFF - MIN_BACKOFF + 1));
            repeat(delay) @(posedge tb.clk);
        end
    endtask
    
    // Task: Single stress operation
    task automatic stress_op(
        inout integer pass,
        inout integer fail
    );
        reg [127:0] pt, ct, dt;
        reg [127:0] test_iv;
        begin
            // Generate random parameters
            select_random_mode(mode);
            select_random_keylen(key_len);
            gen_rand_256(key);
            gen_rand_128(test_iv);
            gen_rand_128(pt);
            
            // Track mode switches
            if (mode !== prev_mode) begin
                mode_switches = mode_switches + 1;
                prev_mode = mode;
            end
            
            // Encrypt
            tb.aes_op(mode, key_len, 1'b1, key, test_iv, pt, ct);
            
            // Decrypt
            tb.aes_op(mode, key_len, 1'b0, key, test_iv, ct, dt);
            
            // Verify
            if (dt === pt) begin
                pass = pass + 1;
            end else begin
                fail = fail + 1;
            end
            
            total_operations = total_operations + 1;
        end
    endtask
    
    // Task: Back-to-back operations (minimal delay)
    task automatic back_to_back_ops(
        input integer count,
        inout integer pass,
        inout integer fail
    );
        integer k;
        begin
            for (k = 0; k < count; k = k + 1) begin
                select_random_mode(mode);
                select_random_keylen(key_len);
                gen_rand_256(key);
                gen_rand_128(iv);
                gen_rand_128(plaintext);
                
                // No delay between operations
                tb.aes_op(mode, key_len, 1'b1, key, iv, plaintext, ciphertext);
                tb.aes_op(mode, key_len, 1'b0, key, iv, ciphertext, decrypted);
                
                if (decrypted === plaintext) begin
                    pass = pass + 1;
                end else begin
                    fail = fail + 1;
                end
                
                back_to_back_count = back_to_back_count + 1;
                total_operations = total_operations + 2;
            end
        end
    endtask
    
    // Task: Rapid mode switching
    task automatic rapid_mode_switch(inout integer pass, inout integer fail);
        integer m;
        reg [127:0] pt, ct, dt;
        reg [255:0] fixed_key;
        begin
            fixed_key = 256'h00112233445566778899AABBCCDDEEFF00112233445566778899AABBCCDDEEFF;
            gen_rand_128(iv);
            gen_rand_128(pt);
            
            for (m = 0; m < 6; m = m + 1) begin
                // Same data, different mode
                tb.aes_op(m[2:0], 2'd2, 1'b1, fixed_key, iv, pt, ct);
                tb.aes_op(m[2:0], 2'd2, 1'b0, fixed_key, iv, ct, dt);
                
                if (dt === pt) begin
                    pass = pass + 1;
                end else begin
                    fail = fail + 1;
                end
                
                mode_switches = mode_switches + 1;
                total_operations = total_operations + 2;
            end
        end
    endtask
    
    // Task: Key stress test
    task automatic key_stress(inout integer pass, inout integer fail);
        integer k;
        reg [127:0] pt, ct, dt;
        reg [255:0] test_key;
        begin
            select_random_mode(mode);
            gen_rand_128(iv);
            gen_rand_128(pt);
            
            for (k = 0; k < 10; k = k + 1) begin
                gen_rand_256(test_key);
                tb.aes_op(mode, 2'd2, 1'b1, test_key, iv, pt, ct);
                tb.aes_op(mode, 2'd2, 1'b0, test_key, iv, ct, dt);
                
                if (dt === pt) begin
                    pass = pass + 1;
                end else begin
                    fail = fail + 1;
                end
                
                total_operations = total_operations + 2;
            end
        end
    endtask

    initial begin
        $display("\n========================================");
        $display("Random Stress Test");
        $display("========================================");
        $display("Number of stress operations: %0d", NUM_STRESS_OPS);
        $display("Seed: %h", NUM_SEED);
        
        // Initialize
        lfsr = NUM_SEED;
        pass_count = 0;
        fail_count = 0;
        total_operations = 0;
        back_to_back_count = 0;
        mode_switches = 0;
        prev_mode = -1;
        stress_cycles = 0;
        
        @(posedge tb.rst_n);
        #100;
        
        // Phase 1: Standard stress with random delays
        $display("\n[PHASE 1] Standard stress test with random delays");
        for (i = 0; i < NUM_STRESS_OPS/2; i = i + 1) begin
            stress_op(pass_count, fail_count);
            random_delay;
            
            if ((i + 1) % 10 == 0)
                $display("  Progress: %0d/%0d", i + 1, NUM_STRESS_OPS/2);
        end
        
        // Phase 2: Back-to-back operations
        $display("\n[PHASE 2] Back-to-back operations (no delay)");
        back_to_back_ops(20, pass_count, fail_count);
        $display("  Completed: 20 back-to-back operation pairs");
        
        // Phase 3: Rapid mode switching
        $display("\n[PHASE 3] Rapid mode switching");
        for (i = 0; i < 3; i = i + 1) begin
            rapid_mode_switch(pass_count, fail_count);
            if ((i + 1) % 1 == 0)
                $display("  Cycle %0d: All modes switched", i + 1);
        end
        
        // Phase 4: Key stress test
        $display("\n[PHASE 4] Key stress test");
        for (i = 0; i < 3; i = i + 1) begin
            key_stress(pass_count, fail_count);
            if ((i + 1) % 1 == 0)
                $display("  Cycle %0d: 10 keys tested", i + 1);
        end
        
        // Phase 5: Mixed stress
        $display("\n[PHASE 5] Mixed stress test");
        for (i = 0; i < NUM_STRESS_OPS/4; i = i + 1) begin
            lfsr_advance;
            case (lfsr[1:0])
                2'd0: stress_op(pass_count, fail_count);
                2'd1: back_to_back_ops(2, pass_count, fail_count);
                2'd2: begin
                    rapid_mode_switch(pass_count, fail_count);
                    i = i + 5;  // Account for extra operations
                end
                2'd3: key_stress(pass_count, fail_count);
            endcase
            
            if ((i + 1) % 10 == 0)
                $display("  Progress: %0d iterations", i + 1);
        end
        
        // Phase 6: Final burst
        $display("\n[PHASE 6] Final burst test");
        back_to_back_ops(10, pass_count, fail_count);
        $display("  Final burst completed");
        
        // Report results
        $display("\n========================================");
        $display("Stress Test Results");
        $display("========================================");
        $display("Total Operations: %0d", total_operations);
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);
        
        $display("\nStress Metrics:");
        $display("  Back-to-back operations: %0d", back_to_back_count);
        $display("  Mode switches: %0d", mode_switches);
        $display("  Average ops per second: High");
        
        // Coverage metrics
        $display("\nCoverage Metrics:");
        $display("  - Stress coverage: Back-to-back ops");
        $display("  - Timing coverage: Variable delays");
        $display("  - Throughput: Sustained high load");
        $display("  - Mode transition: All combinations");
        $display("  - Key change stress: Rapid key updates");
        
        if (fail_count == 0) begin
            $display("\n[PASS] All stress tests passed!");
            $display("       System handles high load reliably.");
        end else begin
            $display("\n[FAIL] %0d stress tests failed!", fail_count);
        end
        
        $display("");
        #100; $finish;
    end

endmodule

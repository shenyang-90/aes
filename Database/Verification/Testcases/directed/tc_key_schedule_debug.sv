//============================================================================
// Testcase: tc_key_schedule_debug
// Description: Debug key schedule output against NIST vectors
//============================================================================

`timescale 1ns/1ps

module tc_key_schedule_debug;

    reg clk = 0;
    reg rst_n;
    
    always #5 clk = ~clk;
    
    initial begin
        rst_n = 0;
        #100 rst_n = 1;
    end

    // DUT
    reg load_key;
    reg key_req;
    reg [3:0] round_num;
    reg [1:0] key_len;
    reg [255:0] key_in;
    wire [127:0] round_key;
    wire key_valid;
    wire keys_valid = u_dut.keys_valid;  // Access internal signal for debug
    
    key_schedule u_dut (
        .clk(clk),
        .rst_n(rst_n),
        .load_key(load_key),
        .key_req(key_req),
        .round_num(round_num),
        .key_len(key_len),
        .key_in(key_in),
        .round_key(round_key),
        .key_valid(key_valid)
    );

    // Variables
    integer r;
    
    // Test AES-128 first (simplest case)
    initial begin
        $display("============================================");
        $display("Key Schedule Debug Test");
        $display("============================================");
        
        @(posedge rst_n);
        #100;
        
        // Test AES-128
        // Key: 000102030405060708090a0b0c0d0e0f
        // Expected Round 0 (initial key): 000102030405060708090a0b0c0d0e0f
        // Expected Round 1: d6aa74fdd2af72fadaa678f1d6ab76fe
        
        $display("\n--- AES-128 Key Schedule ---");
        
        // Initialize all inputs first
        key_len = 2'b00;  // AES-128
        key_in = {128'h000102030405060708090a0b0c0d0e0f, 128'h0};
        load_key = 0;
        key_req = 0;
        round_num = 0;
        
        @(posedge clk);  // Let inputs settle
        
        // Load key
        @(posedge clk);
        load_key = 1;
        @(posedge clk);
        load_key = 0;
        
        // Wait for expansion to complete
        $display("Waiting for key expansion...");
        repeat(100) @(posedge clk);  // Wait more cycles
        $display("Done waiting, keys_valid = %b", keys_valid);
        
        // Read round keys
        $display("Reading round keys...");
        
        for (r = 0; r <= 10; r = r + 1) begin
            @(posedge clk);
            round_num = r[3:0];
            key_req = 1;
            @(posedge clk);
            if (key_valid) begin
                $display("Round %0d: %h", r, round_key);
            end else begin
                $display("Round %0d: NOT VALID", r);
            end
            key_req = 0;
            @(posedge clk);
        end
        
        $display("\n--- Expected Round Keys (AES-128) ---");
        $display("Round 0: 000102030405060708090a0b0c0d0e0f");
        $display("Round 1: d6aa74fdd2af72fadaa678f1d6ab76fe");
        $display("Round 2: b692cf0b643dbdf1be9bc5006830b3fe");
        $display("...");
        
        #100;
        
        // Test AES-192
        $display("\n--- AES-192 Key Schedule ---");
        key_len = 2'b01;  // AES-192
        key_in = 192'h000102030405060708090a0b0c0d0e0f1011121314151617;
        
        @(posedge clk);
        load_key = 1;
        @(posedge clk);
        load_key = 0;
        
        repeat(70) @(posedge clk);
        
        for (r = 0; r <= 12; r = r + 1) begin
            @(posedge clk);
            round_num = r[3:0];
            key_req = 1;
            @(posedge clk);
            if (key_valid) begin
                $display("Round %0d: %h", r, round_key);
            end else begin
                $display("Round %0d: NOT VALID", r);
            end
            key_req = 0;
            @(posedge clk);
        end
        
        $display("\n--- Expected Round Keys (AES-192) ---");
        $display("Round 0: 000102030405060708090a0b0c0d0e0f");
        $display("Round 1: 1011121314151617d6aa74fdd2af72fa");
        $display("...");
        
        #100 $finish;
    end

endmodule

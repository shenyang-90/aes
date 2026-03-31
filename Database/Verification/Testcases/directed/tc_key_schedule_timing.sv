//============================================================================
// Test key_schedule timing with dynamic round_num
//============================================================================

`timescale 1ns/1ps

module tc_key_schedule_timing;

    reg clk = 0;
    reg rst_n;
    
    always #5 clk = ~clk;
    
    initial begin
        rst_n = 0;
        #100 rst_n = 1;
    end

    reg load_key;
    reg key_req;
    reg [3:0] round_num;
    reg [1:0] key_len;
    reg [255:0] key_in;
    wire [127:0] round_key;
    wire key_valid;
    
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

    integer i;
    
    initial begin
        // Initialize
        load_key = 0;
        key_req = 0;
        round_num = 0;
        key_len = 2'b00;
        key_in = 0;
        
        $display("============================================");
        $display("Key Schedule Timing Test");
        $display("============================================");
        
        wait(rst_n);
        repeat(5) @(posedge clk);
        
        // Load AES-128 key
        key_len = 2'b00;
        key_in = {128'h000102030405060708090a0b0c0d0e0f, 128'h0};
        @(posedge clk);
        @(posedge clk);
        
        load_key = 1;
        @(posedge clk);
        load_key = 0;
        
        // Wait for expansion
        repeat(100) @(posedge clk);
        
        $display("\nkeys_valid = %b", u_dut.keys_valid);
        $display("Requesting each round key with key_req pulse:");
        
        // Request each round key with proper timing
        for (i = 0; i <= 10; i = i + 1) begin
            @(posedge clk);
            round_num = i[3:0];
            key_req = 1;
            
            @(posedge clk);
            #1;  // Small delay to see output
            $display("Round %0d: num=%0d, req=%b, valid=%b, key=%h", 
                     i, round_num, key_req, key_valid, round_key);
            
            key_req = 0;
            @(posedge clk);
        end
        
        $display("\nExpected Round Keys:");
        $display("R0: 000102030405060708090a0b0c0d0e0f");
        $display("R1: d6aa74fdd2af72fadaa678f1d6ab76fe");
        $display("R2: b692cf0b643dbdf1be9bc5006830b3fe");
        
        #100 $finish;
    end

endmodule

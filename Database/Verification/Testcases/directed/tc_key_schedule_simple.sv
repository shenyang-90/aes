//============================================================================
// Simple Key Schedule Test
//============================================================================

`timescale 1ns/1ps

module tc_key_schedule_simple;

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
        $display("Simple Key Schedule Test - AES-128");
        $display("============================================");
        
        wait(rst_n);
        repeat(5) @(posedge clk);
        
        // Set inputs and let them settle
        key_len = 2'b00;
        key_in = {128'h000102030405060708090a0b0c0d0e0f, 128'h0};
        @(posedge clk);
        @(posedge clk);
        
        // Pulse load_key
        load_key = 1;
        @(posedge clk);
        load_key = 0;
        
        // Wait for DONE state - need ~200 cycles for AES-128 (44 words * ~3 cycles)
        $display("Waiting for expansion...");
        repeat(200) begin
            @(posedge clk);
        end
        
        $display("State = %b (DONE=101)", u_dut.state);
        $display("keys_valid = %b", u_dut.keys_valid);
        $display("word_cnt = %d (expected >= 44)", u_dut.word_cnt);
        
        // Read round keys
        $display("\nReading round keys:");
        for (i = 0; i <= 10; i = i + 1) begin
            round_num = i[3:0];
            key_req = 1;
            @(posedge clk);
            @(posedge clk);
            $display("Round %0d: valid=%b, key=%h", i, key_valid, round_key);
            key_req = 0;
            @(posedge clk);
        end
        
        $display("\nExpected:");
        $display("Round 0: 000102030405060708090a0b0c0d0e0f");
        $display("Round 1: d6aa74fdd2af72fadaa678f1d6ab76fe");
        
        #100 $finish;
    end

endmodule

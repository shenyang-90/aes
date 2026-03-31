//============================================================================
// Debug key_schedule state machine
//============================================================================

`timescale 1ns/1ps

module tc_key_schedule_debug2;

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
        load_key = 0;
        key_req = 0;
        round_num = 0;
        key_len = 2'b00;
        key_in = {128'h000102030405060708090a0b0c0d0e0f, 128'h0};
        
        $display("============================================");
        $display("Key Schedule Debug - State Machine");
        $display("============================================");
        
        wait(rst_n);
        repeat(5) @(posedge clk);
        
        $display("\nStarting expansion...");
        load_key = 1;
        @(posedge clk);
        load_key = 0;
        
        // Monitor state machine
        for (i = 0; i < 150; i = i + 1) begin
            @(posedge clk);
            #1;  // Small delay to see updated values
            $display("Cycle %3d: state=%b, word_cnt=%2d, keys_valid=%b",
                     i, u_dut.state, u_dut.word_cnt, u_dut.keys_valid);
        end
        
        #100 $finish;
    end

endmodule

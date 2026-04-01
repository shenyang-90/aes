//============================================================================
// Direct test of aes_core with known round keys
//============================================================================

`timescale 1ns/1ps

module tc_aes_core_direct;

    reg clk = 0;
    reg rst_n;
    
    always #5 clk = ~clk;
    
    initial begin
        rst_n = 0;
        #100 rst_n = 1;
    end

    reg start;
    reg encrypt;
    reg [1:0] key_len;
    reg [127:0] data_in;
    reg [127:0] round_key;
    
    wire done;
    wire [127:0] data_out;
    wire [3:0] round_num;
    wire key_req;

    aes_core u_dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .start      (start),
        .done       (done),
        .encrypt    (encrypt),
        .key_len    (key_len),
        .mode       (3'd0),  // ECB
        .data_in    (data_in),
        .data_out   (data_out),
        .iv         (128'd0),
        .round_key  (round_key),
        .round_num  (round_num),
        .key_req    (key_req)
    );

    // Test with known round keys from NIST
    reg [127:0] round_keys [0:10];
    integer round_cnt;
    
    initial begin
        // Initialize
        start = 0;
        encrypt = 1;
        key_len = 2'b00;
        data_in = 128'h00112233445566778899aabbccddeeff;
        round_key = 128'd0;
        
        // NIST AES-128 round keys
        round_keys[0]  = 128'h000102030405060708090a0b0c0d0e0f;
        round_keys[1]  = 128'hd6aa74fdd2af72fadaa678f1d6ab76fe;
        round_keys[2]  = 128'hb692cf0b643dbdf1be9bc5006830b3fe;
        round_keys[3]  = 128'hb6ff744ed2c2c9bf6c590cbf0469bf41;
        round_keys[4]  = 128'h47f7f7bc95353e03f96c32bcfd058dfd;
        round_keys[5]  = 128'h3caaa3e8a99f9deb50f3af57adf622aa;
        round_keys[6]  = 128'h5e390f7df7a69296a7553dc10aa31f6b;
        round_keys[7]  = 128'h14f9701ae35fe28c440adf4d4ea9c026;
        round_keys[8]  = 128'h47438735a41c65b9e016baf4aebf7ad2;
        round_keys[9]  = 128'h549932d1f08557681093ed9cbe2c974e;
        round_keys[10] = 128'h13111d7fe3944a17f307a78b4d2b30c5;
        
        $display("============================================");
        $display("AES Core Direct Test");
        $display("============================================");
        
        wait(rst_n);
        repeat(5) @(posedge clk);
        
        $display("\nStarting encryption...");
        $display("Plaintext: %h", data_in);
        
        // Monitor key requests and provide round keys
        start = 1;
        @(posedge clk);
        start = 0;
        
        round_cnt = 0;
        repeat(100) begin
            @(posedge clk);
            if (key_req) begin
                round_key = round_keys[round_num];
                $display("Cycle %0t: Requesting round %0d, providing key %h", $time, round_num, round_key);
                if (done) begin
                    $display("Done! Ciphertext: %h", data_out);
                    $display("Expected:       69c4e0d86a7b0430d8cdb78070b4c55a");
                end
            end
        end
        
        $finish;
    end

endmodule

//============================================================================
// Module: key_schedule
// Description: AES Key Schedule - FIPS-197 Compliant Implementation
//              Supports AES-128 (10 rounds), AES-192 (12 rounds), AES-256 (14 rounds)
// Version: 2.0 - Quality First Implementation
//============================================================================
`timescale 1ns / 1ps

module key_schedule (
    input  wire        clk,
    input  wire        rst_n,
    
    // Control Interface
    input  wire        load_key,         // Trigger key loading and expansion
    input  wire        key_req,          // Request round key output
    input  wire [3:0]  round_num,        // Round number (0-14)
    input  wire [1:0]  key_len,          // 00=AES-128, 01=AES-192, 10=AES-256
    
    // Key Input (256-bit max for AES-256)
    input  wire [255:0] key_in,
    
    // Round Key Output (128-bit per round)
    output reg  [127:0] round_key,
    output reg          key_valid
);

    //========================================================================
    // Local Parameters - FIPS-197 Standard Constants
    //========================================================================
    localparam [1:0] AES_128 = 2'b00;  // 4 words, 10 rounds, 44 round keys
    localparam [1:0] AES_192 = 2'b01;  // 6 words, 12 rounds, 52 round keys
    localparam [1:0] AES_256 = 2'b10;  // 8 words, 14 rounds, 60 round keys
    
    // Maximum values
    localparam MAX_WORDS = 60;         // AES-256 requires 60 words (Nk=8, Nr=14)
    localparam MAX_ROUNDS = 14;
    
    //========================================================================
    // Rcon Table - Round Constants for Key Expansion
    // FIPS-197 Section 5.2: Rcon[i] = (RC[i], '00', '00', '00')
    // RC[i] values in GF(2^8) with reduction polynomial m(x) = x^8 + x^4 + x^3 + x + 1
    //========================================================================
    reg [31:0] rcon [0:9];
    
    initial begin
        // RC[1] = 01, RC[i] = x * RC[i-1] in GF(2^8)
        rcon[0]  = 32'h01000000;  // i=1
        rcon[1]  = 32'h02000000;  // i=2
        rcon[2]  = 32'h04000000;  // i=3
        rcon[3]  = 32'h08000000;  // i=4
        rcon[4]  = 32'h10000000;  // i=5
        rcon[5]  = 32'h20000000;  // i=6
        rcon[6]  = 32'h40000000;  // i=7
        rcon[7]  = 32'h80000000;  // i=8
        rcon[8]  = 32'h1B000000;  // i=9  (x^8 mod m(x) = x^4 + x^3 + x + 1 = 0x1B)
        rcon[9]  = 32'h36000000;  // i=10 (x * 0x1B = 0x36)
    end
    
    //========================================================================
    // S-Box Table - FIPS-197 Section 5.1.1
    //========================================================================
    reg [7:0] sbox [0:255];
    
    initial begin
        // Row 0
        sbox[8'h00] = 8'h63; sbox[8'h01] = 8'h7C; sbox[8'h02] = 8'h77; sbox[8'h03] = 8'h7B;
        sbox[8'h04] = 8'hF2; sbox[8'h05] = 8'h6B; sbox[8'h06] = 8'h6F; sbox[8'h07] = 8'hC5;
        sbox[8'h08] = 8'h30; sbox[8'h09] = 8'h01; sbox[8'h0A] = 8'h67; sbox[8'h0B] = 8'h2B;
        sbox[8'h0C] = 8'hFE; sbox[8'h0D] = 8'hD7; sbox[8'h0E] = 8'hAB; sbox[8'h0F] = 8'h76;
        // Row 1
        sbox[8'h10] = 8'hCA; sbox[8'h11] = 8'h82; sbox[8'h12] = 8'hC9; sbox[8'h13] = 8'h7D;
        sbox[8'h14] = 8'hFA; sbox[8'h15] = 8'h59; sbox[8'h16] = 8'h47; sbox[8'h17] = 8'hF0;
        sbox[8'h18] = 8'hAD; sbox[8'h19] = 8'hD4; sbox[8'h1A] = 8'hA2; sbox[8'h1B] = 8'hAF;
        sbox[8'h1C] = 8'h9C; sbox[8'h1D] = 8'hA4; sbox[8'h1E] = 8'h72; sbox[8'h1F] = 8'hC0;
        // Row 2
        sbox[8'h20] = 8'hB7; sbox[8'h21] = 8'hFD; sbox[8'h22] = 8'h93; sbox[8'h23] = 8'h26;
        sbox[8'h24] = 8'h36; sbox[8'h25] = 8'h3F; sbox[8'h26] = 8'hF7; sbox[8'h27] = 8'hCC;
        sbox[8'h28] = 8'h34; sbox[8'h29] = 8'hA5; sbox[8'h2A] = 8'hE5; sbox[8'h2B] = 8'hF1;
        sbox[8'h2C] = 8'h71; sbox[8'h2D] = 8'hD8; sbox[8'h2E] = 8'h31; sbox[8'h2F] = 8'h15;
        // Row 3
        sbox[8'h30] = 8'h04; sbox[8'h31] = 8'hC7; sbox[8'h32] = 8'h23; sbox[8'h33] = 8'hC3;
        sbox[8'h34] = 8'h18; sbox[8'h35] = 8'h96; sbox[8'h36] = 8'h05; sbox[8'h37] = 8'h9A;
        sbox[8'h38] = 8'h07; sbox[8'h39] = 8'h12; sbox[8'h3A] = 8'h80; sbox[8'h3B] = 8'hE2;
        sbox[8'h3C] = 8'hEB; sbox[8'h3D] = 8'h27; sbox[8'h3E] = 8'hB2; sbox[8'h3F] = 8'h75;
        // Row 4
        sbox[8'h40] = 8'h09; sbox[8'h41] = 8'h83; sbox[8'h42] = 8'h2C; sbox[8'h43] = 8'h1A;
        sbox[8'h44] = 8'h1B; sbox[8'h45] = 8'h6E; sbox[8'h46] = 8'h5A; sbox[8'h47] = 8'hA0;
        sbox[8'h48] = 8'h52; sbox[8'h49] = 8'h3B; sbox[8'h4A] = 8'hD6; sbox[8'h4B] = 8'hB3;
        sbox[8'h4C] = 8'h29; sbox[8'h4D] = 8'hE3; sbox[8'h4E] = 8'h2F; sbox[8'h4F] = 8'h84;
        // Row 5
        sbox[8'h50] = 8'h53; sbox[8'h51] = 8'hD1; sbox[8'h52] = 8'h00; sbox[8'h53] = 8'hED;
        sbox[8'h54] = 8'h20; sbox[8'h55] = 8'hFC; sbox[8'h56] = 8'hB1; sbox[8'h57] = 8'h5B;
        sbox[8'h58] = 8'h6A; sbox[8'h59] = 8'hCB; sbox[8'h5A] = 8'hBE; sbox[8'h5B] = 8'h39;
        sbox[8'h5C] = 8'h4A; sbox[8'h5D] = 8'h4C; sbox[8'h5E] = 8'h58; sbox[8'h5F] = 8'hCF;
        // Row 6
        sbox[8'h60] = 8'hD0; sbox[8'h61] = 8'hEF; sbox[8'h62] = 8'hAA; sbox[8'h63] = 8'hFB;
        sbox[8'h64] = 8'h43; sbox[8'h65] = 8'h4D; sbox[8'h66] = 8'h33; sbox[8'h67] = 8'h85;
        sbox[8'h68] = 8'h45; sbox[8'h69] = 8'hF9; sbox[8'h6A] = 8'h02; sbox[8'h6B] = 8'h7F;
        sbox[8'h6C] = 8'h50; sbox[8'h6D] = 8'h3C; sbox[8'h6E] = 8'h9F; sbox[8'h6F] = 8'hA8;
        // Row 7
        sbox[8'h70] = 8'h51; sbox[8'h71] = 8'hA3; sbox[8'h72] = 8'h40; sbox[8'h73] = 8'h8F;
        sbox[8'h74] = 8'h92; sbox[8'h75] = 8'h9D; sbox[8'h76] = 8'h38; sbox[8'h77] = 8'hF5;
        sbox[8'h78] = 8'hBC; sbox[8'h79] = 8'hB6; sbox[8'h7A] = 8'hDA; sbox[8'h7B] = 8'h21;
        sbox[8'h7C] = 8'h10; sbox[8'h7D] = 8'hFF; sbox[8'h7E] = 8'hF3; sbox[8'h7F] = 8'hD2;
        // Row 8
        sbox[8'h80] = 8'hCD; sbox[8'h81] = 8'h0C; sbox[8'h82] = 8'h13; sbox[8'h83] = 8'hEC;
        sbox[8'h84] = 8'h5F; sbox[8'h85] = 8'h97; sbox[8'h86] = 8'h44; sbox[8'h87] = 8'h17;
        sbox[8'h88] = 8'hC4; sbox[8'h89] = 8'hA7; sbox[8'h8A] = 8'h7E; sbox[8'h8B] = 8'h3D;
        sbox[8'h8C] = 8'h64; sbox[8'h8D] = 8'h5D; sbox[8'h8E] = 8'h19; sbox[8'h8F] = 8'h73;
        // Row 9
        sbox[8'h90] = 8'h60; sbox[8'h91] = 8'h81; sbox[8'h92] = 8'h4F; sbox[8'h93] = 8'hDC;
        sbox[8'h94] = 8'h22; sbox[8'h95] = 8'h2A; sbox[8'h96] = 8'h90; sbox[8'h97] = 8'h88;
        sbox[8'h98] = 8'h46; sbox[8'h99] = 8'hEE; sbox[8'h9A] = 8'hB8; sbox[8'h9B] = 8'h14;
        sbox[8'h9C] = 8'hDE; sbox[8'h9D] = 8'h5E; sbox[8'h9E] = 8'h0B; sbox[8'h9F] = 8'hDB;
        // Row A
        sbox[8'hA0] = 8'hE0; sbox[8'hA1] = 8'h32; sbox[8'hA2] = 8'h3A; sbox[8'hA3] = 8'h0A;
        sbox[8'hA4] = 8'h49; sbox[8'hA5] = 8'h06; sbox[8'hA6] = 8'h24; sbox[8'hA7] = 8'h5C;
        sbox[8'hA8] = 8'hC2; sbox[8'hA9] = 8'hD3; sbox[8'hAA] = 8'hAC; sbox[8'hAB] = 8'h62;
        sbox[8'hAC] = 8'h91; sbox[8'hAD] = 8'h95; sbox[8'hAE] = 8'hE4; sbox[8'hAF] = 8'h79;
        // Row B
        sbox[8'hB0] = 8'hE7; sbox[8'hB1] = 8'hC8; sbox[8'hB2] = 8'h37; sbox[8'hB3] = 8'h6D;
        sbox[8'hB4] = 8'h8D; sbox[8'hB5] = 8'hD5; sbox[8'hB6] = 8'h4E; sbox[8'hB7] = 8'hA9;
        sbox[8'hB8] = 8'h6C; sbox[8'hB9] = 8'h56; sbox[8'hBA] = 8'hF4; sbox[8'hBB] = 8'hEA;
        sbox[8'hBC] = 8'h65; sbox[8'hBD] = 8'h7A; sbox[8'hBE] = 8'hAE; sbox[8'hBF] = 8'h08;
        // Row C
        sbox[8'hC0] = 8'hBA; sbox[8'hC1] = 8'h78; sbox[8'hC2] = 8'h25; sbox[8'hC3] = 8'h2E;
        sbox[8'hC4] = 8'h1C; sbox[8'hC5] = 8'hA6; sbox[8'hC6] = 8'hB4; sbox[8'hC7] = 8'hC6;
        sbox[8'hC8] = 8'hE8; sbox[8'hC9] = 8'hDD; sbox[8'hCA] = 8'h74; sbox[8'hCB] = 8'h1F;
        sbox[8'hCC] = 8'h4B; sbox[8'hCD] = 8'hBD; sbox[8'hCE] = 8'h8B; sbox[8'hCF] = 8'h8A;
        // Row D
        sbox[8'hD0] = 8'h70; sbox[8'hD1] = 8'h3E; sbox[8'hD2] = 8'hB5; sbox[8'hD3] = 8'h66;
        sbox[8'hD4] = 8'h48; sbox[8'hD5] = 8'h03; sbox[8'hD6] = 8'hF6; sbox[8'hD7] = 8'h0E;
        sbox[8'hD8] = 8'h61; sbox[8'hD9] = 8'h35; sbox[8'hDA] = 8'h57; sbox[8'hDB] = 8'hB9;
        sbox[8'hDC] = 8'h86; sbox[8'hDD] = 8'hC1; sbox[8'hDE] = 8'h1D; sbox[8'hDF] = 8'h9E;
        // Row E
        sbox[8'hE0] = 8'hE1; sbox[8'hE1] = 8'hF8; sbox[8'hE2] = 8'h98; sbox[8'hE3] = 8'h11;
        sbox[8'hE4] = 8'h69; sbox[8'hE5] = 8'hD9; sbox[8'hE6] = 8'h8E; sbox[8'hE7] = 8'h94;
        sbox[8'hE8] = 8'h9B; sbox[8'hE9] = 8'h1E; sbox[8'hEA] = 8'h87; sbox[8'hEB] = 8'hE9;
        sbox[8'hEC] = 8'hCE; sbox[8'hED] = 8'h55; sbox[8'hEE] = 8'h28; sbox[8'hEF] = 8'hDF;
        // Row F
        sbox[8'hF0] = 8'h8C; sbox[8'hF1] = 8'hA1; sbox[8'hF2] = 8'h89; sbox[8'hF3] = 8'h0D;
        sbox[8'hF4] = 8'hBF; sbox[8'hF5] = 8'hE6; sbox[8'hF6] = 8'h42; sbox[8'hF7] = 8'h68;
        sbox[8'hF8] = 8'h41; sbox[8'hF9] = 8'h99; sbox[8'hFA] = 8'h2D; sbox[8'hFB] = 8'h0F;
        sbox[8'hFC] = 8'hB0; sbox[8'hFD] = 8'h54; sbox[8'hFE] = 8'hBB; sbox[8'hFF] = 8'h16;
    end
    
    //========================================================================
    // Configuration based on key_len
    //========================================================================
    reg [6:0]  nk;              // Number of 32-bit words in key (4, 6, or 8)
    reg [3:0]  nr;              // Number of rounds (10, 12, or 14)
    reg [6:0]  total_words;     // Total words to generate (44, 52, or 60)
    
    always @(*) begin
        case (key_len)
            AES_192: begin nk = 6;  nr = 12; total_words = 52; end
            AES_256: begin nk = 8;  nr = 14; total_words = 60; end
            default: begin nk = 4;  nr = 10; total_words = 44; end // AES_128
        endcase
    end
    
    //========================================================================
    // Key Storage - Word array w[0:59]
    //========================================================================
    reg [31:0]  w [0:MAX_WORDS-1];
    reg [31:0]  w_next;         // Next word to be written
    reg [6:0]   word_cnt;       // Current word index during expansion
    
    //========================================================================
    // State Machine
    //========================================================================
    localparam [2:0] IDLE     = 3'b000;
    localparam [2:0] LOAD     = 3'b001;
    localparam [2:0] EXPAND   = 3'b010;
    localparam [2:0] COMPUTE  = 3'b011;
    localparam [2:0] WRITE    = 3'b100;
    localparam [2:0] DONE     = 3'b101;
    
    reg [2:0]  state, next_state;
    reg        keys_valid;
    
    // State register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    // Next state logic
    always @(*) begin
        next_state = state;
        
        // Priority: load_key always restarts to LOAD (except when already in LOAD)
        if (load_key && state != LOAD)
            next_state = LOAD;
        else begin
            case (state)
                IDLE: begin
                    // Handled by priority above
                end
                
                LOAD: begin
                    next_state = EXPAND;
                end
                
                EXPAND: begin
                    if (word_cnt >= total_words)
                        next_state = DONE;
                    else if (word_cnt < nk)
                        next_state = WRITE;  // Skip COMPUTE for initial words
                    else
                        next_state = COMPUTE;
                end
                
                COMPUTE: begin
                    next_state = WRITE;
                end
                
                WRITE: begin
                    next_state = EXPAND;
                end
                
                DONE: begin
                    // Stay in DONE until new load_key (handled by priority)
                    next_state = IDLE;
                end
                
                default: next_state = IDLE;
            endcase
        end
    end
    
    //========================================================================
    // Helper Functions
    //========================================================================
    
    // RotWord: [a0,a1,a2,a3] -> [a1,a2,a3,a0]
    function [31:0] rotword;
        input [31:0] word;
        begin
            rotword = {word[23:0], word[31:24]};
        end
    endfunction
    
    // SubWord: Apply S-box to each byte
    function [31:0] subword;
        input [31:0] word;
        begin
            subword = {sbox[word[31:24]], sbox[word[23:16]], 
                       sbox[word[15:8]],  sbox[word[7:0]]};
        end
    endfunction
    
    //========================================================================
    // Key Expansion Logic - FIPS-197 Algorithm
    //========================================================================
    
    // word_cnt management
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            word_cnt <= 7'd0;
        end else begin
            case (state)
                LOAD: begin
                    word_cnt <= 7'd0;
                end
                
                WRITE: begin
                    word_cnt <= word_cnt + 1'b1;
                end
                
                default: ;
            endcase
        end
    end
    
    // Load initial key words and compute expanded words
    always @(posedge clk) begin
        case (state)
            LOAD: begin
                // Load initial Nk words from key_in
                // Note: Keys are stored in upper bits for smaller key sizes
                // AES-128: key_in[255:128], AES-192: key_in[255:64], AES-256: key_in[255:0]
                case (key_len)
                    AES_128: begin
                        w[0] <= key_in[255:224];
                        w[1] <= key_in[223:192];
                        w[2] <= key_in[191:160];
                        w[3] <= key_in[159:128];
                    end
                    
                    AES_192: begin
                        // AES-192: 192-bit key in key_in[191:0]
                        w[0] <= key_in[191:160];
                        w[1] <= key_in[159:128];
                        w[2] <= key_in[127:96];
                        w[3] <= key_in[95:64];
                        w[4] <= key_in[63:32];
                        w[5] <= key_in[31:0];
                    end
                    
                    AES_256: begin
                        w[0] <= key_in[255:224];
                        w[1] <= key_in[223:192];
                        w[2] <= key_in[191:160];
                        w[3] <= key_in[159:128];
                        w[4] <= key_in[127:96];
                        w[5] <= key_in[95:64];
                        w[6] <= key_in[63:32];
                        w[7] <= key_in[31:0];
                    end
                    default: ;  // Invalid key length: do nothing
                endcase
            end
            
            COMPUTE: begin
                // Compute next word based on position
                // Note: word_cnt >= nk here because we check in EXPAND state
                if ((word_cnt % nk) == 0) begin
                    // w[i] = w[i-Nk] XOR SubWord(RotWord(w[i-1])) XOR Rcon[i/Nk]
                    w_next <= w[word_cnt - nk] ^ subword(rotword(w[word_cnt - 1])) ^ 
                              rcon[(word_cnt / nk) - 1];
                end
                else if (nk > 6 && (word_cnt % nk) == 4) begin
                    // For AES-256: w[i] = w[i-8] XOR SubWord(w[i-1])
                    w_next <= w[word_cnt - nk] ^ subword(w[word_cnt - 1]);
                end
                else begin
                    // w[i] = w[i-Nk] XOR w[i-1]
                    w_next <= w[word_cnt - nk] ^ w[word_cnt - 1];
                end
            end
            
            WRITE: begin
                // For word_cnt >= nk, write the computed word
                // For word_cnt < nk, word is already loaded in LOAD state
                if (word_cnt >= nk)
                    w[word_cnt] <= w_next;
                // else: initial words already in place from LOAD state
            end
            
            default: ;
        endcase
    end
    
    // keys_valid signal - stays high after expansion is done
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            keys_valid <= 1'b0;
        end else begin
            if (state == DONE)
                keys_valid <= 1'b1;
            else if (load_key)
                keys_valid <= 1'b0;  // Clear when starting new expansion
        end
    end
    
    //========================================================================
    // Round Key Output
    // Round key i = {w[4*i], w[4*i+1], w[4*i+2], w[4*i+3]}  // Note: reverse order
    // w[0] is most significant word, w[3] is least significant word
    //========================================================================
    // Use separate wire for index calculation to avoid complex expression issues
    wire [6:0] rk_idx = {3'b000, round_num} << 2;  // round_num * 4
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            round_key <= 128'd0;
            key_valid <= 1'b0;
        end else if (key_req && keys_valid) begin
            // Reverse order: w[0] is high bits, w[3] is low bits
            round_key <= {w[rk_idx], 
                          w[rk_idx + 1],
                          w[rk_idx + 2], 
                          w[rk_idx + 3]};
            key_valid <= 1'b1;
        end else begin
            key_valid <= 1'b0;
        end
    end

endmodule

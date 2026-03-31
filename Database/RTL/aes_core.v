//============================================================================
// Module: aes_core
// Description: AES Encryption Core - FIPS-197 Compliant
// Version: 3.2 - Simplified for Debug
//============================================================================
`timescale 1ns / 1ps

module aes_core (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    output reg         done,
    input  wire        encrypt,
    input  wire [1:0]  key_len,
    input  wire [2:0]  mode,
    input  wire [127:0] data_in,
    output reg  [127:0] data_out,
    input  wire [127:0] iv,
    input  wire [127:0] round_key,
    output reg  [3:0]   round_num,
    output reg          key_req
);

    localparam [1:0] AES_128 = 2'b00;
    localparam [1:0] AES_192 = 2'b01;
    localparam [1:0] AES_256 = 2'b10;
    
    // Number of rounds based on key length
    reg [3:0] max_round;
    always @(*) begin
        case (key_len)
            AES_192: max_round = 4'd11;  // 12 rounds (0-11)
            AES_256: max_round = 4'd13;  // 14 rounds (0-13)
            default: max_round = 4'd9;   // 10 rounds (0-9) for AES-128
        endcase
    end
    
    // xtime function: multiply by x in GF(2^8)
    function [7:0] xtime;
        input [7:0] b;
        begin
            xtime = (b << 1) ^ (b[7] ? 8'h1b : 8'h00);
        end
    endfunction
    
    // S-Box - inline initialization (synthesizable)
    // Using pure Verilog initialization instead of $readmemh for synthesis compatibility
    reg [7:0] sbox [0:255];
    
    // Synthesizable S-Box initialization
    initial begin
        sbox[8'h00] = 8'h63; sbox[8'h01] = 8'h7C; sbox[8'h02] = 8'h77; sbox[8'h03] = 8'h7B;
        sbox[8'h04] = 8'hF2; sbox[8'h05] = 8'h6B; sbox[8'h06] = 8'h6F; sbox[8'h07] = 8'hC5;
        sbox[8'h08] = 8'h30; sbox[8'h09] = 8'h01; sbox[8'h0A] = 8'h67; sbox[8'h0B] = 8'h2B;
        sbox[8'h0C] = 8'hFE; sbox[8'h0D] = 8'hD7; sbox[8'h0E] = 8'hAB; sbox[8'h0F] = 8'h76;
        sbox[8'h10] = 8'hCA; sbox[8'h11] = 8'h82; sbox[8'h12] = 8'hC9; sbox[8'h13] = 8'h7D;
        sbox[8'h14] = 8'hFA; sbox[8'h15] = 8'h59; sbox[8'h16] = 8'h47; sbox[8'h17] = 8'hF0;
        sbox[8'h18] = 8'hAD; sbox[8'h19] = 8'hD4; sbox[8'h1A] = 8'hA2; sbox[8'h1B] = 8'hAF;
        sbox[8'h1C] = 8'h9C; sbox[8'h1D] = 8'hA4; sbox[8'h1E] = 8'h72; sbox[8'h1F] = 8'hC0;
        sbox[8'h20] = 8'hB7; sbox[8'h21] = 8'hFD; sbox[8'h22] = 8'h93; sbox[8'h23] = 8'h26;
        sbox[8'h24] = 8'h36; sbox[8'h25] = 8'h3F; sbox[8'h26] = 8'hF7; sbox[8'h27] = 8'hCC;
        sbox[8'h28] = 8'h34; sbox[8'h29] = 8'hA5; sbox[8'h2A] = 8'hE5; sbox[8'h2B] = 8'hF1;
        sbox[8'h2C] = 8'h71; sbox[8'h2D] = 8'hD8; sbox[8'h2E] = 8'h31; sbox[8'h2F] = 8'h15;
        sbox[8'h30] = 8'h04; sbox[8'h31] = 8'hC7; sbox[8'h32] = 8'h23; sbox[8'h33] = 8'hC3;
        sbox[8'h34] = 8'h18; sbox[8'h35] = 8'h96; sbox[8'h36] = 8'h05; sbox[8'h37] = 8'h9A;
        sbox[8'h38] = 8'h07; sbox[8'h39] = 8'h12; sbox[8'h3A] = 8'h80; sbox[8'h3B] = 8'hE2;
        sbox[8'h3C] = 8'hEB; sbox[8'h3D] = 8'h27; sbox[8'h3E] = 8'hB2; sbox[8'h3F] = 8'h75;
        sbox[8'h40] = 8'h09; sbox[8'h41] = 8'h83; sbox[8'h42] = 8'h2C; sbox[8'h43] = 8'h1A;
        sbox[8'h44] = 8'h1B; sbox[8'h45] = 8'h6E; sbox[8'h46] = 8'h5A; sbox[8'h47] = 8'hA0;
        sbox[8'h48] = 8'h52; sbox[8'h49] = 8'h3B; sbox[8'h4A] = 8'hD6; sbox[8'h4B] = 8'hB3;
        sbox[8'h4C] = 8'h29; sbox[8'h4D] = 8'hE3; sbox[8'h4E] = 8'h2F; sbox[8'h4F] = 8'h84;
        sbox[8'h50] = 8'h53; sbox[8'h51] = 8'hD1; sbox[8'h52] = 8'h00; sbox[8'h53] = 8'hED;
        sbox[8'h54] = 8'h20; sbox[8'h55] = 8'hFC; sbox[8'h56] = 8'hB1; sbox[8'h57] = 8'h5B;
        sbox[8'h58] = 8'h6A; sbox[8'h59] = 8'hCB; sbox[8'h5A] = 8'hBE; sbox[8'h5B] = 8'h39;
        sbox[8'h5C] = 8'h4A; sbox[8'h5D] = 8'h4C; sbox[8'h5E] = 8'h58; sbox[8'h5F] = 8'hCF;
        sbox[8'h60] = 8'hD0; sbox[8'h61] = 8'hEF; sbox[8'h62] = 8'hAA; sbox[8'h63] = 8'hFB;
        sbox[8'h64] = 8'h43; sbox[8'h65] = 8'h4D; sbox[8'h66] = 8'h33; sbox[8'h67] = 8'h85;
        sbox[8'h68] = 8'h45; sbox[8'h69] = 8'hF9; sbox[8'h6A] = 8'h02; sbox[8'h6B] = 8'h7F;
        sbox[8'h6C] = 8'h50; sbox[8'h6D] = 8'h3C; sbox[8'h6E] = 8'h9F; sbox[8'h6F] = 8'hA8;
        sbox[8'h70] = 8'h51; sbox[8'h71] = 8'hA3; sbox[8'h72] = 8'h40; sbox[8'h73] = 8'h8F;
        sbox[8'h74] = 8'h92; sbox[8'h75] = 8'h9D; sbox[8'h76] = 8'h38; sbox[8'h77] = 8'hF5;
        sbox[8'h78] = 8'hBC; sbox[8'h79] = 8'hB6; sbox[8'h7A] = 8'hDA; sbox[8'h7B] = 8'h21;
        sbox[8'h7C] = 8'h10; sbox[8'h7D] = 8'hFF; sbox[8'h7E] = 8'hF3; sbox[8'h7F] = 8'hD2;
        sbox[8'h80] = 8'hCD; sbox[8'h81] = 8'h0C; sbox[8'h82] = 8'h13; sbox[8'h83] = 8'hEC;
        sbox[8'h84] = 8'h5F; sbox[8'h85] = 8'h97; sbox[8'h86] = 8'h44; sbox[8'h87] = 8'h17;
        sbox[8'h88] = 8'hC4; sbox[8'h89] = 8'hA7; sbox[8'h8A] = 8'h7E; sbox[8'h8B] = 8'h3D;
        sbox[8'h8C] = 8'h64; sbox[8'h8D] = 8'h5D; sbox[8'h8E] = 8'h19; sbox[8'h8F] = 8'h73;
        sbox[8'h90] = 8'h60; sbox[8'h91] = 8'h81; sbox[8'h92] = 8'h4F; sbox[8'h93] = 8'hDC;
        sbox[8'h94] = 8'h22; sbox[8'h95] = 8'h2A; sbox[8'h96] = 8'h90; sbox[8'h97] = 8'h88;
        sbox[8'h98] = 8'h46; sbox[8'h99] = 8'hEE; sbox[8'h9A] = 8'hB8; sbox[8'h9B] = 8'h14;
        sbox[8'h9C] = 8'hDE; sbox[8'h9D] = 8'h5E; sbox[8'h9E] = 8'h0B; sbox[8'h9F] = 8'hDB;
        sbox[8'hA0] = 8'hE0; sbox[8'hA1] = 8'h32; sbox[8'hA2] = 8'h3A; sbox[8'hA3] = 8'h0A;
        sbox[8'hA4] = 8'h49; sbox[8'hA5] = 8'h06; sbox[8'hA6] = 8'h24; sbox[8'hA7] = 8'h5C;
        sbox[8'hA8] = 8'hC2; sbox[8'hA9] = 8'hD3; sbox[8'hAA] = 8'hAC; sbox[8'hAB] = 8'h62;
        sbox[8'hAC] = 8'h91; sbox[8'hAD] = 8'h95; sbox[8'hAE] = 8'hE4; sbox[8'hAF] = 8'h79;
        sbox[8'hB0] = 8'hE7; sbox[8'hB1] = 8'hC8; sbox[8'hB2] = 8'h37; sbox[8'hB3] = 8'h6D;
        sbox[8'hB4] = 8'h8D; sbox[8'hB5] = 8'hD5; sbox[8'hB6] = 8'h4E; sbox[8'hB7] = 8'hA9;
        sbox[8'hB8] = 8'h6C; sbox[8'hB9] = 8'h56; sbox[8'hBA] = 8'hF4; sbox[8'hBB] = 8'hEA;
        sbox[8'hBC] = 8'h65; sbox[8'hBD] = 8'h7A; sbox[8'hBE] = 8'hAE; sbox[8'hBF] = 8'h08;
        sbox[8'hC0] = 8'hBA; sbox[8'hC1] = 8'h78; sbox[8'hC2] = 8'h25; sbox[8'hC3] = 8'h2E;
        sbox[8'hC4] = 8'h1C; sbox[8'hC5] = 8'hA6; sbox[8'hC6] = 8'hB4; sbox[8'hC7] = 8'hC6;
        sbox[8'hC8] = 8'hE8; sbox[8'hC9] = 8'hDD; sbox[8'hCA] = 8'h74; sbox[8'hCB] = 8'h1F;
        sbox[8'hCC] = 8'h4B; sbox[8'hCD] = 8'hBD; sbox[8'hCE] = 8'h8B; sbox[8'hCF] = 8'h8A;
        sbox[8'hD0] = 8'h70; sbox[8'hD1] = 8'h3E; sbox[8'hD2] = 8'hB5; sbox[8'hD3] = 8'h66;
        sbox[8'hD4] = 8'h48; sbox[8'hD5] = 8'h03; sbox[8'hD6] = 8'hF6; sbox[8'hD7] = 8'h0E;
        sbox[8'hD8] = 8'h61; sbox[8'hD9] = 8'h35; sbox[8'hDA] = 8'h57; sbox[8'hDB] = 8'hB9;
        sbox[8'hDC] = 8'h86; sbox[8'hDD] = 8'hC1; sbox[8'hDE] = 8'h1D; sbox[8'hDF] = 8'h9E;
        sbox[8'hE0] = 8'hE1; sbox[8'hE1] = 8'hF8; sbox[8'hE2] = 8'h98; sbox[8'hE3] = 8'h11;
        sbox[8'hE4] = 8'h69; sbox[8'hE5] = 8'hD9; sbox[8'hE6] = 8'h8E; sbox[8'hE7] = 8'h94;
        sbox[8'hE8] = 8'h9B; sbox[8'hE9] = 8'h1E; sbox[8'hEA] = 8'h87; sbox[8'hEB] = 8'hE9;
        sbox[8'hEC] = 8'hCE; sbox[8'hED] = 8'h55; sbox[8'hEE] = 8'h28; sbox[8'hEF] = 8'hDF;
        sbox[8'hF0] = 8'h8C; sbox[8'hF1] = 8'hA1; sbox[8'hF2] = 8'h89; sbox[8'hF3] = 8'h0D;
        sbox[8'hF4] = 8'hBF; sbox[8'hF5] = 8'hE6; sbox[8'hF6] = 8'h42; sbox[8'hF7] = 8'h68;
        sbox[8'hF8] = 8'h41; sbox[8'hF9] = 8'h99; sbox[8'hFA] = 8'h2D; sbox[8'hFB] = 8'h0F;
        sbox[8'hFC] = 8'hB0; sbox[8'hFD] = 8'h54; sbox[8'hFE] = 8'hBB; sbox[8'hFF] = 8'h16;
    end
    
    // State - use separate regs to avoid array issues
    reg [7:0] s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12, s13, s14, s15;
    
    // State machine
    localparam [3:0] IDLE=0, INIT=1, ROUND=2, DONE=3;
    reg [3:0] state;
    reg [3:0] round_cnt;
    reg [2:0] phase; // 0=SUB, 1=SHIFT, 2=MIX, 3=ADDKEY
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            done <= 0;
        end else begin
            done <= 0;
            case (state)
                IDLE: if (start) begin 
                    state <= INIT; 
                    round_cnt <= 0; 
                    phase <= 0;
                end
                INIT: begin
                    // Initial AddRoundKey
                    s0  <= data_in[127:120] ^ round_key[127:120];
                    s1  <= data_in[119:112] ^ round_key[119:112];
                    s2  <= data_in[111:104] ^ round_key[111:104];
                    s3  <= data_in[103:96]  ^ round_key[103:96];
                    s4  <= data_in[95:88]   ^ round_key[95:88];
                    s5  <= data_in[87:80]   ^ round_key[87:80];
                    s6  <= data_in[79:72]   ^ round_key[79:72];
                    s7  <= data_in[71:64]   ^ round_key[71:64];
                    s8  <= data_in[63:56]   ^ round_key[63:56];
                    s9  <= data_in[55:48]   ^ round_key[55:48];
                    s10 <= data_in[47:40]   ^ round_key[47:40];
                    s11 <= data_in[39:32]   ^ round_key[39:32];
                    s12 <= data_in[31:24]   ^ round_key[31:24];
                    s13 <= data_in[23:16]   ^ round_key[23:16];
                    s14 <= data_in[15:8]    ^ round_key[15:8];
                    s15 <= data_in[7:0]     ^ round_key[7:0];
                    state <= ROUND;
                    phase <= 0;
                end
                ROUND: begin
                    case (phase)
                        0: begin // SubBytes
                            s0  <= sbox[s0];  s1  <= sbox[s1];  s2  <= sbox[s2];  s3  <= sbox[s3];
                            s4  <= sbox[s4];  s5  <= sbox[s5];  s6  <= sbox[s6];  s7  <= sbox[s7];
                            s8  <= sbox[s8];  s9  <= sbox[s9];  s10 <= sbox[s10]; s11 <= sbox[s11];
                            s12 <= sbox[s12]; s13 <= sbox[s13]; s14 <= sbox[s14]; s15 <= sbox[s15];
                            phase <= 1;
                        end
                        1: begin // ShiftRows
                            // Row 0: no change
                            // Row 1: shift left by 1
                            {s1, s5, s9, s13} <= {s5, s9, s13, s1};
                            // Row 2: shift left by 2
                            {s2, s6, s10, s14} <= {s10, s14, s2, s6};
                            // Row 3: shift left by 3
                            {s3, s7, s11, s15} <= {s15, s3, s7, s11};
                            if (round_cnt == max_round) // Last round - skip MixColumns
                                phase <= 3; // Go to AddRoundKey
                            else
                                phase <= 2;
                        end
                        2: begin // MixColumns
                            // Process each column using xtime (multiply by x in GF(2^8))
                            // Column 0 (s0-s3)
                            begin
                                reg [7:0] t0, u0;
                                t0 = s0 ^ s1 ^ s2 ^ s3;
                                u0 = s0;
                                s0 <= s0 ^ t0 ^ xtime(s0 ^ s1);
                                s1 <= s1 ^ t0 ^ xtime(s1 ^ s2);
                                s2 <= s2 ^ t0 ^ xtime(s2 ^ s3);
                                s3 <= s3 ^ t0 ^ xtime(s3 ^ u0);
                            end
                            // Column 1 (s4-s7)
                            begin
                                reg [7:0] t1, u1;
                                t1 = s4 ^ s5 ^ s6 ^ s7;
                                u1 = s4;
                                s4 <= s4 ^ t1 ^ xtime(s4 ^ s5);
                                s5 <= s5 ^ t1 ^ xtime(s5 ^ s6);
                                s6 <= s6 ^ t1 ^ xtime(s6 ^ s7);
                                s7 <= s7 ^ t1 ^ xtime(s7 ^ u1);
                            end
                            // Column 2 (s8-s11)
                            begin
                                reg [7:0] t2, u2;
                                t2 = s8 ^ s9 ^ s10 ^ s11;
                                u2 = s8;
                                s8  <= s8  ^ t2 ^ xtime(s8  ^ s9);
                                s9  <= s9  ^ t2 ^ xtime(s9  ^ s10);
                                s10 <= s10 ^ t2 ^ xtime(s10 ^ s11);
                                s11 <= s11 ^ t2 ^ xtime(s11 ^ u2);
                            end
                            // Column 3 (s12-s15)
                            begin
                                reg [7:0] t3, u3;
                                t3 = s12 ^ s13 ^ s14 ^ s15;
                                u3 = s12;
                                s12 <= s12 ^ t3 ^ xtime(s12 ^ s13);
                                s13 <= s13 ^ t3 ^ xtime(s13 ^ s14);
                                s14 <= s14 ^ t3 ^ xtime(s14 ^ s15);
                                s15 <= s15 ^ t3 ^ xtime(s15 ^ u3);
                            end
                            phase <= 3;
                        end
                        3: begin // AddRoundKey
                            s0  <= s0  ^ round_key[127:120];
                            s1  <= s1  ^ round_key[119:112];
                            s2  <= s2  ^ round_key[111:104];
                            s3  <= s3  ^ round_key[103:96];
                            s4  <= s4  ^ round_key[95:88];
                            s5  <= s5  ^ round_key[87:80];
                            s6  <= s6  ^ round_key[79:72];
                            s7  <= s7  ^ round_key[71:64];
                            s8  <= s8  ^ round_key[63:56];
                            s9  <= s9  ^ round_key[55:48];
                            s10 <= s10 ^ round_key[47:40];
                            s11 <= s11 ^ round_key[39:32];
                            s12 <= s12 ^ round_key[31:24];
                            s13 <= s13 ^ round_key[23:16];
                            s14 <= s14 ^ round_key[15:8];
                            s15 <= s15 ^ round_key[7:0];
                            if (round_cnt == max_round) begin
                                state <= DONE;
                                // Use intermediate values to capture post-AddRoundKey state
                                data_out <= {s0 ^ round_key[127:120], s1 ^ round_key[119:112], 
                                            s2 ^ round_key[111:104], s3 ^ round_key[103:96],
                                            s4 ^ round_key[95:88], s5 ^ round_key[87:80],
                                            s6 ^ round_key[79:72], s7 ^ round_key[71:64],
                                            s8 ^ round_key[63:56], s9 ^ round_key[55:48],
                                            s10 ^ round_key[47:40], s11 ^ round_key[39:32],
                                            s12 ^ round_key[31:24], s13 ^ round_key[23:16],
                                            s14 ^ round_key[15:8], s15 ^ round_key[7:0]};
                                done <= 1;
                            end else begin
                                round_cnt <= round_cnt + 1;
                                phase <= 0;
                            end
                        end
                    endcase
                end
                DONE: begin
                    state <= IDLE;
                    done <= 0;
                end
            endcase
        end
    end
    
    // Key request timing - request key BEFORE it's needed
    // Request at end of previous phase so it's ready for AddRoundKey
    always @(*) begin
        if (state == IDLE && start) begin
            round_num = 0;  // Request round 0 key
            key_req = 1;
        end
        else if (state == ROUND && phase == 2 && round_cnt < max_round) begin
            // Request next key at end of MixColumns (phase 2)
            // so it's ready for AddRoundKey (phase 3)
            round_num = round_cnt + 1;
            key_req = 1;
        end
        else if (state == ROUND && phase == 1 && round_cnt == max_round) begin
            // Special case for final round (skip MixColumns)
            round_num = max_round + 1;  // Final round uses max_round+1 key index
            key_req = 1;
        end
        else begin
            round_num = round_cnt;
            key_req = 0;
        end
    end

endmodule

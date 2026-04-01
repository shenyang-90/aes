//============================================================================
// Module: gcm_engine
// Description: GCM mode GHASH engine for authentication
// Implements GF(2^128) multiplication
//============================================================================
`timescale 1ns / 1ps

module gcm_engine (
    input  wire        clk,
    input  wire        rst_n,
    
    // Control
    input  wire        gcm_en,
    input  wire        gcm_start,
    input  wire        gcm_done,
    
    // Hash subkey H = E(K, 0^128)
    input  wire [127:0] hash_subkey_h,
    
    // J0 = E(K, IV || 0^31 || 1) for tag finalization
    input  wire [127:0] j0_data,
    input  wire         j0_valid,
    
    // AAD interface
    input  wire [127:0] aad_data,
    input  wire         aad_valid,
    input  wire         aad_last,
    
    // Ciphertext interface
    input  wire [127:0] ct_data,
    input  wire         ct_valid,
    input  wire         ct_last,
    
    // AAD/Ciphertext length (in bits)
    input  wire [63:0]  aad_len,
    input  wire [63:0]  ct_len,
    
    // Tag output
    output reg  [127:0] tag,
    output reg          tag_valid,
    
    // Tag verification (for decryption)
    input  wire [127:0] tag_in,
    input  wire         tag_verify,
    output reg          tag_mismatch
);

    //========================================================================
    // GF(2^128) Multiplier
    // Reduction polynomial: x^128 + x^7 + x^2 + x + 1
    //========================================================================
    function [127:0] gf_mul;
        input [127:0] x, y;
        reg [127:0] result;
        reg [127:0] temp;
        integer i;
        begin
            result = 128'd0;
            temp = y;
            for (i = 0; i < 128; i = i + 1) begin
                if (x[127-i]) begin
                    result = result ^ temp;
                end
                // Multiply temp by x (shift and reduce)
                if (temp[0]) begin
                    temp = {1'b0, temp[127:1]} ^ 128'he1;  // Reverse reduction poly
                end else begin
                    temp = {1'b0, temp[127:1]};
                end
            end
            gf_mul = result;
        end
    endfunction
    
    //========================================================================
    // GHASH State Machine
    //========================================================================
    localparam [3:0] IDLE      = 4'd0;
    localparam [3:0] INIT      = 4'd1;
    localparam [3:0] AAD       = 4'd2;
    localparam [3:0] CT        = 4'd3;
    localparam [3:0] LEN       = 4'd4;
    localparam [3:0] TAG_WAIT  = 4'd5;  // Wait for J0
    localparam [3:0] TAG_FINAL = 4'd6;  // Finalize tag
    localparam [3:0] VERIFY    = 4'd7;  // Verify tag for decryption
    
    reg [3:0] state;
    reg [127:0] y;  // GHASH Accumulator
    reg [127:0] y_len;  // Y value after length block
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            y <= 128'd0;
            y_len <= 128'd0;
            tag <= 128'd0;
            tag_valid <= 1'b0;
            tag_mismatch <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    tag_valid <= 1'b0;
                    tag_mismatch <= 1'b0;
                    if (gcm_start && gcm_en) begin
                        state <= INIT;
                        y <= 128'd0;
                    end
                end
                
                INIT: begin
                    state <= AAD;
                end
                
                AAD: begin
                    if (aad_valid) begin
                        y <= gf_mul(y ^ aad_data, hash_subkey_h);
                    end
                    if (aad_last) begin
                        state <= CT;
                    end
                end
                
                CT: begin
                    if (ct_valid) begin
                        y <= gf_mul(y ^ ct_data, hash_subkey_h);
                    end
                    if (ct_last) begin
                        state <= LEN;
                    end
                end
                
                LEN: begin
                    // Add length block and store result
                    y_len <= gf_mul(y ^ {aad_len, ct_len}, hash_subkey_h);
                    state <= TAG_WAIT;
                end
                
                TAG_WAIT: begin
                    // Wait for J0 (E(K, J0)) to be available
                    if (j0_valid) begin
                        state <= TAG_FINAL;
                    end
                end
                
                TAG_FINAL: begin
                    // Final tag = GHASH result XOR E(K, J0)
                    tag <= y_len ^ j0_data;
                    tag_valid <= 1'b1;
                    if (tag_verify) begin
                        state <= VERIFY;
                    end else if (!gcm_start) begin
                        state <= IDLE;
                    end
                end
                
                VERIFY: begin
                    // Verify tag for decryption mode
                    tag_mismatch <= (tag != tag_in);
                    if (!gcm_start)
                        state <= IDLE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule

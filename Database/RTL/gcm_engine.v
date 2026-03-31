//============================================================================
// Module: gcm_engine
// Description: GCM mode GHASH engine for authentication
// Implements GF(2^128) multiplication
//============================================================================

module gcm_engine (
    input  wire        clk,
    input  wire        rst_n,
    
    // Control
    input  wire        gcm_en,
    input  wire        gcm_start,
    input  wire        gcm_done,
    
    // Hash subkey H = E(K, 0^128)
    input  wire [127:0] hash_subkey_h,
    
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
    output reg          tag_valid
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
    localparam [2:0] IDLE = 3'd0, INIT = 3'd1, AAD = 3'd2, CT = 3'd3, LEN = 3'd4, TAG = 3'd5;
    reg [2:0] state;
    reg [127:0] y;  // Accumulator
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            y <= 128'd0;
            tag <= 128'd0;
            tag_valid <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    tag_valid <= 1'b0;
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
                    // Add length block
                    y <= gf_mul(y ^ {aad_len, ct_len}, hash_subkey_h);
                    state <= TAG;
                end
                
                TAG: begin
                    tag <= y;
                    tag_valid <= 1'b1;
                    if (!gcm_start)
                        state <= IDLE;
                end
            endcase
        end
    end

endmodule

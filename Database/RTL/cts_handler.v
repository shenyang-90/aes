//============================================================================
// Module: cts_handler
// Description: CTS (Ciphertext Stealing) handler for non-aligned data
// Supports: 1-127 bit final block handling
//============================================================================
`timescale 1ns / 1ps

module cts_handler (
    input  wire        clk,
    input  wire        rst_n,
    
    // Control
    input  wire        enable,
    input  wire        start,
    output reg         done,
    input  wire        encrypt,         // 1=encrypt, 0=decrypt (BUG-013)
    input  wire [6:0]  valid_bits,      // 1-127 valid bits in final block
    input  wire        is_final,        // Is this the final block
    
    // Data
    input  wire [127:0] data_in,        // Input data
    input  wire [127:0] prev_block,     // Previous block (cipher for enc, plain for dec)
    output reg  [127:0] data_out,
    
    // AES Core interface
    output reg  [127:0] core_in,
    input  wire [127:0] core_out,
    output reg          core_start,
    input  wire         core_done
);

    // State machine
    localparam [3:0] IDLE           = 4'd0;
    localparam [3:0] CHECK_SIZE     = 4'd1;
    localparam [3:0] FULL_BLOCK     = 4'd2;
    localparam [3:0] PAD_BLOCK      = 4'd3;
    localparam [3:0] PROCESS        = 4'd4;
    localparam [3:0] STEAL_ENC      = 4'd5;  // Encryption: ciphertext stealing
    localparam [3:0] DEC_GET_PARTIAL= 4'd6;  // Decryption: get partial block
    localparam [3:0] DEC_DECRYPT_2  = 4'd7;  // Decryption: decrypt second block
    localparam [3:0] DEC_OUTPUT_1   = 4'd8;  // Decryption: output first block
    localparam [3:0] DEC_OUTPUT_2   = 4'd9;  // Decryption: output second block
    localparam [3:0] DONE           = 4'd10;
    
    reg [3:0] state;
    reg [127:0] buffer;
    reg [127:0] buffer2;        // BUG-013: Second buffer for decryption
    reg [6:0]   valid_bits_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            done <= 1'b0;
            core_start <= 1'b0;
            buffer <= 128'd0;
            buffer2 <= 128'd0;
            valid_bits_reg <= 7'd0;
        end else begin
            core_start <= 1'b0;
            done <= 1'b0;
            
            case (state)
                IDLE: begin
                    if (enable && start) begin
                        valid_bits_reg <= valid_bits;
                        buffer <= data_in;
                        state <= CHECK_SIZE;
                    end
                end
                
                CHECK_SIZE: begin
                    if (valid_bits_reg == 7'd0) begin  // Full block (128 bits valid)
                        // Full block - same for encrypt/decrypt
                        core_in <= buffer;
                        state <= FULL_BLOCK;
                        core_start <= 1'b1;
                    end else begin
                        // Partial block - need CTS
                        if (encrypt) begin
                            // Encryption: pad with previous ciphertext
                            core_in <= (buffer << (128 - valid_bits_reg)) | 
                                       (prev_block >> valid_bits_reg);
                            state <= PAD_BLOCK;
                            core_start <= 1'b1;
                        end else begin
                            // BUG-013: Decryption
                            // 1. Decrypt C_{n-1} (which is 'buffer') -> D_n
                            core_in <= buffer;  // C_{n-1}
                            buffer2 <= prev_block;  // Save C_n (partial ciphertext)
                            state <= DEC_GET_PARTIAL;
                            core_start <= 1'b1;
                        end
                    end
                end
                
                FULL_BLOCK: begin
                    if (core_done) begin
                        data_out <= core_out;
                        state <= DONE;
                    end
                end
                
                PAD_BLOCK: begin
                    if (core_done) begin
                        // CTS Encryption: Cn-1 = encrypt(padded)
                        // Cn = first valid_bits of Cn-1
                        buffer <= core_out;
                        state <= STEAL_ENC;
                    end
                end
                
                STEAL_ENC: begin
                    // Encryption output: steal bits from previous block
                    data_out <= (prev_block & ~({128{1'b1}} >> valid_bits_reg)) |
                               (buffer >> (128 - valid_bits_reg));
                    state <= DONE;
                end
                
                // BUG-013: CTS Decryption states
                DEC_GET_PARTIAL: begin
                    if (core_done) begin
                        // core_out = D_n (decrypted C_{n-1})
                        // P_n = first valid_bits of D_n
                        buffer <= core_out;  // D_n
                        
                        // 2. Construct C'_{n-1} = D_n with C_n in lower bits
                        // C'_{n-1} = (D_n & mask) | C_n
                        core_in <= (core_out & ({128{1'b1}} << (128 - valid_bits_reg))) | 
                                   buffer2;
                        state <= DEC_DECRYPT_2;
                        core_start <= 1'b1;
                    end
                end
                
                DEC_DECRYPT_2: begin
                    if (core_done) begin
                        // core_out = P_{n-1}
                        buffer2 <= core_out;  // Save P_{n-1}
                        
                        // Output P_n (partial) first
                        data_out <= buffer >> (128 - valid_bits_reg);
                        state <= DEC_OUTPUT_2;
                    end
                end
                
                DEC_OUTPUT_2: begin
                    // Output P_{n-1} (full block reconstructed)
                    data_out <= buffer2;
                    state <= DONE;
                end
                
                DONE: begin
                    done <= 1'b1;
                    state <= IDLE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule

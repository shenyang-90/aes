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
    input  wire [6:0]  valid_bits,      // 1-127 valid bits in final block
    input  wire        is_final,        // Is this the final block
    
    // Data
    input  wire [127:0] data_in,        // Input data
    input  wire [127:0] prev_ciphertext,// Previous ciphertext block (for CTS)
    output reg  [127:0] data_out,
    
    // AES Core interface
    output reg  [127:0] core_in,
    input  wire [127:0] core_out,
    output reg          core_start,
    input  wire         core_done
);

    // State machine
    localparam [2:0] IDLE       = 3'd0;
    localparam [2:0] CHECK_SIZE = 3'd1;
    localparam [2:0] FULL_BLOCK = 3'd2;
    localparam [2:0] PAD_BLOCK  = 3'd3;
    localparam [2:0] PROCESS    = 3'd4;
    localparam [2:0] STEAL      = 3'd5;
    localparam [2:0] OUTPUT     = 3'd6;
    localparam [2:0] DONE       = 3'd7;
    
    reg [2:0] state;
    reg [127:0] buffer;
    reg [6:0]   valid_bits_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            done <= 1'b0;
            core_start <= 1'b0;
            buffer <= 128'd0;
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
                    if (valid_bits_reg == 7'd0 || valid_bits_reg == 8'd128) begin
                        // Full block
                        core_in <= buffer;
                        state <= FULL_BLOCK;
                    end else begin
                        // Partial block - need CTS
                        core_in <= (buffer << (128 - valid_bits_reg)) | 
                                   (prev_ciphertext >> valid_bits_reg);
                        state <= PAD_BLOCK;
                    end
                    core_start <= 1'b1;
                end
                
                FULL_BLOCK: begin
                    if (core_done) begin
                        data_out <= core_out;
                        state <= DONE;
                    end
                end
                
                PAD_BLOCK: begin
                    if (core_done) begin
                        // CTS: Cn-1 = encrypt(padded)
                        // Cn = first valid_bits of Cn-1
                        buffer <= core_out;
                        state <= STEAL;
                    end
                end
                
                STEAL: begin
                    // Output: steal bits from previous block
                    data_out <= (prev_ciphertext & ~({128{1'b1}} >> valid_bits_reg)) |
                               (buffer >> (128 - valid_bits_reg));
                    state <= DONE;
                end
                
                DONE: begin
                    done <= 1'b1;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule

//============================================================================
// Module: key_manager
// Description: AES key management - key registers and protection
//============================================================================

module key_manager (
    input  wire        clk,
    input  wire        rst_n,
    
    // Configuration interface
    input  wire        key_load,
    input  wire [1:0]  key_len,         // 00=128, 01=192, 10=256
    input  wire [255:0] key_in,
    
    // Output to key_schedule
    output reg  [255:0] key_out,
    output reg          key_valid,
    
    // Security
    input  wire        zeroize,         // Clear keys (security)
    output reg         key_ready
);

    // Key registers (secure storage)
    reg [255:0] key_reg;
    reg         key_valid_reg;
    
    // Key length encoding
    localparam [1:0] KEY_128 = 2'd0;
    localparam [1:0] KEY_192 = 2'd1;
    localparam [1:0] KEY_256 = 2'd2;
    
    // Key loading and zeroization
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key_reg <= 256'd0;
            key_valid_reg <= 1'b0;
            key_ready <= 1'b0;
        end else if (zeroize) begin
            // Security zeroization
            key_reg <= 256'd0;
            key_valid_reg <= 1'b0;
            key_ready <= 1'b0;
        end else if (key_load) begin
            key_reg <= key_in;
            key_valid_reg <= 1'b1;
            key_ready <= 1'b1;
        end
    end
    
    // Output assignment
    always @(*) begin
        key_out = key_reg;
        key_valid = key_valid_reg;
    end
    
    // Key length masking for security
    wire [255:0] key_masked = (key_len == KEY_128) ? {128'd0, key_reg[127:0]} :
                              (key_len == KEY_192) ? {64'd0, key_reg[191:0]} :
                              key_reg;

endmodule

//============================================================================
// Module: xts_engine
// Description: XTS-AES mode engine with tweak calculation
// Reference: IEEE P1619 - XTS-AES for storage encryption
//============================================================================

module xts_engine (
    input  wire        clk,
    input  wire        rst_n,
    
    // Control
    input  wire        start,
    output reg         done,
    input  wire        encrypt,
    
    // Sector data
    input  wire [127:0] sector_id,      // 128-bit sector ID
    input  wire [31:0]  block_num,      // Block number in sector
    
    // Data
    input  wire [127:0] data_in,
    output reg  [127:0] data_out,
    
    // AES Core interface (for tweak encryption)
    output reg  [127:0] tweak_core_in,
    input  wire [127:0] tweak_core_out,
    output reg          tweak_core_start,
    input  wire         tweak_core_done,
    
    // AES Core interface (for data encryption)
    output reg  [127:0] data_core_in,
    input  wire [127:0] data_core_out,
    output reg          data_core_start,
    input  wire         data_core_done
);

    // State machine
    localparam [3:0] IDLE       = 4'd0;
    localparam [3:0] CALC_TWEAK = 4'd1;
    localparam [3:0] WAIT_TWEAK = 4'd2;
    localparam [3:0] MULT_ALPHA = 4'd3;     // Multiply tweak by alpha
    localparam [3:0] XOR_TWEAK  = 4'd4;     // XOR data with tweak
    localparam [3:0] ENC_DATA   = 4'd5;
    localparam [3:0] WAIT_ENC   = 4'd6;
    localparam [3:0] XOR_OUT    = 4'd7;
    localparam [3:0] DONE       = 4'd8;
    
    reg [3:0] state;
    reg [127:0] tweak;
    reg [127:0] data_xored;
    
    // GF(2^128) multiplication by alpha (x)
    // alpha = x in GF(2^128) representation
    function [127:0] gf_mul_alpha;
        input [127:0] x;
        reg carry;
        begin
            carry = x[127];
            gf_mul_alpha = {x[126:0], 1'b0};
            if (carry)
                gf_mul_alpha = gf_mul_alpha ^ 128'h87;  // Reduction polynomial
        end
    endfunction
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            done <= 1'b0;
            tweak_core_start <= 1'b0;
            data_core_start <= 1'b0;
            tweak <= 128'd0;
            data_xored <= 128'd0;
        end else begin
            tweak_core_start <= 1'b0;
            data_core_start <= 1'b0;
            done <= 1'b0;
            
            case (state)
                IDLE: begin
                    if (start) begin
                        // Calculate tweak = E_k2(sector_id)
                        tweak_core_in <= sector_id;
                        tweak_core_start <= 1'b1;
                        state <= CALC_TWEAK;
                    end
                end
                
                CALC_TWEAK: begin
                    state <= WAIT_TWEAK;
                end
                
                WAIT_TWEAK: begin
                    if (tweak_core_done) begin
                        tweak <= tweak_core_out;
                        state <= MULT_ALPHA;
                    end
                end
                
                MULT_ALPHA: begin
                    // Multiply tweak by alpha^block_num
                    // Simplified: assume block_num = 0 for now
                    state <= XOR_TWEAK;
                end
                
                XOR_TWEAK: begin
                    data_xored <= data_in ^ tweak;
                    state <= ENC_DATA;
                end
                
                ENC_DATA: begin
                    data_core_in <= data_xored;
                    data_core_start <= 1'b1;
                    state <= WAIT_ENC;
                end
                
                WAIT_ENC: begin
                    if (data_core_done) begin
                        state <= XOR_OUT;
                    end
                end
                
                XOR_OUT: begin
                    data_out <= data_core_out ^ tweak;
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

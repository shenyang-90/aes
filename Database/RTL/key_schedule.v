//============================================================================
// Module: key_schedule
// Description: AES Key Schedule - generates round keys from initial key
// Supports: 128/192/256 bit keys
//============================================================================

module key_schedule (
    input  wire        clk,
    input  wire        rst_n,
    
    // Control
    input  wire        load_key,         // Load initial key
    input  wire        key_req,          // Request round key
    input  wire [3:0]  round_num,        // Round number (0-14)
    input  wire [1:0]  key_len,          // 00=128, 01=192, 10=256
    
    // Key input (256-bit max)
    input  wire [255:0] key_in,
    
    // Round key output (128-bit)
    output reg  [127:0] round_key,
    output reg          key_valid
);

    //========================================================================
    // Parameters
    //========================================================================
    localparam [1:0] KEY_128 = 2'd0;
    localparam [1:0] KEY_192 = 2'd1;
    localparam [1:0] KEY_256 = 2'd2;
    
    localparam [3:0] MAX_ROUNDS_128 = 4'd10;
    localparam [3:0] MAX_ROUNDS_192 = 4'd12;
    localparam [3:0] MAX_ROUNDS_256 = 4'd14;
    
    //========================================================================
    // Rcon (Round Constants)
    //========================================================================
    reg [7:0] rcon [0:9];
    
    initial begin
        rcon[0] = 8'h01;
        rcon[1] = 8'h02;
        rcon[2] = 8'h04;
        rcon[3] = 8'h08;
        rcon[4] = 8'h10;
        rcon[5] = 8'h20;
        rcon[6] = 8'h40;
        rcon[7] = 8'h80;
        rcon[8] = 8'h1B;
        rcon[9] = 8'h36;
    end
    
    //========================================================================
    // Key Storage (15 round keys x 128 bits)
    //========================================================================
    reg [127:0] round_keys [0:14];
    reg [255:0] initial_key;
    reg         keys_generated;
    
    //========================================================================
    // State Machine
    //========================================================================
    localparam [2:0] IDLE      = 3'd0;
    localparam [2:0] LOAD      = 3'd1;
    localparam [2:0] EXPAND    = 3'd2;
    localparam [2:0] DONE      = 3'd3;
    
    reg [2:0] state;
    reg [3:0] expand_cnt;
    
    //========================================================================
    // State Register
    //========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            keys_generated <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (load_key)
                        state <= LOAD;
                end
                
                LOAD: begin
                    state <= EXPAND;
                end
                
                EXPAND: begin
                    if (expand_done)
                        state <= DONE;
                end
                
                DONE: begin
                    state <= IDLE;
                    keys_generated <= 1'b1;
                end
            endcase
        end
    end
    
    //========================================================================
    // Key Expansion (simplified - full implementation needed)
    //========================================================================
    wire expand_done;
    reg [3:0] max_round;
    
    always @(*) begin
        case (key_len)
            KEY_128: max_round = MAX_ROUNDS_128;
            KEY_192: max_round = MAX_ROUNDS_192;
            KEY_256: max_round = MAX_ROUNDS_256;
            default: max_round = MAX_ROUNDS_128;
        endcase
    end
    
    assign expand_done = (expand_cnt >= max_round);
    
    // Expansion counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            expand_cnt <= 4'd0;
        end else if (state == LOAD) begin
            expand_cnt <= 4'd0;
        end else if (state == EXPAND) begin
            expand_cnt <= expand_cnt + 1'b1;
        end
    end
    
    // Load initial key
    always @(posedge clk) begin
        if (state == LOAD) begin
            initial_key <= key_in;
            
            // First round key is the initial key (first 128 bits)
            round_keys[0] <= key_in[255:128];  // For 256-bit, use first 128
        end
    end
    
    // Key expansion (simplified placeholder)
    // Full implementation needs RotWord, SubWord, XOR with Rcon
    always @(posedge clk) begin
        if (state == EXPAND && !expand_done) begin
            // Simplified: just copy with some transformation
            // Real implementation needs proper AES key schedule
            round_keys[expand_cnt + 1] <= round_keys[expand_cnt] ^ 
                                          {rcon[expand_cnt[3:0]], 24'h0};
        end
    end
    
    //========================================================================
    // Round Key Output
    //========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            round_key <= 128'd0;
            key_valid <= 1'b0;
        end else if (key_req && keys_generated) begin
            round_key <= round_keys[round_num];
            key_valid <= 1'b1;
        end else begin
            key_valid <= 1'b0;
        end
    end
    
endmodule

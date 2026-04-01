//============================================================================
// Module: aes_controller
// Description: AES IP main controller - FSM and coordination
// Project: AES_Crypto_IP
// Version: 1.0
//============================================================================
`timescale 1ns / 1ps

module aes_controller (
    input  wire        clk,
    input  wire        rst_n,
    
    // Configuration interface (from APB)
    input  wire [31:0] ctrl_reg,         // Control register
    input  wire [31:0] status_reg,       // Status register
    input  wire [31:0] key_len_reg,      // Key length
    input  wire [31:0] mode_reg,         // Operation mode
    input  wire        config_valid,     // Config valid pulse
    
    // Data flow interface
    input  wire        data_in_valid,
    output wire        data_in_ready,
    input  wire        data_out_ready,
    output wire        data_out_valid,
    
    // Sub-module control
    output reg         core_start,       // Start AES core
    input  wire        core_done,        // AES core done
    output reg         key_load,         // Load key
    output reg         iv_load,          // Load IV
    
    // Key schedule status
    input  wire        key_ready,        // Key schedule ready (all round keys valid)
    
    // Mode control
    output reg  [2:0]  aes_mode,         // ECB/CBC/CTR/GCM/XTS/CTS
    output reg  [1:0]  key_mode,         // 128/192/256
    output reg         encrypt,          // 1=encrypt, 0=decrypt
    output reg         cts_enable,       // CTS mode enable
    
    // Interrupt
    output reg         int_done,         // Operation complete interrupt
    output reg         int_error         // Error interrupt
);

    //========================================================================
    // Parameters
    //========================================================================
    localparam [2:0] MODE_ECB  = 3'd0;
    localparam [2:0] MODE_CBC  = 3'd1;
    localparam [2:0] MODE_CTR  = 3'd2;
    localparam [2:0] MODE_GCM  = 3'd3;
    localparam [2:0] MODE_XTS  = 3'd4;
    localparam [2:0] MODE_CTS  = 3'd5;
    
    localparam [1:0] KEY_128 = 2'd0;
    localparam [1:0] KEY_192 = 2'd1;
    localparam [1:0] KEY_256 = 2'd2;
    
    //========================================================================
    // State Machine
    //========================================================================
    localparam [3:0] IDLE          = 4'd0;
    localparam [3:0] KEY_SCHEDULE  = 4'd1;  // Key expansion phase
    localparam [3:0] KEY_WAIT      = 4'd2;  // Wait for key schedule to complete
    localparam [3:0] LOAD_DATA     = 4'd3;  // Load input data
    localparam [3:0] LOAD_DATA_WAIT= 4'd4;  // Wait for data input
    localparam [3:0] ROUND_OP      = 4'd5;  // Main round operations (1-Nr-1)
    localparam [3:0] ROUND_WAIT    = 4'd6;  // Wait for core operation
    localparam [3:0] FINAL_ROUND   = 4'd7;  // Final round operation
    localparam [3:0] OUTPUT_DATA   = 4'd8;  // Output result
    localparam [3:0] DONE          = 4'd9;  // Operation complete
    localparam [3:0] ERROR         = 4'd10; // Error state
    
    reg [3:0] state, next_state;
    
    // Status bits
    wire        ctrl_start    = ctrl_reg[0];
    wire        ctrl_encrypt  = ctrl_reg[1];
    wire [2:0]  ctrl_mode     = ctrl_reg[6:4];
    wire        ctrl_cts_en   = ctrl_reg[8];
    wire        int_en_done   = ctrl_reg[16];  // INT_EN bit
    wire        int_en_error  = ctrl_reg[17];
    
    //========================================================================
    // State Register
    //========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    //========================================================================
    // Next State Logic
    //========================================================================
    always @(*) begin
        next_state = state;
        
        case (state)
            IDLE: begin
                if (ctrl_start && config_valid)
                    next_state = KEY_SCHEDULE;
            end
            
            KEY_SCHEDULE: begin
                // Key schedule phase - immediately proceed to data load
                // Original design: LOAD_KEY -> LOAD_IV
                next_state = LOAD_DATA;
            end
            
            KEY_WAIT: begin
                // Reserved state - bypass to LOAD_DATA
                // Not used in current design (key schedule is immediate)
                next_state = LOAD_DATA;
            end
            
            LOAD_DATA: begin
                // Load IV/data configuration, then wait for data
                next_state = LOAD_DATA_WAIT;
            end
            
            LOAD_DATA_WAIT: begin
                if (data_in_valid)
                    next_state = ROUND_OP;
            end
            
            ROUND_OP: begin
                next_state = ROUND_WAIT;
            end
            
            ROUND_WAIT: begin
                if (core_done)
                    next_state = OUTPUT_DATA;
            end
            
            FINAL_ROUND: begin
                // Final round - integrated with ROUND_OP/ROUND_WAIT
                // This state is reserved for future use if needed
                next_state = OUTPUT_DATA;
            end
            
            OUTPUT_DATA: begin
                if (data_out_ready)
                    next_state = DONE;
            end
            
            DONE: begin
                next_state = IDLE;
            end
            
            ERROR: begin
                next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    //========================================================================
    // Output Logic
    //========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            core_start  <= 1'b0;
            key_load    <= 1'b0;
            iv_load     <= 1'b0;
            aes_mode    <= 3'd0;
            key_mode    <= 2'd0;
            encrypt     <= 1'b0;
            cts_enable  <= 1'b0;
            int_done    <= 1'b0;
            int_error   <= 1'b0;
        end else begin
            // Default values
            core_start  <= 1'b0;
            key_load    <= 1'b0;
            iv_load     <= 1'b0;
            int_done    <= 1'b0;
            int_error   <= 1'b0;
            
            case (state)
                KEY_SCHEDULE: begin
                    key_load <= 1'b1;
                    key_mode <= key_len_reg[1:0];
                end
                
                LOAD_DATA: begin
                    iv_load <= 1'b1;
                    aes_mode   <= ctrl_mode;
                    encrypt    <= ctrl_encrypt;
                    cts_enable <= ctrl_cts_en;
                end
                
                ROUND_OP: begin
                    core_start <= 1'b1;
                end
                
                FINAL_ROUND: begin
                    // Final round operations - reserved for future use
                    // Currently core handles final round internally as part of ROUND_OP
                end
                
                DONE: begin
                    if (int_en_done)
                        int_done <= 1'b1;
                end
                
                ERROR: begin
                    if (int_en_error)
                        int_error <= 1'b1;
                end
            endcase
        end
    end
    
    // Status outputs
    assign data_in_ready  = (state == LOAD_DATA_WAIT);
    assign data_out_valid = (state == OUTPUT_DATA);
    
endmodule

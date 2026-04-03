`timescale 1ns / 1ps

//============================================================================
// Module: safety_bist
// Description: Built-In Self-Test for Safety Mechanisms
//              Tests Dual-rail, CRC, Watchdog, FSM invalid detection
// Reference: Design_Specification.md Section 6.3
//============================================================================

module safety_bist (
    input  wire        clk,
    input  wire        rst_n,
    
    // Control interface
    input  wire        bist_start,      // Software trigger
    output reg         bist_done,
    output reg         bist_pass,
    output reg  [2:0]  bist_fail_id,
    
    // Test interface to fault_detector
    output reg         bist_test_mode,
    output reg  [2:0]  bist_test_sel,
    input  wire        bist_test_result,
    
    // Status output
    output reg  [2:0]  bist_state_out
);

    //========================================================================
    // BIST Test Item Definitions
    //========================================================================
    localparam TEST_LOCKSTEP    = 3'd0;  // Dual-rail comparison test
    localparam TEST_CRC         = 3'd1;  // CRC checker test
    localparam TEST_TIMEOUT     = 3'd2;  // Watchdog timeout test
    localparam TEST_FSM         = 3'd3;  // FSM invalid state test
    localparam TEST_DUALRAIL    = 3'd4;  // Dual-rail enable test
    localparam TEST_MAX         = 3'd5;  // Maximum test index

    //========================================================================
    // BIST State Machine Encoding
    //========================================================================
    localparam BIST_IDLE        = 3'b000;
    localparam BIST_SETUP       = 3'b001;
    localparam BIST_INJECT      = 3'b010;
    localparam BIST_WAIT        = 3'b011;
    localparam BIST_CHECK       = 3'b100;
    localparam BIST_NEXT        = 3'b101;
    localparam BIST_DONE_PASS   = 3'b110;
    localparam BIST_DONE_FAIL   = 3'b111;

    //========================================================================
    // Internal Registers
    //========================================================================
    reg [2:0] bist_state, bist_state_next;
    reg [2:0] test_idx, test_idx_next;
    reg [7:0] wait_cnt, wait_cnt_next;
    
    //========================================================================
    // State Register
    //========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bist_state <= BIST_IDLE;
            test_idx   <= 3'd0;
            wait_cnt   <= 8'd0;
        end else begin
            bist_state <= bist_state_next;
            test_idx   <= test_idx_next;
            wait_cnt   <= wait_cnt_next;
        end
    end

    //========================================================================
    // Next State Logic
    //========================================================================
    always @(*) begin
        bist_state_next = bist_state;
        test_idx_next   = test_idx;
        wait_cnt_next   = wait_cnt;
        
        case (bist_state)
            BIST_IDLE: begin
                if (bist_start) begin
                    bist_state_next = BIST_SETUP;
                    test_idx_next   = 3'd0;
                end
            end
            
            BIST_SETUP: begin
                bist_state_next = BIST_INJECT;
                wait_cnt_next   = 8'd0;
            end
            
            BIST_INJECT: begin
                // Inject fault or setup test condition
                bist_state_next = BIST_WAIT;
                wait_cnt_next   = 8'd0;
            end
            
            BIST_WAIT: begin
                // Wait for detection
                if (wait_cnt < 8'd10) begin
                    wait_cnt_next = wait_cnt + 1'b1;
                end else begin
                    bist_state_next = BIST_CHECK;
                end
            end
            
            BIST_CHECK: begin
                if (bist_test_result) begin
                    // Test passed, move to next
                    if (test_idx >= TEST_MAX - 1) begin
                        bist_state_next = BIST_DONE_PASS;
                    end else begin
                        bist_state_next = BIST_NEXT;
                    end
                end else begin
                    // Test failed
                    bist_state_next = BIST_DONE_FAIL;
                end
            end
            
            BIST_NEXT: begin
                test_idx_next   = test_idx + 1'b1;
                bist_state_next = BIST_SETUP;
            end
            
            BIST_DONE_PASS: begin
                if (!bist_start) begin
                    bist_state_next = BIST_IDLE;
                end
            end
            
            BIST_DONE_FAIL: begin
                if (!bist_start) begin
                    bist_state_next = BIST_IDLE;
                end
            end
            
            default: begin
                bist_state_next = BIST_IDLE;
            end
        endcase
    end

    //========================================================================
    // Output Logic
    //========================================================================
    always @(*) begin
        // Default values
        bist_done    = 1'b0;
        bist_pass    = 1'b0;
        bist_fail_id = 3'd0;
        bist_test_mode = 1'b0;
        bist_test_sel  = test_idx;
        bist_state_out = bist_state;
        
        case (bist_state)
            BIST_INJECT: begin
                bist_test_mode = 1'b1;
            end
            
            BIST_WAIT: begin
                bist_test_mode = 1'b1;
            end
            
            BIST_CHECK: begin
                bist_test_mode = 1'b1;
            end
            
            BIST_DONE_PASS: begin
                bist_done = 1'b1;
                bist_pass = 1'b1;
            end
            
            BIST_DONE_FAIL: begin
                bist_done    = 1'b1;
                bist_pass    = 1'b0;
                bist_fail_id = test_idx;
            end
            
            default: begin
                // Keep defaults
            end
        endcase
    end

endmodule

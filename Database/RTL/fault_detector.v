//============================================================================
// Module: fault_detector
// Description: Fault detection using dual execution comparison
//============================================================================
`timescale 1ns / 1ps

module fault_detector (
    input  wire        clk,
    input  wire        rst_n,
    
    // Control
    input  wire        enable,
    input  wire        op_start,
    input  wire        op_done,
    
    // Data inputs (dual execution results)
    input  wire [127:0] result_a,       // First execution
    input  wire [127:0] result_b,       // Second execution (lockstep)
    input  wire         result_a_valid,
    input  wire         result_b_valid,
    
    // CRC check
    input  wire [31:0]  crc_value,
    input  wire         crc_valid,
    
    // Output
    output reg          fault_detected,
    output reg          fault_type,      // 0=mismatch, 1=CRC error
    output reg [127:0]  safe_result
);

    // State machine
    localparam [2:0] IDLE      = 3'd0;
    localparam [2:0] EXEC_A    = 3'd1;
    localparam [2:0] EXEC_B    = 3'd2;
    localparam [2:0] COMPARE   = 3'd3;
    localparam [2:0] CRC_CHECK = 3'd4;
    localparam [2:0] DONE      = 3'd5;
    localparam [2:0] ERROR     = 3'd6;
    
    reg [2:0] state;
    reg [127:0] result_a_reg;
    reg [127:0] result_b_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            fault_detected <= 1'b0;
            fault_type <= 1'b0;
            safe_result <= 128'd0;
            result_a_reg <= 128'd0;
            result_b_reg <= 128'd0;
        end else begin
            fault_detected <= 1'b0;
            
            case (state)
                IDLE: begin
                    if (enable && op_start)
                        state <= EXEC_A;
                end
                
                EXEC_A: begin
                    if (result_a_valid) begin
                        result_a_reg <= result_a;
                        state <= EXEC_B;
                    end
                end
                
                EXEC_B: begin
                    if (result_b_valid) begin
                        result_b_reg <= result_b;
                        state <= COMPARE;
                    end
                end
                
                COMPARE: begin
                    if (result_a_reg == result_b_reg) begin
                        safe_result <= result_a_reg;
                        state <= CRC_CHECK;
                    end else begin
                        fault_detected <= 1'b1;
                        fault_type <= 1'b0;  // Mismatch
                        state <= ERROR;
                    end
                end
                
                CRC_CHECK: begin
                    if (crc_valid) begin
                        // CRC check passed
                        state <= DONE;
                    end else begin
                        fault_detected <= 1'b1;
                        fault_type <= 1'b1;  // CRC error
                        state <= ERROR;
                    end
                end
                
                DONE: begin
                    if (op_done)
                        state <= IDLE;
                end
                
                ERROR: begin
                    // Hold error state until reset or acknowledged
                    fault_detected <= 1'b1;
                    if (op_done)
                        state <= IDLE;
                end
                default: state <= IDLE;  // Should not reach here
            endcase
        end
    end

endmodule

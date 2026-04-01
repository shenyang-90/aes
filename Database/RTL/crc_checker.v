//============================================================================
// Module: crc_checker
// Description: CRC-32 checker for fault detection
//              Uses standard CRC-32 polynomial (0x04C11DB7)
// Bug Fix: BUG-010 - Now correctly uses data_in for CRC calculation
//============================================================================

`timescale 1ns / 1ps

module crc_checker (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        calc_start,
    input  wire        calc_done,
    input  wire [127:0] data_in,
    output reg  [31:0]  crc_out,
    output reg          crc_valid
);

    // CRC-32 polynomial: x^32 + x^26 + x^23 + x^22 + x^16 + x^12 + x^11 + x^10 + x^8 + x^7 + x^5 + x^4 + x^2 + x + 1
    // 0x04C11DB7 (standard IEEE 802.3 CRC-32)
    
    localparam [31:0] CRC_POLY = 32'h04C11DB7;
    localparam [31:0] CRC_INIT = 32'hFFFFFFFF;
    
    reg [31:0] crc_reg;
    reg [7:0]  bit_cnt;      // 0-128 range (need 8 bits for 128)
    reg [1:0]  state;
    
    localparam [1:0] IDLE = 2'b00;
    localparam [1:0] CALC = 2'b01;
    localparam [1:0] DONE = 2'b10;
    
    //========================================================================
    // CRC Calculation State Machine
    //========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_reg   <= CRC_INIT;
            crc_out   <= 32'd0;
            crc_valid <= 1'b0;
            bit_cnt   <= 8'd0;
            state     <= IDLE;
        end else begin
            // Default: crc_valid is a single-cycle pulse
            crc_valid <= 1'b0;
            
            case (state)
                IDLE: begin
                    if (calc_start) begin
                        crc_reg <= CRC_INIT;  // Initialize CRC to all 1s
                        bit_cnt <= 8'd0;
                        state   <= CALC;
                    end
                end
                
                CALC: begin
                    // Process 128 bits of data_in, MSB first
                    if (bit_cnt < 8'd128) begin
                        // Get current bit from data_in (MSB first: bit 127 down to 0)
                        // XOR the MSB of CRC with the current data bit
                        if (crc_reg[31] ^ data_in[127 - bit_cnt[6:0]]) begin
                            // Feedback is 1: shift left and XOR with polynomial
                            crc_reg <= {crc_reg[30:0], 1'b0} ^ CRC_POLY;
                        end else begin
                            // Feedback is 0: just shift left
                            crc_reg <= {crc_reg[30:0], 1'b0};
                        end
                        bit_cnt <= bit_cnt + 8'd1;
                    end else begin
                        // All 128 bits processed, move to DONE
                        state <= DONE;
                    end
                end
                
                DONE: begin
                    // Final CRC output (inverted as per CRC-32 standard)
                    crc_out   <= ~crc_reg;
                    crc_valid <= 1'b1;
                    state     <= IDLE;
                end
                
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule

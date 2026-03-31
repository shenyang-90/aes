//============================================================================
// Module: crc_checker
// Description: CRC-32 checker for fault detection
//============================================================================

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
    // 0x04C11DB7
    
    localparam [31:0] CRC_POLY = 32'h04C11DB7;
    localparam [31:0] CRC_INIT = 32'hFFFFFFFF;
    
    reg [31:0] crc_reg;
    reg [6:0]  bit_cnt;
    reg [1:0]  state;
    
    localparam [1:0] IDLE = 2'b00;
    localparam [1:0] CALC = 2'b01;
    localparam [1:0] DONE = 2'b10;
    
    integer i;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_reg <= CRC_INIT;
            crc_out <= 32'd0;
            crc_valid <= 1'b0;
            bit_cnt <= 7'd0;
            state <= IDLE;
        end else begin
            crc_valid <= 1'b0;
            
            case (state)
                IDLE: begin
                    if (calc_start) begin
                        crc_reg <= CRC_INIT;
                        bit_cnt <= 7'd0;
                        state <= CALC;
                    end
                end
                
                CALC: begin
                    // Process 128 bits
                    if (bit_cnt < 128) begin
                        // Simple CRC calculation (placeholder)
                        crc_reg <= {crc_reg[30:0], 1'b0} ^ (crc_reg[31] ? CRC_POLY : 32'd0);
                        bit_cnt <= bit_cnt + 1'b1;
                    end else begin
                        state <= DONE;
                    end
                end
                
                DONE: begin
                    crc_out <= ~crc_reg;  // Final XOR
                    crc_valid <= 1'b1;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule

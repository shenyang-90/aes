//============================================================================
// Module: apb_if
// Description: APB Slave Interface for AES IP configuration
//============================================================================

module apb_if (
    input  wire        clk,
    input  wire        rst_n,
    
    // APB Interface
    input  wire        psel,
    input  wire        penable,
    input  wire [11:0] paddr,
    input  wire        pwrite,
    input  wire [31:0] pwdata,
    output reg  [31:0] prdata,
    output reg         pready,
    output reg         pslverr,
    
    // Internal Register Interface
    output reg  [11:0] reg_addr,
    output reg         reg_wr,
    output reg  [31:0] reg_wdata,
    input  wire [31:0] reg_rdata,
    input  wire        reg_ready
);

    // APB State
    localparam [1:0] IDLE   = 2'b00;
    localparam [1:0] SETUP  = 2'b01;
    localparam [1:0] ACCESS = 2'b10;
    
    reg [1:0] apb_state;
    
    // APB State Machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            apb_state <= IDLE;
            pready <= 1'b0;
            pslverr <= 1'b0;
        end else begin
            case (apb_state)
                IDLE: begin
                    if (psel && !penable)
                        apb_state <= SETUP;
                    pready <= 1'b0;
                end
                
                SETUP: begin
                    if (psel && penable)
                        apb_state <= ACCESS;
                end
                
                ACCESS: begin
                    pready <= reg_ready;
                    if (reg_ready)
                        apb_state <= IDLE;
                end
                
                default: apb_state <= IDLE;
            endcase
        end
    end
    
    // Register interface
    always @(posedge clk) begin
        if (apb_state == SETUP) begin
            reg_addr <= paddr;
            reg_wr <= pwrite;
            reg_wdata <= pwdata;
        end
    end
    
    // Read data
    always @(posedge clk) begin
        if (apb_state == ACCESS && !pwrite && reg_ready)
            prdata <= reg_rdata;
    end

endmodule

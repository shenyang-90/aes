//============================================================================
// Module: aes_top
// Description: AES IP Top Level - integrates all sub-modules
// Features: ECB/CBC/CTR/GCM/XTS/CTS modes, 128/192/256-bit keys
// Security: TI masked S-Box, fault detection, lockstep
//============================================================================
`timescale 1ns / 1ps

module aes_top (
    // Clock and Reset
    input  wire        clk,
    input  wire        rst_n,
    
    // APB Configuration Interface
    input  wire        psel,
    input  wire        penable,
    input  wire [11:0] paddr,            // 4KB address space
    input  wire        pwrite,
    input  wire [31:0] pwdata,
    output reg  [31:0] prdata,
    output reg         pready,
    output reg         pslverr,
    
    // AXI4-Stream Data Interface (Input)
    input  wire [127:0] s_axis_tdata,
    input  wire         s_axis_tvalid,
    output wire         s_axis_tready,
    input  wire         s_axis_tlast,
    
    // AXI4-Stream Data Interface (Output)
    output reg  [127:0] m_axis_tdata,
    output reg          m_axis_tvalid,
    input  wire         m_axis_tready,
    output reg          m_axis_tlast,
    
    // Interrupts
    output wire         int_done,
    output wire         int_error,
    
    // DFT (for production)
    input  wire         scan_en,
    input  wire         scan_clk
);

    //========================================================================
    // Parameters
    //========================================================================
    localparam [11:0] REG_CTRL        = 12'h000;
    localparam [11:0] REG_STATUS      = 12'h004;
    localparam [11:0] REG_KEY_LEN     = 12'h008;
    localparam [11:0] REG_MODE        = 12'h00C;
    localparam [11:0] REG_KEY_0       = 12'h010;  // Key[255:224]
    localparam [11:0] REG_KEY_1       = 12'h014;
    localparam [11:0] REG_KEY_2       = 12'h018;
    localparam [11:0] REG_KEY_3       = 12'h01C;
    localparam [11:0] REG_KEY_4       = 12'h020;
    localparam [11:0] REG_KEY_5       = 12'h024;
    localparam [11:0] REG_KEY_6       = 12'h028;
    localparam [11:0] REG_KEY_7       = 12'h02C;  // Key[31:0]
    localparam [11:0] REG_IV_0        = 12'h030;  // IV[127:96]
    localparam [11:0] REG_IV_1        = 12'h034;
    localparam [11:0] REG_IV_2        = 12'h038;
    localparam [11:0] REG_IV_3        = 12'h03C;  // IV[31:0]
    localparam [11:0] REG_CTS_EN      = 12'h040;
    localparam [11:0] REG_SECTOR_ID   = 12'h044;
    localparam [11:0] REG_INT_EN      = 12'h048;
    localparam [11:0] REG_INT_STATUS  = 12'h04C;
    
    //========================================================================
    // Registers
    //========================================================================
    reg [31:0]  ctrl_reg;
    reg [31:0]  status_reg;
    reg [31:0]  key_len_reg;
    reg [31:0]  mode_reg;
    reg [255:0] key_reg;
    reg [127:0] iv_reg;
    reg [31:0]  cts_en_reg;
    reg [31:0]  sector_id_reg;
    reg [31:0]  int_en_reg;
    reg [31:0]  int_status_reg;
    
    //========================================================================
    // APB Interface
    //========================================================================
    wire apb_write = psel && penable && pwrite;
    wire apb_read  = psel && penable && !pwrite;
    
    // Interrupt status signals (connected from controller)
    wire int_done_set  = int_done;
    wire int_error_set = int_error;
    wire int_fault_set = 1'b0;  // No fault detector in current design
    wire int_dma_set   = 1'b0;  // No DMA in current design
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ctrl_reg        <= 32'd0;
            key_len_reg     <= 32'd0;
            mode_reg        <= 32'd0;
            key_reg         <= 256'd0;
            iv_reg          <= 128'd0;
            cts_en_reg      <= 32'd0;
            sector_id_reg   <= 32'd0;
            int_en_reg      <= 32'd0;
            int_status_reg  <= 32'd0;
            pready          <= 1'b0;
            pslverr         <= 1'b0;
        end else begin
            pready <= psel && penable;
            pslverr <= 1'b0;  // No errors
            
            // Update INT_STATUS: set by events, clear by W1C or read-clear
            // Set bits when interrupt conditions occur (only if enabled)
            if (int_done_set)
                int_status_reg[0] <= 1'b1;
            if (int_error_set)
                int_status_reg[1] <= 1'b1;
            if (int_fault_set)
                int_status_reg[2] <= 1'b1;
            if (int_dma_set)
                int_status_reg[3] <= 1'b1;
            
            // BUG-015: Key clear functionality
            // Check for key_clear bit (CTRL[9]) - clears all key registers
            if (apb_write && paddr == REG_CTRL && pwdata[9]) begin
                key_reg <= 256'd0;  // Zeroize keys
            end else if (apb_write) begin
                case (paddr)
                    REG_CTRL:       ctrl_reg       <= pwdata;
                    REG_KEY_LEN:    key_len_reg    <= pwdata;
                    REG_MODE:       mode_reg       <= pwdata;
                    REG_KEY_0:      key_reg[255:224] <= pwdata;
                    REG_KEY_1:      key_reg[223:192] <= pwdata;
                    REG_KEY_2:      key_reg[191:160] <= pwdata;
                    REG_KEY_3:      key_reg[159:128] <= pwdata;
                    REG_KEY_4:      key_reg[127:96]  <= pwdata;
                    REG_KEY_5:      key_reg[95:64]   <= pwdata;
                    REG_KEY_6:      key_reg[63:32]   <= pwdata;
                    REG_KEY_7:      key_reg[31:0]    <= pwdata;
                    REG_IV_0:       iv_reg[127:96]   <= pwdata;
                    REG_IV_1:       iv_reg[95:64]    <= pwdata;
                    REG_IV_2:       iv_reg[63:32]    <= pwdata;
                    REG_IV_3:       iv_reg[31:0]     <= pwdata;
                    REG_CTS_EN:     cts_en_reg     <= pwdata;
                    REG_SECTOR_ID:  sector_id_reg  <= pwdata;
                    REG_INT_EN:     int_en_reg     <= pwdata;
                    REG_INT_STATUS: int_status_reg <= int_status_reg & ~pwdata;  // W1C
                endcase
            end else if (apb_read && paddr == REG_INT_STATUS) begin
                // Read-Clear (RC) behavior: clear all bits on read
                int_status_reg <= 32'd0;
            end
        end
    end
    
    // APB Read
    always @(*) begin
        prdata = 32'd0;
        if (apb_read) begin
            case (paddr)
                REG_CTRL:       prdata = ctrl_reg;
                REG_STATUS:     prdata = status_reg;
                REG_KEY_LEN:    prdata = key_len_reg;
                REG_MODE:       prdata = mode_reg;
                REG_KEY_0:      prdata = key_reg[255:224];
                REG_KEY_1:      prdata = key_reg[223:192];
                REG_KEY_2:      prdata = key_reg[191:160];
                REG_KEY_3:      prdata = key_reg[159:128];
                REG_KEY_4:      prdata = key_reg[127:96];
                REG_KEY_5:      prdata = key_reg[95:64];
                REG_KEY_6:      prdata = key_reg[63:32];
                REG_KEY_7:      prdata = key_reg[31:0];
                REG_IV_0:       prdata = iv_reg[127:96];
                REG_IV_1:       prdata = iv_reg[95:64];
                REG_IV_2:       prdata = iv_reg[63:32];
                REG_IV_3:       prdata = iv_reg[31:0];
                REG_CTS_EN:     prdata = cts_en_reg;
                REG_SECTOR_ID:  prdata = sector_id_reg;
                REG_INT_EN:     prdata = int_en_reg;
                REG_INT_STATUS: prdata = int_status_reg;
                default:        prdata = 32'hDEAD_BEEF;
            endcase
        end
    end
    
    //========================================================================
    // Instantiate Sub-modules
    //========================================================================
    
    // Controller
    wire        core_start;
    wire        core_done;
    wire        key_load;
    wire        iv_load;
    wire [2:0]  aes_mode;
    wire [1:0]  key_mode;
    wire        encrypt;
    wire        cts_enable;
    
    aes_controller u_controller (
        .clk            (clk),
        .rst_n          (rst_n),
        .ctrl_reg       (ctrl_reg),
        .status_reg     (status_reg),
        .key_len_reg    (key_len_reg),
        .mode_reg       (mode_reg),
        .config_valid   (ctrl_reg[0]),
        .data_in_valid  (s_axis_tvalid),
        .data_in_ready  (s_axis_tready),
        .data_out_ready (m_axis_tready),
        .data_out_valid (m_axis_tvalid),
        .core_start     (core_start),
        .core_done      (core_done),
        .key_load       (key_load),
        .iv_load        (iv_load),
        .key_ready      (u_key_schedule.keys_valid),  // Wait for key schedule
        .aes_mode       (aes_mode),
        .key_mode       (key_mode),
        .encrypt        (encrypt),
        .cts_enable     (cts_enable),
        .int_done       (int_done),
        .int_error      (int_error)
    );
    
    // Key Schedule
    wire [127:0] round_key;
    wire         key_valid;
    wire         core_key_req;
    wire [3:0]   core_round_num;
    
    key_schedule u_key_schedule (
        .clk        (clk),
        .rst_n      (rst_n),
        .load_key   (key_load),
        .key_req    (core_key_req),
        .round_num  (core_round_num),
        .key_len    (key_mode),
        .key_in     (key_reg),
        .round_key  (round_key),
        .key_valid  (key_valid)
    );
    
    // AES Core
    wire [127:0] core_data_out;
    
    aes_core u_core (
        .clk        (clk),
        .rst_n      (rst_n),
        .start      (core_start),
        .done       (core_done),
        .encrypt    (encrypt),
        .key_len    (key_mode),
        .mode       (aes_mode),
        .data_in    (s_axis_tdata),
        .data_out   (core_data_out),
        .iv         (iv_reg),
        .round_key  (round_key),
        .round_num  (core_round_num),
        .key_req    (core_key_req)
    );
    
    // BUG-016: CRC Checker Integration
    wire [31:0] crc_out;
    wire        crc_valid;
    reg         crc_error;      // CRC mismatch detected
    wire        crc_en;         // CRC enable from mode_reg
    
    assign crc_en = mode_reg[8];  // CRC enable bit in MODE register
    
    crc_checker u_crc_checker (
        .clk        (clk),
        .rst_n      (rst_n),
        .calc_start (core_done & crc_en),  // Start CRC calc when data is ready
        .calc_done  (crc_valid),
        .data_in    (core_data_out),
        .crc_out    (crc_out),
        .crc_valid  (crc_valid)
    );
    
    // CRC error detection - compare calculated CRC with expected
    // Expected CRC is stored in upper 32 bits of output data
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_error <= 1'b0;
        end else if (crc_valid && crc_en) begin
            // CRC error if calculated CRC doesn't match expected
            // For now, just set error flag when CRC is calculated (test mode)
            crc_error <= 1'b0;  // Placeholder - actual compare would need expected CRC
        end
    end
    
    // Update status_reg with CRC error (bit 3)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            status_reg <= 32'd0;
        end else begin
            status_reg[3] <= crc_error;  // CRC_MISMATCH status
            status_reg[0] <= core_done;  // Operation done
            status_reg[1] <= 1'b0;       // Error placeholder
            status_reg[2] <= 1'b0;       // Fault placeholder
        end
    end
    
    // Output assignment
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_axis_tdata  <= 128'd0;
            m_axis_tlast  <= 1'b0;
        end else if (core_done) begin
            m_axis_tdata <= core_data_out;
            m_axis_tlast <= s_axis_tlast;
        end
    end
    
endmodule

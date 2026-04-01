//============================================================================
// Module: aes_top
// Description: AES IP Top Level - integrates all sub-modules
// Features: ECB/CBC/CTR/GCM/XTS/CTS modes, 128/192/256-bit keys
// Security: TI masked S-Box, fault detection, lockstep
// Safety: Configurable Dual-Rail Compare (Lockstep)
//============================================================================
`timescale 1ns / 1ps

module aes_top #(
    parameter ENABLE_LOCKSTEP = 1,      // 1=Enable dual-core lockstep, 0=Single core mode
    parameter LOCKSTEP_MODE   = 0       // 0=Real-time compare, 1=Delayed compare (reserved)
)(
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
    output wire         int_fault,       // NEW: Fault detection interrupt
    
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
    
    // DUAL_RAIL_EN control (CTRL[9])
    wire dual_rail_en = ctrl_reg[9];
    
    // Busy signal for mode switching protection
    wire ctrl_busy = status_reg[1];
    
    //========================================================================
    // APB Interface
    //========================================================================
    wire apb_write = psel && penable && pwrite;
    wire apb_read  = psel && penable && !pwrite;
    
    // Interrupt status signals
    wire int_done_set;
    wire int_error_set;
    wire int_fault_set;
    wire int_crc_set;
    
    // DFT test mode bypass for lockstep
    wire test_mode = scan_en;  // In test mode, bypass lockstep
    wire dual_rail_effective = test_mode ? 1'b0 : dual_rail_en;
    
    // Combined done signal (set in generate block)
    wire core_done_combined;
    
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
            
            // Update INT_STATUS: set by events, clear by W1C
            if (int_done_set)
                int_status_reg[0] <= 1'b1;
            if (int_error_set)
                int_status_reg[1] <= 1'b1;
            if (int_fault_set)
                int_status_reg[2] <= 1'b1;
            if (int_crc_set)
                int_status_reg[3] <= 1'b1;
            
            // Key clear functionality (CTRL[10] - key clear bit)
            if (apb_write && paddr == REG_CTRL && pwdata[10]) begin
                key_reg <= 256'd0;  // Zeroize keys
            end else if (apb_write) begin
                case (paddr)
                    REG_CTRL: begin
                        // DUAL_RAIL_EN (bit 9) can only be changed when not busy
                        if (ctrl_busy) begin
                            // Only allow changes to non-DUAL_RAIL_EN bits
                            ctrl_reg[31:10] <= pwdata[31:10];
                            ctrl_reg[8:0]   <= pwdata[8:0];
                            // Keep bit 9 unchanged when busy
                        end else begin
                            ctrl_reg <= pwdata;
                        end
                    end
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
            end else begin
                // Auto-clear START bit after operation completes
                if (core_done_combined)
                    ctrl_reg[0] <= 1'b0;
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
    wire        key_load;
    wire        iv_load;
    wire [2:0]  aes_mode;
    wire [1:0]  key_mode;
    wire        encrypt;
    wire        cts_enable;
    wire        m_axis_tvalid_ctrl;
    
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
        .data_out_valid (m_axis_tvalid_ctrl),
        .core_start     (core_start),
        .core_done      (core_done_combined),
        .key_load       (key_load),
        .iv_load        (iv_load),
        .key_ready      (u_key_schedule.key_valid),
        .aes_mode       (aes_mode),
        .key_mode       (key_mode),
        .encrypt        (encrypt),
        .cts_enable     (cts_enable),
        .int_done       (int_done_set),
        .int_error      (int_error_set)
    );
    
    // Key Schedule
    wire [127:0] round_key;
    wire         key_valid;
    wire         core_key_req_a;
    wire         core_key_req_b;
    wire [3:0]   core_round_num_a;
    wire [3:0]   core_round_num_b;
    
    // Combine key requests from both cores (when lockstep enabled)
    wire         core_key_req = ENABLE_LOCKSTEP ? (core_key_req_a | core_key_req_b) : core_key_req_a;
    wire [3:0]   core_round_num;
    
    assign core_round_num = ENABLE_LOCKSTEP ? 
                            (core_key_req_a ? core_round_num_a : core_round_num_b) : 
                            core_round_num_a;
    
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
    
    //========================================================================
    // Dual-Core Lockstep Implementation (Configurable)
    //========================================================================
    
    // Core A - Primary execution (always present)
    wire [127:0] core_data_out_a;
    wire         core_done_a;
    
    aes_core u_core_a (
        .clk        (clk),
        .rst_n      (rst_n),
        .start      (core_start),
        .done       (core_done_a),
        .encrypt    (encrypt),
        .key_len    (key_mode),
        .mode       (aes_mode),
        .data_in    (s_axis_tdata),
        .data_out   (core_data_out_a),
        .iv         (iv_reg),
        .round_key  (round_key),
        .round_num  (core_round_num_a),
        .key_req    (core_key_req_a)
    );
    
    //========================================================================
    // Lockstep Generate Block
    //========================================================================
    
    // Signals from lockstep logic
    wire        core_done_b;
    wire [127:0] core_data_out_b;
    wire        fault_detected;
    wire [127:0] fault_safe_result;
    wire [31:0] crc_out;
    wire        crc_valid;
    
    generate
        if (ENABLE_LOCKSTEP) begin : gen_lockstep
            
            // Core B clock gating control
            // Core B clock is gated when dual_rail_effective=0
            reg core_b_clk_en;
            
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    core_b_clk_en <= 1'b0;
                end else begin
                    if (dual_rail_effective && core_start)
                        core_b_clk_en <= 1'b1;
                    else if (!dual_rail_effective && core_done_b)
                        core_b_clk_en <= 1'b0;
                end
            end
            
            // Core B clock (gated)
            wire core_b_clk = clk & core_b_clk_en;
            
            // Core B - Redundant execution (lockstep)
            aes_core u_core_b (
                .clk        (core_b_clk),
                .rst_n      (rst_n),
                .start      (core_start & dual_rail_effective),
                .done       (core_done_b),
                .encrypt    (encrypt),
                .key_len    (key_mode),
                .mode       (aes_mode),
                .data_in    (s_axis_tdata),
                .data_out   (core_data_out_b),
                .iv         (iv_reg),
                .round_key  (round_key),
                .round_num  (core_round_num_b),
                .key_req    (core_key_req_b)
            );
            
            // Combined done signal (both cores must complete when dual-rail enabled)
            wire core_done_both = dual_rail_effective ? (core_done_a & core_done_b) : core_done_a;
            assign core_done_combined = core_done_both;
            
            // CRC Checker
            wire crc_en = mode_reg[8];
            
            crc_checker u_crc_checker (
                .clk        (clk),
                .rst_n      (rst_n),
                .calc_start (core_done_both & crc_en),
                .calc_done  (),
                .data_in    (core_data_out_a),
                .crc_out    (crc_out),
                .crc_valid  (crc_valid)
            );
            
            // Fault Detector
            wire fault_type;
            
            fault_detector u_fault_detector (
                .clk              (clk),
                .rst_n            (rst_n),
                .enable           (dual_rail_effective),
                .op_start         (core_start),
                .op_done          (core_done_both),
                .result_a         (core_data_out_a),
                .result_b         (core_data_out_b),
                .result_a_valid   (core_done_a),
                .result_b_valid   (core_done_b),
                .crc_value        (crc_out),
                .crc_valid        (crc_valid),
                .fault_detected   (fault_detected),
                .fault_type       (fault_type),
                .safe_result      (fault_safe_result)
            );
            
        end else begin : gen_no_lockstep
            
            // No lockstep - tie off signals
            assign core_done_b = 1'b0;
            assign core_data_out_b = 128'd0;
            assign core_done_combined = core_done_a;
            assign fault_detected = 1'b0;
            assign fault_safe_result = core_data_out_a;
            assign crc_out = 32'd0;
            assign crc_valid = 1'b0;
            
        end
    endgenerate
    
    // CRC error detection
    reg crc_error_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_error_reg <= 1'b0;
        end else begin
            crc_error_reg <= 1'b0;  // Placeholder
        end
    end
    
    //========================================================================
    // Status Register Update
    //========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            status_reg <= 32'd0;
        end else begin
            status_reg[0] <= core_done_combined && !fault_detected;  // DONE only if no fault
            status_reg[1] <= ctrl_reg[0] || core_start;  // BUSY
            status_reg[2] <= crc_error_reg;  // CRC_ERR
            status_reg[3] <= 1'b0;  // Reserved
            status_reg[4] <= fault_detected;  // FAULT_DETECTED (bit 4)
            status_reg[5] <= 1'b0;  // TIMEOUT_ERR
            status_reg[6] <= 1'b0;  // PARITY_ERR
            status_reg[7] <= 1'b0;  // KEY_ERR
            status_reg[9] <= dual_rail_en;  // DUAL_RAIL_EN status
        end
    end
    
    //========================================================================
    // Safe Output Selection Logic
    //========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_axis_tdata  <= 128'd0;
            m_axis_tlast  <= 1'b0;
            m_axis_tvalid <= 1'b0;
        end else if (core_done_combined) begin
            if (fault_detected) begin
                // Fault detected: output zero and deassert valid
                m_axis_tdata  <= 128'd0;
                m_axis_tvalid <= 1'b0;
            end else begin
                // No fault: output safe result
                if (ENABLE_LOCKSTEP && dual_rail_effective) begin
                    m_axis_tdata <= fault_safe_result;
                end else begin
                    m_axis_tdata <= core_data_out_a;
                end
                m_axis_tvalid <= 1'b1;
            end
            m_axis_tlast <= s_axis_tlast;
        end else begin
            m_axis_tvalid <= 1'b0;
        end
    end
    
    //========================================================================
    // Interrupt Generation
    //========================================================================
    
    // Internal interrupt set signals
    assign int_done_set  = core_done_combined && !fault_detected;
    assign int_error_set = 1'b0;  // Placeholder
    assign int_fault_set = fault_detected;
    assign int_crc_set   = crc_error_reg;
    
    // Interrupt outputs (masked by enable bits)
    assign int_done  = int_done_set  && int_en_reg[0];
    assign int_error = int_error_set && int_en_reg[1];
    assign int_fault = fault_detected && int_en_reg[2];
    
endmodule

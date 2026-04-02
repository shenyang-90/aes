//============================================================================
// Module: aes_top
// Description: AES IP Top Level - integrates all sub-modules
// Features: ECB/CBC/CTR/GCM/XTS/CTS modes, 128/192/256-bit keys
// Security: TI masked S-Box, fault detection, lockstep
// Safety: Configurable Dual-Rail Compare (Lockstep)
// Version: 1.1 (Safety Enhanced - Fixed CRC, Interrupt, Key Manager)
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
    output wire         int_fault,       // Fault detection interrupt
    
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
    
    //========================================================================
    // BUG-017 Fix: Correct BUSY signal logic
    // Design Spec v1.2 Section 8.2.3.3: BUSY = (state != IDLE) && (state != DONE)
    // Previously: ctrl_busy = status_reg[1] which was always 0 (Reserved)
    //========================================================================
    wire ctrl_busy = (ctrl_state != 4'd0) && (ctrl_state != 4'd9);  // IDLE=0, DONE=9
    
    //========================================================================
    // APB Interface
    //========================================================================
    wire apb_write = psel && penable && pwrite;
    wire apb_read  = psel && penable && !pwrite;
    
    // Clear fault signal (from STATUS register write)
    wire clear_fault = apb_write && (paddr == REG_STATUS);
    
    // DFT test mode bypass for lockstep
    wire test_mode = scan_en;  // In test mode, bypass lockstep
    wire dual_rail_effective = test_mode ? 1'b0 : dual_rail_en;
    
    // Combined done signal (set in generate block)
    wire core_done_combined;
    
    //========================================================================
    // Key Manager Instance (NEW: Added for key zeroize functionality)
    //========================================================================
    wire [255:0] key_managed;
    //========================================================================
    // Controller Signals (moved before key_manager instantiation)
    //========================================================================
    wire        core_start;
    wire        key_load;
    wire        iv_load;
    wire [2:0]  aes_mode;
    wire [1:0]  key_mode;
    wire        encrypt;
    wire        cts_enable;
    wire        m_axis_tvalid_ctrl;
    
    wire         key_valid_managed;
    wire         key_ready_managed;
    wire         zeroize_key;
    
    // Zeroize control: from CTRL[10] or security event
    assign zeroize_key = (apb_write && paddr == REG_CTRL && pwdata[10]);
    
    key_manager u_key_manager (
        .clk        (clk),
        .rst_n      (rst_n),
        .key_load   (key_load),
        .key_len    (key_mode),
        .key_in     (key_reg),
        .key_out    (key_managed),
        .key_valid  (key_valid_managed),
        .zeroize    (zeroize_key),
        .key_ready  (key_ready_managed)
    );
    
    // Safety mechanism signals from controller
    wire        ctrl_timeout_err;
    wire        ctrl_fault_detected;
    wire        ctrl_int_done;
    wire        ctrl_int_error;
    
    // BUG-017 Fix: Added ctrl_state output for BUSY detection
    wire [3:0] ctrl_state;
    
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
        .key_ready      (key_valid_managed),  // Use key_manager output
        .aes_mode       (aes_mode),
        .key_mode       (key_mode),
        .encrypt        (encrypt),
        .cts_enable     (cts_enable),
        .int_done       (ctrl_int_done),
        .int_error      (ctrl_int_error),
        // NEW: Safety mechanism ports
        .timeout_err    (ctrl_timeout_err),
        .fault_detected (ctrl_fault_detected),
        .clear_fault    (clear_fault),
        // BUG-017 Fix: Export state for BUSY detection
        .ctrl_state     (ctrl_state)
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
        .key_in     (key_managed),  // Use key_manager output
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
    wire        crc_calc_done;  // NEW: Connected calc_done signal
    wire        crc_error;      // NEW: CRC error flag
    
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
            
            // CRC calculation done detection (after 128 cycles for 128-bit data)
            reg crc_calc_active;
            reg [7:0] crc_cycle_cnt;
            
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    crc_calc_active <= 1'b0;
                    crc_cycle_cnt <= 8'd0;
                end else begin
                    if (core_done_both && crc_en && !crc_calc_active) begin
                        crc_calc_active <= 1'b1;
                        crc_cycle_cnt <= 8'd0;
                    end else if (crc_calc_active) begin
                        if (crc_cycle_cnt < 8'd127)
                            crc_cycle_cnt <= crc_cycle_cnt + 1'b1;
                        else
                            crc_calc_active <= 1'b0;
                    end
                end
            end
            
            assign crc_calc_done = crc_calc_active && (crc_cycle_cnt == 8'd127);
            
            crc_checker u_crc_checker (
                .clk        (clk),
                .rst_n      (rst_n),
                .calc_start (core_done_both & crc_en),
                .calc_done  (crc_calc_done),  // NEW: Now connected
                .data_in    (core_data_out_a),
                .crc_out    (crc_out),
                .crc_valid  (crc_valid)
            );
            
            // CRC Error Detection Logic
            // CRC error occurs when CRC is enabled but calculation shows invalid
            reg crc_error_reg;
            reg crc_check_done;
            
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    crc_error_reg <= 1'b0;
                    crc_check_done <= 1'b0;
                end else begin
                    if (crc_valid) begin
                        crc_check_done <= 1'b1;
                        // Check CRC value - non-zero indicates error
                        // (Standard CRC-32 should be 0 for valid data)
                        crc_error_reg <= (crc_out != 32'h0);
                    end else if (clear_fault) begin
                        crc_error_reg <= 1'b0;
                        crc_check_done <= 1'b0;
                    end
                end
            end
            
            assign crc_error = crc_error_reg;
            
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
            assign crc_calc_done = 1'b0;
            assign crc_error = 1'b0;
            
        end
    endgenerate
    
    //========================================================================
    // Status Register Update (Fixed per Design Spec v1.2)
    //========================================================================
    // Design Spec v1.2 STATUS register bit mapping:
    // [0]: BUSY
    // [1]: Reserved (was STATE[0])
    // [2]: Reserved (was STATE[1])  
    // [3]: Reserved (was STATE[2])
    // [4]: FAULT_DETECTED (sticky)
    // [5]: CRC_ERR
    // [6]: TIMEOUT_ERR
    // [7]: PARITY_ERR
    // [8]: MODE_ERR
    // [9]: KEY_ERR
    // [10]: LOCKSTEP_ACTIVE
    
    reg fault_detected_sticky;
    reg crc_error_sticky;
    reg timeout_error_sticky;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            status_reg <= 32'd0;
            fault_detected_sticky <= 1'b0;
            crc_error_sticky <= 1'b0;
            timeout_error_sticky <= 1'b0;
        end else begin
            // Sticky fault bits - W1C (Write 1 to Clear)
            if (fault_detected || ctrl_fault_detected)
                fault_detected_sticky <= 1'b1;
            else if (apb_write && paddr == REG_STATUS && pwdata[4])
                fault_detected_sticky <= 1'b0;
                
            if (crc_error)
                crc_error_sticky <= 1'b1;
            else if (apb_write && paddr == REG_STATUS && pwdata[5])
                crc_error_sticky <= 1'b0;
                
            if (ctrl_timeout_err)
                timeout_error_sticky <= 1'b1;
            else if (apb_write && paddr == REG_STATUS && pwdata[6])
                timeout_error_sticky <= 1'b0;
            
            // BUG-017 Fix: Status register fields
            // Design Spec v1.2 Section 8.2.3.3: BUSY reflects actual operation state
            status_reg[0]  <= ctrl_busy;  // BUSY = (state != IDLE) && (state != DONE)
            status_reg[1]  <= 1'b0;  // Reserved
            status_reg[2]  <= 1'b0;  // Reserved
            status_reg[3]  <= 1'b0;  // Reserved
            status_reg[4]  <= fault_detected_sticky;      // FAULT_DETECTED
            status_reg[5]  <= crc_error_sticky;           // CRC_ERR
            status_reg[6]  <= timeout_error_sticky;       // TIMEOUT_ERR
            status_reg[7]  <= 1'b0;  // PARITY_ERR (not implemented)
            status_reg[8]  <= 1'b0;  // MODE_ERR (not implemented)
            status_reg[9]  <= !key_valid_managed;         // KEY_ERR if key not valid
            status_reg[10] <= dual_rail_en && ENABLE_LOCKSTEP;  // LOCKSTEP_ACTIVE
        end
    end
    
    //========================================================================
    // APB Write/Read Logic
    //========================================================================
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
            // Design Spec v1.2: [0]=ERROR_STATUS, [1]=DONE_STATUS, [2]=FAULT_STATUS
            if (int_error_set)
                int_status_reg[0] <= 1'b1;
            if (int_done_set)
                int_status_reg[1] <= 1'b1;
            if (int_fault_set)
                int_status_reg[2] <= 1'b1;
            if (int_crc_set)
                int_status_reg[3] <= 1'b1;
            
            if (apb_write) begin
                case (paddr)
                    REG_CTRL: begin
                        // BUG-017 Fix: DUAL_RAIL_EN (bit 9) protection with correct BUSY logic
                        // Design Spec v1.2 Section 8.2.3.3: Cannot modify DUAL_RAIL_EN during operation
                        if (ctrl_busy) begin
                            // When BUSY: Only allow changes to non-DUAL_RAIL_EN bits
                            ctrl_reg[31:10] <= pwdata[31:10];
                            ctrl_reg[8:0]   <= pwdata[8:0];
                            // Bit 9 (DUAL_RAIL_EN) is protected and unchanged
                        end else begin
                            // When NOT BUSY: Allow all changes including DUAL_RAIL_EN
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
    // Safe Output Selection Logic
    //========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_axis_tdata  <= 128'd0;
            m_axis_tlast  <= 1'b0;
            m_axis_tvalid <= 1'b0;
        end else if (core_done_combined) begin
            if (fault_detected_sticky || crc_error_sticky) begin
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
    // Interrupt Generation (Fixed per Design Spec v1.2)
    //========================================================================
    
    // Internal interrupt set signals
    wire int_done_set;
    wire int_error_set;
    wire int_fault_set;
    wire int_crc_set;
    
    // DONE interrupt: operation completed successfully
    assign int_done_set  = core_done_combined && !fault_detected_sticky && !crc_error_sticky;
    
    // ERROR interrupt: any error condition
    assign int_error_set = ctrl_timeout_err || crc_error_sticky || (ctrl_fault_detected && !fault_detected_sticky);
    
    // FAULT interrupt: fault detection from dual-rail
    assign int_fault_set = fault_detected_sticky || ctrl_fault_detected;
    
    // CRC interrupt: CRC error detected
    assign int_crc_set   = crc_error_sticky;
    
    // Interrupt outputs (masked by enable bits)
    // Design Spec v1.2: [0]=ERROR_INT_EN, [1]=DONE_INT_EN, [2]=FAULT_INT_EN
    assign int_error = int_error_set && int_en_reg[0];
    assign int_done  = int_done_set  && int_en_reg[1];
    assign int_fault = int_fault_set && int_en_reg[2];
    
endmodule

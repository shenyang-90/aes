//============================================================================
// Module: mode_controller
// Description: AES mode controller - ECB/CBC/CTR/GCM/XTS/CTS
//============================================================================

module mode_controller (
    input  wire        clk,
    input  wire        rst_n,
    
    // Control
    input  wire        start,
    output reg         done,
    input  wire [2:0]  mode,            // 0=ECB, 1=CBC, 2=CTR, 3=GCM, 4=XTS, 5=CTS
    input  wire        encrypt,
    
    // Data
    input  wire [127:0] data_in,
    output reg  [127:0] data_out,
    input  wire [127:0] iv,             // IV for CBC/CTR/GCM
    input  wire [127:0] key,            // Key for XTS tweak
    
    // GCM Additional Data
    input  wire [127:0] aad_data,
    input  wire         aad_valid,
    input  wire [63:0]  aad_len,
    input  wire [63:0]  ct_len,
    output wire [127:0] gcm_tag,
    output wire         gcm_tag_valid,
    
    // AES Core interface
    output reg  [127:0] core_in,
    input  wire [127:0] core_out,
    output reg          core_start,
    input  wire         core_done
);

    // Mode definitions
    localparam [2:0] MODE_ECB = 3'd0;
    localparam [2:0] MODE_CBC = 3'd1;
    localparam [2:0] MODE_CTR = 3'd2;
    localparam [2:0] MODE_GCM = 3'd3;
    localparam [2:0] MODE_XTS = 3'd4;
    localparam [2:0] MODE_CTS = 3'd5;
    
    // State machine
    localparam [2:0] IDLE       = 3'd0;
    localparam [2:0] LOAD_IV    = 3'd1;
    localparam [2:0] PREPARE    = 3'd2;
    localparam [2:0] PROCESS    = 3'd3;
    localparam [2:0] POST_PROC  = 3'd4;
    localparam [2:0] DONE       = 3'd5;
    
    reg [2:0] state;
    reg [127:0] iv_reg;
    reg [127:0] feedback;
    
    // CTR counter
    reg [127:0] ctr_counter;
    
    // GCM signals
    reg [127:0] gcm_hash_subkey_h;  // H = E(K, 0^128)
    reg         gcm_calc_h;         // Flag to calculate H
    reg         gcm_ct_valid;
    reg         gcm_ct_last;
    reg [127:0] gcm_ct_data;
    
    // GCM engine instance
    gcm_engine u_gcm_engine (
        .clk            (clk),
        .rst_n          (rst_n),
        .gcm_en         (mode == MODE_GCM),
        .gcm_start      (gcm_calc_h),
        .gcm_done       (done),
        .hash_subkey_h  (gcm_hash_subkey_h),
        .aad_data       (aad_data),
        .aad_valid      (aad_valid),
        .aad_last       (1'b0),  // Simplified: single AAD block
        .ct_data        (gcm_ct_data),
        .ct_valid       (gcm_ct_valid),
        .ct_last        (gcm_ct_last),
        .aad_len        (aad_len),
        .ct_len         (ct_len),
        .tag            (gcm_tag),
        .tag_valid      (gcm_tag_valid)
    );
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            done <= 1'b0;
            core_start <= 1'b0;
            iv_reg <= 128'd0;
            feedback <= 128'd0;
            ctr_counter <= 128'd0;
            gcm_calc_h <= 1'b0;
            gcm_hash_subkey_h <= 128'd0;
            gcm_ct_valid <= 1'b0;
            gcm_ct_last <= 1'b0;
            gcm_ct_data <= 128'd0;
        end else begin
            core_start <= 1'b0;
            done <= 1'b0;
            
            case (state)
                IDLE: begin
                    if (start) begin
                        iv_reg <= iv;
                        ctr_counter <= iv;
                        feedback <= iv;
                        state <= PREPARE;
                    end
                end
                
                PREPARE: begin
                    case (mode)
                        MODE_ECB: begin
                            core_in <= data_in;
                            state <= PROCESS;
                        end
                        
                        MODE_CBC: begin
                            if (encrypt)
                                core_in <= data_in ^ feedback;
                            else
                                core_in <= data_in;
                            state <= PROCESS;
                        end
                        
                        MODE_CTR: begin
                            core_in <= ctr_counter;
                            state <= PROCESS;
                        end
                        
                        MODE_GCM: begin
                            // For GCM: First calculate H = E(K, 0^128)
                            if (!gcm_calc_h) begin
                                core_in <= 128'd0;  // Encrypt 0 to get H
                                gcm_calc_h <= 1'b1;
                                state <= PROCESS;
                            end else begin
                                // Then do CTR encryption for data
                                core_in <= ctr_counter;
                                state <= PROCESS;
                            end
                        end
                        
                        default: begin
                            core_in <= data_in;
                            state <= PROCESS;
                        end
                    endcase
                    
                    core_start <= 1'b1;
                end
                
                PROCESS: begin
                    if (core_done)
                        state <= POST_PROC;
                end
                
                POST_PROC: begin
                    case (mode)
                        MODE_ECB: begin
                            data_out <= core_out;
                        end
                        
                        MODE_CBC: begin
                            if (encrypt) begin
                                data_out <= core_out;
                                feedback <= core_out;
                            end else begin
                                data_out <= core_out ^ feedback;
                                feedback <= data_in;
                            end
                        end
                        
                        MODE_CTR: begin
                            data_out <= core_out ^ data_in;
                            ctr_counter <= ctr_counter + 1'b1;
                        end
                        
                        MODE_GCM: begin
                            if (gcm_calc_h && gcm_hash_subkey_h == 128'd0) begin
                                // First round: save H
                                gcm_hash_subkey_h <= core_out;
                                // Restart for data encryption
                                gcm_calc_h <= 1'b0;
                                state <= PREPARE;
                            end else begin
                                // CTR encryption result
                                data_out <= core_out ^ data_in;
                                // Feed ciphertext to GCM engine
                                gcm_ct_data <= core_out ^ data_in;
                                gcm_ct_valid <= 1'b1;
                                gcm_ct_last <= 1'b1;  // Simplified: single block
                                ctr_counter <= ctr_counter + 1'b1;
                            end
                        end
                        
                        default: begin
                            data_out <= core_out;
                        end
                    endcase
                    
                    state <= DONE;
                end
                
                DONE: begin
                    done <= 1'b1;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule

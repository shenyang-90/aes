//============================================================================
// SVA Assertions for AES IP
// Description: Safety and functional assertions for coverage improvement
//============================================================================

`ifndef AES_ASSERTIONS_SV
`define AES_ASSERTIONS_SV

//----------------------------------------------------------------------------
// 1. Key Manager Security Assertions
//----------------------------------------------------------------------------
module key_manager_assertions (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        key_clear,
    input  wire [255:0] key_reg,
    input  wire        key_valid
);

    // AS1: Key must be cleared when key_clear is asserted
    property p_key_clear;
        @(posedge clk)
        disable iff (!rst_n)
        key_clear |=> ##[1:10] key_reg == 256'd0;
    endproperty
    assert property (p_key_clear) else
        $error("AS1: Key not cleared after key_clear assertion");

    // AS2: Key should not be valid when cleared
    property p_key_invalid_after_clear;
        @(posedge clk)
        disable iff (!rst_n)
        key_clear |=> !key_valid;
    endproperty
    assert property (p_key_invalid_after_clear) else
        $error("AS2: Key valid after clear operation");

    // AS3: Key register should not have X values when valid
    property p_key_no_x_when_valid;
        @(posedge clk)
        disable iff (!rst_n)
        key_valid -> !$isunknown(key_reg);
    endproperty
    assert property (p_key_no_x_when_valid) else
        $error("AS3: Key has X values when valid");

endmodule

//----------------------------------------------------------------------------
// 2. S-Box Masked (TI) Consistency Assertions
//----------------------------------------------------------------------------
module sbox_masked_assertions (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_in,
    input  wire [7:0]  x0, x1, x2,
    input  wire [7:0]  y0, y1, y2,
    input  wire        valid_out
);

    // Reconstructed input/output
    wire [7:0] x_reconstructed = x0 ^ x1 ^ x2;
    wire [7:0] y_reconstructed = y0 ^ y1 ^ y2;

    // AS4: S-Box output should be stable when valid
    property p_sbox_output_stable;
        @(posedge clk)
        disable iff (!rst_n)
        valid_out |=> $stable(y_reconstructed) until !valid_out;
    endproperty
    assert property (p_sbox_output_stable) else
        $error("AS4: S-Box output changed while valid");

    // AS5: Shares should not all be equal (would leak information)
    property p_shares_not_equal;
        @(posedge clk)
        disable iff (!rst_n)
        valid_in |-> !((x0 == x1) && (x1 == x2));
    endproperty
    assert property (p_shares_not_equal) else
        $warning("AS5: All input shares are equal - potential security issue");

    // AS6: No X in output shares when valid
    property p_output_no_x;
        @(posedge clk)
        disable iff (!rst_n)
        valid_out -> (!$isunknown(y0) && !$isunknown(y1) && !$isunknown(y2));
    endproperty
    assert property (p_output_no_x) else
        $error("AS6: S-Box output has X values");

endmodule

//----------------------------------------------------------------------------
// 3. Mode Controller State Transition Assertions
//----------------------------------------------------------------------------
module mode_controller_assertions (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [2:0]  mode,
    input  wire        mode_change,
    input  wire        processing,
    input  wire [127:0] data_in,
    input  wire [127:0] data_out
);

    localparam [2:0] MODE_ECB = 3'd0;
    localparam [2:0] MODE_CBC = 3'd1;
    localparam [2:0] MODE_CTR = 3'd2;
    localparam [2:0] MODE_GCM = 3'd3;
    localparam [2:0] MODE_XTS = 3'd4;
    localparam [2:0] MODE_CTS = 3'd5;

    // AS7: Mode should be valid
    property p_mode_valid;
        @(posedge clk)
        disable iff (!rst_n)
        mode_change |-> mode inside {MODE_ECB, MODE_CBC, MODE_CTR, MODE_GCM, MODE_XTS, MODE_CTS};
    endproperty
    assert property (p_mode_valid) else
        $error("AS7: Invalid mode selected");

    // AS8: No mode change during processing
    property p_no_mode_change_during_process;
        @(posedge clk)
        disable iff (!rst_n)
        processing |-> $stable(mode);
    endproperty
    assert property (p_no_mode_change_during_process) else
        $error("AS8: Mode changed during processing");

endmodule

//----------------------------------------------------------------------------
// 4. GCM Engine GHASH Assertions
//----------------------------------------------------------------------------
module gcm_engine_assertions (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        gcm_start,
    input  wire [127:0] hash_subkey_h,
    input  wire [127:0] tag,
    input  wire        tag_valid,
    input  wire        gcm_done
);

    // AS10: Tag should be valid when tag_valid asserted
    property p_tag_valid_no_x;
        @(posedge clk)
        disable iff (!rst_n)
        tag_valid -> !$isunknown(tag);
    endproperty
    assert property (p_tag_valid_no_x) else
        $error("AS10: Tag has X values when valid");

    // AS11: Tag should be stable after valid until done
    property p_tag_stable;
        @(posedge clk)
        disable iff (!rst_n)
        tag_valid |=> $stable(tag) until gcm_done;
    endproperty
    assert property (p_tag_stable) else
        $error("AS11: Tag changed after becoming valid");

    // AS12: Hash subkey should not be zero after initialization
    property p_h_not_zero;
        @(posedge clk)
        disable iff (!rst_n)
        gcm_start |-> ##[1:5] hash_subkey_h != 128'd0;
    endproperty
    assert property (p_h_not_zero) else
        $warning("AS12: Hash subkey H is zero (may indicate encryption of zeros)");

endmodule

//----------------------------------------------------------------------------
// 5. XTS Engine Tweak Assertions
//----------------------------------------------------------------------------
module xts_engine_assertions (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [127:0] sector_id,
    input  wire [31:0]  block_num,
    input  wire [127:0] tweak,
    input  wire        tweak_valid
);

    // AS13: Tweak should be different for different sectors
    property p_tweak_sector_unique;
        @(posedge clk)
        disable iff (!rst_n)
        $changed(sector_id) && tweak_valid |=> ##[1:10] $changed(tweak);
    endproperty
    assert property (p_tweak_sector_unique) else
        $error("AS13: Tweak did not change with sector ID");

    // AS14: Tweak should be different for different blocks in same sector
    property p_tweak_block_unique;
        @(posedge clk)
        disable iff (!rst_n)
        $changed(block_num) && tweak_valid |=> ##[1:5] $changed(tweak);
    endproperty
    assert property (p_tweak_block_unique) else
        $error("AS14: Tweak did not change with block number");

    // AS15: Tweak should be non-zero
    property p_tweak_nonzero;
        @(posedge clk)
        disable iff (!rst_n)
        tweak_valid |-> tweak != 128'd0;
    endproperty
    assert property (p_tweak_nonzero) else
        $warning("AS15: Tweak is zero (weak encryption)");

endmodule

//----------------------------------------------------------------------------
// 6. AES Core Round Assertions
//----------------------------------------------------------------------------
module aes_core_assertions (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    input  wire        done,
    input  wire [3:0]  round_cnt,
    input  wire [1:0]  key_len
);

    localparam [1:0] KEY_128 = 2'd0;
    localparam [1:0] KEY_192 = 2'd1;
    localparam [1:0] KEY_256 = 2'd2;

    localparam [3:0] MAX_ROUND_128 = 4'd10;
    localparam [3:0] MAX_ROUND_192 = 4'd12;
    localparam [3:0] MAX_ROUND_256 = 4'd14;

    // AS16: Round count should not exceed max for key length
    property p_round_count_128;
        @(posedge clk)
        disable iff (!rst_n)
        (key_len == KEY_128) && start |-> ##[1:12] round_cnt <= MAX_ROUND_128;
    endproperty
    assert property (p_round_count_128) else
        $error("AS16: Round count exceeded for AES-128");

    property p_round_count_192;
        @(posedge clk)
        disable iff (!rst_n)
        (key_len == KEY_192) && start |-> ##[1:14] round_cnt <= MAX_ROUND_192;
    endproperty
    assert property (p_round_count_192) else
        $error("AS17: Round count exceeded for AES-192");

    property p_round_count_256;
        @(posedge clk)
        disable iff (!rst_n)
        (key_len == KEY_256) && start |-> ##[1:16] round_cnt <= MAX_ROUND_256;
    endproperty
    assert property (p_round_count_256) else
        $error("AS18: Round count exceeded for AES-256");

    // AS19: Done should be asserted after correct number of rounds
    property p_done_after_rounds;
        @(posedge clk)
        disable iff (!rst_n)
        start |-> ##[10:16] done;
    endproperty
    assert property (p_done_after_rounds) else
        $error("AS19: Done not asserted after expected rounds");

endmodule

//----------------------------------------------------------------------------
// 7. General Safety Assertions
//----------------------------------------------------------------------------
module aes_safety_assertions (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [2:0]  state,
    input  wire        error,
    input  wire        int_error
);

    // AS20: Error should be reported via interrupt
    property p_error_to_interrupt;
        @(posedge clk)
        disable iff (!rst_n)
        error |-> ##[1:5] int_error;
    endproperty
    assert property (p_error_to_interrupt) else
        $error("AS20: Error not reported via interrupt");

endmodule

`endif // AES_ASSERTIONS_SV

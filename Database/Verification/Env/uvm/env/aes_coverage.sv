//============================================================================
// Class: aes_coverage
// Description: AES Coverage Collection
//============================================================================

class aes_coverage extends uvm_subscriber#(apb_transaction);
    `uvm_component_utils(aes_coverage)

    // Covergroups
    covergroup aes_mode_cg;
        option.name = "AES Mode Coverage";
        mode: coverpoint mode {
            bins ecb = {AES_ECB};
            bins cbc = {AES_CBC};
            bins ctr = {AES_CTR};
            bins gcm = {AES_GCM};
            bins xts = {AES_XTS};
            bins cts = {AES_CTS};
        }
    endgroup

    covergroup key_len_cg;
        option.name = "Key Length Coverage";
        key_len: coverpoint key_len {
            bins key_128 = {KEY_128};
            bins key_192 = {KEY_192};
            bins key_256 = {KEY_256};
        }
    endgroup

    covergroup operation_cg;
        option.name = "Operation Coverage";
        encrypt: coverpoint encrypt;
        cross mode, key_len, encrypt;
    endgroup
    
    // Extended Covergroups for Coverage Improvement
    covergroup cts_length_cg;
        option.name = "CTS Length Coverage";
        cts_last_len: coverpoint cts_last_len {
            bins min_length = {1};
            bins short[4] = {[2:31]};
            bins medium[4] = {[32:63]};
            bins long[4] = {[64:95]};
            bins near_full[4] = {[96:127]};
            bins max_length = {127};
            illegal_bins invalid = {0, [128:$]};
        }
        cross cts_last_len, encrypt;
    endgroup
    
    covergroup fault_type_cg;
        option.name = "Fault Type Coverage";
        fault_type: coverpoint fault_type {
            bins clk_glitch_single = {0};
            bins clk_glitch_multi = {1};
            bins data_corrupt_bit = {2};
            bins data_corrupt_byte = {3};
            bins key_corrupt = {4};
        }
    endgroup
    
    covergroup gcm_aad_cg;
        option.name = "GCM AAD Coverage";
        aad_len: coverpoint aad_len {
            bins no_aad = {0};
            bins short_aad = {[1:128]};
            bins medium_aad = {[129:512]};
            bins long_aad = {[513:1024]};
        }
        ct_len: coverpoint ct_len {
            bins short_ct = {[0:128]};
            bins medium_ct = {[129:512]};
            bins long_ct = {[513:1024]};
        }
        cross aad_len, ct_len;
    endgroup
    
    covergroup xts_sector_cg;
        option.name = "XTS Sector Coverage";
        sector_id_lsb: coverpoint sector_id[31:0] {
            bins sector_0 = {0};
            bins sector_1 = {1};
            bins sector_small = {[2:255]};
            bins sector_medium = {[256:65535]};
            bins sector_large = {[65536:$]};
        }
        block_num: coverpoint block_num {
            bins block_0 = {0};
            bins block_1 = {1};
            bins block_small = {[2:15]};
            bins block_medium = {[16:255]};
            bins block_large = {[256:$]};
        }
        cross sector_id_lsb, block_num;
    endgroup

    // State
    aes_mode_t mode;
    key_len_t key_len;
    bit encrypt;
    
    // Extended state
    bit [6:0] cts_last_len;
    bit [2:0] fault_type;
    bit [10:0] aad_len;
    bit [10:0] ct_len;
    bit [31:0] sector_id;
    bit [31:0] block_num;

    function new(string name = "aes_coverage", uvm_component parent = null);
        super.new(name, parent);
        aes_mode_cg = new();
        key_len_cg = new();
        operation_cg = new();
        cts_length_cg = new();
        fault_type_cg = new();
        gcm_aad_cg = new();
        xts_sector_cg = new();
    endfunction

    uvm_analysis_imp#(apb_transaction, aes_coverage) apb_coverage_export;
    uvm_analysis_imp#(axis_transaction, aes_coverage) axis_coverage_export;

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        apb_coverage_export = new("apb_coverage_export", this);
        axis_coverage_export = new("axis_coverage_export", this);
    endfunction

    virtual function void write(apb_transaction t);
        case (t.addr)
            REG_MODE: begin
                mode = aes_mode_t'(t.data[6:4]);
                encrypt = t.data[1];
                aes_mode_cg.sample();
                operation_cg.sample();
            end
            REG_KEY_LEN: begin
                key_len = key_len_t'(t.data[1:0]);
                key_len_cg.sample();
                operation_cg.sample();
            end
        endcase
    endfunction

    virtual function void write(axis_transaction t);
        // Data coverage if needed
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("COV", $sformatf("Mode Coverage: %0f%%", aes_mode_cg.get_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf("Key Length Coverage: %0f%%", key_len_cg.get_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf("Operation Coverage: %0f%%", operation_cg.get_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf("CTS Length Coverage: %0f%%", cts_length_cg.get_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf("Fault Type Coverage: %0f%%", fault_type_cg.get_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf("GCM AAD Coverage: %0f%%", gcm_aad_cg.get_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf("XTS Sector Coverage: %0f%%", xts_sector_cg.get_coverage()), UVM_LOW)
    endfunction

endclass

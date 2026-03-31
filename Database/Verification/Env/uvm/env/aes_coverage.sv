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

    // State
    aes_mode_t mode;
    key_len_t key_len;
    bit encrypt;

    function new(string name = "aes_coverage", uvm_component parent = null);
        super.new(name, parent);
        aes_mode_cg = new();
        key_len_cg = new();
        operation_cg = new();
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
    endfunction

endclass

//============================================================================
// Class: aes_base_sequence
// Description: Base sequence for AES transactions
//============================================================================

class aes_base_sequence extends uvm_sequence#(apb_transaction);
    `uvm_object_utils(aes_base_sequence)

    function new(string name = "aes_base_sequence");
        super.new(name);
    endfunction

    task pre_body();
        if (starting_phase != null)
            starting_phase.raise_objection(this);
    endtask

    task post_body();
        if (starting_phase != null)
            starting_phase.drop_objection(this);
    endtask

endclass

//============================================================================
// Configuration Sequence
//============================================================================
class aes_config_sequence extends aes_base_sequence;
    `uvm_object_utils(aes_config_sequence)

    rand aes_mode_t mode;
    rand key_len_t key_len;
    rand bit encrypt;
    rand bit [255:0] key;
    rand bit [127:0] iv;

    constraint config_c {
        mode inside {AES_ECB, AES_CBC, AES_CTR, AES_XTS, AES_CTS};
        key_len inside {KEY_128, KEY_192, KEY_256};
    }

    function new(string name = "aes_config_sequence");
        super.new(name);
    endfunction

    task body();
        apb_transaction tr;
        
        `uvm_info("SEQ", $sformatf("Configuring AES: mode=%s, key=%s, encrypt=%b",
            mode.name(), key_len.name(), encrypt), UVM_MEDIUM)
        
        // Write key length
        tr = apb_transaction::type_id::create("tr");
        start_item(tr);
        tr.addr = REG_KEY_LEN;
        tr.data = key_len;
        tr.write = 1;
        finish_item(tr);
        
        // Write mode
        tr = apb_transaction::type_id::create("tr");
        start_item(tr);
        tr.addr = REG_MODE;
        tr.data = {16'd0, 1'b0, 1'b0, mode, 1'b0, encrypt, 1'b0};
        tr.write = 1;
        finish_item(tr);
        
        // Write key (simplified - write first 4 words)
        for (int i = 0; i < 4; i++) begin
            tr = apb_transaction::type_id::create("tr");
            start_item(tr);
            tr.addr = REG_KEY_0 + (i * 4);
            tr.data = key[255-(i*32) -: 32];
            tr.write = 1;
            finish_item(tr);
        end
        
        // Write IV (for CBC/CTR/XTS)
        if (mode inside {AES_CBC, AES_CTR, AES_XTS}) begin
            for (int i = 0; i < 4; i++) begin
                tr = apb_transaction::type_id::create("tr");
                start_item(tr);
                tr.addr = REG_IV_0 + (i * 4);
                tr.data = iv[127-(i*32) -: 32];
                tr.write = 1;
                finish_item(tr);
            end
        end
        
        // Start operation
        tr = apb_transaction::type_id::create("tr");
        start_item(tr);
        tr.addr = REG_CTRL;
        tr.data = 32'h0001_0001;  // Start + INT enable
        tr.write = 1;
        finish_item(tr);
        
    endtask

endclass

//============================================================================
// ECB Sequence
//============================================================================
class aes_ecb_sequence extends aes_base_sequence;
    `uvm_object_utils(aes_ecb_sequence)

    function new(string name = "aes_ecb_sequence");
        super.new(name);
    endfunction

    task body();
        aes_config_sequence config_seq;
        axis_transaction axis_tr;
        
        `uvm_info("SEQ", "Running ECB sequence", UVM_MEDIUM)
        
        // Configure for ECB
        config_seq = aes_config_sequence::type_id::create("config_seq");
        config_seq.mode = AES_ECB;
        config_seq.randomize();
        config_seq.start(m_sequencer);
        
        // Send data blocks
        repeat(10) begin
            axis_tr = axis_transaction::type_id::create("axis_tr");
            axis_tr.randomize();
            // Send via AXIS agent
        end
        
    endtask

endclass

// Placeholder for other sequences
class aes_cbc_sequence extends aes_base_sequence;
    `uvm_object_utils(aes_cbc_sequence)
    function new(string name = "aes_cbc_sequence"); super.new(name); endfunction
endclass

class aes_ctr_sequence extends aes_base_sequence;
    `uvm_object_utils(aes_ctr_sequence)
    function new(string name = "aes_ctr_sequence"); super.new(name); endfunction
endclass

class aes_xts_sequence extends aes_base_sequence;
    `uvm_object_utils(aes_xts_sequence)
    function new(string name = "aes_xts_sequence"); super.new(name); endfunction
endclass

class aes_cts_sequence extends aes_base_sequence;
    `uvm_object_utils(aes_cts_sequence)
    function new(string name = "aes_cts_sequence"); super.new(name); endfunction
endclass

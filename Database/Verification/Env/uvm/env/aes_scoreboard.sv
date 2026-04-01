//============================================================================
// Class: aes_scoreboard
// Description: AES Scoreboard with reference model
//============================================================================

class aes_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(aes_scoreboard)

    // Analysis exports
    uvm_analysis_export#(apb_transaction) apb_analysis_export;
    uvm_analysis_export#(axis_transaction) axis_in_analysis_export;
    uvm_analysis_export#(axis_transaction) axis_out_analysis_export;
    
    // Analysis FIFOs
    uvm_tlm_analysis_fifo#(apb_transaction) apb_fifo;
    uvm_tlm_analysis_fifo#(axis_transaction) axis_in_fifo;
    uvm_tlm_analysis_fifo#(axis_transaction) axis_out_fifo;

    // Configuration
    bit [255:0] current_key;
    aes_mode_t current_mode;
    key_len_t current_key_len;
    bit encrypt_mode;
    
    // Statistics
    int total_transactions;
    int pass_count;
    int fail_count;

    function new(string name = "aes_scoreboard", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        apb_analysis_export = new("apb_analysis_export", this);
        axis_in_analysis_export = new("axis_in_analysis_export", this);
        axis_out_analysis_export = new("axis_out_analysis_export", this);
        
        apb_fifo = new("apb_fifo", this);
        axis_in_fifo = new("axis_in_fifo", this);
        axis_out_fifo = new("axis_out_fifo", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        apb_analysis_export.connect(apb_fifo.analysis_export);
        axis_in_analysis_export.connect(axis_in_fifo.analysis_export);
        axis_out_analysis_export.connect(axis_out_fifo.analysis_export);
    endfunction

    task run_phase(uvm_phase phase);
        apb_transaction apb_tr;
        axis_transaction axis_in_tr;
        axis_transaction axis_out_tr;
        
        forever begin
            // Get APB transaction (configuration)
            apb_fifo.get(apb_tr);
            process_apb_transaction(apb_tr);
            
            // Get input data
            axis_in_fifo.get(axis_in_tr);
            
            // Get output data
            axis_out_fifo.get(axis_out_tr);
            
            // Compare
            compare_result(axis_in_tr, axis_out_tr);
        end
    endtask

    function void process_apb_transaction(apb_transaction tr);
        case (tr.addr)
            REG_KEY_0: current_key[255:224] = tr.data;
            REG_KEY_1: current_key[223:192] = tr.data;
            REG_KEY_2: current_key[191:160] = tr.data;
            REG_KEY_3: current_key[159:128] = tr.data;
            REG_KEY_4: current_key[127:96]  = tr.data;
            REG_KEY_5: current_key[95:64]   = tr.data;
            REG_KEY_6: current_key[63:32]   = tr.data;
            REG_KEY_7: current_key[31:0]    = tr.data;
            REG_MODE: begin
                current_mode = aes_mode_t'(tr.data[6:4]);
                encrypt_mode = tr.data[1];
            end
            REG_KEY_LEN: current_key_len = key_len_t'(tr.data[1:0]);
        endcase
    endfunction

    function void compare_result(axis_transaction in_tr, axis_transaction out_tr);
        bit [127:0] expected;
        bit result_ok;
        
        total_transactions++;
        
        // Call reference model (placeholder - should use C/Python model)
        expected = calculate_expected(in_tr.data);
        
        result_ok = (out_tr.data == expected);
        
        if (result_ok) begin
            pass_count++;
            `uvm_info("SCB", $sformatf("PASS: Data match (mode=%s)", current_mode.name()), UVM_MEDIUM)
        end else begin
            fail_count++;
            `uvm_error("SCB", $sformatf("FAIL: Expected %h, Got %h", expected, out_tr.data))
        end
    endfunction

    // Placeholder reference model
    function bit [127:0] calculate_expected(bit [127:0] data);
        // TODO: Integrate with C/Python reference model
        return data ^ 128'h12345678;  // Placeholder
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("SCB", $sformatf("Total: %0d, Pass: %0d, Fail: %0d", 
                                   total_transactions, pass_count, fail_count), UVM_LOW)
    endfunction

endclass

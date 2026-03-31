//============================================================================
// Class: aes_base_test
// Description: AES Base Test Class
//============================================================================

class aes_base_test extends uvm_test;
    `uvm_component_utils(aes_base_test)

    aes_env env;
    
    // Test configuration
    rand aes_mode_t test_mode;
    rand key_len_t test_key_len;
    rand bit test_encrypt;

    constraint default_c {
        test_mode inside {AES_ECB, AES_CBC, AES_CTR, AES_XTS, AES_CTS};
        test_key_len inside {KEY_128, KEY_192, KEY_256};
    }

    function new(string name = "aes_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = aes_env::type_id::create("env", this);
    endfunction

    function void start_of_simulation_phase(uvm_phase phase);
        `uvm_info("TEST", $sformatf("Mode: %s, Key: %s, Encrypt: %b",
            test_mode.name(), test_key_len.name(), test_encrypt), UVM_LOW)
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        
        `uvm_info("TEST", "Starting test...", UVM_LOW)
        
        // Configure DUT via APB
        configure_dut();
        
        // Run main test
        run_test_body();
        
        // Wait for completion
        #1000;
        
        phase.drop_objection(this);
    endtask

    virtual task configure_dut();
        // To be overridden by derived tests
    endtask

    virtual task run_test_body();
        // To be overridden by derived tests
    endtask

    function void report_phase(uvm_phase phase);
        uvm_report_server server;
        int errors;
        
        server = uvm_report_server::get_server();
        errors = server.get_severity_count(UVM_ERROR);
        
        if (errors == 0)
            `uvm_info("TEST", "PASSED", UVM_NONE)
        else
            `uvm_error("TEST", $sformatf("FAILED with %0d errors", errors))
    endfunction

endclass

//============================================================================
// Smoke Test
//============================================================================
class aes_smoke_test extends aes_base_test;
    `uvm_component_utils(aes_smoke_test)

    function new(string name = "aes_smoke_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task configure_dut();
        // Simple ECB-128 configuration
        // This would use sequences in full implementation
        `uvm_info("TEST", "Configuring for smoke test (ECB-128)", UVM_MEDIUM)
    endtask

    task run_test_body();
        `uvm_info("TEST", "Running smoke test...", UVM_MEDIUM)
        // Send one block, check result
    endtask

endclass

//============================================================================
// ECB Test
//============================================================================
class aes_ecb_test extends aes_base_test;
    `uvm_component_utils(aes_ecb_test)

    constraint ecb_c {
        test_mode == AES_ECB;
    }

    function new(string name = "aes_ecb_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_test_body();
        `uvm_info("TEST", "Running ECB mode test", UVM_MEDIUM)
    endtask

endclass

//============================================================================
// CBC Test
//============================================================================
class aes_cbc_test extends aes_base_test;
    `uvm_component_utils(aes_cbc_test)

    constraint cbc_c {
        test_mode == AES_CBC;
    }

    function new(string name = "aes_cbc_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

endclass

//============================================================================
// CTR Test
//============================================================================
class aes_ctr_test extends aes_base_test;
    `uvm_component_utils(aes_ctr_test)

    constraint ctr_c {
        test_mode == AES_CTR;
    }

    function new(string name = "aes_ctr_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

endclass

//============================================================================
// XTS Test
//============================================================================
class aes_xts_test extends aes_base_test;
    `uvm_component_utils(aes_xts_test)

    constraint xts_c {
        test_mode == AES_XTS;
    }

    function new(string name = "aes_xts_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

endclass

//============================================================================
// CTS Test
//============================================================================
class aes_cts_test extends aes_base_test;
    `uvm_component_utils(aes_cts_test)

    constraint cts_c {
        test_mode == AES_CTS;
    }

    function new(string name = "aes_cts_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

endclass

//============================================================================
// Stress Test
//============================================================================
class aes_stress_test extends aes_base_test;
    `uvm_component_utils(aes_stress_test)

    function new(string name = "aes_stress_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_test_body();
        `uvm_info("TEST", "Running stress test with random modes/keys", UVM_MEDIUM)
        // Run multiple iterations with randomization
    endtask

endclass

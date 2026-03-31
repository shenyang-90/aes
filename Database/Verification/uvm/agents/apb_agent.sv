//============================================================================
// Class: apb_agent
// Description: APB Agent for AES configuration
//============================================================================

class apb_transaction extends uvm_sequence_item;
    rand bit [11:0] addr;
    rand bit [31:0] data;
    rand bit        write;  // 1=write, 0=read

    `uvm_object_utils_begin(apb_transaction)
        `uvm_field_int(addr, UVM_ALL_ON)
        `uvm_field_int(data, UVM_ALL_ON)
        `uvm_field_int(write, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "apb_transaction");
        super.new(name);
    endfunction
endclass

class apb_agent extends uvm_agent;
    `uvm_component_utils(apb_agent)

    uvm_analysis_port#(apb_transaction) ap;
    
    virtual apb_if vif;

    function new(string name = "apb_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        
        if (!uvm_config_db#(virtual apb_if)::get(this, "", "apb_vif", vif))
            `uvm_fatal("NO_VIF", "APB virtual interface not found")
    endfunction

endclass

class axis_transaction extends uvm_sequence_item;
    rand bit [127:0] data;
    rand bit         last;

    `uvm_object_utils_begin(axis_transaction)
        `uvm_field_int(data, UVM_ALL_ON)
        `uvm_field_int(last, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "axis_transaction");
        super.new(name);
    endfunction
endclass

class axis_agent extends uvm_agent;
    `uvm_component_utils(axis_agent)

    uvm_analysis_port#(axis_transaction) ap;
    
    virtual axis_if vif;
    int is_slave;

    function new(string name = "axis_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        
        if (!uvm_config_db#(virtual axis_if)::get(this, "", "axis_vif", vif))
            `uvm_fatal("NO_VIF", "AXIS virtual interface not found")
        
        if (!uvm_config_db#(int)::get(this, "", "is_slave", is_slave))
            is_slave = 1;
    endfunction

endclass

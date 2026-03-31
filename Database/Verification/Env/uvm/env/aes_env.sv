//============================================================================
// Class: aes_env
// Description: AES UVM Environment
//============================================================================

class aes_env extends uvm_env;
    `uvm_component_utils(aes_env)

    // Agents
    apb_agent apb_agt;
    axis_agent axis_s_agt;  // Slave (input)
    axis_agent axis_m_agt;  // Master (output)
    
    // Scoreboard
    aes_scoreboard scb;
    
    // Coverage
    aes_coverage cov;

    // Virtual interfaces
    virtual apb_if  apb_vif;
    virtual axis_if axis_s_vif;
    virtual axis_if axis_m_vif;

    function new(string name = "aes_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Get virtual interfaces
        if (!uvm_config_db#(virtual apb_if)::get(this, "", "apb_vif", apb_vif))
            `uvm_fatal("NO_VIF", "APB virtual interface not found")
        if (!uvm_config_db#(virtual axis_if)::get(this, "", "axis_s_vif", axis_s_vif))
            `uvm_fatal("NO_VIF", "AXIS Slave virtual interface not found")
        if (!uvm_config_db#(virtual axis_if)::get(this, "", "axis_m_vif", axis_m_vif))
            `uvm_fatal("NO_VIF", "AXIS Master virtual interface not found")
        
        // Create agents
        apb_agt = apb_agent::type_id::create("apb_agt", this);
        axis_s_agt = axis_agent::type_id::create("axis_s_agt", this);
        axis_m_agt = axis_agent::type_id::create("axis_m_agt", this);
        
        // Configure axis agents
        uvm_config_db#(int)::set(this, "axis_s_agt", "is_slave", 1);
        uvm_config_db#(int)::set(this, "axis_m_agt", "is_slave", 0);
        
        // Create scoreboard and coverage
        scb = aes_scoreboard::type_id::create("scb", this);
        cov = aes_coverage::type_id::create("cov", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        // Connect agents to scoreboard
        apb_agt.ap.connect(scb.apb_analysis_export);
        axis_s_agt.ap.connect(scb.axis_in_analysis_export);
        axis_m_agt.ap.connect(scb.axis_out_analysis_export);
        
        // Connect to coverage
        apb_agt.ap.connect(cov.apb_coverage_export);
        axis_s_agt.ap.connect(cov.axis_coverage_export);
    endfunction

endclass

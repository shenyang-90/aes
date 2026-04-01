//============================================================================
// Package: aes_test_pkg
// Description: AES IP UVM Test Package
//============================================================================

package aes_test_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"
    
    // Include common files
    `include "aes_types.sv"
    
    // Include agents
    `include "agents/apb_agent.sv"
    `include "agents/axis_agent.sv"
    
    // Include sequences
    `include "sequences/aes_base_sequence.sv"
    `include "sequences/aes_ecb_sequence.sv"
    `include "sequences/aes_cbc_sequence.sv"
    `include "sequences/aes_ctr_sequence.sv"
    `include "sequences/aes_xts_sequence.sv"
    `include "sequences/aes_cts_sequence.sv"
    
    // Include environment
    `include "env/aes_scoreboard.sv"
    `include "env/aes_coverage.sv"
    `include "env/aes_env.sv"
    
    // Include tests
    `include "tests/aes_base_test.sv"
    `include "tests/aes_smoke_test.sv"
    `include "tests/aes_ecb_test.sv"
    `include "tests/aes_cbc_test.sv"
    `include "tests/aes_ctr_test.sv"
    `include "tests/aes_xts_test.sv"
    `include "tests/aes_cts_test.sv"
    `include "tests/aes_stress_test.sv"

endpackage

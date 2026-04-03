// Verilator C++ wrapper for tb_top
// Unified testbench simulation wrapper

#include <verilated.h>
#include <verilated_vcd_c.h>
#include <verilated_cov.h>
#include "Vtb_top.h"
#include <iostream>

int main(int argc, char** argv) {
    // Initialize Verilator
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);
    
    // Create DUT instance
    Vtb_top* dut = new Vtb_top;
    
    // Setup VCD tracing
    VerilatedVcdC* tfp = new VerilatedVcdC;
    dut->trace(tfp, 99);
    tfp->open("waveform.vcd");
    
    // Get test name from command line
    std::string testname = "tc_smoke";
    for (int i = 1; i < argc; i++) {
        std::string arg = argv[i];
        if (arg.find("+TESTCASE=") == 0) {
            testname = arg.substr(10);
        }
    }
    
    VL_PRINTF("[INFO] Starting test: %s\n", testname.c_str());
    
    // Run simulation
    vluint64_t sim_time = 0;
    vluint64_t max_sim_time = 500000;  // 500K cycles max
    
    while (!Verilated::gotFinish() && sim_time < max_sim_time) {
        dut->eval();
        tfp->dump(sim_time);
        sim_time++;
    }
    
    if (sim_time >= max_sim_time) {
        VL_PRINTF("[WARN] Simulation timeout at time %lu\n", sim_time);
    } else {
        VL_PRINTF("[INFO] Simulation completed at time %lu\n", sim_time);
    }
    
    // Collect coverage
    VL_PRINTF("[INFO] Writing coverage.dat...\n");
    VerilatedCov::write("coverage.dat");
    
    // Cleanup
    tfp->close();
    delete tfp;
    delete dut;
    
    VL_PRINTF("[DONE] Coverage written\n");
    
    return 0;
}

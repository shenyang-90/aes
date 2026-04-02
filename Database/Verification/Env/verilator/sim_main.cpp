//============================================================================
// Verilator Simulation Main File
// Description: C++ wrapper for Verilator simulation
//============================================================================

#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vtb_coverage.h"
#include "Vtb_coverage_tb_coverage.h"
#include <iostream>
#include <cstdlib>
#include <ctime>

// Simulation time
vluint64_t main_time = 0;

double sc_time_stamp() {
    return main_time;
}

int main(int argc, char** argv) {
    // Initialize Verilator
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);
    
    // Create instance
    Vtb_coverage* top = new Vtb_coverage;
    
    // Setup tracing
    VerilatedVcdC* tfp = nullptr;
    if (argc > 1 && std::string(argv[1]) == "+trace") {
        tfp = new VerilatedVcdC;
        top->trace(tfp, 99);
        tfp->open("waveform.vcd");
    }
    
    // Initialize random seed
    srand(time(nullptr));
    
    std::cout << "========================================" << std::endl;
    std::cout << "AES IP Verilator Simulation" << std::endl;
    std::cout << "========================================" << std::endl;
    
    // Reset - access signals through tb_coverage
    top->tb_coverage->rst_n = 0;
    for (int i = 0; i < 20; i++) {
        top->tb_coverage->clk = !top->tb_coverage->clk;
        top->eval();
        if (tfp) tfp->dump(main_time);
        main_time++;
    }
    
    top->tb_coverage->rst_n = 1;
    std::cout << "[SIM] Reset released" << std::endl;
    
    // Run simulation
    int max_cycles = 100000;
    int cycle = 0;
    bool finished = false;
    
    while (cycle < max_cycles && !finished) {
        // Toggle clock
        top->tb_coverage->clk = !top->tb_coverage->clk;
        
        // Evaluate
        top->eval();
        
        // Dump trace
        if (tfp) tfp->dump(main_time);
        
        // Check for $finish
        if (Verilated::gotFinish()) {
            finished = true;
            std::cout << "[SIM] Simulation finished by $finish" << std::endl;
        }
        
        main_time++;
        if (top->tb_coverage->clk == 0) cycle++;
    }
    
    if (cycle >= max_cycles) {
        std::cout << "[SIM] Warning: Hit maximum cycle limit" << std::endl;
    }
    
    // Final evaluation
    top->final();
    
    // Close trace
    if (tfp) {
        tfp->close();
        delete tfp;
    }
    
    // Cleanup
    delete top;
    
    std::cout << "[SIM] Simulation complete" << std::endl;
    std::cout << "Total simulation time: " << main_time << " time units" << std::endl;
    
    return 0;
}

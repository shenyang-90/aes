// Verilator C++ wrapper for tb_coverage

#include <verilated.h>
#include <verilated_vcd_c.h>
#include <verilated_cov.h>
#include "Vtb_coverage.h"
#include <iostream>

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);
    
    Vtb_coverage* dut = new Vtb_coverage;
    
    VerilatedVcdC* tfp = new VerilatedVcdC;
    dut->trace(tfp, 99);
    tfp->open("waveform.vcd");
    
    VL_PRINTF("[INFO] Starting simulation\n");
    
    vluint64_t sim_time = 0;
    vluint64_t max_sim_time = 500000;
    
    while (!Verilated::gotFinish() && sim_time < max_sim_time) {
        dut->eval();
        tfp->dump(sim_time);
        sim_time++;
    }
    
    VL_PRINTF("[INFO] Simulation ended at time %lu\n", sim_time);
    
    VerilatedCov::write("coverage.dat");
    
    tfp->close();
    delete tfp;
    delete dut;
    
    VL_PRINTF("[DONE] Coverage written\n");
    
    return 0;
}

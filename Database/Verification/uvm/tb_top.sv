//============================================================================
// File: tb_top.sv
// Description: AES IP Testbench Top Level
//============================================================================

`timescale 1ns/1ps

module tb_top;

    import uvm_pkg::*;
    import aes_test_pkg::*;

    //========================================================================
    // Clock and Reset
    //========================================================================
    logic clk = 0;
    logic rst_n;
    
    initial begin
        forever #5 clk = ~clk;  // 100MHz
    end
    
    initial begin
        rst_n = 0;
        #100 rst_n = 1;
    end

    //========================================================================
    // DUT Interfaces
    //========================================================================
    
    // APB Interface
    apb_if apb_vif(clk, rst_n);
    
    // AXI4-Stream Slave (Input)
    axis_if axis_s_vif(clk, rst_n);
    
    // AXI4-Stream Master (Output)
    axis_if axis_m_vif(clk, rst_n);

    //========================================================================
    // DUT Instantiation
    //========================================================================
    aes_top dut (
        .clk            (clk),
        .rst_n          (rst_n),
        
        // APB
        .psel           (apb_vif.psel),
        .penable        (apb_vif.penable),
        .paddr          (apb_vif.paddr),
        .pwrite         (apb_vif.pwrite),
        .pwdata         (apb_vif.pwdata),
        .prdata         (apb_vif.prdata),
        .pready         (apb_vif.pready),
        .pslverr        (apb_vif.pslverr),
        
        // AXI4-Stream Slave
        .s_axis_tdata   (axis_s_vif.tdata),
        .s_axis_tvalid  (axis_s_vif.tvalid),
        .s_axis_tready  (axis_s_vif.tready),
        .s_axis_tlast   (axis_s_vif.tlast),
        
        // AXI4-Stream Master
        .m_axis_tdata   (axis_m_vif.tdata),
        .m_axis_tvalid  (axis_m_vif.tvalid),
        .m_axis_tready  (axis_m_vif.tready),
        .m_axis_tlast   (axis_m_vif.tlast),
        
        // Interrupts
        .int_done       (),
        .int_error      (),
        
        // DFT
        .scan_en        (1'b0),
        .scan_clk       (1'b0)
    );

    //========================================================================
    // UVM Test Start
    //========================================================================
    initial begin
        // Set virtual interfaces
        uvm_config_db#(virtual apb_if)::set(null, "*", "apb_vif", apb_vif);
        uvm_config_db#(virtual axis_if)::set(null, "*", "axis_s_vif", axis_s_vif);
        uvm_config_db#(virtual axis_if)::set(null, "*", "axis_m_vif", axis_m_vif);
        
        // Start UVM
        run_test();
    end

    //========================================================================
    // Waveform Dump
    //========================================================================
    initial begin
        $dumpfile("../../Temp/VCS/aes_tb.vcd");
        $dumpvars(0, tb_top);
    end

endmodule

//============================================================================
// APB Interface
//============================================================================
interface apb_if (
    input logic clk,
    input logic rst_n
);
    logic        psel;
    logic        penable;
    logic [11:0] paddr;
    logic        pwrite;
    logic [31:0] pwdata;
    logic [31:0] prdata;
    logic        pready;
    logic        pslverr;
    
    // Tasks for APB transactions
    task automatic write(input [11:0] addr, input [31:0] data);
        @(posedge clk);
        psel <= 1'b1;
        paddr <= addr;
        pwrite <= 1'b1;
        pwdata <= data;
        @(posedge clk);
        penable <= 1'b1;
        wait(pready);
        @(posedge clk);
        psel <= 1'b0;
        penable <= 1'b0;
    endtask
    
    task automatic read(input [11:0] addr, output [31:0] data);
        @(posedge clk);
        psel <= 1'b1;
        paddr <= addr;
        pwrite <= 1'b0;
        @(posedge clk);
        penable <= 1'b1;
        wait(pready);
        data = prdata;
        @(posedge clk);
        psel <= 1'b0;
        penable <= 1'b0;
    endtask
endinterface

//============================================================================
// AXI4-Stream Interface
//============================================================================
interface axis_if (
    input logic clk,
    input logic rst_n
);
    logic [127:0] tdata;
    logic         tvalid;
    logic         tready;
    logic         tlast;
    
    // Task for sending data
    task automatic send(input [127:0] data, input logic last = 1'b1);
        tdata <= data;
        tvalid <= 1'b1;
        tlast <= last;
        @(posedge clk);
        while (!tready) @(posedge clk);
        tvalid <= 1'b0;
    endtask
    
    // Task for receiving data
    task automatic receive(output [127:0] data, output logic last);
        tready <= 1'b1;
        @(posedge clk);
        while (!tvalid) @(posedge clk);
        data = tdata;
        last = tlast;
        tready <= 1'b0;
    endtask
endinterface

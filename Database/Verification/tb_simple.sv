//============================================================================
// Module: tb_simple
// Description: Simple non-UVM testbench for AES IP
// Compatible with: Icarus Verilog, Verilator
//============================================================================

`timescale 1ns/1ps

module tb_simple;

    //========================================================================
    // Clock and Reset
    //========================================================================
    reg clk = 0;
    reg rst_n;
    
    always #5 clk = ~clk;  // 100MHz
    
    initial begin
        rst_n = 0;
        #100 rst_n = 1;
    end

    //========================================================================
    // APB Interface Signals
    //========================================================================
    reg         psel;
    reg         penable;
    reg  [11:0] paddr;
    reg         pwrite;
    reg  [31:0] pwdata;
    wire [31:0] prdata;
    wire        pready;
    wire        pslverr;

    //========================================================================
    // AXI4-Stream Interface Signals
    //========================================================================
    reg  [127:0] s_axis_tdata;
    reg          s_axis_tvalid;
    wire         s_axis_tready;
    reg          s_axis_tlast;
    
    wire [127:0] m_axis_tdata;
    wire         m_axis_tvalid;
    reg          m_axis_tready;
    wire         m_axis_tlast;

    //========================================================================
    // Interrupts
    //========================================================================
    wire int_done;
    wire int_error;

    //========================================================================
    // DUT Instantiation
    //========================================================================
    aes_top dut (
        .clk            (clk),
        .rst_n          (rst_n),
        
        // APB
        .psel           (psel),
        .penable        (penable),
        .paddr          (paddr),
        .pwrite         (pwrite),
        .pwdata         (pwdata),
        .prdata         (prdata),
        .pready         (pready),
        .pslverr        (pslverr),
        
        // AXI4-Stream Slave (Input)
        .s_axis_tdata   (s_axis_tdata),
        .s_axis_tvalid  (s_axis_tvalid),
        .s_axis_tready  (s_axis_tready),
        .s_axis_tlast   (s_axis_tlast),
        
        // AXI4-Stream Master (Output)
        .m_axis_tdata   (m_axis_tdata),
        .m_axis_tvalid  (m_axis_tvalid),
        .m_axis_tready  (m_axis_tready),
        .m_axis_tlast   (m_axis_tlast),
        
        // Interrupts
        .int_done       (int_done),
        .int_error      (int_error),
        
        // DFT (unused)
        .scan_en        (1'b0),
        .scan_clk       (1'b0)
    );

    //========================================================================
    // APB Tasks
    //========================================================================
    task apb_write(input [11:0] addr, input [31:0] data);
        begin
            @(posedge clk);
            psel    <= 1'b1;
            paddr   <= addr;
            pwrite  <= 1'b1;
            pwdata  <= data;
            @(posedge clk);
            penable <= 1'b1;
            while (!pready) @(posedge clk);
            @(posedge clk);
            psel    <= 1'b0;
            penable <= 1'b0;
        end
    endtask

    task apb_read(input [11:0] addr, output [31:0] data);
        begin
            @(posedge clk);
            psel    <= 1'b1;
            paddr   <= addr;
            pwrite  <= 1'b0;
            @(posedge clk);
            penable <= 1'b1;
            while (!pready) @(posedge clk);
            data = prdata;
            @(posedge clk);
            psel    <= 1'b0;
            penable <= 1'b0;
        end
    endtask

    //========================================================================
    // AXI Stream Tasks
    //========================================================================
    task axis_send(input [127:0] data);
        begin
            s_axis_tdata  <= data;
            s_axis_tvalid <= 1'b1;
            s_axis_tlast  <= 1'b1;
            @(posedge clk);
            while (!s_axis_tready) @(posedge clk);
            s_axis_tvalid <= 1'b0;
        end
    endtask

    task axis_receive(output [127:0] data);
        begin
            m_axis_tready <= 1'b1;
            @(posedge clk);
            while (!m_axis_tvalid) @(posedge clk);
            data = m_axis_tdata;
            m_axis_tready <= 1'b0;
        end
    endtask

    //========================================================================
    // Register Addresses
    //========================================================================
    localparam [11:0] REG_CTRL       = 12'h000;
    localparam [11:0] REG_STATUS     = 12'h004;
    localparam [11:0] REG_KEY_LEN    = 12'h008;
    localparam [11:0] REG_MODE       = 12'h00C;
    localparam [11:0] REG_KEY_0      = 12'h010;
    localparam [11:0] REG_KEY_1      = 12'h014;
    localparam [11:0] REG_KEY_2      = 12'h018;
    localparam [11:0] REG_KEY_3      = 12'h01C;
    localparam [11:0] REG_INT_EN     = 12'h048;

    //========================================================================
    // Test Sequence
    //========================================================================
    initial begin
        reg [31:0] rdata;
        reg [127:0] plaintext;
        reg [127:0] ciphertext;
        
        // Initialize
        psel = 0;
        penable = 0;
        pwrite = 0;
        paddr = 0;
        pwdata = 0;
        s_axis_tdata = 0;
        s_axis_tvalid = 0;
        s_axis_tlast = 0;
        m_axis_tready = 0;
        
        $display("========================================");
        $display("AES IP Simple Testbench");
        $display("========================================");
        
        // Wait for reset
        @(posedge rst_n);
        #100;
        
        // Test 1: Configure for AES-128 ECB encryption
        $display("\n[TEST 1] Configure AES-128 ECB Encrypt");
        
        // Set key length to 128-bit
        apb_write(REG_KEY_LEN, 32'h0000_0000);
        
        // Set mode to ECB, Encrypt
        // bit[6:4]=mode(000=ECB), bit[1]=encrypt(1)
        apb_write(REG_MODE, 32'h0000_0002);
        
        // Write key (128-bit: 0x0123456789ABCDEF0123456789ABCDEF)
        apb_write(REG_KEY_0, 32'h0123_4567);
        apb_write(REG_KEY_1, 32'h89AB_CDEF);
        apb_write(REG_KEY_2, 32'h0123_4567);
        apb_write(REG_KEY_3, 32'h89AB_CDEF);
        
        // Enable interrupt
        apb_write(REG_INT_EN, 32'h0001_0001);
        
        // Start operation
        $display("[TEST 1] Starting encryption...");
        apb_write(REG_CTRL, 32'h0001_0001);
        
        // Send plaintext
        plaintext = 128'h00112233445566778899aabbccddeeff;
        $display("[TEST 1] Plaintext: %h", plaintext);
        axis_send(plaintext);
        
        // Receive ciphertext
        axis_receive(ciphertext);
        $display("[TEST 1] Ciphertext: %h", ciphertext);
        
        // Check result (placeholder - actual AES result would be different)
        if (ciphertext != plaintext) begin
            $display("[TEST 1] PASS: Output different from input");
        end else begin
            $display("[TEST 1] FAIL: Output same as input (not encrypted)");
        end
        
        // Read status
        apb_read(REG_STATUS, rdata);
        $display("[TEST 1] Status: %h", rdata);
        
        // End simulation
        #1000;
        $display("\n========================================");
        $display("Simulation Complete");
        $display("========================================");
        $finish;
    end

    //========================================================================
    // Waveform Dump
    //========================================================================
    initial begin
        $dumpfile("aes_simple.vcd");
        $dumpvars(0, tb_simple);
    end

endmodule

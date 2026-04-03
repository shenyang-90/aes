//============================================================================
// Coverage Testbench for AES IP - Verilator Version
// Description: Exhaustive testbench to maximize code coverage
// Usage: Verilator coverage collection
//============================================================================

`timescale 1ns / 1ps

module tb_coverage;

    // Clock and reset (public for Verilator C++ access)
    reg clk /* verilator public */ = 0;
    reg rst_n /* verilator public */ = 0;
    
    // APB interface
    reg [11:0] paddr;
    reg pwrite;
    reg [31:0] pwdata;
    wire [31:0] prdata;
    reg psel;
    reg penable;
    wire pready;
    wire pslverr;
    
    // AXI-Stream interface (Input)
    reg [127:0] s_axis_tdata;
    reg s_axis_tvalid;
    wire s_axis_tready;
    reg s_axis_tlast;
    
    // AXI-Stream interface (Output)
    wire [127:0] m_axis_tdata;
    wire m_axis_tvalid;
    reg m_axis_tready;
    wire m_axis_tlast;
    
    // Interrupts
    wire int_done;
    wire int_error;
    wire int_fault;
    
    // DUT instantiation
    aes_top dut (
        .clk(clk),
        .rst_n(rst_n),
        .paddr(paddr),
        .pwrite(pwrite),
        .pwdata(pwdata),
        .prdata(prdata),
        .psel(psel),
        .penable(penable),
        .pready(pready),
        .pslverr(pslverr),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .s_axis_tlast(s_axis_tlast),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tlast(m_axis_tlast),
        .int_done(int_done),
        .int_error(int_error),
        .int_fault(int_fault),
        .scan_en(1'b0),
        .scan_clk(1'b0)
    );
    
    // Clock generation: 100MHz
    always #5 clk = ~clk;
    
    // Test counters
    integer test_count = 0;
    integer pass_count = 0;
    integer fail_count = 0;
    
    // Task: APB write transaction
    task apb_write(input [11:0] addr, input [31:0] data);
        begin
            @(posedge clk);
            psel = 1;
            pwrite = 1;
            paddr = addr;
            pwdata = data;
            penable = 0;
            @(posedge clk);
            penable = 1;
            @(posedge clk);
            while (!pready) @(posedge clk);
            psel = 0;
            penable = 0;
            pwrite = 0;
        end
    endtask
    
    // Task: APB read transaction
    task apb_read(input [11:0] addr, output [31:0] data);
        begin
            @(posedge clk);
            psel = 1;
            pwrite = 0;
            paddr = addr;
            penable = 0;
            @(posedge clk);
            penable = 1;
            @(posedge clk);
            while (!pready) @(posedge clk);
            data = prdata;
            psel = 0;
            penable = 0;
        end
    endtask
    
    // Task: Send data via AXI-Stream
    task axis_send(input [127:0] data);
        begin
            s_axis_tdata = data;
            s_axis_tvalid = 1;
            s_axis_tlast = 1;
            @(posedge clk);
            while (!s_axis_tready) @(posedge clk);
            s_axis_tvalid = 0;
            s_axis_tlast = 0;
        end
    endtask
    
    // Task: Receive data via AXI-Stream
    task axis_recv(output [127:0] data);
        begin
            m_axis_tready = 1;
            @(posedge clk);
            while (!m_axis_tvalid) @(posedge clk);
            data = m_axis_tdata;
            m_axis_tready = 0;
        end
    endtask
    
    // Task: Complete AES operation
    task aes_operation(
        input [2:0] mode,       // 0=ECB, 1=CBC, 2=CTR, 3=GCM, 4=XTS, 5=CTS
        input [1:0] key_len,    // 0=128, 1=192, 2=256
        input encrypt,          // 1=encrypt, 0=decrypt
        input [255:0] key,
        input [127:0] iv,
        input [127:0] plaintext,
        output [127:0] ciphertext
    );
        begin
            integer timeout;
            reg [31:0] status;
            
            // Write KEY_LEN
            apb_write(12'h008, {30'd0, key_len});
            
            // Write KEY (all 8 words, hardware will use appropriate bits)
            apb_write(12'h010, key[255:224]);
            apb_write(12'h014, key[223:192]);
            apb_write(12'h018, key[191:160]);
            apb_write(12'h01C, key[159:128]);
            apb_write(12'h020, key[127:96]);
            apb_write(12'h024, key[95:64]);
            apb_write(12'h028, key[63:32]);
            apb_write(12'h02C, key[31:0]);
            
            // Write IV (for non-ECB modes)
            if (mode != 3'd0) begin
                apb_write(12'h030, iv[127:96]);
                apb_write(12'h034, iv[95:64]);
                apb_write(12'h038, iv[63:32]);
                apb_write(12'h03C, iv[31:0]);
            end
            
            // Write MODE register
            apb_write(12'h00C, {25'd0, mode, 1'b0, encrypt});
            
            // Start operation
            apb_write(12'h000, 32'h1);
            
            // Send plaintext via AXI-Stream
            axis_send(plaintext);
            
            // Wait for completion (poll STATUS register)
            timeout = 0;
            while (timeout < 10000 && !status[0]) begin
                apb_read(12'h004, status);
                timeout = timeout + 1;
                @(posedge clk);
            end
            
            // Extra cycles after done
            repeat(10) @(posedge clk);
            
            // Receive ciphertext via AXI-Stream
            axis_recv(ciphertext);
        end
    endtask
    
    // Main test sequence
    initial begin
        integer i;
        reg [127:0] pt, ct, result;
        reg [255:0] key;
        reg [127:0] iv;
        reg [31:0] rdata;
        
        $display("========================================");
        $display("AES IP Coverage Testbench (Verilator)");
        $display("========================================");
        
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
        
        // Release reset
        #100;
        rst_n = 1;
        #100;
        
        // Test 1: All modes with AES-128
        $display("\n[Test 1] All modes with AES-128");
        for (i = 0; i < 6; i = i + 1) begin
            pt = {i[31:0], i[31:0], i[31:0], i[31:0]};
            key = 256'h00112233445566778899aabbccddeeff;
            iv = 128'h0;
            aes_operation(i[2:0], 2'd0, 1'b1, key, iv, pt, ct);
            test_count = test_count + 1;
            $display("  Mode %0d: encrypt done", i);
        end
        
        // Test 2: All key lengths with ECB
        $display("\n[Test 2] All key lengths with ECB");
        for (i = 0; i < 3; i = i + 1) begin
            pt = 128'h00112233445566778899aabbccddeeff;
            key = 256'h0;
            iv = 128'h0;
            aes_operation(3'd0, i[1:0], 1'b1, key, iv, pt, ct);
            test_count = test_count + 1;
            $display("  Key length %0d: encrypt done", i);
        end
        
        // Test 3: Encrypt/Decrypt for all modes
        $display("\n[Test 3] Encrypt/Decrypt for all modes");
        for (i = 0; i < 6; i = i + 1) begin
            pt = 128'h00112233445566778899aabbccddeeff;
            key = 256'h00112233445566778899aabbccddeeff;
            iv = 128'h1234567890abcdef1234567890abcdef;
            
            // Encrypt
            aes_operation(i[2:0], 2'd0, 1'b1, key, iv, pt, ct);
            test_count = test_count + 1;
            
            // Decrypt
            aes_operation(i[2:0], 2'd0, 1'b0, key, iv, ct, result);
            test_count = test_count + 1;
            
            $display("  Mode %0d: encrypt/decrypt done", i);
        end
        
        // Test 4: Various plaintext patterns
        $display("\n[Test 4] Various plaintext patterns");
        for (i = 0; i < 16; i = i + 1) begin
            pt = {4{i[7:0], i[7:0], i[7:0], i[7:0]}};
            key = 256'h0;
            iv = 128'h0;
            aes_operation(3'd0, 2'd0, 1'b1, key, iv, pt, ct);
            test_count = test_count + 1;
        end
        $display("  16 patterns tested");
        
        // Test 5: Register read/write coverage
        $display("\n[Test 5] Register coverage");
        // Write then read all registers
        for (i = 0; i < 20; i = i + 1) begin
            apb_write(12'h000 + (i * 4), i[31:0]);
        end
        for (i = 0; i < 20; i = i + 1) begin
            apb_read(12'h000 + (i * 4), rdata);
        end
        $display("  20 registers tested");
        
        // Test 6: Interrupt status check
        $display("\n[Test 6] Interrupt and status check");
        apb_read(12'h004, rdata);  // STATUS
        $display("  STATUS: %h", rdata);
        apb_read(12'h04C, rdata);  // INT_STATUS
        $display("  INT_STATUS: %h", rdata);
        
        // Summary
        $display("\n========================================");
        $display("Coverage Test Summary");
        $display("========================================");
        $display("Total tests executed: %0d", test_count);
        $display("Coverage collection complete!");
        
        #100;
        $finish;
    end

endmodule

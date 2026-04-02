//============================================================================
// Coverage Testbench for AES IP
// Description: Exhaustive testbench to maximize code coverage
//============================================================================

`timescale 1ns / 1ps

module tb_coverage;

    // Clock and reset
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
    
    // AXI-Stream interface (simplified)
    reg [127:0] s_axis_tdata;
    reg s_axis_tvalid;
    wire s_axis_tready;
    reg s_axis_tlast;
    
    wire [127:0] m_axis_tdata;
    wire m_axis_tvalid;
    reg m_axis_tready;
    wire m_axis_tlast;
    
    // Interrupt
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
        .pslverr(),              // Not monitored
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
        .scan_en(1'b0),          // Disable scan mode
        .scan_clk(1'b0)          // Disable scan clock
    );
    
    // Clock generation
    always #5 clk = ~clk;
    
    // Test counters
    integer test_count = 0;
    integer pass_count = 0;
    
    // Task: APB write
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
        end
    endtask
    
    // Task: APB read
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
    
    // Task: AES operation
    task aes_operation(
        input [2:0] mode,
        input [1:0] key_len,
        input encrypt,
        input [255:0] key,
        input [127:0] iv,
        input [127:0] plaintext,
        output [127:0] ciphertext
    );
        begin
            integer i;
            reg [31:0] rdata;
            
            // Write KEY_LEN
            apb_write(12'h008, {30'd0, key_len});
            
            // Write KEY
            apb_write(12'h010, key[255:224]);
            apb_write(12'h014, key[223:192]);
            apb_write(12'h018, key[191:160]);
            apb_write(12'h01C, key[159:128]);
            apb_write(12'h020, key[127:96]);
            apb_write(12'h024, key[95:64]);
            apb_write(12'h028, key[63:32]);
            apb_write(12'h02C, key[31:0]);
            
            // Write IV (if needed)
            if (mode != 3'd0) begin // Not ECB
                apb_write(12'h030, iv[127:96]);
                apb_write(12'h034, iv[95:64]);
                apb_write(12'h038, iv[63:32]);
                apb_write(12'h03C, iv[31:0]);
            end
            
            // Write MODE and start
            apb_write(12'h00C, {27'd0, mode, 1'b0, encrypt});
            
            // Start operation
            apb_write(12'h000, 32'h1);
            
            // Wait for completion
            i = 0;
            while (i < 1000) begin
                apb_read(12'h004, rdata);
                if (rdata[0]) begin // DONE bit
                    #100;
                    i = 1000;
                end
                i = i + 1;
                #10;
            end
            
            // Read result (from stream interface or registers)
            // Simplified: just return 0 for now
            ciphertext = 128'd0;
        end
    endtask
    
    // Main test sequence
    initial begin
        integer i;
        reg [127:0] pt, ct, result;
        reg [255:0] key;
        reg [127:0] iv;
        
        $display("========================================");
        $display("AES IP Coverage Testbench");
        $display("========================================");
        
        // Initialize
        psel = 0;
        penable = 0;
        pwrite = 0;
        s_axis_tvalid = 0;
        s_axis_tlast = 0;
        m_axis_tready = 1;
        
        // Reset
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
        end
        
        // Test 2: All key lengths with ECB
        $display("\n[Test 2] All key lengths with ECB");
        for (i = 0; i < 3; i = i + 1) begin
            pt = 128'h00112233445566778899aabbccddeeff;
            key = 256'h0;
            iv = 128'h0;
            aes_operation(3'd0, i[1:0], 1'b1, key, iv, pt, ct);
            test_count = test_count + 1;
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
        
        // Test 5: Register read/write coverage
        $display("\n[Test 5] Register coverage");
        begin
            reg [31:0] rdata;
            // Read all registers
            apb_read(12'h000, rdata);
            apb_read(12'h004, rdata);
            apb_read(12'h008, rdata);
            apb_read(12'h00C, rdata);
            apb_read(12'h010, rdata);
            apb_read(12'h014, rdata);
            apb_read(12'h018, rdata);
            apb_read(12'h01C, rdata);
            apb_read(12'h020, rdata);
            apb_read(12'h024, rdata);
            apb_read(12'h028, rdata);
            apb_read(12'h02C, rdata);
            apb_read(12'h030, rdata);
            apb_read(12'h034, rdata);
            apb_read(12'h038, rdata);
            apb_read(12'h03C, rdata);
            apb_read(12'h040, rdata);
            apb_read(12'h044, rdata);
            apb_read(12'h048, rdata);
            apb_read(12'h04C, rdata);
        end
        
        // Summary
        $display("\n========================================");
        $display("Coverage Test Summary");
        $display("========================================");
        $display("Total tests: %0d", test_count);
        $display("\nCoverage collection complete!");
        $display("Check coverage database for details.");
        
        #100;
        $finish;
    end

endmodule

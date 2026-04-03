//============================================================================
// Base Testbench for AES IP Testcases
// Description: Provides DUT instance and common tasks for all testcases
//============================================================================

`timescale 1ns / 1ps

module tb_base;

    // Clock and reset
    reg clk = 0;
    reg rst_n = 0;
    
    always #5 clk = ~clk;
    
    initial begin
        rst_n = 0;
        #100 rst_n = 1;
    end

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

    // Test counters
    integer pass_cnt = 0;
    integer fail_cnt = 0;

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

    // Task: APB write transaction
    task apb_write(input [11:0] addr, input [31:0] data);
        begin
            @(posedge clk);
            psel = 1; pwrite = 1; paddr = addr; pwdata = data; penable = 0;
            @(posedge clk); penable = 1;
            @(posedge clk);
            while (!pready) @(posedge clk);
            psel = 0; penable = 0; pwrite = 0;
        end
    endtask

    // Task: APB read transaction
    task apb_read(input [11:0] addr, output [31:0] data);
        begin
            @(posedge clk);
            psel = 1; pwrite = 0; paddr = addr; penable = 0;
            @(posedge clk); penable = 1;
            @(posedge clk);
            while (!pready) @(posedge clk);
            data = prdata;
            psel = 0; penable = 0;
        end
    endtask

    // Task: AXI-Stream send
    task axis_send(input [127:0] data);
        begin
            s_axis_tdata = data; s_axis_tvalid = 1; s_axis_tlast = 1;
            @(posedge clk); while (!s_axis_tready) @(posedge clk);
            s_axis_tvalid = 0; s_axis_tlast = 0;
        end
    endtask

    // Task: AXI-Stream receive
    task axis_recv(output [127:0] data);
        begin
            m_axis_tready = 1;
            @(posedge clk); while (!m_axis_tvalid) @(posedge clk);
            data = m_axis_tdata; m_axis_tready = 0;
        end
    endtask

    // Task: AES operation
    task aes_op(
        input [2:0] mode,
        input [1:0] key_len,
        input encrypt,
        input [255:0] key,
        input [127:0] iv,
        input [127:0] plaintext,
        output [127:0] ciphertext
    );
        begin
            integer timeout;
            reg [31:0] status;
            
            apb_write(12'h008, {30'd0, key_len});
            apb_write(12'h010, key[255:224]);
            apb_write(12'h014, key[223:192]);
            apb_write(12'h018, key[191:160]);
            apb_write(12'h01C, key[159:128]);
            apb_write(12'h020, key[127:96]);
            apb_write(12'h024, key[95:64]);
            apb_write(12'h028, key[63:32]);
            apb_write(12'h02C, key[31:0]);
            
            if (mode != 3'd0) begin
                apb_write(12'h030, iv[127:96]);
                apb_write(12'h034, iv[95:64]);
                apb_write(12'h038, iv[63:32]);
                apb_write(12'h03C, iv[31:0]);
            end
            
            apb_write(12'h00C, {25'd0, mode, 1'b0, encrypt});
            apb_write(12'h000, 32'h1);
            axis_send(plaintext);
            
            timeout = 0;
            while (timeout < 10000 && !status[0]) begin
                apb_read(12'h004, status);
                timeout = timeout + 1;
                @(posedge clk);
            end
            
            repeat(10) @(posedge clk);
            axis_recv(ciphertext);
        end
    endtask

    // Task: Report results
    task report_results;
        begin
            $display("\n========================================");
            $display("Test Results");
            $display("========================================");
            $display("Passed: %0d", pass_cnt);
            $display("Failed: %0d", fail_cnt);
            if (fail_cnt == 0)
                $display("[PASS] All tests passed!");
            else
                $display("[FAIL] Some tests failed!");
        end
    endtask

    // Task: Check result and report
    task check_result;
        input [127:0] actual;
        input [127:0] expected;
        input [63:0] test_name; // String
        begin
            if (actual === expected) begin
                $display("  [PASS] %s", test_name);
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("  [FAIL] %s", test_name);
                $display("    Expected: %h", expected);
                $display("    Actual:   %h", actual);
                fail_cnt = fail_cnt + 1;
            end
        end
    endtask

endmodule

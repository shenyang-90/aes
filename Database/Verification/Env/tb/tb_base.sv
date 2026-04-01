//============================================================================
// File: tb_base.sv
// Description: Base testbench class for AES verification
//============================================================================

`timescale 1ns/1ps

module tb_base;

    // Clock and Reset
    reg clk = 0;
    reg rst_n;
    
    always #5 clk = ~clk;
    
    initial begin
        rst_n = 0;
        #100 rst_n = 1;
    end

    // APB Interface
    reg         psel;
    reg         penable;
    reg  [11:0] paddr;
    reg         pwrite;
    reg  [31:0] pwdata;
    wire [31:0] prdata;
    wire        pready;
    wire        pslverr;

    // AXI4-Stream
    reg  [127:0] s_axis_tdata;
    reg          s_axis_tvalid;
    wire         s_axis_tready;
    reg          s_axis_tlast;
    
    wire [127:0] m_axis_tdata;
    wire         m_axis_tvalid;
    reg          m_axis_tready;
    wire         m_axis_tlast;

    // DUT
    aes_top dut (
        .clk(clk), .rst_n(rst_n),
        .psel(psel), .penable(penable), .paddr(paddr),
        .pwrite(pwrite), .pwdata(pwdata), .prdata(prdata),
        .pready(pready), .pslverr(pslverr),
        .s_axis_tdata(s_axis_tdata), .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready), .s_axis_tlast(s_axis_tlast),
        .m_axis_tdata(m_axis_tdata), .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready), .m_axis_tlast(m_axis_tlast),
        .int_done(), .int_error(),
        .scan_en(1'b0), .scan_clk(1'b0)
    );

    // Register Addresses
    localparam [11:0] REG_CTRL = 12'h000, REG_STATUS = 12'h004;
    localparam [11:0] REG_KEY_LEN = 12'h008, REG_MODE = 12'h00C;
    localparam [11:0] REG_KEY_0 = 12'h010, REG_KEY_1 = 12'h014;
    localparam [11:0] REG_KEY_2 = 12'h018, REG_KEY_3 = 12'h01C;
    localparam [11:0] REG_KEY_4 = 12'h020, REG_KEY_5 = 12'h024;
    localparam [11:0] REG_KEY_6 = 12'h028, REG_KEY_7 = 12'h02C;
    localparam [11:0] REG_IV_0 = 12'h030, REG_IV_1 = 12'h034;
    localparam [11:0] REG_IV_2 = 12'h038, REG_IV_3 = 12'h03C;

    // APB Tasks
    task apb_write(input [11:0] addr, input [31:0] data);
        begin
            @(posedge clk);
            psel = 1'b1; paddr = addr; pwrite = 1'b1; pwdata = data;
            @(posedge clk); penable = 1'b1;
            while (!pready) @(posedge clk);
            @(posedge clk); psel = 1'b0; penable = 1'b0;
        end
    endtask

    task apb_read(input [11:0] addr, output [31:0] data);
        begin
            @(posedge clk);
            psel = 1'b1; paddr = addr; pwrite = 1'b0;
            @(posedge clk); penable = 1'b1;
            while (!pready) @(posedge clk);
            data = prdata;
            @(posedge clk); psel = 1'b0; penable = 1'b0;
        end
    endtask

    // AXI Stream Tasks
    task axis_send(input [127:0] data);
        begin
            s_axis_tdata = data; s_axis_tvalid = 1'b1; s_axis_tlast = 1'b1;
            @(posedge clk); while (!s_axis_tready) @(posedge clk);
            s_axis_tvalid = 1'b0;
        end
    endtask

    task axis_recv(output [127:0] data);
        begin
            m_axis_tready = 1'b1;
            @(posedge clk); while (!m_axis_tvalid) @(posedge clk);
            data = m_axis_tdata; m_axis_tready = 1'b0;
        end
    endtask

    // AES Operation Task
    task aes_op(
        input [2:0] mode,       // 0=ECB, 1=CBC, 2=CTR, 3=GCM, 4=XTS, 5=CTS
        input [1:0] key_len,    // 0=128, 1=192, 2=256
        input       encrypt,    // 1=encrypt, 0=decrypt
        input [255:0] key,
        input [127:0] iv,
        input [127:0] plaintext,
        output [127:0] ciphertext
    );
        reg [31:0] ctrl_val;
        begin
            // Set key length
            apb_write(REG_KEY_LEN, {30'd0, key_len});
            
            // Set mode and direction
            ctrl_val = {25'd0, mode, 2'b00, encrypt, 1'b0};
            apb_write(REG_MODE, ctrl_val);
            
            // Write key based on key length
            apb_write(REG_KEY_0, key[255:224]);
            apb_write(REG_KEY_1, key[223:192]);
            apb_write(REG_KEY_2, key[191:160]);
            apb_write(REG_KEY_3, key[159:128]);
            // For AES-192 and AES-256
            apb_write(REG_KEY_4, key[127:96]);
            apb_write(REG_KEY_5, key[95:64]);
            // For AES-256 only
            apb_write(REG_KEY_6, key[63:32]);
            apb_write(REG_KEY_7, key[31:0]);
            
            // Wait for key registers to update (key_schedule samples on next clock)
            repeat (50) @(posedge clk);
            
            // Write IV for non-ECB modes
            if (mode != 3'd0) begin
                apb_write(REG_IV_0, iv[127:96]);
                apb_write(REG_IV_1, iv[95:64]);
                apb_write(REG_IV_2, iv[63:32]);
                apb_write(REG_IV_3, iv[31:0]);
            end
            
            // Start operation
            apb_write(REG_CTRL, 32'h0001_0001);
            
            // Send data
            axis_send(plaintext);
            
            // Receive result
            axis_recv(ciphertext);
            
            // Wait for key expansion to complete before returning
            // This prevents the next test from interfering
            repeat (300) @(posedge clk);
        end
    endtask

    // Test result tracking
    integer pass_cnt = 0;
    integer fail_cnt = 0;

    task check_result(
        input [127:0] actual,
        input [127:0] expected,
        input string test_name
    );
        begin
            if (actual === expected) begin
                $display("[PASS] %s", test_name);
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("[FAIL] %s", test_name);
                $display("  Expected: %h", expected);
                $display("  Actual:   %h", actual);
                fail_cnt = fail_cnt + 1;
            end
        end
    endtask

    // Report results
    task report_results;
        begin
            $display("\n========================================");
            $display("Test Results: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
            $display("========================================");
        end
    endtask

    // Initialize
    initial begin
        psel = 0; penable = 0; pwrite = 0; paddr = 0; pwdata = 0;
        s_axis_tdata = 0; s_axis_tvalid = 0; s_axis_tlast = 0;
        m_axis_tready = 0;
    end

endmodule

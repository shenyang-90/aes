`include "../../Env/tb/tb_base.sv"
module tc_demo_new;
    tb_base tb();
    initial begin
        $display("[DEMO] New testcase for coverage merge demo");
        tb.init();
        tb.reset_dut();
        tb.apb_write(tb.REG_CTRL, 32'h1);
        #100;
        $display("[DEMO] Coverage demo complete");
        $finish;
    end
endmodule

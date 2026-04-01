// Testcase: tc_safety_fsm_timeout
// Description: Verify FSM timeout detection for stuck states
// Coverage: SM-041~048
// Author: Verification Agent
// Date: 2026-04-01

`timescale 1ns/1ps

module tc_safety_fsm_timeout;
    
    // Testbench base instance
    tb_base tb();
    
    // Test result tracking
    int pass_count = 0;
    int fail_count = 0;
    
    // FSM state encoding
    localparam logic [3:0] IDLE        = 4'd0;
    localparam logic [3:0] KEY_SCHEDULE= 4'd1;
    localparam logic [3:0] KEY_WAIT    = 4'd2;
    localparam logic [3:0] LOAD_DATA   = 4'd3;
    localparam logic [3:0] LOAD_DATA_WAIT = 4'd4;
    localparam logic [3:0] ROUND_OP    = 4'd5;
    localparam logic [3:0] ROUND_WAIT  = 4'd6;
    localparam logic [3:0] FINAL_ROUND = 4'd7;
    localparam logic [3:0] OUTPUT_DATA = 4'd8;
    localparam logic [3:0] DONE        = 4'd9;
    localparam logic [3:0] ERROR       = 4'd10;
    
    // Task: Force FSM state
    task automatic force_fsm_state(
        input logic [3:0] state_value,
        input string state_name
    );
        $display("[INFO] Forcing FSM state to %s (4'd%0d)", state_name, state_value);
        tb.force_signal("aes_controller.state", state_value);
    endtask
    
    // Task: Check timeout detection
    task automatic check_timeout_detected(
        input string test_id,
        input int timeout_cycles = 100
    );
        logic timeout_detected;
        logic int_status_timeout;
        int cycle_count;
        
        cycle_count = 0;
        timeout_detected = 1'b0;
        int_status_timeout = 1'b0;
        
        while (!timeout_detected && cycle_count < timeout_cycles) begin
            @(posedge tb.clk);
            // Check INT_STATUS[3] for timeout interrupt
            int_status_timeout = tb.dut.aes_top.int_status_reg[3];
            cycle_count++;
        end
        
        if (int_status_timeout) begin
            $display("[PASS] %s: Timeout detected after %0d cycles", test_id, cycle_count);
            pass_count++;
        end else begin
            $display("[FAIL] %s: Timeout NOT detected within %0d cycles", test_id, timeout_cycles);
            fail_count++;
        end
    endtask
    
    // Task: Check FSM recovery to IDLE
    task automatic check_fsm_recovery(
        input string test_id,
        input int check_cycles = 10
    );
        logic [3:0] current_state;
        int cycle_count;
        
        cycle_count = 0;
        
        while (cycle_count < check_cycles) begin
            @(posedge tb.clk);
            current_state = tb.dut.aes_controller.state;
            if (current_state === IDLE) begin
                $display("[PASS] %s: FSM recovered to IDLE after %0d cycles", test_id, cycle_count);
                pass_count++;
                return;
            end
            cycle_count++;
        end
        
        $display("[FAIL] %s: FSM NOT recovered to IDLE within %0d cycles (state=4'd%0d)", 
                 test_id, check_cycles, current_state);
        fail_count++;
    endtask
    
    // Task: Release FSM force
    task automatic release_fsm();
        tb.release_signal("aes_controller.state");
        $display("[INFO] Released FSM state force");
    endtask
    
    // Main test sequence
    initial begin
        $display("========================================");
        $display("TC_SAFETY_FSM_TIMEOUT: Starting test suite");
        $display("Coverage: SM-041~048");
        $display("========================================");
        
        // Initialize
        tb.init();
        
        // Wait for reset release
        @(posedge tb.clk);
        wait(tb.rst_n === 1'b1);
        @(posedge tb.clk);
        
        // === FSM timeout tests (SM-041~045) ===
        
        // Test SM-041: FSM stuck at IDLE
        $display("\n--- Test SM-041: FSM stuck at IDLE ---");
        force_fsm_state(IDLE, "IDLE");
        check_timeout_detected("SM-041");
        release_fsm();
        tb.reset_dut();
        
        // Test SM-042: FSM stuck at KEY_WAIT
        $display("\n--- Test SM-042: FSM stuck at KEY_WAIT ---");
        tb.start_operation();
        force_fsm_state(KEY_WAIT, "KEY_WAIT");
        check_timeout_detected("SM-042");
        release_fsm();
        tb.reset_dut();
        
        // Test SM-043: FSM stuck at LOAD_DATA
        $display("\n--- Test SM-043: FSM stuck at LOAD_DATA ---");
        tb.start_operation();
        force_fsm_state(LOAD_DATA, "LOAD_DATA");
        check_timeout_detected("SM-043");
        release_fsm();
        tb.reset_dut();
        
        // Test SM-044: FSM stuck at ROUND_OP
        $display("\n--- Test SM-044: FSM stuck at ROUND_OP ---");
        tb.start_operation();
        force_fsm_state(ROUND_OP, "ROUND_OP");
        check_timeout_detected("SM-044");
        release_fsm();
        tb.reset_dut();
        
        // Test SM-045: FSM stuck at OUTPUT_DATA
        $display("\n--- Test SM-045: FSM stuck at OUTPUT_DATA ---");
        tb.start_operation();
        force_fsm_state(OUTPUT_DATA, "OUTPUT_DATA");
        check_timeout_detected("SM-045");
        release_fsm();
        tb.reset_dut();
        
        // === FSM invalid state tests (SM-046~048) ===
        
        // Test SM-046: FSM invalid state 4'd11
        $display("\n--- Test SM-046: FSM invalid state 4'd11 ---");
        force_fsm_state(4'd11, "INVALID_11");
        check_fsm_recovery("SM-046");
        release_fsm();
        tb.reset_dut();
        
        // Test SM-047: FSM invalid state 4'd12
        $display("\n--- Test SM-047: FSM invalid state 4'd12 ---");
        force_fsm_state(4'd12, "INVALID_12");
        check_fsm_recovery("SM-047");
        release_fsm();
        tb.reset_dut();
        
        // Test SM-048: FSM invalid state 4'd15
        $display("\n--- Test SM-048: FSM invalid state 4'd15 ---");
        force_fsm_state(4'd15, "INVALID_15");
        check_fsm_recovery("SM-048");
        release_fsm();
        tb.reset_dut();
        
        // Test summary
        $display("\n========================================");
        $display("TC_SAFETY_FSM_TIMEOUT: Test Summary");
        $display("========================================");
        $display("Total Tests: %0d", pass_count + fail_count);
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);
        
        if (fail_count == 0) begin
            $display("[TEST PASSED] All FSM timeout tests passed!");
        end else begin
            $display("[TEST FAILED] %0d tests failed!", fail_count);
        end
        
        $display("========================================\n");
        $finish;
    end
    
endmodule

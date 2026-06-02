`timescale 1ns/1ps

module counter16_tb;

    logic        clk;
    logic        rst_n;
    logic        ld_cnt;
    logic        count_enb;
    logic        updn_cnt;
    logic [15:0] data_in;
    logic [15:0] data_out;

    integer errors;

    counter16 dut (
        .clk(clk),
        .rst_n(rst_n),
        .ld_cnt(ld_cnt),
        .count_enb(count_enb),
        .updn_cnt(updn_cnt),
        .data_in(data_in),
        .data_out(data_out)
    );

    bind counter16 counter16_sva dutbound (
        .clk(clk),
        .rst_n(rst_n),
        .ld_cnt(ld_cnt),
        .count_enb(count_enb),
        .updn_cnt(updn_cnt),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, counter16_tb);
    end

    task check;
        input [15:0] expected;
        input [255:0] test_name;
        begin
            if (data_out !== expected) begin
                $display("[FAIL] %0s | time=%0t | expected=%h got=%h",
                         test_name, $time, expected, data_out);
                errors = errors + 1;
            end
            else begin
                $display("[PASS] %0s | time=%0t | data_out=%h",
                         test_name, $time, data_out);
            end
        end
    endtask

    initial begin
        errors = 0;

        $display("========================================");
        $display(" Starting counter16 testbench");
        $display("========================================");

        rst_n      = 1'b1;
        ld_cnt     = 1'b1;
        count_enb  = 1'b0;
        updn_cnt   = 1'b1;
        data_in    = 16'h0000;

        // Test 1: Async reset
        $display("\nTest 1: Asynchronous reset");
        #2;
        rst_n = 1'b0;
        #1;
        check(16'h0000, "Async reset clears output");

        @(negedge clk);
        rst_n = 1'b1;

        // Test 2: Load
        $display("\nTest 2: Active-low load");
        @(negedge clk);
        data_in = 16'h0010;
        ld_cnt  = 1'b0;
        count_enb = 1'b0;

        @(posedge clk);
        #1;
        check(16'h0010, "Load 0x0010");

        @(negedge clk);
        ld_cnt = 1'b1;

        // Test 3: Count up
        $display("\nTest 3: Count up");
        @(negedge clk);
        count_enb = 1'b1;
        updn_cnt  = 1'b1;

        @(posedge clk); #1; check(16'h0011, "Count up cycle 1");
        @(posedge clk); #1; check(16'h0012, "Count up cycle 2");
        @(posedge clk); #1; check(16'h0013, "Count up cycle 3");
        @(posedge clk); #1; check(16'h0014, "Count up cycle 4");

        // Test 4: Count down
        $display("\nTest 4: Count down");
        @(negedge clk);
        updn_cnt = 1'b0;

        @(posedge clk); #1; check(16'h0013, "Count down cycle 1");
        @(posedge clk); #1; check(16'h0012, "Count down cycle 2");
        @(posedge clk); #1; check(16'h0011, "Count down cycle 3");

        // Test 5: Hold
        $display("\nTest 5: Hold when count_enb=0");
        @(negedge clk);
        count_enb = 1'b0;

        @(posedge clk);
        #1;
        check(16'h0011, "Hold value stable");

        // Test 6: Load priority
        $display("\nTest 6: Load priority over count");
        @(negedge clk);
        count_enb = 1'b1;
        updn_cnt  = 1'b1;
        data_in   = 16'h00AA;
        ld_cnt    = 1'b0;

        @(posedge clk);
        #1;
        check(16'h00AA, "Load has priority over count");

        @(negedge clk);
        ld_cnt = 1'b1;

        // Test 7: Count after load
        $display("\nTest 7: Count up after load");
        @(posedge clk); #1; check(16'h00AB, "Count up after load cycle 1");
        @(posedge clk); #1; check(16'h00AC, "Count up after load cycle 2");

        // Test 8: Async reset during operation
        $display("\nTest 8: Async reset during operation");
        #2;
        rst_n = 1'b0;
        #1;
        check(16'h0000, "Async reset during counting");

        @(negedge clk);
        count_enb = 1'b0;
        ld_cnt    = 1'b1;
        rst_n     = 1'b1;

        $display("\n========================================");
        if (errors == 0)
            $display(" ALL TESTS PASSED");
        else
            $display(" TESTBENCH FAILED: %0d error(s)", errors);
        $display("========================================");

        #1;
        $finish;
    end

endmodule
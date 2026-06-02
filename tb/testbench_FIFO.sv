`timescale 1ns/1ps

module fifo_sync_tb;

    parameter WIDTH      = 16;
    parameter DEPTH      = 16;
    parameter ADDR_WIDTH = 4;

    logic                 clk;
    logic                 rst;
    logic                 fifo_write;
    logic                 fifo_read;
    logic [WIDTH-1:0]     fifo_data_in;
    logic [WIDTH-1:0]     fifo_data_out;
    logic                 fifo_full;
    logic                 fifo_empty;

    integer errors;
    integer i;

    // DUT
    fifo_sync #(
        .WIDTH(WIDTH),
        .DEPTH(DEPTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .fifo_write(fifo_write),
        .fifo_read(fifo_read),
        .fifo_data_in(fifo_data_in),
        .fifo_data_out(fifo_data_out),
        .fifo_full(fifo_full),
        .fifo_empty(fifo_empty)
    );

    // Bind SVA properties
    bind fifo_sync fifo_sva fifo_bound (
        .clk(clk),
        .rst(rst),
        .fifo_write(fifo_write),
        .fifo_read(fifo_read),
        .fifo_full(fifo_full),
        .fifo_empty(fifo_empty),
        .wr_ptr(wr_ptr),
        .rd_ptr(rd_ptr),
        .cnt(cnt)
    );

    // Clock generation: 10 ns period
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // Waveform dump
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, fifo_sync_tb);
    end

    // Check task
    task check_equal;
        input [WIDTH-1:0] actual;
        input [WIDTH-1:0] expected;
        input [255:0] test_name;
        begin
            if (actual !== expected) begin
                $display("[FAIL] %0s | time=%0t | expected=%h got=%h",
                         test_name, $time, expected, actual);
                errors = errors + 1;
            end
            else begin
                $display("[PASS] %0s | time=%0t | value=%h",
                         test_name, $time, actual);
            end
        end
    endtask

    initial begin
        errors       = 0;
        rst          = 1'b1;
        fifo_write   = 1'b0;
        fifo_read    = 1'b0;
        fifo_data_in = '0;

        $display("======================================");
        $display("Starting synchronous FIFO testbench");
        $display("======================================");

        // Test 1: asynchronous active-low reset
        $display("\nTest 1: Reset");

        #2;
        rst = 1'b0;
        #1;

        check_equal({15'b0, fifo_empty}, 16'h0001, "FIFO empty after reset");
        check_equal({15'b0, fifo_full},  16'h0000, "FIFO not full after reset");

        @(negedge clk);
        rst = 1'b1;

        // Test 2: write one item
        $display("\nTest 2: Single write");

        @(negedge clk);
        fifo_write   = 1'b1;
        fifo_read    = 1'b0;
        fifo_data_in = 16'h00A1;

        @(posedge clk);
        #1;
        fifo_write = 1'b0;

        check_equal({15'b0, fifo_empty}, 16'h0000, "FIFO not empty after one write");
        check_equal({15'b0, fifo_full},  16'h0000, "FIFO not full after one write");

        // Test 3: write second item
        $display("\nTest 3: Second write");

        @(negedge clk);
        fifo_write   = 1'b1;
        fifo_read    = 1'b0;
        fifo_data_in = 16'h00B2;

        @(posedge clk);
        #1;
        fifo_write = 1'b0;

        // Test 4: read first item
        $display("\nTest 4: Read first item");

        @(negedge clk);
        fifo_write = 1'b0;
        fifo_read  = 1'b1;

        @(posedge clk);
        #1;
        fifo_read = 1'b0;

        check_equal(fifo_data_out, 16'h00A1, "Read returns first written item");

        // Test 5: read second item
        $display("\nTest 5: Read second item");

        @(negedge clk);
        fifo_write = 1'b0;
        fifo_read  = 1'b1;

        @(posedge clk);
        #1;
        fifo_read = 1'b0;

        check_equal(fifo_data_out, 16'h00B2, "Read returns second written item");
        check_equal({15'b0, fifo_empty}, 16'h0001, "FIFO empty after reading all items");

        // Test 6: read when empty
        $display("\nTest 6: Read when empty");

        @(negedge clk);
        fifo_write = 1'b0;
        fifo_read  = 1'b1;

        @(posedge clk);
        #1;
        fifo_read = 1'b0;

        check_equal({15'b0, fifo_empty}, 16'h0001, "FIFO remains empty on invalid read");
        check_equal({15'b0, fifo_full},  16'h0000, "FIFO remains not full on invalid read");

        // Test 7: fill FIFO completely
        $display("\nTest 7: Fill FIFO");

        for (i = 0; i < DEPTH; i = i + 1) begin
            @(negedge clk);
            fifo_write   = 1'b1;
            fifo_read    = 1'b0;
            fifo_data_in = i[WIDTH-1:0];

            @(posedge clk);
            #1;
        end

        @(negedge clk);
        fifo_write = 1'b0;

        #1;
        check_equal({15'b0, fifo_full},  16'h0001, "FIFO full after DEPTH writes");
        check_equal({15'b0, fifo_empty}, 16'h0000, "FIFO not empty when full");

        // Test 8: write when full
        $display("\nTest 8: Write when full");

        @(negedge clk);
        fifo_write   = 1'b1;
        fifo_read    = 1'b0;
        fifo_data_in = 16'hFFFF;

        @(posedge clk);
        #1;
        fifo_write = 1'b0;

        check_equal({15'b0, fifo_full}, 16'h0001, "FIFO remains full on invalid write");

        // Test 9: read all items back
        $display("\nTest 9: Read all items back");

        for (i = 0; i < DEPTH; i = i + 1) begin
            @(negedge clk);
            fifo_write = 1'b0;
            fifo_read  = 1'b1;

            @(posedge clk);
            #1;
            check_equal(fifo_data_out, i[WIDTH-1:0], "FIFO order check");
        end

        @(negedge clk);
        fifo_read = 1'b0;

        #1;
        check_equal({15'b0, fifo_empty}, 16'h0001, "FIFO empty after reading DEPTH items");
        check_equal({15'b0, fifo_full},  16'h0000, "FIFO not full after all reads");

        // Test 10: simultaneous read and write
        $display("\nTest 10: Simultaneous read and write");

        // First write one item
        @(negedge clk);
        fifo_write   = 1'b1;
        fifo_read    = 1'b0;
        fifo_data_in = 16'h1111;

        @(posedge clk);
        #1;

        @(negedge clk);
        fifo_write = 1'b0;

        // Simultaneous read and write
        @(negedge clk);
        fifo_write   = 1'b1;
        fifo_read    = 1'b1;
        fifo_data_in = 16'h2222;

        @(posedge clk);
        #1;

        @(negedge clk);
        fifo_write = 1'b0;
        fifo_read  = 1'b0;

        check_equal(fifo_data_out, 16'h1111, "Read old data during simultaneous read/write");
        check_equal({15'b0, fifo_empty}, 16'h0000, "FIFO still contains one item after simultaneous op");

        // Read remaining item
        @(negedge clk);
        fifo_write = 1'b0;
        fifo_read  = 1'b1;

        @(posedge clk);
        #1;
        fifo_read = 1'b0;

        check_equal(fifo_data_out, 16'h2222, "Remaining item after simultaneous read/write");

        // Final result
        $display("\n======================================");
        if (errors == 0)
            $display("ALL FIFO TESTS PASSED");
        else
            $display("FIFO TESTBENCH FAILED WITH %0d ERROR(S)", errors);
        $display("======================================");

        #10;
        $finish;
    end

endmodule
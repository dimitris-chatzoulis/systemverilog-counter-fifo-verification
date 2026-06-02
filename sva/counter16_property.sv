module counter16_sva (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        ld_cnt,
    input  logic        count_enb,
    input  logic        updn_cnt,
    input  logic [15:0] data_out
);

    // 1. When reset is asserted, output must be zero
    property p_reset_clears_output;
        @(posedge clk)
        (!rst_n) |-> (data_out == 16'h0000);
    endproperty

    ap_reset_clears_output: assert property (p_reset_clears_output)
        $display("[ASSERTION PASS] reset asserted -> data_out = 0 | time=%0t data_out=%h",
                 $time, data_out);
    else
        $error("[ASSERTION FAIL] reset asserted but data_out != 0 | time=%0t data_out=%h",
               $time, data_out);


    // 2. When load is inactive and count_enb is not enabled,
    // the counter output must not change
    property p_hold_when_not_enabled;
        @(posedge clk) disable iff (!rst_n)
        ($past(ld_cnt) && !$past(count_enb)) |->
        (data_out == $past(data_out));
    endproperty

    ap_hold_when_not_enabled: assert property (p_hold_when_not_enabled)
        $display("[ASSERTION PASS] hold condition satisfied | time=%0t prev=%h curr=%h",
                 $time, $past(data_out), data_out);
    else
        $error("[ASSERTION FAIL] hold condition violated | time=%0t prev=%h curr=%h",
               $time, $past(data_out), data_out);


    // 3a. When load is inactive, count_enb is enabled, and updn_cnt is high,
    // the counter must increment
    property p_increment_when_enabled;
        @(posedge clk) disable iff (!rst_n)
        ($past(ld_cnt) && $past(count_enb) && $past(updn_cnt)) |->
        (data_out == $past(data_out) + 16'h0001);
    endproperty

    ap_increment_when_enabled: assert property (p_increment_when_enabled)
        $display("[ASSERTION PASS] increment condition satisfied | time=%0t prev=%h curr=%h",
                 $time, $past(data_out), data_out);
    else
        $error("[ASSERTION FAIL] increment condition violated | time=%0t prev=%h curr=%h",
               $time, $past(data_out), data_out);


    // 3b. When load is inactive, count_enb is enabled, and updn_cnt is low,
    // the counter must decrement
    property p_decrement_when_enabled;
        @(posedge clk) disable iff (!rst_n)
        ($past(ld_cnt) && $past(count_enb) && !$past(updn_cnt)) |->
        (data_out == $past(data_out) - 16'h0001);
    endproperty

    ap_decrement_when_enabled: assert property (p_decrement_when_enabled)
        $display("[ASSERTION PASS] decrement condition satisfied | time=%0t prev=%h curr=%h",
                 $time, $past(data_out), data_out);
    else
        $error("[ASSERTION FAIL] decrement condition violated | time=%0t prev=%h curr=%h",
               $time, $past(data_out), data_out);

endmodule
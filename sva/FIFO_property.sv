module fifo_sva (
    input logic        clk,
    input logic        rst,
    input logic        fifo_write,
    input logic        fifo_read,
    input logic        fifo_full,
    input logic        fifo_empty,
    input logic [3:0]  wr_ptr,
    input logic [3:0]  rd_ptr,
  input logic [4:0]  cnt
);

    // 1. On reset: wr_ptr = 0, rd_ptr = 0, fifo_empty = 1, fifo_full = 0, cnt = 0
    property p_reset_state;
      @(posedge clk)
        (!rst) |-> (wr_ptr == 4'd0 &&
                    rd_ptr == 4'd0 &&
                    fifo_empty == 1'b1 &&
                    fifo_full  == 1'b0 &&
                    cnt == 5'd0);
    endproperty

    ap_reset_state: assert property (p_reset_state)
      $display("[ASSERT 1 PASS] reset state correct | time=%0t", $time);
    else
      $error("[ASSERT FAIL] reset state incorrect | time=%0t wr_ptr=%0d rd_ptr=%0d cnt=%0d empty=%b full=%b",
               $time, wr_ptr, rd_ptr, cnt, fifo_empty, fifo_full);

    // 2. fifo_empty must be asserted whenever cnt == 0
    //    disable when reset is active
    property p_empty_flag;
        @(posedge clk) disable iff (!rst)
        (cnt == 5'd0) |-> (fifo_empty == 1'b1);
    endproperty

    ap_empty_flag: assert property (p_empty_flag)
      $display("[ASSERT 2 PASS] fifo_empty asserted when cnt==0 | time=%0t cnt=%0d empty=%b",
                 $time, cnt, fifo_empty);
    else
      $error("[ASSERT FAIL] fifo_empty not asserted when cnt==0 | time=%0t cnt=%0d empty=%b",
               $time, cnt, fifo_empty);

    // 3. fifo_full must be asserted whenever cnt >= 16
    //    disable when reset is active
    property p_full_flag;
        @(posedge clk) disable iff (!rst)
        (cnt >= 5'd16) |-> (fifo_full == 1'b1);
    endproperty

    ap_full_flag: assert property (p_full_flag)
      $display("[ASSERT 3 PASS] fifo_full asserted when cnt>=16 | time=%0t cnt=%0d full=%b",
                 $time, cnt, fifo_full);
    else
      $error("[ASSERT FAIL] fifo_full not asserted when cnt>=16 | time=%0t cnt=%0d full=%b",
               $time, cnt, fifo_full);

    // 4. If FIFO is full and there is write request only,
    //    then wr_ptr must not change
    property p_wr_ptr_holds_when_full;
        @(posedge clk) disable iff (!rst)
      (fifo_full && fifo_write && !fifo_read) |=> (wr_ptr == $past(wr_ptr));
    endproperty

    ap_wr_ptr_holds_when_full: assert property (p_wr_ptr_holds_when_full)
      $display("[ASSERT 4 PASS] wr_ptr held when full + write only | time=%0t prev=%0d curr=%0d",
                 $time, $past(wr_ptr), wr_ptr);
    else
      $error("[ASSERT FAIL] wr_ptr changed when full + write only | time=%0t prev=%0d curr=%0d",
               $time, $past(wr_ptr), wr_ptr);

    // 5. If FIFO is empty and there is read request only,
    //    then rd_ptr must not change
    property p_rd_ptr_holds_when_empty;
        @(posedge clk) disable iff (!rst)
      (fifo_empty && fifo_read && !fifo_write) |=> (rd_ptr == $past(rd_ptr));
    endproperty

    ap_rd_ptr_holds_when_empty: assert property (p_rd_ptr_holds_when_empty)
      $display("[ASSERT 5 PASS] rd_ptr held when empty + read only | time=%0t prev=%0d curr=%0d",
                 $time, $past(rd_ptr), rd_ptr);
    else
      $error("[ASSERT FAIL] rd_ptr changed when empty + read only | time=%0t prev=%0d curr=%0d",
               $time, $past(rd_ptr), rd_ptr);

endmodule
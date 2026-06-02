//`include "counter16_property.sv"

module counter16 (
    input  logic        clk,
    input  logic        rst_n,       // asynchronous active-low reset
    input  logic        ld_cnt,      // active-low load
    input  logic        count_enb,   // active-high count enable
    input  logic        updn_cnt,    // 1: up, 0: down
    input  logic [15:0] data_in,     // 16-bit input data
    output logic [15:0] data_out     // 16-bit counter output
);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        data_out <= 16'b0;
    else if (!ld_cnt)               // load has highest priority
        data_out <= data_in;
    else if (count_enb) begin
        if (updn_cnt)
            data_out <= data_out + 16'b1;
        else
            data_out <= data_out - 16'b1;
    end
    else
        data_out <= data_out;       // hold value
end

endmodule
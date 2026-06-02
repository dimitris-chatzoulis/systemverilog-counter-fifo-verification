//`include "FIFO_property.sv"


module fifo_sync #(
    parameter WIDTH = 16, // size of each word
    parameter DEPTH = 16, // words stored
    parameter ADDR_WIDTH = 4
)(
    input  logic                 clk,
    input  logic                 rst,           // asynchronous active-low reset
    input  logic                 fifo_write,
    input  logic                 fifo_read,
    input  logic [WIDTH-1:0]     fifo_data_in,
    output logic [WIDTH-1:0]     fifo_data_out,
    output logic                 fifo_full,
    output logic                 fifo_empty
);

    logic [WIDTH-1:0] mem [0:DEPTH-1];
    logic [ADDR_WIDTH-1:0] wr_ptr;
    logic [ADDR_WIDTH-1:0] rd_ptr;
    logic [ADDR_WIDTH:0]   cnt;

    assign fifo_full  = (cnt == DEPTH);
    assign fifo_empty = (cnt == 0);

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            wr_ptr       <= 0;
            rd_ptr       <= 0;
            cnt          <= 0;
            fifo_data_out <= 0;
        end
        else begin
            case ({fifo_write && !fifo_full, fifo_read && !fifo_empty})

                2'b10: begin
                    mem[wr_ptr] <= fifo_data_in;
                    wr_ptr <= wr_ptr + 1'b1;
                    cnt    <= cnt + 1'b1;
                end

                2'b01: begin
                    fifo_data_out <= mem[rd_ptr];
                    rd_ptr <= rd_ptr + 1'b1;
                    cnt    <= cnt - 1'b1;
                end

                2'b11: begin
                    mem[wr_ptr] <= fifo_data_in;
                    fifo_data_out <= mem[rd_ptr];
                    wr_ptr <= wr_ptr + 1'b1;
                    rd_ptr <= rd_ptr + 1'b1;
                    cnt    <= cnt;
                end

                default: begin
                    wr_ptr <= wr_ptr;
                    rd_ptr <= rd_ptr;
                    cnt    <= cnt;
                    fifo_data_out <= fifo_data_out;
                end
            endcase
        end
    end

endmodule
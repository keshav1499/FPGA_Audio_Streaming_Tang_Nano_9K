/*module fifo_buffer #(parameter DEPTH = 64) (
    input clk,
    input rst,
    input [23:0] in_data,
    input wr_en,
    input rd_en,
    output reg [23:0] out_data,
    output full,
    output empty
);

reg [23:0] buffer [0:DEPTH-1];
reg [$clog2(DEPTH):0] wr_ptr = 0, rd_ptr = 0;

assign full  = (wr_ptr - rd_ptr == DEPTH);
assign empty = (wr_ptr == rd_ptr);

always @(posedge clk) begin
    if (wr_en && !full) begin
        buffer[wr_ptr[($clog2(DEPTH)-1):0]] <= in_data;
        wr_ptr <= wr_ptr + 1;
    end
    if (rd_en && !empty) begin
        out_data <= buffer[rd_ptr[($clog2(DEPTH)-1):0]];
        rd_ptr <= rd_ptr + 1;
    end
end

endmodule*/
module FIFO (
    input wire clk,
    input wire [15:0] data_in,
    input wire byte_ready,
    input wire sample_tick,
    output reg [15:0] mono_sample
);

parameter DEPTH = 256;
reg [15:0] fifo [0:DEPTH-1];
reg [7:0] wr_ptr = 0;
reg [7:0] rd_ptr = 0;
reg [8:0] count = 0;

always @(posedge clk) begin
    if (byte_ready && count < DEPTH) begin
        fifo[wr_ptr] <= data_in;
        wr_ptr <= wr_ptr + 1;
        count <= count + 1;
    end

    if (sample_tick && count > 0) begin
        mono_sample <= fifo[rd_ptr];
        rd_ptr <= rd_ptr + 1;
        count <= count - 1;
    end
end

endmodule
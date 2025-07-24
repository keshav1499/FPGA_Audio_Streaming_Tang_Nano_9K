module FIFO (
    input  wire        clk,
    input  wire [15:0] data_in,
    input  wire        byte_ready,
    input  wire        sample_tick,
    output reg  [15:0] mono_sample
);

    // === Parameters ===
    parameter DEPTH = 256;

    // === Internal Signals ===
    reg [15:0] fifo   [0:DEPTH-1]; // FIFO buffer
    reg [7:0]  wr_ptr = 0;         // Write pointer
    reg [7:0]  rd_ptr = 0;         // Read pointer
    reg [8:0]  count  = 0;         // Element count

    // === FIFO Logic ===
    always @(posedge clk) begin
        // Write to FIFO when byte is ready and there's space
        if (byte_ready && count < DEPTH) begin
            fifo[wr_ptr] <= data_in;
            wr_ptr       <= wr_ptr + 1;
            count        <= count + 1;
        end

        // Read from FIFO when sample tick arrives and data is available
        if (sample_tick && count > 0) begin
            mono_sample  <= fifo[rd_ptr];
            rd_ptr       <= rd_ptr + 1;
            count        <= count - 1;
        end
    end

endmodule
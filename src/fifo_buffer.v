module FIFO (
    input  wire        clk,           // Clock signal
    input  wire [15:0] data_in,       // 16-bit input data to be written into the FIFO
    input  wire        byte_ready,    // Signal indicating new data is ready to be written
    input  wire        sample_tick,   // Signal indicating it's time to read a sample
    output reg  [15:0] mono_sample    // 16-bit output data read from the FIFO
);

    // === Parameters ===
    parameter DEPTH = 256;            // Depth of the FIFO buffer (number of entries)

    // === Internal Signals ===
    reg [15:0] fifo   [0:DEPTH-1];    // Actual FIFO memory buffer (256 entries of 16-bit width)
    reg [7:0]  wr_ptr = 0;            // Write pointer (8-bit wide, indexing up to 256 locations)
    reg [7:0]  rd_ptr = 0;            // Read pointer (8-bit wide, indexing up to 256 locations)
    reg [8:0]  count  = 0;            // Counter to track the number of elements in the FIFO (0 to 256)

    // === FIFO Logic ===
    always @(posedge clk) begin
        // === Write Operation ===
        // If a new byte is ready and FIFO is not full, write it into the FIFO
        if (byte_ready && count < DEPTH) begin
            fifo[wr_ptr] <= data_in; // Store input data at the current write pointer location
            wr_ptr       <= wr_ptr + 1; // Increment write pointer (wrap-around handled by implicit overflow)
            count        <= count + 1;  // Increase count since one element has been added
        end

        // === Read Operation ===
        // If it's time to sample and FIFO has data, read from it
        if (sample_tick && count > 0) begin
            mono_sample  <= fifo[rd_ptr]; // Output the data at the current read pointer location
            rd_ptr       <= rd_ptr + 1;   // Increment read pointer
            count        <= count - 1;    // Decrease count since one element has been read
        end
    end

endmodule
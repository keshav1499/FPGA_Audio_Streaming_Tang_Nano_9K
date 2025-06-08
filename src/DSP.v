module DSP (
    input wire clk,               // 27 MHz
    input wire [7:0] data_in,
    input wire byte_ready,
    input wire sample_tick,       // ~45600 Hz pulse from I2S
    output reg [7:0] mono_sample
);

// FIFO parameters
parameter DEPTH = 256;
reg [7:0] fifo [0:DEPTH-1];
reg [7:0] wr_ptr = 0;
reg [7:0] rd_ptr = 0;
reg [8:0] count = 0;  // Range: 0 to 256

always @(posedge clk) begin
    // Default: no read/write
    mono_sample <= mono_sample;

    // === UART Write ===
    if (byte_ready && count < DEPTH) begin
        fifo[wr_ptr] <= data_in;
        wr_ptr <= wr_ptr + 1;
        count <= count + 1;
    end

    // === I2S Read ===
    if (sample_tick && count > 0) begin
        mono_sample <= fifo[rd_ptr];
        rd_ptr <= rd_ptr + 1;
        count <= count - 1;
    end
end

endmodule

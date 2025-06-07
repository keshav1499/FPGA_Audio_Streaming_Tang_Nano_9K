module DSP (
    input wire clk, 
    input wire [7:0] data_in, 
    input wire byte_ready,
    output reg [23:0] mono_sample
);

// --- LFSR for 16-bit dither noise ---
reg [15:0] lfsr = 16'hACE1;

// --- Noise shaping ---
reg [15:0] error_feedback = 16'd0;
wire [15:0] shaped_noise;
assign shaped_noise = lfsr - error_feedback;

// --- FIR filter history ---
reg [7:0] x_n1 = 0;
reg [7:0] x_n2 = 0;

// --- FIR output (use wider bit width to prevent overflow) ---
wire [9:0] filtered_sample;
assign filtered_sample = (data_in + (x_n1 << 1) + x_n2) >> 2;

always @(posedge clk) begin
    // Update LFSR
    lfsr <= {lfsr[14:0], lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10]};

    if (byte_ready) begin
        // Send 24-bit sample: filtered 8-bit + dither
        mono_sample <= {filtered_sample[7:0], shaped_noise};

        // Update noise shaping
        error_feedback <= shaped_noise;

        // Update FIR shift registers
        x_n2 <= x_n1;
        x_n1 <= data_in;
    end
end

endmodule
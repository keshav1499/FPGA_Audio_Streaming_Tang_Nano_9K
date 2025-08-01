module driver (
    input wire clk,                 // Input clock (e.g., 27 MHz)
    input wire btn1,               // Mute toggle button input
    output wire bck,               // Bit clock output (1.4994 MHz for I2S)
    output reg ws = 0,             // Word Select (Left/Right channel indicator)
    output reg data = 0,           // I2S serial data output
    output wire mute,              // Current mute state
    output wire sample_tick,       // Pulse to indicate when a full stereo frame is done
    input wire [15:0] mono_sample  // 16-bit mono audio input
);

localparam RESBIT = 5'd16;             // Bit resolution (16 bits)
localparam TOTAL_BITS = RESBIT * 2 + 2; // Total bits per stereo frame: 16 (L) + 16 (R) + 2 wait bits = 34
localparam COUNTMAX = TOTAL_BITS - 1;   // Max bit count value: 33

reg [5:0] bit_count = 0;                // Bit counter (0 to 33)

// Assert sample_tick at the end of every stereo frame (just before counter resets)
assign sample_tick = (bit_count == COUNTMAX);

// === Mute Button Logic ===
reg btn1_sync_0 = 1, btn1_sync_1 = 1;   // Synchronize btn1 to system clock to avoid metastability
reg btn1_prev = 1;                      // Previous button state (for edge detection)
reg mute_state = 0;                     // Mute state (0 = not muted, 1 = muted)
assign mute = mute_state;              // Output mute status

// Synchronize btn1 to system clock domain
always @(posedge clk) begin
    btn1_sync_0 <= btn1;
    btn1_sync_1 <= btn1_sync_0;
    btn1_prev   <= btn1_sync_1;
end

// Detect falling edge (button press)
wire btn1_pressed = (btn1_prev == 1) && (btn1_sync_1 == 0);

// Toggle mute_state on button press
always @(posedge clk) begin
    if (btn1_pressed)
        mute_state <= ~mute_state;
end

// === Clock Generation ===
// Instantiate Gowin rPLL to convert clk (e.g., 27 MHz) to bck (1.4994 MHz)
Gowin_rPLL CLK_27_TO_1499K (
    .clkoutd(bck),
    .clkin(clk)
);

// === Sample Latching ===
reg [15:0] sample = 16'd0; // Latched audio sample

// On the first bit of the frame, latch the mono sample (or zero if muted)
always @(posedge bck) begin
    if (bit_count == 0)
        sample <= mute_state ? 16'd0 : (mono_sample); // Replace with silence if muted
end

// === Bit Counter ===
// Count from 0 to 33 (one full stereo frame: L+R+waits)
always @(posedge bck) begin
    if (bit_count == COUNTMAX)
        bit_count <= 0;
    else
        bit_count <= bit_count + 1;
end

// === Word Select (WS) Toggle ===
// WS changes at the start of Left and Right channel
always @(negedge bck) begin
    if (bit_count == 0 || bit_count == RESBIT + 1)
        ws <= ~ws;
end

// === I2S Data Output ===
// Output serial audio data on the falling edge of bck
always @(negedge bck) begin
    if (bit_count == 0 || bit_count == RESBIT + 1) begin
        data <= 1'b0; // Wait bit before Left and Right channel
    end else if (bit_count > 0 && bit_count <= RESBIT) begin
        // Transmit Left channel bits (MSB first)
        data <= sample[RESBIT - bit_count];
    end else if (bit_count > RESBIT + 1 && bit_count <= RESBIT + 1 + RESBIT) begin
        // Transmit Right channel bits (identical to Left for mono)
        data <= sample[RESBIT - (bit_count - (RESBIT + 1))];
    end else begin
        data <= 1'b0; // Padding or idle
    end
end

endmodule
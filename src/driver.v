module driver (
    input wire clk,            // 27 MHz system clock
    input wire btn1,           // Mute toggle
    output wire bck,           // 840 kHz bit clock
    output reg ws = 0,         // Word Select (L/R toggle)
    output reg data = 0,       // I2S serial data output
    output wire mute,
    output wire sample_tick,
    input wire [7:0] mono_sample // 8-bit mono audio sample
);

// === Parameters ===
localparam RESBIT     = 5'd8;
localparam TOTAL_BITS = RESBIT * 2 + 2; // 2 delay bits (one per channel)
localparam COUNTMAX   = TOTAL_BITS - 1;

reg [4:0] bit_count = 0;

assign sample_tick = (bit_count == COUNTMAX);

// === Mute Logic ===
reg btn1_sync_0 = 1, btn1_sync_1 = 1;
reg btn1_prev = 1;
reg mute_state = 0;

assign mute = mute_state;

always @(posedge clk) begin
    btn1_sync_0 <= btn1;
    btn1_sync_1 <= btn1_sync_0;
    btn1_prev   <= btn1_sync_1;
end

wire btn1_pressed = (btn1_prev == 1) && (btn1_sync_1 == 0);

always @(posedge clk) begin
    if (btn1_pressed)
        mute_state <= ~mute_state;
end

// === Clock Generation ===
Gowin_rPLL CLK_27_TO_818K (
    .clkoutd(bck),
    .clkin(clk)
);

// === Sample Handling ===
reg [7:0] sample = 8'd0;

always @(posedge bck) begin
    if (bit_count == 0)
        sample <= mute_state ? 8'd0 : mono_sample >> 1;
end

// === Bit Counter ===
always @(posedge bck) begin
    if (bit_count == COUNTMAX)
        bit_count <= 0;
    else
        bit_count <= bit_count + 1;
end

// === WS Toggling (1 cycle before MSB) ===
always @(negedge bck) begin
    if (bit_count == 0 || bit_count == RESBIT + 1)
        ws <= ~ws;
end

// === I2S Output ===
always @(negedge bck) begin
    if (bit_count == 0 || bit_count == RESBIT + 1) begin
        data <= 1'b0; // Wait bit per I2S spec
    end else if (bit_count > 0 && bit_count <= RESBIT) begin
        data <= sample[RESBIT - bit_count]; // Left channel
    end else if (bit_count > RESBIT + 1 && bit_count <= RESBIT + 1 + RESBIT) begin
        data <= sample[RESBIT - (bit_count - (RESBIT + 1))]; // Right channel
    end else begin
        data <= 1'b0;
    end
end

endmodule

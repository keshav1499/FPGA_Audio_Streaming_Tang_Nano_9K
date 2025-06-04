module driver (
    input wire clk,         // 27 MHz system clock
    input wire btn1,        // Mute toggle
    output wire bck,        // 4.8 MHz bit clock
    output reg ws = 0,      // Word Select
    output reg data = 0,    // I2S serial data output
    output wire mute,

    input wire [23:0] mono_sample // 24-bit audio sample
);

// === Parameters ===
localparam RESBIT     = 5'd24;                     
localparam TOTAL_BITS = (RESBIT + 1) * 2;  // 50
localparam COUNTMAX   = TOTAL_BITS - 1;

// === Mute Logic ===
reg btn1_sync_0 = 1, btn1_sync_1 = 1;
reg btn1_prev = 1;
reg mute_state = 0;

always @(posedge clk) begin
    btn1_sync_0 <= btn1;
    btn1_sync_1 <= btn1_sync_0;
    btn1_prev <= btn1_sync_1;
end

wire btn1_pressed = (btn1_prev == 1) && (btn1_sync_1 == 0);

always @(posedge clk) begin
    if (btn1_pressed)
        mute_state <= ~mute_state;
end

assign mute = mute_state;

// === Clock Generation ===
Gowin_rPLL CLK_27_TO_4_8 (
    .clkoutd(bck),
    .clkin(clk)
);

// === Sample Registers ===
reg [23:0] left_sample  = 24'd0;
reg [23:0] right_sample = 24'd0;

reg [5:0] bit_count = 0;

always @(posedge bck) begin
    if (bit_count == COUNTMAX)
        bit_count <= 0;
    else
        bit_count <= bit_count + 1;
end

always @(negedge bck) begin
    if (bit_count == 1 || bit_count == RESBIT + 2)
        ws <= ~ws;
end

// === Load mono sample into both channels with 50% volume ===
always @(posedge bck) begin
    if (bit_count == 0) begin
        left_sample  <= mute_state ? 24'd0 : mono_sample >>> 1;  // 50% volume
        right_sample <= mute_state ? 24'd0 : mono_sample >>> 1;  // 50% volume
    end
end

// === I2S Bitstream Output ===
always @(negedge bck) begin
    if (bit_count == 0 || bit_count == RESBIT + 1) begin
        data <= 0; // Wait bit
    end else if (bit_count < RESBIT + 1) begin
        data <= left_sample[23 - (bit_count - 1)];
    end else if (bit_count < TOTAL_BITS) begin
        data <= right_sample[23 - (bit_count - (RESBIT + 1))];
    end else begin
        data <= 0;
    end
end

endmodule

module uart
#(
    parameter DELAY_FRAMES = 31  // For 27 MHz / 882000 ≈ 30.6, round to 31
)
(
    input clk,
    input uart_rx,
    output uart_tx, // Not used
    output reg [5:0] led,
    input btn1,
    output reg [15:0] data_in, // Final 16-bit output sample
    output reg byte_ready
);

assign uart_tx = 1'b1;  // No TX

localparam HALF_DELAY_WAIT = (DELAY_FRAMES / 2);

reg [3:0] rxState = 0;
reg [12:0] rxCounter = 0;
reg [2:0] rxBitNumber = 0;

reg [7:0] shift_reg = 0;
reg [7:0] byte_buf = 0;

reg byte_phase = 0;  // 0 = LSB phase, 1 = MSB phase
reg [15:0] temp_data = 0;

localparam RX_STATE_IDLE       = 0;
localparam RX_STATE_START_BIT  = 1;
localparam RX_STATE_READ_WAIT  = 2;
localparam RX_STATE_READ       = 3;
localparam RX_STATE_STOP_BIT   = 4;

// --- LED smoothing registers ---
reg [23:0] intensity_accum = 0;
reg [15:0] intensity_smoothed = 0;
reg [15:0] led_update_counter = 0;
localparam LED_UPDATE_RATE = 1350; // ~20 ms for 27 MHz (LED updates at ~50 Hz)

always @(posedge clk) begin
    case (rxState)
        RX_STATE_IDLE: begin
            byte_ready <= 0;
            if (uart_rx == 0) begin
                rxState <= RX_STATE_START_BIT;
                rxCounter <= 1;
                rxBitNumber <= 0;
            end
        end

        RX_STATE_START_BIT: begin
            if (rxCounter == HALF_DELAY_WAIT) begin
                rxState <= RX_STATE_READ_WAIT;
                rxCounter <= 1;
            end else
                rxCounter <= rxCounter + 1;
        end

        RX_STATE_READ_WAIT: begin
            rxCounter <= rxCounter + 1;
            if (rxCounter == DELAY_FRAMES - 1) begin
                rxState <= RX_STATE_READ;
                rxCounter <= 0;
            end
        end

        RX_STATE_READ: begin
            shift_reg <= {uart_rx, shift_reg[7:1]};
            rxBitNumber <= rxBitNumber + 1;
            if (rxBitNumber == 3'b111) begin
                rxState <= RX_STATE_STOP_BIT;
                byte_buf <= {uart_rx, shift_reg[7:1]};  // Full byte captured here
            end else begin
                rxState <= RX_STATE_READ_WAIT;
            end
        end

        RX_STATE_STOP_BIT: begin
            rxCounter <= rxCounter + 1;
            if (rxCounter == DELAY_FRAMES - 1) begin
                rxCounter <= 0;
                rxState <= RX_STATE_IDLE;

                if (byte_phase == 0) begin
                    temp_data[7:0] <= byte_buf;  // LSB
                    byte_phase <= 1;
                end else begin
                    temp_data[15:8] <= byte_buf; // MSB
                    data_in <= temp_data;
                    byte_ready <= 1;
                    byte_phase <= 0;

                    // === Intensity calculation ===
                    if (temp_data[15] == 1'b1) begin
                        // Negative, take two's complement for abs
                        intensity_accum <= intensity_accum + (~temp_data + 1);
                    end else begin
                        intensity_accum <= intensity_accum + temp_data;
                    end

                    // === LED update ===
                    led_update_counter <= led_update_counter + 1;
                    if (led_update_counter >= LED_UPDATE_RATE) begin
                        led_update_counter <= 0;
                        intensity_smoothed <= intensity_accum[23:8]; // Averaged result
                        intensity_accum <= 0;
                        led <= intensity_smoothed[13:8];  // Visible brightness pattern
                    end
                end
            end
        end
    endcase
end

endmodule

// UART Receiver with LED Visualizer for Audio Amplitude
// ------------------------------------------------------
// Receives 16-bit audio samples over UART in LSB-MSB byte order.
// Samples are smoothed to control 6-bit LED brightness levels,
// reflecting audio intensity in real time.
//
// Parameters:
//   DELAY_FRAMES - Number of clock cycles per UART bit period
//                  (27 MHz / 882000 ≈ 30.6 → rounded to 31)

module uart
#(
    parameter DELAY_FRAMES = 31
)
(
    input clk,              // System clock (27 MHz)
    input uart_rx,          // UART receive line
    output uart_tx,         // UART transmit (not used)
    output reg [5:0] led,   // 6-bit LED output for audio intensity
    input btn1,             // Button input (not used)
    output reg [15:0] data_in,  // Final 16-bit output sample
    output reg byte_ready       // Pulse when 16-bit sample is ready
);

// TX not used: pulled high
assign uart_tx = 1'b1;

// Internal constants
localparam HALF_DELAY_WAIT   = (DELAY_FRAMES / 2);
localparam RX_STATE_IDLE     = 0;
localparam RX_STATE_START_BIT= 1;
localparam RX_STATE_READ_WAIT= 2;
localparam RX_STATE_READ     = 3;
localparam RX_STATE_STOP_BIT = 4;
localparam LED_UPDATE_RATE   = 1350; // ~50 Hz LED update (for 27 MHz clock)

// UART reception state machine
reg [3:0] rxState = 0;
reg [12:0] rxCounter = 0;
reg [2:0] rxBitNumber = 0;
reg [7:0] shift_reg = 0;
reg [7:0] byte_buf = 0;

// Byte accumulation phase
reg byte_phase = 0;         // 0 = waiting for LSB, 1 = waiting for MSB
reg [15:0] temp_data = 0;   // Temporary storage for incoming 16-bit sample

// LED smoothing and accumulation
reg [23:0] intensity_accum = 0;
reg [15:0] intensity_smoothed = 0;
reg [15:0] led_update_counter = 0;

// === Main UART Receiver Logic ===
always @(posedge clk) begin
    case (rxState)
        //----------------------------------------
        // IDLE: Wait for start bit (falling edge)
        //----------------------------------------
        RX_STATE_IDLE: begin
            byte_ready <= 0;
            if (uart_rx == 0) begin
                rxState <= RX_STATE_START_BIT;
                rxCounter <= 1;
                rxBitNumber <= 0;
            end
        end

        //----------------------------------------
        // START BIT: Wait half-bit to sample in middle
        //----------------------------------------
        RX_STATE_START_BIT: begin
            if (rxCounter == HALF_DELAY_WAIT) begin
                rxState <= RX_STATE_READ_WAIT;
                rxCounter <= 1;
            end else begin
                rxCounter <= rxCounter + 1;
            end
        end

        //----------------------------------------
        // READ WAIT: Delay for 1 full bit period
        //----------------------------------------
        RX_STATE_READ_WAIT: begin
            rxCounter <= rxCounter + 1;
            if (rxCounter == DELAY_FRAMES - 1) begin
                rxState <= RX_STATE_READ;
                rxCounter <= 0;
            end
        end

        //----------------------------------------
        // READ: Shift in bit from UART line
        //----------------------------------------
        RX_STATE_READ: begin
            shift_reg <= {uart_rx, shift_reg[7:1]};
            rxBitNumber <= rxBitNumber + 1;

            if (rxBitNumber == 3'b111) begin
                rxState <= RX_STATE_STOP_BIT;
                byte_buf <= {uart_rx, shift_reg[7:1]};  // Store received byte
            end else begin
                rxState <= RX_STATE_READ_WAIT;
            end
        end

        //----------------------------------------
        // STOP BIT: Wait 1 full bit period before finishing
        //----------------------------------------
        RX_STATE_STOP_BIT: begin
            rxCounter <= rxCounter + 1;
            if (rxCounter == DELAY_FRAMES - 1) begin
                rxCounter <= 0;
                rxState <= RX_STATE_IDLE;

                if (byte_phase == 0) begin
                    // First byte → LSB
                    temp_data[7:0] <= byte_buf;
                    byte_phase <= 1;
                end else begin
                    // Second byte → MSB
                    temp_data[15:8] <= byte_buf;
                    data_in <= temp_data;
                    byte_ready <= 1;
                    byte_phase <= 0;

                    //----------------------------------------
                    // Audio Intensity Accumulation (for LED)
                    //----------------------------------------
                    if (temp_data[15] == 1'b1) begin
                        // Negative → take two's complement (abs)
                        intensity_accum <= intensity_accum + (~temp_data + 1);
                    end else begin
                        intensity_accum <= intensity_accum + temp_data;
                    end

                    //----------------------------------------
                    // LED Update Logic (approx. every 20ms)
                    //----------------------------------------
                    led_update_counter <= led_update_counter + 1;
                    if (led_update_counter >= LED_UPDATE_RATE) begin
                        led_update_counter <= 0;
                        intensity_smoothed <= intensity_accum[23:8]; // Averaged value
                        intensity_accum <= 0;
                        led <= intensity_smoothed[13:8];  // Update visible LEDs
                    end
                end
            end
        end
    endcase
end

endmodule
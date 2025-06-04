module uart
#(
    parameter DELAY_FRAMES = 189 // 27 MHz / 143000 Baud
)
(
    input clk,
    input uart_rx,
    output uart_tx, // Not used
    output reg [5:0] led,
    input btn1,
    output reg [23:0] mono_sample, // 24-bit padded sample
    output reg byte_ready
);

assign uart_tx = 1'b1; // No transmit functionality

localparam HALF_DELAY_WAIT = (DELAY_FRAMES / 2);

reg [3:0] rxState = 0;
reg [12:0] rxCounter = 0;
reg [7:0] dataIn = 0;
reg [2:0] rxBitNumber = 0;

localparam RX_STATE_IDLE       = 0;
localparam RX_STATE_START_BIT  = 1;
localparam RX_STATE_READ_WAIT  = 2;
localparam RX_STATE_READ       = 3;
localparam RX_STATE_STOP_BIT   = 4;

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
            dataIn <= {uart_rx, dataIn[7:1]};
            rxBitNumber <= rxBitNumber + 1;
            if (rxBitNumber == 3'b111)
                rxState <= RX_STATE_STOP_BIT;
            else
                rxState <= RX_STATE_READ_WAIT;
        end
        RX_STATE_STOP_BIT: begin
            rxCounter <= rxCounter + 1;
            if (rxCounter == DELAY_FRAMES - 1) begin
                rxState <= RX_STATE_IDLE;
                rxCounter <= 0;
                mono_sample <= {dataIn, 16'd0}; // 8-bit to 24-bit
                byte_ready <= 1;
                led <= ~dataIn[5:0];
            end
        end
    endcase
end

endmodule

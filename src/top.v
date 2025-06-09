module top (
    input clk,          // 27 MHz
    input uart_rx,
    output uart_tx,
    input btn1,
    output bck,
    output ws,
    output data,
    output mute,
    output pow,
    output [5:0] led
);

assign pow =1;

wire [15:0] mono_sample;
wire [15:0] data_in;
wire byte_ready;


uart uart_inst (
    .clk(clk),
    .uart_rx(uart_rx),
    .uart_tx(uart_tx),
    .led(led),
    .btn1(btn1),
    .data_in(data_in),
    .byte_ready(byte_ready)
);

wire sample_tick;

FIFO fifo_buffer (
    .clk(clk),
    .data_in(data_in),
    .byte_ready(byte_ready),
    .sample_tick(sample_tick),
    .mono_sample(mono_sample)
);
driver driver_inst (
    .clk(clk),
    .btn1(btn1),
    .bck(bck),
    .ws(ws),
    .data(data),
    .mute(mute),
    .sample_tick(sample_tick),
    .mono_sample(mono_sample)
   // .sample_valid(sample_valid)
);

endmodule
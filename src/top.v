module top (
    input clk,          // 27 MHz
    input uart_rx,
    output uart_tx,
    input btn1,
    output bck,
    output ws,
    output data,
    output mute,
    output [5:0] led
);

wire [23:0] mono_sample;
wire byte_ready;


uart uart_inst (
    .clk(clk),
    .uart_rx(uart_rx),
    .uart_tx(uart_tx),
    .led(led),
    .btn1(btn1),
    .mono_sample(mono_sample),
    .byte_ready(byte_ready)
);

driver driver_inst (
    .clk(clk),
    .btn1(btn1),
    .bck(bck),
    .ws(ws),
    .data(data),
    .mute(mute),
    .mono_sample(mono_sample)
   // .sample_valid(sample_valid)
);

endmodule
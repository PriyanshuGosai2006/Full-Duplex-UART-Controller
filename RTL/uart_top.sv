// File: uart_top.sv
`timescale 1ns / 1ps

module uart_top (
    input  logic clk,
    input  logic rst_n,
    input  logic rx_pin,
    output logic tx_pin,
    uart_if.slave uif // Interface passed through port list
);

    parameter CLOCK_FREQ = 100_000_000;
    parameter BAUD_RATE  = 9600;
    localparam CLKS_PER_BIT = CLOCK_FREQ / BAUD_RATE;

    uart_tx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) tx_inst (
        .clk(clk),
        .rst_n(rst_n),
        .tx_data_in(uif.tx_data),
        .tx_valid(uif.tx_valid),
        .tx_ready(uif.tx_ready),
        .tx_pin(tx_pin)
    );

    uart_rx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) rx_inst (
        .clk(clk),
        .rst_n(rst_n),
        .rx_pin(rx_pin),
        .rx_data_out(uif.rx_data),
        .rx_valid(uif.rx_valid)
    );

    // If implementing backpressure logic, handle uif.rx_ready here.
    // For standard UART, the receiver just overwrites data if the user misses it.

endmodule
// File: uart_axis_top.sv
`timescale 1ns / 1ps

module uart_axis_top #(
    parameter CLOCK_FREQ = 100_000_000,
    parameter BAUD_RATE  = 9600,
    parameter FIFO_DEPTH = 16
)(
    input  logic       clk,
    input  logic       rst_n,
    
    // Physical UART Pins
    input  logic       rx_pin,
    output logic       tx_pin,

    // AXI4-Stream Slave Interface (System writing to UART TX)
    input  logic [7:0] s_axis_tdata,
    input  logic       s_axis_tvalid,
    output logic       s_axis_tready,

    // AXI4-Stream Master Interface (UART RX writing to System)
    output logic [7:0] m_axis_tdata,
    output logic       m_axis_tvalid,
    input  logic       m_axis_tready
);

    // Instantiate Phase 2 Interface
    uart_if uif (clk, rst_n);
    
    // Instantiate Phase 2 Core (Untouched, perfectly preserved logic)
    uart_top #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) core (
        .clk(clk),
        .rst_n(rst_n),
        .rx_pin(rx_pin),
        .tx_pin(tx_pin),
        .uif(uif.slave)
    );

    // ==========================================
    // TX FIFO (System to UART)
    // ==========================================
    logic tx_fifo_full;
    logic tx_fifo_empty;
    logic [7:0] tx_fifo_out;

    sync_fifo #(
        .DATA_WIDTH(8),
        .DEPTH(FIFO_DEPTH)
    ) tx_fifo (
        .clk(clk),
        .rst_n(rst_n),
        
        // Write Interface (AXI Slave Side)
        .wr_en(s_axis_tvalid),
        .wr_data(s_axis_tdata),
        .full(tx_fifo_full),
        
        // Read Interface (UART Core Side)
        .rd_en(uif.tx_ready && !tx_fifo_empty),
        .rd_data(tx_fifo_out),
        .empty(tx_fifo_empty)
    );

    // AXI Slave Backpressure
    assign s_axis_tready = ~tx_fifo_full;
    
    // Feed UART TX
    assign uif.tx_data  = tx_fifo_out;
    assign uif.tx_valid = ~tx_fifo_empty;


    // ==========================================
    // RX FIFO (UART to System)
    // ==========================================
    logic rx_fifo_full;
    logic rx_fifo_empty;

    sync_fifo #(
        .DATA_WIDTH(8),
        .DEPTH(FIFO_DEPTH)
    ) rx_fifo (
        .clk(clk),
        .rst_n(rst_n),
        
        // Write Interface (UART Core Side)
        .wr_en(uif.rx_valid),
        .wr_data(uif.rx_data),
        .full(rx_fifo_full),
        
        // Read Interface (AXI Master Side)
        .rd_en(m_axis_tready && !rx_fifo_empty),
        .rd_data(m_axis_tdata),
        .empty(rx_fifo_empty)
    );

    // AXI Master Output
    assign m_axis_tvalid = ~rx_fifo_empty;
    assign uif.rx_ready  = ~rx_fifo_full;

endmodule
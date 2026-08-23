// File: uart_if.sv
`timescale 1ns / 1ps

interface uart_if (input logic clk, input logic rst_n);
    // TX Signals (User to UART)
    logic [7:0] tx_data;
    logic       tx_valid;
    logic       tx_ready; // UART tells User it is ready to accept data

    // RX Signals (UART to User)
    logic [7:0] rx_data;
    logic       rx_valid; // UART tells User it has valid data
    logic       rx_ready; // User tells UART it read the data

    // Modports dictate directionality 
    modport master ( // Driven by Testbench / Microprocessor
        output tx_data, tx_valid, rx_ready,
        input  tx_ready, rx_data, rx_valid
    );

    modport slave ( // Driven by the UART IP
        input  tx_data, tx_valid, rx_ready,
        output tx_ready, rx_data, rx_valid
    );
endinterface
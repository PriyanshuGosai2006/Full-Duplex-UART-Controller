// File: uart_top_tb.sv
`timescale 1ns / 1ps

module uart_top_tb;

    // Clock and Reset
    logic clk;
    logic rst_n;
    
    // Physical loopback wire
    logic serial_line;

    // Instantiate Interface
    uart_if uif(clk, rst_n);

    // Instantiate Top Module
    uart_top dut (
        .clk(clk),
        .rst_n(rst_n),
        .rx_pin(serial_line), // Loopback: TX connects to RX
        .tx_pin(serial_line),
        .uif(uif.slave)
    );

    // 100 MHz Clock Generation
    always #5 clk = ~clk;

    // Stimulus
    initial begin
        // Initialize
        clk = 0;
        rst_n = 0;
        uif.tx_valid = 0;
        uif.tx_data = 8'h00;
        uif.rx_ready = 1;

        // Reset system
        #100;
        rst_n = 1;
        #100;

        $display("--- Starting Full-Duplex UART Loopback Test ---");

        // Send First Byte (0xAB)
        @(posedge clk);
        wait(uif.tx_ready);
        uif.tx_valid = 1;
        uif.tx_data  = 8'hAB;
        @(posedge clk);
        uif.tx_valid = 0;
        
        $display("[%0t] TX: Sent 0xAB", $time);

        // Wait for it to be received via loopback
        wait(uif.rx_valid);
        $display("[%0t] RX: Received 0x%h", $time, uif.rx_data);
        
        if (uif.rx_data !== 8'hAB) $error("Mismatch: Expected 0xAB!");

        #50000;

        // Send Second Byte (0x55 - alternating 1s and 0s)
        @(posedge clk);
        wait(uif.tx_ready);
        uif.tx_valid = 1;
        uif.tx_data  = 8'h55;
        @(posedge clk);
        uif.tx_valid = 0;
        
        $display("[%0t] TX: Sent 0x55", $time);

        wait(uif.rx_valid);
        $display("[%0t] RX: Received 0x%h", $time, uif.rx_data);

        if (uif.rx_data !== 8'h55) $error("Mismatch: Expected 0x55!");

        $display("--- Test Passed ---");
        #1000;
        $finish;
    end

endmodule
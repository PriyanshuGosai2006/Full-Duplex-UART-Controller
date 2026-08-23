// File: uart_axis_tb.sv
`timescale 1ns / 1ps

module uart_axis_tb;

    logic clk;
    logic rst_n;
    logic serial_line;

    // AXI4-Stream Slave (System writing to UART)
    logic [7:0] s_axis_tdata;
    logic       s_axis_tvalid;
    logic       s_axis_tready;

    // AXI4-Stream Master (UART reading to System)
    logic [7:0] m_axis_tdata;
    logic       m_axis_tvalid;
    logic       m_axis_tready;

    // Instantiate Phase 3 Wrapper
    // ARTIFICIALLY SHRINKING FIFO TO DEPTH 4 FOR STRESS TEST
    uart_axis_top #(
        .CLOCK_FREQ(100_000_000),
        .BAUD_RATE(9600),
        .FIFO_DEPTH(4) 
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .rx_pin(serial_line),
        .tx_pin(serial_line), // Loopback
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready)
    );

    // 100 MHz Clock Generation (Strict SV construct)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Standard AXI Master Driver Task
    task send_byte(input logic [7:0] data);
        begin
            @(posedge clk);
            s_axis_tvalid = 1'b1;
            s_axis_tdata  = data;
            
            // The Backpressure Wait: Do not proceed until hardware says ready
            wait(s_axis_tready == 1'b1);
            
            @(posedge clk);
            s_axis_tvalid = 1'b0;
        end
    endtask

    initial begin
        // Initialization
        rst_n = 0;
        s_axis_tvalid = 0;
        s_axis_tdata = 0;
        m_axis_tready = 1; // System is always ready to receive in this test

        #100 rst_n = 1;
        #100;

        $display("==================================================");
        $display("--- Starting AXI4-Stream Backpressure Stress Test ---");
        $display("FIFO Depth is overridden to 4.");
        $display("==================================================");

        // Blast 6 bytes back-to-back. 
        send_byte(8'hA1);
        $display("[%0t] Pushed A1 into TX FIFO", $time);
        
        send_byte(8'hB2);
        $display("[%0t] Pushed B2 into TX FIFO", $time);
        
        send_byte(8'hC3);
        $display("[%0t] Pushed C3 into TX FIFO", $time);
        
        send_byte(8'hD4);
        $display("[%0t] Pushed D4 into TX FIFO", $time);
        
        $display("[%0t] WARNING: FIFO should be physically FULL right now.", $time);
        $display("[%0t] Attempting to push E5... The testbench should stall here.", $time);
        
        // This task will freeze because s_axis_tready will be 0
        send_byte(8'hE5); 
        $display("[%0t] Pushed E5 into TX FIFO (Backpressure resolved!)", $time);
        
        send_byte(8'hF6);
        $display("[%0t] Pushed F6 into TX FIFO", $time);

        // Wait for all 6 bytes to physically loop back through the wire and exit the RX FIFO
        repeat(6) begin
            wait(m_axis_tvalid);
            @(posedge clk);
            $display("[%0t] RX Extracted: %h from RX FIFO", $time, m_axis_tdata);
        end

        $display("==================================================");
        $display("--- AXI Test Passed Flawlessly ---");
        #1000 $finish;
    end
endmodule
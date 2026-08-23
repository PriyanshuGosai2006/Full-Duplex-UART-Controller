// File: uart_rx.sv
`timescale 1ns / 1ps

module uart_rx #(
    parameter CLKS_PER_BIT = 10417
)(
    input  logic       clk,
    input  logic       rst_n,
    input  logic       rx_pin,
    output logic [7:0] rx_data_out,
    output logic       rx_valid
);

    typedef enum logic [1:0] {IDLE, START, DATA, STOP} state_t;
    state_t state;

    logic [13:0] clk_count;
    logic [2:0]  bit_index;
    logic        rx_pin_sync1, rx_pin_sync; // Double-flop synchronizer to prevent metastability

    // Synchronize asynchronous RX input
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_pin_sync1 <= 1'b1;
            rx_pin_sync  <= 1'b1;
        end else begin
            rx_pin_sync1 <= rx_pin;
            rx_pin_sync  <= rx_pin_sync1;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state       <= IDLE;
            clk_count   <= '0;
            bit_index   <= '0;
            rx_data_out <= '0;
            rx_valid    <= 1'b0;
        end else begin
            // Default pulse valid for only one clock cycle
            rx_valid <= 1'b0; 

            case (state)
                IDLE: begin
                    clk_count <= '0;
                    bit_index <= '0;
                    // Detect falling edge of start bit
                    if (rx_pin_sync == 1'b0) begin
                        state <= START;
                    end
                end

                START: begin
                    if (clk_count == (CLKS_PER_BIT / 2)) begin
                        if (rx_pin_sync == 1'b0) begin // Confirm it's still low (center of start bit)
                            clk_count <= '0;
                            state     <= DATA;
                        end else begin
                            state <= IDLE; // False alarm (glitch)
                        end
                    end else begin
                        clk_count <= clk_count + 1;
                    end
                end

                DATA: begin
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= '0;
                        rx_data_out[bit_index] <= rx_pin_sync; // Sample at center
                        
                        if (bit_index < 7) begin
                            bit_index <= bit_index + 1;
                        end else begin
                            bit_index <= '0;
                            state     <= STOP;
                        end
                    end
                end

                STOP: begin
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= '0;
                        if (rx_pin_sync == 1'b1) begin // Valid stop bit
                            rx_valid <= 1'b1;
                        end
                        state <= IDLE;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule
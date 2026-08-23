// File: uart_tx.sv
`timescale 1ns / 1ps

module uart_tx #(
    parameter CLKS_PER_BIT = 10417 // 100MHz / 9600 baud
)(
    input  logic       clk,
    input  logic       rst_n,
    input  logic [7:0] tx_data_in,
    input  logic       tx_valid,
    output logic       tx_ready,
    output logic       tx_pin
);

    typedef enum logic [1:0] {IDLE, START, DATA, STOP} state_t;
    state_t state, next_state;

    logic [13:0] clk_count;
    logic [2:0]  bit_index;
    logic [7:0]  tx_data_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state       <= IDLE;
            clk_count   <= '0;
            bit_index   <= '0;
            tx_data_reg <= '0;
            tx_pin      <= 1'b1; // Idle high
            tx_ready    <= 1'b1;
        end else begin
            case (state)
                IDLE: begin
                    tx_pin    <= 1'b1;
                    tx_ready  <= 1'b1;
                    clk_count <= '0;
                    bit_index <= '0;
                    
                    if (tx_valid) begin
                        tx_data_reg <= tx_data_in;
                        tx_ready    <= 1'b0;
                        state       <= START;
                    end
                end

                START: begin
                    tx_pin <= 1'b0; // Start bit is low
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= '0;
                        state     <= DATA;
                    end
                end

                DATA: begin
                    tx_pin <= tx_data_reg[bit_index];
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= '0;
                        if (bit_index < 7) begin
                            bit_index <= bit_index + 1;
                        end else begin
                            bit_index <= '0;
                            state     <= STOP;
                        end
                    end
                end

                STOP: begin
                    tx_pin <= 1'b1; // Stop bit is high
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= '0;
                        state     <= IDLE;
                        tx_ready  <= 1'b1;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule
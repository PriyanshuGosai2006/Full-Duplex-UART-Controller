// File: sync_fifo.sv
`timescale 1ns / 1ps

module sync_fifo #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH      = 16 
)(
    input  logic                  clk,
    input  logic                  rst_n,

    // Write Interface 
    input  logic                  wr_en,
    input  logic [DATA_WIDTH-1:0] wr_data,
    output logic                  full,

    // Read Interface
    input  logic                  rd_en,
    output logic [DATA_WIDTH-1:0] rd_data,
    output logic                  empty
);

    localparam ADDR_WIDTH = $clog2(DEPTH);

    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    logic [ADDR_WIDTH-1:0] wr_ptr;
    logic [ADDR_WIDTH-1:0] rd_ptr;
    logic [ADDR_WIDTH:0]   count; 

    assign empty = (count == 0);
    assign full  = (count == DEPTH);

    // FWFT Architecture: The data is combinationally exposed to the bus immediately.
    assign rd_data = mem[rd_ptr];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= '0;
        end else if (wr_en && !full) begin
            mem[wr_ptr] <= wr_data;
            wr_ptr      <= wr_ptr + 1;
        end
    end

    // The Read Pointer moves, updating the combinational output automatically
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr  <= '0;
        end else if (rd_en && !empty) begin
            rd_ptr  <= rd_ptr + 1;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= '0;
        end else begin
            case ({wr_en && !full, rd_en && !empty})
                2'b10: count <= count + 1; 
                2'b01: count <= count - 1; 
                default: count <= count;
            endcase
        end
    end
endmodule
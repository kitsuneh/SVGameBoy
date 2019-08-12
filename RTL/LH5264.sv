`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
/*
    This is the functional block of LH5264 SRAM
    Size 8192 x 1 bytes (8bits)
*/
//////////////////////////////////////////////////////////////////////////////////

module LH5264
(
    input logic [7:0] D_in,
    input logic [12:0] A,
    input logic CE1,
    input logic CE2,
    input logic clk,
    input logic OE,
    output logic [7:0] D_out
);

logic we;
assign we = CE1 && CE2;

logic [7:0] q;
assign D_out = OE ? q : 8'hFF;
Quartus_single_port_ram_8k RAM_8K(.data(D_in), .addr(A), .clk(clk), .we(we), .q(q));

endmodule

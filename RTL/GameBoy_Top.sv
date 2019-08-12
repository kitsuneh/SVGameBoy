`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// The GameBoy Top Level
//////////////////////////////////////////////////////////////////////////////////


module GameBoy_Top
(
    input logic clk,
    input logic rst,
    /* GameBoy Pixel Conduit */
    output logic PX_VALID,
    output logic [1:0] LD,
    /* GameBoy Joypad Conduit */
	input logic P10,
	input logic P11,
	input logic P12,
	input logic P13,
	output logic P14,
	output logic P15,
	/* GameBoy Cartridge Conduit */
	output logic [15:0] CART_ADDR,
	input logic [7:0] CART_DATA_in,
	output logic [7:0] CART_DATA_out,
	output logic CART_RD,
	output logic CART_WR,
	/* GameBoy Audio Conduit */
	output logic [15:0] LOUT,
	output logic [15:0] ROUT
	
);

/* Video SRAM */
logic [7:0] MD_in; // video sram data
logic [7:0] MD_out; // video sram data
logic [12:0] MA;
logic MWR; // high active
logic MCS; // high active
logic MOE; // high active
/* LCD */
logic CPG; // CONTROL
logic CP; // CLOCK
logic ST; // HORSYNC
logic CPL; // DATALCH
logic FR; // ALTSIGL
logic S; // VERTSYN

/* Serial Link */
logic S_OUT;
logic S_IN;
logic SCK_in; // serial link clk
logic SCK_out; // serial link clk
/* Work RAM/Cartridge */
logic CLK_GC; // Game Cartridge Clock
logic WR; // high active
logic RD; // high active
logic CS; // high active
logic [15:0] A;
logic [7:0] D_in; // data bus
logic [7:0] D_out; // data bus

/* The DMG-CPU */
LR35902 DMG_CPU(.clk(clk), .rst(rst), .MD_in(MD_in), .MD_out(MD_out), .MA(MA), .MWR(MWR), .MCS(MCS), .MOE(MOE), .LD(LD), .PX_VALID(PX_VALID),
                .CPG(CPG), .CP(CP), .ST(ST), .CPL(CPL), .FR(FR), .S(S), .P10(P10), .P11(P11), .P12(P12), .P13(P13), .P14(P14), .P15(P15),
                .S_OUT(S_OUT), .S_IN(S_IN), .SCK_in(SCK_in), .SCK_out(SCK_out), .CLK_GC(CLK_GC), .WR(WR), .RD(RD), .CS(CS), .A(A), .D_in(D_in),
                .D_out(D_out), .LOUT(LOUT), .ROUT(ROUT));

/* VRAM Connection */
LH5264 VRAM(.D_out(MD_in), .D_in(MD_out), .CE1(MCS), .CE2(MWR), .A(MA), .OE(MOE), .clk(~clk));

/* WRAM Connection */
logic [7:0] WRAM_Din, WRAM_Dout, WRAM_WR;
LH5264 WRAM(.D_out(WRAM_Din), .D_in(WRAM_Dout), .CE1(WRAM_WR), .CE2(A[14]), .A(A), .OE(A[14]), .clk(~clk));

/* Cartridge */
assign D_in = (A < 16'h8000 || (A >= 16'hA000 && A < 16'hC000)) ? CART_DATA_in : WRAM_Din;
assign CART_DATA_out = (A < 16'h8000 || (A >= 16'hA000 && A < 16'hC000)) ? D_out : 0; 
assign CART_RD = RD && (A < 16'h8000 || (A >= 16'hA000 && A < 16'hC000));
assign CART_WR = WR && (A < 16'h8000 || (A >= 16'hA000 && A < 16'hC000));
assign CART_ADDR = (A < 16'h8000 || (A >= 16'hA000 && A < 16'hC000)) ? A : 0;
assign WRAM_Dout = !(A < 16'h8000 || (A >= 16'hA000 && A < 16'hC000)) ? D_out : 8'hFF;
assign WRAM_WR = WR && (A >= 16'hC000 && A < 16'hFE00);

endmodule

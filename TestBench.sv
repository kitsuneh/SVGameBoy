`timescale 1ns / 1ns


module TestBench();
    
logic clk, clk2;
logic rst;

logic [15:0] MEM_ADDR;
logic [7:0] DATA_in [0:31];
logic [7:0] DATA_out;
logic RD; logic WR; logic HALT; logic INTQ;
logic [7:0] DATA_brom;
logic [14:0] LCD_ADDR;
logic [1:0] LCD_PIXEL;
logic [7:0] IN_BCD, OUT_BCD;
logic [7:0] joypad;

logic [1:0] AAAA [1:0];
logic B1, B2, B3, B4;
assign B1 = AAAA[0][0];
assign B2 = AAAA[1][0];
assign B3 = AAAA[0][1];
assign B4 = AAAA[1][1];

//GB_Z80_SINGLE GB_Z80_CPU(.clk(clk), .rst(rst), .ADDR(MEM_ADDR), .DATA_in(DATA_brom), .DATA_out(DATA_out), .*); 

initial begin

    AAAA[0] <= 2'b11;
    AAAA[1] <= 2'b00;
    //$readmemh("dmg_boot.mem", boot_rom, 0, 255);
//    for (int i = 0; i < 32; i++)
//        DATA_in [i] <= 8'h00;
//    DATA_in[1] <= 8'h01;
//    DATA_in[2] <= 8'h12;
//    DATA_in[3] <= 8'h34;
//    DATA_in[4] <= 8'h03;
//    DATA_in[5] <= 8'h04;
//    DATA_in[6] <= 8'h05;
//    DATA_in[7] <= 8'h06;
//    DATA_in[8] <= 8'hAB;
//    DATA_in[9] <= 8'h07;
//    DATA_in[10] <= 8'h08;
//    DATA_in[13] <= 8'h09;
//    DATA_in[14] <= 8'h02;
//    DATA_in[15] <= 8'h01;
//    DATA_in[16] <= 8'h01;
//    DATA_in[17] <= 8'h00;
//    DATA_in[18] <= 8'h0A;
//    DATA_in[19] <= 8'h0B;
//    DATA_in[20] <= 8'h0C;
//    DATA_in[21] <= 8'h0D;
//    DATA_in[22] <= 8'h0E;
    IN_BCD <= 8'hFF;
//    DATA_in[23] <= 8'h33;
//    DATA_in[24] <= 8'h0F;
//    DATA_in[25] <= 8'h18;
//    DATA_in[26] <= 8'hFE;
    clk <= 0;
    clk2 <= 0;
    rst <= 1;
    joypad <= 0;
    #20 rst <= 0;
    //#2665000 $finish; // wait for vertical blank boot rom $0x0064
    //#2711100 $finish;//First Fetch M0
    // #5478400 ADDR 0070 LD C0x13
    //# 5479080 $finish;// 0x0088 SUB
   // LD FE50 to disable rom
    //#235061200 $finish; // 03 test op hl jp C000
   // #238391550 $finish; // 03 test op hl $CB21 POP HL
   //#338391550 $finish;
   //#251578800 $finish; // $C67C LD a16 SP 
   //#255246000 $finish; //$DEFB JP Z C67D
     //#259340000 $finish; // RST 0
//      #1138469109 joypad[4] <= 1;
//      #100000000 joypad[4] <= 0;
//      #100000000 joypad[4] <= 1;
//      #100000000 joypad[4] <= 0;
       #1048641959 $finish;
      //#100000000 joypad[4] <= 1;
      //#100000000 joypad[4] <= 0;
      //#2138469109 $finish; // RST 0
end

logic DE1_VGA_CLK;
assign DE1_VGA_CLK = clk;
//brom boot_rom(.addr(MEM_ADDR[7:0]), .clk(~clk), .data(DATA_brom));


logic [15:0] CART_ADDR;
logic [25:0] MBC1_ADDR;;
logic [7:0] CART_DATA;
logic [7:0] MBC_CART_DATA_in, MBC1_DATA_out;
logic CART_RD;
logic CART_WR;
logic CART_CS;
logic MBC1_RD;
logic MBC1_WR;

logic [7:0] CART_DATA_int;
logic [7:0] CART_DATA_out;
logic [7:0] CART_RAM_DATA;
logic [7:0] CART_ROM_DATA;

logic [14:0] CART_ADDR_int;
assign CART_DATA = CART_RD ? CART_DATA_int : 8'hFF;
//assign CART_ADDR_int = CART_RD ? CART_ADDR : 0;
MBC1 GB_MBC1( .clk(clk2), .reset(rst), .CART_ADDR(CART_ADDR), .CART_DATA_in(CART_DATA), .CART_DATA_out(CART_DATA_out),
              .CART_RD(CART_RD), .CART_WR(CART_WR), .MBC1_ADDR(MBC1_ADDR), .MBC1_RD(MBC1_RD), .MBC1_WR(MBC1_WR), 
              .MBC1_DATA_in(CART_DATA_int), .MBC1_DATA_out(MBC1_DATA_out), .NUM_ROM_BANK(8'd32), .NUM_RAM_BANK(8'd4));
Tetris_ROM CART(.addr(MBC1_ADDR), .clk(~clk), .data(CART_ROM_DATA));

ram_128 CART_RAM(.data(MBC1_DATA_out), .we(MBC1_WR), .clk(clk2), .q(CART_RAM_DATA), .addr(MBC1_ADDR[6:0]));
assign CART_DATA_int = MBC1_ADDR >= 26'h2000000 ? CART_RAM_DATA : CART_ROM_DATA;


Top GameBoy(.*);
//logic [7:0] VGA_R, VGA_G, VGA_B;
//vga_ball vga_ball(.clk(clk), .reset(rst), .VGA_R(VGA_R), .VGA_G(VGA_G), .VGA_B(VGA_B));

always @(*)
begin
    #5 clk <= !clk;
    #1 clk2 <= !clk2;
end

endmodule

module ram_128
#(parameter DATA_WIDTH=8, parameter ADDR_WIDTH=7)
(
	input [(DATA_WIDTH-1):0] data,
	input [(ADDR_WIDTH-1):0] addr,
	input we, clk,
	output [(DATA_WIDTH-1):0] q
);

	// Declare the RAM variable
	reg [DATA_WIDTH-1:0] ram[127:0];

	// Variable to hold the registered read address
	reg [ADDR_WIDTH-1:0] addr_reg;

	always @ (posedge clk)
	begin
		// Write
		if (we)
			ram[addr] <= data;

		addr_reg <= addr;
	end

	// Continuous assignment implies read returns NEW data.
	// This is the natural behavior of the TriMatrix memory
	// blocks in Single Port mode.  
	assign q = ram[addr_reg];

endmodule

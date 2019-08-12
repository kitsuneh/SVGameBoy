/* This is the Cartridge Interface for SDRAM - MBC - GameBoy */
`define SDRAM_RAM_BASE 26'h2000000
module GameBoy_Cartridge
(
	input logic clk,
	input logic reset,
	
	output logic SYNC_clk,
	output logic GB_rst,
	
	/* Avalon Master for SDRAM Read/Write */
	output logic [25:0] address,
	output logic read,
	output logic write,
	input logic [7:0] readdata,
	output logic [7:0] writedata,
	input logic waitrequest,
	
	/* Avalon Slave for HPS */
	input logic [25:0] hps_address,
	input logic hps_read,
	input logic hps_write,
	output logic [7:0] hps_readdata,
	input logic [7:0] hps_writedata,
	output logic hps_waitrequest,
	
	/* GameBoy Cartrdige Conduit */
	input logic [15:0] CART_ADDR,
	output logic [7:0] CART_DATA_in,
	input logic [7:0] CART_DATA_out,
	input logic CART_RD,
	input logic CART_WR,
	
	output logic [9:0] LEDR
);

logic [25:0] MBC1_ADDR;
logic MBC1_RD;
logic MBC1_WR;
logic [7:0] MBC1_DATA_in;
logic [7:0] MBC1_DATA_out;
logic [7:0] MBC1_CART_DATA_in;
logic [7:0] NUM_RAM_BANK, NUM_ROM_BANK, NUM_ROM_BANK2;
MBC1 GB_MBC1 (.clk(clk), .reset(reset), .CART_ADDR(CART_ADDR), .CART_DATA_in(MBC1_CART_DATA_in),
			  .CART_DATA_out(CART_DATA_out), .CART_RD(CART_RD), .CART_WR(CART_WR), .MBC1_ADDR(MBC1_ADDR), 
			  .MBC1_RD(MBC1_RD), .MBC1_WR(MBC1_WR), .MBC1_DATA_in(MBC1_DATA_in), .MBC1_DATA_out(MBC1_DATA_out),
			  .NUM_RAM_BANK(NUM_RAM_BANK), .NUM_ROM_BANK(NUM_ROM_BANK));

logic [25:0] MBC3_ADDR;
logic MBC3_RD;
logic MBC3_WR;
logic [7:0] MBC3_DATA_in;
logic [7:0] MBC3_DATA_out;
logic [7:0] MBC3_CART_DATA_in;
MBC3 GB_MBC3 (.clk(clk), .reset(reset), .CART_ADDR(CART_ADDR), .CART_DATA_in(MBC3_CART_DATA_in),
			  .CART_DATA_out(CART_DATA_out), .CART_RD(CART_RD), .CART_WR(CART_WR), .MBC3_ADDR(MBC3_ADDR), 
			  .MBC3_RD(MBC3_RD), .MBC3_WR(MBC3_WR), .MBC3_DATA_in(MBC3_DATA_in), .MBC3_DATA_out(MBC3_DATA_out),
			  .NUM_RAM_BANK(NUM_RAM_BANK), .NUM_ROM_BANK(NUM_ROM_BANK));

logic [25:0] MBC5_ADDR;
logic MBC5_RD;
logic MBC5_WR;
logic [7:0] MBC5_DATA_in;
logic [7:0] MBC5_DATA_out;
logic [7:0] MBC5_CART_DATA_in;
MBC5 GB_MBC5 (.clk(clk), .reset(reset), .CART_ADDR(CART_ADDR), .CART_DATA_in(MBC5_CART_DATA_in),
			  .CART_DATA_out(CART_DATA_out), .CART_RD(CART_RD), .CART_WR(CART_WR), .MBC5_ADDR(MBC5_ADDR), 
			  .MBC5_RD(MBC5_RD), .MBC5_WR(MBC5_WR), .MBC5_DATA_in(MBC5_DATA_in), .MBC5_DATA_out(MBC5_DATA_out),
			  .NUM_RAM_BANK(NUM_RAM_BANK), .NUM_ROM_BANK({NUM_ROM_BANK2, NUM_ROM_BANK}));

logic rom_load_done;
logic [7:0] MBC_sel;
assign LEDR = {10{rom_load_done}};

logic double_speed, double_speed_req;
always_ff @(posedge clk)
begin
	if (reset)
	begin
		rom_load_done <= 0;
		NUM_ROM_BANK <= 0;
		NUM_ROM_BANK2 <= 0;
		NUM_RAM_BANK <= 0;
		MBC_sel <= 0;
		double_speed_req <= 0;
	end
	else if (hps_address[25:0] == (`SDRAM_RAM_BASE - 1) && hps_write && !hps_waitrequest) rom_load_done <= hps_writedata[0];
	else if (hps_address[25:0] == (`SDRAM_RAM_BASE - 2) && hps_write && !hps_waitrequest) NUM_ROM_BANK2 <= hps_writedata;
	else if (hps_address[25:0] == (`SDRAM_RAM_BASE - 3) && hps_write && !hps_waitrequest) NUM_ROM_BANK <= hps_writedata;
	else if (hps_address[25:0] == (`SDRAM_RAM_BASE - 4) && hps_write && !hps_waitrequest) NUM_RAM_BANK <= hps_writedata;
	else if (hps_address[25:0] == (`SDRAM_RAM_BASE - 5) && hps_write && !hps_waitrequest) MBC_sel <= hps_writedata;
	else if (hps_address[25:0] == (`SDRAM_RAM_BASE - 6) && hps_write && !hps_waitrequest) double_speed_req <= hps_writedata;
end

always_comb
begin
	address = hps_address;
	read = hps_read;
	write = hps_write;
	hps_readdata = readdata;
	writedata = hps_writedata;
	hps_waitrequest = waitrequest;
	CART_DATA_in = 8'hFF;
	MBC1_DATA_in = 8'hFF;
	MBC3_DATA_in = 8'hFF;
	MBC5_DATA_in = 8'hFF;
	if (rom_load_done)
	begin
		unique case (MBC_sel)
			8'h00:
			begin
				address = {10'b0, CART_ADDR};
				read = CART_RD;
				write = 0;
				CART_DATA_in = readdata;
			end
			8'h01:
			begin
				address = MBC1_ADDR;
				read = MBC1_RD;
				write = MBC1_WR;
				MBC1_DATA_in = readdata;
				CART_DATA_in = MBC1_CART_DATA_in;
				writedata = MBC1_DATA_out;
			end
			8'h03:
			begin
				address = MBC3_ADDR;
				read = MBC3_RD;
				write = MBC3_WR;
				MBC3_DATA_in = readdata;
				CART_DATA_in = MBC3_CART_DATA_in;
				writedata = MBC3_DATA_out;
			end
			8'h05:
			begin
				address = MBC5_ADDR;
				read = MBC5_RD;
				write = MBC5_WR;
				MBC5_DATA_in = readdata;
				CART_DATA_in = MBC5_CART_DATA_in;
				writedata = MBC5_DATA_out;
			end
		endcase
	end
end

logic [5:0] clk_div;
always_ff @(posedge clk)
begin
    if (reset || !rom_load_done) 
    begin
		GB_rst <= 1;
        //clk_div <= 8'h00;
        double_speed <= 0;
    end
    else
    begin
		if (clk_div[2] && !clk_div[3] && double_speed_req) double_speed <= double_speed;
		else if (!clk_div[2] && clk_div[3] && !double_speed_req) double_speed <= double_speed;
		else double_speed <= double_speed_req;
		
		if (waitrequest && ((!double_speed && clk_div[3:0] == 4'b0111) || (double_speed && clk_div[2:0] == 3'b011))) clk_div <= clk_div;
		else clk_div <= clk_div + 1;
		GB_rst <= 0;
	end
end

assign SYNC_clk = double_speed ? clk_div[2] : clk_div[3];

endmodule

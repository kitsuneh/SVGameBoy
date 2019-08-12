`timescale 1ns / 1ps

module GameBoy_Audio
(
	input logic clk,
	input logic rst,
	
	input logic [15:0] GB_LOUT,
	input logic [15:0] GB_ROUT,
	
	output logic [15:0] right_data,
	output logic right_valid,
	input logic right_ready,
	output logic [15:0] left_data,
	output logic left_valid,
	input logic left_ready
);

logic [15:0] counter;
logic [6:0] init_counter;

always_ff @(posedge clk)
begin
	if (rst)
	begin
		counter <= 0;
		init_counter <= 0;
	end
	else
	begin
		if (init_counter != 7'b111_1111)
			init_counter <= init_counter + 1;
		else
		begin
			counter <= counter + 1;
		end
	end
end

always_comb
begin
	right_valid = 0;
	left_valid = 0;
	right_data = 0;
	left_data = 0;
	if (init_counter != 7'b111_1111)
	begin
		right_data = 16'h0000;
		left_data = 16'h0000;
		right_valid = 1;
		left_valid = 1;
	end
	else
	begin
		if (counter[7:0] == 8'hFF)
		begin
			right_valid = 1;
			left_valid = 1;
			right_data = GB_ROUT << 6;
			left_data = GB_LOUT  << 6;
		end
	end
end

endmodule

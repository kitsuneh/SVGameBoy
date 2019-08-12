module GameBoy_Joypad
(
	input 	logic 	clk,
	input 	logic	reset,
	/* Avalon Slave */
	input 	logic [7:0]  writedata_slv,
	input 	logic 	write_slv,
	input 			chipselect_slv,
	/* Gameboy JoyPad Conduit */
	input	logic	P15,
	input 	logic 	P14,
	output  logic 	P13,
	output  logic 	P12,
	output  logic 	P11,
	output  logic 	P10
);

logic	[7:0]		joypad;

always_ff @(posedge clk)
begin
	if (reset) 
	begin
		joypad <= 8'h00;
	end 
	else if (chipselect_slv && write_slv)
	begin
		joypad <= writedata_slv;	
	end
end

always_comb
begin
	 P10 = 1;
	 P11 = 1;
	 P12 = 1;
	 P13 = 1;
    if (!P14)
	 begin
        if (joypad[0])	// RIGHT
            P10 = 0;
        if (joypad[1])	// LEFT
            P11 = 0;
        if (joypad[2])	// UP
            P12 = 0;
        if (joypad[3])	// DOWN
            P13 = 0;
	 end
    if (!P15)
	 begin
        if (joypad[4])	// A
            P10 = 0;
        if (joypad[5])	// B
            P11 = 0;
        if (joypad[6])	// SELECT
            P12 = 0;
        if (joypad[7])	// START
            P13 = 0;
	 end
end

endmodule
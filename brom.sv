`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
//This is the internal boot rom for GameBoy
//http://gbdev.gg8.se/files/roms/bootroms/
//Convert to mem file by
//hexdump -e '8/1 "%02x " "\n"' input.bin > output.mem
//////////////////////////////////////////////////////////////////////////////////

// Quartus Prime Verilog Template
// Single Port ROM
module brom
(
    input [7:0] addr,
    input clk,
    output reg [7:0] data
);

    reg [7:0] boot_rom [0:255];

    initial begin
        $readmemh("dmg_boot.mem", boot_rom, 0, 255);
    end

    always @ (posedge clk)
    begin
        data <= boot_rom[addr];
    end

endmodule

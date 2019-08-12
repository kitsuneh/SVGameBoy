`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// This is the MBC 5 Memory Bank Controller for The GameBoy
//////////////////////////////////////////////////////////////////////////////////

`define SDRAM_RAM_BASE 26'h2000000

module MBC5
(
    input logic clk,
    input logic reset,
    input logic [9:0] NUM_ROM_BANK, // How many ROM banks in this cartridge?
    input logic [4:0] NUM_RAM_BANK, // How many RAM banks in this cartridge?
    input logic [15:0] CART_ADDR,
    output logic [7:0] CART_DATA_in,
    input logic [7:0] CART_DATA_out,
    input logic CART_RD,
    input logic CART_WR,
    output logic [25:0] MBC5_ADDR,
    output logic MBC5_RD,
    output logic MBC5_WR,
    input logic [7:0] MBC5_DATA_in,
    output logic [7:0] MBC5_DATA_out
);

// 4 writable registers
logic [8:0] ROM_BANK_NUM, ROM_BANK_NUM_NEXT;    // {ROMB1(1-bit), ROMB0(8-bit)}
logic [8:0] ROM_BANK_NUM_ACTUAL;                // 0x3000-0x3FFF 0x2000-0x2FFF
logic [3:0] RAM_BANK_NUM, RAM_BANK_NUM_NEXT;    // 0x4000-0x5FFF
logic RAM_EN, RAM_EN_NEXT;                      // 0x0000-0x1FFF

always_ff @(posedge clk)
begin
    if (reset)
    begin
        ROM_BANK_NUM <= 1;
        RAM_BANK_NUM <= 0;
        RAM_EN <= 0;
    end
    else
    begin
        ROM_BANK_NUM <= ROM_BANK_NUM_NEXT;
        RAM_BANK_NUM <= RAM_BANK_NUM_NEXT;
        RAM_EN <= RAM_EN_NEXT;
    end
end

always_comb
begin
    ROM_BANK_NUM_NEXT = ROM_BANK_NUM;
    RAM_EN_NEXT = RAM_EN;
    RAM_BANK_NUM_NEXT = RAM_BANK_NUM;
    MBC5_ADDR = 0;
    MBC5_RD = 0;
    MBC5_WR = 0;
    
    ROM_BANK_NUM_ACTUAL = ROM_BANK_NUM % NUM_ROM_BANK;
    
    CART_DATA_in = MBC5_DATA_in;
    MBC5_DATA_out = CART_DATA_out;

    if (CART_ADDR < 16'h4000 && CART_RD) // ROM Bank 0 (READ ONLY)
    begin
        MBC5_ADDR = {10'b0, CART_ADDR};
        MBC5_RD = CART_RD;
    end
    else if (CART_ADDR < 16'h8000 && CART_RD) // ROM Bank N (READ ONLY)
    begin
        MBC5_ADDR = {10'b0, CART_ADDR} + (ROM_BANK_NUM_ACTUAL << 14) - 26'h4000;
        MBC5_RD = CART_RD;
    end
    else if (CART_ADDR >= 16'hA000 && CART_ADDR < 16'hC000) // RAM Bank N (READ/WRITE)
    begin
        if (RAM_EN)
        begin
            MBC5_ADDR = `SDRAM_RAM_BASE + {10'b0, CART_ADDR} - 26'hA000 + ((RAM_BANK_NUM % NUM_RAM_BANK) << 13);
            MBC5_RD = CART_RD;
            MBC5_WR = CART_WR;
        end
        else CART_DATA_in = 8'hFF;
    end
    else if (CART_ADDR < 16'h2000 && CART_WR)   // RAM enable (WRITE ONLY)
    begin
        if (CART_DATA_out[3:0] == 4'hA) RAM_EN_NEXT = 1;
        else RAM_EN_NEXT = 0;
    end
    else if (CART_ADDR >= 16'h2000 && CART_ADDR < 16'h3000 && CART_WR)  // ROMB0 (WRITE ONLY)
    begin
        ROM_BANK_NUM_NEXT = {ROM_BANK_NUM[8], CART_DATA_out[7:0]};
    end
    else if (CART_ADDR >= 16'h3000 && CART_ADDR < 16'h4000 && CART_WR)  // ROMB1 (WRITE ONLY)
    begin
        ROM_BANK_NUM_NEXT = {CART_DATA_out[0], ROM_BANK_NUM[7:0]};
    end
    else if (CART_ADDR >= 16'h4000 && CART_ADDR < 16'h6000 && CART_WR)  // RAM Bank (WRITE ONLY)
    begin
        RAM_BANK_NUM_NEXT = CART_DATA_out[3:0];
    end
end

endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// This is the MBC 1 Memory Bank Controller for The GameBoy
//////////////////////////////////////////////////////////////////////////////////

`define SDRAM_RAM_BASE 26'h2000000

module MBC1
(
    input logic clk,
    input logic reset,
    input logic [7:0] NUM_ROM_BANK, // How many ROM banks in this cartridge?
    input logic [7:0] NUM_RAM_BANK, // How many RAM banks in this cartridge?
    input logic [15:0] CART_ADDR,
    output logic [7:0] CART_DATA_in,
    input logic [7:0] CART_DATA_out,
    input logic CART_RD,
    input logic CART_WR,
    output logic [25:0] MBC1_ADDR,
    output logic MBC1_RD,
    output logic MBC1_WR,
    input logic [7:0] MBC1_DATA_in,
    output logic [7:0] MBC1_DATA_out
);

// 4 writable registers
logic [6:0] BANK_NUM, BANK_NUM_NEXT;    // {BANK2(2-bit), BANK1(5-bit)}
logic [6:0] BANK_NUM_ACTUAL;            // 0x4000-0x5FFF 0x2000-0x3FFF
logic RAM_ROM_MODE, RAM_ROM_MODE_NEXT;  // 0x6000-0x7FFF
logic RAM_EN, RAM_EN_NEXT;              // 0x0000-0x1FFF

always_ff @(posedge clk)
begin
    if (reset)
    begin
        BANK_NUM <= 0;
        RAM_ROM_MODE <= 0;
        RAM_EN <= 0;
    end
    else
    begin
        BANK_NUM <= BANK_NUM_NEXT;
        RAM_ROM_MODE <= RAM_ROM_MODE_NEXT;
        RAM_EN <= RAM_EN_NEXT;
    end
end

always_comb
begin
    BANK_NUM_NEXT = BANK_NUM;
    RAM_ROM_MODE_NEXT = RAM_ROM_MODE;
    RAM_EN_NEXT = RAM_EN;
    MBC1_ADDR = 0;
    MBC1_RD = 0;
    MBC1_WR = 0;
    BANK_NUM_ACTUAL = BANK_NUM;
    if (BANK_NUM_ACTUAL == 8'h00 || BANK_NUM_ACTUAL == 8'h20 ||
        BANK_NUM_ACTUAL == 8'h40 || BANK_NUM_ACTUAL == 8'h60  )
    begin
        BANK_NUM_ACTUAL = BANK_NUM_ACTUAL + 1;
    end
    BANK_NUM_ACTUAL = BANK_NUM_ACTUAL % NUM_ROM_BANK;
    
    CART_DATA_in = MBC1_DATA_in;
    MBC1_DATA_out = CART_DATA_out;

    if (CART_ADDR < 16'h4000 && CART_RD) // ROM Bank 0 (READ ONLY)
    begin
        MBC1_ADDR = {10'b0, CART_ADDR};
        // RAM Banking
        if (RAM_ROM_MODE)
        begin
            MBC1_ADDR = {10'b0, CART_ADDR} + ((BANK_NUM_ACTUAL[6:5]) << 19);
        end
        MBC1_RD = CART_RD;
    end
    else if (CART_ADDR < 16'h8000 && CART_RD) // ROM Bank N (READ ONLY)
    begin
        MBC1_ADDR = {10'b0, CART_ADDR} + (BANK_NUM_ACTUAL << 14) - 26'h4000;
        MBC1_RD = CART_RD;
    end
    else if (CART_ADDR >= 16'hA000 && CART_ADDR < 16'hC000) // RAM Bank N (READ/WRITE)
    begin
        if (RAM_EN)
        begin
            MBC1_ADDR = `SDRAM_RAM_BASE + {10'b0, CART_ADDR} - 26'hA000 + (RAM_ROM_MODE ? (BANK_NUM[6:5] % NUM_RAM_BANK) << 13 : 0);
            MBC1_RD = CART_RD;
            MBC1_WR = CART_WR;
        end
        else CART_DATA_in = 8'hFF;
    end
    else if (CART_ADDR < 16'h2000 && CART_WR)   // RAM enable (WRITE ONLY)
    begin
        if (CART_DATA_out[3:0] == 4'hA) RAM_EN_NEXT = 1;
        else RAM_EN_NEXT = 0;
    end
    else if (CART_ADDR >= 16'h2000 && CART_ADDR < 16'h4000 && CART_WR)  // Bank1 (WRITE ONLY)
    begin
        BANK_NUM_NEXT = {BANK_NUM[6:5], CART_DATA_out[4:0]};
    end
    else if (CART_ADDR >= 16'h4000 && CART_ADDR < 16'h6000 && CART_WR)  // Bank2 (WRITE ONLY)
    begin
        BANK_NUM_NEXT = {CART_DATA_out[1:0], BANK_NUM[4:0]};
    end
    else if (CART_ADDR >= 16'h6000 && CART_ADDR < 16'h8000 && CART_WR)  // Mode (WRITE ONLY)
    begin
        RAM_ROM_MODE_NEXT = CART_DATA_out[0];
    end
end

endmodule

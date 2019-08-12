`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// This is the MBC 3 Memory Bank Controller for The Game Boy
//////////////////////////////////////////////////////////////////////////////////

`define SDRAM_RAM_BASE 26'h2000000

module MBC3
(
    input logic clk,
    input logic reset,
    input logic [7:0] NUM_ROM_BANK, // Number of ROM banks in cartridge: 0-128
    input logic [2:0] NUM_RAM_BANK, // Number of RAM banks in cartridge: 0-4
    input logic [15:0] CART_ADDR,
    output logic [7:0] CART_DATA_in,
    input logic [7:0] CART_DATA_out,
    input logic CART_RD,
    input logic CART_WR,
    output logic [25:0] MBC3_ADDR,
    output logic MBC3_RD,
    output logic MBC3_WR,
    input logic [7:0] MBC3_DATA_in,
    output logic [7:0] MBC3_DATA_out
);

// 4 writable control registers
logic RAM_RTC_EN, RAM_RTC_EN_NEXT;              // 0x0000-0x1FFF
logic [6:0] ROM_BANK_NUM, ROM_BANK_NUM_NEXT;    // 0x2000-0x3FFF
logic [6:0] ROM_BANK_NUM_ACTUAL;
logic [1:0] RAM_BANK_NUM, RAM_BANK_NUM_NEXT;    // 0x4000-0x5FFF
logic [3:0] RTC_REG_NUM, RTC_REG_NUM_NEXT;
logic RAM_RTC_MODE, RAM_RTC_MODE_NEXT;          // 1: RAM selected; 0: RTC selected
logic LATCH_CLOCK_DATA, LATCH_CLOCK_DATA_NEXT;  // 0x6000-0x7FFF
logic LATCH_CLOCK_DATA_PREV;

// RTC registers
logic RTC_latch_EN; 
logic RTC_write;
logic [7:0] RTC_writedata;
logic [5:0] RTC_S;  // Seconds counter
logic [5:0] RTC_M;  // Minutes counter
logic [4:0] RTC_H;  // Hours counter
logic [7:0] RTC_DL; // Days counter (lower-order 8 bits)
logic [7:0] RTC_DH; // Days counter (bit7: carry; bit6: HALT; bit5-1: 0; bit0: higher-order bit)

logic RTC_clk;

RTC_clk_div RTC_clk_out(.clk(clk), .reset(reset), .clk_out(RTC_clk));

RTC_Counters MBC3_RTC_Counters(.clk(RTC_clk), .reset(reset), .latch_EN(RTC_latch_EN),
                               .write(RTC_write), .writedata(RTC_writedata), .Reg_sel(RTC_REG_NUM),
                               .RTC_S_out(RTC_S), .RTC_M_out(RTC_M), .RTC_H_out(RTC_H),
                               .RTC_DL_out(RTC_DL), .RTC_DH_out(RTC_DH));

always_ff @(posedge clk)
begin
    if (reset)
    begin
        RAM_RTC_EN <= 0;
        ROM_BANK_NUM <= 0;
        RAM_BANK_NUM <= 0;
        RTC_REG_NUM <= 0;
        LATCH_CLOCK_DATA <= 0;
        LATCH_CLOCK_DATA_PREV <= 0;
        RAM_RTC_MODE <= 0;
    end
    else
    begin
        RAM_RTC_EN <= RAM_RTC_EN_NEXT;
        ROM_BANK_NUM <= ROM_BANK_NUM_NEXT;
        RAM_BANK_NUM <= RAM_BANK_NUM_NEXT;
        RTC_REG_NUM <= RTC_REG_NUM_NEXT;
        LATCH_CLOCK_DATA <= LATCH_CLOCK_DATA_NEXT;
        LATCH_CLOCK_DATA_PREV <= LATCH_CLOCK_DATA;
        RAM_RTC_MODE <= RAM_RTC_MODE_NEXT;
    end
end

always_comb
begin
    RAM_RTC_EN_NEXT = RAM_RTC_EN;
    ROM_BANK_NUM_NEXT = ROM_BANK_NUM;
    RAM_BANK_NUM_NEXT = RAM_BANK_NUM;
    RTC_REG_NUM_NEXT = RTC_REG_NUM;
    RAM_RTC_MODE_NEXT = RAM_RTC_MODE;
    LATCH_CLOCK_DATA_NEXT = LATCH_CLOCK_DATA;
    
    MBC3_ADDR = 0;
    MBC3_RD = 0;
    MBC3_WR = 0;
    RTC_write = 0;
    RTC_writedata = 0;
    RTC_latch_EN = 0;

    // Selecting Bank 0 will select Bank 1 instead
    ROM_BANK_NUM_ACTUAL = ROM_BANK_NUM;
    if (ROM_BANK_NUM_ACTUAL == 7'h00)
        ROM_BANK_NUM_ACTUAL = 7'h01;
    ROM_BANK_NUM_ACTUAL = ROM_BANK_NUM_ACTUAL % NUM_ROM_BANK;   // put this before above statement?

    CART_DATA_in = MBC3_DATA_in;
    MBC3_DATA_out = CART_DATA_out;

    if (CART_ADDR < 16'h4000 && CART_RD)    // ROM Bank 0 (READ ONLY)
    begin
        MBC3_ADDR = {10'b0, CART_ADDR};
        MBC3_RD = CART_RD;
    end
    else if (CART_ADDR < 16'h8000 && CART_RD) // ROM Bank N (READ ONLY)
    begin
        MBC3_ADDR = {10'b0, CART_ADDR} + (ROM_BANK_NUM_ACTUAL << 14) - 26'h4000;
        MBC3_RD = CART_RD;
    end
    else if (CART_ADDR >= 16'hA000 && CART_ADDR < 16'hC000) // RAM Bank N or RTC Register (READ/WRITE)
    begin
        if (RAM_RTC_EN)  
        begin
            if (RAM_RTC_MODE)   // RAM Bank
            begin
                MBC3_ADDR = `SDRAM_RAM_BASE + {10'b0, CART_ADDR} - 26'hA000 + ((RAM_BANK_NUM % NUM_RAM_BANK) << 13);
                MBC3_RD = CART_RD;
                MBC3_WR = CART_WR;
            end
            else    // RTC Register
            begin
                if (CART_RD)
                begin
                    unique case (RTC_REG_NUM)
                        4'h8: CART_DATA_in = {2'b0, RTC_S};
                        4'h9: CART_DATA_in = {2'b0, RTC_M};
                        4'hA: CART_DATA_in = {3'b0, RTC_H};
                        4'hB: CART_DATA_in = RTC_DL;
                        4'hC: CART_DATA_in = RTC_DH;
                    endcase
                end
                else if (CART_WR)
                begin
                    RTC_write = 1;  
                    RTC_writedata = CART_DATA_out;
                end
            end
        end
        else CART_DATA_in = 8'hFF;
    end
    else if (CART_ADDR < 16'h2000 && CART_WR)   // RAM and RTC enable (WRITE ONLY)
    begin
        if (CART_DATA_out[3:0] == 4'hA) RAM_RTC_EN_NEXT = 1;
        else RAM_RTC_EN_NEXT = 0;
    end
    else if (CART_ADDR >= 16'h2000 && CART_ADDR < 16'h4000 && CART_WR)  // ROM Bank (WRITE ONLY)
    begin
        ROM_BANK_NUM_NEXT = CART_DATA_out[6:0];
    end
    else if (CART_ADDR >= 16'h4000 && CART_ADDR < 16'h6000 && CART_WR)  // RAM Bank or RTC Register (WRITE ONLY)
    begin
        if (CART_DATA_out < 8'h04) 
        begin
            RAM_RTC_MODE_NEXT = 1;
            RAM_BANK_NUM_NEXT = CART_DATA_out[1:0];
        end
        else if (CART_DATA_out >= 8'h08 && CART_DATA_out <= 8'h0C) 
        begin
            RAM_RTC_MODE_NEXT = 0;
            RTC_REG_NUM_NEXT = CART_DATA_out[3:0];
        end
    end
    else if (CART_ADDR >= 16'h6000 && CART_ADDR < 16'h8000 && CART_WR)  // Latch Clock Data (WRITE ONLY)
    begin
        LATCH_CLOCK_DATA_NEXT = CART_DATA_out[0];
        if (LATCH_CLOCK_DATA_NEXT == 1 && LATCH_CLOCK_DATA_PREV == 0)
        begin
            RTC_latch_EN = 1;
        end
    end    
end

endmodule

module RTC_Counters
(
    input logic clk,    // 2^15 = 32.768 kHz
    input logic reset,

    // write signals
    input logic write,
    input logic [7:0] writedata,
    input logic [3:0] Reg_sel,

    // read signals        
    input logic latch_EN,   // latch enable
    output logic [5:0] RTC_S_out,   // Seconds counter
    output logic [5:0] RTC_M_out,   // Minutes counter
    output logic [4:0] RTC_H_out,   // Hours counter
    output logic [7:0] RTC_DL_out,  // Days counter (lower-order 8 bits)
    output logic [7:0] RTC_DH_out   // Days counter (bit7: carry; bit6: HALT; bit5-1: 0; bit0: higher-order bit)
);

logic [14:0] counter, counter_next;
logic [5:0] RTC_S, RTC_S_next;
logic [5:0] RTC_M, RTC_M_next;
logic [4:0] RTC_H, RTC_H_next;
logic [7:0] RTC_DL, RTC_DL_next;
logic [7:0] RTC_DH, RTC_DH_next;

assign RTC_DH_next[5:1] = 5'b0;

always_ff @(posedge (clk || latch_EN || write))
begin
    if (reset)
    begin
        counter <= 0;
        RTC_S <= 0;
        RTC_M <= 0;
        RTC_H <= 0;
        RTC_DL <= 0;
        RTC_DH[7] <= 0;
        RTC_DH[6] <= 0;
        RTC_DH[0] <= 0;

        RTC_S_out <= 0;
        RTC_M_out <= 0;
        RTC_H_out <= 0;
        RTC_DL_out <= 0;
        RTC_DH_out <= 0;
    end
    else
    begin
        if (latch_EN)   // only at posedge latch_EN
        begin
            RTC_S_out <= RTC_S;
            RTC_M_out <= RTC_M;
            RTC_H_out <= RTC_H;
            RTC_DL_out <= RTC_DL;
            RTC_DH_out <= RTC_DH;
        end
        else
        begin
            if (write)
            begin
                unique case (Reg_sel)
                    4'h8: RTC_S <= writedata[5:0];
                    4'h9: RTC_M <= writedata[5:0];
                    4'hA: RTC_H <= writedata[4:0];
                    4'hB: RTC_DL <= writedata;
                    4'hC: begin RTC_DH[7:6] <= writedata[7:6]; RTC_DH[0] <= writedata[0]; end
                endcase
                counter <= 0;   // restart counter
            end
            else
            begin
                counter <= counter_next;
                RTC_S <= RTC_S_next;
                RTC_M <= RTC_M_next;
                RTC_H <= RTC_H_next;
                RTC_DL <= RTC_DL_next;
                RTC_DH[7] <= RTC_DH_next[7];
                RTC_DH[6] <= RTC_DH_next[6];
                RTC_DH[0] <= RTC_DH_next[0];
            end
        end
    end
end

always_comb
begin
    counter_next = counter;
    RTC_S_next = RTC_S;
    RTC_M_next = RTC_M;
    RTC_H_next = RTC_H;
    RTC_DL_next = RTC_DL;
    RTC_DH_next[7] = RTC_DH[7];
    RTC_DH_next[6] = RTC_DH[6];
    RTC_DH_next[0] = RTC_DH[0];

    if (!RTC_DH[6]) // when HALT is 0: counters operate
    begin
        if (counter == 15'h4)
        begin
            counter_next = 0;
            if (RTC_S == 6'd5)
            begin
                RTC_S_next = 0;
                if (RTC_M == 6'd6)
                begin
                    RTC_M_next = 0;
                    if (RTC_H == 5'd23)
                    begin
                        RTC_H_next = 0;
                        if (RTC_DL == 8'd255)
                        begin
                            RTC_DL_next = 0;
                            RTC_DH_next[0] = 1'd1;
                            if (RTC_DH[0] == 1'd1)
                                RTC_DH_next[7] = 1; // Carry bit remains set to 1 until 0 is written
                        end
                        else
                            RTC_DL_next++;
                    end
                    else 
                        RTC_H_next++;
                end
                else
                    RTC_M_next++;
            end
            else
                RTC_S_next++;
        end
        else
            counter_next++;
    end
end

endmodule

module RTC_clk_div
(
    input logic clk,        // 2^22 = 4.194304 MHz
    input logic reset,
    output logic clk_out    // 2^15 = 32.768 kHz
);

//  count to (clk/RTC_clk)/2 = 2^6 = 64
logic [5:0] count;

always_ff @(posedge clk)
begin
    if (reset)
    begin
        count <= 0;
        clk_out <= 0;
    end
    else
    begin
        if (count == 6'd63)
        begin
            count <= 0;
            clk_out <= ~clk_out;
        end
        else
            count++;
    end
end

endmodule

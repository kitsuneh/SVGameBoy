`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Timier for the Gameboy                                                       //
// Based On http://gbdev.gg8.se/wiki/articles/Timer_Obscure_Behaviour           //
//////////////////////////////////////////////////////////////////////////////////


module TIMER
(
    input logic clk,
    input logic rst,
    
    input logic [15:0] ADDR,
    input logic WR,
    input logic RD,
    input logic [7:0] MMIO_DATA_out,
    output logic [7:0] MMIO_DATA_in,
    
    output logic IRQ_TIMER
);

logic [7:0] DIV, TIMA, TMA, TAC;
logic [15:0] BIG_COUNTER, BIG_COUNTER_NEXT;
logic FALL_EDGE_TIMER_CLK;
logic TIMER_CLK_PREV, TIMER_CLK_PREV_NEXT, TIMER_CLK_NOW;
logic TIMER_OVERFLOW, TIMER_OVERFLOW_NEXT;
logic [1:0] TIMER_OVERFLOW_CNT, TIMER_OVERFLOW_CNT_NEXT;

logic [7:0] FF04;
assign FF04 = DIV;
assign DIV = BIG_COUNTER[15:8];

logic [7:0] FF05, FF05_NEXT;
assign TIMA = FF05;

logic [7:0] FF06, FF06_NEXT;
assign TMA = FF06;

logic [7:0] FF07, FF07_NEXT;
logic [7:0] TAC_PREV, TAC_PREV_NEXT, TAC_NEXT;
assign TAC = FF07;
assign TAC_NEXT = FF07_NEXT;

/* Main State Machine */
always_ff @(posedge clk)
begin
    if (rst)
    begin
        BIG_COUNTER <= 0;
        FF05 <= 0;
        FF06 <= 0;
        FF07 <= 8'hF8;
        TIMER_CLK_PREV <= 0;
        TIMER_OVERFLOW <= 0;
        TIMER_OVERFLOW_CNT <= 0;
        TAC_PREV <= 0;
    end
    else
    begin
        BIG_COUNTER <= BIG_COUNTER_NEXT;
        FF05 <= FF05_NEXT;
        FF06 <= FF06_NEXT;
        FF07 <= FF07_NEXT;
        TIMER_CLK_PREV <= TIMER_CLK_PREV_NEXT;
        TIMER_OVERFLOW <= TIMER_OVERFLOW_NEXT;
        TIMER_OVERFLOW_CNT <= TIMER_OVERFLOW_CNT_NEXT;
        TAC_PREV <= TAC_PREV_NEXT;
    end
end

always_comb
begin
    FF05_NEXT = FF05;
    FF06_NEXT = FF06;
    FF07_NEXT = FF07;
    if (WR && (ADDR == 16'hFF07)) FF07_NEXT =  MMIO_DATA_out;
    TIMER_CLK_NOW = 0;
    FALL_EDGE_TIMER_CLK = 0;
    unique case (TAC[1:0])
        2'd0: 
        begin
            TIMER_CLK_PREV_NEXT = BIG_COUNTER[9];
            TIMER_CLK_NOW = BIG_COUNTER[9];
        end
        2'd3: 
        begin
            TIMER_CLK_PREV_NEXT = BIG_COUNTER[7]; 
            TIMER_CLK_NOW = BIG_COUNTER[7];
        end
        2'd2: 
        begin
            TIMER_CLK_PREV_NEXT = BIG_COUNTER[5]; 
            TIMER_CLK_NOW = BIG_COUNTER[5];
        end
        2'd1: 
        begin
            TIMER_CLK_PREV_NEXT = BIG_COUNTER[3]; 
            TIMER_CLK_NOW = BIG_COUNTER[3];
        end
    endcase
    
    TAC_PREV_NEXT = TAC;
    FALL_EDGE_TIMER_CLK = (TIMER_CLK_PREV && !TIMER_CLK_NOW && TAC[2]) || (TIMER_CLK_PREV && !TAC_NEXT[2] && TAC[2]);
    //FALL_EDGE_TIMER_CLK = (TIMER_CLK_PREV && !TIMER_CLK_NOW && TAC[2]) || (TIMER_CLK_PREV && !TAC[2] && TAC_PREV[2]);
    //FALL_EDGE_TIMER_CLK = (!TIMER_CLK_PREV && TIMER_CLK_NOW && TAC[2]) || (!TIMER_CLK_PREV && !TAC[2] && TAC_PREV[2]);
    
    TIMER_OVERFLOW_NEXT = TIMER_OVERFLOW;
    TIMER_OVERFLOW_CNT_NEXT = TIMER_OVERFLOW_CNT;
    IRQ_TIMER = 0;
    if (FALL_EDGE_TIMER_CLK)
    begin
        FF05_NEXT = FF05 + 1; // increase TIMA when there is a falling edge of Timer clock
        if (FF05 == 8'hFF)
        begin
            TIMER_OVERFLOW_NEXT = 1; 
        end
    end
    if (TIMER_OVERFLOW) TIMER_OVERFLOW_CNT_NEXT = TIMER_OVERFLOW_CNT + 1;
    if (TIMER_OVERFLOW_CNT == 2'b11)
        TIMER_OVERFLOW_NEXT = 0;
    
    BIG_COUNTER_NEXT = (WR && (ADDR == 16'hFF04)) ? 1 : BIG_COUNTER + 1; // Reset big counter if write into FF04
    if (WR && (ADDR == 16'hFF05)) FF05_NEXT =  (TIMER_OVERFLOW_CNT == 2'b11) ? FF05 : MMIO_DATA_out;  // Latch behavior
    if (WR && (ADDR == 16'hFF06))
    begin
        FF06_NEXT =  MMIO_DATA_out;
        if (TIMER_OVERFLOW_CNT == 2'b11) // Latch behavior
        begin
            FF05_NEXT = MMIO_DATA_out;
        end
    end
    
    case (ADDR)
        16'hFF04: MMIO_DATA_in = FF04;
        16'hFF05: MMIO_DATA_in = FALL_EDGE_TIMER_CLK ? FF05_NEXT : FF05; // Since the original Timer is Latch based, increase happens at the same clock cycle
        16'hFF06: MMIO_DATA_in = FF06;
        16'hFF07: MMIO_DATA_in = {5'b11111, FF07[2:0]};
        default : MMIO_DATA_in = 8'hFF;
    endcase
    
    if (FALL_EDGE_TIMER_CLK) // When TIMA is about to overflow but writting something to it
    begin
        if (FF05 == 8'hFF && FF05_NEXT != 8'h00) TIMER_OVERFLOW_NEXT = 0; 
    end
    if (TIMER_OVERFLOW_CNT == 2'b10) FF05_NEXT = FF06_NEXT; // count 3T after overflow
    if (TIMER_OVERFLOW && TIMER_OVERFLOW_CNT == 2'b00) IRQ_TIMER = 1; // INTQ to CPU is delayed by 2T from overflow (Anywhere from 1T-4T is acceptable?)
end

endmodule

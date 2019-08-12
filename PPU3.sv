`timescale 1ns / 1ns

//`include "PPU.vh"
`define NO_BOOT 0

module PPU3
(
    input logic clk,
    input logic rst,
    
    input logic [15:0] ADDR,
    input logic WR,
    input logic RD,
    input logic [7:0] MMIO_DATA_out,
    output logic [7:0] MMIO_DATA_in,
    
    output logic IRQ_V_BLANK,
    output logic IRQ_LCDC,
    
    output logic [1:0] PPU_MODE,
    
    output logic PPU_RD,
    output logic [15:0] PPU_ADDR,
    input logic [7:0] PPU_DATA_in,
    
    output logic [1:0] PX_OUT,
    output logic PX_valid
);

logic [7:0] LCDC, STAT, SCX, SCY, LYC, DMA, BGP, OBP0, OBP1, WX, WY; // Register alias

logic [7:0] FF40, FF40_NEXT;
assign LCDC = FF40;

logic [7:0] FF41, FF41_NEXT;
assign STAT = FF41;

logic [7:0] FF42, FF42_NEXT;
assign SCY = FF42;

logic [7:0] FF43, FF43_NEXT;
assign SCX = FF43;

logic [7:0] FF44;

logic [7:0] FF45, FF45_NEXT;
assign LYC = FF45;

logic [7:0] FF46, FF46_NEXT;
assign DMA = FF46;

logic [7:0] FF47, FF47_NEXT;
assign BGP = FF47;

logic [7:0] FF48, FF48_NEXT; 
assign OBP0 = {FF48[7:2], 2'b00}; // Last 2 bits are not used

logic [7:0] FF49, FF49_NEXT;
assign OBP1 = {FF49[7:2], 2'b00};

logic [7:0] FF4A, FF4A_NEXT;
assign WY = FF4A;

logic [7:0] FF4B, FF4B_NEXT;
assign WX = FF4B;

typedef enum {OAM_SEARCH, RENDER, H_BLANK, V_BLANK} PPU_STATE_t;

PPU_STATE_t PPU_STATE, PPU_STATE_NEXT;

// Current Coordinates
logic [7:0] LX, LX_NEXT; // LX starts from 0, LCD starts from LX + SCX & 7
logic [7:0] LY, LY_NEXT;
assign FF44 = LY;


// OAM Machine
logic OAM_SEARCH_GO;
logic [15:0] OAM_SEARCH_PPU_ADDR;

// BGWD Machine
logic BGWD_RENDER_GO;
logic SHIFT_REG_GO;

// Current Rendering Tile Map Pattern Number
logic [7:0] BG_MAP;
logic [7:0] WD_MAP;
logic [7:0] SP_MAP;

// PPU Running Counter for every 60Hz refresh
shortint unsigned PPU_CNT, PPU_CNT_NEXT;
logic [2:0] SCX_CNT, SCX_CNT_NEXT;

//assign IRQ_V_BLANK = (LY == 144 && PPU_CNT == 0);

// Sprite Logic
logic isSpriteOnLine;
assign isSpriteOnLine = (((PPU_DATA_in + (LCDC[2] << 3)) > (LY + 8)) && (PPU_DATA_in <= (LY + 16)));
logic [3:0] sp_table_cnt; //sp_table_cnt_next;
logic [5:0] sp_name_table [0:9]; //logic [5:0] sp_name_table_next [0:9];
logic [7:0] sp_name_table_x [0:9]; 

genvar sp_n_gi;
generate
for (sp_n_gi = 0; sp_n_gi < 10; sp_n_gi++)
begin : sp_n_gen
    assign sp_name_table_x[sp_n_gi] = {sp_name_table[sp_n_gi], 2'b00};
end
endgenerate

logic [7:0] sp_y_table [0:9];    //logic [7:0] sp_y_table_next [0:9];
logic [7:0] sp_x_table [0:9];    //logic [7:0] sp_x_table_next [0:9];
logic sp_found; //sp_found_next; // Search Result
logic isHitSP; // is there a sprite to fetch on current X?
logic [3:0] sp_to_fetch;
logic [9:0] sp_not_used, sp_not_used_next; // which sprite has been used
logic SP_RENDER_GO;
//logic [15:0] SPRITE_PPU_ADDR;
logic [9:0] SP_SHIFT_REG_LOAD;
logic [8:0] SP_TILE_DATA0, SP_TILE_DATA1;
logic [1:0] SP_PX_MAP [9:0];
logic [3:0] SP_NEXT_SLOT, SP_NEXT_SLOT_NEXT;
logic [2:0] SP_CNT;
logic [7:0] SP_FLAG;
logic [1:0] SP_PRIPN [0:9];
logic [1:0] SP_PRIPN_NEXT [0:9];

PPU_SHIFT_REG SP_SHIFT_REG9(.clk(clk), .rst(rst), .data('{SP_TILE_DATA1, SP_TILE_DATA0}), .go(SHIFT_REG_GO), .load(SP_SHIFT_REG_LOAD[9]), .q(SP_PX_MAP[9]));
PPU_SHIFT_REG SP_SHIFT_REG8(.clk(clk), .rst(rst), .data('{SP_TILE_DATA1, SP_TILE_DATA0}), .go(SHIFT_REG_GO), .load(SP_SHIFT_REG_LOAD[8]), .q(SP_PX_MAP[8]));
PPU_SHIFT_REG SP_SHIFT_REG7(.clk(clk), .rst(rst), .data('{SP_TILE_DATA1, SP_TILE_DATA0}), .go(SHIFT_REG_GO), .load(SP_SHIFT_REG_LOAD[7]), .q(SP_PX_MAP[7]));
PPU_SHIFT_REG SP_SHIFT_REG6(.clk(clk), .rst(rst), .data('{SP_TILE_DATA1, SP_TILE_DATA0}), .go(SHIFT_REG_GO), .load(SP_SHIFT_REG_LOAD[6]), .q(SP_PX_MAP[6]));
PPU_SHIFT_REG SP_SHIFT_REG5(.clk(clk), .rst(rst), .data('{SP_TILE_DATA1, SP_TILE_DATA0}), .go(SHIFT_REG_GO), .load(SP_SHIFT_REG_LOAD[5]), .q(SP_PX_MAP[5]));
PPU_SHIFT_REG SP_SHIFT_REG4(.clk(clk), .rst(rst), .data('{SP_TILE_DATA1, SP_TILE_DATA0}), .go(SHIFT_REG_GO), .load(SP_SHIFT_REG_LOAD[4]), .q(SP_PX_MAP[4]));
PPU_SHIFT_REG SP_SHIFT_REG3(.clk(clk), .rst(rst), .data('{SP_TILE_DATA1, SP_TILE_DATA0}), .go(SHIFT_REG_GO), .load(SP_SHIFT_REG_LOAD[3]), .q(SP_PX_MAP[3]));
PPU_SHIFT_REG SP_SHIFT_REG2(.clk(clk), .rst(rst), .data('{SP_TILE_DATA1, SP_TILE_DATA0}), .go(SHIFT_REG_GO), .load(SP_SHIFT_REG_LOAD[2]), .q(SP_PX_MAP[2]));
PPU_SHIFT_REG SP_SHIFT_REG1(.clk(clk), .rst(rst), .data('{SP_TILE_DATA1, SP_TILE_DATA0}), .go(SHIFT_REG_GO), .load(SP_SHIFT_REG_LOAD[1]), .q(SP_PX_MAP[1]));
PPU_SHIFT_REG SP_SHIFT_REG0(.clk(clk), .rst(rst), .data('{SP_TILE_DATA1, SP_TILE_DATA0}), .go(SHIFT_REG_GO), .load(SP_SHIFT_REG_LOAD[0]), .q(SP_PX_MAP[0]));

// Fetch Logic
localparam OAM_BASE = 16'hFE00;
logic [15:0] VRAM_DATA_BASE;
assign VRAM_DATA_BASE = LCDC[4] ? 16'h8000 : 16'h9000; 

// LY + SCY is the effictive Y for Background, LX - 8 is the effective X for Background
// LY - WY is the effective Y for Window, LX - WX - 1 is the effective X for Window
`define GET_BG_TILE_ON_LINE_AT_x(x) (16'h9800 | {LCDC[3], 10'b0}) | {((LY + SCY) & 8'hF8), 2'b00} | (((``x + SCX) & 8'hF8) >> 3)
`define GET_xth_BG_TILE_DATA0(x) LCDC[4] ? VRAM_DATA_BASE + {``x, 4'b0} | {(LY + SCY) & 7, 1'b0} : VRAM_DATA_BASE -{``x[7], 11'b0} + {``x[6:0], 4'b0} | {(LY + SCY) & 8'h07, 1'b0}
`define GET_xth_BG_TILE_DATA1(x) LCDC[4] ? VRAM_DATA_BASE + {``x, 4'b0} | {(LY + SCY) & 7, 1'b1} : VRAM_DATA_BASE -{``x[7], 11'b0} + {``x[6:0], 4'b0} | {(LY + SCY) & 8'h07, 1'b1}
`define GET_WD_TILE_ON_LINE_AT_x(x) (16'h9800 | {LCDC[6], 10'b0}) | {((LY - WY) & 8'hF8), 2'b00}  | (((``x - WX - 1) & 8'hF8) >> 3)
`define GET_xth_WD_TILE_DATA0(x) LCDC[4] ? VRAM_DATA_BASE + {``x, 4'b0} | {(LY - WY) & 7, 1'b0} : VRAM_DATA_BASE -{``x[7], 11'b0} + {``x[6:0], 4'b0} | {(LY - WY) & 8'h07, 1'b0}
`define GET_xth_WD_TILE_DATA1(x) LCDC[4] ? VRAM_DATA_BASE + {``x, 4'b0} | {(LY - WY) & 7, 1'b1} : VRAM_DATA_BASE -{``x[7], 11'b0} + {``x[6:0], 4'b0} | {(LY - WY) & 8'h07, 1'b1}
`define GET_xth_SP_TILE_DATA0(x) SP_FLAG[6] ? 16'h8000 + ({``x, 4'b0} | (((8 + (LCDC[2] << 3) + sp_y_table[sp_to_fetch] - LY - 16 - 1) & 15) << 1)) : 16'h8000 + ({``x, 4'b0} | (((LY + 16 - sp_y_table[sp_to_fetch]) & 15) << 1))
`define GET_xth_SP_TILE_DATA1(x) SP_FLAG[6] ? 16'h8000 + ({``x, 4'b0} | (((8 + (LCDC[2] << 3) + sp_y_table[sp_to_fetch] - LY - 16 - 1) & 15) << 1)) + 1 : 16'h8000 + ({``x, 4'b0} | (((LY + 16 - sp_y_table[sp_to_fetch]) & 15) << 1)) + 1

logic isHitWD;

// Fetched Data
logic [15:0] BGWD_PPU_ADDR;
//logic bgwd_to_fetch;
logic [2:0] BGWD_CNT;
logic [7:0] BGWD_MAP;
logic [7:0] BGWD_TILE_DATA0, BGWD_TILE_DATA1;
logic isFetchWD, isFetchWD_NEXT;
logic FIRST_FETCH_WD_DONE, FIRST_FETCH_WD_DONE_NEXT;
logic [1:0] BGWD_PX_MAP_A, BGWD_PX_MAP_B;
logic BGWD_SHIFT_REG_SEL, BGWD_SHIFT_REG_SEL_NEXT; // 0 selects A, 1 selects B, selected shift register will run, unselected one will load
logic [1:0] BGWD_SHIFT_REG_LOAD;

PPU_SHIFT_REG BGWD_SHIFT_REG_A (.clk(clk), .rst(rst), .data('{BGWD_TILE_DATA1, BGWD_TILE_DATA0}), .go(SHIFT_REG_GO && !BGWD_SHIFT_REG_SEL), .load(BGWD_SHIFT_REG_LOAD[0]), .q(BGWD_PX_MAP_A));
PPU_SHIFT_REG BGWD_SHIFT_REG_B (.clk(clk), .rst(rst), .data('{BGWD_TILE_DATA1, BGWD_TILE_DATA0}), .go(SHIFT_REG_GO && BGWD_SHIFT_REG_SEL), .load(BGWD_SHIFT_REG_LOAD[1]), .q(BGWD_PX_MAP_B));

// Display Logic

logic [1:0] BGWD_PX_MAP;
assign BGWD_PX_MAP = BGWD_SHIFT_REG_SEL ? BGWD_PX_MAP_B : BGWD_PX_MAP_A;
logic [1:0] BGWD_PX_DATA;

assign BGWD_PX_DATA = {BGP[{BGWD_PX_MAP, 1'b1}],BGP[{BGWD_PX_MAP, 1'b0}]};

always_comb
begin
    PX_OUT = BGWD_PX_DATA;
    if (LCDC[1]) // Sprite Display?
    begin
        for (int i = 9 ; i > -1 ; i --)
        begin
            if (SP_PRIPN[i][1] && (SP_PX_MAP[i] != 2'b00)) // SP below BGWD
            begin
                PX_OUT = SP_PRIPN[i][0] ? {OBP1[{SP_PX_MAP[i], 1'b1}], OBP1[{SP_PX_MAP[i], 1'b0}]} : {OBP0[{SP_PX_MAP[i], 1'b1}], OBP0[{SP_PX_MAP[i], 1'b0}]};
            end
        end
     end
     if (LCDC[0]) // BG Display?
     begin
        PX_OUT = (BGWD_PX_MAP == 2'b00) ? PX_OUT : BGWD_PX_DATA;
     end
     if (LCDC[1]) // Sprite Display?
     begin
        for (int i = 9 ; i > -1 ; i --)
        begin
            if (!SP_PRIPN[i][1] && (SP_PX_MAP[i] != 2'b00)) // SP above BGWD
            begin
                PX_OUT = SP_PRIPN[i][0] ? {OBP1[{SP_PX_MAP[i], 1'b1}], OBP1[{SP_PX_MAP[i], 1'b0}]} : {OBP0[{SP_PX_MAP[i], 1'b1}], OBP0[{SP_PX_MAP[i], 1'b0}]};
            end
        end
     end
end


logic BGWD_SHIFT_REG_A_VALID, BGWD_SHIFT_REG_A_VALID_NEXT;
logic BGWD_SHIFT_REG_B_VALID, BGWD_SHIFT_REG_B_VALID_NEXT;

logic [2:0] RENDER_CNT, RENDER_CNT_NEXT;

/* STAT Interrupts */
logic IRQ_STAT, IRQ_STAT_NEXT; // The Internal IRQ signal, IRQ LCDC Triggered on the rising edge of this

always_ff @(posedge clk)
begin
    if (rst) IRQ_STAT <= 0;
    else IRQ_STAT <= IRQ_STAT_NEXT;
end

always_comb
begin
IRQ_STAT_NEXT = (FF41_NEXT[6] && LY == LYC) ||
                (FF41_NEXT[3] && PPU_STATE == H_BLANK) ||
                (FF41_NEXT[5] && PPU_STATE == OAM_SEARCH) ||
                ((FF41_NEXT[4] || FF41_NEXT[5]) && PPU_STATE == V_BLANK);
IRQ_STAT_NEXT = IRQ_STAT_NEXT & LCDC[7];
end

assign IRQ_LCDC = IRQ_STAT_NEXT && !IRQ_STAT;

/* Register State Machine */
always_ff @(posedge clk)
begin
    if (rst)
    begin
        FF40 <= `NO_BOOT ? 8'h91 : 0;
        FF41 <= 0;
        FF42 <= 0;
        FF43 <= 0;
        FF45 <= 0;
        FF46 <= 0;
        FF47 <= `NO_BOOT ? 8'hFC : 0;
        FF48 <= `NO_BOOT ? 8'hFF : 0;
        FF49 <= `NO_BOOT ? 8'hFF : 0;
        FF4A <= 0; 
        FF4B <= 0;  
    end
    else
    begin
        FF40 <= FF40_NEXT;
        FF41 <= FF41_NEXT;
        FF42 <= FF42_NEXT;
        FF43 <= FF43_NEXT;
        FF45 <= FF45_NEXT;
        FF46 <= FF46_NEXT;
        FF47 <= FF47_NEXT;
        FF48 <= FF48_NEXT;
        FF49 <= FF49_NEXT;
        FF4A <= FF4A_NEXT;
        FF4B <= FF4B_NEXT;
    end
end

always_comb
begin
    FF40_NEXT = (WR && (ADDR == 16'hFF40)) ? MMIO_DATA_out : FF40;
    FF41_NEXT = (WR && (ADDR == 16'hFF41)) ? {MMIO_DATA_out[7:3], FF41[2:0]} : {FF41[7:3], LYC == LY, PPU_MODE};
    FF42_NEXT = (WR && (ADDR == 16'hFF42)) ? MMIO_DATA_out : FF42;
    FF43_NEXT = (WR && (ADDR == 16'hFF43)) ? MMIO_DATA_out : FF43;
    FF45_NEXT = (WR && (ADDR == 16'hFF45)) ? MMIO_DATA_out : FF45;
    FF46_NEXT = (WR && (ADDR == 16'hFF46)) ? MMIO_DATA_out : FF46;
    FF47_NEXT = (WR && (ADDR == 16'hFF47)) ? MMIO_DATA_out : FF47;
    FF48_NEXT = (WR && (ADDR == 16'hFF48)) ? MMIO_DATA_out : FF48;
    FF49_NEXT = (WR && (ADDR == 16'hFF49)) ? MMIO_DATA_out : FF49;
    FF4A_NEXT = (WR && (ADDR == 16'hFF4A)) ? MMIO_DATA_out : FF4A;
    FF4B_NEXT = (WR && (ADDR == 16'hFF4B)) ? MMIO_DATA_out : FF4B;
    case (ADDR)
        16'hFF40: MMIO_DATA_in = FF40;
        16'hFF41: MMIO_DATA_in = {1'b1, FF41[6:0]};
        16'hFF42: MMIO_DATA_in = FF42;
        16'hFF43: MMIO_DATA_in = FF43;
        16'hFF44: MMIO_DATA_in = FF44;
        16'hFF45: MMIO_DATA_in = FF45;
        16'hFF46: MMIO_DATA_in = FF46;
        16'hFF47: MMIO_DATA_in = FF47;
        16'hFF48: MMIO_DATA_in = FF48;
        16'hFF49: MMIO_DATA_in = FF49;
        16'hFF4A: MMIO_DATA_in = FF4A;
        16'hFF4B: MMIO_DATA_in = FF4B;
        default : MMIO_DATA_in = 8'hFF;
    endcase
end
 
 /* PPU State Machine */
always_ff @(posedge clk)
begin
    if (rst)
    begin  
        PPU_STATE <= V_BLANK;
        LX <= 0;
        LY <= 8'h91;
        PPU_CNT <= 0;
        
        sp_not_used <= 10'b11_1111_1111;
        SCX_CNT <= 0;
        isFetchWD <= 0;
        FIRST_FETCH_WD_DONE <= 0;
        
        BGWD_SHIFT_REG_SEL <= 0;
        BGWD_SHIFT_REG_A_VALID <= 0;
        BGWD_SHIFT_REG_B_VALID <= 0;
        
        RENDER_CNT <= 0;
        
        SP_NEXT_SLOT <= 0;
        
        for (int i = 0; i < 10; i++) SP_PRIPN[i] <= 0;
    end
    
    else
    begin
        PPU_STATE <= PPU_STATE_NEXT;
        LX <= LX_NEXT;
        LY <= LY_NEXT;
        PPU_CNT <= PPU_CNT_NEXT;
        
        sp_not_used <= sp_not_used_next;
        SCX_CNT <= SCX_CNT_NEXT;
        
        isFetchWD <= isFetchWD_NEXT;
        FIRST_FETCH_WD_DONE <= FIRST_FETCH_WD_DONE_NEXT;
        
        BGWD_SHIFT_REG_SEL <= BGWD_SHIFT_REG_SEL_NEXT;
        BGWD_SHIFT_REG_A_VALID <= BGWD_SHIFT_REG_A_VALID_NEXT;
        BGWD_SHIFT_REG_B_VALID <= BGWD_SHIFT_REG_B_VALID_NEXT;
        
        RENDER_CNT <= RENDER_CNT_NEXT;
        
        SP_NEXT_SLOT <= SP_NEXT_SLOT_NEXT;
        
        for (int i = 0; i < 10; i++) SP_PRIPN[i] <= SP_PRIPN_NEXT[i];
        
    end
end

always_comb
begin
    // Registers Defualts
    PPU_STATE_NEXT = PPU_STATE;
    LX_NEXT = LX;
    LY_NEXT = LY;
    PPU_CNT_NEXT = PPU_CNT;
    
    
    SCX_CNT_NEXT = SCX_CNT;
    
    sp_not_used_next = sp_not_used;
    
    isFetchWD_NEXT = isFetchWD;
    FIRST_FETCH_WD_DONE_NEXT = FIRST_FETCH_WD_DONE;
    
    BGWD_SHIFT_REG_SEL_NEXT = BGWD_SHIFT_REG_SEL;
    BGWD_SHIFT_REG_A_VALID_NEXT = BGWD_SHIFT_REG_A_VALID;
    BGWD_SHIFT_REG_B_VALID_NEXT = BGWD_SHIFT_REG_B_VALID;
    
    RENDER_CNT_NEXT = RENDER_CNT;
    
    SP_NEXT_SLOT_NEXT = SP_NEXT_SLOT;
    
    for (int i = 0; i < 10; i++) SP_PRIPN_NEXT[i] = SP_PRIPN[i];
    
    // Combinational Defaults
    PPU_ADDR = 0;
    PPU_RD = 0; 
    PPU_MODE = 2'b01; // VBLANK
    
    OAM_SEARCH_GO = 0;
    BGWD_RENDER_GO = 0;
    
    isHitWD = (WY <= LY) && (LX == WX + 1) && LCDC[5];
    
    SP_RENDER_GO = 0;
    SP_SHIFT_REG_LOAD = 0;
    
    SHIFT_REG_GO = 0;
    BGWD_SHIFT_REG_LOAD = 2'b00;
    
    PX_valid = 0;
    
    IRQ_V_BLANK = 0;
    
    if (LCDC[7]) // LCD Enable
    begin
        PPU_CNT_NEXT = PPU_CNT + 1;
        unique case (PPU_STATE)
            OAM_SEARCH:
            begin
                PPU_MODE = 2'b10;
                PPU_RD = 1;
                OAM_SEARCH_GO = 1;
                PPU_ADDR = PPU_CNT[0] ? OAM_BASE + (PPU_CNT << 1) - 1 : OAM_BASE + (PPU_CNT << 1);
                sp_not_used_next = 10'b11_1111_1111;
                if (PPU_CNT == 79) PPU_STATE_NEXT = RENDER;
            end  
            
            RENDER:
            begin
                PPU_MODE = 2'b11;
                PPU_RD = 1;
                if (isHitWD && !isFetchWD)
                begin
                    RENDER_CNT_NEXT = 0;
                    BGWD_SHIFT_REG_A_VALID_NEXT = 0;
                    BGWD_SHIFT_REG_B_VALID_NEXT = 0;
                    isFetchWD_NEXT = 1;
                end
                else if ((!BGWD_SHIFT_REG_A_VALID || !BGWD_SHIFT_REG_B_VALID) && RENDER_CNT <= 6)
                begin
                    BGWD_RENDER_GO = 1;
                    if (!isFetchWD)
                    begin
                        unique case (BGWD_CNT)
                            0: PPU_ADDR = `GET_BG_TILE_ON_LINE_AT_x(LX);
                            1: PPU_ADDR = `GET_xth_BG_TILE_DATA0(BGWD_MAP);
                            2: PPU_ADDR = `GET_xth_BG_TILE_DATA1(BGWD_MAP);
                            3,4,5:;
                        endcase
                    end
                    else
                    begin
                        unique case (BGWD_CNT)
                            0: PPU_ADDR = `GET_WD_TILE_ON_LINE_AT_x(LX + {FIRST_FETCH_WD_DONE, 3'b00});
                            1: PPU_ADDR = `GET_xth_WD_TILE_DATA0(BGWD_MAP);
                            2: PPU_ADDR = `GET_xth_WD_TILE_DATA1(BGWD_MAP);
                            3,4,5:;
                        endcase
                    end
                    if (BGWD_CNT == (5 & {2'b11, !isHitSP})) // Why sprite will only stall 5 - LX & 7 ?
                    begin
                        if (BGWD_SHIFT_REG_SEL) 
                        begin
                            BGWD_SHIFT_REG_A_VALID_NEXT = 1;
                            BGWD_SHIFT_REG_LOAD[0] = 1;
                        end
                        else
                        begin
                            BGWD_SHIFT_REG_B_VALID_NEXT = 1;
                            BGWD_SHIFT_REG_LOAD[1] = 1;
                        end
                        if (!BGWD_SHIFT_REG_A_VALID && !BGWD_SHIFT_REG_B_VALID) BGWD_SHIFT_REG_SEL_NEXT = !BGWD_SHIFT_REG_SEL;
                        if (isFetchWD) FIRST_FETCH_WD_DONE_NEXT = 1;
                    end 
                end
                else if (isHitSP)
                begin
                    SP_RENDER_GO = 1;
                    unique case (SP_CNT)
                        0: PPU_ADDR = OAM_BASE + sp_name_table_x[sp_to_fetch] + 2; // Get Pattern Number
                        1: PPU_ADDR = OAM_BASE + sp_name_table_x[sp_to_fetch] + 3; // Get Attributes
                        2,3: PPU_ADDR = `GET_xth_SP_TILE_DATA0(LCDC[2] ? {SP_MAP[7:1], 1'b0} : SP_MAP);
                        4,5: PPU_ADDR = `GET_xth_SP_TILE_DATA1(LCDC[2] ? {SP_MAP[7:1], 1'b0} : SP_MAP);
                    endcase
                    if (SP_CNT == 5)
                    begin
                        sp_not_used_next[sp_to_fetch] = 0;
                        SP_SHIFT_REG_LOAD[SP_NEXT_SLOT] = 1;
                        SP_PRIPN_NEXT[SP_NEXT_SLOT] = {SP_FLAG[7], SP_FLAG[4]};
                        SP_NEXT_SLOT_NEXT = SP_NEXT_SLOT + 1;
                    end
                end
                
                if ((BGWD_SHIFT_REG_A_VALID || BGWD_SHIFT_REG_B_VALID) && !isHitSP && !(isHitWD && !isFetchWD))
                begin
                    RENDER_CNT_NEXT = RENDER_CNT + 1;
                    SHIFT_REG_GO = 1;
                    
                    if (SCX_CNT != (SCX & 7)) SCX_CNT_NEXT = SCX_CNT + 1;
                    else
                    begin
                        LX_NEXT = LX + 1;
                        if (LX >= 8)
                            PX_valid = 1; // On screen
                    end
                    
                    if (RENDER_CNT == 7)
                    begin
                        BGWD_SHIFT_REG_SEL_NEXT = !BGWD_SHIFT_REG_SEL;
                        if (BGWD_SHIFT_REG_SEL == 0) BGWD_SHIFT_REG_A_VALID_NEXT = 0;
                        else BGWD_SHIFT_REG_B_VALID_NEXT = 0;
                    end
                end
                
                if(LX_NEXT == 160 + 8) // Start of Horizontal Blank 
                begin
                    PPU_STATE_NEXT = H_BLANK;
                    isFetchWD_NEXT = 0;
                    FIRST_FETCH_WD_DONE_NEXT = 0;
                    BGWD_SHIFT_REG_A_VALID_NEXT = 0;
                    BGWD_SHIFT_REG_B_VALID_NEXT = 0;
                    RENDER_CNT_NEXT = 0;
                    sp_not_used_next = 10'b11_1111_1111;
                    SP_NEXT_SLOT_NEXT = 0;
                    SCX_CNT_NEXT = 0;
                end 
            end
            
            H_BLANK:
            begin
                PPU_MODE = 2'b00;
                if (PPU_CNT == 455) // end of line
                begin
                    LY_NEXT = LY + 1;
                    LX_NEXT = 0;
                    PPU_CNT_NEXT = 0;
                    PPU_STATE_NEXT = OAM_SEARCH;
                    if (LY_NEXT == 144)
                    begin
                        PPU_STATE_NEXT = V_BLANK;
                        IRQ_V_BLANK = 1;
                    end
                end
            end
    
            V_BLANK:
            begin
                PPU_MODE = 2'b01;
                /*
                " Line 153 takes only a few clocks to complete (the exact timings are below). The rest of
                the clocks of line 153 are spent in line 0 in mode 1! "
                */
                if (LY == 153)
                begin
                    LY_NEXT = 0; 
                    LX_NEXT = 0;
                end
                if (PPU_CNT == 455 && LY != 0) // end of line
                begin
                    LY_NEXT = LY + 1;
                    PPU_CNT_NEXT = 0;
                end
                if (PPU_CNT == 455 && LY == 0)
				begin
					PPU_STATE_NEXT = OAM_SEARCH; // end of Vertical Blank
					PPU_CNT_NEXT = 0;
				end
            end
        endcase
    end
    else // LCD is off
    begin
        PPU_MODE = 2'b00;
        LY_NEXT = 0;
        LX_NEXT = 0;
        PPU_CNT_NEXT = 0;
        PPU_STATE_NEXT = OAM_SEARCH;
        PPU_CNT_NEXT = 0;
    end
end

/* OAM Serach Machine */
always_ff @(posedge clk)
begin
    if (rst || PPU_STATE == H_BLANK) // reset at the end of the scanline
    begin
        sp_table_cnt <= 0;
        sp_found <= 0;
        for (int i = 0; i < 10; i ++)
        begin
            sp_y_table[i] <= 8'hFF;
            sp_x_table[i] <= 8'hFF;
        end
    end
    else if (OAM_SEARCH_GO)
    begin
        if (!PPU_CNT[0]) // even cycles
        begin
            if (isSpriteOnLine && (sp_table_cnt < 10))
            begin
                sp_table_cnt <= (sp_table_cnt + 1);
                sp_name_table[sp_table_cnt] <= (PPU_CNT >> 1);
                sp_y_table[sp_table_cnt] <= PPU_DATA_in;
                sp_found <= 1;
            end
        end
        else // odd cycles
        begin
            if (sp_found)
            begin
                sp_x_table[sp_table_cnt - 1] <= PPU_DATA_in;
            end
            sp_found <= 0;
        end
    end
end
        
/* BGWD Machine */
always_ff @(posedge clk)
begin
    if (rst || !BGWD_RENDER_GO)
    begin
        BGWD_CNT <= 0;
        BGWD_TILE_DATA0 <= 0;
        BGWD_TILE_DATA1 <= 0;
        BGWD_MAP <= 0;
    end
    else
    begin
        BGWD_CNT <= BGWD_CNT == 5 ? 0 : BGWD_CNT + 1;
        unique case (BGWD_CNT)
            0: BGWD_MAP <= PPU_DATA_in;
            1: BGWD_TILE_DATA0 <= PPU_DATA_in;
            2: BGWD_TILE_DATA1 <= PPU_DATA_in;
            3,4,5:;
        endcase
    end
end

/* Sprite Machine */
always_ff @(posedge clk)
begin
    if (rst || PPU_STATE == H_BLANK) // reset at the end of the scanline
    begin
        SP_CNT <= 0;
        SP_TILE_DATA0 <= 0;
        SP_TILE_DATA1 <= 0;
        SP_MAP <= 0;
        SP_FLAG <= 0; 
    end
    else if (SP_RENDER_GO)
    begin
        SP_CNT <= (SP_CNT == 5) ? 0 : SP_CNT + 1;
        unique case (SP_CNT)
            0: SP_MAP <= PPU_DATA_in;
            1: SP_FLAG <= PPU_DATA_in;
            //2,3: if (!SP_FLAG[5]) SP_TILE_DATA0 <= PPU_DATA_in; else SP_TILE_DATA0 <= {<<{PPU_DATA_in}};
            //4,5: if (!SP_FLAG[5]) SP_TILE_DATA1 <= PPU_DATA_in; else SP_TILE_DATA1 <= {<<{PPU_DATA_in}};
            2: if (!SP_FLAG[5]) SP_TILE_DATA0 <= PPU_DATA_in; else SP_TILE_DATA0 <= {PPU_DATA_in[0], PPU_DATA_in[1], PPU_DATA_in[2], PPU_DATA_in[3], PPU_DATA_in[4], PPU_DATA_in[5], PPU_DATA_in[6], PPU_DATA_in[7]};
            4: if (!SP_FLAG[5]) SP_TILE_DATA1 <= PPU_DATA_in; else SP_TILE_DATA1 <= {PPU_DATA_in[0], PPU_DATA_in[1], PPU_DATA_in[2], PPU_DATA_in[3], PPU_DATA_in[4], PPU_DATA_in[5], PPU_DATA_in[6], PPU_DATA_in[7]};
            3,5:;
        endcase
    end
end

always_comb
begin
    isHitSP = 0;
    sp_to_fetch = 0;
    if (LCDC[1])
    begin
        for (int i = 9; i >= 0; i--)
        begin
            if (sp_x_table[i] == LX && sp_not_used[i])
            begin 
                isHitSP = 1;
                sp_to_fetch = i;
            end
        end
    end
end

endmodule

module PPU_SHIFT_REG
(
    input clk,
    input rst,
    input logic [7:0] data [1:0],
    input logic go,
    input logic load,
    output logic [1:0] q
);

logic [7:0] shift_reg [0:1];

always_ff @(posedge clk)
begin
    if (rst)
    begin
        shift_reg[0] <= 0;
        shift_reg[1] <= 0;
    end
    else if (load)
    begin
        shift_reg[0] <= data[0];
        shift_reg[1] <= data[1];
    end
    else
    begin
        if (go)
        begin
            shift_reg[0][7:1] <= shift_reg[0][6:0];
            shift_reg[0][0] <= 0;
            shift_reg[1][7:1] <= shift_reg[1][6:0];
            shift_reg[1][0] <= 0;
        end
    end
end

assign q = {shift_reg[1][7], shift_reg[0][7]};
        
endmodule
    

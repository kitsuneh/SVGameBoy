`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
/*
    This is the functional block of Sharp LR35902 AKA DMG-CPU 
    Clock Frequency: 4194304(2^22) Hz
    Machine Cycle:   1048576(2^20) Hz
    Port naming based on Gameboy1-cpuboard.gif
*/
//////////////////////////////////////////////////////////////////////////////////
`define NO_BOOT 0

// All tristate signals are redesigned to be separate in/out
module LR35902
(
    input logic clk,   // XTAL
    input logic rst, // Power On Reset
    /* Video SRAM */
    input logic [7:0] MD_in,   // video sram data
    output logic [7:0] MD_out, // video sram data
    output logic [12:0] MA,
    output logic MWR, // high active
    output logic MCS, // high active
    output logic MOE, // high active
    /* LCD */
    output logic [1:0] LD, // PPU DATA 1-0
    output logic PX_VALID,
    output logic CPG, // CONTROL
    output logic CP, // CLOCK
    output logic ST, // HORSYNC
    output logic CPL, // DATALCH
    output logic FR, // ALTSIGL
    output logic S, // VERTSYN
    /* Joy Pads */
    input logic P10,
    input logic P11,
    input logic P12,
    input logic P13,
    output logic P14,
    output logic P15,
    /* Serial Link */
    output logic S_OUT,
    input logic S_IN,
    input logic SCK_in, // serial link clk in
    output logic SCK_out, // serial link clk out
    /* Work RAM/Cartridge */
    output logic CLK_GC, // Game Cartridge Clock
    output logic WR, // high active
    output logic RD, // high active
    output logic CS, // high active
    output logic [15:0] A,
    input logic [7:0] D_in, // work ram/cartridge data bus
    output logic [7:0] D_out, // work ram/cartridge data bus
    /* Audio */
    output logic [15:0] LOUT,
    output logic [15:0] ROUT    
);

/* GB-Z80 CPU */

logic [7:0] GB_Z80_D_in;
logic [7:0] GB_Z80_D_out;
logic [15:0] GB_Z80_ADDR;
logic GB_Z80_RD, GB_Z80_WR;
logic GB_Z80_HALT;
logic [4:0] GB_Z80_INTQ;

GB_Z80_SINGLE GB_Z80_CPU(.clk(clk), .rst(rst), .ADDR(GB_Z80_ADDR), .DATA_in(GB_Z80_D_in), .DATA_out(GB_Z80_D_out), 
                         .RD(GB_Z80_RD), .WR(GB_Z80_WR), .CPU_HALT(GB_Z80_HALT), .INTQ(GB_Z80_INTQ));

/* Begin Peripherals for GB-Z80 */

/* ROM Region $0x0000 to 0x7FFF*/

// The Boot Rom is mapped from $0x0000 to $0x00FF if $0xFF50 is not written before
logic brom_en, brom_en_next;
logic [7:0] DATA_BROM;
brom boot_rom(.addr(GB_Z80_ADDR[7:0]), .data(DATA_BROM), .clk(~clk));

/* Video RAM Region $0x8000 to $0x9FFF */


/* Cartridge RAM Region $0xA000 to $0xBFFF */


/* Work RAM Region $0xC000 to $0xDFFF */ /* Echo RAM Region $0xE000 to $0xFDFF */


/* OAM Region $0xFE00 to $0xFE9F */ /* Reserved Unusable Region $0xFEA0 to $0xFEFF */
logic OAM_WR; 
logic [7:0] DATA_OAM_in;
logic [7:0] DATA_OAM_out;
logic [7:0] OAM_ADDR;
Quartus_single_port_ram_160 OAM(.q(DATA_OAM_in), .addr(OAM_ADDR), .clk(~clk), .we(OAM_WR), .data(DATA_OAM_out));


/* Hardware I0 Register Region $0xFF00 to $0xFF4B */
logic [7:0] FF00, FF00_NEXT;
assign P15 = FF00[5];
assign P14 = FF00[4];
logic [7:0] FF0F, FF0F_NEXT; // Interrupt Flag

// Serial
logic MMIO_SERIAL_WR, MMIO_SERIAL_RD;
logic [7:0] MMIO_SERIAL_DATA_in, MMIO_SERIAL_DATA_out;
logic IRQ_SERIAL;

Serial GB_SERIAL(.clk(clk), .reset(rst), .addr(GB_Z80_ADDR), .write(MMIO_SERIAL_WR), .read(MMIO_SERIAL_RD), 
                .dout(MMIO_SERIAL_DATA_in), .din(MMIO_SERIAL_DATA_out), .SCK_in(SCK_in), .SCK_out(SCK_out),
                .S_IN(S_IN), .S_OUT(S_OUT), .S_INTERRUPT(IRQ_SERIAL));

// Sound
logic MMIO_SOUND_WR, MMIO_SOUND_RD;
logic [7:0] MMIO_SOUND_DATA_in, MMIO_SOUND_DATA_out;

SOUND2 GB_SOUND(.clk(!clk), .rst(rst), .ADDR(GB_Z80_ADDR), .WR(MMIO_SOUND_WR), .RD(MMIO_SOUND_RD), .MMIO_DATA_out(MMIO_SOUND_DATA_out),
               .MMIO_DATA_in(MMIO_SOUND_DATA_in), .SOUND_LEFT(LOUT), .SOUND_RIGHT(ROUT));

// Timer
logic MMIO_TIMER_WR, MMIO_TIMER_RD;
logic [7:0] MMIO_TIMER_DATA_in, MMIO_TIMER_DATA_out;
logic IRQ_TIMER;
TIMER GB_TIMER (.clk(clk), .rst(rst), .ADDR(GB_Z80_ADDR), .WR(MMIO_TIMER_WR), .RD(MMIO_TIMER_RD), .MMIO_DATA_out(MMIO_TIMER_DATA_out),
                .MMIO_DATA_in(MMIO_TIMER_DATA_in), .IRQ_TIMER(IRQ_TIMER));

// DMA Controller
logic [7:0] FF46;
logic [7:0] DMA_ADDR, DMA_ADDR_NEXT;
logic [7:0] DMA_SETUP_ADDR, DMA_SETUP_ADDR_NEXT;
logic [2:0] DMA_SETUP_CNT, DMA_SETUP_CNT_NEXT;
logic DMA_SETUP, DMA_SETUP_NEXT;
typedef enum {DMA_IDLE, DMA_GO} DMA_STATE_t;
DMA_STATE_t DMA_STATE, DMA_STATE_NEXT;
logic [9:0] DMA_CNT, DMA_CNT_NEXT;

/* Reserved Unusable Region $0xFF4C to $0xFF7F */


/* High RAM Region $0xFF80 to $0xFFFE */ 

/* Interrupt Enable Register $0xFFFF */
logic [7:0] FFFF, FFFF_NEXT;

assign GB_Z80_INTQ = (DMA_STATE == DMA_GO) ? 0 : FFFF_NEXT[4:0] & FF0F_NEXT[4:0]; 

logic HRAM_WR;
logic [7:0] DATA_HRAM_in;
logic [7:0] DATA_HRAM_out;
Quartus_single_port_ram_128 HRAM(.q(DATA_HRAM_in), .addr(GB_Z80_ADDR[6:0]), .clk(~clk), .we(HRAM_WR), .data(DATA_HRAM_out));

/* PPU */
logic MMIO_PPU_WR, MMIO_PPU_RD;
logic [7:0] MMIO_PPU_DATA_in, MMIO_PPU_DATA_out;
logic IRQ_V_BLANK, IRQ_LCDC;
logic [1:0] PPU_MODE;
logic PPU_RD;
logic [7:0] PPU_DATA_in;
logic [15:0] PPU_ADDR;
PPU3 GB_PPU(.clk(clk), .rst(rst), .ADDR(GB_Z80_ADDR), .WR(MMIO_PPU_WR), .RD(MMIO_PPU_RD), .MMIO_DATA_out(MMIO_PPU_DATA_out), 
            .MMIO_DATA_in(MMIO_PPU_DATA_in), .IRQ_V_BLANK(IRQ_V_BLANK), .IRQ_LCDC(IRQ_LCDC), .PPU_MODE(PPU_MODE),
            .PPU_ADDR(PPU_ADDR), .PPU_RD(PPU_RD), .PPU_DATA_in(PPU_DATA_in), .PX_OUT(LD), .PX_valid(PX_VALID));


/* Memory Management Unit */
// Map the CPU Memory Address to correct Peripheral Address
always_ff @(posedge clk)
begin
    if (rst)
    begin
        brom_en <= `NO_BOOT ? 0 : 1;
        FF00 <= 8'hCF;
        FF0F <= 8'hE0;
        FFFF <= 8'h00;
        
        DMA_ADDR <= 0;
        DMA_STATE <= DMA_IDLE;
        DMA_CNT <= 0;
        DMA_SETUP_CNT <= 0;
        DMA_SETUP_ADDR <= 0;
        DMA_SETUP <= 0;
    end
    else
    begin
        brom_en <= brom_en_next;
        FF00 <= FF00_NEXT;
        FF0F <= FF0F_NEXT;
        FFFF <= FFFF_NEXT;
        
        DMA_STATE <= DMA_STATE_NEXT;
        DMA_CNT <= DMA_CNT_NEXT;
        DMA_ADDR <= DMA_ADDR_NEXT;
        DMA_SETUP_CNT <= DMA_SETUP_CNT_NEXT;
        DMA_SETUP_ADDR <= DMA_SETUP_ADDR_NEXT;
        DMA_SETUP <= DMA_SETUP_NEXT;
    end
end


always_comb
begin
    GB_Z80_D_in = 8'hFF; 
    MWR = 0; MOE = 0; MCS = 0;
    MD_out = 0;
    MA = 0;
    A = 0;
    D_out = 0;
    WR = 0; RD = 0; CS = 0;
    HRAM_WR = 0; OAM_WR = 0; 
    DATA_HRAM_out = 8'hFF;
    DATA_OAM_out = 8'hFF;
    brom_en_next = brom_en;
    OAM_ADDR = GB_Z80_ADDR[7:0];
    MMIO_PPU_WR = 0; MMIO_PPU_RD = 0; MMIO_PPU_DATA_out = 8'hFF;
    PPU_DATA_in = 8'hFF;
    MMIO_TIMER_WR = 0; MMIO_TIMER_RD = 0; MMIO_TIMER_DATA_out = 8'hFF;
    MMIO_SOUND_WR = 0; MMIO_SOUND_RD = 0; MMIO_SOUND_DATA_out = 8'hFF;
    MMIO_SERIAL_WR = 0; MMIO_SERIAL_RD = 0; MMIO_SERIAL_DATA_out = 8'hFF;
    
    /* Interrupt Register */
    FF00_NEXT = FF00;
    FF0F_NEXT = FF0F;
    if (IRQ_V_BLANK) FF0F_NEXT[0] = 1;
    if (IRQ_LCDC) FF0F_NEXT[1] = 1;
    if (IRQ_TIMER) FF0F_NEXT[2] = 1;
    if (IRQ_SERIAL) FF0F_NEXT[3] = 1;
    FFFF_NEXT = FFFF;
    
    /* Memory Access Handlers */
    if (GB_Z80_ADDR == 16'hFF50 && GB_Z80_WR) brom_en_next = 0; // Capture Write to FF50 which disables Boot Rom
    
    /* DMA */
    DMA_STATE_NEXT = DMA_STATE;
    DMA_CNT_NEXT = DMA_CNT;
    DMA_ADDR_NEXT = DMA_ADDR;
    DMA_SETUP_CNT_NEXT = DMA_SETUP_CNT;
    DMA_SETUP_ADDR_NEXT = DMA_SETUP_ADDR;
    DMA_SETUP_NEXT = DMA_SETUP;
    
    if (GB_Z80_ADDR == 16'hFF46 && GB_Z80_WR) // Capture DMA write
    begin
        DMA_SETUP_NEXT = 1;
        DMA_SETUP_CNT_NEXT = 1;
        DMA_SETUP_ADDR_NEXT = GB_Z80_D_out;
    end
    
    unique case (DMA_STATE)
        DMA_IDLE: DMA_CNT_NEXT = 0;
        DMA_GO:
        begin
            DMA_CNT_NEXT = DMA_CNT + 1;
            OAM_WR = 1;
            OAM_ADDR = DMA_CNT >> 2;
            if (({DMA_ADDR, 8'h00} + (DMA_CNT >> 2)) >= 16'h8000 && ({DMA_ADDR, 8'h00} + (DMA_CNT >> 2)) <= 16'h9FFF) // Copy from VRAM
            begin
                MA = {DMA_ADDR, 8'h00} + (DMA_CNT >> 2);
                MCS = 1; MOE = 1;
                DATA_OAM_out = MD_in;
                
                if (GB_Z80_ADDR <= 16'h7FFF || (GB_Z80_ADDR >= 16'hA000 && GB_Z80_ADDR < 16'hFE00)) // Allow CPU to access WRAM/CART Bus at this time
                begin
                    A = GB_Z80_ADDR;
                    GB_Z80_D_in = D_in; 
                    D_out = GB_Z80_D_out;
                    CS = 1; RD = GB_Z80_RD; WR = GB_Z80_WR;
                end
            end
            else // Copy from ROM or Work RAM
            begin
                A = {DMA_ADDR, 8'h00} + (DMA_CNT >> 2);
                CS = 1; RD = 1;
                DATA_OAM_out = D_in;
                
                if (PPU_MODE == 2'b11 && PPU_ADDR >= 16'h8000 && PPU_ADDR <= 16'h9FFF) // Allow GPU to Access VRAM at this time
                begin
                    MA = PPU_ADDR;
                    PPU_DATA_in = MD_in;
                    MCS = 1; MOE = PPU_RD; MWR = 0;
                end
            end
            if (DMA_CNT == ((160 << 2) - 1))
            begin
                DMA_CNT_NEXT = 0;
                DMA_STATE_NEXT = DMA_IDLE;
            end
        end
    endcase
    
    if (DMA_SETUP)
    begin
        DMA_SETUP_CNT_NEXT = DMA_SETUP_CNT + 1;
        if (DMA_SETUP_CNT == 3'b100)
        begin
            DMA_SETUP_NEXT = 0;
            DMA_ADDR_NEXT = DMA_SETUP_ADDR;
            DMA_CNT_NEXT = 0;
            DMA_STATE_NEXT = DMA_GO;
            DMA_SETUP_CNT_NEXT = 0;
        end
    end
    
    /* ADDR MUX */
    
    if (DMA_STATE == DMA_GO)
    begin
        if (GB_Z80_ADDR >= 16'hFF80 && GB_Z80_ADDR < 16'hFFFF) // only high ram acess is allowed
        begin
            GB_Z80_D_in = DATA_HRAM_in;
            DATA_HRAM_out = GB_Z80_D_out;
            HRAM_WR = GB_Z80_WR;
        end 
    end
    
    if (DMA_STATE != DMA_GO) // DMA has higher priority than any of other memory access
    begin
        if (GB_Z80_ADDR >= 16'h0000 && GB_Z80_ADDR <= 16'h00FF)
        begin
            A = brom_en ? 0 : GB_Z80_ADDR;
            GB_Z80_D_in = brom_en ? DATA_BROM : D_in;
            D_out = brom_en ? 0 : GB_Z80_D_out;
            CS = brom_en ? 0 : 1;
            RD = brom_en ? 0 : GB_Z80_RD;
            WR = brom_en ? 0 : GB_Z80_WR;
        end
        else if (GB_Z80_ADDR >= 16'h0100 && GB_Z80_ADDR <= 16'h7FFF)
        begin
            A = GB_Z80_ADDR;
            GB_Z80_D_in = D_in; 
            D_out = GB_Z80_D_out;
            CS = 1; RD = GB_Z80_RD; WR = GB_Z80_WR;
        end
        else if (GB_Z80_ADDR >= 16'h8000 && GB_Z80_ADDR <= 16'h9FFF) // VRAM
        begin
            if (PPU_MODE != 2'b11)
            begin
                MA = GB_Z80_ADDR;
                GB_Z80_D_in = MD_in;
                MD_out = GB_Z80_D_out;
                MCS = 1; MOE = GB_Z80_RD; MWR = GB_Z80_WR;
            end
            else GB_Z80_D_in = 16'hFF;
        end
        else if (GB_Z80_ADDR >= 16'hA000 &&  GB_Z80_ADDR <= 16'hBFFF) // RAM for MBC
        begin
            A = GB_Z80_ADDR;
            GB_Z80_D_in = D_in; 
            D_out = GB_Z80_D_out;
            CS = 1; RD = GB_Z80_RD; WR = GB_Z80_WR;
        end
        
        else if (GB_Z80_ADDR >= 16'hC000 && GB_Z80_ADDR <= 16'hFDFF)  // WRAM with its echo
        begin
           A = GB_Z80_ADDR;
           GB_Z80_D_in = D_in; 
           D_out = GB_Z80_D_out;
           CS = 1; RD = GB_Z80_RD; WR = GB_Z80_WR;
        end
        else if (GB_Z80_ADDR >= 16'hFE00 && GB_Z80_ADDR<= 16'hFEFF)// OAM
        begin
            if (!PPU_MODE[1])
            begin
                GB_Z80_D_in = GB_Z80_ADDR < 16'hFEA0 ? DATA_OAM_in : 8'hFF;
                DATA_OAM_out = GB_Z80_ADDR < 16'hFEA0 ? GB_Z80_D_out : 8'hFF;
                OAM_WR = GB_Z80_ADDR < 16'hFEA0 ? GB_Z80_WR : 0;
            end
            else GB_Z80_D_in = 16'hFF;
        end
        else if (GB_Z80_ADDR == 16'hFF00) // JoyPad
        begin
            GB_Z80_D_in = {2'b11, FF00[5:4], P13, P12, P11, P10};
            if (GB_Z80_WR) FF00_NEXT = GB_Z80_D_out & 8'h30;
        end 
        else if (GB_Z80_ADDR == 16'hFF01 || GB_Z80_ADDR == 16'hFF02) // Serial
        begin
            MMIO_SERIAL_WR = GB_Z80_WR;
            MMIO_SERIAL_RD = GB_Z80_RD;
            GB_Z80_D_in = MMIO_SERIAL_DATA_in;
            MMIO_SERIAL_DATA_out = GB_Z80_D_out;
        end
        else if (GB_Z80_ADDR == 16'hFF03) GB_Z80_D_in = 8'hFF; // Undocumented
        else if (GB_Z80_ADDR >= 16'hFF04 && GB_Z80_ADDR <= 16'hFF07) // Timer
        begin
            MMIO_TIMER_WR = GB_Z80_WR;
            MMIO_TIMER_RD = GB_Z80_RD;
            GB_Z80_D_in = MMIO_TIMER_DATA_in;
            MMIO_TIMER_DATA_out = GB_Z80_D_out;
        end
        else if (GB_Z80_ADDR >= 16'hFF08 && GB_Z80_ADDR <= 16'hFF0E) GB_Z80_D_in = 8'hFF; // Undocumented
        else if (GB_Z80_ADDR == 16'hFF0F) //Interrupt Flag
        begin
            if (GB_Z80_RD) GB_Z80_D_in = {3'b111, FF0F[4:0]};
            if (GB_Z80_WR) FF0F_NEXT = GB_Z80_D_out;
        end
        else if (GB_Z80_ADDR >= 16'hFF10 && GB_Z80_ADDR <= 16'hFF3F) // Sound
        begin
            MMIO_SOUND_WR = GB_Z80_WR;
            MMIO_SOUND_RD = GB_Z80_RD;
            GB_Z80_D_in = MMIO_SOUND_DATA_in;
            MMIO_SOUND_DATA_out = GB_Z80_D_out;    
        end
        else if (GB_Z80_ADDR >= 16'hFF40 && GB_Z80_ADDR <= 16'hFF4B) //PPU
        begin
            MMIO_PPU_WR = GB_Z80_WR;
            MMIO_PPU_RD = GB_Z80_RD;
            GB_Z80_D_in = MMIO_PPU_DATA_in;
            MMIO_PPU_DATA_out = GB_Z80_D_out;
        end
        else if (GB_Z80_ADDR >= 16'hFF4C && GB_Z80_ADDR <= 16'hFF7F) GB_Z80_D_in = 8'hFF; // Unusable
        else if (GB_Z80_ADDR >= 16'hFF80 && GB_Z80_ADDR < 16'hFFFF) // High Ram
        begin
            GB_Z80_D_in = DATA_HRAM_in;
            DATA_HRAM_out = GB_Z80_D_out;
            HRAM_WR = GB_Z80_WR;
        end
        else if (GB_Z80_ADDR == 16'hFFFF)
        begin
            if (GB_Z80_RD) GB_Z80_D_in = FFFF;
            if (GB_Z80_WR) FFFF_NEXT = GB_Z80_D_out;
        end
        else GB_Z80_D_in = 8'hFF ;
        
        if (PPU_MODE == 2'b11 && PPU_ADDR >= 16'h8000 && PPU_ADDR <= 16'h9FFF)
        begin
            MA = PPU_ADDR;
            PPU_DATA_in = MD_in;
            MCS = 1; MOE = PPU_RD; MWR = 0;
        end
        
        if (PPU_MODE[1] && PPU_ADDR >= 16'hFE00 && PPU_ADDR < 16'hFEA0)
        begin
            OAM_WR = 0; OAM_ADDR = PPU_ADDR;
            PPU_DATA_in = DATA_OAM_in;
        end
    end
    
    if (GB_Z80_ADDR == 16'hFF46 && GB_Z80_RD) // DMA Register can be read anytime
    begin
            GB_Z80_D_in = DMA_SETUP_ADDR;
    end

end

endmodule
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// GameBoy Sound Peripheral
//////////////////////////////////////////////////////////////////////////////////


module SOUND2
(
    input logic clk,
    input logic rst,
    
    input logic [7:0] ADDR,
    input logic WR,
    input logic RD,
    input logic [7:0] MMIO_DATA_out,
    output logic [7:0] MMIO_DATA_in,
    
    output logic [15:0] SOUND_LEFT,
    output logic [15:0] SOUND_RIGHT
);

logic [7:0] SOUND_REG [0:22];
logic [7:0] SOUND_REG_NEXT [0:22];
logic [7:0] WAVE_RAM [0:15];
logic [7:0] WAVE_RAM_NEXT [0:15];

logic PWR_RST;
assign PWR_RST = rst || !SOUND_REG_NEXT[22][7];

logic clk_len_ctr, clk_vol_env, clk_sweep; 
FRAME_SEQUENCER FS(.clk(clk), .rst(PWR_RST), .*);

logic [3:0] TRIGGER;
assign TRIGGER[0] = SOUND_REG_NEXT[4][7];
assign TRIGGER[1] = SOUND_REG_NEXT[9][7];
assign TRIGGER[2] = SOUND_REG_NEXT[14][7];
assign TRIGGER[3] = SOUND_REG_NEXT[19][7];

logic [3:0] LC_LOAD;
assign LC_LOAD[0] = WR && ADDR == 8'h11;
assign LC_LOAD[1] = WR && ADDR == 8'h16;
assign LC_LOAD[2] = WR && ADDR == 8'h1B;
assign LC_LOAD[3] = WR && ADDR == 8'h20;

logic [3:0] ON;
logic [3:0] SOUND [0:3];

/* Channel 1 */
logic [10:0] CH1_PERIOD;
assign CH1_PERIOD = {SOUND_REG_NEXT[4][2:0], SOUND_REG[3]};
logic [2:0] CH1_SWEEP_PERIOD;
assign CH1_SWEEP_PERIOD = SOUND_REG[0][6:4];
logic CH1_NEGATE;
assign CH1_NEGATE = SOUND_REG[0][3];
logic [2:0] CH1_SWEEP_SHIFT;
assign CH1_SWEEP_SHIFT = SOUND_REG[0][2:0];
logic [10:0] CH1_SQWAVE_PERIOD;
logic CH1_SWEEPER_EN;
logic [1:0] CH1_DUTY;
assign CH1_DUTY = SOUND_REG[1][7:6];
logic [5:0] CH1_LENGTH;
assign CH1_LENGTH = SOUND_REG[1][5:0];
logic [3:0] CH1_VOL_INIT;
assign CH1_VOL_INIT = SOUND_REG[2][7:4];
logic CH1_VOL_MODE;
assign CH1_VOL_MODE = SOUND_REG[2][3];
logic [2:0] CH1_VOL_PERIOD;
assign CH1_VOL_PERIOD = SOUND_REG[2][2:0];
logic CH1_LEN_EN;
assign CH1_LEN_EN = SOUND_REG_NEXT[4][6];
logic CH1_SWEEPER_OVERFLOW;

SWEEPER CH1_SWEPPER(.clk(clk), .clk_sweep(clk_sweep), .rst(rst), .ch1_period(CH1_PERIOD), .sweep_period(CH1_SWEEP_PERIOD), .negate(CH1_NEGATE), 
                    .shift(CH1_SWEEP_SHIFT), .load(TRIGGER[0]), .sqwave_period(CH1_SQWAVE_PERIOD), .en(CH1_SWEEPER_EN), .overflow(CH1_SWEEPER_OVERFLOW));

SQ_WAVE CH1_SQ_WAVE(.*, .duty(CH1_DUTY), .length(MMIO_DATA_out), .vol_init(CH1_VOL_INIT), .vol_mode(CH1_VOL_MODE), .vol_period(CH1_VOL_PERIOD), .period(CH1_SQWAVE_PERIOD),
                    .trigger(TRIGGER[0]), .LC_LOAD(LC_LOAD[0]), .len_en(CH1_LEN_EN), .shut_down(PWR_RST), .ON(ON[0]), .SOUND(SOUND[0]), .overflow(CH1_SWEEPER_OVERFLOW));

/* Channel 2 */
logic [10:0] CH2_PERIOD; 
assign CH2_PERIOD = {SOUND_REG_NEXT[9][2:0], SOUND_REG[8]};
logic [1:0] CH2_DUTY;
assign CH2_DUTY = SOUND_REG[6][7:6];
logic [5:0] CH2_LENGTH;
assign CH2_LENGTH = SOUND_REG[6][5:0];
logic [3:0] CH2_VOL_INIT;
assign CH2_VOL_INIT = SOUND_REG[7][7:4];
logic CH2_VOL_MODE;
assign CH2_VOL_MODE = SOUND_REG[7][3];
logic [2:0] CH2_VOL_PERIOD;
assign CH2_VOL_PERIOD = SOUND_REG[7][2:0];
logic CH2_LEN_EN;
assign CH2_LEN_EN = SOUND_REG_NEXT[9][6];
SQ_WAVE CH2_SQ_WAVE(.*, .duty(CH2_DUTY), .length(MMIO_DATA_out), .vol_init(CH2_VOL_INIT), .vol_mode(CH2_VOL_MODE), .vol_period(CH2_VOL_PERIOD), .period(CH2_PERIOD),
                    .trigger(TRIGGER[1]), .LC_LOAD(LC_LOAD[1]), .len_en(CH2_LEN_EN), .shut_down(PWR_RST), .ON(ON[1]), .SOUND(SOUND[1]), .overflow(1'b0));


/* Channel 3 */
logic CH3_POWER;
assign CH3_POWER = SOUND_REG[10][7];
logic [7:0] CH3_LENGTH;
assign CH3_LENGTH = SOUND_REG[11];
logic [1:0] CH3_VOL;
assign CH3_VOL = SOUND_REG[12][6:5];
logic [10:0] CH3_PERIOD;
assign CH3_PERIOD = {SOUND_REG_NEXT[14][2:0], SOUND_REG[13]};
logic CH3_LEN_EN;
assign CH3_LEN_EN = SOUND_REG_NEXT[14][6];


WAVE CH3_WAVE(.*, .power(CH3_POWER), .length(MMIO_DATA_out), .vol(CH3_VOL), .period(CH3_PERIOD), .trigger(TRIGGER[2]), .LC_LOAD(LC_LOAD[2]),
              .len_en(CH3_LEN_EN), .shut_down(PWR_RST), .ON(ON[2]), .SOUND(SOUND[2]));
        

/* Channel 4 */
logic [5:0] CH4_LENGTH;
assign CH4_LENGTH = SOUND_REG[16][5:0];
logic [3:0] CH4_VOL_INIT;
assign CH4_VOL_INIT = SOUND_REG[17][7:4];
logic CH4_VOL_MODE;
assign CH4_VOL_MODE = SOUND_REG[17][3];
logic [2:0] CH4_VOL_PERIOD;
assign CH4_VOL_PERIOD = SOUND_REG[17][2:0];
logic [3:0] CH4_SHIFT;
assign CH4_SHIFT = SOUND_REG[18][7:4];
logic CH4_LSFR_MODE;
assign CH4_LSFR_MODE = SOUND_REG[18][3];
logic [2:0] CH4_DIV;
assign CH4_DIV = SOUND_REG[18][2:0];
logic CH4_LEN_EN;
assign CH4_LEN_EN = SOUND_REG_NEXT[19][6];


NOISE CH4_NOISE(.*, .length(CH4_LENGTH), .vol_init(CH4_VOL_INIT), .vol_mode(CH4_VOL_MODE), .vol_period(CH4_VOL_PERIOD), .shift(CH4_SHIFT),
                .lsfr_mode(CH4_LSFR_MODE), .div(CH4_DIV), .trigger(TRIGGER[3]), .LC_LOAD(LC_LOAD[3]), .len_en(CH4_LEN_EN), .shut_down(PWR_RST),
                .ON(ON[3]), .SOUND(SOUND[3]));


logic [3:0] LEFT_EN, RIGHT_EN;
assign LEFT_EN = SOUND_REG[21][7:4];
assign RIGHT_EN = SOUND_REG[21][3:0];
logic [2:0] LEFT_VOL, RIGHT_VOL;
assign LEFT_VOL = SOUND_REG[20][6:4];
assign RIGHT_VOL = SOUND_REG[20][2:0];

always_ff @(posedge clk)
begin
    if (PWR_RST) for (int i = 0; i < 23; i ++) SOUND_REG[i] <= 0;
    else for (int i = 0; i < 23; i ++) SOUND_REG[i] <= SOUND_REG_NEXT[i];
    
    if (rst) for (int i = 0; i < 16; i ++) WAVE_RAM[i] <= 0;
    else for (int i = 0; i < 16; i ++) WAVE_RAM[i] <= WAVE_RAM_NEXT[i];
end

always_comb
begin
    for (int i = 0; i < 23; i++) SOUND_REG_NEXT[i] = SOUND_REG[i];
    for (int i = 0; i < 16; i ++) WAVE_RAM_NEXT[i] = WAVE_RAM[i];
    MMIO_DATA_in = 8'hFF;
    /* Trigger Auto Reset */
    SOUND_REG_NEXT[4][7] = 0;
    SOUND_REG_NEXT[9][7] = 0;
    SOUND_REG_NEXT[14][7] = 0;
    SOUND_REG_NEXT[19][7] = 0;
    if (ADDR <= 8'h26 && ADDR >= 8'h10)
    begin
        if (WR) SOUND_REG_NEXT[ADDR - 8'h10] = MMIO_DATA_out;
        MMIO_DATA_in = SOUND_REG[ADDR - 8'h10];
        /* REG MASKS */
        case (ADDR)
            8'h10 : MMIO_DATA_in = MMIO_DATA_in | 8'h80;
            8'h11, 8'h16: MMIO_DATA_in = MMIO_DATA_in | 8'h3F;
            8'h13, 8'h18, 8'h1B, 8'h1D, 8'h20, 8'h15, 8'h1F: MMIO_DATA_in = 8'hFF;
            8'h14, 8'h19, 8'h1E, 8'h23: MMIO_DATA_in = MMIO_DATA_in | 8'hBF;
            8'h1A: MMIO_DATA_in = MMIO_DATA_in | 8'h7F;
            8'h1C: MMIO_DATA_in = MMIO_DATA_in | 8'h9F;
            8'h26: MMIO_DATA_in = {MMIO_DATA_in[7], 3'b111, ON};
        endcase
    end
    else if (ADDR >= 8'h30 && ADDR <= 8'h3F)
    begin
        if (WR) WAVE_RAM_NEXT[ADDR - 8'h30] = MMIO_DATA_out;
        MMIO_DATA_in = WAVE_RAM[ADDR - 8'h30];
    end
    
    
    /* Frequnecy Sweeper */
    if (CH1_SWEEPER_EN && clk_sweep)
    begin
        SOUND_REG_NEXT[4][2:0] = CH1_SQWAVE_PERIOD[10:8];
        SOUND_REG_NEXT[3] = CH1_SQWAVE_PERIOD[7:0];
    end
    
    SOUND_LEFT = 0; SOUND_RIGHT = 0;
    for (int i = 0; i < 4; i++)
    begin
        if (LEFT_EN[i]) SOUND_LEFT = SOUND_LEFT + SOUND[i];
    end
    
    for (int i = 0; i < 4; i++)
    begin
        if (RIGHT_EN[i]) SOUND_RIGHT = SOUND_RIGHT + SOUND[i];
    end
    
    SOUND_LEFT = SOUND_LEFT * (LEFT_VOL + 1);
    SOUND_RIGHT = SOUND_RIGHT * (RIGHT_VOL + 1);
    
end

endmodule

module SWEEPER
(
    input logic clk,
    input logic clk_sweep,
    input logic rst,
    input logic [10:0] ch1_period,
    input logic [2:0] sweep_period,
    input logic negate,
    input logic [2:0] shift,
    input logic load,
    output logic overflow,
    output logic [10:0] sqwave_period,
    output logic en
);

logic [2:0] counter;
logic [2:0] shift_int;
logic [10:0] period;
logic [11:0] period_new;

assign en = (sweep_period != 0 && shift_int != 0);

always_comb
begin
    overflow = 0;
    period_new = {1'b0, period};
    if (en)
    begin
        if (negate) period_new = period - (period >> shift_int);
        else period_new = period + (period >> shift_int);
        
        if (period_new > 2047) overflow = 1;
    end
    
end

always_ff @(posedge clk)
begin
    if (rst) begin counter <= 0; period <= 0; shift_int <= 0;end
    else if (load) begin period <= ch1_period; counter <= sweep_period; shift_int <= shift; end
    else 
    begin
        if (counter != 0 && clk_sweep)
        begin
            counter <= counter - 1;
        end
        if (counter == 0 && clk_sweep)
        begin
            counter <= sweep_period;
        end
    
        if (clk_sweep && en && counter == 0 && !overflow) period <= period_new;
    end
end

assign sqwave_period = (en) ? period_new : ch1_period;

endmodule

module FRAME_SEQUENCER
(
    input logic clk,
    input logic rst,
    output logic clk_len_ctr,
    output logic clk_vol_env,
    output logic clk_sweep
);

logic [15:0] counter;

always_ff @(posedge clk)
begin
    if (rst) counter <= 0;
    else counter <= counter + 1;
end

assign clk_vol_env = counter[15] && counter[14:0] == 15'd0;
assign clk_sweep = counter[14] && counter[13:0] == 14'd0;
assign clk_len_ctr = counter[13] && counter [12:0] == 13'd0;

endmodule

module SOUND_TIMER
(
    input logic clk,
    input logic rst,
    input logic load,
    input logic [13:0] period,
    output logic tick
);

logic [13:0] counter;
always_ff @(posedge clk)
begin
    if (rst) counter <= 0;
    else if (counter == 0 || load) counter <= period;
    else counter <= counter - 1;
end

assign tick = (counter == 0);
endmodule

module LENGTH_COUNTER #( parameter len_max = 64 )
(
    input logic clk,
    input logic clk_len_ctr,
    input logic rst,
    input logic load,
    input logic trigger,
    input logic [7:0] length,
    output logic en
);

logic [8:0] counter;

always_ff @(posedge clk)
begin
    if (rst) counter <= 0;
    else if (load) counter <= (len_max - length);
    else if (trigger) counter <= len_max;
    else if (counter != 0 && clk_len_ctr) counter <= counter - 1;
end

assign en = (counter != 0);

endmodule

module VOLUME_ENVELOPE
(
    input logic clk,
    input logic clk_vol_env,
    input logic rst,
    input logic load,
    input logic mode,
    input logic [3:0] vol_init,
    input logic [2:0] period,
    output logic [3:0] vol
);

logic [3:0] volume;
logic [2:0] counter;

always_ff @(posedge clk)
begin
    if (rst) begin counter <= 0; volume <= vol_init; end
    else if (load)
    begin
        counter <= period; 
        volume <= vol_init;
    end
    else
    begin
        if (clk_vol_env && counter != 0) counter <= counter - 1;
        if (clk_vol_env && counter == 0 && period != 0 && ((mode && volume != 4'hF) || (!mode && volume != 4'h0)))
        begin
            counter <= period;
            volume <= mode ? volume + 1 : volume - 1;
        end
    end
end

assign vol = period != 0 ? volume : vol_init;

endmodule

module DUTY_CYCLE
(
    input logic clk,
    input logic rst,
    input logic tick,
    input logic [1:0] duty,
    output logic sq_wave
);

logic [7:0] DUTY_TEMPLATE [0:3];
logic [2:0] counter;
assign DUTY_TEMPLATE[0] = 8'b0000_0001;
assign DUTY_TEMPLATE[1] = 8'b1000_0001;
assign DUTY_TEMPLATE[2] = 8'b1000_0111;
assign DUTY_TEMPLATE[3] = 8'b0111_1110;

always_ff @(posedge clk)
begin
    if (rst) counter <= 0;
    else if (tick) counter <= counter + 1;
end

assign sq_wave = DUTY_TEMPLATE[duty][counter];

endmodule

module SQ_WAVE
(
    input logic clk,
    input logic clk_len_ctr,
    input logic clk_vol_env,
    input logic rst,
    input logic [1:0] duty,
    input logic [5:0] length,
    input logic [3:0] vol_init,
    input logic vol_mode,
    input logic [2:0] vol_period,
    input logic [10:0] period,
    input logic trigger,
    input logic len_en,
    input logic shut_down,
    input logic overflow,
    input logic LC_LOAD,
    output logic ON,
    output logic [3:0] SOUND
);

logic tick;
logic sq_wave;
logic en;
logic [3:0] vol;
SOUND_TIMER TIMER(.clk(clk), .rst(rst), .load(trigger), .period({(12'd2048 - period), 2'd0}), .tick(tick));
DUTY_CYCLE  DUTY (.*);
LENGTH_COUNTER LC(.clk(clk), .clk_len_ctr(clk_len_ctr), .rst(rst || shut_down), .load(LC_LOAD), .trigger(trigger), .length({2'd0, length}), .en(en));
VOLUME_ENVELOPE ENV(.clk(clk), .clk_vol_env(clk_vol_env), .rst(rst), .load(trigger), .mode(vol_mode), .vol_init(vol_init), .period(vol_period), .vol(vol));

assign ON = en && !shut_down && !overflow;
assign SOUND = (en || !len_en) && !shut_down && !overflow && sq_wave ? vol : 0;
    
endmodule

module WAVE
(
    input logic clk,
    input logic clk_len_ctr,
    input logic rst,
    input logic power,
    input logic [7:0] length,
    input logic [1:0] vol,
    input logic [10:0] period,
    input logic trigger,
    input logic len_en,
    input logic shut_down,
    input logic [7:0] WAVE_RAM [0:15],
    input logic LC_LOAD,
    
    output logic ON,
    output logic [3:0] SOUND
);

logic [4:0] ptr;
logic [4:0] ptr_2;
assign ptr_2 = ptr + 1;
logic [4:0] sample_h, sample_l;
assign sample_h =  WAVE_RAM[ptr_2 >> 1][7:4];
assign sample_l =  WAVE_RAM[ptr_2 >> 1][3:0];

logic [4:0] sample;

logic tick;
logic en;

always_ff @(posedge clk)
begin
    if (rst)
    begin
        ptr <= 0;
        sample <= 0;
    end
    else if (shut_down) ptr <= 0;
    else if (tick)
    begin
        ptr <= ptr + 1;
        sample <= ptr[0] ? sample_l : sample_h;
    end
end
SOUND_TIMER TIMER(.clk(clk), .rst(rst), .load(trigger), .period({1'b0, 12'd2048 - period, 1'b0}), .tick(tick));
LENGTH_COUNTER #(256) LC(.clk(clk), .clk_len_ctr(clk_len_ctr), .rst(rst || shut_down), .load(LC_LOAD), .trigger(trigger), .length(length), .en(en));

assign ON = en && !shut_down && power;
assign SOUND = (en || !len_en) && !shut_down && power && (vol != 0) ? sample >> (vol - 1) : 0;

endmodule

module NOISE
(
    input logic clk,
    input logic clk_len_ctr,
    input logic clk_vol_env,
    input logic rst,
    input logic [5:0] length,
    input logic [3:0] vol_init,
    input logic vol_mode,
    input logic [2:0] vol_period,
    input logic [3:0] shift,
    input logic lsfr_mode,
    input logic [2:0] div,
    input logic trigger,
    input logic len_en,
    input logic shut_down,
    input logic LC_LOAD,
    
    output logic ON,
    output logic [3:0] SOUND
);

logic [14:0] LSFR;

logic tick;
logic en;
logic [3:0] vol;

logic [13:0] period;
assign period = (div == 0) ?  2 << 2 : (2 << 3) * div;


SOUND_TIMER TIMER(.clk(clk), .rst(rst), .load(trigger), .period(period << (shift + 1)), .tick(tick));
LENGTH_COUNTER LC(.clk(clk), .clk_len_ctr(clk_len_ctr), .rst(rst || shut_down), .load(LC_LOAD), .trigger(trigger), .length({2'd0, length}), .en(en));
VOLUME_ENVELOPE ENV(.clk(clk), .clk_vol_env(clk_vol_env), .rst(rst), .load(trigger), .mode(vol_mode), .vol_init(vol_init), .period(vol_period), .vol(vol));


always_ff @(posedge clk)
begin
    if (rst || trigger)
    begin
        LSFR <= {15{1'b1}};
    end
    else if (tick) LSFR <= lsfr_mode ? {LSFR[1]^LSFR[0], LSFR[14:8], LSFR[1]^LSFR[0], LSFR[6:1]}: {LSFR[1]^LSFR[0], LSFR[14:1]};
end

assign ON = en && !shut_down;
assign SOUND = (en || !len_en) && !shut_down && !LSFR[0] ? vol : 0;

endmodule
`timescale 1ns / 1ps

module Serial
(
    input logic clk,
    input logic reset,

    input logic [15:0] addr,
    input logic write,
    input logic read,

    output logic [7:0] dout,
    input logic [7:0] din,

    input logic SCK_in,    // external clock (typically supplied by another Game Boy)
    output logic SCK_out,   

    input logic S_IN,    
    output logic S_OUT,

    output logic S_INTERRUPT    // serial interrupt       
);

// Serial I/O registers
logic [7:0] SB;             // serial transfer data; address 0xFF01
logic [7:0] SB_set, SB_set_next;
logic [7:0] SC, SC_next;    // serial transfer control; address 0xFF02
                            // bit 7 - transfer start flag
                            // 0: no transfer, 1: start transfer
                            // bit 0 - shift clock 
                            // 0: external (max 500 kHz); 1: internal (8192 Hz) 

logic [3:0] count;

logic transfer_start;
logic [7:0] clk_count;

logic shift_clk;
logic int_clk;  // internal clock (8192 Hz)

Serial_clk_div Serial_clk(.clk(clk), .reset(reset), .clk_out(int_clk), .count(clk_count));

assign shift_clk = SC[7] ? (SC[0] ? int_clk : SCK_in) : 1;
assign SCK_out = SC[7] ? int_clk : 1;

always_ff @(posedge clk)
begin
    if (reset)
    begin
        SC <= 0;
        SB_set <= 0;
        S_OUT <= 0;
        SB <= 0;
        transfer_start <= 0;
        S_INTERRUPT <= 0;
        count <= 0;
    end
    else
    begin
        SC <= SC_next;
        SB_set <= SB_set_next;
        if (SC[7])
        begin
            if (clk_count == 8'd255)    // edge of internal clock
            begin
                if (shift_clk)  // negative edge
                begin
                    if (count == 4'd7)
                    begin
                        count <= 0;
                        SC[7] <= 0; // transfer complete
                        SB_set <= SB; 
                        S_INTERRUPT <= 1;
                        transfer_start <= 0;  
                    end
                    else
                    begin
                        transfer_start <= 1;
                        S_OUT <= SB[7];
                        SB[7] <= SB[6];
                        SB[6] <= SB[5];
                        SB[5] <= SB[4];
                        SB[4] <= SB[3];
                        SB[3] <= SB[2];
                        SB[2] <= SB[1];
                        SB[1] <= SB[0];
                        count <= count + 1;
                    end
                end
                else    // positive edge
                begin
                    if (transfer_start)
                        SB[0] <= S_IN;
                end
            end
        end
        else
        begin
            SB <= SB_set_next;
            S_INTERRUPT <= 0;
        end
    end
end

always_comb
begin
    SB_set_next = SB_set;
    SC_next = SC;
    dout = 8'hFF;

    if (addr == 16'hFF01 && write && !SC[7])
    begin
        SB_set_next = din;
    end
    else if (addr == 16'hFF01 && read && !SC[7])
    begin
        dout = SB;
    end
    else if (addr == 16'hFF02 && write)
    begin
        SC_next = din;
    end
    else if (addr == 16'hFF02 && read)
    begin
        //dout = SC;  
        dout = {SC[7], 6'b111111, SC[0]};
    end
end

endmodule
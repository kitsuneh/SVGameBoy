`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// This is the GB-Z80 CPU 
// All modules in a single file for simulation
//////////////////////////////////////////////////////////////////////////////////
`include "GB_Z80_ALU.vh"
`include "GB_Z80_CPU.vh"
`include "GB_Z80_DECODER.vh"

`define NO_BOOT 0

module GB_Z80_SINGLE
(
    input logic clk,
    input logic rst,
    output logic [15:0] ADDR, // Memory Address Bus
    input logic [7:0] DATA_in, // Input Data Bus 
    output logic [7:0] DATA_out, // Output Data Bus
    output logic RD, // CPU wants to read data from Memory or IO, active high
    output logic WR, // CPU holds valid data to be stored in Memory or IO, active high
    output logic CPU_HALT, // CPU has executed a HALT instruction and is awaiting an interrupt, active high
    input logic [4:0] INTQ, // Interrupt Request, Interrupt will be honored at the end of the current instruction
    input logic [4:0] IE // Interrupt Enable
);

GB_Z80_REG CPU_REG, CPU_REG_NEXT;
logic [15:0] ADDR_NEXT;

/* Decoder */
logic [7:0] INST, INST_NEXT; // Instruction Register
logic [4:0] INTQ_INT, INTQ_INT_NEXT;
GB_Z80_RISC_OPCODE RISC_OPCODE [0:10];
logic [5:0] NUM_Tcnt; 
logic isCB, isCB_NEXT;
logic isINT, isINT_NEXT;
logic isPCMEM [0:10];
logic [4:0] T_CNT, T_CNT_NEXT;
logic [2:0] M_CNT, M_CNT_NEXT;
byte cur_risc_num;

GB_Z80_DECODER CPU_DECODER(.CPU_OPCODE(INST), .INTQ(INTQ_INT), .isCB(isCB), .isINT(isINT), .RISC_OPCODE(RISC_OPCODE), .NUM_Tcnt(NUM_Tcnt), .isPCMEM(isPCMEM), 
                           .FLAG(CPU_REG.F));

/* ALU */
logic [7:0] ALU_OPD1_L, ALU_OPD2_L, ALU_STATUS, ALU_RESULT_L, ALU_RESULT_H;
GB_Z80_ALU_OPCODE ALU_OPCODE;
GB_Z80_ALU CPU_ALU(.OPD1_L(ALU_OPD1_L), .OPD2_L(ALU_OPD2_L), .OPCODE(ALU_OPCODE), .FLAG(CPU_REG.F), .STATUS(ALU_STATUS), 
                   .RESULT_L(ALU_RESULT_L), .RESULT_H(ALU_RESULT_H));

/* Main FSMD */
// Main 4 Stages are IF -> DE -> EX -> (MEM)WB
// Each takes 1 T cycle

typedef enum {CPU_IF, CPU_DE, CPU_DE_CB, CPU_EX_RISC, CPU_WB_RISC} CPU_STATE_t;
CPU_STATE_t CPU_STATE, CPU_STATE_NEXT;

logic RD_NEXT, WR_NEXT;
logic EX_done;


logic IME, IME_NEXT; // Interrupt Master Enable

always_ff @(posedge clk)
begin
    /* Power On Reset */
    if (rst)
    begin
        CPU_STATE <= CPU_IF;
        CPU_REG.PC <= 0;
        CPU_REG.F <= 0;
        CPU_REG.T <= 0;
        ADDR <= 0;
        if (`NO_BOOT)
        begin
            CPU_REG.A <= 8'h01;
            CPU_REG.F <= 8'hB0;
            CPU_REG.B <= 8'h00;
            CPU_REG.C <= 8'h13;
            CPU_REG.D <= 8'h00;
            CPU_REG.E <= 8'hD8;
            CPU_REG.H <= 8'h01;
            CPU_REG.L <= 8'h4D;
            CPU_REG.SPh <= 8'hFF;
            CPU_REG.SPl <= 8'hFE;
            CPU_REG.PC <= 16'h0100;
            ADDR <= 16'h0100;
        end
        RD <= 1; WR <= 0;
        T_CNT <= 0; //M_CNT <= 0;
        isCB <= 0;
        isINT <= 0;
        IME <= 0;
        INTQ_INT <= 0;
    end
    else
    begin
        CPU_STATE <= CPU_STATE_NEXT;
        CPU_REG <= CPU_REG_NEXT;
        ADDR <= ADDR_NEXT;
        RD <= RD_NEXT; WR<= WR_NEXT;
        T_CNT <= T_CNT_NEXT; //M_CNT <= M_CNT_NEXT;
        isCB <= isCB_NEXT;
        isINT <= isINT_NEXT;
        INST <= INST_NEXT;
        IME <= IME_NEXT;
        INTQ_INT <= INTQ_INT_NEXT;
    end
    
end

assign M_CNT = (T_CNT - 1) >> 2; // 1 M Cycle for every 4 T cycles
assign cur_risc_num = (T_CNT >> 1) - 1 - (isCB << 1) + isINT;

always_comb
begin
    CPU_STATE_NEXT = CPU_STATE;
    CPU_REG_NEXT = CPU_REG;
    ADDR_NEXT = CPU_REG.PC;
    isCB_NEXT = isCB;
    isINT_NEXT = isINT;
    IME_NEXT = IME;
    INTQ_INT_NEXT = INTQ_INT;
    RD_NEXT = 0; WR_NEXT = 0;
    DATA_out = 0;
    T_CNT_NEXT = T_CNT + 1;
    INST_NEXT = INST;
    ALU_OPD1_L = 0;
    ALU_OPD2_L = 0;
    ALU_OPCODE = ALU_NOP;
    CPU_HALT = 0;
    unique case (CPU_STATE)
        // Instruction Fetch From Memory at PC
        CPU_IF :
        begin
            RD_NEXT = 0;
            INST_NEXT = DATA_in; 
            T_CNT_NEXT = T_CNT + 1;
            CPU_STATE_NEXT = CPU_DE;
            CPU_REG_NEXT.PC = CPU_REG.PC + 1;
        end  
        CPU_DE :
        begin
            if ((INST) == 8'hCB && !isCB) 
            begin
                CPU_STATE_NEXT = CPU_DE_CB;
                isCB_NEXT = 1;
                T_CNT_NEXT = T_CNT + 1;
            end
            else 
            begin
                CPU_STATE_NEXT = CPU_EX_RISC;
                T_CNT_NEXT = T_CNT + 1;
            end
        end
        CPU_DE_CB :
        begin
            if (T_CNT != 3) // CB fetch delay
            begin
                T_CNT_NEXT = T_CNT + 1;
                CPU_STATE_NEXT = CPU_DE_CB;
            end
            else
            begin
                T_CNT_NEXT = T_CNT + 1;
                CPU_STATE_NEXT = CPU_IF;
                RD_NEXT = 1;
            end
        end
        
        CPU_EX_RISC :
        begin
            T_CNT_NEXT = T_CNT + 1;
            CPU_STATE_NEXT = CPU_WB_RISC;
            
            if (isPCMEM[cur_risc_num])
                    CPU_REG_NEXT.PC = CPU_REG.PC + 1;
            //if (!IME && (RISC_OPCODE[cur_risc_num] == HALT)) // HALT "skip" behaviour
            //        CPU_REG_NEXT.PC = CPU_REG.PC + 1;

            case (RISC_OPCODE[cur_risc_num])
                NOP: ;  // no operations
                LD_APC, LD_BPC, LD_CPC, LD_DPC, LD_EPC, LD_HPC, LD_LPC, LD_TPC, LD_XPC, LD_SPlPC, LD_SPhPC, JP_R8, JP_NZR8, JP_ZR8, JP_NCR8, JP_CR8: RD_NEXT = 1;
                LD_ABC: `RD_nn(B, C)
                LD_ADE: `RD_nn(D, E)
                LD_AHL, LD_BHL, LD_CHL, LD_DHL, LD_EHL, LD_HHL, LD_LHL, LD_THL, ADD_AHL, ADC_AHL, SUB_AHL, SBC_AHL, AND_AHL, XOR_AHL, OR_AHL, CP_AHL: `RD_nn(H, L)
                LD_ATX: `RD_nn(T, X)
                LD_PClSP, LD_PChSP, LD_BSP, LD_CSP, LD_DSP, LD_ESP, LD_HSP, LD_LSP, LD_ASP, LD_FSP: `RD_nn(SPh, SPl) 
                LD_AHT: `RD_FFn(T)
                LD_AHC: `RD_FFn(C)  
                
                LD_PCSPl, LD_PCSPh: WR_NEXT = 1;              
                LD_BCA: `WR_nn(B, C)
                LD_DEA: `WR_nn(D, E) 
                LD_HLA, LD_HLB, LD_HLC, LD_HLD, LD_HLE, LD_HLH, LD_HLL, LD_HLT: `WR_nn(H, L)
                LD_TXA, LD_TXSPh, LD_TXSPl: `WR_nn(T, X)
                LD_SPA, LD_SPB, LD_SPC, LD_SPD, LD_SPE, LD_SPH, LD_SPL, LD_SPF, LD_SPPCh, LD_SPPCl : `WR_nn(SPh, SPl)  
                LD_HTA: `WR_FFn(T)
                LD_HCA: `WR_FFn(C)
                DI: IME_NEXT = 0; 
                LATCH_INTQ: INTQ_INT_NEXT = INTQ;
                RST_IF: begin ADDR_NEXT = 16'hFF0F; WR_NEXT = 1; RD_NEXT = 1; end
            default: ;          
        endcase
        end    
        CPU_WB_RISC :
        begin
            if (T_CNT - (isCB << 2) == NUM_Tcnt - 1)
            begin
                T_CNT_NEXT = 0;
                CPU_STATE_NEXT = CPU_IF;

                isCB_NEXT = 0;
                RD_NEXT = 1;
                isINT_NEXT = 0;
                INTQ_INT_NEXT = 0;
                if (IME && (INTQ != 5'b00))
                begin
                    CPU_STATE_NEXT = CPU_EX_RISC;
                    isINT_NEXT = 1;
                end
                else if ((INTQ == 5'b00) && (RISC_OPCODE[cur_risc_num] == HALT)) // Handle HALT
                begin
                    CPU_STATE_NEXT = CPU_WB_RISC;
                    T_CNT_NEXT = T_CNT;
                    CPU_HALT = 1;
                end
            end
            else
            begin
                T_CNT_NEXT = T_CNT + 1;
                CPU_STATE_NEXT = CPU_EX_RISC;
            end

            case (RISC_OPCODE[cur_risc_num])
                NOP: ;
                LD_AA: `LD_n_n(A, A) 
                LD_AB: `LD_n_n(A, B)
                LD_AC: `LD_n_n(A, C)
                LD_AD: `LD_n_n(A, D)
                LD_AE: `LD_n_n(A, E)
                LD_AH: `LD_n_n(A, H)
                LD_AL: `LD_n_n(A, L)
                
                LD_BA: `LD_n_n(B, A)
                LD_BB: `LD_n_n(B, B)
                LD_BC: `LD_n_n(B, C)
                LD_BD: `LD_n_n(B, D)
                LD_BE: `LD_n_n(B, E)
                LD_BH: `LD_n_n(B, H)
                LD_BL: `LD_n_n(B, L)
                
                LD_CA: `LD_n_n(C, A)
                LD_CB: `LD_n_n(C, B)
                LD_CC: `LD_n_n(C, C)
                LD_CD: `LD_n_n(C, D)
                LD_CE: `LD_n_n(C, E)
                LD_CH: `LD_n_n(C, H)
                LD_CL: `LD_n_n(C, L)
                
                LD_DA: `LD_n_n(D, A)
                LD_DB: `LD_n_n(D, B)
                LD_DC: `LD_n_n(D, C)
                LD_DD: `LD_n_n(D, D)
                LD_DE: `LD_n_n(D, E)
                LD_DH: `LD_n_n(D, H)
                LD_DL: `LD_n_n(D, L)
                
                LD_EA: `LD_n_n(E, A)
                LD_EB: `LD_n_n(E, B)
                LD_EC: `LD_n_n(E, C)
                LD_ED: `LD_n_n(E, D)
                LD_EE: `LD_n_n(E, E)
                LD_EH: `LD_n_n(E, H)
                LD_EL: `LD_n_n(E, L)
                
                LD_HA: `LD_n_n(H, A)
                LD_HB: `LD_n_n(H, B)
                LD_HC: `LD_n_n(H, C)
                LD_HD: `LD_n_n(H, D)
                LD_HE: `LD_n_n(H, E)
                LD_HH: `LD_n_n(H, H)
                LD_HL: `LD_n_n(H, L)
                
                LD_LA: `LD_n_n(L, A)
                LD_LB: `LD_n_n(L, B)
                LD_LC: `LD_n_n(L, C)
                LD_LD: `LD_n_n(L, D)
                LD_LE: `LD_n_n(L, E)
                LD_LH: `LD_n_n(L, H)
                LD_LL: `LD_n_n(L, L)
                
                LD_PCHL: CPU_REG_NEXT.PC = {CPU_REG.H, CPU_REG.L};
                
                LD_SPHL: {CPU_REG_NEXT.SPh, CPU_REG_NEXT.SPl} = {CPU_REG.H, CPU_REG.L};
                      
                LD_APC, LD_AHL, LD_ABC, LD_ADE, LD_ASP, LD_AHT, LD_AHC, LD_ATX: CPU_REG_NEXT.A = DATA_in;
                LD_BPC, LD_BHL, LD_BSP: CPU_REG_NEXT.B = DATA_in;
                LD_CPC, LD_CHL, LD_CSP: CPU_REG_NEXT.C = DATA_in;
                LD_DPC, LD_DHL, LD_DSP: CPU_REG_NEXT.D = DATA_in;
                LD_EPC, LD_EHL, LD_ESP: CPU_REG_NEXT.E = DATA_in;
                LD_HPC, LD_HHL, LD_HSP: CPU_REG_NEXT.H = DATA_in;
                LD_LPC, LD_LHL, LD_LSP: CPU_REG_NEXT.L = DATA_in;
                LD_FSP: CPU_REG_NEXT.F = DATA_in;
                LD_TPC: CPU_REG_NEXT.T = DATA_in;
                LD_XPC: CPU_REG_NEXT.X = DATA_in;    
                LD_SPlPC: CPU_REG_NEXT.SPl = DATA_in;
                LD_SPhPC: CPU_REG_NEXT.SPh = DATA_in;                  
                LD_THL: CPU_REG_NEXT.T = DATA_in;
                LD_PClSP: CPU_REG_NEXT.PC = {CPU_REG.PC[15:8], DATA_in};
                LD_PChSP: CPU_REG_NEXT.PC = {DATA_in, CPU_REG.PC[7:0]};
                
          
                
                LD_BCA, LD_DEA, LD_HLA, LD_SPA, LD_HTA, LD_HCA, LD_TXA: DATA_out = CPU_REG.A;
                LD_HLB, LD_SPB: DATA_out = CPU_REG.B;
                LD_HLC, LD_SPC: DATA_out = CPU_REG.C;
                LD_HLD, LD_SPD: DATA_out = CPU_REG.D;
                LD_HLE, LD_SPE: DATA_out = CPU_REG.E;
                LD_HLH, LD_SPH: DATA_out = CPU_REG.H;
                LD_HLL, LD_SPL: DATA_out = CPU_REG.L;
                LD_SPF:  DATA_out = CPU_REG.F;
                LD_HLT: DATA_out = CPU_REG.T; 
                LD_PCSPl, LD_TXSPl: DATA_out = CPU_REG.SPl;
                LD_PCSPh, LD_TXSPh: DATA_out = CPU_REG.SPh;
                LD_SPPCh: DATA_out = CPU_REG.PC[15:8];
                LD_SPPCl: DATA_out = CPU_REG.PC[7:0];
                
                LD_HL_SPR8: `LD_HL_SPR8
                
                INC_BC : `INC_nn(B, C)
                DEC_BC : `DEC_nn(B, C)
                INC_DE : `INC_nn(D, E)
                DEC_DE : `DEC_nn(D, E)
                INC_HL : `INC_nn(H, L)
                DEC_HL : `DEC_nn(H, L)
                INC_TX : `INC_nn(T, X)
                DEC_TX : `DEC_nn(T, X)
                INC_SP : `INC_nn(SPh, SPl)
                DEC_SP : `DEC_nn(SPh, SPl)
                INC_A : `INC_n(A)
                DEC_A : `DEC_n(A)                     
                INC_B : `INC_n(B)
                DEC_B : `DEC_n(B)
                INC_C : `INC_n(C)
                DEC_C : `DEC_n(C)
                INC_D : `INC_n(D)
                DEC_D : `DEC_n(D)
                INC_E : `INC_n(E)
                DEC_E : `DEC_n(E)
                INC_H : `INC_n(H)
                DEC_H : `DEC_n(H)
                INC_L : `INC_n(L)
                DEC_L : `DEC_n(L)
                INC_T : `INC_n(T)
                DEC_T : `DEC_n(T) 
                                                  
                RLC_A : `SHIFTER_op_n(RLC, A)
                RLC_B : `SHIFTER_op_n(RLC, B)
                RLC_C : `SHIFTER_op_n(RLC, C)
                RLC_D : `SHIFTER_op_n(RLC, D)
                RLC_E : `SHIFTER_op_n(RLC, E)
                RLC_H : `SHIFTER_op_n(RLC, H)
                RLC_L : `SHIFTER_op_n(RLC, L)
                RLC_T : `SHIFTER_op_n(RLC, T)   
                                                                                             
                RRC_A : `SHIFTER_op_n(RRC, A)
                RRC_B : `SHIFTER_op_n(RRC, B)
                RRC_C : `SHIFTER_op_n(RRC, C)
                RRC_D : `SHIFTER_op_n(RRC, D)
                RRC_E : `SHIFTER_op_n(RRC, E)
                RRC_H : `SHIFTER_op_n(RRC, H)
                RRC_L : `SHIFTER_op_n(RRC, L)
                RRC_T : `SHIFTER_op_n(RRC, T)
                
                RR_A : `SHIFTER_op_n(RR, A)
                RR_B : `SHIFTER_op_n(RR, B)
                RR_C : `SHIFTER_op_n(RR, C)
                RR_D : `SHIFTER_op_n(RR, D)
                RR_E : `SHIFTER_op_n(RR, E)
                RR_H : `SHIFTER_op_n(RR, H)
                RR_L : `SHIFTER_op_n(RR, L)
                RR_T : `SHIFTER_op_n(RR, T)
                
                RL_A : `SHIFTER_op_n(RL, A)
                RL_B : `SHIFTER_op_n(RL, B)
                RL_C : `SHIFTER_op_n(RL, C)
                RL_D : `SHIFTER_op_n(RL, D)
                RL_E : `SHIFTER_op_n(RL, E)
                RL_H : `SHIFTER_op_n(RL, H)
                RL_L : `SHIFTER_op_n(RL, L)
                RL_T : `SHIFTER_op_n(RL, T)
                
                SRA_A : `SHIFTER_op_n(SRA, A)
                SRA_B : `SHIFTER_op_n(SRA, B)
                SRA_C : `SHIFTER_op_n(SRA, C)
                SRA_D : `SHIFTER_op_n(SRA, D)
                SRA_E : `SHIFTER_op_n(SRA, E)
                SRA_H : `SHIFTER_op_n(SRA, H)
                SRA_L : `SHIFTER_op_n(SRA, L)
                SRA_T : `SHIFTER_op_n(SRA, T)
                
                SLA_A : `SHIFTER_op_n(SLA, A)
                SLA_B : `SHIFTER_op_n(SLA, B)
                SLA_C : `SHIFTER_op_n(SLA, C)
                SLA_D : `SHIFTER_op_n(SLA, D)
                SLA_E : `SHIFTER_op_n(SLA, E)
                SLA_H : `SHIFTER_op_n(SLA, H)
                SLA_L : `SHIFTER_op_n(SLA, L)
                SLA_T : `SHIFTER_op_n(SLA, T)   
                
                SWAP_A : `SHIFTER_op_n(SWAP, A)
                SWAP_B : `SHIFTER_op_n(SWAP, B)
                SWAP_C : `SHIFTER_op_n(SWAP, C)
                SWAP_D : `SHIFTER_op_n(SWAP, D)
                SWAP_E : `SHIFTER_op_n(SWAP, E)
                SWAP_H : `SHIFTER_op_n(SWAP, H)
                SWAP_L : `SHIFTER_op_n(SWAP, L)
                SWAP_T : `SHIFTER_op_n(SWAP, T)
                
                SRL_A : `SHIFTER_op_n(SRL, A)
                SRL_B : `SHIFTER_op_n(SRL, B)
                SRL_C : `SHIFTER_op_n(SRL, C)
                SRL_D : `SHIFTER_op_n(SRL, D)
                SRL_E : `SHIFTER_op_n(SRL, E)
                SRL_H : `SHIFTER_op_n(SRL, H)
                SRL_L : `SHIFTER_op_n(SRL, L)
                SRL_T : `SHIFTER_op_n(SRL, T)         
                
                
                
                ADD_AA: `ALU_A_op_n(ADD, A)
                ADD_AB: `ALU_A_op_n(ADD, B)
                ADD_AC: `ALU_A_op_n(ADD, C) 
                ADD_AD: `ALU_A_op_n(ADD, D) 
                ADD_AE: `ALU_A_op_n(ADD, E) 
                ADD_AH: `ALU_A_op_n(ADD, H) 
                ADD_AL: `ALU_A_op_n(ADD, L)
                ADD_AT: `ALU_A_op_n(ADD, T)
                ADD_AHL: `ALU_A_op_Data_in(ADD)
                
                ADD_SPT: `ADD_SPT

                ADC_AA: `ALU_A_op_n(ADC, A)
                ADC_AB: `ALU_A_op_n(ADC, B)
                ADC_AC: `ALU_A_op_n(ADC, C) 
                ADC_AD: `ALU_A_op_n(ADC, D) 
                ADC_AE: `ALU_A_op_n(ADC, E) 
                ADC_AH: `ALU_A_op_n(ADC, H) 
                ADC_AL: `ALU_A_op_n(ADC, L)
                ADC_AT: `ALU_A_op_n(ADC, T)
                ADC_AHL: `ALU_A_op_Data_in(ADC)
                
                SUB_AA: `ALU_A_op_n(SUB, A)
                SUB_AB: `ALU_A_op_n(SUB, B)
                SUB_AC: `ALU_A_op_n(SUB, C) 
                SUB_AD: `ALU_A_op_n(SUB, D) 
                SUB_AE: `ALU_A_op_n(SUB, E) 
                SUB_AH: `ALU_A_op_n(SUB, H) 
                SUB_AL: `ALU_A_op_n(SUB, L)
                SUB_AT: `ALU_A_op_n(SUB, T)
                SUB_AHL: `ALU_A_op_Data_in(SUB)

                SBC_AA: `ALU_A_op_n(SBC, A)
                SBC_AB: `ALU_A_op_n(SBC, B)
                SBC_AC: `ALU_A_op_n(SBC, C) 
                SBC_AD: `ALU_A_op_n(SBC, D) 
                SBC_AE: `ALU_A_op_n(SBC, E) 
                SBC_AH: `ALU_A_op_n(SBC, H) 
                SBC_AL: `ALU_A_op_n(SBC, L)
                SBC_AT: `ALU_A_op_n(SBC, T)
                SBC_AHL: `ALU_A_op_Data_in(SBC)                                    

                AND_AA: `ALU_A_op_n(AND, A)
                AND_AB: `ALU_A_op_n(AND, B)
                AND_AC: `ALU_A_op_n(AND, C) 
                AND_AD: `ALU_A_op_n(AND, D) 
                AND_AE: `ALU_A_op_n(AND, E) 
                AND_AH: `ALU_A_op_n(AND, H) 
                AND_AL: `ALU_A_op_n(AND, L)
                AND_AT: `ALU_A_op_n(AND, T)
                AND_AHL: `ALU_A_op_Data_in(AND)

                XOR_AA: `ALU_A_op_n(XOR, A)
                XOR_AB: `ALU_A_op_n(XOR, B)
                XOR_AC: `ALU_A_op_n(XOR, C) 
                XOR_AD: `ALU_A_op_n(XOR, D) 
                XOR_AE: `ALU_A_op_n(XOR, E) 
                XOR_AH: `ALU_A_op_n(XOR, H) 
                XOR_AL: `ALU_A_op_n(XOR, L)
                XOR_AT: `ALU_A_op_n(XOR, T)
                XOR_AHL: `ALU_A_op_Data_in(XOR)
                
                OR_AA: `ALU_A_op_n(OR, A)
                OR_AB: `ALU_A_op_n(OR, B)
                OR_AC: `ALU_A_op_n(OR, C) 
                OR_AD: `ALU_A_op_n(OR, D) 
                OR_AE: `ALU_A_op_n(OR, E) 
                OR_AH: `ALU_A_op_n(OR, H) 
                OR_AL: `ALU_A_op_n(OR, L)
                OR_AT: `ALU_A_op_n(OR, T)
                OR_AHL: `ALU_A_op_Data_in(OR)
               
                CP_AA: `ALU_op_n(CP, A)
                CP_AB: `ALU_op_n(CP, B)
                CP_AC: `ALU_op_n(CP, C) 
                CP_AD: `ALU_op_n(CP, D) 
                CP_AE: `ALU_op_n(CP, E) 
                CP_AH: `ALU_op_n(CP, H) 
                CP_AL: `ALU_op_n(CP, L)
                CP_AT: `ALU_op_n(CP, T)
                CP_AHL: `ALU_op_Data_in(CP)                
                                                                
                ADD_LC: `ADDL_n(C)
                ADD_LE: `ADDL_n(E)
                ADD_LL: `ADDL_n(L)
                ADD_LSPl: `ADDL_n(SPl)
                ADC_HB: `ADCH_n(B)
                ADC_HD: `ADCH_n(D)
                ADC_HH: `ADCH_n(H)
                ADC_HSPh: `ADCH_n(SPh)
                
                DAA: `DAA
                CPL: begin CPU_REG_NEXT.A = CPU_REG.A ^ 8'hFF;  CPU_REG_NEXT.F = CPU_REG.F | 8'b0110_0000; end// invert all bits in A
                SCF: CPU_REG_NEXT.F = {CPU_REG.F[7], 3'b001, CPU_REG.F[3:0]}; // set carry flag
                CCF: CPU_REG_NEXT.F = {CPU_REG.F[7], 2'b00, ~CPU_REG.F[4], CPU_REG.F[3:0]}; // compliment carry flag
                
                JP_R8: CPU_REG_NEXT.PC = `DO_JPR8;
                JP_NZR8 : CPU_REG_NEXT.PC = CPU_REG.F[7] ? CPU_REG.PC : `DO_JPR8;
                JP_ZR8 : CPU_REG_NEXT.PC = CPU_REG.F[7] ? `DO_JPR8 :  CPU_REG.PC;
                JP_NCR8 : CPU_REG_NEXT.PC = CPU_REG.F[4] ? CPU_REG.PC : `DO_JPR8;
                JP_CR8 : CPU_REG_NEXT.PC = CPU_REG.F[4] ? `DO_JPR8 :  CPU_REG.PC;
                
                JP_TX : CPU_REG_NEXT.PC = {CPU_REG.T, CPU_REG.X};
                JP_Z_TX : CPU_REG_NEXT.PC = CPU_REG.F[7] ? {CPU_REG.T, CPU_REG.X} : CPU_REG.PC ;
                JP_NZ_TX : CPU_REG_NEXT.PC = CPU_REG.F[7] ? CPU_REG.PC : {CPU_REG.T, CPU_REG.X};
                JP_C_TX : CPU_REG_NEXT.PC = CPU_REG.F[4] ? {CPU_REG.T, CPU_REG.X} : CPU_REG.PC ;
                JP_NC_TX : CPU_REG_NEXT.PC = CPU_REG.F[4] ? CPU_REG.PC : {CPU_REG.T, CPU_REG.X};
                
                RST_00 : CPU_REG_NEXT.PC = {8'h00, 8'h00};
                RST_08 : CPU_REG_NEXT.PC = {8'h00, 8'h08};
                RST_10 : CPU_REG_NEXT.PC = {8'h00, 8'h10};
                RST_18 : CPU_REG_NEXT.PC = {8'h00, 8'h18};
                RST_20 : CPU_REG_NEXT.PC = {8'h00, 8'h20};
                RST_28 : CPU_REG_NEXT.PC = {8'h00, 8'h28};
                RST_30 : CPU_REG_NEXT.PC = {8'h00, 8'h30};
                RST_38 : CPU_REG_NEXT.PC = {8'h00, 8'h38};
                RST_40 : CPU_REG_NEXT.PC = {8'h00, 8'h40};
                RST_48 : CPU_REG_NEXT.PC = {8'h00, 8'h48};
                RST_50 : CPU_REG_NEXT.PC = {8'h00, 8'h50};
                RST_58 : CPU_REG_NEXT.PC = {8'h00, 8'h58};
                RST_60 : CPU_REG_NEXT.PC = {8'h00, 8'h60};
                    
                BIT0_A: `ALU_BIT_b_n(0, A)
                BIT1_A: `ALU_BIT_b_n(1, A)
                BIT2_A: `ALU_BIT_b_n(2, A)
                BIT3_A: `ALU_BIT_b_n(3, A)
                BIT4_A: `ALU_BIT_b_n(4, A)
                BIT5_A: `ALU_BIT_b_n(5, A)
                BIT6_A: `ALU_BIT_b_n(6, A)
                BIT7_A: `ALU_BIT_b_n(7, A)
                
                BIT0_B: `ALU_BIT_b_n(0, B)
                BIT1_B: `ALU_BIT_b_n(1, B)
                BIT2_B: `ALU_BIT_b_n(2, B)
                BIT3_B: `ALU_BIT_b_n(3, B)
                BIT4_B: `ALU_BIT_b_n(4, B)
                BIT5_B: `ALU_BIT_b_n(5, B)
                BIT6_B: `ALU_BIT_b_n(6, B)
                BIT7_B: `ALU_BIT_b_n(7, B)
                
                BIT0_C: `ALU_BIT_b_n(0, C)
                BIT1_C: `ALU_BIT_b_n(1, C)
                BIT2_C: `ALU_BIT_b_n(2, C)
                BIT3_C: `ALU_BIT_b_n(3, C)
                BIT4_C: `ALU_BIT_b_n(4, C)
                BIT5_C: `ALU_BIT_b_n(5, C)
                BIT6_C: `ALU_BIT_b_n(6, C)
                BIT7_C: `ALU_BIT_b_n(7, C)
                
                BIT0_D: `ALU_BIT_b_n(0, D)
                BIT1_D: `ALU_BIT_b_n(1, D)
                BIT2_D: `ALU_BIT_b_n(2, D)
                BIT3_D: `ALU_BIT_b_n(3, D)
                BIT4_D: `ALU_BIT_b_n(4, D)
                BIT5_D: `ALU_BIT_b_n(5, D)
                BIT6_D: `ALU_BIT_b_n(6, D)
                BIT7_D: `ALU_BIT_b_n(7, D)
                
                BIT0_E: `ALU_BIT_b_n(0, E)
                BIT1_E: `ALU_BIT_b_n(1, E)
                BIT2_E: `ALU_BIT_b_n(2, E)
                BIT3_E: `ALU_BIT_b_n(3, E)
                BIT4_E: `ALU_BIT_b_n(4, E)
                BIT5_E: `ALU_BIT_b_n(5, E)
                BIT6_E: `ALU_BIT_b_n(6, E)
                BIT7_E: `ALU_BIT_b_n(7, E)
                
                BIT0_H: `ALU_BIT_b_n(0, H)
                BIT1_H: `ALU_BIT_b_n(1, H)
                BIT2_H: `ALU_BIT_b_n(2, H)
                BIT3_H: `ALU_BIT_b_n(3, H)
                BIT4_H: `ALU_BIT_b_n(4, H)
                BIT5_H: `ALU_BIT_b_n(5, H)
                BIT6_H: `ALU_BIT_b_n(6, H)
                BIT7_H: `ALU_BIT_b_n(7, H)
                
                BIT0_L: `ALU_BIT_b_n(0, L)
                BIT1_L: `ALU_BIT_b_n(1, L)
                BIT2_L: `ALU_BIT_b_n(2, L)
                BIT3_L: `ALU_BIT_b_n(3, L)
                BIT4_L: `ALU_BIT_b_n(4, L)
                BIT5_L: `ALU_BIT_b_n(5, L)
                BIT6_L: `ALU_BIT_b_n(6, L)
                BIT7_L: `ALU_BIT_b_n(7, L)
                
                BIT0_T: `ALU_BIT_b_n(0, T)
                BIT1_T: `ALU_BIT_b_n(1, T)
                BIT2_T: `ALU_BIT_b_n(2, T)
                BIT3_T: `ALU_BIT_b_n(3, T)
                BIT4_T: `ALU_BIT_b_n(4, T)
                BIT5_T: `ALU_BIT_b_n(5, T)
                BIT6_T: `ALU_BIT_b_n(6, T)
                BIT7_T: `ALU_BIT_b_n(7, T)

                RES0_A: `ALU_SETRST_op_b_n(RES, 0, A)
                RES1_A: `ALU_SETRST_op_b_n(RES, 1, A)
                RES2_A: `ALU_SETRST_op_b_n(RES, 2, A)
                RES3_A: `ALU_SETRST_op_b_n(RES, 3, A)
                RES4_A: `ALU_SETRST_op_b_n(RES, 4, A)
                RES5_A: `ALU_SETRST_op_b_n(RES, 5, A)
                RES6_A: `ALU_SETRST_op_b_n(RES, 6, A)
                RES7_A: `ALU_SETRST_op_b_n(RES, 7, A)
                
                RES0_B: `ALU_SETRST_op_b_n(RES, 0, B)
                RES1_B: `ALU_SETRST_op_b_n(RES, 1, B)
                RES2_B: `ALU_SETRST_op_b_n(RES, 2, B)
                RES3_B: `ALU_SETRST_op_b_n(RES, 3, B)
                RES4_B: `ALU_SETRST_op_b_n(RES, 4, B)
                RES5_B: `ALU_SETRST_op_b_n(RES, 5, B)
                RES6_B: `ALU_SETRST_op_b_n(RES, 6, B)
                RES7_B: `ALU_SETRST_op_b_n(RES, 7, B)
                
                RES0_C: `ALU_SETRST_op_b_n(RES, 0, C)
                RES1_C: `ALU_SETRST_op_b_n(RES, 1, C)
                RES2_C: `ALU_SETRST_op_b_n(RES, 2, C)
                RES3_C: `ALU_SETRST_op_b_n(RES, 3, C)
                RES4_C: `ALU_SETRST_op_b_n(RES, 4, C)
                RES5_C: `ALU_SETRST_op_b_n(RES, 5, C)
                RES6_C: `ALU_SETRST_op_b_n(RES, 6, C)
                RES7_C: `ALU_SETRST_op_b_n(RES, 7, C)
                
                RES0_D: `ALU_SETRST_op_b_n(RES, 0, D)
                RES1_D: `ALU_SETRST_op_b_n(RES, 1, D)
                RES2_D: `ALU_SETRST_op_b_n(RES, 2, D)
                RES3_D: `ALU_SETRST_op_b_n(RES, 3, D)
                RES4_D: `ALU_SETRST_op_b_n(RES, 4, D)
                RES5_D: `ALU_SETRST_op_b_n(RES, 5, D)
                RES6_D: `ALU_SETRST_op_b_n(RES, 6, D)
                RES7_D: `ALU_SETRST_op_b_n(RES, 7, D)
                
                RES0_E: `ALU_SETRST_op_b_n(RES, 0, E)
                RES1_E: `ALU_SETRST_op_b_n(RES, 1, E)
                RES2_E: `ALU_SETRST_op_b_n(RES, 2, E)
                RES3_E: `ALU_SETRST_op_b_n(RES, 3, E)
                RES4_E: `ALU_SETRST_op_b_n(RES, 4, E)
                RES5_E: `ALU_SETRST_op_b_n(RES, 5, E)
                RES6_E: `ALU_SETRST_op_b_n(RES, 6, E)
                RES7_E: `ALU_SETRST_op_b_n(RES, 7, E)
                
                RES0_H: `ALU_SETRST_op_b_n(RES, 0, H)
                RES1_H: `ALU_SETRST_op_b_n(RES, 1, H)
                RES2_H: `ALU_SETRST_op_b_n(RES, 2, H)
                RES3_H: `ALU_SETRST_op_b_n(RES, 3, H)
                RES4_H: `ALU_SETRST_op_b_n(RES, 4, H)
                RES5_H: `ALU_SETRST_op_b_n(RES, 5, H)
                RES6_H: `ALU_SETRST_op_b_n(RES, 6, H)
                RES7_H: `ALU_SETRST_op_b_n(RES, 7, H)
                
                RES0_L: `ALU_SETRST_op_b_n(RES, 0, L)
                RES1_L: `ALU_SETRST_op_b_n(RES, 1, L)
                RES2_L: `ALU_SETRST_op_b_n(RES, 2, L)
                RES3_L: `ALU_SETRST_op_b_n(RES, 3, L)
                RES4_L: `ALU_SETRST_op_b_n(RES, 4, L)
                RES5_L: `ALU_SETRST_op_b_n(RES, 5, L)
                RES6_L: `ALU_SETRST_op_b_n(RES, 6, L)
                RES7_L: `ALU_SETRST_op_b_n(RES, 7, L)
                
                RES0_T: `ALU_SETRST_op_b_n(RES, 0, T)
                RES1_T: `ALU_SETRST_op_b_n(RES, 1, T)
                RES2_T: `ALU_SETRST_op_b_n(RES, 2, T)
                RES3_T: `ALU_SETRST_op_b_n(RES, 3, T)
                RES4_T: `ALU_SETRST_op_b_n(RES, 4, T)
                RES5_T: `ALU_SETRST_op_b_n(RES, 5, T)
                RES6_T: `ALU_SETRST_op_b_n(RES, 6, T)
                RES7_T: `ALU_SETRST_op_b_n(RES, 7, T)  
                
                SET0_A: `ALU_SETRST_op_b_n(SET, 0, A)
                SET1_A: `ALU_SETRST_op_b_n(SET, 1, A)
                SET2_A: `ALU_SETRST_op_b_n(SET, 2, A)
                SET3_A: `ALU_SETRST_op_b_n(SET, 3, A)
                SET4_A: `ALU_SETRST_op_b_n(SET, 4, A)
                SET5_A: `ALU_SETRST_op_b_n(SET, 5, A)
                SET6_A: `ALU_SETRST_op_b_n(SET, 6, A)
                SET7_A: `ALU_SETRST_op_b_n(SET, 7, A)
                
                SET0_B: `ALU_SETRST_op_b_n(SET, 0, B)
                SET1_B: `ALU_SETRST_op_b_n(SET, 1, B)
                SET2_B: `ALU_SETRST_op_b_n(SET, 2, B)
                SET3_B: `ALU_SETRST_op_b_n(SET, 3, B)
                SET4_B: `ALU_SETRST_op_b_n(SET, 4, B)
                SET5_B: `ALU_SETRST_op_b_n(SET, 5, B)
                SET6_B: `ALU_SETRST_op_b_n(SET, 6, B)
                SET7_B: `ALU_SETRST_op_b_n(SET, 7, B)
                
                SET0_C: `ALU_SETRST_op_b_n(SET, 0, C)
                SET1_C: `ALU_SETRST_op_b_n(SET, 1, C)
                SET2_C: `ALU_SETRST_op_b_n(SET, 2, C)
                SET3_C: `ALU_SETRST_op_b_n(SET, 3, C)
                SET4_C: `ALU_SETRST_op_b_n(SET, 4, C)
                SET5_C: `ALU_SETRST_op_b_n(SET, 5, C)
                SET6_C: `ALU_SETRST_op_b_n(SET, 6, C)
                SET7_C: `ALU_SETRST_op_b_n(SET, 7, C)
                
                SET0_D: `ALU_SETRST_op_b_n(SET, 0, D)
                SET1_D: `ALU_SETRST_op_b_n(SET, 1, D)
                SET2_D: `ALU_SETRST_op_b_n(SET, 2, D)
                SET3_D: `ALU_SETRST_op_b_n(SET, 3, D)
                SET4_D: `ALU_SETRST_op_b_n(SET, 4, D)
                SET5_D: `ALU_SETRST_op_b_n(SET, 5, D)
                SET6_D: `ALU_SETRST_op_b_n(SET, 6, D)
                SET7_D: `ALU_SETRST_op_b_n(SET, 7, D)
                
                SET0_E: `ALU_SETRST_op_b_n(SET, 0, E)
                SET1_E: `ALU_SETRST_op_b_n(SET, 1, E)
                SET2_E: `ALU_SETRST_op_b_n(SET, 2, E)
                SET3_E: `ALU_SETRST_op_b_n(SET, 3, E)
                SET4_E: `ALU_SETRST_op_b_n(SET, 4, E)
                SET5_E: `ALU_SETRST_op_b_n(SET, 5, E)
                SET6_E: `ALU_SETRST_op_b_n(SET, 6, E)
                SET7_E: `ALU_SETRST_op_b_n(SET, 7, E)
                
                SET0_H: `ALU_SETRST_op_b_n(SET, 0, H)
                SET1_H: `ALU_SETRST_op_b_n(SET, 1, H)
                SET2_H: `ALU_SETRST_op_b_n(SET, 2, H)
                SET3_H: `ALU_SETRST_op_b_n(SET, 3, H)
                SET4_H: `ALU_SETRST_op_b_n(SET, 4, H)
                SET5_H: `ALU_SETRST_op_b_n(SET, 5, H)
                SET6_H: `ALU_SETRST_op_b_n(SET, 6, H)
                SET7_H: `ALU_SETRST_op_b_n(SET, 7, H)
                
                SET0_L: `ALU_SETRST_op_b_n(SET, 0, L)
                SET1_L: `ALU_SETRST_op_b_n(SET, 1, L)
                SET2_L: `ALU_SETRST_op_b_n(SET, 2, L)
                SET3_L: `ALU_SETRST_op_b_n(SET, 3, L)
                SET4_L: `ALU_SETRST_op_b_n(SET, 4, L)
                SET5_L: `ALU_SETRST_op_b_n(SET, 5, L)
                SET6_L: `ALU_SETRST_op_b_n(SET, 6, L)
                SET7_L: `ALU_SETRST_op_b_n(SET, 7, L)
                
                SET0_T: `ALU_SETRST_op_b_n(SET, 0, T)
                SET1_T: `ALU_SETRST_op_b_n(SET, 1, T)
                SET2_T: `ALU_SETRST_op_b_n(SET, 2, T)
                SET3_T: `ALU_SETRST_op_b_n(SET, 3, T)
                SET4_T: `ALU_SETRST_op_b_n(SET, 4, T)
                SET5_T: `ALU_SETRST_op_b_n(SET, 5, T)
                SET6_T: `ALU_SETRST_op_b_n(SET, 6, T)
                SET7_T: `ALU_SETRST_op_b_n(SET, 7, T)
                
                EI: IME_NEXT = 1;    
                
                RST_IF:
                begin
                    DATA_out = DATA_in;
                    for (int i = 0; i < 5; i++)
                    begin
                        if (INTQ_INT[i])
                        begin
                            DATA_out[i] = 0;
                            break;
                        end
                    end
                end
                
                default: ;           
                
            endcase
            // Patch
            if ((INST == 8'hC1 || INST == 8'hD1 || INST == 8'hE1 || INST == 8'hF1) && !isCB && !isINT && cur_risc_num == 4)
            `INC_nn(SPh, SPl)
            
            if ((RISC_OPCODE[cur_risc_num] == RLC_A || RISC_OPCODE[cur_risc_num] == RL_A ||
                 RISC_OPCODE[cur_risc_num] == RRC_A || RISC_OPCODE[cur_risc_num] == RR_A)  && !isCB && !isINT)
            begin
                CPU_REG_NEXT.F = ALU_STATUS & 8'b0001_1111; 
            end
            
            if ((INST == 8'h09 || INST == 8'h19 || INST == 8'h29 || INST == 8'h39) && !isCB && !isINT)
            begin
                CPU_REG_NEXT.F = (ALU_STATUS & 8'b0111_1111) | (CPU_REG.F & 8'b1000_0000);  // Dont change Zero Flag
            end
            
            CPU_REG_NEXT.F = CPU_REG_NEXT.F & 8'b1111_0000;
            
            if (CPU_STATE_NEXT == CPU_IF) ADDR_NEXT = CPU_REG_NEXT.PC; // When PC is update at the last cycle, ADDR won't change in time, fix this
        end
        
    endcase
end


endmodule


module GB_Z80_DECODER
(
    input logic [7:0] CPU_OPCODE,
    input logic [4:0] INTQ,
    input logic isCB,
    input logic isINT,
    input logic [7:0] FLAG,
    output GB_Z80_RISC_OPCODE RISC_OPCODE[0:10],
    output logic [5:0] NUM_Tcnt, // How many RISC opcodes in total (1-5)
    output logic isPCMEM [0:10]
);

always_comb
begin

for (int i = 0; i <= 10; i ++)
begin
    RISC_OPCODE[i] = NOP;
    isPCMEM[i] = 0;
end

NUM_Tcnt = 6'd4;

if (!isINT)
begin
unique case ( {isCB, CPU_OPCODE} )
    9'h000: RISC_OPCODE[0] = NOP;
    9'h001: `DECODER_LDnn_d16(B, C)
    9'h002: `DECODER_LDnn_A(BC)
    9'h003: `DECODER_INC_nn(BC)
    9'h004: RISC_OPCODE[0] = INC_B;
    9'h005: RISC_OPCODE[0] = DEC_B;
    9'h006: `DECODER_LDn_d8(B)
    9'h007: RISC_OPCODE[0] = RLC_A;
    9'h008: `DECODER_LD_a16_SP
    9'h009: `DECODER_ADDHL_nn(B, C)
    9'h00A: `DECODER_LDA_nn(BC)
    9'h00B: `DECODER_DEC_nn(BC)
    9'h00C: RISC_OPCODE[0] = INC_C;
    9'h00D: RISC_OPCODE[0] = DEC_C;
    9'h00E:  `DECODER_LDn_d8(C)
    9'h00F: RISC_OPCODE[0] = RRC_A;
    9'h010: // STOP 0
    begin
        RISC_OPCODE[0] = NOP; // STOP not implemented yet
    end
    9'h011: `DECODER_LDnn_d16(D, E)
    9'h012: `DECODER_LDnn_A(DE)
    9'h013: `DECODER_INC_nn(DE)
    9'h014: RISC_OPCODE[0] = INC_D;
    9'h015: RISC_OPCODE[0] = DEC_D;
    9'h016: `DECODER_LDn_d8(D)
    9'h017: RISC_OPCODE[0]= RL_A;
    9'h018: // JR r8
    begin
        RISC_OPCODE[2] = JP_R8;
        NUM_Tcnt = 6'd12;
    end
    9'h019: `DECODER_ADDHL_nn(D, E)
    9'h01A: `DECODER_LDA_nn(DE)
    9'h01B: `DECODER_DEC_nn(DE)
    9'h01C: RISC_OPCODE[0] = INC_E;
    9'h01D: RISC_OPCODE[0] = DEC_E;
    9'h01E: `DECODER_LDn_d8(E)
    9'h01F: RISC_OPCODE[0] = RR_A;
    9'h020: // JR NZ,r8
        begin
            RISC_OPCODE[2] = JP_NZR8;
            NUM_Tcnt = FLAG[7] ? 6'd8 : 6'd12;
        end
    9'h021: `DECODER_LDnn_d16(H, L)
    9'h022: `DECODER_LD_HL_INC_A
    9'h023: `DECODER_INC_nn(HL)
    9'h024: RISC_OPCODE[0] = INC_H;
    9'h025: RISC_OPCODE[0] = DEC_H;
    9'h026: `DECODER_LDn_d8(H)
    9'h027: RISC_OPCODE[0] = DAA;
    9'h028: // JR Z,r8       
        begin
            RISC_OPCODE[2] = JP_ZR8;
            NUM_Tcnt = FLAG[7] ? 6'd12 : 6'd8;
        end
    9'h029: `DECODER_ADDHL_nn(H, L)
    9'h02A: `DECODER_LD_A_HL_INC
    9'h02B: `DECODER_DEC_nn(HL)
    9'h02C: RISC_OPCODE[0] = INC_L;
    9'h02D: RISC_OPCODE[0] = DEC_L;
    9'h02E: `DECODER_LDn_d8(L)
    9'h02F: RISC_OPCODE[0] = CPL;
    9'h030: 
        begin
            RISC_OPCODE[2] = JP_NCR8;
            NUM_Tcnt = FLAG[4] ? 6'd8 : 6'd12;
        end
    9'h031: `DECODER_LDnn_d16(SPh, SPl)
    9'h032: `DECODER_LD_HL_DEC_A
    9'h033: `DECODER_INC_nn(SP)
    9'h034: `DECODER_INC_MEM_HL
    9'h035: `DECODER_DEC_MEM_HL
    9'h036: `DECODER_LD_MEM_HL_d8
    9'h037: RISC_OPCODE[0] = SCF;
    9'h038: 
        begin
            RISC_OPCODE[2] = JP_CR8;
            NUM_Tcnt = FLAG[4] ? 6'd12 : 6'd8;
        end
    9'h039: `DECODER_ADDHL_nn(SPh, SPl)
    9'h03A: `DECODER_LD_A_HL_DEC
    9'h03B: `DECODER_DEC_nn(SP)
    9'h03C: RISC_OPCODE[0] = INC_A;
    9'h03D: RISC_OPCODE[0] = DEC_A;
    9'h03E: `DECODER_LDn_d8(A)
    9'h03F: RISC_OPCODE[0] = CCF;
    9'h040: RISC_OPCODE[0] = LD_BB;
    9'h041: RISC_OPCODE[0] = LD_BC;
    9'h042: RISC_OPCODE[0] = LD_BD;
    9'h043: RISC_OPCODE[0] = LD_BE;
    9'h044: RISC_OPCODE[0] = LD_BH;
    9'h045: RISC_OPCODE[0] = LD_BL;
    9'h046: `DECODER_LD_n_MEM_HL(B)
    9'h047: RISC_OPCODE[0] = LD_BA;
    9'h048: RISC_OPCODE[0] = LD_CB;
    9'h049: RISC_OPCODE[0] = LD_CC;
    9'h04A: RISC_OPCODE[0] = LD_CD;
    9'h04B: RISC_OPCODE[0] = LD_CE;
    9'h04C: RISC_OPCODE[0] = LD_CH;
    9'h04D: RISC_OPCODE[0] = LD_CL;
    9'h04E: `DECODER_LD_n_MEM_HL(C)
    9'h04F: RISC_OPCODE[0] = LD_CA; 
    9'h050: RISC_OPCODE[0] = LD_DB;
    9'h051: RISC_OPCODE[0] = LD_DC;
    9'h052: RISC_OPCODE[0] = LD_DD;
    9'h053: RISC_OPCODE[0] = LD_DE;
    9'h054: RISC_OPCODE[0] = LD_DH;
    9'h055: RISC_OPCODE[0] = LD_DL;
    9'h056: `DECODER_LD_n_MEM_HL(D)
    9'h057: RISC_OPCODE[0] = LD_DA;
    9'h058: RISC_OPCODE[0] = LD_EB;
    9'h059: RISC_OPCODE[0] = LD_EC;
    9'h05A: RISC_OPCODE[0] = LD_ED;
    9'h05B: RISC_OPCODE[0] = LD_EE;
    9'h05C: RISC_OPCODE[0] = LD_EH;
    9'h05D: RISC_OPCODE[0] = LD_EL;
    9'h05E: `DECODER_LD_n_MEM_HL(E)
    9'h05F: RISC_OPCODE[0] = LD_EA;  
    9'h060: RISC_OPCODE[0] = LD_HB;
    9'h061: RISC_OPCODE[0] = LD_HC;
    9'h062: RISC_OPCODE[0] = LD_HD;
    9'h063: RISC_OPCODE[0] = LD_HE;
    9'h064: RISC_OPCODE[0] = LD_HH;
    9'h065: RISC_OPCODE[0] = LD_HL;
    9'h066: `DECODER_LD_n_MEM_HL(H)
    9'h067: RISC_OPCODE[0] = LD_HA;
    9'h068: RISC_OPCODE[0] = LD_LB;
    9'h069: RISC_OPCODE[0] = LD_LC;
    9'h06A: RISC_OPCODE[0] = LD_LD;
    9'h06B: RISC_OPCODE[0] = LD_LE;
    9'h06C: RISC_OPCODE[0] = LD_LH;
    9'h06D: RISC_OPCODE[0] = LD_LL;
    9'h06E: `DECODER_LD_n_MEM_HL(L)
    9'h06F: RISC_OPCODE[0] = LD_LA;
    9'h070: `DECODER_LD_MEM_HL_n(B)
    9'h071: `DECODER_LD_MEM_HL_n(C) 
    9'h072: `DECODER_LD_MEM_HL_n(D) 
    9'h073: `DECODER_LD_MEM_HL_n(E) 
    9'h074: `DECODER_LD_MEM_HL_n(H) 
    9'h075: `DECODER_LD_MEM_HL_n(L)
    9'h076: RISC_OPCODE[0] = HALT;
    9'h077: `DECODER_LD_MEM_HL_n(A)   
    9'h078: RISC_OPCODE[0] = LD_AB;
    9'h079: RISC_OPCODE[0] = LD_AC;
    9'h07A: RISC_OPCODE[0] = LD_AD;
    9'h07B: RISC_OPCODE[0] = LD_AE;
    9'h07C: RISC_OPCODE[0] = LD_AH;
    9'h07D: RISC_OPCODE[0] = LD_AL;
    9'h07E: `DECODER_LD_n_MEM_HL(A)
    9'h07F: RISC_OPCODE[0] = LD_AA;
    9'h080: `DECODER_ALU_op_n(ADD, B)
    9'h081: `DECODER_ALU_op_n(ADD, C)
    9'h082: `DECODER_ALU_op_n(ADD, D)
    9'h083: `DECODER_ALU_op_n(ADD, E)
    9'h084: `DECODER_ALU_op_n(ADD, H)
    9'h085: `DECODER_ALU_op_n(ADD, L)
    9'h086: `DECODER_ALU_op_MEM_HL(ADD)
    9'h087: `DECODER_ALU_op_n(ADD, A)
    9'h088: `DECODER_ALU_op_n(ADC, B)
    9'h089: `DECODER_ALU_op_n(ADC, C)
    9'h08A: `DECODER_ALU_op_n(ADC, D)
    9'h08B: `DECODER_ALU_op_n(ADC, E)
    9'h08C: `DECODER_ALU_op_n(ADC, H)
    9'h08D: `DECODER_ALU_op_n(ADC, L)
    9'h08E: `DECODER_ALU_op_MEM_HL(ADC)
    9'h08F: `DECODER_ALU_op_n(ADC, A)
    9'h090: `DECODER_ALU_op_n(SUB, B)
    9'h091: `DECODER_ALU_op_n(SUB, C)
    9'h092: `DECODER_ALU_op_n(SUB, D)
    9'h093: `DECODER_ALU_op_n(SUB, E)
    9'h094: `DECODER_ALU_op_n(SUB, H)
    9'h095: `DECODER_ALU_op_n(SUB, L)
    9'h096: `DECODER_ALU_op_MEM_HL(SUB)
    9'h097: `DECODER_ALU_op_n(SUB, A)
    9'h098: `DECODER_ALU_op_n(SBC, B)
    9'h099: `DECODER_ALU_op_n(SBC, C)
    9'h09A: `DECODER_ALU_op_n(SBC, D)
    9'h09B: `DECODER_ALU_op_n(SBC, E)
    9'h09C: `DECODER_ALU_op_n(SBC, H)
    9'h09D: `DECODER_ALU_op_n(SBC, L)
    9'h09E: `DECODER_ALU_op_MEM_HL(SBC)
    9'h09F: `DECODER_ALU_op_n(SBC, A)
    9'h0A0: `DECODER_ALU_op_n(AND, B)
    9'h0A1: `DECODER_ALU_op_n(AND, C)
    9'h0A2: `DECODER_ALU_op_n(AND, D)
    9'h0A3: `DECODER_ALU_op_n(AND, E)
    9'h0A4: `DECODER_ALU_op_n(AND, H)
    9'h0A5: `DECODER_ALU_op_n(AND, L)
    9'h0A6: `DECODER_ALU_op_MEM_HL(AND)
    9'h0A7: `DECODER_ALU_op_n(AND, A)
    9'h0A8: `DECODER_ALU_op_n(XOR, B)
    9'h0A9: `DECODER_ALU_op_n(XOR, C)
    9'h0AA: `DECODER_ALU_op_n(XOR, D)
    9'h0AB: `DECODER_ALU_op_n(XOR, E)
    9'h0AC: `DECODER_ALU_op_n(XOR, H)
    9'h0AD: `DECODER_ALU_op_n(XOR, L)
    9'h0AE: `DECODER_ALU_op_MEM_HL(XOR)
    9'h0AF: `DECODER_ALU_op_n(XOR, A)
    9'h0B0: `DECODER_ALU_op_n(OR, B)
    9'h0B1: `DECODER_ALU_op_n(OR, C)
    9'h0B2: `DECODER_ALU_op_n(OR, D)
    9'h0B3: `DECODER_ALU_op_n(OR, E)
    9'h0B4: `DECODER_ALU_op_n(OR, H)
    9'h0B5: `DECODER_ALU_op_n(OR, L)
    9'h0B6: `DECODER_ALU_op_MEM_HL(OR)
    9'h0B7: `DECODER_ALU_op_n(OR, A)
    9'h0B8: `DECODER_ALU_op_n(CP, B)
    9'h0B9: `DECODER_ALU_op_n(CP, C)
    9'h0BA: `DECODER_ALU_op_n(CP, D)
    9'h0BB: `DECODER_ALU_op_n(CP, E)
    9'h0BC: `DECODER_ALU_op_n(CP, H)
    9'h0BD: `DECODER_ALU_op_n(CP, L)
    9'h0BE: `DECODER_ALU_op_MEM_HL(CP)
    9'h0BF: `DECODER_ALU_op_n(CP, A)
    9'h0C0: `DECODER_RET_NZ
    9'h0C1: `DECODER_POP_nn(B, C)
    9'h0C2: `DECODER_JP_NZ_a16
    9'h0C3: `DECODER_JP_a16
    9'h0C4: `DECODER_CALL_NZ_a16
    9'h0C5: `DECODER_PUSH_nn(B, C)
    9'h0C6: `DECODER_ALU_op_d8(ADD)
    9'h0C7: `DECODER_RST(00)
    9'h0C8: `DECODER_RET_Z
    9'h0C9: `DECODER_RET
    9'h0CA: `DECODER_JP_Z_a16
    9'h0CB: ; // CB Prefix
    9'h0CC: `DECODER_CALL_Z_a16
    9'h0CD: `DECODER_CALL_a16
    9'h0CE: `DECODER_ALU_op_d8(ADC)
    9'h0CF: `DECODER_RST(08)
    9'h0D0: `DECODER_RET_NC
    9'h0D1: `DECODER_POP_nn(D, E)
    9'h0D2: `DECODER_JP_NC_a16
    9'h0D3: ; // Undefined
    9'h0D4: `DECODER_CALL_NC_a16
    9'h0D5: `DECODER_PUSH_nn(D, E)
    9'h0D6: `DECODER_ALU_op_d8(SUB)
    9'h0D7: `DECODER_RST(10)
    9'h0D8: `DECODER_RET_C
    9'h0D9: `DECODER_RETI
    9'h0DA: `DECODER_JP_C_a16
    9'h0DB: ; // Undefined
    9'h0DC: `DECODER_CALL_C_a16
    9'h0DD: ; // Undefined
    9'h0DE: `DECODER_ALU_op_d8(SBC)
    9'h0DF: `DECODER_RST(18)
    9'h0E0: `DECODER_LDH_a8_A
    9'h0E1: `DECODER_POP_nn(H, L)
    9'h0E2: `DECODER_LDH_C_A
    9'h0E3: ; // Undefined
    9'h0E4: ; // Undefined
    9'h0E5: `DECODER_PUSH_nn(H, L)
    9'h0E6: `DECODER_ALU_op_d8(AND)     
    9'h0E7: `DECODER_RST(20)
    9'h0E8: `DECODER_ADD_SP_R8
    9'h0E9: RISC_OPCODE[0] = LD_PCHL;
    9'h0EA: `DECODER_LD_a16_A        
    9'h0EB: ; // Undefined
    9'h0EC: ; // Undefined
    9'h0ED: ; // Undefined
    9'h0EE: `DECODER_ALU_op_d8(XOR)
    9'h0EF: `DECODER_RST(28)
    9'h0F0: `DECODER_LDH_A_a8
    9'h0F1: `DECODER_POP_nn(A, F)
    9'h0F2: `DECODER_LDH_A_C
    9'h0F3: RISC_OPCODE[0] = DI;
    9'h0F4: ; // Undefined
    9'h0F5: `DECODER_PUSH_nn(A, F)
    9'h0F6: `DECODER_ALU_op_d8(OR)
    9'h0F7: `DECODER_RST(30)
    9'h0F8: `DECODER_LD_HL_SPR8
    9'h0F9: begin RISC_OPCODE[2] = LD_SPHL; NUM_Tcnt = 6'd8; end
    9'h0FA: `DECODER_LD_A_a16
    9'h0FB: RISC_OPCODE[0] = EI;
    9'h0FC: ; // Undefined
    9'h0FD: ; // Undefined
    9'h0FE: `DECODER_ALU_op_d8(CP)
    9'h0FF: `DECODER_RST(38)
    /* CB Commands */
    9'h100: RISC_OPCODE[0] = RLC_B;
    9'h101: RISC_OPCODE[0] = RLC_C;
    9'h102: RISC_OPCODE[0] = RLC_D;
    9'h103: RISC_OPCODE[0] = RLC_E;
    9'h104: RISC_OPCODE[0] = RLC_H;
    9'h105: RISC_OPCODE[0] = RLC_L;
    9'h106: `DECODER_CB_ALU_op_MEM_HL(RLC)
    9'h107: RISC_OPCODE[0] = RLC_A;
    9'h108: RISC_OPCODE[0] = RRC_B;
    9'h109: RISC_OPCODE[0] = RRC_C;
    9'h10A: RISC_OPCODE[0] = RRC_D;
    9'h10B: RISC_OPCODE[0] = RRC_E;
    9'h10C: RISC_OPCODE[0] = RRC_H;
    9'h10D: RISC_OPCODE[0] = RRC_L;
    9'h10E: `DECODER_CB_ALU_op_MEM_HL(RRC)
    9'h10F: RISC_OPCODE[0] = RRC_A;
    9'h110: RISC_OPCODE[0] = RL_B;
    9'h111: RISC_OPCODE[0] = RL_C;
    9'h112: RISC_OPCODE[0] = RL_D;
    9'h113: RISC_OPCODE[0] = RL_E;
    9'h114: RISC_OPCODE[0] = RL_H;
    9'h115: RISC_OPCODE[0] = RL_L;
    9'h116: `DECODER_CB_ALU_op_MEM_HL(RL)
    9'h117: RISC_OPCODE[0] = RL_A;
    9'h118: RISC_OPCODE[0] = RR_B;
    9'h119: RISC_OPCODE[0] = RR_C;
    9'h11A: RISC_OPCODE[0] = RR_D;
    9'h11B: RISC_OPCODE[0] = RR_E;
    9'h11C: RISC_OPCODE[0] = RR_H;
    9'h11D: RISC_OPCODE[0] = RR_L;
    9'h11E: `DECODER_CB_ALU_op_MEM_HL(RR)
    9'h11F: RISC_OPCODE[0] = RR_A;
    9'h120: RISC_OPCODE[0] = SLA_B;
    9'h121: RISC_OPCODE[0] = SLA_C;
    9'h122: RISC_OPCODE[0] = SLA_D;
    9'h123: RISC_OPCODE[0] = SLA_E;
    9'h124: RISC_OPCODE[0] = SLA_H;
    9'h125: RISC_OPCODE[0] = SLA_L;
    9'h126: `DECODER_CB_ALU_op_MEM_HL(SLA)
    9'h127: RISC_OPCODE[0] = SLA_A;
    9'h128: RISC_OPCODE[0] = SRA_B;
    9'h129: RISC_OPCODE[0] = SRA_C;
    9'h12A: RISC_OPCODE[0] = SRA_D;
    9'h12B: RISC_OPCODE[0] = SRA_E;
    9'h12C: RISC_OPCODE[0] = SRA_H;
    9'h12D: RISC_OPCODE[0] = SRA_L;
    9'h12E: `DECODER_CB_ALU_op_MEM_HL(SRA) 
    9'h12F: RISC_OPCODE[0] = SRA_A;
    9'h130: RISC_OPCODE[0] = SWAP_B;
    9'h131: RISC_OPCODE[0] = SWAP_C;
    9'h132: RISC_OPCODE[0] = SWAP_D;
    9'h133: RISC_OPCODE[0] = SWAP_E;
    9'h134: RISC_OPCODE[0] = SWAP_H;
    9'h135: RISC_OPCODE[0] = SWAP_L;
    9'h136: `DECODER_CB_ALU_op_MEM_HL(SWAP)
    9'h137: RISC_OPCODE[0] = SWAP_A;
    9'h138: RISC_OPCODE[0] = SRL_B;
    9'h139: RISC_OPCODE[0] = SRL_C;
    9'h13A: RISC_OPCODE[0] = SRL_D;
    9'h13B: RISC_OPCODE[0] = SRL_E;
    9'h13C: RISC_OPCODE[0] = SRL_H;
    9'h13D: RISC_OPCODE[0] = SRL_L;
    9'h13E: `DECODER_CB_ALU_op_MEM_HL(SRL) 
    9'h13F: RISC_OPCODE[0] = SRL_A;
    9'h140: `DECODER_CB_BIT_op_b_n(BIT, 0, B)
    9'h141: `DECODER_CB_BIT_op_b_n(BIT, 0, C)
    9'h142: `DECODER_CB_BIT_op_b_n(BIT, 0, D)
    9'h143: `DECODER_CB_BIT_op_b_n(BIT, 0, E)
    9'h144: `DECODER_CB_BIT_op_b_n(BIT, 0, H)
    9'h145: `DECODER_CB_BIT_op_b_n(BIT, 0, L)
    9'h146: `DECODER_CB_BIT_op_b_MEM_HL(BIT, 0)
    9'h147: `DECODER_CB_BIT_op_b_n(BIT, 0, A)  
    9'h148: `DECODER_CB_BIT_op_b_n(BIT, 1, B)
    9'h149: `DECODER_CB_BIT_op_b_n(BIT, 1, C)
    9'h14A: `DECODER_CB_BIT_op_b_n(BIT, 1, D)
    9'h14B: `DECODER_CB_BIT_op_b_n(BIT, 1, E)
    9'h14C: `DECODER_CB_BIT_op_b_n(BIT, 1, H)
    9'h14D: `DECODER_CB_BIT_op_b_n(BIT, 1, L)
    9'h14E: `DECODER_CB_BIT_op_b_MEM_HL(BIT, 1)
    9'h14F: `DECODER_CB_BIT_op_b_n(BIT, 1, A)
    9'h150: `DECODER_CB_BIT_op_b_n(BIT, 2, B)
    9'h151: `DECODER_CB_BIT_op_b_n(BIT, 2, C)
    9'h152: `DECODER_CB_BIT_op_b_n(BIT, 2, D)
    9'h153: `DECODER_CB_BIT_op_b_n(BIT, 2, E)
    9'h154: `DECODER_CB_BIT_op_b_n(BIT, 2, H)
    9'h155: `DECODER_CB_BIT_op_b_n(BIT, 2, L)
    9'h156: `DECODER_CB_BIT_op_b_MEM_HL(BIT, 2)
    9'h157: `DECODER_CB_BIT_op_b_n(BIT, 2, A)  
    9'h158: `DECODER_CB_BIT_op_b_n(BIT, 3, B)
    9'h159: `DECODER_CB_BIT_op_b_n(BIT, 3, C)
    9'h15A: `DECODER_CB_BIT_op_b_n(BIT, 3, D)
    9'h15B: `DECODER_CB_BIT_op_b_n(BIT, 3, E)
    9'h15C: `DECODER_CB_BIT_op_b_n(BIT, 3, H)
    9'h15D: `DECODER_CB_BIT_op_b_n(BIT, 3, L)
    9'h15E: `DECODER_CB_BIT_op_b_MEM_HL(BIT, 3)
    9'h15F: `DECODER_CB_BIT_op_b_n(BIT, 3, A)
    9'h160: `DECODER_CB_BIT_op_b_n(BIT, 4, B)
    9'h161: `DECODER_CB_BIT_op_b_n(BIT, 4, C)
    9'h162: `DECODER_CB_BIT_op_b_n(BIT, 4, D)
    9'h163: `DECODER_CB_BIT_op_b_n(BIT, 4, E)
    9'h164: `DECODER_CB_BIT_op_b_n(BIT, 4, H)
    9'h165: `DECODER_CB_BIT_op_b_n(BIT, 4, L)
    9'h166: `DECODER_CB_BIT_op_b_MEM_HL(BIT, 4)
    9'h167: `DECODER_CB_BIT_op_b_n(BIT, 4, A)  
    9'h168: `DECODER_CB_BIT_op_b_n(BIT, 5, B)
    9'h169: `DECODER_CB_BIT_op_b_n(BIT, 5, C)
    9'h16A: `DECODER_CB_BIT_op_b_n(BIT, 5, D)
    9'h16B: `DECODER_CB_BIT_op_b_n(BIT, 5, E)
    9'h16C: `DECODER_CB_BIT_op_b_n(BIT, 5, H)
    9'h16D: `DECODER_CB_BIT_op_b_n(BIT, 5, L)
    9'h16E: `DECODER_CB_BIT_op_b_MEM_HL(BIT, 5)
    9'h16F: `DECODER_CB_BIT_op_b_n(BIT, 5, A)
    9'h170: `DECODER_CB_BIT_op_b_n(BIT, 6, B)
    9'h171: `DECODER_CB_BIT_op_b_n(BIT, 6, C)
    9'h172: `DECODER_CB_BIT_op_b_n(BIT, 6, D)
    9'h173: `DECODER_CB_BIT_op_b_n(BIT, 6, E)
    9'h174: `DECODER_CB_BIT_op_b_n(BIT, 6, H)
    9'h175: `DECODER_CB_BIT_op_b_n(BIT, 6, L)
    9'h176: `DECODER_CB_BIT_op_b_MEM_HL(BIT, 6)
    9'h177: `DECODER_CB_BIT_op_b_n(BIT, 6, A)  
    9'h178: `DECODER_CB_BIT_op_b_n(BIT, 7, B)
    9'h179: `DECODER_CB_BIT_op_b_n(BIT, 7, C)
    9'h17A: `DECODER_CB_BIT_op_b_n(BIT, 7, D)
    9'h17B: `DECODER_CB_BIT_op_b_n(BIT, 7, E)
    9'h17C: `DECODER_CB_BIT_op_b_n(BIT, 7, H)
    9'h17D: `DECODER_CB_BIT_op_b_n(BIT, 7, L)
    9'h17E: `DECODER_CB_BIT_op_b_MEM_HL(BIT, 7)
    9'h17F: `DECODER_CB_BIT_op_b_n(BIT, 7, A)
    9'h180: `DECODER_CB_BIT_op_b_n(RES, 0, B)
    9'h181: `DECODER_CB_BIT_op_b_n(RES, 0, C)
    9'h182: `DECODER_CB_BIT_op_b_n(RES, 0, D)
    9'h183: `DECODER_CB_BIT_op_b_n(RES, 0, E)
    9'h184: `DECODER_CB_BIT_op_b_n(RES, 0, H)
    9'h185: `DECODER_CB_BIT_op_b_n(RES, 0, L)
    9'h186: `DECODER_CB_RES_SET_op_b_MEM_HL(RES, 0)
    9'h187: `DECODER_CB_BIT_op_b_n(RES, 0, A)  
    9'h188: `DECODER_CB_BIT_op_b_n(RES, 1, B)
    9'h189: `DECODER_CB_BIT_op_b_n(RES, 1, C)
    9'h18A: `DECODER_CB_BIT_op_b_n(RES, 1, D)
    9'h18B: `DECODER_CB_BIT_op_b_n(RES, 1, E)
    9'h18C: `DECODER_CB_BIT_op_b_n(RES, 1, H)
    9'h18D: `DECODER_CB_BIT_op_b_n(RES, 1, L)
    9'h18E: `DECODER_CB_RES_SET_op_b_MEM_HL(RES, 1)
    9'h18F: `DECODER_CB_BIT_op_b_n(RES, 1, A)
    9'h190: `DECODER_CB_BIT_op_b_n(RES, 2, B)
    9'h191: `DECODER_CB_BIT_op_b_n(RES, 2, C)
    9'h192: `DECODER_CB_BIT_op_b_n(RES, 2, D)
    9'h193: `DECODER_CB_BIT_op_b_n(RES, 2, E)
    9'h194: `DECODER_CB_BIT_op_b_n(RES, 2, H)
    9'h195: `DECODER_CB_BIT_op_b_n(RES, 2, L)
    9'h196: `DECODER_CB_RES_SET_op_b_MEM_HL(RES, 2)
    9'h197: `DECODER_CB_BIT_op_b_n(RES, 2, A)  
    9'h198: `DECODER_CB_BIT_op_b_n(RES, 3, B)
    9'h199: `DECODER_CB_BIT_op_b_n(RES, 3, C)
    9'h19A: `DECODER_CB_BIT_op_b_n(RES, 3, D)
    9'h19B: `DECODER_CB_BIT_op_b_n(RES, 3, E)
    9'h19C: `DECODER_CB_BIT_op_b_n(RES, 3, H)
    9'h19D: `DECODER_CB_BIT_op_b_n(RES, 3, L)
    9'h19E: `DECODER_CB_RES_SET_op_b_MEM_HL(RES, 3)
    9'h19F: `DECODER_CB_BIT_op_b_n(RES, 3, A)
    9'h1A0: `DECODER_CB_BIT_op_b_n(RES, 4, B)
    9'h1A1: `DECODER_CB_BIT_op_b_n(RES, 4, C)
    9'h1A2: `DECODER_CB_BIT_op_b_n(RES, 4, D)
    9'h1A3: `DECODER_CB_BIT_op_b_n(RES, 4, E)
    9'h1A4: `DECODER_CB_BIT_op_b_n(RES, 4, H)
    9'h1A5: `DECODER_CB_BIT_op_b_n(RES, 4, L)
    9'h1A6: `DECODER_CB_RES_SET_op_b_MEM_HL(RES, 4)
    9'h1A7: `DECODER_CB_BIT_op_b_n(RES, 4, A)  
    9'h1A8: `DECODER_CB_BIT_op_b_n(RES, 5, B)
    9'h1A9: `DECODER_CB_BIT_op_b_n(RES, 5, C)
    9'h1AA: `DECODER_CB_BIT_op_b_n(RES, 5, D)
    9'h1AB: `DECODER_CB_BIT_op_b_n(RES, 5, E)
    9'h1AC: `DECODER_CB_BIT_op_b_n(RES, 5, H)
    9'h1AD: `DECODER_CB_BIT_op_b_n(RES, 5, L)
    9'h1AE: `DECODER_CB_RES_SET_op_b_MEM_HL(RES, 5)
    9'h1AF: `DECODER_CB_BIT_op_b_n(RES, 5, A)
    9'h1B0: `DECODER_CB_BIT_op_b_n(RES, 6, B)
    9'h1B1: `DECODER_CB_BIT_op_b_n(RES, 6, C)
    9'h1B2: `DECODER_CB_BIT_op_b_n(RES, 6, D)
    9'h1B3: `DECODER_CB_BIT_op_b_n(RES, 6, E)
    9'h1B4: `DECODER_CB_BIT_op_b_n(RES, 6, H)
    9'h1B5: `DECODER_CB_BIT_op_b_n(RES, 6, L)
    9'h1B6: `DECODER_CB_RES_SET_op_b_MEM_HL(RES, 6)
    9'h1B7: `DECODER_CB_BIT_op_b_n(RES, 6, A)  
    9'h1B8: `DECODER_CB_BIT_op_b_n(RES, 7, B)
    9'h1B9: `DECODER_CB_BIT_op_b_n(RES, 7, C)
    9'h1BA: `DECODER_CB_BIT_op_b_n(RES, 7, D)
    9'h1BB: `DECODER_CB_BIT_op_b_n(RES, 7, E)
    9'h1BC: `DECODER_CB_BIT_op_b_n(RES, 7, H)
    9'h1BD: `DECODER_CB_BIT_op_b_n(RES, 7, L)
    9'h1BE: `DECODER_CB_RES_SET_op_b_MEM_HL(RES, 7)
    9'h1BF: `DECODER_CB_BIT_op_b_n(RES, 7, A)
    9'h1C0: `DECODER_CB_BIT_op_b_n(SET, 0, B)
    9'h1C1: `DECODER_CB_BIT_op_b_n(SET, 0, C)
    9'h1C2: `DECODER_CB_BIT_op_b_n(SET, 0, D)
    9'h1C3: `DECODER_CB_BIT_op_b_n(SET, 0, E)
    9'h1C4: `DECODER_CB_BIT_op_b_n(SET, 0, H)
    9'h1C5: `DECODER_CB_BIT_op_b_n(SET, 0, L)
    9'h1C6: `DECODER_CB_RES_SET_op_b_MEM_HL(SET, 0)
    9'h1C7: `DECODER_CB_BIT_op_b_n(SET, 0, A)  
    9'h1C8: `DECODER_CB_BIT_op_b_n(SET, 1, B)
    9'h1C9: `DECODER_CB_BIT_op_b_n(SET, 1, C)
    9'h1CA: `DECODER_CB_BIT_op_b_n(SET, 1, D)
    9'h1CB: `DECODER_CB_BIT_op_b_n(SET, 1, E)
    9'h1CC: `DECODER_CB_BIT_op_b_n(SET, 1, H)
    9'h1CD: `DECODER_CB_BIT_op_b_n(SET, 1, L)
    9'h1CE: `DECODER_CB_RES_SET_op_b_MEM_HL(SET, 1)
    9'h1CF: `DECODER_CB_BIT_op_b_n(SET, 1, A)
    9'h1D0: `DECODER_CB_BIT_op_b_n(SET, 2, B)
    9'h1D1: `DECODER_CB_BIT_op_b_n(SET, 2, C)
    9'h1D2: `DECODER_CB_BIT_op_b_n(SET, 2, D)
    9'h1D3: `DECODER_CB_BIT_op_b_n(SET, 2, E)
    9'h1D4: `DECODER_CB_BIT_op_b_n(SET, 2, H)
    9'h1D5: `DECODER_CB_BIT_op_b_n(SET, 2, L)
    9'h1D6: `DECODER_CB_RES_SET_op_b_MEM_HL(SET, 2)
    9'h1D7: `DECODER_CB_BIT_op_b_n(SET, 2, A)  
    9'h1D8: `DECODER_CB_BIT_op_b_n(SET, 3, B)
    9'h1D9: `DECODER_CB_BIT_op_b_n(SET, 3, C)
    9'h1DA: `DECODER_CB_BIT_op_b_n(SET, 3, D)
    9'h1DB: `DECODER_CB_BIT_op_b_n(SET, 3, E)
    9'h1DC: `DECODER_CB_BIT_op_b_n(SET, 3, H)
    9'h1DD: `DECODER_CB_BIT_op_b_n(SET, 3, L)
    9'h1DE: `DECODER_CB_RES_SET_op_b_MEM_HL(SET, 3)
    9'h1DF: `DECODER_CB_BIT_op_b_n(SET, 3, A)
    9'h1E0: `DECODER_CB_BIT_op_b_n(SET, 4, B)
    9'h1E1: `DECODER_CB_BIT_op_b_n(SET, 4, C)
    9'h1E2: `DECODER_CB_BIT_op_b_n(SET, 4, D)
    9'h1E3: `DECODER_CB_BIT_op_b_n(SET, 4, E)
    9'h1E4: `DECODER_CB_BIT_op_b_n(SET, 4, H)
    9'h1E5: `DECODER_CB_BIT_op_b_n(SET, 4, L)
    9'h1E6: `DECODER_CB_RES_SET_op_b_MEM_HL(SET, 4)
    9'h1E7: `DECODER_CB_BIT_op_b_n(SET, 4, A)  
    9'h1E8: `DECODER_CB_BIT_op_b_n(SET, 5, B)
    9'h1E9: `DECODER_CB_BIT_op_b_n(SET, 5, C)
    9'h1EA: `DECODER_CB_BIT_op_b_n(SET, 5, D)
    9'h1EB: `DECODER_CB_BIT_op_b_n(SET, 5, E)
    9'h1EC: `DECODER_CB_BIT_op_b_n(SET, 5, H)
    9'h1ED: `DECODER_CB_BIT_op_b_n(SET, 5, L)
    9'h1EE: `DECODER_CB_RES_SET_op_b_MEM_HL(SET, 5)
    9'h1EF: `DECODER_CB_BIT_op_b_n(SET, 5, A)
    9'h1F0: `DECODER_CB_BIT_op_b_n(SET, 6, B)
    9'h1F1: `DECODER_CB_BIT_op_b_n(SET, 6, C)
    9'h1F2: `DECODER_CB_BIT_op_b_n(SET, 6, D)
    9'h1F3: `DECODER_CB_BIT_op_b_n(SET, 6, E)
    9'h1F4: `DECODER_CB_BIT_op_b_n(SET, 6, H)
    9'h1F5: `DECODER_CB_BIT_op_b_n(SET, 6, L)
    9'h1F6: `DECODER_CB_RES_SET_op_b_MEM_HL(SET, 6)
    9'h1F7: `DECODER_CB_BIT_op_b_n(SET, 6, A)  
    9'h1F8: `DECODER_CB_BIT_op_b_n(SET, 7, B)
    9'h1F9: `DECODER_CB_BIT_op_b_n(SET, 7, C)
    9'h1FA: `DECODER_CB_BIT_op_b_n(SET, 7, D)
    9'h1FB: `DECODER_CB_BIT_op_b_n(SET, 7, E)
    9'h1FC: `DECODER_CB_BIT_op_b_n(SET, 7, H)
    9'h1FD: `DECODER_CB_BIT_op_b_n(SET, 7, L)
    9'h1FE: `DECODER_CB_RES_SET_op_b_MEM_HL(SET, 7)
    9'h1FF: `DECODER_CB_BIT_op_b_n(SET, 7, A)       
endcase
end
else
begin
    if (INTQ == 0) `DECODER_INTR(00)
    else
    begin
        for (int i = 0; i <= 4; i++)
        begin
            if(INTQ[i])
            begin
                unique case (i)
                    0: `DECODER_INTR(40)
                    1: `DECODER_INTR(48)
                    2: `DECODER_INTR(50)
                    3: `DECODER_INTR(58)
                    4: `DECODER_INTR(60)
                endcase
                break;
            end
        end
    end
    NUM_Tcnt = 6'd20;
end

for (int i = 0; i <= 10; i++)
begin
    if (RISC_OPCODE[i] == LD_BPC || RISC_OPCODE[i] == LD_CPC ||
        RISC_OPCODE[i] == LD_DPC || RISC_OPCODE[i] == LD_EPC ||
        RISC_OPCODE[i] == LD_HPC || RISC_OPCODE[i] == LD_LPC ||
        RISC_OPCODE[i] == LD_TPC || RISC_OPCODE[i] == LD_XPC ||
        RISC_OPCODE[i] == LD_APC || 
        RISC_OPCODE[i] == LD_PCB || RISC_OPCODE[i] == LD_PCC ||
        RISC_OPCODE[i] == LD_PCD || RISC_OPCODE[i] == LD_PCE ||
        RISC_OPCODE[i] == LD_PCH || RISC_OPCODE[i] == LD_PCL ||
        RISC_OPCODE[i] == LD_PCT ||
        RISC_OPCODE[i] == LD_PCSPl || RISC_OPCODE[i] == LD_PCSPh ||
        RISC_OPCODE[i] == LD_SPlPC || RISC_OPCODE[i] == LD_SPhPC ||
        RISC_OPCODE[i] == JP_R8 || RISC_OPCODE[i] == JP_NZR8 ||
        RISC_OPCODE[i] == JP_ZR8 || RISC_OPCODE[i] == JP_NCR8 ||
        RISC_OPCODE[i] == JP_CR8 
        )
    begin
            isPCMEM[i] = 1;
    end
end

end

endmodule


module GB_Z80_ALU
(
    input logic [7:0] OPD1_L,
    input logic [7:0] OPD2_L,
    input GB_Z80_ALU_OPCODE OPCODE,
    input logic [7:0] FLAG,    // the F register
    output logic [7:0] STATUS, // updated flag
    output logic [7:0] RESULT_L,
    output logic [7:0] RESULT_H // Not used for 8-bit ALU
);

// int is signed 32 bit 2 state integer
int opd1h_int;
int opd2h_int;
int opd16_int;
int result_int;
logic [7:0] status_int;

assign RESULT_L = result_int[7:0];
assign RESULT_H = result_int[15:8];
assign STATUS = status_int;
assign opd1h_int = {1'b0, OPD1_L};
assign opd2h_int = {1'b0, OPD2_L};

assign opd16_int = {OPD2_L, OPD1_L};

always_comb
begin

result_int = 0;
status_int = FLAG;
unique case (OPCODE)

    ALU_NOP : ;
    /* 8-bit Arithmetic */
    ALU_ADD, ALU_ADC :
    begin
        result_int = opd1h_int + opd2h_int + ((OPCODE == ALU_ADC) & FLAG[4]);
        status_int[7] = RESULT_L == 0; // Zero Flag (Z)
        status_int[6] = 0; //Subtract Flag (N)
        status_int[5] = opd1h_int[3:0] + opd2h_int[3:0] + ((OPCODE == ALU_ADC) & FLAG[4])> 5'h0F; // Half Carry Flag (H)
        status_int[4] = result_int[8]; // Carry Flag (C)
    end
    ALU_SUB, ALU_SBC, ALU_CP : // SUB and CP are the same command to the ALU
    begin
        result_int = opd2h_int - opd1h_int - ((OPCODE == ALU_SBC) & FLAG[4]);
        status_int[7] = RESULT_L == 0;
        status_int[6] = 1;
        status_int[5] = {1'b0, opd2h_int[3:0]} < ({1'b0, opd1h_int[3:0]} + ((OPCODE == ALU_SBC) & FLAG[4]));
        status_int[4] = opd2h_int < (opd1h_int + ((OPCODE == ALU_SBC) & FLAG[4]));
    end
    ALU_AND :
    begin
        result_int = opd1h_int & opd2h_int;
        status_int[7] = RESULT_L == 0;
        status_int[6] = 0;
        status_int[5] = 1;
        status_int[4] = 0;
    end
    ALU_OR :
    begin
        result_int = opd1h_int | opd2h_int;
        status_int[7] = RESULT_L == 0;
        status_int[6] = 0;
        status_int[5] = 0;
        status_int[4] = 0;
    end
    ALU_XOR :
    begin
        result_int = opd1h_int ^ opd2h_int;
        status_int[7] = RESULT_L == 0;
        status_int[6] = 0;
        status_int[5] = 0;
        status_int[4] = 0;
    end
    ALU_INC :
    begin
        result_int = opd1h_int + 1;
        status_int[7] = RESULT_L == 0;
        status_int[6] = 0;
        status_int[5] = opd1h_int[3:0] == 4'hF;
        status_int[4] = FLAG[4];
    end
    ALU_DEC :
    begin
        result_int = opd1h_int - 1;
        status_int[7] = RESULT_L == 0;
        status_int[6] = 1;
        status_int[5] = opd1h_int[3:0] == 4'h0;
        status_int[4] = FLAG[4];
    end
    ALU_CPL :
    begin
        for (int i = 0; i <= 7; i++)
            result_int[i] = ~opd1h_int[i];
        status_int[7] = FLAG[7];
        status_int[6] = 1;
        status_int[5] = 1;
        status_int[4] = FLAG[4];
    end
    ALU_BIT :
    begin
        status_int[7] = ~opd1h_int[opd2h_int];
        status_int[6] = 0;
        status_int[5] = 1;
        status_int[4] = FLAG[4];
    end
    ALU_SET :
    begin
        result_int = opd1h_int;
        result_int[opd2h_int] = 1;
    end
    ALU_RES :
    begin
        result_int = opd1h_int;
        result_int[opd2h_int] = 0;
    end
    ALU_INC16 :
    begin
        result_int = opd16_int + 1;
    end
    ALU_DEC16 :
    begin
        result_int = opd16_int - 1;
    end
    ALU_DAA :
    begin
        //https://ehaskins.com/2018-01-30%20Z80%20DAA/
        status_int[4] = 0;
        if (FLAG[5] || (!FLAG[6] && ((opd1h_int & 8'h0F) > 8'h09))) result_int = result_int | 8'h06;
        if (FLAG[4] || (!FLAG[6] && (opd1h_int > 8'h99)))
        begin
            result_int = result_int | 8'h60;
            status_int[4] = 1;
        end
        result_int = FLAG[6] ? opd1h_int - result_int : opd1h_int + result_int;
        status_int[7] = RESULT_L == 0;
        status_int[5] = 0;  
    end
    SHIFTER_SWAP:
    begin
        result_int = {opd1h_int[3:0], opd1h_int[7:4]};
        status_int[7] = RESULT_L == 0;
        status_int[6] = 0;
        status_int[5] = 0;
        status_int[4] = 0;
    end
    SHIFTER_RLC : 
    begin
        result_int = {opd1h_int[6:0], opd1h_int[7]};
        status_int[7] = RESULT_L == 0;
        status_int[6] = 0;
        status_int[5] = 0;
        status_int[4] = opd1h_int[7];
    end
    SHIFTER_RL :
    begin
        result_int = {opd1h_int[6:0], FLAG[4]};
        status_int[7] = RESULT_L == 0;
        status_int[6] = 0;
        status_int[5] = 0;
        status_int[4] = opd1h_int[7];
    end
    SHIFTER_RRC : 
    begin
        result_int = {opd1h_int[0], opd1h_int[7:1]};
        status_int[7] = RESULT_L == 0;
        status_int[6] = 0;
        status_int[5] = 0;
        status_int[4] = opd1h_int[0];
    end   
    SHIFTER_RR : 
    begin
        result_int = {FLAG[4], opd1h_int[7:1]};
        status_int[7] = RESULT_L == 0;
        status_int[6] = 0;
        status_int[5] = 0;
        status_int[4] = opd1h_int[0];
    end
    SHIFTER_SLA :
    begin
        result_int = {opd1h_int[6:0], 1'b0};
        status_int[7] = RESULT_L == 0;
        status_int[6] = 0;
        status_int[5] = 0;
        status_int[4] = opd1h_int[7];
    end
    SHIFTER_SRA :
    begin
        result_int = {opd1h_int[7], opd1h_int[7:1]};
        status_int[7] = RESULT_L == 0;
        status_int[6] = 0;
        status_int[5] = 0;
        status_int[4] = opd1h_int[0];
    end
    SHIFTER_SRL :
    begin
        result_int = {1'b0, opd1h_int[7:1]};
        status_int[7] = RESULT_L == 0;
        status_int[6] = 0;
        status_int[5] = 0;
        status_int[4] = opd1h_int[0];
    end            
endcase

end


endmodule

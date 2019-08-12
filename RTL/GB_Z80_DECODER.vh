`ifndef GB_Z80_DECODER_H
  `define GB_Z80_DECODER_H
  
  typedef enum
  {
    /* No Operation */
    NOP,
    
    HALT,
    STOP,
    
    /* 8-bit register operations */
    /* LD r1 <- r2 */
    LD_AA,  // 7F , Same as original
    LD_AB,  // 78 , Same as original
    LD_AC,  // 7A , Same as original
    LD_AD,
    LD_AE,
    LD_AH,
    LD_AL,
    LD_BB,
    LD_BA,
    LD_BC,
    LD_BD,
    LD_BE,
    LD_BH,
    LD_BL,
    LD_CA,
    LD_CB,
    LD_CC,
    LD_CD,
    LD_CE,
    LD_CH,
    LD_CL,
    LD_DA,
    LD_DB,
    LD_DC,
    LD_DD,
    LD_DE,
    LD_DH,
    LD_DL,
    LD_EA,
    LD_EB,
    LD_EC,
    LD_ED,
    LD_EE,
    LD_EH,
    LD_EL,
    LD_HA,
    LD_HB,
    LD_HC,
    LD_HD,
    LD_HE,
    LD_HH,
    LD_HL,
    LD_LA,
    LD_LB,
    LD_LC,
    LD_LD,
    LD_LE,
    LD_LL,
    LD_LH,
    LD_SPlL, // low side of SP
    LD_SPhH, // high side of SP
    LD_PCHL,
    LD_SPHL,
    
    LD_HL_SPR8,
    
    
    /* LD r1 <- (nn) */
    LD_APC,
    LD_BPC,
    LD_CPC,
    LD_DPC,
    LD_EPC,
    LD_HPC,
    LD_LPC,
    LD_TPC,
    LD_XPC,
    LD_SPlPC,
    LD_SPhPC,
    LD_ABC,
    LD_ADE,
    LD_AHL,
    LD_BHL,
    LD_CHL,
    LD_DHL,
    LD_EHL,
    LD_HHL,
    LD_LHL,
    LD_THL,
    LD_BSP,
    LD_CSP,
    LD_DSP,
    LD_ESP,
    LD_HSP,
    LD_LSP,
    LD_ASP,
    LD_FSP,
    LD_PClSP,
    LD_PChSP,
    LD_AHT,
    LD_AHC,
    LD_ATX,

    
    /* LD (nn) <- r1 */
    LD_PCB,
    LD_PCC,
    LD_PCD,
    LD_PCE,
    LD_PCH,
    LD_PCL,
    LD_PCT,
    LD_PCSPl,
    LD_PCSPh,
    LD_BCA,
    LD_DEA,
    LD_HLA,
    LD_HLB,
    LD_HLC,
    LD_HLD,
    LD_HLE,
    LD_HLH,
    LD_HLL,
    LD_HLT,
    LD_SPA,
    LD_SPB,
    LD_SPC,
    LD_SPD,
    LD_SPE,
    LD_SPH,
    LD_SPL,
    LD_SPF,
    LD_SPPCh,
    LD_SPPCl,
    LD_HTA,
    LD_HCA,
    LD_TXA,
    LD_TXSPl,
    LD_TXSPh,
    
    /* Arithmetic Operations */
    
    ADD_AA,  // Write back to A
    ADD_AB,
    ADD_AC,
    ADD_AD,
    ADD_AE,
    ADD_AH,
    ADD_AL,
    ADD_AT,
    ADD_AHL,
    ADD_LC,
    ADD_LE,  // 16-bit
    ADD_LL,
    ADD_LSPl,
    
    ADD_SPT, 
    
    ADC_AA,
    ADC_AB,
    ADC_AC,
    ADC_AD,
    ADC_AE,
    ADC_AH,
    ADC_AL,
    ADC_AT,
    ADC_AHL,
    ADC_HB,
    ADC_HD,
    ADC_HH,
    ADC_HSPh,
    
    SUB_AA,
    SUB_AB,
    SUB_AC,
    SUB_AD,
    SUB_AE,
    SUB_AH,
    SUB_AL,
    SUB_AT,
    SUB_AHL,

    SBC_AA,
    SBC_AB,
    SBC_AC,
    SBC_AD,
    SBC_AE,
    SBC_AH,
    SBC_AL,
    SBC_AT,
    SBC_AHL,
    
    AND_AA,
    AND_AB,
    AND_AC,
    AND_AD,
    AND_AE,
    AND_AH,
    AND_AL,
    AND_AT,
    AND_AHL,
    
    
    OR_AA,
    OR_AB,
    OR_AC,
    OR_AD,
    OR_AE,
    OR_AH,
    OR_AL,
    OR_AT,
    OR_AHL,
    
    XOR_AA,
    XOR_AB,
    XOR_AC,
    XOR_AD,
    XOR_AE,
    XOR_AH,
    XOR_AL,
    XOR_AT,
    XOR_AHL,
    
    CP_AA,
    CP_AB,
    CP_AC,
    CP_AD,
    CP_AE,
    CP_AH,
    CP_AL,
    CP_AT,
    CP_AHL,
    
    INC_A,
    INC_B,
    INC_C,
    INC_D,
    INC_E,
    INC_H,
    INC_L,
    INC_T,
    
    
    INC_BC, // 16-bit
    INC_DE,
    INC_HL,
    INC_SP,
    INC_TX,
    
    DEC_A,
    DEC_B,
    DEC_C,
    DEC_D,
    DEC_E,
    DEC_H,
    DEC_L,
    DEC_T,
    
    DEC_BC, // 16-bit
    DEC_DE,
    DEC_HL,
    DEC_SP,
    DEC_TX,
    
    RL_A,
    RL_B,
    RL_C,
    RL_D,
    RL_E,
    RL_H,
    RL_L,
    RL_T,
     
     
    RLC_A,
    RLC_B,
    RLC_C,
    RLC_D,
    RLC_E,
    RLC_H,
    RLC_L,
    RLC_T,
         
    RR_A,
    RR_B,
    RR_C,
    RR_D,
    RR_E,
    RR_H,
    RR_L,
    RR_T,
    
    RRC_A,
    RRC_B,
    RRC_C,
    RRC_D,
    RRC_E,
    RRC_H,
    RRC_L,
    RRC_T,
    
    SLA_A,
    SLA_B,
    SLA_C,
    SLA_D,
    SLA_E,
    SLA_H,
    SLA_L,
    SLA_T,
    
    SRA_A,
    SRA_B,
    SRA_C,
    SRA_D,
    SRA_E,
    SRA_H,
    SRA_L,
    SRA_T,
    
    SWAP_A,
    SWAP_B,
    SWAP_C,
    SWAP_D,
    SWAP_E,
    SWAP_H,
    SWAP_L,
    SWAP_T,
    
    SRL_A,
    SRL_B,
    SRL_C,
    SRL_D,
    SRL_E,
    SRL_H,
    SRL_L,
    SRL_T,
    
    DAA,
    CPL,
    SCF,
    CCF,
    
    JP_R8,
    JP_NZR8,
    JP_ZR8,
    JP_NCR8,
    JP_CR8,
    JP_TX,
    JP_Z_TX,
    JP_NZ_TX,
    JP_C_TX,
    JP_NC_TX,
    
    RST_00,
    RST_08,
    RST_10,
    RST_18,
    RST_20,
    RST_28,
    RST_30,
    RST_38,
    RST_40,
    RST_48,
    RST_50,
    RST_58,
    RST_60,
    
    BIT0_A,
    BIT1_A,
    BIT2_A,
    BIT3_A,
    BIT4_A,
    BIT5_A,
    BIT6_A,
    BIT7_A,
    
    BIT0_B,
    BIT1_B,
    BIT2_B,
    BIT3_B,
    BIT4_B,
    BIT5_B,
    BIT6_B,
    BIT7_B,
    
    BIT0_C,
    BIT1_C,
    BIT2_C,
    BIT3_C,
    BIT4_C,
    BIT5_C,
    BIT6_C,
    BIT7_C,
    
    BIT0_D,
    BIT1_D,
    BIT2_D,
    BIT3_D,
    BIT4_D,
    BIT5_D,
    BIT6_D,
    BIT7_D,
    
    BIT0_E,
    BIT1_E,
    BIT2_E,
    BIT3_E,
    BIT4_E,
    BIT5_E,
    BIT6_E,
    BIT7_E,
    
    BIT0_H,
    BIT1_H,
    BIT2_H,
    BIT3_H,
    BIT4_H,
    BIT5_H,
    BIT6_H,
    BIT7_H,
    
    BIT0_L,
    BIT1_L,
    BIT2_L,
    BIT3_L,
    BIT4_L,
    BIT5_L,
    BIT6_L,
    BIT7_L,
    
    BIT0_T,
    BIT1_T,
    BIT2_T,
    BIT3_T,
    BIT4_T,
    BIT5_T,
    BIT6_T,
    BIT7_T,
    
    RES0_A,
    RES1_A,
    RES2_A,
    RES3_A,
    RES4_A,
    RES5_A,
    RES6_A,
    RES7_A,
    
    RES0_B,
    RES1_B,
    RES2_B,
    RES3_B,
    RES4_B,
    RES5_B,
    RES6_B,
    RES7_B,
    
    RES0_C,
    RES1_C,
    RES2_C,
    RES3_C,
    RES4_C,
    RES5_C,
    RES6_C,
    RES7_C,
    
    RES0_D,
    RES1_D,
    RES2_D,
    RES3_D,
    RES4_D,
    RES5_D,
    RES6_D,
    RES7_D,
    
    RES0_E,
    RES1_E,
    RES2_E,
    RES3_E,
    RES4_E,
    RES5_E,
    RES6_E,
    RES7_E,
    
    RES0_H,
    RES1_H,
    RES2_H,
    RES3_H,
    RES4_H,
    RES5_H,
    RES6_H,
    RES7_H,
    
    RES0_L,
    RES1_L,
    RES2_L,
    RES3_L,
    RES4_L,
    RES5_L,
    RES6_L,
    RES7_L,
    
    RES0_T,
    RES1_T,
    RES2_T,
    RES3_T,
    RES4_T,
    RES5_T,
    RES6_T,
    RES7_T,
    
    SET0_A,
    SET1_A,
    SET2_A,
    SET3_A,
    SET4_A,
    SET5_A,
    SET6_A,
    SET7_A,
    
    SET0_B,
    SET1_B,
    SET2_B,
    SET3_B,
    SET4_B,
    SET5_B,
    SET6_B,
    SET7_B,
    
    SET0_C,
    SET1_C,
    SET2_C,
    SET3_C,
    SET4_C,
    SET5_C,
    SET6_C,
    SET7_C,
    
    SET0_D,
    SET1_D,
    SET2_D,
    SET3_D,
    SET4_D,
    SET5_D,
    SET6_D,
    SET7_D,
    
    SET0_E,
    SET1_E,
    SET2_E,
    SET3_E,
    SET4_E,
    SET5_E,
    SET6_E,
    SET7_E,
    
    SET0_H,
    SET1_H,
    SET2_H,
    SET3_H,
    SET4_H,
    SET5_H,
    SET6_H,
    SET7_H,
    
    SET0_L,
    SET1_L,
    SET2_L,
    SET3_L,
    SET4_L,
    SET5_L,
    SET6_L,
    SET7_L,
    
    SET0_T,
    SET1_T,
    SET2_T,
    SET3_T,
    SET4_T,
    SET5_T,
    SET6_T,
    SET7_T,
    
    EI,
    DI,
    LATCH_INTQ,
    RST_IF

  } GB_Z80_RISC_OPCODE;

`define DECODER_LDn_d8(n) \
begin \
    RISC_OPCODE[1] = LD_``n``PC; \
    NUM_Tcnt = 6'd8; \
end  

`define DECODER_LDnn_d16(n1, n2) \
begin \
    RISC_OPCODE[1] = LD_``n2``PC; \
    RISC_OPCODE[3] = LD_``n1``PC; \
    NUM_Tcnt = 6'd12; \
end

`define DECODER_LDnn_A(nn) \
begin \
    RISC_OPCODE[1] = LD_``nn``A; \
    NUM_Tcnt = 6'd8; \
end

`define DECODER_LDA_nn(nn) \
begin \
    RISC_OPCODE[1] = LD_A``nn; \
    NUM_Tcnt = 6'd8; \
end

`define DECODER_ADDHL_nn(n1, n2) \
begin \
    RISC_OPCODE[1] = ADD_L``n2; \
    RISC_OPCODE[2] = ADC_H``n1; \
    NUM_Tcnt = 6'd8; \
end

`define DECODER_DEC_nn(nn) \
begin \
    RISC_OPCODE[1] = DEC_``nn; \
    NUM_Tcnt = 6'd8; \
end

`define DECODER_INC_nn(nn) \
begin \
    RISC_OPCODE[1] = INC_``nn; \
    NUM_Tcnt = 6'd8; \
end

`define DECODER_LD_HL_INC_A \
begin \
    RISC_OPCODE[1] = LD_HLA; \
    RISC_OPCODE[2] = INC_HL; \
    NUM_Tcnt = 6'd8; \
end
`define DECODER_LD_HL_DEC_A \
begin \
    RISC_OPCODE[1] = LD_HLA; \
    RISC_OPCODE[2] = DEC_HL; \
    NUM_Tcnt = 6'd8; \
end
`define DECODER_LD_A_HL_INC \
begin \
    RISC_OPCODE[1] = LD_AHL; \
    RISC_OPCODE[2] = INC_HL; \
    NUM_Tcnt = 6'd8; \
end
`define DECODER_LD_A_HL_DEC \
begin \
    RISC_OPCODE[1] = LD_AHL; \
    RISC_OPCODE[2] = DEC_HL; \
    NUM_Tcnt = 6'd8; \
end
`define DECODER_INC_MEM_HL \
begin \
    RISC_OPCODE[1] = LD_THL; \
    RISC_OPCODE[2] = INC_T; \
    RISC_OPCODE[3] = LD_HLT; \
    NUM_Tcnt = 6'd12; \
end
`define DECODER_DEC_MEM_HL \
begin \
    RISC_OPCODE[1] = LD_THL; \
    RISC_OPCODE[2] = DEC_T; \
    RISC_OPCODE[3] = LD_HLT; \
    NUM_Tcnt = 6'd12; \
end
`define DECODER_LD_MEM_HL_d8 \
begin \
    RISC_OPCODE[1] = LD_TPC; \
    RISC_OPCODE[3] = LD_HLT; \
    NUM_Tcnt = 6'd12; \
end                
`define DECODER_LD_n_MEM_HL(n) \
begin \
    RISC_OPCODE[2] = LD_``n``HL; \
    NUM_Tcnt = 6'd8; \
end
`define DECODER_LD_MEM_HL_n(n) \
begin \
     RISC_OPCODE[2] = LD_HL``n; \
     NUM_Tcnt = 6'd8; \
end
`define DECODER_ALU_op_n(op, n) \
begin \
     RISC_OPCODE[0] = ``op``_A``n; \
end

`define DECODER_ALU_op_d8(op) \
begin \
    RISC_OPCODE[1] = LD_TPC; \
    RISC_OPCODE[2] = ``op``_AT; \
    NUM_Tcnt = 6'd8; \
end

`define DECODER_ALU_op_MEM_HL(op) \
begin \
     RISC_OPCODE[2] = ``op``_A``HL; \
     NUM_Tcnt = 6'd8; \
end

`define DECODER_RET \
begin \
    RISC_OPCODE[1] = LD_PClSP; \
    RISC_OPCODE[2] = INC_SP; \
    RISC_OPCODE[3] = LD_PChSP; \
    RISC_OPCODE[4] = INC_SP; \
    NUM_Tcnt = 6'd16; \
end

`define DECODER_RETI \
begin \
    RISC_OPCODE[1] = LD_PClSP; \
    RISC_OPCODE[2] = INC_SP; \
    RISC_OPCODE[3] = LD_PChSP; \
    RISC_OPCODE[4] = INC_SP; \
    RISC_OPCODE[5] = EI; \
    NUM_Tcnt = 6'd16; \
end

`define DECODER_RET_NZ \
begin \
    if (!FLAG[7]) \
        begin \
            RISC_OPCODE[3] = LD_PClSP; \
            RISC_OPCODE[4] = INC_SP; \
            RISC_OPCODE[5] = LD_PChSP; \
            RISC_OPCODE[6] = INC_SP; \
        end \
    NUM_Tcnt = FLAG[7] ? 6'd8 : 6'd20; \
end

`define DECODER_RET_Z \
begin \
    if (FLAG[7]) \
        begin \
            RISC_OPCODE[3] = LD_PClSP; \
            RISC_OPCODE[4] = INC_SP; \
            RISC_OPCODE[5] = LD_PChSP; \
            RISC_OPCODE[6] = INC_SP; \
        end \
    NUM_Tcnt = FLAG[7] ? 6'd20 : 6'd8; \
end

`define DECODER_RET_C \
begin \
    if (FLAG[4]) \
        begin \
            RISC_OPCODE[3] = LD_PClSP; \
            RISC_OPCODE[4] = INC_SP; \
            RISC_OPCODE[5] = LD_PChSP; \
            RISC_OPCODE[6] = INC_SP; \
        end \
    NUM_Tcnt = FLAG[4] ? 6'd20 : 6'd8; \
end

`define DECODER_RET_NC \
begin \
    if (!FLAG[4]) \
        begin \
            RISC_OPCODE[3] = LD_PClSP; \
            RISC_OPCODE[4] = INC_SP; \
            RISC_OPCODE[5] = LD_PChSP; \
            RISC_OPCODE[6] = INC_SP; \
        end \
    NUM_Tcnt = FLAG[4] ? 6'd8 : 6'd20; \
end

`define DECODER_PUSH_nn(n1, n2) \
begin \
    RISC_OPCODE[2] = DEC_SP; \
    RISC_OPCODE[3] = LD_SP``n1; \
    RISC_OPCODE[4] = DEC_SP; \
    RISC_OPCODE[5] = LD_SP``n2; \
    NUM_Tcnt = 6'd16; \
end

`define DECODER_POP_nn(n1, n2) \
begin \
    RISC_OPCODE[2] = LD_``n2``SP; \
    RISC_OPCODE[3] = INC_SP; \
    RISC_OPCODE[4] = LD_``n1``SP; \
    RISC_OPCODE[5] = INC_SP; \
    NUM_Tcnt = 6'd12; \
end

`define DECODER_JP_Z_a16 \
begin \
    RISC_OPCODE[1] = LD_XPC; \
    RISC_OPCODE[3] = LD_TPC; \
    RISC_OPCODE[6] = JP_Z_TX; \
    NUM_Tcnt = FLAG[7] ? 6'd16 : 6'd12; \
end

`define DECODER_JP_NZ_a16 \
begin \
    RISC_OPCODE[1] = LD_XPC; \
    RISC_OPCODE[3] = LD_TPC; \
    RISC_OPCODE[6] = JP_NZ_TX; \
    NUM_Tcnt = FLAG[7] ? 6'd12 : 6'd16; \
end

`define DECODER_JP_C_a16 \
begin \
    RISC_OPCODE[1] = LD_XPC; \
    RISC_OPCODE[3] = LD_TPC; \
    RISC_OPCODE[6] = JP_C_TX; \
    NUM_Tcnt = FLAG[4] ? 6'd16 : 6'd12; \
end

`define DECODER_JP_NC_a16 \
begin \
    RISC_OPCODE[1] = LD_XPC; \
    RISC_OPCODE[3] = LD_TPC; \
    RISC_OPCODE[6] = JP_NC_TX; \
    NUM_Tcnt = FLAG[4] ? 6'd12 : 6'd16; \
end


`define DECODER_JP_a16 \
begin \
    RISC_OPCODE[1] = LD_XPC; \
    RISC_OPCODE[3] = LD_TPC; \
    RISC_OPCODE[6] = JP_TX; \
    NUM_Tcnt = 6'd16; \
end

`define DECODER_CALL_a16 \
begin \
    RISC_OPCODE[2] = LD_XPC; \
    RISC_OPCODE[3] = LD_TPC; \
    RISC_OPCODE[5] = DEC_SP; \
    RISC_OPCODE[6] = LD_SPPCh; \
    RISC_OPCODE[7] = DEC_SP; \
    RISC_OPCODE[8] = LD_SPPCl; \
    RISC_OPCODE[9] = JP_TX; \
    NUM_Tcnt = 6'd24; \
end

`define DECODER_CALL_Z_a16 \
begin \
    RISC_OPCODE[2] = LD_XPC; \
    RISC_OPCODE[3] = LD_TPC; \
    if (FLAG[7]) \
    begin \
        RISC_OPCODE[5] = DEC_SP; \
        RISC_OPCODE[6] = LD_SPPCh; \
        RISC_OPCODE[7] = DEC_SP; \
        RISC_OPCODE[8] = LD_SPPCl; \
        RISC_OPCODE[9] = JP_Z_TX; \
    end \
    NUM_Tcnt = FLAG[7] ? 6'd24 : 6'd12; \
end

`define DECODER_CALL_NZ_a16 \
begin \
    RISC_OPCODE[2] = LD_XPC; \
    RISC_OPCODE[3] = LD_TPC; \
    if (!FLAG[7]) \
    begin \
        RISC_OPCODE[5] = DEC_SP; \
        RISC_OPCODE[6] = LD_SPPCh; \
        RISC_OPCODE[7] = DEC_SP; \
        RISC_OPCODE[8] = LD_SPPCl; \
        RISC_OPCODE[9] = JP_NZ_TX; \
    end \
    NUM_Tcnt = FLAG[7] ? 6'd12 : 6'd24; \
end

`define DECODER_CALL_C_a16 \
begin \
    RISC_OPCODE[2] = LD_XPC; \
    RISC_OPCODE[3] = LD_TPC; \
    if (FLAG[4]) \
    begin \
        RISC_OPCODE[5] = DEC_SP; \
        RISC_OPCODE[6] = LD_SPPCh; \
        RISC_OPCODE[7] = DEC_SP; \
        RISC_OPCODE[8] = LD_SPPCl; \
        RISC_OPCODE[9] = JP_C_TX; \
    end \
    NUM_Tcnt = FLAG[4] ? 6'd24 : 6'd12; \
end

`define DECODER_CALL_NC_a16 \
begin \
    RISC_OPCODE[2] = LD_XPC; \
    RISC_OPCODE[3] = LD_TPC; \
    if (!FLAG[4]) \
    begin \
        RISC_OPCODE[5] = DEC_SP; \
        RISC_OPCODE[6] = LD_SPPCh; \
        RISC_OPCODE[7] = DEC_SP; \
        RISC_OPCODE[8] = LD_SPPCl; \
        RISC_OPCODE[9] = JP_NC_TX; \
    end \
    NUM_Tcnt = FLAG[4] ? 6'd12 : 6'd24; \
end

`define DECODER_RST(addr) \
begin \
    RISC_OPCODE[2] = DEC_SP; \
    RISC_OPCODE[3] = LD_SPPCh; \
    RISC_OPCODE[4] = DEC_SP; \
    RISC_OPCODE[5] = LD_SPPCl; \
    RISC_OPCODE[6] = RST_``addr; \
    NUM_Tcnt = 6'd16; \
end

// Read/Write timing is important for TIMER
`define DECODER_LDH_a8_A \
begin \
    RISC_OPCODE[1] = LD_TPC; \
    RISC_OPCODE[3] = LD_HTA; \
    NUM_Tcnt = 6'd12; \
end

`define DECODER_LDH_A_a8 \
begin \
    RISC_OPCODE[1] = LD_TPC; \
    RISC_OPCODE[3] = LD_AHT; \
    NUM_Tcnt = 6'd12; \
end

`define DECODER_LDH_C_A \
begin \
    RISC_OPCODE[2] = LD_HCA; \
    NUM_Tcnt = 6'd8; \
end

`define DECODER_LDH_A_C \
begin \
    RISC_OPCODE[2] = LD_AHC; \
    NUM_Tcnt = 6'd8; \
end

`define DECODER_ADD_SP_R8 \
begin \
     RISC_OPCODE[1] = LD_TPC; \
     RISC_OPCODE[3] = ADD_SPT; \
     NUM_Tcnt = 6'd16; \
end

`define DECODER_LD_HL_SPR8 \
begin \
    RISC_OPCODE[1] = LD_TPC; \
    RISC_OPCODE[3] = LD_HL_SPR8; \
    NUM_Tcnt = 6'd12; \
end

`define DECODER_LD_a16_SP \
begin \
    RISC_OPCODE[1] = LD_XPC; \
    RISC_OPCODE[3] = LD_TPC; \
    RISC_OPCODE[6] = LD_TXSPl; \
    RISC_OPCODE[7] = INC_TX; \
    RISC_OPCODE[8] = LD_TXSPh; \
    NUM_Tcnt = 6'd20; \
end

`define DECODER_LD_a16_A \
begin \
    RISC_OPCODE[1] = LD_XPC; \
    RISC_OPCODE[3] = LD_TPC; \
    RISC_OPCODE[5] = LD_TXA; \
    NUM_Tcnt = 6'd16; \
end

`define DECODER_LD_A_a16 \
begin \
    RISC_OPCODE[1] = LD_XPC; \
    RISC_OPCODE[3] = LD_TPC; \
    RISC_OPCODE[5] = LD_ATX; \
    NUM_Tcnt = 6'd16; \
end   

`define DECODER_CB_ALU_op_MEM_HL(op) \
begin \
     RISC_OPCODE[2] = LD_THL; \
     RISC_OPCODE[3] = ``op``_T; \
     RISC_OPCODE[4] = LD_HLT; \
     NUM_Tcnt = 6'd12; \
end

`define DECODER_CB_BIT_op_b_n(op, b, n) \
begin \
    RISC_OPCODE[0] = ``op````b``_``n; \
end

 // Cycle count is wrong on the html
`define DECODER_CB_BIT_op_b_MEM_HL(op, b) \
begin \
    RISC_OPCODE[1] = LD_THL; \
    RISC_OPCODE[2] = ``op````b``_T; \
    NUM_Tcnt = 6'd8; \
end

`define DECODER_CB_RES_SET_op_b_MEM_HL(op, b) \
begin \
    RISC_OPCODE[1] = LD_THL; \
    RISC_OPCODE[2] = ``op````b``_T; \
    RISC_OPCODE[3] = LD_HLT; \
    NUM_Tcnt = 6'd12; \
end

`define DECODER_INTR(addr)\
begin \
    RISC_OPCODE[0] = DI; \
    RISC_OPCODE[1] = DEC_SP; \
    RISC_OPCODE[2] = LD_SPPCh; \
    RISC_OPCODE[3] = LATCH_INTQ; \
    RISC_OPCODE[4] = RST_IF; \
    RISC_OPCODE[5] = DEC_SP; \
    RISC_OPCODE[6] = LD_SPPCl; \
    RISC_OPCODE[7] = RST_``addr; \
    NUM_Tcnt = 6'd20; \
end
                       
`endif

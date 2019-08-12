/* This are the ALU OPCODEs */
`ifndef GB_Z80_ALU_H
  `define GB_Z80_ALU_H

typedef enum
{
    ALU_NOP,
    ALU_ADD,
    ALU_ADC,
    ALU_SUB,
    ALU_SBC,
    ALU_CP,
    ALU_AND,
    ALU_OR,
    ALU_XOR,
    ALU_INC,
    ALU_DEC,
    ALU_CPL,
    ALU_BIT,
    ALU_SET,
    ALU_RES,
    ALU_INC16, // 16 bit alu operation
    ALU_DEC16, // 16 bit alu operation
    ALU_DAA,
    
    /* Shifter Operations */
    SHIFTER_SWAP,
    SHIFTER_RLC,
    SHIFTER_RL,
    SHIFTER_RRC,
    SHIFTER_RR,
    SHIFTER_SLA,
    SHIFTER_SRA,
    SHIFTER_SRL
    
} GB_Z80_ALU_OPCODE;

`endif
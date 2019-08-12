/* Internal Registers */
`ifndef GB_Z80_CPU_H
  `define GB_Z80_CPU_H

typedef struct
{
    logic [7:0] A; logic [7:0] F;  // AF, F for Flag
    logic [7:0] B; logic [7:0] C;  // BC, nn
    logic [7:0] D; logic [7:0] E;  // DE, nn
    logic [7:0] H; logic [7:0] L;  // HL, nn
    
    logic [7:0] T; logic [7:0] X;  // Temp Result

    logic [7:0] SPh, SPl;          // Stack Pointer
    logic [15:0] PC;               // Program Counter
} GB_Z80_REG;

`define WR_nn(n1, n2) \
    begin \
        WR_NEXT = 1; \
        ADDR_NEXT = {CPU_REG.``n1, CPU_REG.``n2}; \
    end

`define WR_FFn(n) \
    begin \
        WR_NEXT = 1; \
        ADDR_NEXT = {8'hFF, CPU_REG.``n}; \
    end

`define RD_nn(n1, n2) \
    begin \
        RD_NEXT = 1; \
        ADDR_NEXT = {CPU_REG.``n1, CPU_REG.``n2}; \
    end   

`define RD_FFn(n) \
    begin \
        RD_NEXT = 1; \
        ADDR_NEXT = {8'hFF, CPU_REG.``n}; \
    end     

`define LD_n_n(n1, n2) \
    begin \
        CPU_REG_NEXT.``n1 = CPU_REG.``n2; \
    end

`define INC_n(n) \
    begin \
        ALU_OPCODE = ALU_INC; \
        ALU_OPD1_L = CPU_REG.``n; \
        CPU_REG_NEXT.``n = ALU_RESULT_L; \
        CPU_REG_NEXT.F = ALU_STATUS; \
    end
    
`define DEC_n(n) \
    begin \
        ALU_OPCODE = ALU_DEC; \
        ALU_OPD1_L = CPU_REG.``n; \
        CPU_REG_NEXT.``n = ALU_RESULT_L; \
        CPU_REG_NEXT.F = ALU_STATUS; \
    end

// {n1, n2}
`define INC_nn(n1, n2) \
    begin \
        ALU_OPCODE = ALU_INC16; \
        ALU_OPD1_L = CPU_REG.``n2; \
        ALU_OPD2_L = CPU_REG.``n1; \
        CPU_REG_NEXT.``n1 = ALU_RESULT_H; \
        CPU_REG_NEXT.``n2 = ALU_RESULT_L; \
    end
`define DEC_nn(n1, n2) \
    begin \
        ALU_OPCODE = ALU_DEC16; \
        ALU_OPD1_L = CPU_REG.``n2; \
        ALU_OPD2_L = CPU_REG.``n1; \
        CPU_REG_NEXT.``n1 = ALU_RESULT_H; \
        CPU_REG_NEXT.``n2 = ALU_RESULT_L; \
    end
    
`define ADDL_n(n) \
    begin \
        ALU_OPCODE = ALU_ADD; \
        ALU_OPD2_L = CPU_REG.L; \
        ALU_OPD1_L = CPU_REG.``n; \
        CPU_REG_NEXT.L = ALU_RESULT_L; \
        CPU_REG_NEXT.F = ALU_STATUS; \
    end

`define ADCH_n(n) \
    begin \
        ALU_OPCODE = ALU_ADC; \
        ALU_OPD2_L = CPU_REG.H; \
        ALU_OPD1_L = CPU_REG.``n; \
        CPU_REG_NEXT.H = ALU_RESULT_L; \
        CPU_REG_NEXT.F = ALU_STATUS; \
    end

`define ALU_A_op_n(op, n) \
    begin \
        ALU_OPCODE = ALU_``op; \
        ALU_OPD2_L = CPU_REG.A; \
        ALU_OPD1_L = CPU_REG.``n; \
        CPU_REG_NEXT.A = ALU_RESULT_L; \
        CPU_REG_NEXT.F = ALU_STATUS; \
    end
    
`define ALU_A_op_Data_in(op) \
    begin \
        ALU_OPCODE = ALU_``op; \
        ALU_OPD2_L = CPU_REG.A; \
        ALU_OPD1_L = DATA_in; \
        CPU_REG_NEXT.A = ALU_RESULT_L; \
        CPU_REG_NEXT.F = ALU_STATUS; \
    end
    
`define ALU_op_n(op, n) \
    begin \
        ALU_OPCODE = ALU_``op; \
        ALU_OPD2_L = CPU_REG.A; \
        ALU_OPD1_L = CPU_REG.``n; \
        //CPU_REG_NEXT.A = ALU_RESULT_L; \
        CPU_REG_NEXT.F = ALU_STATUS; \
    end

    
`define ALU_BIT_b_n(b, n) \
    begin \
        ALU_OPCODE = ALU_BIT; \
        ALU_OPD2_L = ``b; \
        ALU_OPD1_L = CPU_REG.``n; \
        CPU_REG_NEXT.F = ALU_STATUS; \
    end
    
`define ALU_SETRST_op_b_n(op, b, n) \
    begin \
        ALU_OPCODE = ALU_``op; \
        ALU_OPD2_L = ``b; \
        ALU_OPD1_L = CPU_REG.``n; \
        CPU_REG_NEXT.``n = ALU_RESULT_L; \
    end   
    
`define ALU_op_Data_in(op) \
    begin \
        ALU_OPCODE = ALU_``op; \
        ALU_OPD2_L = CPU_REG.A; \
        ALU_OPD1_L = DATA_in; \
        //CPU_REG_NEXT.A = ALU_RESULT_L; \
        CPU_REG_NEXT.F = ALU_STATUS; \
    end
        
`define SHIFTER_op_n(op, n) \
    begin \
        ALU_OPCODE = SHIFTER_``op; \
        ALU_OPD1_L = CPU_REG.``n; \
        CPU_REG_NEXT.``n = ALU_RESULT_L; \
        CPU_REG_NEXT.F = ALU_STATUS; \
    end             
 
 `define DAA \
    begin \
        ALU_OPCODE = ALU_DAA; \
        ALU_OPD1_L = CPU_REG.A; \
        CPU_REG_NEXT.A = ALU_RESULT_L; \
        CPU_REG_NEXT.F = ALU_STATUS; \
    end
 `define DO_JPR8 {1'b0, CPU_REG.PC} + {3'b0, DATA_in[6:0]} - {1'b0, DATA_in[7], 7'b000_0000}
 
 // H and C are based on Unsigned ! added to SPl
 `define ADD_SPT \
    begin \
        {CPU_REG_NEXT.SPh, CPU_REG_NEXT.SPl} = {1'b0, CPU_REG.SPh, CPU_REG.SPl} + {3'b0, CPU_REG.T[6:0]} - {1'b0, CPU_REG.T[7], 7'b000_0000}; \
        CPU_REG_NEXT.F = \
        { \
            2'b00, \
            (({1'b0, CPU_REG.SPl[3:0]} + {1'b0, CPU_REG.T[3:0]}) > 5'h0F), \
            (({1'b0, CPU_REG.SPl[7:0]} + {1'b0, CPU_REG.T[7:0]}) > 9'h0FF), \
            CPU_REG.F[3:0] \
        }; \
    end
    
`define LD_HL_SPR8 \
    begin \
        {CPU_REG_NEXT.H, CPU_REG_NEXT.L} = {1'b0, CPU_REG.SPh, CPU_REG.SPl} + {3'b0, CPU_REG.T[6:0]} - {1'b0, CPU_REG.T[7], 7'b000_0000}; \
        CPU_REG_NEXT.F = \
        { \
            2'b00, \
             (({1'b0, CPU_REG.SPl[3:0]} + {1'b0, CPU_REG.T[3:0]}) > 5'h0F), \
             (({1'b0, CPU_REG.SPl[7:0]} + {1'b0, CPU_REG.T[7:0]}) > 9'h0FF), \
            CPU_REG.F[3:0] \
        }; \
    end
    
`endif
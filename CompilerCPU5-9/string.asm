    LOAD R0 0x18    ; 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    ADDI SP SP 1
    RET

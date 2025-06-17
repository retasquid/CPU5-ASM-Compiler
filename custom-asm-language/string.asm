    LOAD R0 0x56    ;V 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x61    ;a 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x6c    ;l 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x65    ;e 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x75    ;u 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x72    ;r 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x64    ;d 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x65    ;e 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x52    ;R 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x31    ;1 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x3e    ;> 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    ADDI SP SP 1
    RET

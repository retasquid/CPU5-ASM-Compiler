start :
    LOAD SP 0x40ff
    LOAD R0 0
    OUTI R0 BAUDH
    LOAD R0 9602
    OUTI R0 BAUDL
loop :
    CALL
    SUBI SP SP 1
    JMP LOAD_phrase
    LOAD R1 1

ecoute : 
    INI R0 UART
    SUBI R0 R0 0
    JM0 ecoute
    SUBI R10 R0 13
    JM0 entree
    CALL 
    SUBI SP SP 1
    JMP send_uart
    JMP ecoute

entree :

backspace : 

end :
    JMP end


LOAD_phrase :
    LOAD R0 0x45    ;E 
    CALL 
    SUBI SP SP 1
    JMP send_uart

    LOAD R0 0x6e    ;n 
    CALL 
    SUBI SP SP 1
    JMP send_uart

    LOAD R0 0x74    ;t 
    CALL 
    SUBI SP SP 1
    JMP send_uart

    LOAD R0 0x72    ;r 
    CALL 
    SUBI SP SP 1
    JMP send_uart

    LOAD R0 0x65    ;e 
    CALL 
    SUBI SP SP 1
    JMP send_uart

    LOAD R0 0x7a    ;z 
    CALL 
    SUBI SP SP 1
    JMP send_uart

    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP send_uart

    LOAD R0 0x75    ;u 
    CALL 
    SUBI SP SP 1
    JMP send_uart

    LOAD R0 0x6e    ;n 
    CALL 
    SUBI SP SP 1
    JMP send_uart

    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP send_uart

    LOAD R0 0x6e    ;n 
    CALL 
    SUBI SP SP 1
    JMP send_uart

    LOAD R0 0x6f    ;o 
    CALL 
    SUBI SP SP 1
    JMP send_uart

    LOAD R0 0x6d    ;m 
    CALL 
    SUBI SP SP 1
    JMP send_uart

    LOAD R0 0x62    ;b 
    CALL 
    SUBI SP SP 1
    JMP send_uart

    LOAD R0 0x72    ;r 
    CALL 
    SUBI SP SP 1
    JMP send_uart

    LOAD R0 0x65    ;e 
    CALL 
    SUBI SP SP 1
    JMP send_uart

    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP send_uart

    LOAD R0 0x3a    ;: 
    CALL 
    SUBI SP SP 1
    JMP send_uart

    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP send_uart

    ADDI SP SP 1
    RET

send_uart :
    ORI R0 R0 0b0000000100000000 ; Set the send bit
    OUTI R0 UART
    ANDI R0 R0 0b1111111011111111 ; Clear the send bit
    OUTI R0 UART
wait_uart_send :
    INI R0 STATUS  ; Read the status register
    ANDI R0 R0 0x02  ; Check if the UART is busy
    JM0 end_uart_send  ; If end sending, jump
    JMP wait_uart_send  ; Loop until UART is ready
end_uart_send :
    ADDI SP SP 1  ; Decrement Stack Pointer
    RET
    CONFINT
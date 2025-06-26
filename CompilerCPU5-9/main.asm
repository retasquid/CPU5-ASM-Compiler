; IO :          0x0000
;               ******
;               0x3fff

; RAM :         0x4000
;               ******
;               0x7fff

; RAM2 :        0x8000  IMPLEMENTED :   0x8000
;               ******                  ******
;               0xbfff                  0x9fff

; RAM3 :        0xc000  IMPLEMENTED :   0xc000
;               ******
;               0xffff                  0xc0ff

start :
    LOAD SP 0xc0ff
    LOAD R0 0
    OUTI R0 BAUDH
    LOAD R0 9600
    OUTI R0 BAUDL
loop :
    LOAD R0 0xdc
    OUTI R0 GPO0

    CALL            ;print("Test reception ") 
    SUBI SP SP 1
    JMP print_header

test_reception : 
    LOAD R1 0x4000
    CALL
    SUBI SP SP 1
    JMP input_uart
    SUBI R7 R0 0

    IN R0 R7
    CALL                ;byte 0
    SUBI SP SP 1
    JMP print_number
    ADDI R7 R7 1

    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart

    IN R0 R7
    CALL                ;byte 1
    SUBI SP SP 1
    JMP print_number
    ADDI R7 R7 1

    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart

    IN R0 R7
    CALL                ;byte 2
    SUBI SP SP 1
    JMP print_number
    ADDI R7 R7 1

    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart

    IN R0 R7
    CALL                ;byte 3
    SUBI SP SP 1
    JMP print_number
    ADDI R7 R7 1

    LOAD R0 13    ;\
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 10    ;n 
    CALL 
    SUBI SP SP 1
    JMP output_uart

    JMP test_reception


end :

    JMP end

;  ////////////////////////////////////////////
; ///   Standard Library for the CPU 5.9   ///
;////////////////////////////////////////////

;input : R1 = start string pointer
;output : R0 = start string pointer
;output : R1 = end string pointer
input_uart : 
    AND R11 R1 R1
    INI R0 UART
    SUBI R0 R0 0
    JM0 input_uart
    SUBI R10 R0 13
    JM0 entree
    SUBI R10 R0 8
    JM0 backSpace
    OUT R0 R1
    ADDI R1 R1 1
    JMP continue_print_char
    backSpace : 
        SUBI R1 R1 1
        OUT R10 R1
    continue_print_char : 
        CALL
        SUBI SP SP 1
        JMP output_uart
        JMP input_uart
    entree : 
        OUT R10 R1 ;end str with NULL
        AND R0 R11 R11
    ADDI SP SP 1
    RET

;input : R0 = character to send
output_uart :
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



;input : R0 = number
;output : R0 = BCDL
;output : R1 = BCDH
print_number :
    AND R2 R0 R0
    LOAD R0 0x0000  ; BCDL
    LOAD R1 0x0000  ; BCDH
    LOAD R3 0x0000  ; i
    i_loop :
        LOAD R4 0x0000  ; j
    j_loop :
        SHR R10 R0 R4   ;if (((bcd >> j) & 0xF) >= 5)
        ANDI R10 R10 0xF
        SUBI R10 R10 5
        JMN else   ;{
        LOAD R10 3      ;bcdl += (3 << j)
        SHL R10 R10 R4
        ADD R0 R0 R10   ;}
    else :
        ADDI R4 R4 4    ;for (int j = 0; j < 16; j+=4)
        SUBI R10 R4 16
        JMN j_loop
        ANDI R10 R1 0xF
        SUBI R10 R10 5
        JMN else2   ;{
        ADDI R1 R1 3      ;bcdh += 3
    else2 :
        SHLI R10 R1 1    ;bcdH = (bcdH << 1) | (bcdL>>15);
        SHRI R11 R0 15
        OR R1 R10 R11
        SHLI R10 R0 1    ;bcdL = (bcdL << 1) | (binary >> 15);
        SHRI R11 R2 15
        OR R0 R10 R11
        SHLI R2 R2 1    ;binary <<= 1;
        ADDI R3 R3 1    ;for (int i = 0; i < 16; i++)
        SUBI R10 R3 16
        JMN i_loop   
    digit1 :
        ANDI R8 R1 0xF
        JM0 digit2
        CALL
        SUBI SP SP 1
        JMP output_uart_special
    digit2 :
        ANDI R9 R0 0xF000
        ADD R10 R9 R8
        JM0 digit3
        SHRI R8 R9 12
        CALL
        SUBI SP SP 1
        JMP output_uart_special
    digit3 :
        ANDI R9 R0 0xF00
        ADD R10 R10 R9
        JM0 digit4
        SHRI R8 R9 8
        CALL
        SUBI SP SP 1
        JMP output_uart_special
    digit4 :
        ANDI R9 R0 0xF0
        ADD R10 R9 R10
        JM0 digit5
        SHRI R8 R9 4
        CALL
        SUBI SP SP 1
        JMP output_uart_special
    digit5 :
        ANDI R8 R0 0xF
        CALL
        SUBI SP SP 1
        JMP output_uart_special
        ADDI SP SP 1  
        RET
output_uart_special :
    ORI R8 R8 0b0000000100110000 ; Set the send bit
    OUTI R8 UART
    ANDI R8 R8 0b1111111011001111 ; Clear the send bit
    OUTI R8 UART
    wait_uart_send_special :
        INI PC STATUS  ; Read the status register
        ANDI PC PC 0x02  ; Check if the UART is busy
        JM0 end_uart_send_special  ; If end sending, jump
        JMP wait_uart_send_special  ; Loop until UART is ready
    end_uart_send_special :
        ADDI SP SP 1  ; Decrement Stack Pointer
        RET


print_header : 
    LOAD R0 13    ;\
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 10    ;n 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x2d    ;- 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x3c    ;< 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x3c    ;< 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x54    ;T 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x65    ;e 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x73    ;s 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x74    ;t 
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
    LOAD R0 0x74    ;t 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x72    ;r 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x61    ;a 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x6e    ;n 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x73    ;s 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x6d    ;m 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x69    ;i 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x73    ;s 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x69    ;i 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x6f    ;o 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x6e    ;n 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x53    ;S 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x65    ;e 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x72    ;r 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x69    ;i 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x65    ;e 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x3e    ;> 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x3e    ;> 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x2d    ;- 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 13    ;\
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 10    ;n
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 13    ;\
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 10    ;n 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    ADDI SP SP 1
    RET

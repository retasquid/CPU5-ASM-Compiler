; IO :          0x0000
;               ******
;               0x3fff

; RAM :         0x4000  IMPLEMENTED :   0x4000
;               ******                  ******
;               0x7fff                  0x40ff

; NOT_USED :    0x8000
;               ******
;               0xbfff

; NOT_USED :    0xc000
;               ******
;               0xffff

start :
    LOAD SP 0x40ff
    LOAD R0 0
    OUTI R0 BAUDH
    LOAD R0 9600
    OUTI R0 BAUDL
loop :
    CALL            ;print("Calculateur de resistance series ") 
    SUBI SP SP 1
    JMP print_header

    CALL            ;print("Entrez valeur resistance 1: ") 
    SUBI SP SP 1
    JMP print_R1

    LOAD R1 RAM0
    CALL   
    SUBI SP SP 1
    JMP input_uart   ; Read input from UART

    LOAD R0 RAM0
    CALL 
    SUBI SP SP 1
    JMP string_to_int
    OUTI R0 0x4010

    LOAD R0 13    ;\
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 10    ;n 
    CALL 
    SUBI SP SP 1
    JMP output_uart

    CALL            ;print("Entrez valeur resistance 2: ") 
    SUBI SP SP 1
    JMP print_R2

    LOAD R1 RAM0
    CALL
    SUBI SP SP 1
    JMP input_uart   ; Read input from UART

    LOAD R0 RAM0
    CALL 
    SUBI SP SP 1
    JMP string_to_int
    OUTI R0 0x4011

    LOAD R0 13    ;\
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 10    ;n 
    CALL 
    SUBI SP SP 1
    JMP output_uart

    CALL            ;print("valeur Req : ") 
    SUBI SP SP 1
    JMP print_Req

    INI R0 0x4010
    INI R1 0x4011
    CALL 
    SUBI SP SP 1
    JMP mult

    CALL 
    SUBI SP SP 1
    JMP print_number

    LOAD R0 13    ;\
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 10    ;n 

    CALL 
    SUBI SP SP 1
    JMP output_uart

end :
    JMP loop

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

;input : R0 = char* str
;output : R0 = number
string_to_int :
    LOAD R10 0 ;uint16_t result = 0;
    LOAD R11 0 ;int i = 0;
    for_0000 :  ;for (int i = 0; str[i] != '\0'; i++) {
        IN R12 R0
        ADDI R0 R0 1
        SUBI R12 R12 0 ;str[i] != '\0'
        JM0 end_string_to_int
        SHLI R13 R10 3 ;(result << 3)
        SHLI PC R10 1 ;(result << 1)
        ADD R13 R13 PC ;(result << 3)+(result << 1)
        SUBI R12 R12 0x30 ;str[i] - '0'
        ADD R10 R13 R12 ;(result << 3)+(result << 1)+(str[i] - '0')
        ADDI R11 R11 1 ;i++
        JMP for_0000
    end_string_to_int :
        AND R0 R10 R10 ;return result;
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
        ANDI R10 R0 0xF00
        ADD R8 R10 R9
        JM0 digit4
        SHRI R8 R10 8
        CALL
        SUBI SP SP 1
        JMP output_uart_special
    digit4 :
        ANDI R11 R0 0xF0
        ADD R10 R11 R10
        JM0 digit5
        SHRI R8 R11 4
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

;input : R0 = start string pointer
output_uart_string :
    IN R1 R0  ; Read the first byte of the string
    ADDI R0 R0 1  ; Increment the pointer to the next character
    ADDI R1 R1 0   ;test end with '\O'
    JM0 end_uart_send_str  ; If end of string, jump
    ORI R1 R1 0b100000000 ; Set the send bit
    OUTI R1 UART
    ANDI R1 R1 0b011111111 ; Clear the send bit
    OUTI R1 UART
    wait_uart_send_str :
        INI R1 STATUS  ; Read the status register
        ANDI R1 R1 0x02  ; Check if the UART is busy
        JM0 output_uart_string   ; If end sending, jump
        JMP wait_uart_send_str  ; Loop until UART is ready
    end_uart_send_str :
        ADDI SP SP 1  ; Decrement Stack Pointer
        RET

;input : R0 = a
;input : R1 = b
;output : R0 = product of a and b
mult :
    LOAD R3 0x0 ;int sign = 1
    LOAD R4 0 ;int32_t result = 0
    SUBI R0 R0 0 ;if (a < 0) {
    JMN mult_neg_a
    JMP mult_check_b
    mult_neg_a : 
        SUB R0 R4 R0 ;    a = -a;
        NAND R3 R3 R3 ;    sign = ~sign;
    mult_check_b :
        SUBI R1 R1 0 ;if (b < 0) {
        JMN mult_neg_b
        JMP mult_check_ainfb
    mult_neg_b :
        SUB R1 R4 R1 ;    a = -a;
        NAND R3 R3 R3 ;    sign = ~sign;
    mult_check_ainfb :
        SUB R10 R0 R1 ;if(a<b){
        XOR R0 R0 R1  ;a = a ^ b;
        XOR R1 R0 R1  ;b = a ^ b; 
        XOR R0 R0 R1  ;a = a ^ b;
    while_0000 : 
        SUBI R1 R1 0  ;while (b != 0) {
        JM0 mult_end
        ANDI R10 R1 1 ;        if (b & 1) { 
        JM0 mult_skip_add
        ADD R4 R4 R0 ;            result += a;
    mult_skip_add :
        SHLI R0 R0 1 ;        a <<= 1;
        SHRI R1 R1 1 ;        b >>= 1;
        JMP while_0000
    mult_end :
        SUBI R3 R3 0 ;if (sign < 0) {
        JM0 mult_return_pos
        SUB R0 R1 R4
        ADDI SP SP 1
        RET ;        return result;
    mult_return_pos : 
        AND R0 R4 R4
        ADDI SP SP 1
        RET ;        return result;


print_R1 : 
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

    
print_R2 : 
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
    LOAD R0 0x32    ;2
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



print_Req :
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
    LOAD R0 0x65    ;e 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x71    ;q 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x3a    ;: 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    ADDI SP SP 1
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

    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart

    LOAD R1 40
    for_0001 :
    SUBI R1 R1 1
    JM0 continue_print_char001
        LOAD R0 0x2f    ;/ 
        CALL 
        SUBI SP SP 1
        JMP output_uart
    JMP for_0001
    continue_print_char001 :
    LOAD R0 13    ;\
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 10    ;n 
    CALL 
    SUBI SP SP 1
    JMP output_uart

    LOAD R0 0x2f    ;/ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x2f    ;/ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x43    ;C 
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
    LOAD R0 0x63    ;c 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x75    ;u 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x6c    ;l 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x61    ;a 
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
    LOAD R0 0xe9    ;� 
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
    LOAD R0 0x73    ;s 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x74    ;t 
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
    LOAD R0 0x63    ;c 
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
    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x65    ;e 
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
    LOAD R0 0xe9    ;� 
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
    LOAD R0 0x73    ;s 
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

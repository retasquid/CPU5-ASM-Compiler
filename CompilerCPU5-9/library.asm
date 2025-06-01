send_uart :
    INI R0 RAM0  ;take the commande to send
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
    IN PC SP  ; Read the return adress from Stack Pointer
    RET

send_uart_string :
    INI R0 RAM0  ;take the pointer to send
read_char :
    IN R1 R0  ; Read the first byte of the string
    ADDI R0 R0 1  ; Increment the pointer to the next character
    ADDI R1 R1 0   ;test end with '\O'
    JM0 end_uart_send  ; If end of string, jump
    ORI R1 R1 0b100000000 ; Set the send bit
    OUTI R1 UART
    ANDI R1 R1 0b011111111 ; Clear the send bit
    OUTI R1 UART
wait_uart_send :
    INI R1 STATUS  ; Read the status register
    ANDI R1 R1 0x02  ; Check if the UART is busy
    JM0 read_char   ; If end sending, jump
    JMP wait_uart_send  ; Loop until UART is ready
end_uart_send :
    ADDI SP SP 1  ; Decrement Stack Pointer
    IN PC SP  ; Read the return adress from Stack Pointer
    RET

transfert_spi :  
    INI R0 RAM0  ;take the commande to send
    ORI R0 R0  0b0000000100000000 ; Set the send bit
    OUTI R0 SPI
    ANDI R0 R0 0b1111111011111111 ; Clear the send bit
    OUTI R0 SPI
wait_spi_send :
    INI R0 STATUS  ; Read the status register
    ANDI R0 R0 0x01  ; Check if the SPI is busy
    JM0 end_spi_send  ; If end sending, jump
    JMP wait_spi_send  ; Loop until SPI is ready
end_spi_send :
    INI R0 SPI  ; store the response from SPI
    OUTI R0 RAM0  ; Store the response in RAM0
    ADDI SP SP 1  ; Decrement Stack Pointer
    IN PC SP  ; Read the return adress from Stack Pointer
    RET

print_number :
    LOAD R0 0x0000  ; BCDL
    LOAD R1 0x0000  ; BCDH
    INI R2 RAM0  ; Load the binary number from RAM0
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
    ADDI R8 R8 0x130
    OUTI R8 UART   ; Send the high nibble to UART
    ANDI R8 R8 0x003F
    OUTI R8 UART   ; Send a space character to UART
digit2 :
    ANDI R9 R0 0xF000
    ADD R10 R9 R8
    JM0 digit3
    SHRI R8 R9 12
    ADDI R8 R8 0x130
    OUTI R8 UART   ; Send the high nibble to UART
    ANDI R8 R8 0x003F
    OUTI R8 UART   ; Send a space character to UART
digit3 :
    ANDI R10 R0 0xF00
    ADD R8 R10 R9
    JM0 digit4
    SHRI R8 R10 8
    ADDI R8 R8 0x130
    OUTI R8 UART   ; Send the high nibble to UART
    ANDI R8 R8 0x003F
    OUTI R8 UART   ; Send a space character to UART
digit4 :
    ANDI R11 R0 0xF0
    ADD R10 R11 R10
    JM0 digit5
    SHRI R8 R11 4
    ADDI R8 R8 0x130
    OUTI R8 UART   ; Send the high nibble to UART
    ANDI R8 R8 0x003F
    OUTI R8 UART   ; Send a space character to UART
digit5 :
    ANDI R8 R0 0xF
    ADDI R8 R8 0x130
    OUTI R8 UART   ; Send the high nibble to UART
    ANDI R8 R8 0x003F
    OUTI R8 UART   ; Send a space character to UART
    OUTI R0 0x4000   ;return bcd;
    OUTI R1 0x4001   ;return bcd;
    ADDI SP SP 1  
    IN PC SP  
    RET


; RESET ENABLE
    LOAD R0 0x166  ; Set the first bit to 1
    LOAD R12 0x0
    OUTI R12 GPO1
    OUTI R0 SPI
    LOAD R0 6  ; Set the first bit to 1
    OUTI R0 SPI
wait_spi_send1 :
    SUBI R0 R0 1  ; Check if the SPI is busy
    JM0 end_spi_send1  ; If end sending, jump
    JMP wait_spi_send1  ; Loop until SPI is ready
end_spi_send1 :
    LOAD R12 0x1
    OUTI R12 GPO1

; RESET
    LOAD R0 0x199  ; Set the first bit to 1
    LOAD R12 0x0
    OUTI R12 GPO1
    OUTI R0 SPI
    LOAD R0 6  ; Set the first bit to 1
    OUTI R0 SPI
wait_spi_send2 :
    SUBI R0 R0 1  ; Check if the SPI is busy
    JM0 end_spi_send2  ; If end sending, jump
    JMP wait_spi_send2  ; Loop until SPI is ready
end_spi_send2 :
    LOAD R12 0x1
    OUTI R12 GPO1

; READ STATUS
    LOAD R0 0x105  ; Set the first bit to 1
    LOAD R12 0x0
    OUTI R12 GPO1
    OUTI R0 SPI
    LOAD R0 6  ; Set the first bit to 1
    OUTI R0 SPI
wait_spi_send3 :    
    SUBI R0 R0 1  ; Check if the SPI is busy
    JM0 end_spi_send3  ; If end sending, jump
    JMP wait_spi_send3  ; Loop until SPI is ready
end_spi_send3 :
    LOAD R0 0x1ff  ; Set the first bit to 1
    OUTI R0 SPI
    LOAD R0 6  ; Set the first bit to 1
    OUTI R0 SPI
wait_spi_send4 :
    SUBI R0 R0 1  ; Check if the SPI is busy
    JM0 end_spi_send4  ; If end sending, jump
    JMP wait_spi_send4  ; Loop until SPI is ready
end_spi_send4 :
    LOAD R12 0x1
    OUTI R12 GPO1

; READ ID
    LOAD R0 0x19F  ; Set the first bit to 1
    LOAD R12 0x0
    OUTI R12 GPO1
    OUTI R0 SPI
    LOAD R0 6  ; Set the first bit to 1
    OUTI R0 SPI
wait_spi_send5 :    
    SUBI R0 R0 1  ; Check if the SPI is busy
    JM0 end_spi_send5  ; If end sending, jump
    JMP wait_spi_send5  ; Loop until SPI is ready
end_spi_send5 :
    LOAD R0 0x1ff  ; Set the first bit to 1
    OUTI R0 SPI
    LOAD R0 6  ; Set the first bit to 1
    OUTI R0 SPI
wait_spi_send6 :
    SUBI R0 R0 1  ; Check if the SPI is busy
    JM0 end_spi_send6  ; If end sending, jump
    JMP wait_spi_send6  ; Loop until SPI is ready
end_spi_send6 :
    INI R10 SPI  ; store the response from SPI
    LOAD R0 0x1ff  ; Set the first bit to 1
    OUTI R0 SPI
    LOAD R0 6  ; Set the first bit to 1
    OUTI R0 SPI
wait_spi_send7 :
    SUBI R0 R0 1  ; Check if the SPI is busy
    JM0 end_spi_send7  ; If end sending, jump
    JMP wait_spi_send7  ; Loop until SPI is ready
end_spi_send7 :
    LOAD R0 0x1ff  ; Set the first bit to 1
    OUTI R0 SPI
    LOAD R0 6  ; Set the first bit to 1
    OUTI R0 SPI
wait_spi_send8 :
    SUBI R0 R0 1  ; Check if the SPI is busy
    JM0 end_spi_send8  ; If end sending, jump
    JMP wait_spi_send8  ; Loop until SPI is ready
end_spi_send8 :
    LOAD R12 0x1
    OUTI R12 GPO1
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
    SUBI SP SP 1  ; Decrement Stack Pointer
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
    SUBI SP SP 1  ; Decrement Stack Pointer
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
    SUBI SP SP 1  ; Decrement Stack Pointer
    IN PC SP  ; Read the return adress from Stack Pointer
    RET

print_number :
    LOAD R0 0x0000  ; BCDL
    LOAD R4 0x0000  ; BCDH
    LOAD R1 0x0000  ; i
    INI R2 RAM0  ; binary
i_loop :
    LOAD R3 0x0000  ; j
j_loop :
    SHR R10 R0 R3   ;if (((bcd >> j) & 0xF) >= 5)
    ANDI R10 R10 0xF
    SUBI R10 R10 5
    JMN continue1   ;{
    LOAD R10 3      ;bcd += (3 << j)
    SHL R10 R10 R3
    ADD R0 R0 R10   ;}
continue1 :
    ADDI R3 R3 4    ;for (int j = 0; j < 16; j+=4)
    SUBI R10 R3 0x10
    JMN j_loop
    SHLI R0 R0 1    ;bcd <<= 1;
    SHRI R10 R2 15  ;bcd |= binary>> 15;
    OR R0 R0 R10 
    SHLI R2 R2 1    ;binary <<= 1;
end_print_number_loop :
    ADDI R1 R1 1    ;for (int i = 0; i < 16; i++)
    SUBI R10 R1 0x10
    JMN i_loop   
    OUTI R0 RAM0   ;return bcd;
    SUBI SP SP 1  
    IN PC SP  
    RET
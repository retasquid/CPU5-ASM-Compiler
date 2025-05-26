    ; WRITE_ENABLE 0x06
    ; WRITE_DISABLE 0x04
    ; READ_STATUS_REG 0x05
    ; READ_STATUS_REG2 0x35
    ; WRITE_STATUS_REG 0x01
    ; READ_DATA 0x03
    ; FAST_READ 0x0B
    ; PAGE_PROGRAM 0x02
    ; SECTOR_ERASE 0x20      // 4KB
    ; BLOCK_ERASE_32K 0x52   // 32KB
    ; BLOCK_ERASE 0xD8       // 64KB
    ; CHIP_ERASE 0xC7
    ; READ_ID 0x9F
    ; ENABLE_QPI 0x35
    ; RESET_ENABLE 0x66 
    ; RESET_DEVICE 0x99
start :
    ; Initialize the stack pointer
    LOAD SP 0x40ff  ; Set Stack Pointer to 255

    ; Initialize the SPI interface
    LOAD R0 0x20  ; Initialize R0 to 0x20
    OUTI R0 CONFSPI  ; Set SPI configuration

    ; Main loop
    LOAD R0 0x45  ; LOAD command to send
    OUTI R0 RAM0  ; set it in argument

    CALL            ;store the current address in PC
    ADDI PC PC 5    ; Increment Program Counter
    OUT PC SP       ;store the current address in Stack Pointer
    ADDI SP SP 1    ; Increment Stack Pointer
    JMP transfert_spi
    INI R0 RAM0  ; Read the response from SPI
    OUTI R0 GPO0  ; Send the response to GPO0

    ; Loop forever
main_loop :
    JMP main_loop  ; Infinite loop to keep the program running

transfert_spi :  
    ;take commande in RAM0 and return received commande in RAM0
    INI R0 RAM0  ;take the commande to send
    ORI R0 R0  0b0000000100000000 ; Set the send bit
    OUTI R0 SPI
    ANDI R0 R0 0b1111111011111111 ; Clear the send bit
    OUTI R0 SPI
wait_spi_send :
    ; Wait for the SPI to be ready
    INI R0 STATUS  ; Read the status register
    ANDI R0 R0 0x01  ; Check if the SPI is busy
    JM0 end_spi_send  ; If end sending, jump
    JMP wait_spi_send  ; Loop until SPI is ready
end_spi_send :
    ;read the response from SPI
    INI R0 SPI  ; store the response from SPI
    OUTI R0 RAM0  ; Store the response in RAM0
    ;return to main loop
    SUBI SP SP 1  ; Decrement Stack Pointer
    IN PC SP  ; Read the return adress from Stack Pointer
    RET

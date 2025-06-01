start :
    LOAD R10 0
    LOAD R11 1
    OUTI R11 GPO1
    LOAD SP 0x40FF
    LOAD R0 0b00100000
    OUTI R0 CONFSPI

RESET_EN :
    LOAD R0 0x166  ; Set the first bit to 1
    OUTI R10 GPO1
    OUTI R0 SPI
    OUTI R10 SPI
wait_spi_send6 :
    INI R0 STATUS  ; Read the status register
    NANDI R0 R0 0x01  ; Check if the SPI is busy
    JM0 wait_spi_send6  ; If end sending, jump
    OUTI R11 GPO1

RESET :
    LOAD R0 0x199  ; Set the first bit to 1
    OUTI R10 GPO1
    OUTI R0 SPI
    OUTI R10 SPI
wait_spi_send7 :
    INI R0 STATUS  ; Read the status register
    NANDI R0 R0 0x01  ; Check if the SPI is busy
    JM0 wait_spi_send7  ; If end sending, jump
    OUTI R11 GPO1

;READ
    CALL
    ADDI PC PC 5
    OUT PC SP
    SUBI SP SP 1
    JMP READ

WRITE_EN :
    LOAD R0 0b00100000
    OUTI R0 CONFSPI
    LOAD R0 0x106 
    OUTI R10 GPO1
    OUTI R0 SPI
    OUTI R10 SPI
wait_spi_send8 :
    INI R0 STATUS  ; Read the status register
    NANDI R0 R0 0x01  ; Check if the SPI is busy
    JM0 wait_spi_send8  ; If end sending, jump
    OUTI R11 GPO1

READ_STATUS :
    LOAD R0 0b00100000
    OUTI R0 CONFSPI
    LOAD R0 0x105
    OUTI R10 GPO1
    OUTI R0 SPI
    OUTI R10 SPI
wait_spi_send9 :
    INI R0 STATUS  ; Read the status register
    NANDI R0 R0 0x01  ; Check if the SPI is busy
    JM0 wait_spi_send9  ; If end sending, jump

    LOAD R0 0b00000000
    OUTI R0 CONFSPI
    LOAD R0 0x1ff 
    OUTI R0 SPI
    OUTI R10 SPI
wait_spi_send10 :
    INI R0 STATUS  ; Read the status register
    NANDI R0 R0 0x01  ; Check if the SPI is busy
    JM0 wait_spi_send10  ; If end sending, jump
    OUTI R11 GPO1
    INI R0 SPI
    ANDI R0 R0 0x02
    JM0 READ_STATUS

WRITE_PAGE :
    LOAD R0 0b00100000
    OUTI R0 CONFSPI
    LOAD R0 0x102  ; Set the first bit to 1
    OUTI R10 GPO1
    OUTI R0 SPI
    OUTI R10 SPI
wait_spi_send11 :
    INI R0 STATUS  ; Read the status register
    NANDI R0 R0 0x01  ; Check if the SPI is busy
    JM0 wait_spi_send11  ; If end sending, jump

    LOAD R0 0x100  ; Set the first bit to 1
    OUTI R0 SPI
    OUTI R10 SPI
wait_spi_send12 :
    INI R0 STATUS  ; Read the status register
    NANDI R0 R0 0x01  ; Check if the SPI is busy
    JM0 wait_spi_send12  ; If end sending, jump

    LOAD R0 0x100  ; Set the first bit to 1
    OUTI R0 SPI
    OUTI R10 SPI
wait_spi_send13 :
    INI R0 STATUS  ; Read the status register
    NANDI R0 R0 0x01  ; Check if the SPI is busy
    JM0 wait_spi_send13  ; If end sending, jump

    LOAD R0 0x100  ; Set the first bit to 1
    OUTI R0 SPI
    OUTI R10 SPI
wait_spi_send14 :
    INI R0 STATUS  ; Read the status register
    NANDI R0 R0 0x01  ; Check if the SPI is busy
    JM0 wait_spi_send14  ; If end sending, jump

    LOAD R0 312  ; Set the first bit to 1
    OUTI R0 SPI
    OUTI R10 SPI
wait_spi_send15 :
    INI R0 STATUS  ; Read the status register
    NANDI R0 R0 0x01  ; Check if the SPI is busy
    JM0 wait_spi_send15  ; If end sending, jump
    INI R5 SPI  ; Read the response from SPI
    OUTI R11 GPO1
    OUTI R5 GPO0
write_status1 : 
;READ STATUS
    LOAD R0 0b00100000
    OUTI R0 CONFSPI
    LOAD R0 0x105
    OUTI R0 GPO1
    OUTI R0 SPI
    OUTI R10 SPI
wait_spi_send16 :
    INI R0 STATUS  ; Read the status register
    NANDI R0 R0 0x01  ; Check if the SPI is busy
    JM0 wait_spi_send16  ; If end sending, jump

    LOAD R0 0b00000000
    OUTI R0 CONFSPI
    LOAD R0 0x1ff 
    OUTI R0 SPI
    OUTI R10 SPI
wait_spi_send17 :
    INI R0 STATUS  ; Read the status register
    NANDI R0 R0 0x01  ; Check if the SPI is busy
    JM0 wait_spi_send17  ; If end sending, jump
    OUTI R11 GPO1
    INI R0 SPI
    OUTI R0 GPO0
    NANDI R0 R0 0x01
    JM0 write_status1

WRITE_DISABLE :
    LOAD R0 0b00100000
    OUTI R0 CONFSPI
    LOAD R0 0x104 
    OUTI R10 GPO1
    OUTI R0 SPI
    OUTI R10 SPI
wait_spi_send18 :
    INI R0 STATUS  ; Read the status register
    NANDI R0 R0 0x01  ; Check if the SPI is busy
    JM0 wait_spi_send18  ; If end sending, jump
    OUTI R11 GPO1

;READ
    CALL
    ADDI PC PC 5
    OUT PC SP
    SUBI SP SP 1
    JMP READ

end :
    JMP end

;FUNCTIONS

READ :
    LOAD R0 0b00100000
    OUTI R0 CONFSPI
    LOAD R0 0x103      
    OUTI R10 GPO1
    OUTI R0 SPI
    OUTI R10 SPI
wait_spi_send1 :
    INI R0 STATUS  ; Read the status register
    NANDI R0 R0 0x01  ; Check if the SPI is busy
    JM0 wait_spi_send1  ; If end sending, jump

    LOAD R0 0x100  ; Set the first bit to 1
    OUTI R0 SPI
    OUTI R10 SPI
wait_spi_send2 :
    INI R0 STATUS  ; Read the status register
    NANDI R0 R0 0x01  ; Check if the SPI is busy
    JM0 wait_spi_send2  ; If end sending, jump

    LOAD R0 0x100  ; Set the first bit to 1
    OUTI R0 SPI
    OUTI R10 SPI
wait_spi_send3 :
    INI R0 STATUS  ; Read the status register
    NANDI R0 R0 0x01  ; Check if the SPI is busy
    JM0 wait_spi_send3  ; If end sending, jump

    LOAD R0 0x100  ; Set the first bit to 1
    OUTI R0 SPI
    OUTI R10 SPI
wait_spi_send4 :
    INI R0 STATUS  ; Read the status register
    NANDI R0 R0 0x01  ; Check if the SPI is busy
    JM0 wait_spi_send4  ; If end sending, jump

    LOAD R0 0b00000000
    OUTI R0 CONFSPI
    LOAD R0 0x1ff  ; Set the first bit to 1
    OUTI R0 SPI
    OUTI R10 SPI
wait_spi_send5 :
    INI R0 STATUS  ; Read the status register
    NANDI R0 R0 0x01  ; Check if the SPI is busy
    JM0 wait_spi_send5  ; If end sending, jump
    INI R5 SPI
    OUTI R5 GPO0
    OUTI R11 GPO1
    ADDI SP SP 1  ; Decrement Stack Pointer
    IN PC SP  ; Read the return adress from Stack Pointer
    RET
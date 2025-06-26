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
    mem_test :
        LOAD R0 0 ; mem count
        LOAD R3 0xDC ; test value
        LOAD R1 0x0 ; addresse initial value over IO
    loop_mem_test_write :
        ADDI R1 R1 1
        JM0 end_mem_test
        OUT R3 R1 
        IN R2 R1
        SUB R2 R2 R3
        JM0 add_mem_cnt
        JMP loop_mem_test_write
    add_mem_cnt :
        ADDI R0 R0 1 
        OUT R2 R1 
        JMP loop_mem_test_write
    end_mem_test : 
        OUTI R0 0x4000

    LOAD SP 0xc0ff  ;SP to the highest ram adress
    LOAD R0 0x1     ;CPU frequency
    OUTI R0 0x4001
    LOAD R0 0x86A0
    OUTI R0 0x4002
    LOAD R0 0x0     ;file number
    OUTI R0 0x4003
    LOAD R0 0x4010  ;FAT location
    OUTI R0 0x4004
    LOAD R0 0x9000  ;free space
    OUTI R0 0x4005
    LOAD R0 1     ;115200 bauds  : 0x1 0xC200
    OUTI R0 BAUDH
    LOAD R0 0xC200
    OUTI R0 BAUDL

    LOAD R0 0x63    ;c 
    OUTI R0 0x4200
    LOAD R0 0x61    ;a 
    OUTI R0 0x4201
    LOAD R0 0x74    ;t 
    OUTI R0 0x4202
    LOAD R0 0x20    ;  
    OUTI R0 0x4203

    LOAD R0 0x6c    ;l 
    OUTI R0 0x4210
    LOAD R0 0x73    ;s 
    OUTI R0 0x4211
    LOAD R0 0x20    ;  
    OUTI R0 0x4212

    LOAD R0 0x6e    ;n 
    OUTI R0 0x4220
    LOAD R0 0x61    ;a 
    OUTI R0 0x4221
    LOAD R0 0x6e    ;n 
    OUTI R0 0x4222
    LOAD R0 0x6f    ;o 
    OUTI R0 0x4223
    LOAD R0 0x20    ;  
    OUTI R0 0x4224

    LOAD R0 0x74    ;t 
    OUTI R0 0x4230
    LOAD R0 0x6f    ;o 
    OUTI R0 0x4231
    LOAD R0 0x75    ;u 
    OUTI R0 0x4232
    LOAD R0 0x63    ;c 
    OUTI R0 0x4233
    LOAD R0 0x68    ;h 
    OUTI R0 0x4234
    LOAD R0 0x20    ;  
    OUTI R0 0x4235

    LOAD R0 0x6d    ;m 
    OUTI R0 0x4240
    LOAD R0 0x65    ;e 
    OUTI R0 0x4241
    LOAD R0 0x6d    ;m 
    OUTI R0 0x4242
    LOAD R0 0x20    ;  
    OUTI R0 0x4243

    CALL
    SUBI SP SP 1
    JMP logo_NOS
    CALL
    SUBI SP SP 1
    JMP print_mem_test
    INI R0 0x4000 ;get the memory size
    CALL
    SUBI SP SP 1
    JMP print_number

loop : 
    CALL
    SUBI SP SP 1
    JMP print_user_input

    LOAD R0 0x8000
    CALL
    SUBI SP SP 1
    JMP input_uart

    LOAD R0 0x8000
;input : R0 = input str*
command_decoder :
    LOAD R3 0x4200
    LOAD PC 0
    AND R11 R0 R0
    command_decoder_loop :
        IN R1 R0
        IN R2 R3
        SUBI R10 R2 0x20
        JM0 command_decoder_match
        ADDI R0 R0 1
        ADDI R3 R3 1
        SUB R10 R1 R2
        JM0 command_decoder_loop
        ANDI R3 R3 0xFFF0
        ADDI R3 R3 0x10
        AND R0 R11 R11
        SUBI R10 R3 0x4241
        JMN command_decoder_loop
        JMP command_decoder_error
    command_decoder_match :
        ADDI R0 R0 1
        SUB R10 R1 R2
        JM0 command_decoder_match_test
        JMP command_decoder_error
    command_decoder_match_test :
        OUTI R3 GPO0
        SUBI R10 R3 0x4203
        JM0 cat_command
        SUBI R10 R3 0x4212
        JM0 ls_command
        SUBI R10 R3 0x4224
        JM0 nano_command
        SUBI R10 R3 0x4235
        JM0 touch_command
        SUBI R10 R3 0x4243
        JM0 mem_command
    command_decoder_error :
        LOAD PC 1
        CALL
        SUBI SP SP 1
        JMP error_file
        JMP loop

cat_command :
    CALL
    SUBI SP SP 1
    JMP search_file
    AND R2 R0 R0
    LOAD R0 13    ;\
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 10    ;n 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    AND R0 R2 R2
    CALL
    SUBI SP SP 1
    JMP output_uart_string
    JMP loop

ls_command :
    LOAD R0 13    ;\
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 10    ;n 
    CALL 
    SUBI SP SP 1
    JMP output_uart

    INI R2 0x4003
    ls_command_loop :
        SHLI R0 R2 4
        ORI R0 R0 0x4001
        CALL
        SUBI SP SP 1
        JMP output_uart_string
        LOAD R0 0x20    ;  
        CALL 
        SUBI SP SP 1
        JMP output_uart
        SUBI R2 R2 1
        JM0 loop
    JMP ls_command_loop

nano_command :
    LOAD R0 13    ;\
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 10    ;n 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 12    ;clear
    CALL 
    SUBI SP SP 1
    JMP output_uart

    CALL
    SUBI SP SP 1
    JMP search_file
    CALL 
    SUBI SP SP 1
    JMP size_of
    ADD R2 R0 R10 ;get the end of the line of code
    AND R3 R0 R0
    ;R2: end of str, R3: actual size of str
    AND R0 R10 R10
    CALL
    SUBI SP SP 1
    JMP output_uart_string  ;print the actual data of the file

    AND R0 R2 R2
    AND R1 R0 R0
    AND R11 R10 R10
    input_uart_loop1 :
        INI R0 UART
        SUBI R0 R0 0
        JM0 input_uart_loop1
        SUBI R10 R0 13
        JM0 entree1
        SUBI R10 R0 24
        JM0 save_file1
        SUBI R10 R0 127
        JM0 backSpace1
        OUT R0 R1
        ADDI R1 R1 1
    continue_print_char1 : 
        CALL
        SUBI SP SP 1
        JMP output_uart
        JMP input_uart_loop1
    backSpace1 : 
        SUB R10 R1 R11
        JM0 input_uart_loop1
        SUBI R1 R1 1
        LOAD R10 0
        OUT R10 R1
        JMP continue_print_char1
    entree1 :
        LOAD R0 13    ;\
        OUT R0 R1
        ADDI R1 R1 1
        CALL 
        SUBI SP SP 1
        JMP output_uart

        LOAD R0 10    ;n 
        OUT R0 R1
        ADDI R1 R1 1
        CALL 
        SUBI SP SP 1
        JMP output_uart
        JMP input_uart_loop1
    save_file1 :
        OUT R10 R1
        JMP loop

touch_command :
    AND R1 R0 R0
    INI R0 0x4005
    ADDI R10 R0 0x100
    OUTI R10 0x4005 
    CALL
    SUBI SP SP 1
    JMP add_file
    OUTI R0 0x8010

    LOAD R0 0x8000
    ADDI R1 R0 0x10
    CALL
    SUBI SP SP 1
    JMP read_memory

    SUBI PC PC 0
    JM0 no_error
    JMP error
    no_error :
        CALL
        SUBI SP SP 1
        JMP print_file_test
        INI R0 0x8010
        ADDI R0 R0 1
        CALL
        SUBI SP SP 1
        JMP output_uart_string
        JMP loop
    error :
        CALL
        SUBI SP SP 1
        JMP error_file
        JMP loop

mem_command :
    CALL
    SUBI SP SP 1
    JMP string_to_hex
    ADDI R1 R0 0x800
    CALL
    SUBI SP SP 1
    JMP read_memory
    JMP loop

end :
    JMP end

;  ////////////////////////////////////////////
; ///   Standard Library for the CPU 5.9   ///
;////////////////////////////////////////////


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


;input : R0 = char* str
;output : R0 = number
string_to_int :
    LOAD R10 0 ;uint16_t result = 0;
    for_0000 :   ;for (int i = 0; str[i] != '\0'; i++) {
        IN R12 R0 ;str[i] != '\0'
        SUBI R12 R12 0
        JM0 end_string_to_int
        SHLI R13 R10 3 ;(result << 3)
        ADD R13 R13 R10 ;+result
        ADD R13 R13 R10 ;+result
        SUBI R12 R12 0x30 ;str[i] - '0'
        ADD R10 R13 R12 ;result =result*10 + (str[i] - '0')
        ADDI R0 R0 1 ;i++
        JMP for_0000
    end_string_to_int :
        AND R0 R10 R10 ;return result;
        ADDI SP SP 1  ; Decrement Stack Pointer
        RET

;input : R0 = char* str in hex
;output : R0 = number 
string_to_hex :
    LOAD R10 0 ;uint16_t result = 0;
    for_0000 :   ;for (int i = 0; str[i] != '\0'; i++) {
        IN R12 R0 ;str[i] != '\0'
        SUBI R12 R12 0
        JM0 end_string_to_int
        SHLI R10 R10 4 ;(result << 4)
        SUBI R12 R12 0x61
        JMN test_letter0
        JMP test_letter1
        test_letter0 :
        ADDI R12 R12 0x31 ;str[i] - '0'
        test_letter1 :
        ADD R10 R10 R12 ;result =result*10 + (str[i] - '0')
        ADDI R0 R0 1 ;i++
        JMP for_0000
    end_string_to_int :
        AND R0 R10 R10 ;return result;
        ADDI SP SP 1  ; Decrement Stack Pointer
        RET

;input : R0 = start adress
;input : R1 = end adress
read_memory :
        AND R5 R0 R0
        AND R7 R1 R1
    read_loop0 :
        SUB R10 R5 R7
        JM0 end_read_memory
        LOAD R0 13    ;\
        CALL 
        SUBI SP SP 1
        JMP output_uart
        LOAD R0 10    ;n 
        CALL 
        SUBI SP SP 1
        JMP output_uart
        AND R0 R5 R5
        CALL
        SUBI SP SP 1
        JMP print_number_hex

        LOAD R6 8
        read_loop1 :     
            LOAD R0 0x20    ;' '
            CALL 
            SUBI SP SP 1
            JMP output_uart
            IN R0 R5
            CALL
            SUBI SP SP 1
            JMP print_number_hex
            ADDI R5 R5 1
            SUBI R6 R6 1
            JM0 read_interpreter
            JMP read_loop1
        read_interpreter :
        LOAD R6 8
        SUBI R5 R5 8
        read_loop2 :     
            LOAD R0 0x20    ;' '
            CALL 
            SUBI SP SP 1
            JMP output_uart
            IN R0 R5
            CALL
            SUBI SP SP 1
            JMP output_uart
            ADDI R5 R5 1
            SUBI R6 R6 1
            JM0 read_loop0
            JMP read_loop2
    end_read_memory :
        ADDI SP SP 1
        RET



;input : R0 = number
print_number_hex :
    LOAD R1 12
    AND R2 R0 R0
    loop_print_hex : 
        SHR R0 R2 R1
        ANDI R0 R0 0xf
        SUBI R10 R0 10
        JMN print_number_digit
        ADDI R0 R0 39
        print_number_digit :
        ADDI R0 R0 48
        CALL
        SUBI SP SP 1
        JMP output_uart
        SUBI R1 R1 4 
        JMN end_print_number_hex
        JMP loop_print_hex
    end_print_number_hex :
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
;output : R0 = start string pointer
;output : R1 = end string pointer
input_uart : 
    AND R1 R0 R0
    AND R2 R0 R0
    input_uart_loop :
        INI R0 UART
        SUBI R0 R0 0
        JM0 input_uart_loop
        SUBI R10 R0 13
        JM0 entree
        SUBI R10 R0 127
        JM0 backSpace
        OUT R0 R1
        ADDI R1 R1 1
    continue_print_char : 
        CALL
        SUBI SP SP 1
        JMP output_uart
        JMP input_uart_loop
    backSpace : 
        SUB R10 R1 R2 
        JM0 input_uart_loop
        SUBI R1 R1 1
        LOAD R10 0
        OUT R10 R1
        JMP continue_print_char
    entree :
        OUT R10 R1 ;end str with NULL
    ADDI SP SP 1
    RET


;input : R0 = char* str
;output : R0 = size of the string 
;output : R10 = char* str
size_of :
    AND R10 R0 R0  
    size_of_count :
    IN R1 R0  ; Read the next character from the string
    SUBI R1 R1 0  
    JM0 end_size_of
    ADDI R0 R0 1     ; go to next character
    JMP size_of_count
    end_size_of :
        SUB R0 R0 R10
        ADDI SP SP 1     ; Decrement Stack Pointer
        RET


;input : R0 = mem location
;input : R1 = name string ptr
;output : R0 = FAT adresse
add_file : 
    INI R2 0x4004   ;get the begin adress of files
    INI R3 0x4003   ;get the number of files
    SUBI R10 R3 16
    JM0 add_file_end_error_fnumber
    SHLI R3 R3 4
    ADD R2 R2 R3    ;get the new file adress
    AND R11 R2 R2   ;store the FAT adress
    OUT R0 R2       ;store the file pointer
    ADDI R2 R2 1    ;inc the fat file ptr
    AND R12 R1 R1   ;mov R1 to R12
    AND R0 R12 R12   ;mov R1 to R12
    size_of_count1 :
        IN R1 R0  ; Read the next character from the string
        SUBI R1 R1 0  
        JM0 end_size_of1
        ADDI R0 R0 1     ; go to next character
        JMP size_of_count1
    end_size_of1 :
        SUB R0 R0 R12
    SUBI R10 R0 15  ;test the lenght of the title
    JMN add_file_string_store
    JMP add_file_end_error_name
    ; R2 : FAT file adress, R12 : input str name, R0 : size of name
    add_file_string_store : 
        IN R1 R12
        OUT R1 R2
        SUBI R0 R0 1
        JMN add_file_end
        ADDI R12 R12 1
        ADDI R2 R2 1
        JMP add_file_string_store
    add_file_end :
        INI R3 0x4003   ;get the number of files
        ADDI R3 R3 1
        OUTI R3 0x4003   ;inc the number of files
        LOAD PC 0
        AND R0 R11 R11   ;store the FAT adress
        ADDI SP SP 1
        RET
    add_file_end_error_name :
        LOAD PC 1
        ADDI SP SP 1
        RET
    add_file_end_error_fnumber :
        LOAD PC 2
        ADDI SP SP 1
        RET

;input : R0 = name string ptr
;output : R0 = file adresse
search_file : 
    INI R4 0x4003 ;get FAT entry
    INI R3 0x4004 ;get FAT entry
    ADDI R3 R3 1 ;ignor the file ptr
    LOAD PC 0
    AND R11 R0 R0
    SUBI R12 R3 1
    SUBI R4 R4 1
    search_file_loop :
        IN R1 R0
        IN R2 R3
        SUBI R2 R2 0
        JM0 search_file_match
        ADDI R0 R0 1
        ADDI R3 R3 1
        SUB R10 R1 R2
        JM0 search_file_loop
        ANDI R3 R3 0xFFF0
        ADDI R3 R3 0x11
        SUBI R12 R3 1
        AND R0 R11 R11
        SUBI R4 R4 1
        JM0 search_file_error
        JMP search_file_loop
    search_file_match : 
        ADDI R0 R0 1
        SUB R10 R1 R2
        JM0 search_file_match_test
        JMP search_file_error
    search_file_match_test : 
        IN R0 R12
        ADDI SP SP 1
        RET
    search_file_error :
        LOAD PC 1
        CALL
        SUBI SP SP 1
        JMP error_file
        ADDI SP SP 1
        RET


;  //////////////////////
; ///  Constant strings

error_file : 
    LOAD R0 13    ;\
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 10    ;n 
    CALL 
    SUBI SP SP 1
    JMP output_uart

    LOAD R0 0x45    ;E 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x72    ;r 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x72    ;r 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x6f    ;o 
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
    LOAD R0 0x77    ;w 
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
    LOAD R0 0x74    ;t 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x69    ;i 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x6e    ;n 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x67    ;g 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x66    ;f 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x69    ;i 
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
    ADDI SP SP 1
    RET



print_file_test : 
    LOAD R0 13    ;\
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 10    ;n 
    CALL 
    SUBI SP SP 1
    JMP output_uart

    LOAD R0 0x66    ;f 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x69    ;i 
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
    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x63    ;c 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x72    ;r 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x65    ;e 
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
    LOAD R0 0x64    ;d 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x77    ;w 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x69    ;i 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x74    ;t 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x68    ;h 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x6e    ;n 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x61    ;a 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x6d    ;m 
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


print_user_input :
    LOAD R0 13    ;\
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 10    ;n 
    CALL 
    SUBI SP SP 1
    JMP output_uart

    LOAD R0 0x6e    ;n 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x6f    ;o 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x73    ;s 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x40    ;@ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x43    ;C 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x50    ;P 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x55    ;U 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x35    ;5 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x2d    ;- 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x39    ;9 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x3a    ;: 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x7e    ;~ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x24    ;$ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    ADDI SP SP 1
    RET


print_mem_test : 
    LOAD R0 13    ;\
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 10    ;n 
    CALL 
    SUBI SP SP 1
    JMP output_uart

    LOAD R0 0x52    ;R 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x41    ;A 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x4d    ;M 
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
    LOAD R0 0x69    ;i 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x73    ;s 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x70    ;p 
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
    LOAD R0 0x69    ;i 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x62    ;b 
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
    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x28    ;( 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x57    ;W 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x6f    ;o 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x72    ;r 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x64    ;d 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x73    ;s 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x29    ;) 
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


logo_NOS :
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
    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x5f    ;_ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x5f    ;_ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x5f    ;_ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x5f    ;_ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x5f    ;_ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x5f    ;_ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x5f    ;_ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x5f    ;_ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x5f    ;_ 
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


    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x2f    ;/ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x5c    ;\ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x5f    ;_ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x5f    ;_ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x5c    ;\ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x2f    ;/ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x5c    ;\ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x5c    ;\ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x2f    ;/ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x5c    ;\ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x5c    ;\ 
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


    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x2f    ;/ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x3a    ;: 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x7c    ;| 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x5f    ;_ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x7c    ;| 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x5f    ;_ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x2f    ;/ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x3a    ;: 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x3a    ;: 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x5c    ;\ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x5c    ;\ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x2f    ;/ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x3a    ;: 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x3a    ;: 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x5c    ;\ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x5c    ;\ 
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


    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x2f    ;/ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x3a    ;: 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x3a    ;: 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x7c    ;| 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x2f    ;/ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x5c    ;\ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x5f    ;_ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x5f    ;_ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x2f    ;/ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x3a    ;: 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x2f    ;/ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x5c    ;\ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x3a    ;: 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x5c    ;\ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x5f    ;_ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x5f    ;_ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x2f    ;/ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x5c    ;\ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x3a    ;: 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x5c    ;\ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x3a    ;: 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x5c    ;\ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x5f    ;_ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x5f    ;_ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x5c    ;\ 
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

    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x5c    ;\ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x2f    ;/ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x7c    ;| 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x3a    ;: 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x3a    ;: 
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
    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x5c    ;\ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x3a    ;: 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x5c    ;\ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x2f    ;/ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x3a    ;: 
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
    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x5c    ;\ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x3a    ;: 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x5c    ;\ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x3a    ;: 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x5c    ;\ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x2f    ;/ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x5f    ;_ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x5f    ;_ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x2f    ;/ 
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

    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x7c    ;| 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x3a    ;: 
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
    LOAD R0 0x20    ;  
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
    LOAD R0 0x5c    ;\ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x3a    ;: 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x3a    ;: 
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
    LOAD R0 0x20    ;  
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
    LOAD R0 0x5c    ;\ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x3a    ;: 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x3a    ;: 
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
    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x2f    ;/ 
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
    
    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x5c    ;\ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x2f    ;/ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x5f    ;_ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x5f    ;_ 
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
    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x5c    ;\ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x2f    ;/ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x5f    ;_ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x5f    ;_ 
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
    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x20    ;  
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x5c    ;\ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x2f    ;/ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x5f    ;_ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x5f    ;_ 
    CALL 
    SUBI SP SP 1
    JMP output_uart
    LOAD R0 0x2f    ;/ 
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
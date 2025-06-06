start :
    LOAD SP 0x40ff
    LOAD R0 2
    OUTI R0 GPO0

    CALL
    SUBI SP SP 1
    JMP add
    OUTI R0 GPO0

    CALL
    SUBI SP SP 1
    JMP add
    OUTI R0 GPO0

    JMP start

add :
    ADDI R0 R0 6
    ADDI SP SP 1
    RET

interrupt_vector0 :
    LOAD R0 567
interrupt_vector1 :
    LOAD R0 567
interrupt_vector2 :
    LOAD R0 567
interrupt_vector3 :
    LOAD R0 567
interrupt_vector4 :
    LOAD R0 567
interrupt_vector5 :
    LOAD R0 567
interrupt_vector6 :
    LOAD R0 567
interrupt_vector7 :
    LOAD R6 23456

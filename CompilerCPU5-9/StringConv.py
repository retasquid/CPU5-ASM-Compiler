output=open("string.asm", "w")

buffer = input("Enter a string: ")
# Convert the input string to a list of characters
buffer = list(buffer)
char_list = list(buffer)
for i in range(len(char_list)):
    # Convert each character to its ASCII value
    char_list[i] = ord(buffer[i])

for i in range(len(char_list)):
    output.write("    LOAD R0 0x"+str(format(char_list[i],'02x'))+"    ;"+buffer[i]+" \n")
    output.write("    CALL \n")
    output.write("    SUBI SP SP 1\n")
    output.write("    JMP output_uart\n")
output.write("    ADDI SP SP 1\n")
output.write("    RET\n")
output.close()
print("Assembly code has been written to string.asm")
print("string lenght : " + str(len(char_list))+ ", code size : " + str(len(char_list)*4) + " lines")

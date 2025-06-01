import sys

def main():
    # Constants
    ROM_SIZE = 256
    # Les 4 instructions de saut partagent le même opcode de base (10010)
    COMMANDS = ["HALT", "LOAD", "ADD", "ADDI", "SUB", "SUBI", "SHL", "SHLI", "SHR", "SHRI", 
                "AND", "ANDI", "NAND", "NANDI", "OR", "ORI", "XOR", "XORI", 
            "JMP", "IN", "OUT", "OUTI", "CALL", "RET", "INI"]
    
    JUMPS = ["JMP", "JM0", "JMC", "JMN"]

    REGISTERS = ["R0","R1","R2","R3","R4","R5","R6","R7","R8","R9","R10","R11","R12","R13", "PC", "SP"]
    SHORTCUTS = {"RAM0":16384, "SP0":32767, "GPI0":0, "GPI1":1, "GPO0":2, "GPO1":3, "SPI":4, "CONFSPI":5, "UART":6,"BAUDL":7, "BAUDH":8, "STATUS":9}
    
    # Parse input arguments
    try:
        source_file = sys.argv[1]
        output_file = sys.argv[2]
        
        if output_file.endswith(".bin"):
            mode = 0  # binary output
        elif output_file.endswith(".v"):
            mode = 1  # Verilog ROM output
        else:
            mode = 2  # hex output
    except:
        source_file = "main.asm"
        output_file = "D:/FPGA/CPU5_9/CPU5_9/src/ROM.v"
        mode = 1
    
    # Helper functions
    def to_binary(number, length):
        """Convert decimal to binary string of fixed length"""
        number = str(number)
        if number.startswith('0b'):
            base = 2
            number = number[2:]
        elif number.startswith('0x'):
            base = 16
            number = number[2:]
        else:
            base = 10
        number = int(number, base)
        if isinstance(number, int):
            return format(number & ((1 << length) - 1), f'0{length}b')
        try:
            return format(int(number) & ((1 << length) - 1), f'0{length}b')
        except ValueError:
            print("Error converting to binary:", number) 
            return "0" * length
    
    def to_hex8(binary_str):
        """Convert 29-bit binary string to 8-digit hex"""
        # Pad to 32 bits for easier conversion
        padded = "000" + str(binary_str)
        return format(int(padded, 2), '08x')
    
    def to_verilog(inst, pc):
        """Format instruction for Verilog ROM"""
        return f"        data[{pc}] = 29'h{to_hex8(inst)};\n"
    

    # First pass: collect labels
    labels = {}
    pc = 0
    
    with open(source_file, "r") as source:
        for line in source:
            words = line.strip().split()
            if not words or words[0].startswith(';'):
                continue
                
            try:
                if words[0] in COMMANDS or words[0] in JUMPS:
                    pc += 1
                elif words[1] == ':':
                    labels[words[0]] = pc
                elif words[1].startswith(';') and words[0] not in ["HALT", "CALL", "RET"]:
                    print(f"Error: no argument for instruction but ';' found on line {pc+1}")
                    sys.exit(1)
            except IndexError:
                continue
                
            if pc >= ROM_SIZE:
                print(f"Error: ROM size: {ROM_SIZE} exceeded")
                sys.exit(1)
    # Second pass: generate machine code
    with open(source_file, "r") as source, open(output_file, "w") as output:
        instruction = ''
        # Write Verilog header if needed
        if mode == 1:
            output.write("module ROM(\n"
                         "    output reg[28:0] DataROM,\n"
                         "    input wire[10:0] AddrROM\n"
                         ");\n"
                         "    reg[28:0] data [2047:0];\n"
                         "    initial begin\n")
        
        pc = 0
        for line in source:
            words = line.strip().split()
            if not words or words[0].startswith(';') or words[0] in labels:
                continue
            elif words[0] == "HALT":
                instruction = "0" * 29

            elif words[0] =="LOAD":
                try:
                    if words[1] in REGISTERS:
                        if words[2] in SHORTCUTS:
                            instruction = "00001"+to_binary(REGISTERS.index(words[1]),4)+"0000"+to_binary(SHORTCUTS[words[2]],16)
                        else:
                            instruction = "00001"+to_binary(REGISTERS.index(words[1]),4)+"0000"+to_binary(words[2],16)
                    else:
                        print(f"Error: LOAD instruction without operands on line {pc+1}")
                        sys.exit(1)
                except: 
                    print(f"Error: LOAD instruction without target on line {pc+1}")
                    sys.exit(1)

            elif words[0] in ["ADD", "SUB", "SHL", "SHR", "AND", "NAND", "OR", "XOR"]:
                try:
                    if words[1] in REGISTERS and words[2] in REGISTERS and words[3] in REGISTERS:
                        instruction = to_binary(COMMANDS.index(words[0]),5)+to_binary(REGISTERS.index(words[1]),4)+to_binary(REGISTERS.index(words[2]),4)+to_binary(REGISTERS.index(words[3]),4)+"000000000000"
                    else:
                        print(f"Error: {words[0]} instruction without operands on line {pc+1}")
                        sys.exit(1)
                except: 
                    print(f"Error: {words[0]} instruction without target on line {pc+1}")
                    sys.exit(1)

            elif words[0] in ["ADDI", "SUBI", "SHLI", "SHRI", "ANDI", "NANDI", "ORI", "XORI"]:
                try:
                    if words[1] in REGISTERS and words[2] in REGISTERS:
                        if words[3] in labels:
                            instruction = to_binary(COMMANDS.index(words[0]),5)+to_binary(REGISTERS.index(words[1]),4)+to_binary(REGISTERS.index(words[2]),4)+to_binary(labels[words[3]],16)
                        elif words[3] in SHORTCUTS:
                            instruction = to_binary(COMMANDS.index(words[0]),5)+to_binary(REGISTERS.index(words[1]),4)+to_binary(REGISTERS.index(words[2]),4)+to_binary(SHORTCUTS[words[3]],16)
                        else:
                            instruction = to_binary(COMMANDS.index(words[0]),5)+to_binary(REGISTERS.index(words[1]),4)+to_binary(REGISTERS.index(words[2]),4)+to_binary(words[3],16)
                    else:
                        print(f"Error: {words[0]} instruction without operands on line {pc+1}")
                        sys.exit(1)
                except: 
                    print(f"Error: {words[0]} instruction without target on line {pc+1}")
                    sys.exit(1)

            elif words[0] in ["JMP", "JM0", "JMC", "JMN"]:
                try:
                    if words[1] in labels:
                        instruction = to_binary(18,5)+"0000"+to_binary(JUMPS.index(words[0]),4)+to_binary(labels[words[1]],16)
                    elif words[1] in SHORTCUTS:
                        instruction = to_binary(18,5)+"0000"+to_binary(JUMPS.index(words[0]),4)+to_binary(SHORTCUTS[words[1]],16)
                    else:
                        instruction = to_binary(18,5)+"0000"+to_binary(JUMPS.index(words[0]),4)+to_binary(words[1],16)
                except: 
                    print(f"Error: {words[0]} instruction without target on line {pc+1}")
                    sys.exit(1)

            elif words[0] =="IN":
                try:
                    if words[1] in REGISTERS and words[2] in REGISTERS:
                        instruction = to_binary(COMMANDS.index(words[0]),5)+to_binary(REGISTERS.index(words[1]),4)+"0000"+to_binary(REGISTERS.index(words[2]),4)+"0"*12
                    else:
                        print(f"Error: {words[0]} instruction without operands on line {pc+1}")
                        sys.exit(1)
                except: 
                    print(f"Error: {words[0]} instruction without target on line {pc+1}")
                    sys.exit(1)

            elif words[0] == "INI":
                try:
                    if words[1] in REGISTERS and words[2] in SHORTCUTS:
                        instruction = to_binary(COMMANDS.index(words[0]),5)+to_binary(REGISTERS.index(words[1]),4)+"0000"+to_binary(SHORTCUTS[words[2]],16)
                    else:
                        instruction = to_binary(COMMANDS.index(words[0]),5)+to_binary(REGISTERS.index(words[1]),4)+"0000"+to_binary(words[2],16)
                except: 
                    print(f"Error: {words[0]} instruction without target on line {pc+1}")
                    sys.exit(1)

            elif words[0] =="OUT":
                try:
                    if words[1] in REGISTERS and words[2] in REGISTERS:
                        instruction = to_binary(COMMANDS.index(words[0]),5)+"0000"+to_binary(REGISTERS.index(words[1]),4)+to_binary(REGISTERS.index(words[2]),4)+"0"*12
                    else:
                        print(f"Error: {words[0]} instruction without operands on line {pc+1}")
                        sys.exit(1)
                except: 
                    print(f"Error: {words[0]} instruction without target on line {pc+1}")
                    sys.exit(1)
            elif words[0] == "OUTI":
                try:
                    if words[1] in REGISTERS and words[2] in SHORTCUTS:
                        instruction = to_binary(COMMANDS.index(words[0]),5)+"0000"+to_binary(REGISTERS.index(words[1]),4)+to_binary(SHORTCUTS[words[2]],16)
                    else:
                        instruction = to_binary(COMMANDS.index(words[0]),5)+"0000"+to_binary(REGISTERS.index(words[1]),4)+to_binary(words[2],16)
                except:
                    print(f"Error: {words[0]} instruction without target on line {pc+1}")
                    sys.exit(1)
            elif words[0] == "RET":
                instruction = to_binary(COMMANDS.index(words[0]),5)+"0000"+"1110"+"0" * 16
            elif words[0] == "CALL":
                instruction = to_binary(COMMANDS.index(words[0]),5)+"1110"+"0" * 20

            if mode == 0:
                output.write(instruction + '\n')
            elif mode == 1:
                output.write(to_verilog(instruction, pc))
            elif mode == 2:
                output.write(to_hex8(instruction) + '\n')
            pc += 1
        
        # Write Verilog footer if needed
        if mode == 1:
            output.write("    end\n"
                         "    \n"
                         "    // Lecture synchrone ou asynchrone de la ROM\n"
                         "    always @(*) begin\n"
                         "        DataROM = data[AddrROM];\n"
                         "    end\n"
                         "endmodule\n")
    
    print("\nCompilation terminée\n")
    print("taille du code : "+str(pc)+" lignes soit "+str(pc<<2)+" Octets")


if __name__ == "__main__":
    main()
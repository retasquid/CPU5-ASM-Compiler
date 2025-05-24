import sys

def main():
    # Constants
    ROM_SIZE = 255
    # Les 4 instructions de saut partagent le même opcode de base (10010)
    # Les opcodes des instructions suivantes sont décalés de 3
    COMMANDS = ["HALT", "LOAD", "ADD", "ADDI", "SUB", "SUBI", "SHL", "SHLI", "SHR", "SHRI", 
                "AND", "ANDI", "NAND", "NANDI", "OR", "ORI", "XOR", "XORI", 
                "JMP", # Opcode 10010, JMP ID = 00
                # JM0, JMC, JMN ont le même opcode 10010 avec des JMP ID différents
                "IN", "OUT", "OUTI", "CALL", "RET"]
    
    # JMP ID pour les différentes instructions de saut
    JUMP_IDS = {
        "JMP": 0,  # 00
        "JM0": 1,  # 01
        "JMC": 2,  # 10
        "JMN": 3   # 11
    }
    
    REGISTERS = ["R0","R1","R2","R3","R4","R5","R6","R7","R8","R9","R10","R11","R12","R13", "PC", "SP"]
    SHORTCUTS = ["RAM0", "SP0", "GPI0", "GPI1", "GPO0", "GPO1", "SPI", "BAUDH", "BAUDL", "UART"]
    ADDR_SHORTCUTS = [16384, 32767, 0, 1, 2, 3, 4, 5, 6, 7]
    
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
        output_file = "C:/Users/redsq/Documents/logisim/Tang nano 9k/CPU5_5/src/ROM.v"
        mode = 1
    
    # First pass: collect labels
    labels = {}
    pc = 0
    
    with open(source_file, "r") as source:
        for line in source:
            words = line.strip().split()
            if not words or words[0].startswith(';'):
                continue
                
            try:
                if words[1] == ':':
                    labels[words[0]] = pc
                elif words[1].startswith(';') and words[0] not in ["HALT", "CALL", "RET"]:
                    print(f"Error: no argument for instruction but ';' found on line {pc+1}")
                    sys.exit(1)
                else:
                    pc += 1
            except IndexError:
                pc += 1
                
            if pc == ROM_SIZE:
                print(f"Error: ROM size: {ROM_SIZE} exceeded")
                sys.exit(1)
    
    # Helper functions
    def to_binary(decimal, length):
        """Convert decimal to binary string of fixed length"""
        if isinstance(decimal, int):
            return format(decimal & ((1 << length) - 1), f'0{length}b')
        try:
            return format(int(decimal) & ((1 << length) - 1), f'0{length}b')
        except ValueError:
            return "0" * length
    
    def to_hex8(binary_str):
        """Convert 29-bit binary string to 8-digit hex"""
        # Pad to 32 bits for easier conversion
        padded = "000" + binary_str
        return format(int(padded, 2), '08x')
    
    def to_verilog(inst, pc):
        """Format instruction for Verilog ROM"""
        return f"        data[{pc}] = 29'h{to_hex8(inst)};\n"
    
    # Second pass: generate machine code
    with open(source_file, "r") as source, open(output_file, "w") as output:
        # Write Verilog header if needed
        if mode == 1:
            output.write("module ROM(\n"
                         "    output reg[28:0] DataROM,\n"
                         "    input wire[7:0] AddrROM\n"
                         ");\n"
                         "    reg[28:0] data [255:0];\n"
                         "    initial begin\n")
        
        pc = 0
        for line in source:
            words = line.strip().split()
            if not words or words[0].startswith(';'):
                continue
                
            if len(words) > 1 and words[1] == ':':
                continue  # Skip label definitions in second pass
                
            try:
                # Gestion spéciale pour les instructions de saut
                if words[0] in JUMP_IDS:
                    instruction = "10010"  # Opcode commun pour tous les sauts
                    jump_id = to_binary(JUMP_IDS[words[0]], 2)  # ID du saut sur 2 bits
                    
                    # Traitement de l'adresse de saut
                    if len(words) > 1:
                        if words[1] in labels:
                            # Référence à un label
                            instruction += "000000" + jump_id + to_binary(labels[words[1]], 16)
                        else:
                            # Adresse directe
                            try:
                                value = int(words[1], 16) if words[1].startswith('0x') else int(words[1], 10)
                                instruction += "000000" + jump_id + to_binary(value, 16)
                            except ValueError:
                                print(f"Error: Invalid jump address '{words[1]}' on line {pc+1}")
                                sys.exit(1)
                    else:
                        print(f"Error: Jump instruction without target on line {pc+1}")
                        sys.exit(1)
                        
                    # Compléter l'instruction pour atteindre 29 bits
                    instruction += "0" * (29 - len(instruction))
                else:
                        # Instructions normales (non-saut)
                    if words[0] not in COMMANDS:
                        raise ValueError(f"Unknown command '{words[0]}'")
                    else:
                        # Get opcode
                        instruction = to_binary(COMMANDS.index(words[0]), 5)
                        
                        # Flag for load instructions
                        is_load = False
                        
                        # Process first operand
                        if len(words) > 1 and words[1] != ':':
                            if words[1] in REGISTERS:
                                if words[0] in [ "OUT", "OUTI"]:
                                    instruction += "0000" + to_binary(REGISTERS.index(words[1]), 4)
                                else:
                                    instruction += to_binary(REGISTERS.index(words[1]), 4)
                            else:
                                # Valeur immédiate
                                try:
                                    value = int(words[1], 16) if words[1].startswith('0x') else int(words[1], 10)
                                    instruction += "0000" + to_binary(value, 16)
                                except ValueError:
                                    if words[1] in labels:
                                        instruction += "0000" + to_binary(labels[words[1]], 16)
                                    elif words[1].startswith(';'):
                                        pass
                                    else:
                                        print(f"Error: Invalid value '{words[1]}' on line {pc+1}")
                                        sys.exit(1)
                        
                            # Process second operand
                            if len(words) > 2:
                                if words[2] in REGISTERS:
                                    if( words[0]=="IN"):
                                        instruction += "0000" + to_binary(REGISTERS.index(words[2]), 4)
                                    else:
                                        instruction += to_binary(REGISTERS.index(words[2]), 4)
                                elif words[2] in labels:
                                    instruction += "0000" + to_binary(labels[words[2]], 16)
                                    is_load = True
                                elif words[2] in SHORTCUTS:
                                    if words[0] in [ "OUT", "OUTI"]:
                                        instruction += to_binary(ADDR_SHORTCUTS[SHORTCUTS.index(words[2])], 16)
                                    else:
                                        instruction += "0000" + to_binary(ADDR_SHORTCUTS[SHORTCUTS.index(words[2])], 16)
                                    is_load = True
                                else:
                                    try:
                                        value = int(words[2], 16) if words[2].startswith('0x') else int(words[2], 10)
                                        if words[0] in [ "OUT", "OUTI"]:
                                            instruction += to_binary(value, 16)
                                        else:
                                            instruction += "0000" + to_binary(value, 16)
                                        is_load = True
                                    except ValueError:
                                        if words[2].startswith(';'):
                                            pass
                                        else:
                                            print(f"Error: Invalid value '{words[2]}' on line {pc+1}")
                                            sys.exit(1)
                            else:
                                instruction += "0" * (29 - len(instruction))
                        
                            # Process third operand
                            if len(words) > 3:
                                if words[3] in REGISTERS:
                                    instruction += to_binary(REGISTERS.index(words[3]), 4) + "0" * 12
                                elif words[3] in labels:
                                    instruction += to_binary(labels[words[3]], 16)
                                    is_load = True
                                elif words[3] in SHORTCUTS:
                                    instruction += to_binary(ADDR_SHORTCUTS[SHORTCUTS.index(words[3])], 16)
                                    is_load = True
                                else:
                                    try:
                                        value = int(words[3], 16) if words[3].startswith('0x') else int(words[3], 10)
                                        instruction += to_binary(value, 16)
                                        is_load = True
                                    except ValueError:
                                        if words[3].startswith(';'):
                                            pass
                                        else:
                                            print(f"Error: Invalid value '{words[3]}' on line {pc+1}")
                                            sys.exit(1)
                            elif not is_load:
                                instruction += "0" * (29 - len(instruction))
                        else:
                            # No operands (like HALT)
                            instruction += "0" * (29 - len(instruction))
                    
                # Ensure instruction is 29 bits long
                if len(instruction) != 29:
                    instruction = instruction.ljust(29, '0')
                
                # Write the instruction in the appropriate format
                if mode == 0:
                    output.write(instruction + '\n')
                elif mode == 1:
                    output.write(to_verilog(instruction, pc))
                elif mode == 2:
                    output.write(to_hex8(instruction) + '\n')
                
                pc += 1
            except Exception as e:
                print(f"Error on line {pc+1}: {str(e)}")
                if words[0] in COMMANDS:
                    # Handle single-opcode instructions like HALT
                    instruction = to_binary(COMMANDS.index(words[0]), 5) + "0" * 24
                    if mode == 0:
                        output.write(instruction + '\n')
                    elif mode == 1:
                        output.write(to_verilog(instruction, pc))
                    elif mode == 2:
                        output.write(to_hex8(instruction) + '\n')
                    pc += 1
                elif words[0] in JUMP_IDS:
                    # Handle jump instructions that failed
                    instruction = "10010" + to_binary(JUMP_IDS[words[0]], 2) + "0" * 22
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

if __name__ == "__main__":
    main()
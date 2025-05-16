import sys
try:
    source=open(sys.argv[1],"r")
    output=open(sys.argv[2],"w")
except:
    source=open("main.asm","r")
    output=open("main.hex","w")

PC=0
ld=0
jmp=0
commande=["HALT","LOAD","ADD","ADDI","SUB","SUBI","SHL","SHLI","SHR","SHRI","AND","ANDI","NAND","NANDI","OR","ORI","XOR","XORI","JMP","JM0","JMC","JMN","IN","OUT","OUTI","CALL","RET"]
registres=["R0","R1","R2","R3","R4","R5","R6","R7","R8","R9","R10","R11","R12","R13","R14","R15"]
raccourcis=["RAM0","GPI0","GPI1","GPO0","GPO1","SPI","BAUDH","BAUDL","UART"]
adrRacc=[16384,0,1,2,3,4,5,6,7]
label=[]
adrLab=[]

#decimal to binary with output lenght
def b(decimal,nb):
    b=""
    for i in range(nb):
        bi=decimal % 2
        decimal //= 2
        b=str(bi)+b
    return(b)

#binary to hexadecimal with 8 digits output 
def hexa8(strbin):
    binhex=["0000","0001","0010","0011","0100","0101","0110","0111","1000","1001","1010","1011","1100","1101","1110","1111"]
    dechex=["0","1","2","3","4","5","6","7","8","9","a","b","c","d","e","f"]
    mot="000"+strbin
    h1=dechex[binhex.index(mot[0:4])]
    h2=dechex[binhex.index(mot[4:8])]
    h3=dechex[binhex.index(mot[8:12])]
    h4=dechex[binhex.index(mot[12:16])]
    h5=dechex[binhex.index(mot[16:20])]
    h6=dechex[binhex.index(mot[20:24])]
    h7=dechex[binhex.index(mot[24:28])]
    h8=dechex[binhex.index(mot[28:32])]
    return(h1+h2+h3+h4+h5+h6+h7+h8)

#get label adresses
for line in source:
    try:
        mots = line.split()
        if(mots[1]==':'):
            label.append(mots[0])
            adrLab.append(PC)
        else:
            PC+=1
    except:
        PC+=1
source.close()
print(label)
#convert to machine code
source=open("main.asm","r")
for ligne in source:
    mots = ligne.split()
    try:
        if(mots[1]!=':'):
            inst=b(commande.index(mots[0]),5)
            if mots[1] in registres:
                inst=inst+b(registres.index(mots[1]),4)
            elif mots[1] in label:
                if(inst=="10011"):
                    inst=inst+"00000001"+b(adrLab[label.index(mots[1])],16)
                elif(inst=="10100"):
                    inst=inst+"00000010"+b(adrLab[label.index(mots[1])],16)
                elif(inst=="10101"):
                    inst=inst+"00000011"+b(adrLab[label.index(mots[1])],16)
                else:
                    inst=inst+"00000000"+b(adrLab[label.index(mots[1])],16)
                jmp=1
            else:
                if(inst=="10011"):
                    inst=inst+"00000001"+b(int(mots[1],16))
                elif(inst=="10100"):
                    inst=inst+"00000010"+b(int(mots[1],16))
                elif(inst=="10101"):
                    inst=inst+"00000011"+b(int(mots[1],16))
                else:
                    inst=inst+"00000000"+b(int(mots[1],16))
                jmp=1 
            try:
                if mots[2] in registres:
                    inst=inst+b(registres.index(mots[2]),4)
                elif mots[2] in label:
                    inst=inst+"0000"+b(adrLab[label.index(mots[2])],16)
                    ld=1
                elif mots[2] in raccourcis:
                    inst=inst+"0000"+b(adrRacc[raccourcis.index(mots[2])],16)
                    ld=1
                else:
                    inst=inst+"0000"+b(int(mots[2]),16)
                    ld=1
            except:
                if(jmp==0 and ld==0):
                    inst=inst+"00000000000000000000"
            try:
                if mots[3] in registres:
                    inst=inst+b(registres.index(mots[3]),4)+"000000000000"
                elif mots[3] in label:
                    inst=inst+b(adrLab[label.index(mots[3])],16)
                    ld=1
                elif mots[3] in raccourcis:
                    inst=inst+b(adrRacc[raccourcis.index(mots[3])],16)
                    ld=1
                else:
                    inst=inst+b(int(mots[3]),16)
                    ld=1
            except:
                if(jmp==0 and ld==0):
                    inst=inst+"0000000000000000"
            output.write(hexa8(inst))
            output.write('\n')
            jmp=0
            ld=0            
    except:
        inst=b(commande.index(mots[0]),5)+"000000000000000000000000"
        output.write(hexa8(inst))
        output.write('\n')
        

source.close()
output.close()
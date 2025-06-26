import serial
from progBuffer import code


# 1. DÉTECTION DES PORTS DISPONIBLES
def lister_ports():
    import serial.tools.list_ports
    
    ports = serial.tools.list_ports.comports()
    for port in ports:
        print(f"Port: {port.device}")
        print(f"Description: {port.description}")
        print(f"Fabricant: {port.manufacturer}")
        print("---")

# 2. COMMUNICATION BINAIRE
def transfert_binaire():
    len_code = len(code)
    page_count = 0
    flash_addr = 0x001000
    while (len_code !=0):
        page_count +=1 
        if len_code>255 :
            bytes_to_write = 255
            len_code-=255
        else :
            bytes_to_write = len_code
            len_code = 0

        flash_addrH = (flash_addr>>16) & 0xff
        flash_addrM = (flash_addr>>8) & 0xff
        flash_addrL = flash_addr & 0xff

        ser.write(flash_addrH)
        ser.write(flash_addrM)
        ser.write(flash_addrL)
        print("Ecriture a l'adresse : "+ str(flash_addr))

        ser.write(bytes_to_write)
        print("Ecriture de "+ str(bytes_to_write)+" octets")
        
        for i in range(bytes_to_write) :
            # Envoyer des données binaires
            ser.write(code[i])

        # Lire des données binaires
        received = ser.read(1)
        if(received!=0xDC) :
            print("Erreur de transfert ligne "+ str(i))
            return 1    
  
        print("Page "+str(page_count)+" écrite avec succès\n")

        flash_addr += 0x100

    return 0

# 1. CONNEXION DE BASE
# Ouvrir une connexion série
print("Ports disponibles:")
lister_ports()

print("\nQuele Port choisisez-vous: ")
PORT=input("COM")

ser = serial.Serial(
    port="COM"+PORT,          # Windows: COM1, COM2... / Linux: /dev/ttyUSB0, /dev/ttyACM0...
    baudrate=115200,    # Vitesse de transmission (bits/seconde)
    bytesize=8,         # Nombre de bits de données
    parity='N',         # Parité (N=None, E=Even, O=Odd)
    stopbits=1,         # Bits d'arrêt
    timeout=1           # Timeout en secondes
)

if transfert_binaire() :
    print("Le transfert a échoué")
else :
    print("Le transfert est réussi")




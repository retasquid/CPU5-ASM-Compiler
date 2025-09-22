
// Tableau de données à écrire
#include "prog.h"

#define SCLK 16   // Serial Clock
#define SO 2     // Serial Output (MISO - Master In Slave Out)
#define SI 15     // Serial Input (MOSI - Master Out Slave In)
#define CSn 4    // Chip Select

// Instructions pour MX25L3233F
#define WRITE_ENABLE 0x06
#define WRITE_DISABLE 0x04
#define READ_STATUS_REG 0x05
#define READ_STATUS_REG2 0x35
#define WRITE_STATUS_REG 0x01
#define READ_DATA 0x03
#define FAST_READ 0x0B
#define PAGE_PROGRAM 0x02
#define SECTOR_ERASE 0x20        // 4KB
#define BLOCK_ERASE_32K 0x52     // 32KB
#define BLOCK_ERASE 0xD8         // 64KB
#define CHIP_ERASE 0xC7
#define READ_ID 0x9F
#define RESET_ENABLE 0x66
#define RESET_DEVICE 0x99

// Mode de fonctionnement
#define MODE_READ 1
#define MODE_WRITE 0
#define MODE MODE_WRITE  // Changez ici pour basculer entre lecture/écriture

// Adresse d'écriture/lecture
#define WRITE_ADDRESS 0x1000  // Utiliser une adresse alignée sur un secteur
#define ROM_SIZE 262143

void setup() {
  // Configuration des broches
  pinMode(CSn, OUTPUT);
  pinMode(SCLK, OUTPUT);
  pinMode(SI, OUTPUT);
  pinMode(SO, INPUT);
  // État initial des broches
  digitalWrite(CSn, HIGH);    // Désactiver la puce
  
  // Initialiser la communication série pour le débogage
  Serial.begin(115200);
  while (!Serial) { ; }  // Attendre que le port série soit prêt
  flashProgrammer();

}

void loop() {

}
void flashProgrammer(){
  Serial.println("\n\n=== EEPROM MX25L PROGRAMMER ===\n");
  // Configuration initiale de l'EEPROM
  EEPROMsetup();
    // Afficher l'ID de la puce à chaque cycle
  Serial.println("\n--- Lecture ID ---");
  uint8_t id[3];
  readID(id);
  Serial.print("ID fabricant: 0x");
  Serial.println(id[0], HEX);
  Serial.print("Type de mémoire: 0x");
  Serial.println(id[1], HEX);
  Serial.print("Capacité: 0x");
  Serial.print(id[2], HEX);
  Serial.print(" / ");
  unsigned long taille = 1<<(id[2]-17);
  Serial.print(taille);
  Serial.print(" Megabits\n");
  
  // Vérifier si c'est bien une puce Macronix
  if(id[0] != 0xC2) {
    Serial.println("ATTENTION: Puce non reconnue ou problème de communication!");
    delay(1000);
    return;
  }
  
  if(MODE == MODE_READ) {
    performRead();
  } else {
    performWrite();
    // Après écriture, passer en mode lecture pour éviter d'écrire en continu
    // Commentez la ligne suivante si vous voulez rester en mode écriture
    // MODE = MODE_READ;
  }
}

void performRead() {
  Serial.println("=== DEBUT LECTURE ===");
  Serial.print("Lecture à l'adresse 0x");
  Serial.println(WRITE_ADDRESS, HEX);
  
  uint8_t data[sizeof(code)];
  EEPROMread(WRITE_ADDRESS, data, sizeof(code));
  
  Serial.println("Données lues:");
  printHexData(data, sizeof(code),WRITE_ADDRESS);
}

void performWrite() {
  Serial.println("=== DEBUT ECRITURE ===");
  
  // 2. Effacer le secteur avant écriture
  Serial.print("Effacement du secteur à l'adresse 0x");
  Serial.println(WRITE_ADDRESS, HEX);
  sectorErase(WRITE_ADDRESS);
  
  // 3. Écrire les données
  Serial.print("Écriture de ");
  Serial.print(sizeof(code));
  Serial.print(" octets à l'adresse 0x");
  Serial.println(WRITE_ADDRESS, HEX);
  
  writeMultiplePages(WRITE_ADDRESS, (uint8_t*)code, sizeof(code));
  
  Serial.println("Écriture vector table");

  // Calculer l'adresse de la table vectorielle (fin de ROM)
  uint32_t vectorAddress = ROM_SIZE - 31; // 65536 - 32 = 65504 (0xFFE0)
  
  // Vérifier si la table vectorielle est dans le même secteur que le code principal
  uint32_t codeSector = WRITE_ADDRESS & 0xFFFFF000;
  uint32_t vectorSector = vectorAddress & 0xFFFFF000;
  
  Serial.print("Secteur du code: 0x");
  Serial.println(codeSector, HEX);
  Serial.print("Secteur de la table vectorielle: 0x");
  Serial.println(vectorSector, HEX);
  
  // Effacer le secteur de la table vectorielle seulement s'il est différent
  if(vectorSector != codeSector) {
    Serial.print("Effacement du secteur pour la table vectorielle à 0x");
    Serial.println(vectorSector, HEX);
    sectorErase(vectorSector);
  } else {
    Serial.println("Table vectorielle dans le même secteur - pas d'effacement supplémentaire");
  }
  
  writeMultiplePages(vectorAddress, (uint8_t*)vector_table, 32);

  Serial.println("Écriture terminée");
  
  // 4. Vérification du code principal
  
  Serial.println("\n=== VERIFICATION CODE ===");
  uint8_t readData[sizeof(code)];
  EEPROMread(WRITE_ADDRESS, readData, sizeof(code));
  
  Serial.println("Données lues après écriture:");
  printHexData(readData, sizeof(code),0);
  
  // 5. Comparaison code
  bool success1 = verifyData((uint8_t*)code, readData, sizeof(code));

  // 6. Vérification vector table 
  Serial.println("\n=== VERIFICATION VECTOR TABLE ===");
  uint8_t readDataVector[32];
  EEPROMread(vectorAddress, readDataVector, 32);
  
  Serial.println("Table vectorielle lue après écriture:");
  printHexData(readDataVector, 32, 0);
  
  // 7. Comparaison vector table
  bool success2 = verifyData((uint8_t*)vector_table, readDataVector, 32);

  if(success1 && success2) {
    Serial.println("✓ VERIFICATION REUSSIE - Données correctement écrites!");
  } else {
    Serial.println("✗ ERREUR - Données corrompues!");
  }
  
}
// Afficher des données en hexadécimal avec formatage amélioré
void printHexData(const uint8_t *data, uint16_t length, uint32_t offset) {
  for(uint32_t i = offset; i < length+offset; i++) {
    if(i % 16 == 0) {
      Serial.print("0x");
      if(i < 0x10) Serial.print("0");
      if(i < 0x100) Serial.print("0");
      Serial.print(i, HEX);
      Serial.print(": ");
    }
    
    if(data[i] < 0x10) Serial.print("0");
    Serial.print(data[i] , HEX);
    Serial.print(" ");
    
    if((i + 1) % 16 == 0) {
      Serial.println();
    } else if((i + 1) % 4 == 0) {
      Serial.print(" ");
    }
  }
  if(length % 16 != 0) Serial.println();
}

// Vérifier que les données lues correspondent aux données écrites
bool verifyData(const uint8_t *expected, const uint8_t *actual, uint16_t length) {
  for(uint16_t i = 0; i < length; i++) {
    if(expected[i] != actual[i]) {
      Serial.print("ERREUR à l'offset ");
      Serial.print(i);
      Serial.print(": attendu 0x");
      if(expected[i] < 0x10) Serial.print("0");
      Serial.print(expected[i], HEX);
      Serial.print(", lu 0x");
      if(actual[i] < 0x10) Serial.print("0");
      Serial.println(actual[i], HEX);
      return false;
    }
  }
  return true;
}

// Écriture sur plusieurs pages (gère automatiquement les limites)
void writeMultiplePages(uint32_t address,const uint8_t *data, uint16_t length) {
  uint16_t bytesWritten = 0;
  
  Serial.println("Début écriture multi-pages:");
  
  while(bytesWritten < length) {
    uint32_t currentAddress = address + bytesWritten;
    uint16_t pageOffset = currentAddress & 0xFF;  // Position dans la page courante
    uint16_t bytesInPage = 256 - pageOffset;      // Octets restants dans la page
    uint16_t bytesToWrite = (bytesInPage<(length - bytesWritten))?bytesInPage : (length - bytesWritten);
    Serial.print("  Écriture page: ");
    Serial.print(bytesToWrite);
    Serial.print(" octets à 0x");
    Serial.print(currentAddress, HEX);
    
    EEPROMwrite(currentAddress, data + bytesWritten, bytesToWrite);
    
    Serial.println(" - OK");
    bytesWritten += bytesToWrite;
  }
  Serial.print("Total écrit: ");
  Serial.print(bytesWritten);
  Serial.println(" octets");
}

void EEPROMsetup() {
  Serial.println("Initialisation de l'EEPROM MX25L...");
  
  // Reset de la puce pour s'assurer qu'elle est dans un état connu
  resetDevice();
  
  // Vérifier que la puce est prête
  uint8_t status = readStatus();
  
  // Interpréter le statut
  if(status & 0x01) Serial.println("  - Opération en cours (BUSY)");
  if(status & 0x02) Serial.println("  - Écriture activée (WEL)");
  if(status & 0x3C) Serial.println("  - Protection active");
  
  // Si nécessaire, déverrouiller la protection en écriture
  if(status & 0x3C) {
    Serial.println("Désactivation de la protection...");
    writeEnable();
    writeStatus(0x00);
    Serial.println("Protection désactivée");
  }
}

void resetDevice() {  
  digitalWrite(CSn, LOW);
  sendByte(RESET_ENABLE);
  digitalWrite(CSn, HIGH);
  delayMicroseconds(10);
  
  digitalWrite(CSn, LOW);
  sendByte(RESET_DEVICE);
  digitalWrite(CSn, HIGH);
  
  delay(30);  // Attendre que le reset soit terminé
  Serial.println("Reset terminé");
}

uint8_t readStatus() {
  uint8_t status;
  
  digitalWrite(CSn, LOW);
  sendByte(READ_STATUS_REG);
  status = receiveByte();
  digitalWrite(CSn, HIGH);
  
  return status;
}

void writeEnable() {
  digitalWrite(CSn, LOW);
  sendByte(WRITE_ENABLE);
  digitalWrite(CSn, HIGH);
  
  // Vérifier que le WEL bit est mis à 1
  uint8_t status = readStatus();
  if(!(status & 0x02)) {
    Serial.println("ERREUR: Write Enable a échoué!");
  }
}

void writeDisable() {
  digitalWrite(CSn, LOW);
  sendByte(WRITE_DISABLE);
  digitalWrite(CSn, HIGH);
}

void writeStatus(uint8_t status) {
  digitalWrite(CSn, LOW);
  sendByte(WRITE_STATUS_REG);
  sendByte(status);
  digitalWrite(CSn, HIGH);
  
  // Attendre que l'opération soit terminée
  while(readStatus() & 0x01) {
    delay(1);
  }
}

void readID(uint8_t *id) {
  digitalWrite(CSn, LOW);
  sendByte(READ_ID);
  id[0] = receiveByte();  // ID fabricant (0xC2 pour Macronix)
  id[1] = receiveByte();  // Type
  id[2] = receiveByte();  // Capacité (0x16 pour 32Mbit)
  digitalWrite(CSn, HIGH);
}

void EEPROMread(uint32_t address, uint8_t *buffer, uint16_t length) {
  digitalWrite(CSn, LOW);
  sendByte(READ_DATA);
  sendByte((address >> 16) & 0xFF);  // MSB
  sendByte((address >> 8) & 0xFF);   // Milieu
  sendByte(address & 0xFF);          // LSB
  
  for(uint16_t i = 0; i < length; i++) {
    buffer[i] = receiveByte();
  }
  
  digitalWrite(CSn, HIGH);
}

void EEPROMwrite(uint32_t address, const uint8_t *buffer, uint16_t length) {
  // Vérifier si l'adresse + longueur dépasse une page
  if((address & 0xFF) + length > 256) {
    Serial.println("ERREUR: L'écriture traverse une limite de page");
    return;
  }
  
  writeEnable();
  
  digitalWrite(CSn, LOW);
  sendByte(PAGE_PROGRAM);
  sendByte((address >> 16) & 0xFF);  // MSB
  sendByte((address >> 8) & 0xFF);   // Milieu
  sendByte(address & 0xFF);          // LSB
  
  for(uint16_t i = 0; i < length; i++) {
    sendByte(pgm_read_byte(buffer+i));
  }
  
  digitalWrite(CSn, HIGH);
  
  // Attendre que l'opération d'écriture soit terminée
  while(readStatus() & 0x01) {
    delay(1);
  }
  
  writeDisable();
}

// Effacer un secteur (4KB)
void sectorErase(uint32_t address) {
  writeEnable();
  
  digitalWrite(CSn, LOW);
  sendByte(BLOCK_ERASE);
  sendByte((address >> 16) & 0xFF);  // MSB
  sendByte((address >> 8) & 0xFF);   // Milieu
  sendByte(address & 0xFF);          // LSB
  digitalWrite(CSn, HIGH);
  
  // Attendre que l'opération d'effacement soit terminée
  while(readStatus() & 0x01) {
    Serial.print(".");
    delay(100);
  }
  writeDisable();
}

void sendByte(uint8_t byte) {
  for(int i = 7; i >= 0; i--) {
    digitalWrite(SI, (byte >> i) & 0x01);
    digitalWrite(SCLK, HIGH);
    delayMicroseconds(1);
    digitalWrite(SCLK, LOW);
    delayMicroseconds(1);
  }
}

uint8_t receiveByte() {
  uint8_t byte = 0;
  
  for(int i = 7; i >= 0; i--) {
    digitalWrite(SCLK, HIGH);
    delayMicroseconds(1);
    byte |= (digitalRead(SO) << i);
    digitalWrite(SCLK, LOW);
    delayMicroseconds(1);
  }
  
  return byte;
}

#include "prog.h"

#define CSn 8    // Chip Select
#define SO 9     // Serial Output (MISO - Master In Slave Out)
#define SCLK 10   // Serial Clock
#define SI 11     // Serial Input (MOSI - Master Out Slave In)

// Instructions pour MX25L3233F - identiques à la plupart des mémoires flash SPI
#define WRITE_ENABLE 0x06
#define WRITE_DISABLE 0x04
#define READ_STATUS_REG 0x05
#define READ_STATUS_REG2 0x35    // Registre de statut 2 (peut être différent selon les puces)
#define WRITE_STATUS_REG 0x01
#define READ_DATA 0x03
#define FAST_READ 0x0B
#define PAGE_PROGRAM 0x02
#define SECTOR_ERASE 0x20        // 4KB
#define BLOCK_ERASE_32K 0x52     // 32KB
#define BLOCK_ERASE 0xD8         // 64KB
#define CHIP_ERASE 0xC7          // Ou 0x60 pour certaines puces
#define READ_ID 0x9F
#define ENABLE_QPI 0x35          // MX25L3233F peut supporter le mode QPI
#define RESET_ENABLE 0x66        // Instructions de reset
#define RESET_DEVICE 0x99


#define read 1
#define write 0
#define MODE write

void setup() {
  // Configuration des broches
  pinMode(CSn, OUTPUT);
  pinMode(SCLK, OUTPUT);
  pinMode(SI, OUTPUT);
  pinMode(SO, INPUT);
  
  // État initial des broches
  digitalWrite(CSn, HIGH);    // Désactiver la puce
  
  // Initialiser la communication série pour le débogage
  Serial.begin(9600);
  
  // Configuration initiale de l'EEPROM
  EEPROMsetup();
}

void loop() {
  if(MODE){
    Serial.println("Lecture de la puce MX25L3233F:");
    char data[256];
    for(int pc=0; pc<(sizeof(code)>>8); pc++){
      EEPROMread(pc, data, 256);
      for(int i=0; i<4; i++){
        Serial.print(" 0x");
        Serial.print(data[pc+i]);
      }
      Serial.println("");
    }
  }else{
    Serial.println("Ecriture de la puce MX25L3233F:");
    for(int pc=0; pc<(sizeof(code)>>8); pc++){
      EEPROMwrite(pc, code, 256);
      for(int i=0; i<4; i++){
        Serial.print(" 0x");
        Serial.print(code[pc+i]);
      }
      Serial.println("");
    }
  }
}

void EEPROMsetup() {
  Serial.println("Initialisation de l'EEPROM MX25L3233F...");
  
  // Reset de la puce pour s'assurer qu'elle est dans un état connu
  resetDevice();
  
  // Vérifier que la puce est prête
  uint8_t status = readStatus();
  Serial.print("Statut initial: 0x");
  Serial.println(status, HEX);
  
  // Si nécessaire, déverrouiller la protection en écriture
  if(status & 0x3C) {  // Si des bits de protection sont actifs
    writeEnable();
    writeStatus(0x00);  // Désactiver toutes les protections
    Serial.println("Protection en écriture désactivée");
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
  
  delay(30);  // Attendre que le reset soit terminé (généralement <30ms)
}

uint8_t readStatus() {
  uint8_t status;
  
  digitalWrite(CSn, LOW);
  sendByte(READ_STATUS_REG);
  status = receiveByte();
  digitalWrite(CSn, HIGH);
  
  return status;
}

// Activer l'écriture
void writeEnable() {
  digitalWrite(CSn, LOW);
  sendByte(WRITE_ENABLE);
  digitalWrite(CSn, HIGH);
  
  // Attendre que le WEL bit soit mis à 1
  while(!(readStatus() & 0x02));
}

// Désactiver l'écriture
void writeDisable() {
  digitalWrite(CSn, LOW);
  sendByte(WRITE_DISABLE);
  digitalWrite(CSn, HIGH);
}

// Écrire dans le registre de statut
void writeStatus(uint8_t status) {
  digitalWrite(CSn, LOW);
  sendByte(WRITE_STATUS_REG);
  sendByte(status);
  digitalWrite(CSn, HIGH);
  
  // Attendre que l'opération soit terminée
  while(readStatus() & 0x01);
}

void readID(uint8_t *id) {
  digitalWrite(CSn, LOW);
  sendByte(READ_ID);
  id[0] = receiveByte();  // ID fabricant (devrait être 0xC2 pour Macronix)
  id[1] = receiveByte();  // Type de mémoire
  id[2] = receiveByte();  // Capacité (devrait être 0x16 pour 32Mbit)
  digitalWrite(CSn, HIGH);
}

// Lire des données de l'EEPROM
void EEPROMread(uint32_t address, uint8_t *buffer, uint16_t length) {
  digitalWrite(CSn, LOW);
  sendByte(READ_DATA);
  // MX25L3233F nécessite une adresse sur 24 bits (3 octets)
  sendByte((address >> 16) & 0xFF);  // MSB
  sendByte((address >> 8) & 0xFF);   // Milieu
  sendByte(address & 0xFF);          // LSB
  
  for(uint16_t i = 0; i < length; i++) {
    buffer[i] = receiveByte();
  }
  
  digitalWrite(CSn, HIGH);
}

// Écrire des données dans l'EEPROM (limité à une page de 256 octets)
void EEPROMwrite(uint32_t address, uint8_t *buffer, uint16_t length) {
  // Vérifier si l'adresse + longueur dépasse une page
  if((address & 0xFF) + length > 256) {
    Serial.println("Erreur: L'écriture traverse une limite de page");
    return;
  }
  
  writeEnable();
  
  digitalWrite(CSn, LOW);
  sendByte(PAGE_PROGRAM);
  sendByte((address >> 16) & 0xFF);
  sendByte((address >> 8) & 0xFF);
  sendByte(address & 0xFF);
  
  for(uint16_t i = 0; i < length; i++) {
    sendByte(buffer[i]);
  }
  
  digitalWrite(CSn, HIGH);
  
  // Attendre que l'opération d'écriture soit terminée
  while(readStatus() & 0x01);
  
  writeDisable();
}

// Envoyer un octet via SPI bit par bit
void sendByte(uint8_t byte) {
  for(int i = 7; i >= 0; i--) {
    digitalWrite(SI, (byte >> i) & 0x01);
    digitalWrite(SCLK, HIGH);
    delayMicroseconds(10000);  // Court délai pour s'assurer que le signal est stable
    digitalWrite(SCLK, LOW);
    delayMicroseconds(10000);
  }
}

// Recevoir un octet via SPI bit par bit
uint8_t receiveByte() {
  uint8_t byte = 0;
  
  for(int i = 7; i >= 0; i--) {
    digitalWrite(SCLK, HIGH);
    delayMicroseconds(10000);
    byte |= (digitalRead(SO) << i);
    digitalWrite(SCLK, LOW);
    delayMicroseconds(10000);
  }
  
  return byte;
}
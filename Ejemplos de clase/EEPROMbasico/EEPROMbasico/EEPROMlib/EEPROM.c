#include "EEPROM.h"

void writeEEPROM(uint16_t direccion, uint8_t dato)
{
	// Esperar a que termine de escribir
	while (EECR & (1<<EEPE));
	// Asignar dirección donde queremos escribir
	EEAR = direccion;
	// Asignar dato a guardar
	EEDR = dato;
	// Master write
	EECR |= (1<<EEMPE);
	// Write enable
	EECR |= (1<<EEPE);
}

uint8_t readEEPROM(uint16_t direccion)
{
	// Esperar a que termine de escribir dato anterior
	while (EECR & (1<<EEPE));
	// Asignar dirección donde queremos leer el dato
	EEAR = direccion;
	// Read enable (ya sin el error que tenías)
	EECR |= (1<<EERE);
	// Retornar lectura de EEPROM en dirección EEAR
	return EEDR;
}
/*
 * NombreProgra.c
 * Created: 23 APR 26
 * Author: LUIS CHACÓN
 */

#include <avr/io.h>
#include <avr/interrupt.h>
#include "UARTlib/UART.h"
#include "EEPROM.h" // Incluyes tu nueva librería

uint16_t dir_eeprom = 0;

int main (void)
{
    cli();
	DDRD | = (1<<DDD6) | (1<<DDD5);
	PORTD &= ~((1<<PORTD6) | (1<<PORTD5));
    initUART();
    sei();
    
    uint8_t lectura = readEEPROM(dir_eeprom);
    
    while(lectura != 0xFF)
    {
        WriteChar(lectura);
        writeEEPROM(dir_eeprom, 0xFF);
        
        dir_eeprom++;
        lectura = readEEPROM(dir_eeprom);
    }
    
    // dir_eeprom = 0; // Descomenta esto si quieres reiniciar el contador
    
    while(1)
    {
        // Bucle infinito
    }
}

ISR(USART_RX_vect)
{
    uint8_t rx_buffer = UDR0;
	if (rx_buffer !)
	{
	}
    WriteChar(rx_buffer);
    writeEEPROM(dir_eeprom, rx_buffer);
    dir_eeprom++;
}
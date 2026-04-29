#include "UART.h"

void initUART(void)
{
	// D0 = RX -> Entrada
	DDRD &=~ (1<<DDD0);
	// D1 = TX -> Salida
	DDRD |= (1<<DDD1);
	
	// Normal speed
	UCSR0A = 0;
	UCSR0B = (1<<RXCIE0) | (1<<RXEN0) | (1<<TXEN0);
	// Modo async, sin paridad, 1 stop bit, 8 data bits
	UCSR0C = (1<<UCSZ01) | (1<<UCSZ00);
	// Cargar UBRR0
	UBRR0 = 103;
}

void WriteChar(char c)
{
	while(!(UCSR0A & (1<<UDRE0)));
	UDR0 = c;
}

void writeString(char* string)
{
	for(uint8_t i = 0; string[i] != '\0'; i++)
	{
		WriteChar(string[i]);
	}
}
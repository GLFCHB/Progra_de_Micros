#include <avr/io.h>
#include <avr/interrupt.h>
#include "UARTlib/UART.h" // Incluyes el archivo que creaste

int main(void)
{
	cli();
	
	// Configuración B5
	DDRB |= (1<<DDB5);
	PORTB &= ~(1<<PORTB5);
	
	// Configuración D5
	DDRD |= (1<<DDD5);
	PORTD &= ~(1<<PORTD5);

	initUART();
	writeString("Hola seccion 10\r\n");
	
	sei();

	while(1)
	{
		// El programa se queda aquí
	}
}

ISR(USART_RX_vect)
{
	uint8_t bufferRX = UDR0;
	WriteChar(bufferRX);
	
	if (bufferRX == 'a')
	{
		PORTB |= (1<<PORTB5);
		PORTD |= (1<<PORTD5);
	}
	
	if(bufferRX == 'b')
	{
		PORTB &= ~(1<<PORTB5);
		PORTD &= ~(1<<PORTD5);
	}
}
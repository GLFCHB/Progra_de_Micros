/*
 * NombreProgra.c
 *
 * Created: 
 * Author: 
 * Description: 
 */
/****************************************/
// Encabezado (Libraries)


/****************************************/
// Function prototypes

/****************************************/
// Main Function

int main(void)
{
	cli():
	DDRB |= (1<<DDB5);
	PORB &= ~(1<<PORTB5);
	DDRB |= (1<<DDD5);
	PORB &= ~(1<<PORTD5);
	initUART();
	writeString("Hola sección 10");
	while(1)
	{
		
	}
}

/****************************************/
// NON-Interrupt subroutines
void initsUART()
{
	//Configurar pine
	DDRD &=~ (1<<DDD0); // D0 = RX -> Entrada
	DDRD &=~ (1<<DDD1); // D1 = TX -> Salida
	
	//Normal speed
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

void writeStrin(char* string)
{
	for(uint8_t i = 0; string[i] != '\0'; i++)
	{
		WriteChar(string[i]);
	}
}

/****************************************/
// Interrupt routines

ISR(USART_RX_vect)
{
	uint8_t bufferRX = UDR0;
	WriteChar(bufferRX);
	if (bufferRX == 'a')
	{
		PORTB |= (1<<PORTB5);
		PORTB |= (1<<PORTB5);
		
	}
	
	if(bufferRX == 'b')
	{
		PORTB &= ~(1<<PORTB5);
		PORTB &= ~(1<<PORTB5);
	}
}
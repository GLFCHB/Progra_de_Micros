/*
 * NombreProgra.c
 *
 * Created: 
 * Author: 
 * Description: 
 */
/****************************************/
// Encabezado (Libraries)
#include <avr/io.h>
#include <stdint.h>

/****************************************/
// Function prototypes
void setup();
void delay();

/****************************************/
// Main Function
int main(void)
{
	setup();
	while(1)
	{
		PORTC | = (1<<PORTC3) |(1<<PORTC2) |(1<<PORTC1) |(1<<PORTC0);
		delay ();
		PORTC & = ~((1<<PORTC3) |(1<<PORTC2) |(1<<PORTC1) |(1<<PORTC0));
		delay ();
		
		/*Forma de hacer toggle:
		PORTC ^ = (1<<PORTC3) |(1<<PORTC2) |(1<<PORTC1) |(1<<PORTC0);
		delay ();
		*/
		
	}
}
/****************************************/
// NON-Interrupt subroutines
void setup()
{
	//CONFIGURAR PRESCALER = 16
	CLKPR	= (1<<CLKPCE);
	CLKPR	= (1<<CLKPS2);
	//CONFIGURAR OUTPUT
	//DDRC	= 0xFF (ALTERNATIVA)
	DDRC	| = (1<<DDC3) | (1<<DDC2) | (1<<DDC1) | (1<<DDC0);
	PORTC & = ~((1<<DDC3) | (1<<DDC2) | (1<<DDC1) | (1<<DDC0));
/*
	PORTC = 1101 1101
			1111 0000
	-----------------
			1101 0000	
*/

}

void delay()
{
	for (volatile uint8_t i = 0 <255; i++)
	{
		for (volatile uint8_t i = 0 <255; i++)
		{
			
		}
	}
}
/****************************************/
// Interrupt routines
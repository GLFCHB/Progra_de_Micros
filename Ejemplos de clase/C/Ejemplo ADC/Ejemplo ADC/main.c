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
#include <avr/interrupt.h>

/****************************************/
// Function prototypes
void setup();
void initADC();

/****************************************/
// Main Function
int main (void)
{
	
	cli();
	setup();
	initADC();
	//Habilitar interrupciones
	ADCSRA | = (1<<ADIE);
	// Iniciar conv. ADC
	ADCSRA | = (1<<ADSC);
	sei();
	while (1)
	{
		
	}
	{
	}
}
/****************************************/
// NON-Interrupt subroutines
void setup()
{
	//Prescaler_CPU = 16
	CLKPR = (1<<CLKPCE);
	CLKPR = (1<<CLKPS2);
	
	//Configurar salidas (DDRD)
	DDRD = 0xFF; //Todo el puerto D como salida
	PORTD = 0x00; //Todo el puerto D apagado
	UCSR0B = 0x00; //Apagar PD1 y PD0
	
	
}

void initADC()
{
	//Borrar ADMUX
	ADMUX = 0;
	//Vref = AVccM Just, a la isq; ADC = ADC6. 
	ADMUX | = (1<<REFS0) | (1<<ADLAR) | (1<<MUX2) | (1<<MUX1);
	
	//Borrar ADCSRA
	ADCSRA = 0;
	// Habilitar ADC
	ADCSRA | = (1<<ADEN) | (1<<ADPS1) | (1<<ADPS0);
	
}
/****************************************/
// Interrupt routines
ISR(ADC_vect)
{
	PORTD = ADCH;
	ADCSRA | = (1<<ADSC);
	
}
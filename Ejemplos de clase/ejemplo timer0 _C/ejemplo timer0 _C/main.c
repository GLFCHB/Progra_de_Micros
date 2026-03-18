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
#include <avr/interrupt.h>

#define TCNT0_value 100
uint8_t counter = 0;


/****************************************/
// Function prototypes
void setup();
void initTMR0();


/****************************************/
// Main Function

int main(void)
{
	cli();
	setup();
	//HABILITAR INTERRUPCIÓN POR OVERFLOW DEL TIMER0
	TIMSK0 | = (1<<TOIE0)
	
	//HABILITAR INT. GLOBALES
	sei();
	while(1)
	{
		
	}
	
}

/****************************************/
// NON-Interrupt subroutines
void setup()
{
	//F_CPU = 1MHZ AHORA
	CLKPR = (1<<CLKPCE);
	CLKPR = (1<<CLKPS2);
	
	//CONFIGURAR SALIDAS
	DDRC = 0x0F;
	PORTC = 0x00;
	
	//CONFIGURAR TIMER 0
	initTMR0();
	
}
void initTMR0()
{
	// CONFIGURAR EN MODO NORMAL
	TCCR0A & = ~((1<<WGM01) | (1<<WGM00));
	TCCR0B & = ~(1<<WGM02);
	
	//CONFIGURAR PRESCALER_TMR0 = 64
	TCCR0B & = ~(1<<CS02);
	TCCR0B | = ((1<<CS01) | (1<<CS00));
	
	//INICIAR TCNT0
	TCNT0 = TCNT0_value;
	
	
}
/****************************************/
// Interrupt routines
ISR(TIMER0_OVF_vect)
{
	TCNT0 = TCNT0_value;
	COUNTER++;
	if (counter == 50)
	{
		PORTC++;
		PORTC &= 0x0F;
		counter = 0;
	}
}
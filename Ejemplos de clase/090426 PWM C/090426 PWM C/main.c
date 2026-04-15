/*
 * NombreProgra.c
 *
 * Created: 
 * Author: 
 * Description: 
 */
/****************************************/
// Encabezado (Libraries)
#define F_CPU 16000000
#include <avr/io.h>
#include <util/delay.h>



/****************************************/
// Function prototypes
void setup();
void initPWM0();
void updateDutyCyvle0A(uint8_t ciclo);
void updateDutyCyvle0B(uint8_t ciclo);

/****************************************/
// Main Function
int main(void)
{
	uint8_t duty = 127;
	setup();
	initPWM0();
	while (1)
	{
		updateDutyCyvle0A(duty);
		updateDutyCyvle0B(duty);
		duty++
		_delay_ms(1);
	}
	
}

/****************************************/
// NON-Interrupt subroutines
void setup()
{
	CLKPR	=(1<<CLKPCE);
	CLKPR	=(1<<CLKPS2);
}
void initPWM0()
{
	//Configurar salidas
	DDRD | = (1<<DDD6) | (1<<DDD5);
		
	TCCR0A = 0;
	TCCR0B = 0;
		
	//No invertido OCROA e Invertido OCROB
	TCCR0A |= (1<<COM0A1); //No invertido
	TCCR0A |= (1<<COM0B1) | (1<<COM0B0); //Invertido
		
	TCCR0A |= (1<<WGM01) | (1<<WGM00); // Fast PWM
		
	TCCR0B |= (1<<CS01); //Prescaler = 8
		
		
}
void updateDutyCyvle0A(uint8_t ciclo)
{
	OCR0A = ciclo;
}

void updateDutyCyvle0B(uint8_t ciclo)
{
	OCR0B = ciclo;
}
/****************************************/
// Interrupt routines
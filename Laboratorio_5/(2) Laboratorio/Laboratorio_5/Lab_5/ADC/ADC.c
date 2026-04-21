#include "ADC.h"

void ADC_init(void) {
	ADMUX |= (1<<REFS0);      // VCC como referencia (5V)
	ADMUX &= ~(1<<REFS1);
	ADMUX &= ~(1<<ADLAR);     // Resultado de 10 bits justificado a la derecha
	
	// Prescaler 128 (16MHz/128 = 125kHz)
	ADCSRA |= (1<<ADPS2) | (1<<ADPS1) | (1<<ADPS0);
	ADCSRA |= (1<<ADEN);      // Encender el ADC
}

uint16_t ADC_read(uint8_t canal) {
	ADMUX = (ADMUX & 0xF0) | (canal & 0x0F); // Seleccionar canal limpio
	ADCSRA |= (1<<ADSC);                     // Iniciar conversión
	while((ADCSRA) & (1<<ADSC));             // Esperar a que termine
	return (ADC);
}
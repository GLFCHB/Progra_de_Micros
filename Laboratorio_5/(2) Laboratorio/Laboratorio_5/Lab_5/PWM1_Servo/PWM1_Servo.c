#include "PWM1_Servo.h"

void PWM1_init(void) {
	DDRB |= (1 << DDB1);
	TCCR1A = (1 << COM1A1) | (1 << WGM11);
	TCCR1B = (1 << WGM13) | (1 << WGM12) | (1 << CS11);
	ICR1 = 39999;
	OCR1A = 3000; // Posición inicial segura (centro)
}

void PWM1_update(uint16_t adc_val) {
	// Mapeo lineal: de 0-1023 (ADC) a 1000-4800 (0.5ms a 2.4ms)
	// Esto mapea de 1000 ticks (0.5 ms) a 5000 ticks (2.5 ms)
	OCR1A = 1000 + (uint16_t)((adc_val * 4000UL) / 1023);
}
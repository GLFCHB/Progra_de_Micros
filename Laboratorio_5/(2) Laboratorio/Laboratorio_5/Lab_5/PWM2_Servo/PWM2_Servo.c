#include "PWM2_Servo.h"

void PWM2_init(void) {
	DDRB |= (1 << DDB2);
	TCCR1A |= (1 << COM1B1);
	OCR1B = 3000; // Posición inicial segura (centro)
}

void PWM2_update(uint16_t adc_val) {
	// Mismo mapeo que el servo 1, pero aplicado al registro OCR1B
	// Esto mapea de 1000 ticks (0.5 ms) a 5000 ticks (2.5 ms)
	OCR1B = 1000 + (uint16_t)((adc_val * 4000UL) / 1023);
}
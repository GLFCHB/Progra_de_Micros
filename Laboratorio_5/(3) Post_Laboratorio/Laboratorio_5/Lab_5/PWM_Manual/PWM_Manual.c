#include "PWM_Manual.h"
#include <avr/interrupt.h>

// Variables globales volátiles porque se modifican dentro de la interrupción
volatile uint8_t flag_15ms = 0;       // Bandera para el main
volatile uint8_t manual_pwm_counter = 0; // Contador de 0 a 100 para el PWM 
volatile uint8_t manual_pwm_duty = 0;    // Valor seteado por el potenciómetro (0-100)
volatile uint16_t tick_counter = 0;      // Contador para medir los 15ms

void PWM_Manual_init(void) {
    DDRD |= (1 << DDD6);     // Pin PD6 (LED) como salida
    PORTD &= ~(1 << PORTD6); // Iniciamos con el LED apagado

    //Configuración Timer 0 en Modo CTC
    TCCR0A = (1 << WGM01); // Modo CTC (Top en OCR0A)
    TCCR0B = (1 << CS01) | (1 << CS00); // Prescaler de 64
    
    /* Cálculo del TOP (OCR0A):
       f_int = f_cpu / (Prescaler * (1 + OCR0A))
       10000 Hz = 16000000 / (64 * (1 + OCR0A))
       OCR0A = 24 
	   */
    OCR0A = 24; 

    // Habilitamos la interrupción por Compare Match A
    TIMSK0 |= (1 << OCIE0A); 
}

void PWM_Manual_update(uint16_t adc_val) {
    // Mapeamos el valor del ADC (0-1023) a porcentaje (0-100)
    manual_pwm_duty = (uint8_t)((adc_val * 100UL) / 1023);
}

//RUTINA DE INTERRUPCIÓN (Se ejecuta cada 100 microsegundos)
ISR(TIMER0_COMPA_vect) {
    
    // 1. Lógica del PWM Manual pedida en el Post-Lab
    manual_pwm_counter++; // Aumenta el contador
    
    if (manual_pwm_counter >= 100) {
        manual_pwm_counter = 0; // Reinicia el ciclo
        if (manual_pwm_duty > 0) {
            PORTD |= (1 << PORTD6); // Contador en cero -> Salida en alto 
        }
    }
    
    if (manual_pwm_counter >= manual_pwm_duty) {
        PORTD &= ~(1 << PORTD6); // Alcanza el valor seteado -> Salida en cero 
    }

    // 2. Lógica del Delay de 15ms
    tick_counter++;
    if (tick_counter >= 150) {   // 150 ticks de 100 us = 15,000 us = 15 ms
        tick_counter = 0;
        flag_15ms = 1;           // Le pasamos la estafeta al main
    }
}
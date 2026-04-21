/*
 * Archivo: main.c
 * Autor: Luis Fernando
 * Descripción: Lab 5 - PWM y Librerías
 * - Timer 1: Hardware PWM para Servos 1 y 2.
 */

#define F_CPU 16000000UL
#include <avr/io.h>
#include <util/delay.h>

// Librerías de los módulos
#include "ADC/ADC.h"
#include "PWM1_Servo/PWM1_Servo.h"
#include "PWM2_Servo/PWM2_Servo.h"

int main(void)
{
    // 1. Inicialización
    ADC_init();             
    PWM1_init();            
    PWM2_init();            

    // 2. Loop principal
    while (1)
    {
        // PRE-LAB: Servo 1
        uint16_t pot1 = ADC_read(0); 
        PWM1_update(pot1);

        // LAB: Servo 2
        uint16_t pot2 = ADC_read(1); 
        PWM2_update(pot2);
        
        // Delay para no saturar las lecturas
        _delay_ms(15);
    }
}
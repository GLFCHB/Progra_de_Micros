/*
 * Archivo: main.c
 * Autor: Luis Fernando
 * Descripción: Lab 5 - PWM y Librerías
 * - Timer 1: Hardware PWM para Servos 1 y 2.
 * - Timer 0: Interrupciones para PWM Manual (LED) 
 */

#define F_CPU 16000000UL
#include <avr/io.h>
#include <avr/interrupt.h>  

// Librerías de los módulos
#include "ADC/ADC.h"
#include "PWM1_Servo/PWM1_Servo.h"
#include "PWM2_Servo/PWM2_Servo.h"
#include "PWM_Manual/PWM_Manual.h"

// Variable externa que se modifica dentro de la interrupción del Timer 0
extern volatile uint8_t flag_15ms; 

int main(void)
{
    // 1. Inicialización
    ADC_init();             
    PWM1_init();            
    PWM2_init();            
    PWM_Manual_init();      

    // 2. Habilitar interrupciones globales
    sei();

    // 3. Loop principal
    while (1)
    {
        // Solo entra a este if() cuando el Timer 0 avisa que pasaron 15ms
        if (flag_15ms == 1) 
        {
            // PRE-LAB: Servo 1
            uint16_t pot1 = ADC_read(0); 
            PWM1_update(pot1);

            // LAB: Servo 2
            uint16_t pot2 = ADC_read(1); 
            PWM2_update(pot2);

            // POST-LAB: PWM Manual (LED)
            uint16_t pot3 = ADC_read(2);   
            PWM_Manual_update(pot3);
            
            // Bajamos la bandera para esperar otros 15ms
            flag_15ms = 0; 
        }
        
    }
}
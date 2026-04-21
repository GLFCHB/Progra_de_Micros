/*
 * Archivo: main.c
 * Autor: Luis Fernando
 * Dispositivo: ATmega328P
 * Descripción: Pre-Lab 5 - Lectura de ADC y control de un Servomotor
 */

#define F_CPU 16000000UL    // Frecuencia del oscilador a 16MHz
#include <util/delay.h>     // Librería para utilizar retardos
#include <avr/io.h>         // Entradas y salidas del AVR
#include "ServoControl/ServoControl.h"  // Librería para control de servos (Timer 1)
#include "PWM0/PWM0.h"                  // Librería de PWM para

float adcValue = 0;         // Variable  para almacenar la lectura del ADC

//Prototipos de funciones
void ADC_init(void);
uint16_t adcRead(uint8_t canal);

int main(void)
{
    // Inicialización de módulos
    ADC_init();             // Configura los registros del ADC
    PWM_init();             // Configura el Timer 1 para la señal PWM del servo
    
    while (1)
    {
        // Se lee el canal 1 (A1). La máscara 0xFFF8 elimina el ruido de los últimos 3 bits
        adcValue = adcRead(1) & 0xFFF8;
        
        // Se actualiza el ciclo de trabajo del servo según la lectura filtrada
        servo_writeA(adcValue);
        
        // Retardo para darle tiempo mecánico al servo de moverse
        _delay_ms(15);
    }
}

// Implementación de funciones 

void ADC_init(void) {
    ADMUX |= (1<<REFS0);      // Selecciona AVCC (5V) como voltaje de referencia
    ADMUX &= ~(1<<REFS1);     
    ADMUX &= ~(1<<ADLAR);     // Justificación a la derecha (los 10 bits completos en ADC)
    
    // Configura el Prescaler a 128 (16MHz / 128 = 125kHz)
    ADCSRA |= (1<<ADPS2)|(1<<ADPS1)|(1<<ADPS0);
    ADCSRA |= (1<<ADEN);      // Habilita el módulo ADC
}

uint16_t adcRead(uint8_t canal) {
    // Aplica máscara para limpiar los bits de canal (MUX3:0) y asigna el canal deseado
    ADMUX = (ADMUX & 0xF0) | canal;   
    
    ADCSRA |= (1<<ADSC);              // Inicia una nueva conversión
    
    while((ADCSRA)&(1<<ADSC));        // Bucle de espera mientras la conversión termina
    
    return(ADC);                      // Retorna el registro de datos ADC (10 bits)
}
/*
 * Prelab4.c
 *
 * Created: 01/04/2026
 * Author: Luis Chacón
 * Description: Contador binario de 8 bits 
 */

/****************************************/
// Encabezado (Libraries)
#define F_CPU 16000000UL
#include <avr/io.h>
#include <avr/interrupt.h>

/****************************************/
// Variables Globales
volatile uint8_t flag_timer = 0; // Bandera del Timer
uint8_t contador = 0;

// Variables para recordar cómo estaban los botones hace 16ms
uint8_t estado_ant_B1 = 0;
uint8_t estado_ant_B2 = 0;

/****************************************/
// Function prototypes
void setup(void);
void initTMR0(void);

/****************************************/
// Main Function
int main(void)
{
    cli();       // Deshabilitar interrupciones para configurar
    setup();
    initTMR0();
    sei();       // Habilitar interrupciones globales

    while(1)
    {
        // Se ejecuta aprox. cada 16ms
        if (flag_timer == 1) 
        {
            flag_timer = 0; // Bajamos la bandera hasta la próxima interrupción

            // Leer estado actual de los botones (1 = presionado, 0 = suelto)
            // Se usa la negación (!) porque los pull-up dan 0 al presionar
            uint8_t estado_act_B1 = !(PINB & (1 << PINB0));
            uint8_t estado_act_B2 = !(PINB & (1 << PINB1));

            // DETECCIÓN DE FLANCO: Botón 1 (Incrementar)
            // ¿Está presionado AHORA, pero ANTES estaba suelto?
            if (estado_act_B1 == 1 && estado_ant_B1 == 0) 
            {
                contador++;
                PORTD = contador;
            }

            // DETECCIÓN DE FLANCO: Botón 2 (Decrementar)
            if (estado_act_B2 == 1 && estado_ant_B2 == 0) 
            {
                contador--;
                PORTD = contador;
            }

            // Actualizamos la memoria para el próximo ciclo
            estado_ant_B1 = estado_act_B1;
            estado_ant_B2 = estado_act_B2;
        }
    }
}

/****************************************/
// NON-Interrupt subroutines
void setup(void)
{
	// APAGAR EL UART PARA PODER USAR PD0 Y PD1 COMO LEDS
	UCSR0B = 0x00;

	// Configurar PORTD como salida
	DDRD = 0xFF;
	PORTD = 0x00;
	
	// Configurar PB0 y PB1 como entradas
	DDRB &= ~((1 << DDB0) | (1 << DDB1));
	// Activar resistencias pull-up internas
	PORTB |= (1 << PORTB0) | (1 << PORTB1);
}
void initTMR0(void)
{
    // Configurar Timer0 en modo normal
    TCCR0A = 0x00; 
    // Prescaler 1024: (16MHz / 1024 / 256) = ~61 Hz = 16.3ms
    TCCR0B = (1 << CS02) | (1 << CS00);
    // Habilitar interrupción por Overflow
    TIMSK0 |= (1 << TOIE0); 
}

/****************************************/
// Interrupt routines
ISR(TIMER0_OVF_vect)
{
    // Solo levantamos la bandera
    flag_timer = 1; 
}
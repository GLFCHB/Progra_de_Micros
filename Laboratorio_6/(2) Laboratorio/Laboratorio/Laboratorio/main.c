/*
 * Lab6.c
 * Author: Luis Chacón
 */

#include <avr/io.h>
#include <avr/interrupt.h>

// Prototipos de funciones
void initUART(void);
void WriteChar(char c);
void cadena(char txt[]);

int main(void)
{
    // Configurar pines PD2-PD7 y PB0-PB1 como salida para los LEDs del prelab
    DDRD |= 0xFC; 
    DDRB |= 0x03; 
    
    // Inicializar el módulo USART
    initUART();
    
    // Habilitar interrupciones globales para que funcione la recepción
    sei();
    
    // Texto al inicio
    cadena("Elige una opción: \r\n");
    cadena("1. Leer Potenciómetro \r\n");
	cadena("2. Enviar ASCII \r\n");
    
    while(1)
    {
        // Loop infinito vacío. Todo el trabajo se hace en la interrupción.
    }
}

void initUART(void)
{
    // Configurar pines de comunicación
    DDRD &= ~(1 << DDD0); // D0 = RX -> Entrada
    DDRD |= (1 << DDD1);  // D1 = TX -> Salida
    
    UCSR0A = 0;
    
    // Habilitar TX, RX y la interrupción de recepción (RXCIE0)
    UCSR0B = (1 << RXCIE0) | (1 << RXEN0) | (1 << TXEN0); 
    
    // Modo asíncrono, sin paridad, 1 stop bit, 8 data bits
    UCSR0C = (1 << UCSZ01) | (1 << UCSZ00);
    
    // UBRR0 a 103 para 9600 baudios con Fosc de 16MHz
    UBRR0 = 103; 
}

void WriteChar(char c)
{
    // Esperar a que la bandera UDRE0 indique que el buffer está listo
    while(!(UCSR0A & (1 << UDRE0)));
    UDR0 = c; 
}

//  Laboratorio 
void cadena(char txt[])
{
    for(uint8_t i = 0; txt[i] != '\0'; i++)
    {
        WriteChar(txt[i]);
    }
}

// Interrupción del prelab: Recibir caracter y mostrarlo en LEDs
ISR(USART_RX_vect)
{
    uint8_t bufferRX = UDR0;
    
    
    WriteChar(bufferRX);
    
    // Mostrar el valor ASCII en los LEDs (PD7-PD2 y PB1-PB0)
    PORTD = (PORTD & 0x03) | (bufferRX & 0xFC);
    PORTB = (PORTB & 0xFC) | (bufferRX & 0x03); 
}
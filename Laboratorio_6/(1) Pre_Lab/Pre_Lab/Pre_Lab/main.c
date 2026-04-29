/*
 * Prelab6.c
 * Author: Luis Chacón
 */

#include <avr/io.h>
#include <avr/interrupt.h>

void initUART(void);
void WriteChar(char c);

int main(void)
{
    // Configurar pines PD2-PD7 y PB0-PB1 como salida para los LEDs
    DDRD |= 0xFC; 
    DDRB |= 0x03; 
    
    initUART();
    
    sei(); // Habilitar interrupciones globales
    
    //PARTE 1: Enviar un caracter hacia la computadora
    WriteChar('X'); // Manda una X apenas arranca
    
    while(1)
    {
        // No hay nada en el loop principal. 
    }
}

void initUART(void)
{
    DDRD &= ~(1 << DDD0); // RX Entrada
    DDRD |= (1 << DDD1);  // TX Salida
    
    UCSR0A = 0;
    // Habilitar TX, RX y la interrupción de recepción
    UCSR0B = (1 << RXCIE0) | (1 << RXEN0) | (1 << TXEN0);
    // Modo async, 1 stop bit, 8 data bits
    UCSR0C = (1 << UCSZ01) | (1 << UCSZ00);
    // 9600 baudios a 16MHz
    UBRR0 = 103; 
}

void WriteChar(char c)
{
    while(!(UCSR0A & (1 << UDRE0)));
    UDR0 = c;
}

//PARTE 2: Recibir caracter y mostrarlo
ISR(USART_RX_vect)
{
    uint8_t bufferRX = UDR0;
    
   
    WriteChar(bufferRX);
    
    // Mostrar el valor ASCII en los LEDs (PD2-PD7 y PB0-PB1)
    PORTD = (PORTD & 0x03) | (bufferRX & 0xFC);
    PORTB = (PORTB & 0xFC) | (bufferRX & 0x03);
}
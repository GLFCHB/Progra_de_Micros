/*
 * PostLab6.c
 * Author: Luis Chacón
 */

#include <avr/io.h>
#include <stdlib.h>
#include "ADC.h" 

// Prototipos
void initUART(void);
void WriteChar(char c);
char ReadChar(void); 
void cadena(char txt[]);

int main(void)
{
    // Configurar LEDs (PD2-PD7 y PB0-PB1)
    DDRD |= 0xFC;
    DDRB |= 0x03;

    initUART();
    ADC_init(); // Inicializar ADC 

    char buffer[10];
    char opcion;

    while(1)
    {
        // 1. Mostrar el menú en la terminal
        cadena("\r\n--- MENU ---\r\n");
        cadena("1. Leer Potenciometro\r\n");
        cadena("2. Enviar Ascii\r\n");
        cadena("Elige una opcion: ");

        // 2. Esperar a que el usuario presione una tecla
        opcion = ReadChar();
        WriteChar(opcion);
        cadena("\r\n");

        // 3. Evaluar la opción
        if (opcion == '1')
        {
            // Leer el pot usando tu función (canal 0 = A0)
            uint16_t valor_pot = ADC_read(0);

            // Forzar los extremos si entras a la zona muerta
            if (valor_pot < 40) valor_pot = 0;
            if (valor_pot > 900) valor_pot = 1023;

            // Convertir el número (que ahora es de 10 bits) a texto
            itoa(valor_pot, buffer, 10);
            cadena("Valor ADC (0-1023): ");
            cadena(buffer);
            cadena("\r\n");
        }
        else if (opcion == '2')
        {
            cadena("Escribe el caracter para los LEDs: ");
            char letra = ReadChar();
            WriteChar(letra); 
            cadena("\r\n");

            // Mostrar en LEDs (MSB en PD7, LSB en PB0)
            PORTD = (PORTD & 0x03) | (letra & 0xFC);
            PORTB = (PORTB & 0xFC) | (letra & 0x03);
        }
        else
        {
            cadena("Opcion no valida. Intenta de nuevo.\r\n");
        }
    }
}

void initUART(void)
{
    DDRD &= ~(1 << DDD0); // RX
    DDRD |= (1 << DDD1);  // TX

    UCSR0A = 0;
    
    UCSR0B = (1 << RXEN0) | (1 << TXEN0);
    
    // Modo asíncrono, 1 stop bit, 8 data bits
    UCSR0C = (1 << UCSZ01) | (1 << UCSZ00);
    
    // 9600 baudios a 16MHz
    UBRR0 = 103; 
}

void WriteChar(char c)
{
    while(!(UCSR0A & (1 << UDRE0)));
    UDR0 = c;
}

// Función para leer un caracter de la terminal (se queda esperando)
char ReadChar(void)
{
    // Esperar a que la bandera RXC0 indique que hay un dato no leído
    while(!(UCSR0A & (1 << RXC0)));
    return UDR0;
}

void cadena(char txt[])
{
    for(uint8_t i = 0; txt[i] != '\0'; i++)
    {
        WriteChar(txt[i]);
    }
}
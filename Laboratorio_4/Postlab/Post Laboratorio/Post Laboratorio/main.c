/*
 * Laboratorio 4.c
 * Author: Luis Chacón
 * Description: Contador 8 bits, ADC en Hexadecimal (00-FF) y Match LED
 */

#include <avr/io.h>      
#include <avr/interrupt.h> 

// Tabla de 7 segmentos (Cátodo Común) para los números 0-F
const uint8_t display[16] = {
    0x3F, 
	0x06, 
	0x5B, 
	0x4F, 
    0x66, 
	0x6D, 
	0x7D, 
	0x07, 
    0x7F, 
	0x6F, 
	0x77, 
	0x7C, 
    0x39, 
	0x5E, 
	0x79, 
	0x71  
};

// Variables 
volatile uint8_t display_actual = 0; // Alterna entre 0 (decenas) y 1 (unidades)
volatile uint8_t decenas = 0;  // Almacenará los 4 bits más significativos del ADC
volatile uint8_t unidades = 0; // Almacenará los 4 bits menos significativos del ADC

volatile uint8_t flag_timer = 0; // Bandera que se levanta cada 16ms para los botones
volatile uint8_t tick_botones = 0; // Contador interno para llegar a los 16ms

volatile uint8_t flag_adc = 0; // Bandera que se levanta cada 100ms para refrescar el ADC
volatile uint8_t tick_adc = 0; // Contador interno para llegar a los 100ms

uint8_t contador_leds = 0; // Variable principal del contador de 8 bits

// Variables para el detector de flanco (antirrebote)
uint8_t estado_ant_B1 = 0;
uint8_t estado_ant_B2 = 0;

// Prototipos 
void setup(void);
void initADC(void);
void initTMR0(void);
uint8_t leerADC(void);
void mostrar_numero(uint8_t num);

int main(void)
{
    cli(); // Apaga interrupciones globales mientras configuramos
    setup(); // Configura pines de entrada/salida
    initADC(); // Configura el convertidor análogo a digital
    initTMR0(); // Configura el timer 0 para el multiplexado y tiempos
    sei(); // Enciende las interrupciones globales

    while(1) // Loop infinito
    {

        // LÓGICA DE BOTONES Y CONTADOR (Se ejecuta cada 16ms)
        if (flag_timer == 1) 
        {
            flag_timer = 0; // Bajamos la bandera para esperar otros 16ms
            
            // Leemos el estado actual de los pines. Usamos '!' porque el pull-up da 0 al presionar.
            uint8_t estado_act_B1 = !(PINB & (1 << PINB0));
            uint8_t estado_act_B2 = !(PINB & (1 << PINB1));

            // Detección de flanco positivo: Solo suma si AHORA está presionado y ANTES estaba suelto
            if (estado_act_B1 == 1 && estado_ant_B1 == 0) {
                contador_leds++;
                PORTD = contador_leds; // Actualizamos los LEDs del puerto D
            }

            // Detección de flanco negativo
            if (estado_act_B2 == 1 && estado_ant_B2 == 0) {
                contador_leds--;
                PORTD = contador_leds;
            }

            // Guardamos el estado actual para la siguiente pasada
            estado_ant_B1 = estado_act_B1;
            estado_ant_B2 = estado_act_B2;
        }

        // LÓGICA DEL ADC (Se ejecuta cada 100ms para evitar parpadeos visuales)
        if (flag_adc == 1)
        {
            flag_adc = 0; // Bajamos la bandera
            
            uint16_t suma_adc = 0;
            
            // Filtro de promedio: Leemos 16 veces rapidísimo y sumamos
            for(uint8_t i = 0; i < 16; i++) {
                suma_adc += leerADC();
            }
            // Sacamos la media para eliminar el ruido eléctrico
            uint8_t valor_promedio = suma_adc / 16;
			
			static uint8_t promedio_anterior = 0; // Guarda el valor de la vez pasada
			
			// Calculamos cuánto cambió la lectura
			int16_t diferencia = (int16_t)valor_promedio - (int16_t)promedio_anterior;
			
			// Si el cambio es mayor a 2 (hacia arriba o hacia abajo), sí actualizamos
			if (diferencia > 2 || diferencia < -2) {
				promedio_anterior = valor_promedio;
				} else {
				// Si el cambio es mínimo , forzamos a que use el valor viejo
				valor_promedio = promedio_anterior;
			}

            // Ponemos un límite inferior y superior para asegurarnos que vaya desde 00 hasta FF.
            uint8_t min_pot = 0x1A; // Límite inferior 
            uint8_t max_pot = 0xC0; // Límite superior
            uint8_t valor_calibrado = 0;

            // Mapeo/Calibración para estirar el valor defectuoso a un rango perfecto de 0 a 255
            if (valor_promedio <= min_pot) {
                valor_calibrado = 0x00; // Forzar a cero absoluto
            } 
            else if (valor_promedio >= max_pot) {
                valor_calibrado = 0xFF; // Forzar a tope absoluto
            } 
            else {
                // Ecuación de la recta (y = mx + b) adaptada para enteros de 8 bits
                valor_calibrado = (uint8_t)( ((uint32_t)(valor_promedio - min_pot) * 255) / (max_pot - min_pot) );
            }
            
            // Movemos los 4 bits de la izquierda a la derecha para sacar el dígito alto
            decenas = (valor_calibrado >> 4); 
            // Usamos una máscara 00001111 para borrar lo de la izquierda y quedarnos con el dígito bajo
            unidades = (valor_calibrado & 0x0F); 
            
            // LÓGICA DEL POSTLAB
            if (valor_calibrado == contador_leds) {
                PORTC |= (1 << PORTC0); // SET: Encender LED en A0 (PC0) si hacen match
            } else {
                PORTC &= ~(1 << PORTC0); // CLEAR: Apagar LED si son diferentes
            }
        }
    }
}
// SUBRUTINAS DE CONFIGURACIÓN 

void setup(void)
{
    UCSR0B = 0x00; // Deshabilita RX y TX (UART) para poder usar PD0 y PD1 como salidas normales
    
    // Configuración del Puerto D (LEDs del contador)
    DDRD = 0xFF;   // 11111111 -> Todo el puerto D como salida
    PORTD = 0x00;  // Inician apagados
    
    // Configuración de los botones en PB0 y PB1
    DDRB &= ~((1 << DDB0) | (1 << DDB1)); // 0 en dirección -> Entradas
    PORTB |= (1 << PORTB0) | (1 << PORTB1); // 1 en puerto (siendo entradas) -> Activa Pull-up interno
    
    // Configuración de los transistores de multiplexado en PB4 y PB5
    DDRB |= (1 << DDB4) | (1 << DDB5); // 1 -> Salidas
    PORTB &= ~((1 << PORTB4) | (1 << PORTB5)); // 0 -> Inician apagados

    // Configuración de pines para el display de 7 segmentos (a-e en PC1-PC5)
    DDRC |= (1<<DDC1) | (1<<DDC2) | (1<<DDC3) | (1<<DDC4) | (1<<DDC5);
    PORTC &= ~((1<<PORTC1) | (1<<PORTC2) | (1<<PORTC3) | (1<<PORTC4) | (1<<PORTC5));
    // Configuración de pines para el display de 7 segmentos (f-g en PB2-PB3)
    DDRB |= (1<<DDB2) | (1<<DDB3);
    PORTB &= ~((1<<PORTB2) | (1<<PORTB3));
    
    // Configuración del LED del Postlab en A0 (PC0)
    DDRC |= (1 << DDC0); // 1 -> Salida
    PORTC &= ~(1 << PORTC0); // 0 -> Apagado
}

void initADC(void)
{
    // REFS0 = 1: Voltaje de referencia de 5V 
    // ADLAR = 1: Justificar a la izquierda
    // MUX2=1, MUX1=1: Selecciona el canal analógico ADC6 (pin A6).
    ADMUX = (1 << REFS0) | (1 << ADLAR) | (1 << MUX2) | (1 << MUX1); 
    
    // ADEN = 1: Enciende el módulo ADC.
    // ADPS2=1, ADPS1=1, ADPS0=1: Prescaler en 128 (16MHz / 128 = 125kHz).
    ADCSRA = (1 << ADEN) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0);
}

void initTMR0(void)
{
    TCCR0A = 0x00; // Modo de operación normal
    // CS01=1, CS00=1: Prescaler a 64. Con un reloj de 16MHz y registro de 8 bits, overflow cada 1.024 ms.
    TCCR0B = (1 << CS01) | (1 << CS00);
    // TOIE0 = 1: Habilita la interrupción por overflow del Timer 0.
    TIMSK0 |= (1 << TOIE0); 
}

uint8_t leerADC(void)
{
    ADCSRA |= (1 << ADSC); // SET: Escribir un 1 en ADSC inicia la conversión analógica.
    while (ADCSRA & (1 << ADSC)); // Ciclo de espera: El micro se queda atascado aquí mientras ADSC siga siendo 1.
    return ADCH; // Retorna los 8 bits superiores del resultado.
}

void mostrar_numero(uint8_t num) {
    // Primero, CLEAR a todos los segmentos para evitar sombras o valores fantasma del dígito anterior
    PORTC &= ~((1<<PORTC1) | (1<<PORTC2) | (1<<PORTC3) | (1<<PORTC4) | (1<<PORTC5));
    PORTB &= ~((1<<PORTB2) | (1<<PORTB3));

    // Carga el patrón de bits desde el arreglo según el número solicitado
    uint8_t bits = display[num];

    // Se evalúa bit por bit usando AND lógico. Si el bit es 1, se enciende el segmento correspondiente.
    if(bits & 0x01) PORTC |= (1<<PORTC1); // Segmento 'a'
    if(bits & 0x02) PORTC |= (1<<PORTC2); // Segmento 'b'
    if(bits & 0x04) PORTC |= (1<<PORTC3); // Segmento 'c'
    if(bits & 0x08) PORTC |= (1<<PORTC4); // Segmento 'd'
    if(bits & 0x10) PORTC |= (1<<PORTC5); // Segmento 'e'
    if(bits & 0x20) PORTB |= (1<<PORTB2); // Segmento 'f'
    if(bits & 0x40) PORTB |= (1<<PORTB3); // Segmento 'g'
}

// RUTINAS DE INTERRUPCIÓN (ISR)

// Esta interrupción se ejecuta cada vez que el Timer0 tiene overflow (aprox. cada 1 milisegundo)
ISR(TIMER0_OVF_vect)
{
    // Apagamos ambos transistores de multiplexado
    PORTB &= ~((1 << PORTB4) | (1 << PORTB5)); 
    
    // Multiplexado rápido: Solo se enciende un display a la vez.
    if (display_actual == 0) {
        mostrar_numero(decenas); // Carga la forma del dígito en los pines
        PORTB |= (1 << PORTB5); // SET: Enciende el transistor del dígito izquierdo
        display_actual = 1; // Cambia de turno
    } else {
        mostrar_numero(unidades);
        PORTB |= (1 << PORTB4); // SET: Enciende el transistor del dígito derecho
        display_actual = 0;
    }

    // Como la interrupción ocurre cada 1ms, usamos contadores para medir tiempos más grandes
    tick_botones++;
    if (tick_botones >= 16) { 
        flag_timer = 1; // Levanta la bandera para leer botones (antirrebote de 16ms)
        tick_botones = 0;
    }

    tick_adc++;
    if (tick_adc >= 100) {
        flag_adc = 1; // Levanta la bandera para actualizar la lectura del potenciómetro cada 100ms
        tick_adc = 0;
    }
}
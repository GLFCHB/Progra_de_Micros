/*
* postlab_3.asm
*
* Creado: 24/02/2026
* Autor : Luis Fernando Chacón - 241193
* Descripción: Contador binario con botones, y contador de 0-59.
*              Reset a 60 segundos.
*/
/****************************************/
// Encabezado (Definición de Registros, Variables y Constantes)
.include "M328PDEF.inc"     // Include definitions specific to ATMega328P
.dseg
.org    SRAM_START
//variable_name:     .byte   1   // Memory alocation for variable_name:     .byte   (byte size)

.cseg
.org 0x0000

/****************************************/
// Vectores de interrupción
RJMP    SETUP               // Reset vector
.org 0x0006
RJMP    ISR_PCINT1          // Vector PCINT1 (PC0, PC1 - botones)
.org 0x0020
RJMP    ISR_TIMER0_OVF      // Vector Timer0 Overflow

/****************************************/
// Tabla de display de 7 segmentos (cátodo común -> activo = 1)
T7SEG:
    .db 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F, 0x77, 0x7C, 0x39, 0x5E, 0x79, 0x71

/****************************************/
// Configuración de la pila
LDI     R16, LOW(RAMEND)
OUT     SPL, R16
LDI     R16, HIGH(RAMEND)
OUT     SPH, R16

/****************************************/
// Habilita los pines PD0 y PD1
LDI R16, 0x00
STS UCSR0B, R16

/****************************************/
// Configuracion MCU
SETUP:
    // Configurar reloj a 1MHz
    LDI R16, (1 << CLKPCE)
    STS CLKPR, R16
    LDI R16, 0b00000100     // Divisor 16 -> 16MHz/16 = 1MHz
    STS CLKPR, R16

    // Configuración Timer0
    // Prescaler 1024 -> tick cada 1.024ms
    // TCNT0 arranca en 246 -> overflow cada 10 ticks = 10.24ms
    LDI R16, (1 << CS02) | (1 << CS00)     // Prescaler 1024
    OUT TCCR0B, R16
    LDI R16, 246
    OUT TCNT0, R16

    // Habilitar interrupción overflow Timer0
    LDI R16, (1 << TOIE0)
    STS TIMSK0, R16

    // PUERTO B
    // DDR: 0 entrada, 1 salida
    LDI R16, 0b00111111     // PB0-PB3 salida (LEDs), PB4-PB5 salida (transistores displays)
    OUT DDRB, R16
    // PORT: Si salida (0 low, 1 high)
    LDI R16, 0b00010000     // LEDs apagados, PB4=1 (transistor unidades activo), PB5=0
    OUT PORTB, R16

    // PUERTO C
    // DDR: 0 entrada, 1 salida
    LDI R16, 0b00000000     // PC0-PC1 entrada (botones)
    OUT DDRC, R16
    // PORT: Si entrada (0 sin pull-up, 1 con pull-up)
    LDI R16, 0b00000011     // PC0 y PC1 con pull-up interno
    OUT PORTC, R16

    // PUERTO D
    // DDR: 0 entrada, 1 salida
    LDI R16, 0b01111111     // PD0-PD6 salida (segmentos a-g del display)
    OUT DDRD, R16
    // PORT: Si salida (0 low, 1 high)
    LDI R16, 0b00000000     // Display apagado al inicio
    OUT PORTD, R16

    // Habilitar Pin Change Interrupt para PCINT1 (Puerto C)
    LDI R16, (1 << PCIE1)
    STS PCICR, R16
    // Habilitar solo PC0 y PC1
    LDI R16, (1 << PCINT8) | (1 << PCINT9)
    STS PCMSK1, R16

    // Registros con rol fijo
    LDI R20, 0              // Contador de overflows (97 overflows = ~1s)
    LDI R21, 0              // Contador de unidades de segundo (0-9)
    LDI R22, 0              // Contador de decenas de segundo (0-5)
    LDI R23, 0              // Contador binario 4-bit (controlado por botones)
    LDI R24, 0              // Dígito activo del display (0=unidades, 1=decenas)
    LDI R25, 0b00000011     // Estado anterior de botones (pull-up = 1 = no presionado)

    // Mostrar valor inicial en displays
    CALL ACTUALIZAR_DISPLAY_UNIDADES

    // Habilitar interrupciones globales
    SEI

/****************************************/
// Loop Infinito
MAIN_LOOP:
    RJMP    MAIN_LOOP

/****************************************/
// NON-Interrupt subroutines

// Mostrar unidades de segundo (R21) en Puerto D
ACTUALIZAR_DISPLAY_UNIDADES:
    PUSH R16
    PUSH ZL
    PUSH ZH

    LDI ZL, LOW(T7SEG << 1)
    LDI ZH, HIGH(T7SEG << 1)
    ADD ZL, R21
    LDI R16, 0
    ADC ZH, R16
    LPM R16, Z
    OUT PORTD, R16

    POP ZH
    POP ZL
    POP R16
    RET

// Mostrar decenas de segundo (R22) en Puerto D
ACTUALIZAR_DISPLAY_DECENAS:
    PUSH R16
    PUSH ZL
    PUSH ZH

    LDI ZL, LOW(T7SEG << 1)
    LDI ZH, HIGH(T7SEG << 1)
    ADD ZL, R22
    LDI R16, 0
    ADC ZH, R16
    LPM R16, Z
    OUT PORTD, R16

    POP ZH
    POP ZL
    POP R16
    RET

// Actualizar LEDs con el valor del contador binario (R23)
// Preserva PB4 y PB5 (transistores display)
ACTUALIZAR_LEDS:
    PUSH R16
    PUSH R17
    MOV R17, R23
    ANDI R17, 0x0F
    IN R16, PORTB
    ANDI R16, 0b11110000    // Conservar PB4-PB5, limpiar PB0-PB3
    OR R16, R17
    OUT PORTB, R16
    POP R17
    POP R16
    RET

/****************************************/
// Interrupt routines

// ISR: Timer0 Overflow (10.24ms)
ISR_TIMER0_OVF:
    PUSH R16
    IN R16, SREG
    PUSH R16

    // Recargar timer
    LDI R16, 246
    OUT TCNT0, R16

    // Multiplexeo del display: alternar dígito activo
    INC R24
    ANDI R24, 0x01

    SBRC R24, 0
    RJMP MOSTRAR_DECENAS

    // Mostrar unidades: apagar PB5, encender PB4
    CBI PORTB, 5
    CALL ACTUALIZAR_DISPLAY_UNIDADES
    SBI PORTB, 4
    RJMP CONTAR_TIEMPO

MOSTRAR_DECENAS:
    // Mostrar decenas: apagar PB4, encender PB5
    CBI PORTB, 4
    CALL ACTUALIZAR_DISPLAY_DECENAS
    SBI PORTB, 5

CONTAR_TIEMPO:
    // 97 overflows x 10.24ms = ~993ms
    INC R20
    CPI R20, 97
    BRNE FIN_ISR_TIMER0
    CLR R20

    // Incrementar unidades de segundo
    INC R21
    CPI R21, 10
    BRNE FIN_ISR_TIMER0

    // Unidades llegaron a 10 -> resetear e incrementar decenas
    CLR R21
    INC R22

    // Verificar si llegamos a 60 segundos (decenas = 6)
    CPI R22, 6
    BRNE FIN_ISR_TIMER0

    // Reset completo a 0
    CLR R22

FIN_ISR_TIMER0:
    POP R16
    OUT SREG, R16
    POP R16
    RETI

// ISR: Pin Change Interrupt 1 (botones en PC0 y PC1)
ISR_PCINT1:
    PUSH R16
    IN R16, SREG
    PUSH R16

    IN R16, PINC            // Leer estado actual de los botones

    // Revisar PC0 (incrementar)
    SBRC R16, 0             // Si PC0 actual es 1 (suelto), saltar
    RJMP CHECK_PC1_BTN
    SBRS R25, 0             // Si PC0 anterior era 0 (ya presionado), saltar
    RJMP CHECK_PC1_BTN
    INC R23
    ANDI R23, 0x0F

CHECK_PC1_BTN:
    // Revisar PC1 (decrementar)
    SBRC R16, 1             // Si PC1 actual es 1 (suelto), saltar
    RJMP FIN_ISR_PCINT1
    SBRS R25, 1             // Si PC1 anterior era 0 (ya presionado), saltar
    RJMP FIN_ISR_PCINT1
    DEC R23
    ANDI R23, 0x0F

FIN_ISR_PCINT1:
    MOV R25, R16            // Guardar estado actual como anterior
    CALL ACTUALIZAR_LEDS
    POP R16
    OUT SREG, R16
    POP R16
    RETI

/****************************************/
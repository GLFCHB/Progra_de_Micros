/*
* prelab_3.asm
*
* Creado: 24/02/2026
* Autor : Luis Fernando Chacón - 241193
* Descripción: Contador binario de 4 bits con dos pushbuttons y cuatro LEDs.
*              PC0 incrementa, PC1 decrementa. Interrupciones on-change (PCINT1).
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
.org 0x000A
RJMP    ISR_PCINT1          // Vector PCINT1 (PC0, PC1 - botones)

/****************************************/
// Configuración de la pila
LDI     R16, LOW(RAMEND)
OUT     SPL, R16
LDI     R16, HIGH(RAMEND)
OUT     SPH, R16

/****************************************/
// Configuracion MCU
SETUP:
    // PUERTO B
    // DDR: 0 entrada, 1 salida
    LDI R16, 0b00001111     // PB0-PB3 salida (LEDs)
    OUT DDRB, R16
    // PORT: Si salida (0 low, 1 high)
    LDI R16, 0b00000000     // LEDs apagados
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
    LDI R16, 0b00000000     // Sin uso
    OUT DDRD, R16
    // PORT: Si entrada (0 sin pull-up, 1 con pull-up)
    LDI R16, 0b00000000
    OUT PORTD, R16

    // Habilitar Pin Change Interrupt para PCINT1 (Puerto C)
    LDI R16, (1 << PCIE1)
    STS PCICR, R16
    // Habilitar solo PC0 y PC1
    LDI R16, (1 << PCINT8) | (1 << PCINT9)
    STS PCMSK1, R16

    // Registros con rol fijo
    LDI R23, 0              // Contador binario 4-bit
    IN R25, PINC            // Estado inicial de los botones (para detectar flanco)

    // Habilitar interrupciones globales
    SEI

/****************************************/
// Loop Infinito
// Actualiza los LEDs continuamente con el valor del contador
MAIN_LOOP:
    IN R16, PORTB
    ANDI R16, 0b11110000    // Preservar PB4-PB7
    MOV R17, R23
    ANDI R17, 0x0F          // Asegurar 4 bits
    OR R16, R17
    OUT PORTB, R16
    RJMP    MAIN_LOOP

/****************************************/
// NON-Interrupt subroutines
/****************************************/
// Interrupt routines

// ISR: Pin Change Interrupt 1 (botones en PC0 y PC1)
// Detecta flanco de bajada: pin era 1 (suelto) y ahora es 0 (presionado)
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
    // Flanco detectado en PC0 -> incrementar
    INC R23
    ANDI R23, 0x0F

CHECK_PC1_BTN:
    // Revisar PC1 (decrementar)
    SBRC R16, 1             // Si PC1 actual es 1 (suelto), saltar
    RJMP FIN_ISR_PCINT1
    SBRS R25, 1             // Si PC1 anterior era 0 (ya presionado), saltar
    RJMP FIN_ISR_PCINT1
    // Flanco detectado en PC1 -> decrementar
    DEC R23
    ANDI R23, 0x0F

FIN_ISR_PCINT1:
    MOV R25, R16            // Guardar estado actual como anterior
    POP R16
    OUT SREG, R16
    POP R16
    RETI

/****************************************/
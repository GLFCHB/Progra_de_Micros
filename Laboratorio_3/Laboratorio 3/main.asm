/*
* laboratorio_3.asm
*
* Creado: 24/02/2026
* Autor : Luis Fernando Chacón - 241193
* Descripción: Contador binario de 4 bits con botones (PCINT1) y contador
*              hexadecimal en display 7 segmentos con Timer0. Ambos simultáneos.
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
.org 0x0020
RJMP    ISR_TIMER0_OVF      // Vector Timer0 Overflow

/****************************************/
// Tabla de display de 7 segmentos (cátodo común -> activo = 1)
// PD0-PD6: segmentos a-g
T7SEG:
    .db 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x67, 0x77, 0x7C, 0x39, 0x5E, 0x79, 0x71
//   0     1     2     3     4     5     6     7     8     9     A     B     C     D     E     F

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
    LDI R16, 0b00111111     // PB0-PB3 salida (LEDs), PB4-PB5 salida (transistores display)
    OUT DDRB, R16
    // PORT: Si salida (0 low, 1 high)
    LDI R16, 0b00010000     // LEDs apagados, PB4=1 (transistor display activo)
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

    // Configurar Timer0
    // Prescaler 1024 -> 16MHz / 1024 = 15625 Hz
    // 256 ticks * (1/15625) = ~16.38ms por interrupción
    // Para 1000ms: 1000 / 16.38 = ~61 interrupciones
    LDI R16, (1 << CS02) | (1 << CS00)     // Prescaler 1024
    OUT TCCR0B, R16
    // Habilitar interrupción overflow Timer0
    LDI R16, (1 << TOIE0)
    STS TIMSK0, R16

    // Habilitar Pin Change Interrupt para PCINT1 (Puerto C)
    LDI R16, (1 << PCIE1)
    STS PCICR, R16
    // Habilitar solo PC0 y PC1
    LDI R16, (1 << PCINT8) | (1 << PCINT9)
    STS PCMSK1, R16

    // Registros con rol fijo
    LDI R17, 0              // Contador binario 4-bit (botones -> LEDs)
    LDI R18, 0              // Contador hexadecimal (Timer0 -> display)
    LDI R20, 0              // Contador de interrupciones del Timer0 (para llegar a 1s)
    IN R19, PINC            // Estado inicial de los botones (para detectar flanco)

    // Habilitar interrupciones globales
    SEI

/****************************************/
// Loop Infinito
MAIN_LOOP:
    // Actualizar LEDs con el contador binario (R17)
    IN R16, PORTB
    ANDI R16, 0b11110000    // Preservar PB4-PB7
    MOV R21, R17
    ANDI R21, 0x0F
    OR R16, R21
    OUT PORTB, R16

    // Actualizar display con el contador hexadecimal (R18)
    LDI ZH, HIGH(T7SEG << 1)
    LDI ZL, LOW(T7SEG << 1)
    MOV R21, R18
    ANDI R21, 0x0F
    ADD ZL, R21
    CLR R22
    ADC ZH, R22
    LPM R16, Z
    OUT PORTD, R16

    RJMP    MAIN_LOOP

/****************************************/
// NON-Interrupt subroutines
/****************************************/
// Interrupt routines

// ISR: Timer0 Overflow (~16.38ms)
// Cuenta 61 interrupciones para llegar a ~1 segundo e incrementa el display
ISR_TIMER0_OVF:
    PUSH R16
    IN R16, SREG
    PUSH R16

    INC R20
    CPI R20, 61             // 61 x 16.38ms = ~1000ms
    BRLO FIN_ISR_TIMER0

    CLR R20                 // Reiniciar contador de interrupciones
    INC R18                 // Incrementar contador hexadecimal
    ANDI R18, 0x0F          // Mantener en 4 bits (0-F)

FIN_ISR_TIMER0:
    POP R16
    OUT SREG, R16
    POP R16
    RETI

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
    SBRS R19, 0             // Si PC0 anterior era 0 (ya presionado), saltar
    RJMP CHECK_PC1_BTN
    // Flanco detectado en PC0 -> incrementar
    INC R17
    ANDI R17, 0x0F

CHECK_PC1_BTN:
    // Revisar PC1 (decrementar)
    SBRC R16, 1             // Si PC1 actual es 1 (suelto), saltar
    RJMP FIN_ISR_PCINT1
    SBRS R19, 1             // Si PC1 anterior era 0 (ya presionado), saltar
    RJMP FIN_ISR_PCINT1
    // Flanco detectado en PC1 -> decrementar
    DEC R17
    ANDI R17, 0x0F

FIN_ISR_PCINT1:
    MOV R19, R16            // Guardar estado actual como anterior
    POP R16
    OUT SREG, R16
    POP R16
    RETI

/****************************************/
/*
* contador_completo.asm
*
* Creado: 17/02/2026
* Autor : Luis Chacón
* Descripción: Contador 0-F con display, LED que parpadea según valor del display
*/
/****************************************/
// Encabezado (Definición de Registros, Variables y Constantes)
.include "M328PDEF.inc"
.dseg
.org    SRAM_START

.cseg
.org 0x0000

/****************************************/
// Tabla de display de 7 segmentos (ánodo común -> activo = 0v)
T7SEG: 
    .db 0x40, 0x79, 0x24, 0x30, 0x19, 0x12, 0x02, 0x78, 0x00, 0x10, 0x08, 0x03, 0x46, 0x21, 0x06, 0x0E

/****************************************/
// Configuración de la pila
LDI     R16, LOW(RAMEND)
OUT     SPL, R16
LDI     R16, HIGH(RAMEND)
OUT     SPH, R16

/****************************************/
// Habilita los pines PD0 y PD1
LDI R24, 0x00
STS UCSR0B, R24

/****************************************/
// Configuracion MCU
SETUP:
    // Configurar reloj a 1MHz
    LDI R16, (1 << CLKPCE)
    STS CLKPR, R16
    LDI R16, 0b00000100
    STS CLKPR, R16
    
    // Configurar Timer0 con prescaler 1024 (cada overflow son cada 100ms)
    LDI R16, 5              // Prescaler 1024
    OUT TCCR0B, R16
    LDI R16, 158            // Vamos a empezar a contar desde 158
    OUT TCNT0, R16
    
    // PUERTO B
    // DDR: 0 entrada, 1 salida
    LDI R16, 0b00100000     // B5 salida (LED indicador), B0-B1 entrada (botones)
    OUT DDRB, R16
    // PORT: Si es entrada (0 sin pull-up, 1 con pull-up), Si es salida (0 low, 1 high)
    LDI R16, 0b00000011     // B0-B1 con pull-up, B5 en low
    OUT PORTB, R16
    
    // PUERTO C
    // DDR: 0 entrada, 1 salida
    LDI R16, 0b00001111     // C0-C3 salida (contador binario)
    OUT DDRC, R16
    // PORT: Si es entrada (0 sin pull-up, 1 con pull-up), Si es salida (0 low, 1 high)
    LDI R16, 0b00000000     // Contador en 0
    OUT PORTC, R16
    
    // PUERTO D
    // DDR: 0 entrada, 1 salida
    LDI R16, 0b01111111     // D0-D6 salida (display)
    OUT DDRD, R16
    // PORT: Si es entrada (0 sin pull-up, 1 con pull-up), Si es salida (0 low, 1 high)
    LDI R16, 0b01111111     // Display apagado
    OUT PORTD, R16
    
    // Registros importantes
    LDI R20, 0              // Contador de overflows de 100ms (para llegar a 1s)
    LDI R21, 0              // Contador binario (incrementa cada 1s)
    LDI R22, 0              // Contador de segundos
    LDI R25, 0              // Valor del display (controlado por botones)
    
    // Mostrar valor inicial en display
    CALL ACTUALIZAR_DISPLAY
    
/****************************************/
// Loop Principal
MAIN_LOOP:
    // Actualizar timer y contador
    CALL CHECK_TIMER
    
    // Revisar botones
    CALL CHECK_BOTONES
    
    // Volver al inicio del loop
    RJMP MAIN_LOOP

/****************************************/
// NON-Interrupt subroutines

// Revisar y procesar botones
CHECK_BOTONES:
    PUSH R16
    
    // Revisar botón decrementar (PB0)
    SBIC PINB, 0
    RJMP CHECK_BOTON_INC
    
    // Botón decrementar presionado
    CALL ANTIREBOTE
    CALL DECREMENTAR_DISPLAY
    CALL ESPERAR_SOLTAR_BTN0
    RJMP FIN_CHECK_BOTONES
    
CHECK_BOTON_INC:
    // Revisar botón incrementar (PB1)
    SBIC PINB, 1
    RJMP FIN_CHECK_BOTONES
    
    // Botón incrementar presionado
    CALL ANTIREBOTE
    CALL INCREMENTAR_DISPLAY
    CALL ESPERAR_SOLTAR_BTN1
    
FIN_CHECK_BOTONES:
    POP R16
    RET

// Esperar que se suelte botón 0
ESPERAR_SOLTAR_BTN0:
    SBIC PINB, 0
    RET
    RJMP ESPERAR_SOLTAR_BTN0

// Esperar que se suelte botón 1
ESPERAR_SOLTAR_BTN1:
    SBIC PINB, 1
    RET
    RJMP ESPERAR_SOLTAR_BTN1

// Incrementar valor del display
INCREMENTAR_DISPLAY:
    INC R25
    ANDI R25, 0x0F
    CALL ACTUALIZAR_DISPLAY
    RET

// Decrementar valor del display
DECREMENTAR_DISPLAY:
    DEC R25
    ANDI R25, 0x0F
    CALL ACTUALIZAR_DISPLAY
    RET

// Verificar timer (cada overflow son 100ms)
CHECK_TIMER:
    PUSH R16
    
    // Revisar si hubo overflow
    IN R16, TIFR0
    SBRS R16, TOV0
    RJMP FIN_CHECK_TIMER
    
    // Limpiar flag y recargar timer
    SBI TIFR0, TOV0
    LDI R16, 158
    OUT TCNT0, R16
    
    // Incrementar contador para 1 segundo
    INC R20
    CPI R20, 10             // 10 × 100ms son 1 segundo
    BRNE FIN_CHECK_TIMER
    
    // Ha pasado 1 segundo
    CLR R20
    CALL ACTUALIZAR_CONTADOR_1S
    
FIN_CHECK_TIMER:
    POP R16
    RET

// Actualizar contadores cada 1 segundo
ACTUALIZAR_CONTADOR_1S:
    PUSH R16
    PUSH R17
    
    // Incrementar contador binario cada 1 segundo
    INC R21
    ANDI R21, 0x0F
    OUT PORTC, R21          // Mostrar en LEDs
    
    // Incrementar contador de segundos
    INC R22
    ANDI R22, 0x0F
    
    // Comparar con valor del display
    CP R22, R25
    BRNE FIN_ACTUALIZAR_1S
    
    // Son iguales, resetear contador y toggle LED
    CLR R22
    IN R16, PORTB
    LDI R17, (1 << PB5)
    EOR R16, R17            // Toggle bit 5
    OUT PORTB, R16
    
FIN_ACTUALIZAR_1S:
    POP R17
    POP R16
    RET

// Anti-rebote de 200ms (2 overflows)
ANTIREBOTE:
    PUSH R26
    PUSH R16
    
    LDI R26, 0
    
ESPERAR_ANTIREBOTE:
    IN R16, TIFR0
    SBRS R16, TOV0
    RJMP ESPERAR_ANTIREBOTE
    
    SBI TIFR0, TOV0
    LDI R16, 158
    OUT TCNT0, R16
    
    INC R26
    CPI R26, 2              // 2 overflows (200ms)
    BRNE ESPERAR_ANTIREBOTE
    
    POP R16
    POP R26
    RET

// Actualizar display de 7 segmentos
ACTUALIZAR_DISPLAY:
    PUSH R16
    PUSH ZL
    PUSH ZH
    
    // Cargar dirección de la tabla en Z
    LDI ZL, LOW(T7SEG << 1)
    LDI ZH, HIGH(T7SEG << 1)
    
    // Sumar offset
    ADD ZL, R25
    LDI R16, 0
    ADC ZH, R16
    
    // Leer patrón de la tabla
    LPM R16, Z
    
    // Escribir en Puerto D
    ANDI R16, 0b01111111
    OUT PORTD, R16
    
    POP ZH
    POP ZL
    POP R16
    RET

/****************************************/
// Interrupt routines
/****************************************/
/*
* contador_display_7seg.asm
*
* Creado: 11/02/2026
* Autor : [Tu nombre]
* Descripción: Contador 0-9 con display de 7 segmentos controlado por botones
*/
/****************************************/
// Encabezado (Definición de Registros, Variables y Constantes)
.include "M328PDEF.inc"

// Tabla de display de 7 segmentos (ánodo común - activo bajo)
// Segmentos: .gfedcba (de A6 a A0)
.cseg
.org 0x0000

DISPLAY_TABLE:
    .db 0x40, 0x79, 0x24, 0x30, 0x19, 0x12, 0x02, 0x78, 0x00, 0x10, 0x08, 0x03, 0x46, 0x21, 0x06, 0x0E

/****************************************/
// Configuración de la pila
LDI     R16, LOW(RAMEND)
OUT     SPL, R16
LDI     R16, HIGH(RAMEND)
OUT     SPH, R16

/****************************************/
// Configuracion MCU
SETUP:
    // Configurar reloj a 1MHz
    LDI R16, (1 << CLKPCE)
    STS CLKPR, R16
    LDI R16, 0b00000100
    STS CLKPR, R16
    
    // Configurar Timer0 con prescaler 64
    LDI R16, 3              // Prescaler 64
    OUT TCCR0B, R16
    LDI R16, 100            // Iniciar en 100 para overflows de 10ms
    OUT TCNT0, R16
    
    // Configurar Puerto D (D6-D7) como entradas con pull-up
    LDI R16, 0b00000000
    OUT DDRD, R16
    LDI R16, 0b11000000     // Pull-up en D6 y D7
    OUT PORTD, R16
    
    // Configurar Puerto C (A0-A6) como salida para display
    LDI R16, 0b01111111
    OUT DDRC, R16
    LDI R16, 0b01111111
    OUT PORTC, R16          // Apagar todos los segmentos
    
    LDI R25, 0              // Contador del display 
    
    // Mostrar valor inicial (0)
    CALL ACTUALIZAR_DISPLAY
    
/****************************************/
// Loop Infinito
MAIN_LOOP:
    // Revisar botón incrementar (D6)
    SBIC PIND, 6
    RJMP CHECK_DEC
    
    // Botón incrementar presionado
    CALL ANTIREBOTE
    
    INC R25
    CPI R25, 16             // Si llega a 15, volver a 0
    BRNE ACTUALIZAR_INC
    LDI R25, 0
    
ACTUALIZAR_INC:
    CALL ACTUALIZAR_DISPLAY
    
    // Esperar que suelte el botón
ESPERAR_SOLTAR_INC:
    SBIC PIND, 6
    RJMP MAIN_LOOP
    RJMP ESPERAR_SOLTAR_INC
    
CHECK_DEC:
    // Revisar botón decrementar (D7)
    SBIC PIND, 7
    RJMP MAIN_LOOP
    
    // Botón decrementar presionado
    CALL ANTIREBOTE
    
    DEC R25
    CPI R25, 255        
    BRNE ACTUALIZAR_DEC
    LDI R25, 16
    
ACTUALIZAR_DEC:
    CALL ACTUALIZAR_DISPLAY
    
    // Esperar que suelte el botón
ESPERAR_SOLTAR_DEC:
    SBIC PIND, 7
    RJMP MAIN_LOOP
    RJMP ESPERAR_SOLTAR_DEC

/****************************************/
// NON-Interrupt subroutines

// Subrutina de anti-rebote
ANTIREBOTE:
    PUSH R21
    PUSH R16
    
    LDI R21, 0              // Contador de overflows
    
ESPERAR_ANTIREBOTE:
    IN R16, TIFR0
    SBRS R16, TOV0
    RJMP ESPERAR_ANTIREBOTE
    
    // Limpiar flag y recargar timer
    SBI TIFR0, TOV0
    LDI R16, 100
    OUT TCNT0, R16
    
    INC R21
    CPI R21, 5              // 2 overflows (2 × 10ms) para 20ms
    BRNE ESPERAR_ANTIREBOTE
    
    POP R16
    POP R21
    RET

// Subrutina para actualizar display
ACTUALIZAR_DISPLAY:
    PUSH R16
    PUSH R30
    PUSH R31
    
    // Cargar dirección de la tabla en Z
    LDI R30, LOW(DISPLAY_TABLE << 1)
    LDI R31, HIGH(DISPLAY_TABLE << 1)
    
    // Sumar offset (valor del contador)
    ADD R30, R25
    LDI R16, 0
    ADC R31, R16
    
    // Leer patrón de la tabla
    LPM R16, Z
    
    // Escribir en Puerto C
    OUT PORTC, R16
    
    POP R31
    POP R30
    POP R16
    RET

/****************************************/
// Interrupt routines
/****************************************/
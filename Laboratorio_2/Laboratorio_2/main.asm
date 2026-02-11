/*
* contador_timer0.asm
*
* Creado: 10/02/2026
* Autor : Luis Chacón
* Descripción: Contador binario de 4 bits con incremento cada 100ms usando Timer0
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
// Configuración de la pila
LDI     R16, LOW(RAMEND)
OUT     SPL, R16
LDI     R16, HIGH(RAMEND)
OUT     SPH, R16
/****************************************/
// Configuracion MCU
SETUP:
	// Configurar reloj a 1MHz (16MHz / 16)
	LDI R16, (1 << CLKPCE)
	STS CLKPR, R16
	LDI R16, 0b00000100     // Prescaler de 16
	STS CLKPR, R16
	
	// Configurar Timer0 con prescaler de 64
	LDI R16, (1 << CS01) | (1 << CS00)
	OUT TCCR0B, R16
	
	// Inicializar timer en 100 (cuenta de 100 a 255, luego overflow)
	LDI R16, 100
	OUT TCNT0, R16
	
	// Configurar Puerto B (PB0-PB3) como salida
	LDI R16, 0b00001111
	OUT DDRB, R16
	LDI R16, 0b00000000
	OUT PORTB, R16
	
	LDI R20, 0              // Contador de overflows (de 0 a 9)
	LDI R25, 0              // Contador binario a mostrar (de 0 a 15)
    
/****************************************/
// Loop Infinito
MAIN_LOOP:
	// Leer flags del timer
	IN R16, TIFR0
	
	// Si no hay overflow, volver a revisar
	SBRS R16, TOV0
	RJMP MAIN_LOOP
	
	// Limpiar flag de overflow
	SBI TIFR0, TOV0
	
	// Recargar timer en 100
	LDI R16, 100
	OUT TCNT0, R16
	
	// Incrementar contador de overflows
	INC R20
	
	// Si aún no llegamos a 10 overflows, volver al loop
	CPI R20, 10
	BRNE MAIN_LOOP
	
	// Han pasado 10 overflows (aproximadamente 100ms)
	CLR R20                 // Resetear contador de overflows
	
	INC R25                 // Incrementar contador binario
	ANDI R25, 0x0F          // Mantener solo 4 bits (0-15)
	
	OUT PORTB, R25          // Mostrar en LEDs
	
	RJMP MAIN_LOOP

/****************************************/
// NON-Interrupt subroutines
/****************************************/
// Interrupt routines
/****************************************/
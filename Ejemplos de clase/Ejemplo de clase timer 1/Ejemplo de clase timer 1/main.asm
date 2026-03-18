/*
* NombreProgra.asm
*
* Creado: 19/02/2026
* Autor : Luis Fernando Chacón - 241193
* Descripción: Ejemplo timer 1
*/
/****************************************/
// Encabezado (Definición de Registros, Variables y Constantes)
.include "M328PDEF.inc"     // Include definitions specific to ATMega328P
.dseg
.org    SRAM_START
//variable_name:     .byte   1   // Memory alocation for variable_name:     .byte   (byte size)

.cseg
.org 0x0000
	JMP START
.org 0x0000
	JMP ISR_TMIR1

START:
.equ TCNT1_value = 0x0BDC
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
    LDI R16, 0b00000000
    OUT DDRB, R16
    // PORT: Si entrada (0 sin pull-up, 1 con pull-up), Si salida (0 low, 1 high)
    LDI R16, 0b00000000
    OUT PORTB, R16
    
    // PUERTO C
    // DDR: 0 entrada, 1 salida
    LDI R16, 0b00000000
    OUT DDRC, R16
    // PORT: Si entrada (0 sin pull-up, 1 con pull-up), Si salida (0 low, 1 high)
    LDI R16, 0b00000000
    OUT PORTC, R16
    
    // PUERTO D
    // DDR: 0 entrada, 1 salida
    LDI R16, 0b00000000
    OUT DDRD, R16
    // PORT: Si entrada (0 sin pull-up, 1 con pull-up), Si salida (0 low, 1 high)
    LDI R16, 0b00000000
    OUT PORTD, R16

	// Configurar reloj a 1MHz
    LDI R16, (1 << CLKPCE)
    STS CLKPR, R16
    LDI R16, 0b00000100
    STS CLKPR, R16

	CALL INIT_IMTR1

	//Habilitar interrupción
	LDI R16, (1 << TOIE1)
	STS	TIMSK1, R16

	SEI
     
/****************************************/
// Loop Infinito
MAIN_LOOP:
	
    RJMP    MAIN_LOOP
/****************************************/
// NON-Interrupt subroutines
INIT_TMR1:

	LDI R16, 0x00
	OUT TCCR1A, R16
	LDI R16, (1<<CS11) // PRESCALER = 8
	STS TCCR1B, R16

	LDI R16, HIGH(TCNT1_value)
	STS TCNT1H, R16 
	LDI R16, LOW(TCNT1_value)
	STS TCNT1L, R16

	RET
/****************************************/
// Interrupt routines
ISR_TMIR1:
	PUSH R16
	IN R16, SREG
	PUSH R16

	SBI PINB, PINB0
	SBI PINB, PINB5

	POP R16
	OUT

	RET
/****************************************/
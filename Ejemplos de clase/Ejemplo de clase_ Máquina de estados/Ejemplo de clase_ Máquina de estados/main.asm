/*
* NombreProgra.asm
*
* Creado: 
* Autor : Luis Fernando Chacón - 241193
* Descripción: 
*/
/****************************************/
// Encabezado (Definición de Registros, Variables y Constantes)
.include "M328PDEF.inc"     // Include definitions specific to ATMega328P
.dseg
.org    SRAM_START
//variable_name:     .byte   1   // Memory alocation for variable_name:     .byte   (byte size)
.equ	T1VALUE			= 0xT17B
.equ	MAX_MODES		= 3
.def	MODE			= R20
.def	COUNTER			= R21
.def	ACTION			= R22


.cseg
.org 0x0000
	JMP START

.org PCI2addr
	JMP TMR1

.org

START


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
    LDI R16, 0b00000011
    OUT DDRB, R16
    // PORT: Si entrada (0 sin pull-up, 1 con pull-up), Si salida (0 low, 1 high)
    LDI R16, 0b00000000
    OUT PORTB, R16
    
    // PUERTO C
    // DDR: 0 entrada, 1 salida
    LDI R16, 0b00001111
    OUT DDRC, R16
    // PORT: Si entrada (0 sin pull-up, 1 con pull-up), Si salida (0 low, 1 high)
    LDI R16, 0b00000000
    OUT PORTC, R16
    
    // PUERTO D
    // DDR: 0 entrada, 1 salida
    LDI R16, 0b00000000
    OUT DDRD, R16
    // PORT: Si entrada (0 sin pull-up, 1 con pull-up), Si salida (0 low, 1 high)
    LDI R16, 0b00001100
    OUT PORTD, R16

	// Configurar reloj a 1MHz
    LDI R16, (1 << CLKPCE)
    STS CLKPR, R16
    LDI R16, 0b00000100     // Divisor 16 -> 16MHz/16 = 1MHz
    STS CLKPR, R16

	CALL INIT_TMR1

	//Habilitar interrupciones PD2 y PD3
	//timer 1
	LDI R16, (1 << TOIE1)
	STS TIMSK1, R16

		//Inicializar variables/registros
		CLR		MODE
		CLR		COUNTER
		CLR		ACTION

	//Habilitar interrupciones de botón
	LDI R16, (1<< TOIE1)
	STS PCINT, R16
	LDI	R16(1<<)|(1<<)
	




/****************************************/
// Loop Infinito
MAIN_LOOP:
	OUT PORTC, COUNTER
	OUT PORTB, MODE
	CPI MODE, 0
	BREQ INC_MODE



    RJMP    MAIN_LOOP

INC_MODE:
	CPI ACCION, 0x01
	BRNE EXIT_INC
	INC COUNTER
	ANDI COUNTER, 0x0F

DEC_MODE:
	CPI ACCION, 0x01
	BRNE EXIT_IN
	DEC COUNTER
	ANDI COUNTER, 0x0F


EXIT_INC:
	RJMP MAIN_LOOP

EXIT_DEC:
	RJMP MAIN_LOOP





/****************************************/
// NON-Interrupt subroutines

INIT_TMR1:
	LDI		R16, 0x00
	STS		TCCR1A, R16 //SIEMPRE USAR OUT PRIMERO, SI TIRA ERROR USAMOS STS
	LDI		R16, (1 << CS11) | (1 << CS10)
	STS		TCCR1B, R16
	LDI		R16, HIGH(T1VALUE)
	STS		RCNT1H, R16
	LDI		R16, LOW(T1VALUE)
	STS		TCNT1L, R16
	
	
	RET
/****************************************/
// Interrupt routines

PIND_ISR:
	RETI

TMR1_ISR:
	PUSH R16
	POP	R16 

	INC COUNTER
	ANDI COUNTER, 0x0F
	LDI		R16, (1 << CS11) | (1 << CS10)
	STS		TCCR1B, R16
	LDI		R16, HIGH(T1VALUE)
	STS		RCNT1H, R16

	RETI
/****************************************/
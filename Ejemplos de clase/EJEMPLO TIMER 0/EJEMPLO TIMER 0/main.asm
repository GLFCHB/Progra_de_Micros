/*
* NombreProgra.asm
*
* Creado: 
* Autor : 
* Descripción: 
*/
/****************************************/
// Encabezado (Definición de Registros, Variables y Constantes)
.include "M328PDEF.inc"     // Include definitions specific to ATMega328P
.dseg
.org    SRAM_START
//variable_name:     .byte   1   // Memory alocation for variable_name:     .byte   (byte size)

.cseg
.org 0x0000 //En esta localidad poneme...
	JMP START //Esta instrucción 
.org OVF0addr
	JMP ISR_PCINT2

 /****************************************/
// Configuración de la pila
START:
	LDI     R16, LOW(RAMEND)
	OUT     SPL, R16
	LDI     R16, HIGH(RAMEND)
	OUT     SPH, R16
/****************************************/
// Configuracion MCU
SETUP:
	CLI
	// Configurar reloj a 1MHz (16MHz / 16)
	LDI R16, (1 << CLKPCE)
	STS CLKPR, R16
	LDI R16, (1 << CLKPC2)    // Prescaler de 16
	STS CLKPR, R16

	//Configurar entradas y salidas
	CBI DDRD, DDD2
	SBI PORD, PORD2
	SBI DDRB, DDBO
	SBI DDRB, DDB5
	CBI PORTB, PORTB0
	CBI PORTB, PORTB5

	//Configurar PCINT2
	LDI R16, (1<<PCIE2)
	STS PCICR, R16
	LDI R16, (1<<PCINT18)
	STS 

	//Condigurar INT0 //0b00000011
	LDI R16, (1<<ISC01) | (1<<ISC01) //Estamos corriendo bits a la izquierda.
	STS	EICRA, R16
	LDI R16, (1<<INT0)
	STS EIMSK, R16

	//Configurar timer0 e interrupciones
	LDI R16, 0x00
	OUT TCCR0A, R16
	LDI R16, (1<<CS01) |(1<<CS00)
	OUT TCCR0B, R16
	LDI R16, 100
	OUT TCNT0, R16
	// Habilitar interrupciones tipo overflow
	LDI R16, (1<<TOIE0)
	OUT TIMSK0, R16

	CLR R20


	SEI 




/****************************************/
// Loop Infinito
MAIN_LOOP:
	CPI R20, 50
	BRNE MAIN_LOOP
	SBI PINB, PINB5
	SBI PINB, PINB0
	CLR R20
    RJMP    MAIN_LOOP

/****************************************/
// NON-Interrupt subroutines

/****************************************/
// Interrupt routines
ISR_TOV0:
	PUSH R16
	IN R16, SREG
	PUSH R16

	SBI PINB, PB5
	SBI PINB, PB0

	POP R16
	OUT TCNT0, R16

	SBI PINB, PB0
	SBI PINB, PB5

	POP R16
	OUT SREG, R16
	POP R16

	RETI


		
/****************************************/
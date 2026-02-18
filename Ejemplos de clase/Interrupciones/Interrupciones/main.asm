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
.org INT0addr
	JMP ISR_INT0 //Este nombre se busca en la sección de vectores
.org OVF0add:
	JMP ISR_TMR0_0VF:

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

	SEI 




/****************************************/
// Loop Infinito
MAIN_LOOP:
    RJMP    MAIN_LOOP

/****************************************/
// NON-Interrupt subroutines

/****************************************/
// Interrupt routines
ISR_INT0:
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

ISR_PCINT2:
	PUSH R16
	IN R16, SREG
	PUSH R16

	SBIS PIND, PIND2
	SBI PINB, PB5
	SBIS PIND, PIND2
	SBI PINB, PB0

	POP R16
	OUT SREG, R16
	POP R16
		
/****************************************/
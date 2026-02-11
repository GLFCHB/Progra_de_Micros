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

.cseg //code segment. Lo que viene a continuación es código.
.org 0x0000 //Empeza en esta localidad
 /****************************************/
// Configuración de la pila
LDI     R16, LOW(RAMEND)
OUT     SPL, R16
LDI     R16, HIGH(RAMEND)
OUT     SPH, R16
/****************************************/
// Configuracion MCU
SETUP:
    CLR R16
/****************************************/
// Loop Infinito
MAIN_LOOP:
	INC R16
	CALL SUMAR
    RJMP    MAIN_LOOP

/****************************************/
// NON-Interrupt subroutines
SUMAR:
	LDI R17, 0x05
	ADD R16, R17
	RET //Importantísimo siempre regresar al usar un call. SI NO LLENAMOS LA SRAM y se pueden sobreescribir variables. 

DELAY:
	LDI R17 , 0xFF
DELAY1:
	DEC R17
		BRNE DELAY1
		RET  

/****************************************/
// Interrupt routines

/****************************************/
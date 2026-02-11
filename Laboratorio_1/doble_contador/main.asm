/*
* contador_binario_luis_chacon.asm
*
* Creado: 10/02/2026
* Autor : Luis Chacón
* Descripción: Dos contadores binarios que se suman.
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
//Habilita los pines PD0 y PD1
LDI R24, 0x00
STS UCSR0B, R24

// Configuracion MCU
SETUP:
	 // Ponemos el reloj a 1 MHz 
    LDI R20, (1 << CLKPCE)
    STS CLKPR, R20
    LDI R20, 0b0000_0111
    STS CLKPR, R20

    // Configuración del port B
	LDI R16, 0b00000000
    LDI R17, 0b11111111
	OUT DDRB, R16
	OUT PORTB, R17

	// Configuración del port C
	LDI R16, 0b00011111
    LDI R17, 0b00000000
	OUT DDRC, R16
	OUT PORTC, R17

	// Configuración del port D
    LDI R16, 0b11111111
    LDI R17, 0b00000000
	OUT DDRD, R16
	OUT PORTD, R17
   
    LDI R29, 0x00 // Registro del Contador 1
	LDI R30, 0x00 // Registro del contador 2
	LDI R31, 0x00 // Registro del contador 3
    
/****************************************/
// Loop Infinito
MAIN_LOOP:

    // Mostramos los contadores en los puertos correspondientes
    // Combinamos contador 1 (bits 0-3) y contador 2 (bits 4-7) en PORTD
    MOV R16, R30
    SWAP R16        // Mover R30 a bits altos
    ANDI R16, 0xF0  // Limpiar bits bajos
    MOV R17, R29
    ANDI R17, 0x0F  // Asegurar R29 solo en bits bajos
    OR R16, R17     // Combinar ambos contadores
    OUT PORTD, R16  // Mostrar en PORTD
    
    // Mostrar resultado de suma en PORTC (bits 0-3)
    MOV R18, R31
    ANDI R18, 0x0F  // Solo 4 bits del resultado
    IN R19, PORTC
    ANDI R19, 0xF0  // Mantener bit 4 (LED overflow)
    OR R18, R19     // Combinar resultado con estado del LED
    OUT PORTC, R18
    
	RJMP CHECK_INC
//Como tenemos pull-up interno, cuando presionemos un botón este se va a ir a 0V.

// Revisar Botón Incrementar contador 1
CHECK_INC:
    SBIC PINB, 0 //Revisamos si el bit 0 en el PINB es 0, si sí, entonces pegamos el salto. 
	RJMP CHECK_DEC //Si no, vamos a ver si hay un decremento	
    RJMP INC_1 //Si sí está presionado, vamos a incrementar.

// Revisar botón de decremento 1. 
CHECK_DEC:
    SBIC PINB, 1 //Si el valor en el botón es 0V (está presionado) pegamos el salto  
    RJMP CHECK_INC2 //Si no está presionado, vamos a ver si el del incremento 2 lo está. 
    RJMP DEC_1 //Si sí está presionado, vamos a decrementar. 

CHECK_INC2:
	SBIC PINB, 2
	RJMP CHECK_DEC2
	RJMP INC_2

CHECK_DEC2:
    SBIC PINB, 3     
    RJMP CHECK_SUM
    RJMP DEC_2

CHECK_SUM:
	SBIC PINB, 4     
    RJMP MAIN_LOOP
    RJMP SUM
	
/****************************************/
// NON-Interrupt subroutines
DELAY:
    LDI R18, 100
	D1: 
	LDI R19, 100
	D2: 
	DEC R19
    BRNE D2
    DEC R18
    BRNE D1
    RET
/****************************************/
// Interrupt routines

INC_1: 
    CALL DELAY //Este sería nuestro sistema de anti-rebote. 
    INC R29
    ANDI R29, 0x0F //Usamos un and para que nuestro contador sea solo de 4 bits. Si no, puede afectar nuestra suma más tarde.
    ESPERAR_11:
    SBIC PINB, 0 //Si el botón sigue presionado, vamos a seguir esperando. 
    RJMP MAIN_LOOP
    RJMP ESPERAR_11

DEC_1: 
    CALL DELAY 
    DEC R29
    ANDI R29, 0x0F //Usamos un and para que nuestro contador sea solo de 4 bits. Si no, puede afectar nuestra suma más tarde. 
    ESPERAR_21:
    SBIC PINB, 1 
    RJMP MAIN_LOOP
    RJMP ESPERAR_21

INC_2:
    CALL DELAY
    INC R30
    ANDI R30, 0x0F //Usamos un and para que nuestro contador sea solo de 4 bits. Si no, puede afectar nuestra suma más tarde.
    ESPERAR_22:
    SBIC PINB, 2 
    RJMP MAIN_LOOP
    RJMP ESPERAR_22

DEC_2:
    CALL DELAY 
    DEC R30
    ANDI R30, 0x0F //Usamos un and para que nuestro contador sea solo de 4 bits. Si no, puede afectar nuestra suma más tarde.
	ESPERAR_32:
    SBIC PINB, 3 
    RJMP MAIN_LOOP
    RJMP ESPERAR_32

SUM:
	CALL DELAY
	MOV R31, R30
	ADD R31, R29
	CPI R31, 0x10 // Comparar con 16 (mayor que 15)
	BRGE LED // Saltar si es mayor o igual que 16
	CBI PORTC, 4 //Apagamos el led de carry
	ESPERAR_SUM:
    SBIC PINB, 4 
    RJMP MAIN_LOOP
    RJMP ESPERAR_SUM

LED:
	SBI PORTC, 4 //Encendemos el led de carry
	ANDI R31, 0x0F // Mantener solo 4 bits del resultado
	ESPERAR_SUM2:
    SBIC PINB, 4 
    RJMP MAIN_LOOP
    RJMP ESPERAR_SUM2
	
	
	
/****************************************/
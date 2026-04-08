/*
* Proyecto_1.asm
*
* Creado: 25/02/2026
* Autor : Luis Fernando Chacón - 241193
* Descripción: Reloj que muestra hora, fecha y tiene alarma. 
*/
//**************************************//
// Encabezado (Definición de Registros, Variables y Constantes)
.include "m328pdef.inc"     // Include definitions specific to ATMega328P

.dseg
.org    SRAM_START
// --- Variables de Tiempo ---
segundos:       .byte 1
minutos_u:      .byte 1
minutos_d:      .byte 1
horas_u:        .byte 1
horas_d:        .byte 1
// --- Variables de Fecha ---
dias_u:         .byte 1
dias_d:         .byte 1
meses_u:        .byte 1
meses_d:        .byte 1
// --- Variables de Alarma ---
al_min_u:       .byte 1
al_min_d:       .byte 1
al_hr_u:        .byte 1
al_hr_d:        .byte 1
// --- Variables de Control ---
estado:         .byte 1     // 0=Hora, 1= conf Hora, 2= Fecha, 3=Conf Fecha, 4=Conf Alarma
subestado:      .byte 1     // 0=Izquierda, 1=Derecha
digito_activo:  .byte 1     // 0 a 3 para multiplexado
banderas:       .byte 1     // Bit0 = Alarma ON/OFF
cont_500ms_L:   .byte 1
cont_500ms_H:   .byte 1

.cseg
.org 0x0000
    RJMP SETUP             // Vector de Reset

.org 0x000A                // Vector de interrupcion Pin Change 1 (PCINT1_vect para Puerto C)
    RJMP BOTONES_ISR

.org 0x0020                // Vector de interrupcion Timer0 OVF
    RJMP TIMER0_OVF_ISR

// --- Tabla de 7 Segmentos (0-9) ---
TABLA_7SEG: 
    .db 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x67

//**************************************//
SETUP:
// Configuración de la pila
LDI     R16, LOW(RAMEND)
OUT     SPL, R16
LDI     R16, HIGH(RAMEND)
OUT     SPH, R16

//**************************************//
// Configuracion MCU

    // PUERTO B (PB0-PB3: Transistores, PB4-PB5: LEDs Modo)
    LDI R16, 0b00111111    // PB0-PB5 salidas
    OUT DDRB, R16
    LDI R16, 0b00000000    // Apagados inicialmente
    OUT PORTB, R16

    // PUERTO C (PC0-PC4: Botones, PC5: Buzzer)
    LDI R16, 0b00100000    // PC5 salida, PC0-PC4 entradas
    OUT DDRC, R16
    LDI R16, 0b00011111    // Pull-ups en PC0-PC4
    OUT PORTC, R16

    // PUERTO D (PD0-PD6: Segmentos, PD7: Dos Puntos)
    LDI R16, 0b11111111    // Todo salida
    OUT DDRD, R16
    LDI R16, 0b00000000    // Apagados
    OUT PORTD, R16

    // Configuración Timer0 (Prescaler 8)
    LDI R16, 0b00000010    
    OUT TCCR0B, R16
    LDI R16, 0b00000001    // Habilitar interrupción OVF
    STS TIMSK0, R16

    // Configuración Interrupciones Pin Change (Botones)
    LDI R16, 0b00000010    // Habilitar PCIE1 (Puerto C)
    STS PCICR, R16
    LDI R16, 0b00011111    // Enmascarar PCINT8 a PCINT12
    STS PCMSK1, R16

    // Inicializar variables de SRAM 
    CLR R16
    STS segundos, R16
    STS estado, R16
    STS subestado, R16
    STS digito_activo, R16
    STS cont_500ms_L, R16
    STS cont_500ms_H, R16

	// --- Valores iniciales de Hora (23:59:50) ---
	LDI R16, 50            
    STS segundos, R16
    LDI R16, 9
    STS minutos_u, R16
    LDI R16, 5
    STS minutos_d, R16
    LDI R16, 3
    STS horas_u, R16
    LDI R16, 2
    STS horas_d, R16

	// --- Valores iniciales de Fecha (31/12) ---
    LDI R16, 1
    STS dias_u, R16      // 1 unidad de día
    LDI R16, 3
    STS dias_d, R16      // 3 decenas de día (31)
    
    LDI R16, 2
    STS meses_u, R16     // 2 unidades de mes
    LDI R16, 1
    STS meses_d, R16     // 1 decena de mes (12)

    // --- Valores iniciales de Alarma (00:01) ---
    LDI R16, 1
    STS al_min_u, R16     
    CLR R16               
    STS al_min_d, R16   
    STS al_hr_u, R16      
    STS al_hr_d, R16       

    SEI // Habilitar interrupciones globales

//**************************************//
// Loop Infinito
MAIN_LOOP:
    RJMP    MAIN_LOOP

//**************************************//
// NON-Interrupt subroutines
//**************************************//

//**************************************//
// Interrupt routines

// --- INTERRUPCIÓN DE BOTONES (PCINT1) ---
BOTONES_ISR:
    PUSH R16
    IN R16, SREG
    PUSH R16
    PUSH R17
    PUSH R18
    PUSH R19
    PUSH R20

    // Apagar temporalmente ESTA interrupción (PCINT1) para no hacer un bucle infinito
    LDS R16, PCICR
    ANDI R16, 0b11111101
    STS PCICR, R16

    // Volvemos a habilitar las interrupciones globales
    // Así el Timer0 puede seguir multiplexando y los displays no parpadean
    SEI 

    // 1. DELAY 
    LDI R20, 4
DELAY_EXTERNO:
    LDI R19, 255
DELAY_MEDIO:
    LDI R18, 255
DELAY_INTERNO:
    DEC R18
    BRNE DELAY_INTERNO
    DEC R19
    BRNE DELAY_MEDIO
    DEC R20
    BRNE DELAY_EXTERNO

    // Volvemos a cerrar las interrupciones globales para terminar de leer el botón
    CLI 

    // 2. Limpiar la bandera de rebotes acumulados
    LDI R16, 0b00000010    
    OUT PCIFR, R16

    // Volver a habilitar PCINT1
    LDS R16, PCICR
    ORI R16, 0b00000010
    STS PCICR, R16

    // 3. Leer el puerto C DESPUÉS del delay
    IN R16, PINC
    
    // --- INTERCEPTOR DE ALARMA ---
    LDS R17, banderas
    SBRS R17, 0            // Si la bandera está en 0 (apagada), salta al ruteo normal
    RJMP RUTEO_NORMAL

    // Si está sonando, SOLO revisamos el botón de Alarma (PC4)
    SBRC R16, 4            // Si PC4 está en 1 (NO presionado), salimos de la interrupción
    RJMP FIN_BOTONES       // ¡Esto bloquea los demás botones!

    // Si PC4 está presionado (0), apagamos la alarma
    ANDI R17, 0b11111110   // Limpiamos el Bit 0
    STS banderas, R17
    IN R16, PORTC
    ANDI R16, 0b11011111   // Forzamos el apagado del buzzer (PC5)
    OUT PORTC, R16
    RJMP FIN_BOTONES       // Salimos directo

RUTEO_NORMAL:
    // --- RUTEO DE BOTONES ---
    SBRS R16, 0            // Si PC0 está en 0 (presionado)
    RJMP CAMBIAR_MODO
    SBRS R16, 1            // Si PC1 está en 0 (presionado)
    RJMP ACCION_UP
	SBRS R16, 2            // Si PC2 está en 0 (presionado) 
    RJMP ACCION_DOWN
    SBRS R16, 3            // Si PC3 está en 0 (presionado) 
    RJMP ACCION_SELECT     
    RJMP FIN_BOTONES       // Si no fue ninguno, salimos

CAMBIAR_MODO:
    LDS R17, estado
    INC R17
    CPI R17, 5            
    BRNE GUARDAR_MODO
    CLR R17

GUARDAR_MODO:
    STS estado, R17

    IN R16, PORTB
    ANDI R16, 0b11001111   
    MOV R18, R17
    LSL R18
    LSL R18
    LSL R18
    LSL R18                
    OR R16, R18
    OUT PORTB, R16
    RJMP FIN_BOTONES 

// ---------------------------------------------------
// LÓGICA DEL BOTÓN UP (PC1)
// ---------------------------------------------------
ACCION_UP:
    LDS R17, estado
    CPI R17, 0
    BRNE CONTINUAR_UP   
    RJMP SALIR_UP        

CONTINUAR_UP:
    LDS R18, subestado
    
    CPI R17, 1            // Modo 1: Configurar Hora
    BREQ EDITAR_TIEMPO
    CPI R17, 4            // Modo 4: Configurar Alarma
    BREQ EDITAR_TIEMPO
    CPI R17, 3            // Modo 3: Configurar Fecha
    BRNE NO_ES_FECHA_U    
    RJMP EDITAR_FECHA_U   
NO_ES_FECHA_U:
    RJMP SALIR_UP

EDITAR_TIEMPO:
    CPI R18, 0
    BREQ UP_HORAS         // subestado 0 = Editar Horas (Izquierda)
    RJMP UP_MINUTOS       // subestado 1 = Editar Minutos (Derecha)

// --- SUBIR HORAS (0 a 23) ---
UP_HORAS:
    CPI R17, 1
    BREQ CARGAR_HR_NORMAL
    LDS R19, al_hr_u
    LDS R20, al_hr_d
    RJMP INCREMENTAR_HR
CARGAR_HR_NORMAL:
    LDS R19, horas_u
    LDS R20, horas_d

INCREMENTAR_HR:
    INC R19
    CPI R20, 2
    BRNE HR_MENOR_20
    CPI R19, 4
    BRNE GUARDAR_HR
    CLR R19               // Llegó a 24, reinicia a 00
    CLR R20
    RJMP GUARDAR_HR
HR_MENOR_20:
    CPI R19, 10
    BRNE GUARDAR_HR
    CLR R19
    INC R20

GUARDAR_HR:
    CPI R17, 1
    BREQ GUARDAR_HR_NORMAL
    STS al_hr_u, R19
    STS al_hr_d, R20
    RJMP SALIR_UP
GUARDAR_HR_NORMAL:
    STS horas_u, R19
    STS horas_d, R20
    RJMP SALIR_UP

// --- SUBIR MINUTOS (0 a 59) ---
UP_MINUTOS:
    CPI R17, 1
    BREQ CARGAR_MIN_NORMAL
    LDS R19, al_min_u
    LDS R20, al_min_d
    RJMP INCREMENTAR_MIN
CARGAR_MIN_NORMAL:
    LDS R19, minutos_u
    LDS R20, minutos_d

INCREMENTAR_MIN:
    INC R19
    CPI R19, 10
    BRNE GUARDAR_MIN
    CLR R19
    INC R20
    CPI R20, 6
    BRNE GUARDAR_MIN
    CLR R20               // Llegó a 60, reinicia a 00

GUARDAR_MIN:
    CPI R17, 1
    BREQ GUARDAR_MIN_NORMAL
    STS al_min_u, R19
    STS al_min_d, R20
    RJMP SALIR_UP
GUARDAR_MIN_NORMAL:
    STS minutos_u, R19
    STS minutos_d, R20
// --- LÓGICA DE SUBIR FECHA ---
EDITAR_FECHA_U:
    CPI R18, 0
    BREQ UP_DIAS          // subestado 0 = Días (Izquierda)
    RJMP UP_MESES         // subestado 1 = Meses (Derecha)

UP_DIAS:
    LDS R19, dias_u
    LDS R20, dias_d
    INC R19
    CPI R19, 10
    BRNE REVISAR_TOPE_DIAS
    CLR R19
    INC R20

REVISAR_TOPE_DIAS:
    LDS R16, meses_u     // Reusamos R16 para leer el mes actual
    LDS R18, meses_d     // Reusamos R18

    CPI R18, 1           // ¿Estamos en los meses 10, 11 o 12?
    BREQ TOPE_MESES_1X
    
    // Si estamos en meses 01 a 09:
    CPI R16, 2           // Febrero
    BREQ REVISAR_28
    CPI R16, 4           // Abril
    BREQ REVISAR_30
    CPI R16, 6           // Junio
    BREQ REVISAR_30
    CPI R16, 9           // Septiembre
    BREQ REVISAR_30
    RJMP REVISAR_31      // Enero, Marzo, Mayo, Julio, Agosto

TOPE_MESES_1X:
    CPI R16, 1           // Noviembre
    BREQ REVISAR_30
    RJMP REVISAR_31      // Octubre y Diciembre

REVISAR_28:
    CPI R20, 2
    BRNE GUARDAR_DIAS
    CPI R19, 9           // ¿Llegó a 29?
    BRNE GUARDAR_DIAS
    RJMP RESET_DIAS

REVISAR_30:
    CPI R20, 3
    BRNE GUARDAR_DIAS
    CPI R19, 1           // ¿Llegó a 31?
    BRNE GUARDAR_DIAS
    RJMP RESET_DIAS

REVISAR_31:
    CPI R20, 3
    BRNE GUARDAR_DIAS
    CPI R19, 2           // ¿Llegó a 32?
    BRNE GUARDAR_DIAS

RESET_DIAS:
    LDI R19, 1           // Regresa al día 01
    CLR R20

GUARDAR_DIAS:
    STS dias_u, R19
    STS dias_d, R20
    RJMP SALIR_UP
UP_MESES:
    LDS R19, meses_u
    LDS R20, meses_d
    INC R19
    CPI R19, 10
    BRNE REVISAR_TOPE_MESES
    CLR R19
    INC R20
REVISAR_TOPE_MESES:
    CPI R20, 1
    BRNE GUARDAR_MESES
    CPI R19, 3
    BRNE GUARDAR_MESES
    LDI R19, 1            // Llegó a 13, reinicia a 01
    CLR R20
GUARDAR_MESES:
    RJMP VERIFICAR_DIAS_MES

SALIR_UP:
	RJMP FIN_BOTONES
// ---------------------------------------------------
// LÓGICA DEL BOTÓN DOWN (PC2)
// ---------------------------------------------------
ACCION_DOWN:
    LDS R17, estado
    CPI R17, 0
    BRNE CONTINUAR_DOWN
    RJMP SALIR_DOWN       // Si es 0, salir de la subrutina

CONTINUAR_DOWN:
    LDS R18, subestado
    
    CPI R17, 1            // Modo 1: Configurar Hora
    BREQ EDITAR_TIEMPO_D
    CPI R17, 4            // Modo 4: Configurar Alarma
    BREQ EDITAR_TIEMPO_D
    CPI R17, 3            // Modo 3: Configurar Fecha
    BRNE NO_ES_FECHA_D    
    RJMP EDITAR_FECHA_D   
NO_ES_FECHA_D:
    RJMP SALIR_DOWN

EDITAR_TIEMPO_D:
    CPI R18, 0
    BREQ DOWN_HORAS
    RJMP DOWN_MINUTOS

// --- BAJAR HORAS (23 a 0) ---
DOWN_HORAS:
    CPI R17, 1
    BREQ CARGAR_HR_D_NORMAL
    LDS R19, al_hr_u
    LDS R20, al_hr_d
    RJMP DECREMENTAR_HR
CARGAR_HR_D_NORMAL:
    LDS R19, horas_u
    LDS R20, horas_d

DECREMENTAR_HR:
    CPI R19, 0
    BRNE HR_RESTAR_U
    CPI R20, 0
    BRNE HR_RESTAR_D
    // Si ambos son 0 (00:xx), el underflow salta a 23
    LDI R19, 3
    LDI R20, 2
    RJMP GUARDAR_HR_D

HR_RESTAR_D:
    LDI R19, 9            // Las unidades pasan a 9
    DEC R20               // Se resta 1 a las decenas
    RJMP GUARDAR_HR_D

HR_RESTAR_U:
    DEC R19

GUARDAR_HR_D:
    CPI R17, 1
    BREQ GUARDAR_HR_D_NORMAL
    STS al_hr_u, R19
    STS al_hr_d, R20
    RJMP SALIR_DOWN
GUARDAR_HR_D_NORMAL:
    STS horas_u, R19
    STS horas_d, R20
    RJMP SALIR_DOWN

// --- BAJAR MINUTOS (59 a 0) ---
DOWN_MINUTOS:
    CPI R17, 1
    BREQ CARGAR_MIN_D_NORMAL
    LDS R19, al_min_u
    LDS R20, al_min_d
    RJMP DECREMENTAR_MIN
CARGAR_MIN_D_NORMAL:
    LDS R19, minutos_u
    LDS R20, minutos_d

DECREMENTAR_MIN:
    CPI R19, 0
    BRNE MIN_RESTAR_U
    CPI R20, 0
    BRNE MIN_RESTAR_D
    // Si ambos son 0 (xx:00), el underflow salta a 59
    LDI R19, 9
    LDI R20, 5
    RJMP GUARDAR_MIN_D_FINAL

MIN_RESTAR_D:
    LDI R19, 9
    DEC R20
    RJMP GUARDAR_MIN_D_FINAL

MIN_RESTAR_U:
    DEC R19

GUARDAR_MIN_D_FINAL:
    CPI R17, 1
    BREQ GUARDAR_MIN_D_NORMAL
    STS al_min_u, R19
    STS al_min_d, R20
    RJMP SALIR_DOWN
GUARDAR_MIN_D_NORMAL:
    STS minutos_u, R19
    STS minutos_d, R20

// --- LÓGICA DE BAJAR FECHA ---
EDITAR_FECHA_D:
    CPI R18, 0
    BREQ DOWN_DIAS
    RJMP DOWN_MESES

DOWN_DIAS:
    LDS R19, dias_u
    LDS R20, dias_d
    
    // Revisar si estamos en el día 01 para hacer el salto hacia atrás
    CPI R20, 0
    BRNE DIAS_RESTAR_NORMAL
    CPI R19, 1
    BRNE DIAS_RESTAR_NORMAL
    
    RJMP UNDERFLOW_DIAS

DIAS_RESTAR_NORMAL:
    CPI R19, 0
    BRNE DIAS_RESTAR_U
    LDI R19, 9            // Las unidades pasan a 9, restamos decenas
    DEC R20
    RJMP GUARDAR_DIAS_D
DIAS_RESTAR_U:
    DEC R19
    RJMP GUARDAR_DIAS_D

UNDERFLOW_DIAS:
    LDS R16, meses_u
    LDS R18, meses_d
    
    CPI R18, 1
    BREQ UNDERFLOW_1X
    
    CPI R16, 2
    BREQ UNDER_28
    CPI R16, 4
    BREQ UNDER_30
    CPI R16, 6
    BREQ UNDER_30
    CPI R16, 9
    BREQ UNDER_30
    RJMP UNDER_31
    
UNDERFLOW_1X:
    CPI R16, 1
    BREQ UNDER_30
    RJMP UNDER_31

UNDER_28:
    LDI R19, 8
    LDI R20, 2
    RJMP GUARDAR_DIAS_D
UNDER_30:
    LDI R19, 0
    LDI R20, 3
    RJMP GUARDAR_DIAS_D
UNDER_31:
    LDI R19, 1
    LDI R20, 3

GUARDAR_DIAS_D:
    STS dias_u, R19
    STS dias_d, R20
    RJMP SALIR_DOWN
DOWN_MESES:
    LDS R19, meses_u
    LDS R20, meses_d
    CPI R20, 0
    BRNE MESES_SEGUIR
    CPI R19, 1
    BRNE MESES_SEGUIR
    LDI R19, 2            // Si es 01 y se resta, salta a 12
    LDI R20, 1
    RJMP GUARDAR_MESES_D
MESES_SEGUIR:
    CPI R19, 0
    BRNE MESES_RESTAR_U
    LDI R19, 9
    DEC R20
    RJMP GUARDAR_MESES_D
MESES_RESTAR_U:
    DEC R19
GUARDAR_MESES_D:
    RJMP VERIFICAR_DIAS_MES

SALIR_DOWN:
    RJMP FIN_BOTONES      // Muro de contención para que no pase a Select

// ---------------------------------------------------
// LÓGICA DEL BOTÓN SELECT (PC3)
// ---------------------------------------------------
ACCION_SELECT:
    LDS R17, estado
    CPI R17, 0
    BREQ SALIR_SELECT     // En Modo 0 (Mostrar Hora) no hace nada
    CPI R17, 2
    BREQ SALIR_SELECT     // En Modo 2 (Mostrar Fecha) no hace nada


    LDS R18, subestado
    CPI R18, 0
    BREQ CAMBIAR_A_MINUTOS
    
    // Si era 1 (Minutos), lo regresamos a 0 (Horas)
    CLR R18
    RJMP GUARDAR_SUBESTADO

CAMBIAR_A_MINUTOS:
    LDI R18, 1            // Lo pasamos a 1 (Minutos)

GUARDAR_SUBESTADO:
    STS subestado, R18

SALIR_SELECT:
    RJMP FIN_BOTONES

// --- AUTOCORRECCIÓN DE DÍAS AL CAMBIAR MES ---
VERIFICAR_DIAS_MES:
    STS meses_u, R19       // Guardamos el nuevo mes primero
    STS meses_d, R20

    LDS R16, dias_u        // Leemos el día que está en pantalla
    LDS R17, dias_d

    CPI R20, 1             // ¿Estamos en Mes 10, 11 o 12?
    BREQ V_MES_1X

    CPI R19, 2             // ¿Febrero?
    BREQ V_FORZAR_28
    CPI R19, 4             // ¿Abril?
    BREQ V_FORZAR_30
    CPI R19, 6             // ¿Junio?
    BREQ V_FORZAR_30
    CPI R19, 9             // ¿Septiembre?
    BREQ V_FORZAR_30
    RJMP V_FIN_CORRECCION  // Enero, Marzo, Mayo, Julio, Agosto (31 es válido)

V_MES_1X:
    CPI R19, 1             // ¿Noviembre?
    BREQ V_FORZAR_30
    RJMP V_FIN_CORRECCION  // Octubre, Diciembre

V_FORZAR_28:
    CPI R17, 3             // Si es día 30 o 31...
    BREQ V_APLICAR_28      
    CPI R17, 2
    BRNE V_FIN_CORRECCION  // Si es 0x o 1x, todo nítido
    CPI R16, 9             // Si es día 29...
    BREQ V_APLICAR_28      
    RJMP V_FIN_CORRECCION

V_APLICAR_28:
    LDI R16, 8             // Bajar a la fuerza a 28
    LDI R17, 2
    RJMP V_GUARDAR_CORRECCION

V_FORZAR_30:
    CPI R17, 3
    BRNE V_FIN_CORRECCION
    CPI R16, 1             // Solo si es exactamente día 31...
    BRNE V_FIN_CORRECCION  
    LDI R16, 0             // Bajar a la fuerza a 30
    LDI R17, 3

V_GUARDAR_CORRECCION:
    STS dias_u, R16
    STS dias_d, R17

V_FIN_CORRECCION:
    RJMP FIN_BOTONES

FIN_BOTONES:
    POP R20
    POP R19
    POP R18
    POP R17
    POP R16
    OUT SREG, R16
    POP R16
    RETI

// --- INTERRUPCIÓN DEL TIMER 0 ---
TIMER0_OVF_ISR:
    PUSH R16               
    IN R16, SREG
    PUSH R16
    PUSH R17
    PUSH R18
	PUSH R19             
    PUSH R20
    PUSH R30               // Puntero Z Low
    PUSH R31               // Puntero Z High

    // -- MULTIPLEXADO DE DISPLAYS --
    IN R16, PORTB
    ANDI R16, 0b11110000   // Apagar transistores (PB0-PB3)
    OUT PORTB, R16

    LDS R17, digito_activo
    LDS R19, estado          // Leemos en qué modo estamos

    // Revisamos qué modo es para saltar a la rutina correcta
    CPI R19, 2            // Estado 2: Mostrar Fecha
    BREQ MOSTRAR_FECHA
    CPI R19, 3            // Estado 3: Configurar Fecha
    BREQ MOSTRAR_FECHA
    CPI R19, 4            // Estado 4: Configurar Alarma
    BREQ MOSTRAR_ALARMA

  

    // Si es 0 o 1, mostramos la HORA NORMAL
MOSTRAR_TIEMPO:
    CPI R17, 0
    BREQ MOSTRAR_T_MIN_U
    CPI R17, 1
    BREQ MOSTRAR_T_MIN_D
    CPI R17, 2
    BREQ MOSTRAR_T_HR_U
    RJMP MOSTRAR_T_HR_D

MOSTRAR_T_MIN_U: 
    LDS R18, minutos_u 
    RJMP CARGAR_7SEG
MOSTRAR_T_MIN_D: 
    LDS R18, minutos_d 
    RJMP CARGAR_7SEG
MOSTRAR_T_HR_U:  
    LDS R18, horas_u 
    RJMP CARGAR_7SEG
MOSTRAR_T_HR_D:  
    LDS R18, horas_d 
    RJMP CARGAR_7SEG

    // Si es 2, mostramos la FECHA (DD:MM)
MOSTRAR_FECHA:
    CPI R17, 0
    BREQ MOSTRAR_F_MES_U
    CPI R17, 1
    BREQ MOSTRAR_F_MES_D
    CPI R17, 2
    BREQ MOSTRAR_F_DIA_U
    RJMP MOSTRAR_F_DIA_D

MOSTRAR_F_MES_U: 
    LDS R18, meses_u 
    RJMP CARGAR_7SEG
MOSTRAR_F_MES_D: 
    LDS R18, meses_d 
    RJMP CARGAR_7SEG
MOSTRAR_F_DIA_U: 
    LDS R18, dias_u   
    RJMP CARGAR_7SEG
MOSTRAR_F_DIA_D: 
    LDS R18, dias_d   
    RJMP CARGAR_7SEG

    // Si es 3, mostramos la ALARMA
MOSTRAR_ALARMA:
    CPI R17, 0
    BREQ MOSTRAR_A_MIN_U
    CPI R17, 1
    BREQ MOSTRAR_A_MIN_D
    CPI R17, 2
    BREQ MOSTRAR_A_HR_U
    RJMP MOSTRAR_A_HR_D

MOSTRAR_A_MIN_U: 
    LDS R18, al_min_u 
    RJMP CARGAR_7SEG
MOSTRAR_A_MIN_D: 
    LDS R18, al_min_d 
    RJMP CARGAR_7SEG
MOSTRAR_A_HR_U:  
    LDS R18, al_hr_u   
    RJMP CARGAR_7SEG
MOSTRAR_A_HR_D:  
    LDS R18, al_hr_d   

CARGAR_7SEG:
    // Usar el puntero Z para buscar el patrón
    LDI R30, LOW(TABLA_7SEG * 2)
    LDI R31, HIGH(TABLA_7SEG * 2)
    ADD R30, R18
    CLR R16               
    ADC R31, R16           
    LPM R18, Z


    // Mandar el patrón al Puerto D sin tocar el PD7 (Dos Puntos)
    IN R16, PORTD
    ANDI R16, 0b10000000   // Conservar PD7
    OR R16, R18            // Mezclar con el patrón del 7 segmentos
    OUT PORTD, R16

    // Encender el transistor correcto
    MOV R18, R17           
    LDI R16, 1             
DESPLAZAR_MUX:
    CPI R18, 0
    BREQ LISTO_MUX
    LSL R16                
    DEC R18
    RJMP DESPLAZAR_MUX
LISTO_MUX:
    IN R18, PORTB
    OR R18, R16            
    OUT PORTB, R18

    // Actualizar dígito para la próxima vez
    INC R17
    CPI R17, 4
    BRNE GUARDAR_DIG
    CLR R17                
GUARDAR_DIG:
    STS digito_activo, R17

    // -- CONTEO DE 500ms y RTC --
    LDS R16, cont_500ms_L
    LDS R17, cont_500ms_H
    SUBI R16, LOW(-1)      
    SBCI R17, HIGH(-1)

    // Comparar con 3906 (0x0F42) para los 500ms
    CPI R16, 0x42
    LDI R18, 0x0F
    CPC R17, R18
    BREQ PASARON_500MS     // Si son iguales, salta un pasito hacia abajo
    RJMP GUARDAR_TIMER     // Si no son iguales, usa el salto largo hasta el final

PASARON_500MS:
    // Pasaron 500ms: Reiniciar contador y Toggle PD7
    CLR R16
    CLR R17
    IN R18, PORTD
    LDI R19, 0b10000000    
    EOR R18, R19
    OUT PORTD, R18

    // --- PARPADEO DE LEDS (SOLO MODO 4) ---
    LDS R19, estado
    CPI R19, 4             // ¿Estamos en Modo 4 (Alarma)?
    BRNE REVISAR_BUZZER    // Si NO es modo 4, salta a revisar el buzzer en lugar de salir

    IN R19, PORTB
    LDI R20, 0b00110000    // Máscara para hacer toggle a los LEDs en PB4 y PB5
    EOR R19, R20
    OUT PORTB, R19

REVISAR_BUZZER:
    // --- PARPADEO DEL BUZZER ---
    LDS R19, banderas
    SBRS R19, 0            // ¿Está sonando la alarma (Bit 0 en 1)?
    RJMP REVISAR_SEGUNDO   // Si no, salimos de una vez

    // Validar que estemos en Modo 0 (Hora) o Modo 2 (Fecha)
    LDS R19, estado
    CPI R19, 0
    BREQ SONAR_BUZZER      // Si es 0, suena
    CPI R19, 2
    BREQ SONAR_BUZZER      // Si es 2, suena
    RJMP REVISAR_SEGUNDO   // Si es cualquier otro (edición), se mantiene en silencio

SONAR_BUZZER:
    IN R19, PORTC
    LDI R20, 0b00100000    // Máscara para hacer toggle a PC5 (Buzzer)
    EOR R19, R20
    OUT PORTC, R19

REVISAR_SEGUNDO:
    // ¿Fueron 500ms o 1000ms? Verificamos el estado de PD7 para saber si pasó un segundo
    SBRC R18, 7            // Si PD7 está en 1 (encendido), solo pasaron 500ms
    RJMP GUARDAR_TIMER     // Si PD7 está en 0 (apagado), ¡ya pasó el segundo completo!
	
    // --- INCREMENTAR SEGUNDOS (RTC) ---
    LDS R18, segundos
    INC R18
    CPI R18, 60
    BRNE GUARDAR_SEGUNDOS
    CLR R18
    STS segundos, R18

	
INC_MIN_U:
    LDS R19, minutos_u
    INC R19
    CPI R19, 10
    BRNE GUARDAR_MIN_U
    CLR R19
    STS minutos_u, R19

INC_MIN_D:
    LDS R19, minutos_d
    INC R19
    CPI R19, 6
    BRNE GUARDAR_MIN_D
    CLR R19
    STS minutos_d, R19

INC_HORAS:
    LDS R19, horas_u
    LDS R20, horas_d
    INC R19
    
    // Trampa de las 24 horas (Si decenas = 2 y unidades = 4)
    CPI R20, 2
    BRNE REVISAR_HORA_NORMAL
    CPI R19, 4
    BRNE GUARDAR_HORAS
    // Si llegó a 24, reset a 00 y aquí saltaría a DÍAS
    CLR R19
    CLR R20
    STS horas_u, R19
    STS horas_d, R20
    RJMP INC_DIAS

REVISAR_HORA_NORMAL:
    // Si no estamos en los 20s, cuenta normal hasta 10
    CPI R19, 10
    BRNE GUARDAR_HORAS
    CLR R19
    INC R20

GUARDAR_HORAS:
    STS horas_u, R19
    STS horas_d, R20
    RJMP FIN_RTC

GUARDAR_MIN_D:
    STS minutos_d, R19
    RJMP FIN_RTC

GUARDAR_MIN_U:
    STS minutos_u, R19
    RJMP FIN_RTC

GUARDAR_SEGUNDOS:
    STS segundos, R18
    RJMP FIN_RTC

INC_DIAS:
    LDS R19, dias_u
    LDS R20, dias_d
    INC R19
    CPI R19, 10
    BRNE REVISAR_RTC_MES
    CLR R19
    INC R20

REVISAR_RTC_MES:
    LDS R16, meses_u
    LDS R18, meses_d

    // Verificamos en qué mes estamos para saber el límite
    CPI R18, 1
    BREQ RTC_MES_1X

    // Meses 01 al 09
    CPI R16, 2           // Febrero
    BREQ RTC_LIM_28
    CPI R16, 4           // Abril
    BREQ RTC_LIM_30
    CPI R16, 6           // Junio
    BREQ RTC_LIM_30
    CPI R16, 9           // Septiembre
    BREQ RTC_LIM_30
    RJMP RTC_LIM_31      // Los demás de un dígito tienen 31

RTC_MES_1X:
    CPI R16, 1           // Noviembre
    BREQ RTC_LIM_30
    RJMP RTC_LIM_31      // Octubre y Diciembre

RTC_LIM_28:
    CPI R20, 2
    BRNE GUARDAR_RTC_DIAS
    CPI R19, 9           // Si llegó a 29, salta de mes
    BREQ RTC_NUEVO_MES
    RJMP GUARDAR_RTC_DIAS

RTC_LIM_30:
    CPI R20, 3
    BRNE GUARDAR_RTC_DIAS
    CPI R19, 1           // Si llegó a 31, salta de mes
    BREQ RTC_NUEVO_MES
    RJMP GUARDAR_RTC_DIAS

RTC_LIM_31:
    CPI R20, 3
    BRNE GUARDAR_RTC_DIAS
    CPI R19, 2           // Si llegó a 32, salta de mes
    BREQ RTC_NUEVO_MES

GUARDAR_RTC_DIAS:
    STS dias_u, R19
    STS dias_d, R20
    RJMP FIN_RTC

// --- CAMBIÓ EL MES ---
RTC_NUEVO_MES:
    LDI R19, 1           // Reiniciamos al día 01
    CLR R20
    STS dias_u, R19
    STS dias_d, R20

    // Ahora sumamos el mes
    LDS R19, meses_u
    LDS R20, meses_d
    INC R19
    CPI R19, 10
    BRNE REVISAR_TOPE_RTC_MES
    CLR R19
    INC R20
REVISAR_TOPE_RTC_MES:
    CPI R20, 1
    BRNE GUARDAR_RTC_MES
    CPI R19, 3           // Si llegó al mes 13...
    BRNE GUARDAR_RTC_MES
    LDI R19, 1           // ...Feliz año nuevo (reinicia a Enero)
    CLR R20

GUARDAR_RTC_MES:
    STS meses_u, R19
    STS meses_d, R20

FIN_RTC:

// --- COMPROBAR ALARMA ---
    LDS R18, segundos
    CPI R18, 0
    BRNE SALIR_RTC_TIMER   // Solo revisamos en el segundo 00

    LDS R19, horas_d
    LDS R20, al_hr_d
    CP R19, R20
    BRNE SALIR_RTC_TIMER

    LDS R19, horas_u
    LDS R20, al_hr_u
    CP R19, R20
    BRNE SALIR_RTC_TIMER

    LDS R19, minutos_d
    LDS R20, al_min_d
    CP R19, R20
    BRNE SALIR_RTC_TIMER

    LDS R19, minutos_u
    LDS R20, al_min_u
    CP R19, R20
    BRNE SALIR_RTC_TIMER

    // ¡La hora coincide! Encendemos la bandera de la alarma (Bit 0)
    LDS R19, banderas
    ORI R19, 0b00000001
    STS banderas, R19

SALIR_RTC_TIMER:


GUARDAR_TIMER:
    STS cont_500ms_L, R16
    STS cont_500ms_H, R17

    POP R31
    POP R30
	POP R20               
    POP R19
    POP R18
    POP R17
    POP R16
    OUT SREG, R16
    POP R16
    RETI
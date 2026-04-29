#ifndef UART_H_
#define UART_H_

#include <avr/io.h>

// Function prototypes
void initUART(void);
void WriteChar(char c);
void writeString(char* string);

#endif /* UART_H_ */
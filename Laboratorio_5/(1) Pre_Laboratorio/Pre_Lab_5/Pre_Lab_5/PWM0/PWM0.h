#ifndef PWM0_H_
#define PWM0_H_

#include <avr/io.h>

void PWM0_init(void);
void PWM0_dca(uint8_t dc, uint8_t modo);

#endif /* PWM0_H_ */
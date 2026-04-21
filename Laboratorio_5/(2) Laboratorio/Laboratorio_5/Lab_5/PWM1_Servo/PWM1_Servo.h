#ifndef PWM1_SERVO_H_
#define PWM1_SERVO_H_

#include <avr/io.h>

void PWM1_init(void);
void PWM1_update(uint16_t adc_val);

#endif /* PWM1_SERVO_H_ */
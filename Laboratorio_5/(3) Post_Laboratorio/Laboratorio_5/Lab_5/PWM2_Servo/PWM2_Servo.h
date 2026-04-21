#ifndef PWM2_SERVO_H_
#define PWM2_SERVO_H_

#include <avr/io.h>

void PWM2_init(void);
void PWM2_update(uint16_t adc_val);

#endif /* PWM2_SERVO_H_ */
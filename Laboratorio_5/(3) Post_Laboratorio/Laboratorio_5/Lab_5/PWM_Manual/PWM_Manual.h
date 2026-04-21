#ifndef PWM_MANUAL_H_
#define PWM_MANUAL_H_

#include <avr/io.h>

void PWM_Manual_init(void);
void PWM_Manual_update(uint16_t adc_val);

#endif /* PWM_MANUAL_H_ */
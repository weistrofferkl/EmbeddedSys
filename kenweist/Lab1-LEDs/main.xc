/*
 * main.xc
 *
 *  Created on: Sep 14, 2017
 *      Author: kenda
 */
#include <xs1.h>
#define FLASH_DELAY (XS1_TIMER_HZ/10)

out port oLEDs = XS1_PORT_32A;

int main(){
    timer tmr;
    unsigned int t;
    unsigned pattern = 0b00000000100000000000;
    tmr :> t;
    while(1){
        oLEDs <: pattern;
        t += FLASH_DELAY;
        tmr when timerafter(t) :> void;
        pattern = ~pattern;
    }
    return 0;

}


/*
 * Lab02-SimSetup.xc
 *
 *  Created on: Sep 21, 2017
 *      Author: kenda
 */


#include <xs1.h>
#include <print.h>
#include "utility.h"
#include <stdio.h>

#define TICKS_PER_MS (XS1_TIMER_HZ/1000)

in port iButton = XS1_PORT_1C;
out port oButtonSim = XS1_PORT_1B;

int test() {
    char buffer[64];
// BEGIN TEST CASES
    format_message(buffer,TICKS_PER_MS,50*TICKS_PER_MS);
    printstr ( buffer );
    format_message( buffer , 900*TICKS_PER_MS, TICKS_PER_MS);
    printstr ( buffer );
// END TEST CASES
}
void monitor_button(){


    unsigned value;
    unsigned int t;
    unsigned int t2;

    timer tmr;
    char buffer[64];
    iButton when pinsneq(0) :> value; //when button is pressed set value to 0
    while(1){

       iButton when pinseq(0) :> void;
       tmr:>t;
       iButton when pinseq(1) :> void;
       tmr:>t2;
       format_message(buffer, t, t2);
       printstr(buffer);

    }

}

void button_simulator(){
    //signal to oButtonSim that pin is intially high
    //inf. loop:
        //signal on oButtonSim to low
        //wait 1ms*iteration number
        //send signal on oButtonSUm to high
        //wait .5 Ms


    unsigned iteration = 1;
    unsigned t;
    timer tmr;
    tmr:>t;
    oButtonSim <: 1;

    while(1){
        oButtonSim <: 0;
        printf("Iteration: %u\n", iteration);
        t+= iteration*(TICKS_PER_MS);
        tmr when timerafter(t):>t;
        oButtonSim <: 1;
        t+= (TICKS_PER_MS/2);
        tmr when timerafter(t):>t;
        iteration++;

    }

}

int main(){

    par{
        monitor_button();
        button_simulator();
    }
}


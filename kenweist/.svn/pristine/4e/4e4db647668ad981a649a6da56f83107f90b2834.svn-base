/*
 * main.xc
 *
 *  Created on: Sep 14, 2017
 *      Author: kenda
 */
#include <xs1.h>
#include <stdio.h>
#include <math.h>

in port iButton = XS1_PORT_32A; //32 bit vector
out port oLed = XS1_PORT_1A;
unsigned value = 0b0;


unsigned int compute_difference(unsigned int t0, unsigned int t1){

    if(t1 > t0){
        return ((t1-t0));
    }
    return ((t0-t1));


}
int main(){
    unsigned int oldButton;
    float timeSecs;
    unsigned timeMS;
    iButton :> value;
    timer tmr;
    unsigned int t;
    unsigned int t2;

    while(1){

        iButton :> oldButton;
        iButton when pinsneq(value) :> value;

        if((value&1) == (oldButton&1)){}
        else if ((value&1) < (oldButton&1)){
            //want to turn on LED if value < oldValue
            //as then we have a state change
            oLed <: 1;
            tmr :> t;
        }

        else {
        //turn off LED

            oLed <: 0;
            tmr :> t2;
            timeMS = compute_difference(t,t2);
            timeSecs = (float)compute_difference(t,t2)*pow(10,-6)/100;
            printf("Delay was %u microseconds (%.6f seconds)\n",timeMS,timeSecs);
        }



    }
}

int main_sampling(){

    while(1){
        int value;
        iButton :> value;
        if (value%2==0){

            oLed <: 1;
        }
        else {
        //turn off LED

            oLed <: 0;
        }


    }
}

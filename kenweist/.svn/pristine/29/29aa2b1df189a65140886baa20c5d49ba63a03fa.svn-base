/*
 * main.xc
 *
 *  Created on: Sep 16, 2017
 *      Author: Kendall Weistroffer
 *      Assignment: Homework #1, Embedded Systems
 *      Due: Sept. 21 @ 2pm
 */
#include <xs1.h>
#include <stdio.h>
#include<stdlib.h>


#define FLASH_DELAY (XS1_TIMER_HZ/2)
#define overflowConstant 0xFFFFFFFF
in port iButton = XS1_PORT_32A;
out port oLed = XS1_PORT_1A;
out port oLed2 = XS1_PORT_1D;
int times[10];

//Method from the lab used to compute the difference between two timestamps
unsigned int compute_difference(unsigned int t0, unsigned int t1){

    if(t1 > t0){
        return ((t1-t0))/100; //dividing by 100 to get the time in microseconds
    }
    return (overflowConstant-(t0-t1))/100;
}

//Used to insert an element into a specific position within an array
void insertArray(unsigned diff, unsigned pos, int* times){
    times[pos] = diff;
}

//Used to sort the array and to print out the desired information using math
int computeStats(int times[]){

    //Bubble Sort:
    int i,j;
    for(i = 0; i<9;i++){
        for(j =0; j<9-i;j++){
            if(times[j] > times[j+1]){

                int temp = times[j];
                times[j] = times[j+1];
                times[j+1] = temp;
            }
        }
    }

    //Grab desired stats:
    unsigned min = times[0];
    unsigned max = times[9];
    unsigned median = (times[4]+times[5])/2;
    unsigned avg = 0;

    //compute the avg.
    for(i = 0; i< 10; i++){
        avg+=times[i];
    }
    avg = avg/10;

    //print dat shit out!
    printf("Stats in Microseconds: \n");
    printf("Min: %u\n", min);
    printf("Max: %u\n", max);
    printf("Median: %u\n", median);
    printf("Avg: %u\n", avg);

    return 0;
}

//Used to toggle the 3 initial flashes at the beginning of each sequence
unsigned int toggleLight(int flashes, int pattern, timer tmr){
    unsigned int t;
    tmr :> t;
    unsigned int result;

    for(int i = 0; i<flashes*2; i++){
        t+=FLASH_DELAY;
        tmr when timerafter(t):> result;
        pattern = ~pattern;

        oLed <: pattern;
        oLed2 <: pattern;
    }
    return result;
}

int main(){

 unsigned pattern = 0b0;

 unsigned t;
 unsigned t2;
 unsigned value;
 unsigned diff;
 unsigned delay;
 unsigned pos = 0;
 timer tmr;

 iButton :> value;
 tmr :> t;
 while(1){
    //3 initial flashes:
    t = toggleLight(3, pattern, tmr);

    //turn the LEDs on after the random delay has passed:
    delay = XS1_TIMER_HZ+rand()%XS1_TIMER_HZ;
    t+=delay;
    tmr when timerafter(t):> t;

    oLed<:1;
    oLed2<:1;


    //When the button has been pressed:
    iButton :>value;
    iButton when pinsneq ( value ) :> value ;
    if((value&1) != 1 ){

        //record the reacton timestamp & use it to compute
        //& save the difference:
        tmr :>t2;
        diff = compute_difference(t,t2);

        insertArray(diff, pos, times);
        pos++;

        //if we have seen 10 reaction-times, then we want to compute the stats
        //and then continue:
        //Used this for debugging, may help with ensuring grading:
        //printf("POS, DIFF: %u %u\n", pos, diff);

        if(pos == 10){
            computeStats(times);
            pos = 0;
            //break;
        }
        //if we haven't seen the required 10 reactions, then we want to turn
        //off the LEDs and wait for a second before restarting the process:
        oLed <: 0;
        oLed2 <:0;
        t += XS1_TIMER_HZ;
        tmr when timerafter(t):> t;
    }
    else{}

 }
 return 0;

}

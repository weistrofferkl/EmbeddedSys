/*
 * utility.c
 *
 *  Created on: Sep 21, 2017
 *      Author: kenda
 */
#include <math.h>
#include <xs1.h>
#include <stdio.h>


#define OVERFLOWCONSTANT 0xFFFFFFFF

unsigned int timer_diff (unsigned int t0 , unsigned int t1 ){
    if(t1 > t0){

          return (t1-t0);
          //Not dividing by 100 to get the time in microseconds, we want ticks!
      }

      return (OVERFLOWCONSTANT-(t0-t1));
}

void format_message(char buffer [] , unsigned int t0 , unsigned int t1 ){
    //use timer_diff to calcualte number of ticks
    //use sprintf to furmat a string into bugger char array

    float diff = timer_diff(t0,t1)/100000000.0; // gets diff in seconds
    sprintf(buffer, "Difference was %.6f seconds!\n", diff);

}

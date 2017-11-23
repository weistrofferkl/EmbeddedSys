/*
 * HW02-HotPotato.xc
 *
 *  Created on: Sep 22, 2017
 *      Author: kenda
 */

#define TICKS_PER_US (XS1_TIMER_HZ/1000000)
#define TICKS_PER_MS (XS1_TIMER_HZ/1000)
#include <xs1.h>
#include <stdio.h>
#include <print.h>

in port iButton1 = XS1_PORT_1C;
out port oButtonSim1 = XS1_PORT_1A;

void button_listener_task (chanend left , chanend right ){
    //wait for pin to go high
    iButton1 when pinseq(1) :> void;
    timer tmr;
    unsigned t;
    unsigned token;
    int toggled=0;

   // printf("IN button listener");

    while(1){
        //use select monitor button pin, channels and timer
        tmr :> t;
        t += 2*TICKS_PER_MS;

        select{

            case tmr when timerafter(t):>t:
                return;

            case left :> token:

                if(toggled == 1){
                   left <: token;
                   toggled = 0;

                }
                else{
                    right <: token;
                    //toggled = 0;

                }
                break;

            case right :> token:

                if(toggled == 1){
                    right <: token;
                    toggled = 0;

                }
                else{
                    left <: token;
                    //toggled = 0;
                }
                break;

            case iButton1 when pinseq(0) :> void:
               // iButton1 when pinseq(1) :> void;
              //  printf("In the ibutton");
               toggled = 1;
                break;


        }

    }

}

void button_simulator(){
    unsigned t;
    timer tmr;
    tmr:>t;
    oButtonSim1 <: 1;
    char buffer[64];

    while(1){
        t+= TICKS_PER_US;
        tmr when timerafter(t):>t;

        oButtonSim1 <: 0;
        sprintf(buffer, "Button pressed\n");
        printstr(buffer);
        t+= TICKS_PER_US;
        tmr when timerafter(t):>t;

        oButtonSim1 <: 1;
        return;

    }
  //  return;

}

void worker(unsigned int worker_id , chanend left , chanend right ){
//use select to listen on both right channels simultaneously
//when token arrives, increment token & format message using sprintf, and then printstr
//delay 10 MS
//pass new token to other channel
//return if new val of token is > 10 OR if task has not rec. token in 1 MS
//if worker_ID = 1, introduce a token w/value of 1 to channel on the right --> start

    unsigned token;
    char buffer[64];
    timer tmr;
    unsigned t;
    if(worker_id == 1){
      token = 1;
      sprintf(buffer, "Worker ID: %u, Token Initalized, value: %u\n", worker_id, token);
      printstr(buffer);
      right <: token;
    }

    while(1){
        tmr :> t;

        select{
            case tmr when timerafter(t+TICKS_PER_MS):>t:
                    return;

            case left :> token:
                token++;
                if(token > 10){
                    return;
                }
                sprintf(buffer, "Worker ID: %u, Token arrived at channel left, value: %u\n", worker_id, token);
                printstr(buffer);
                tmr :> t;
                t+= 10*TICKS_PER_US;
                tmr when timerafter(t):>t;
                right <: token;
                break;

            case right :> token:
                token++;
                if(token > 10){
                  return;
                }
                sprintf(buffer, "Worker ID: %u, Token arrived at channel right, value: %u\n", worker_id, token);
                printstr(buffer);
                tmr :> t;
                t+= 10*TICKS_PER_US;
                tmr when timerafter(t):>t;
                left <: token;
                break;
        }

    }
}

int main(){

    chan one;
    chan two;
    chan three;
    chan four;

    par{
        button_listener_task(one, two);
        worker(1,two,three);
        worker(2,three, four);
        worker(3,four,one);
        button_simulator();
    }


}

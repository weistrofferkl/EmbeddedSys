/*
 * Lab02-Channels.xc
 *
 *  Created on: Sep 21, 2017
 *      Author: kenda
 */
#include <xs1.h>
#include <print.h>
#include <stdio.h>


in port iButton1 = XS1_PORT_1C;
in port iButton2 = XS1_PORT_1D;
out port oButtonSim1 = XS1_PORT_1A;
out port oButtonSim2 = XS1_PORT_1B;
#define TICKS_PER_MS (XS1_TIMER_HZ/1000)

void display_output(chanend c){

    while(1){
        int readStore;
        char buffer[64];


        c :> readStore;
        sprintf(buffer, "Button %i was pressed\n", readStore);
        printstr(buffer);
    }
}
void monitor_buttons(chanend c){
    iButton1 when pinseq(1) :> void;
    iButton2 when pinseq(1) :> void;
    int val;

    while(1){

        select{
            case iButton1 when pinseq(0) :> void:
                val = 1;
                iButton1 when pinseq(1) :> void;
                c <:1;
                break;
            case iButton2 when pinseq(0) :> void:
                val = 2;
                iButton2 when pinseq(1) :> void;
                c<:2;
                break;

        }


    }



}
void button_simulator(){

    oButtonSim1 <: 1;
    oButtonSim2 <: 1;
    int iteration = 1;
    unsigned int t;
    timer tmr;
    tmr:>t;
    while(1){
        if(iteration%2==0){
                oButtonSim2 <: 0;
            }else{
                oButtonSim1 <: 0;

            }
            t+=TICKS_PER_MS;
            tmr when timerafter(t):>t;
            oButtonSim1 <:1;
            oButtonSim2<:1;
            iteration++;

        }
}

int main(){

    chan c1;
    par{
        display_output(c1);
        monitor_buttons(c1);
        button_simulator();
    }
}

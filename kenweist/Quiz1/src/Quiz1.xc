/*
 * Quiz1.xc
 *
 *  Created on: Sep 26, 2017
 *      Author: kenda
 */
#include <xs1.h>
#include <stdio.h>
#include <print.h>

in port port0 = XS1_PORT_1F;
void monitor_pin(in port iPort){
    //ensure monitor is initially set to be low
    //as value is 0 when idle in "Nomal Mode"
    iPort when pinseq(0) :> void;

    //return high-low pulses when sampled continuesly
    while(1){
        //output goes high then low when triggered:
            //wait for input to come in as high
        iPort when pinseq(1):> void;
            //wait for input to come in as low
        iPort when pinseq(0):> void;
              //this indicates movement:
        printf("MOVEMENT");

    }

}

int main(){
    monitor_pin(port0);


}

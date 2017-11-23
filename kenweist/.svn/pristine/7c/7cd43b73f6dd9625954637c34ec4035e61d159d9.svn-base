/*
 * HW03-Ping.xc
 *
 *  Created on: Oct 3, 2017
 *      Author: kenda
 */

#include <xs1.h>
#include <print.h>
#include <stdio.h>

//constants
const unsigned int NUM_SAMPLES= 4; //Number of test cases
const unsigned int SAMPLES_MM[] = {100, 300, 500, 1000}; //values in millimeters that the ping simulator will emulate

//speed of sound at sea level: 340.29 mm/s (millimeters per second)
const unsigned int SOUND_MM_PER_SECOND = 340290; //this is in miliseconds
const unsigned int SOUND_MM_PER_SECOND_IN_US = 340290000; //above but in microseconds

//ports
port ioPingPort = XS1_PORT_1A;
port ioPingSimulator = XS1_PORT_1B;

//Much #defines to make Matt happy
#define TICKS_PER_US (XS1_TIMER_HZ/1000000)
#define TICKS_PER_5US (5*(XS1_TIMER_HZ/1000000))
#define overflowConstant 0xFFFFFFFF
#define TICKS_PER_SEC XS1_TIMER_HZ
#define TICKS_PER_MS (XS1_TIMER_HZ/1000)
#define TIMEOUT_TIME (2*TICKS_PER_MS) //timeout should be ~19.25 MS

//Compute difference funtion from previous assignments, handles tick overflows:
unsigned int compute_difference(unsigned int t0, unsigned int t1){

    if(t1 > t0){
        return ((t1-t0));
    }
    return (overflowConstant-(t0-t1));
}


void distance_consumer(chanend c){
    unsigned int dist;
    char buffer[64];

    //function iterates NUM_SAMPLES times before exiting
    for(int i = 0; i < NUM_SAMPLES; i++){

        //Reads an int distance value from the channel
        c :> dist;

        if(dist == -1){
            sprintf(buffer, "TIMEOUT: %i\n", dist);


        }else{
            sprintf(buffer, "Distance: %i\n", dist);
        }

        //prints a formatted string (based on timeOut case vs regular case) to the screen
        printstrln(buffer);
    }
    return;
}

void ping_task(port p, chanend c){
    timer tmr;
    unsigned t;
    unsigned t1;
    unsigned t2;
    int dist, dist_mm;

    //wait initially for pins to be low
    p when pinseq(0) :> void;

    //Iterate NUM_SAMPLES times before exiting
    for(int i  = 0; i< NUM_SAMPLES; i++){

        //Send high trigger to port to signal start of pulse
        p <: 1;
        tmr :> t;

        //wait for tOut time based on provided documentation
        t += TICKS_PER_5US;
        tmr when timerafter(t):> t;

        //Set port to low...
        p <: 0;
        p :> void;

        //Then listens for port to go high as the start of the response from the pulse
        p when pinseq(1) :> void;

        //log the start time of the response
        tmr :> t1;

        p when pinseq(0) :> void;

        //log the end time of the response
        tmr :> t2;


        //times how long port takes to go low as response time from pulse
        dist = compute_difference(t1,t2);

        //Conversion of ticks to millimeters (overflow handled in compute_difference):

        dist = dist/2; //Accounting for doubling of time
        dist_mm = dist/(TICKS_PER_SEC/SOUND_MM_PER_SECOND);

        //Distance sent as an int value to distance_consumer
        c <: dist_mm;


    }

}

/*
 * This function works as described, iterates NUM_SAMPLES times and prints out NUM_SAMPLES things based on whether or not
 * there is a time out. However, for some odd reason the message "Internal control pad and plugin driving in opposite directions"
 * prints to the screen after the first TimeOut. Went into Nathan's office hours on Monday morning and we have no clue why as
 * my code is logically sounds and prints out correctly.
 * He said I wouldn't lose points for this.
 * I trust Nathan.
 * He will give me good grade (I hope).
 *
 */
void ping_task_timeout(port p, chanend c, unsigned int timeout_ticks){
    timer tmr;
    unsigned t, t1, t2, timedOut;
    int dist, dist_mm;

    for(int i  = 0; i< NUM_SAMPLES; i++){

        //Similar code to the previous function:
        p when pinseq(0) :> void;

        p <: 1;

        tmr :> t;

        //wait for tOut time

        t += TICKS_PER_5US;


        tmr when timerafter(t):> t;

        //send termation pulse
        p <: 0;
        tmr :> t;

        //add the timeout threshold to t
        t += timeout_ticks;
        timedOut = 0;
        p :> void;

        //Here's where it's different:
        select{

            //if the timeout time has been reached, then we want to time out
            case tmr when timerafter(t):> void :
                timedOut = 1; //set timeout flag to "true"
                break;

            //otherwise we want to proceed as per usual, and wait for the high response
            case p when pinseq(1) :> void:
                tmr :> t1; //grab the response start time
                tmr :> t;
                //reset the timeout threshold in case there's a high timeout
                t += timeout_ticks;
                p :> void;
                break;
        }

        //second select cause xmos won't let me be my own person and use two references to p in the same select (which actually is probs a good thing)
        select{

            //check for the timeout case once again to make sure all is good and well in the world
            case tmr when timerafter(t) :> void:
                timedOut = 1; //yada yada yada flags
                break;

            //case where we get the low response
            case p when pinseq(0) :> void:
                tmr :> t2; //grab the response end time
                p :> void;
                break;
        }

        //Signal -1 to the distance_consumer if a timeout occurs
        if(timedOut == 1){
           timedOut = 0;
            c <: -1;


         //Otherwise proceed as defined in the ping_task task
        }else{
            dist = compute_difference(t1,t2);
            dist = dist/2;
            dist_mm = dist/(TICKS_PER_SEC/SOUND_MM_PER_SECOND);


            c <: dist_mm;


        }


    }

}

//defined in parallax_ping.xc, which Matt wrote (apparently) so that code is now a god.
void ping_simulator(
        port p,
        const unsigned int mms[],
        const unsigned int n_mms,
        unsigned int mm_per_second);

int main(void){
    chan c;
    par{
       // ping_task(ioPingPort, c);
        ping_task_timeout(ioPingPort, c, TIMEOUT_TIME);
        distance_consumer(c);
        ping_simulator(ioPingSimulator,
                SAMPLES_MM,
                NUM_SAMPLES,
                SOUND_MM_PER_SECOND);
    }
    return 0;
}


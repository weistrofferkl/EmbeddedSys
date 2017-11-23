/*
 * Quiz2.xc
 *
 *  Created on: Oct 3, 2017
 *      Author: kenda
 */

#define overflowConstant 0xFFFFFFFF

unsigned float compute_difference(unsigned int t0, unsigned int t1){

    if(t1 > t0){
        return ((t1-t0))/100; //dividing by 100 to get the time in microseconds
    }
    return (overflowConstant-(t0-t1))/100;
}
float read_pwm(in port iPort){
    //assuming 1ms frame
    timer tmr;
    int t, t2, t3, t4;
    float hightime;

    float totaltime;

    tmr :> t;


        iPort when pinseq (1) :> void;
        tmr :> t2;

        iPort when pinseq(0) :> void;
        tmr :> t3;


        tmr :> t4;

        hightime = compute_difference(t2, t3);
        totaltime = compute_difference(t, t4);

        return hightime/totalTime;

    }



    //time spent on: t3 - t2
    //total time: t4 - t




}

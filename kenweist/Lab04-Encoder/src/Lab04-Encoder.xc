/*
 * Lab04-Encoder.xc
 *
 *  Created on: Oct 7, 2017
 *      Author: kenda
 */

#include <xs1.h>
#include <print.h>
#include <stdio.h>

#define BIN1_ON 0b0010
#define BIN2_ON 0b1000
#define AIN1_ON 0b0100
#define AIN2_ON 0b0001
out port oMotorPWMA = XS1_PORT_1P;
out port oMotorPWMB = XS1_PORT_1I;
out port oMotorControl = XS1_PORT_4D;

out port oLED1 = XS1_PORT_1A;
out port oLED2 = XS1_PORT_1D;
out port oSTB = XS1_PORT_1O;

in port iEncoder = XS1_PORT_4C;
//mask : 0b0010 for 4C1
//mask : 0b0001 for 4C2

        //sig1 = d15
        //sig2 = d20 or d14

#define TICKS_PER_US (XS1_TIMER_HZ/1000000)
#define TICKS_PER_MS (XS1_TIMER_HZ/1000)
#define PWM_FRAME_TICKS TICKS_PER_MS
#define TICKS_PER_SEC XS1_TIMER_HZ

void motor_task_static(out port oMotorPWM, out port oMotorControl, unsigned int control_mask, unsigned int duty_cycle){
    //oMotorPWM = output port of PWM pin
    //oMotorControl = output port of 4-bit motor control pins
    //control_mask = bit-pattern to be sent to motor controller
    //duty_cycle = duty cycle in percent (ie number between 0 and 100 inclusive)

    timer tmr;
    unsigned t;
    unsigned frameHigh = (duty_cycle*PWM_FRAME_TICKS)/100;
    unsigned frameLow = PWM_FRAME_TICKS - frameHigh;
    //set spec. control mask to motor control port
    //set oSTBY port to 1
    oMotorControl <: control_mask;
    oSTB <: 1;

    //in inf. loop:
        //send PWM to motor using PWM_FRAME_TICKS for size of each PWM frame

    //dutycycle*pwm/100
    while(1){
        oMotorPWM <: 1;
        tmr :> t;
        t += frameHigh;

        tmr when timerafter(t) :> void;

        oMotorPWM <: 0;
        tmr :> t;
        t += frameLow;

        tmr when timerafter(frameLow) :> void;
    }



}

void encoder_task(in port iEncoder, out port oLED1, out port oLED2){
    //monitor iencoder port, light LEDs oLED1 when 1 and 0 is off

    int output;

    while(1){

        iEncoder :> output;

        if((output & 0b0010) == 2){
            oLED2 <: 1;
        }
        else {
            oLED2 <: 0;
        }

        if((output & 0b0001) == 1){
            oLED1 <: 1;
        }
        else{
            oLED1 <: 0;
        }
    }
}


int main(){
    oSTB <: 1;
    par{
         // motor_task_static(oMotorPWMA, oMotorControl, AIN1_ON, 50);
          encoder_task(iEncoder, oLED1, oLED2);
         // toggle_port(oLED, 2);
      }

    return 0;
}

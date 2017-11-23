/*
 * Lab04-SingleMotor.xc
 *
 *  Created on: Oct 5, 2017
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
out port oLED = XS1_PORT_1A;
out port oSTB = XS1_PORT_1O;

#define TICKS_PER_US (XS1_TIMER_HZ/1000000)
#define TICKS_PER_MS (XS1_TIMER_HZ/1000)
#define PWM_FRAME_TICKS TICKS_PER_MS
#define TICKS_PER_SEC XS1_TIMER_HZ


//Blink the specified LED at specified freq. continuously
void toggle_port(out port oLED, unsigned int hz){
    timer tmr;
    unsigned t;
    int periodLength = hz * XS1_TIMER_HZ; //hz = cycles per second

    oLED <: 0;
    while(1){
        oLED <: 1;
        tmr :> t;
        t += (periodLength/2);
        tmr when timerafter(t):> void;
        oLED <: 0;

        tmr :> t;
        t+= (periodLength/2);
        tmr when timerafter(t) :> void;

    }

}

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

void driver_task(chanend out_motor_cmd_chan, int increment, unsigned int delay_ticks){

    unsigned t,flag = 1;
    int duty = 0;
    timer tmr;
   char buffer[64];


    while(1){

        out_motor_cmd_chan <: duty;
        tmr :> t;
        t+= delay_ticks;

        tmr when timerafter(t) :> void;
        //duty += increment;

        sprintf(buffer, "DUTY: %i, FLAG: %u\n", duty, flag);
        printstr(buffer);

        if((duty + increment >= 100) && flag == 1){
            flag = 0;
            duty = 100;

        }
        else if ((duty - increment <= -100) && flag == 0){
            flag = 1;
            duty = -100;

        }
        else if(flag == 1){
            duty = (duty + increment);

        }
        else if (flag == 0){
            duty = (duty - increment);

        }


    }


}

void motor_task(out port oMotorPWM, out port oMotorControl, unsigned int cw_mask, unsigned int ccw_mask, chanend in_motor_cmd_chan){

       timer tmr,tmr1;
       unsigned t,t1,timeToGo = 0;
       int duty_cycle = 0;
       int holder;
       unsigned frameHigh;// = (duty_cycle*PWM_FRAME_TICKS)/100;



       oMotorControl <: cw_mask;
       oSTB <: 1;

       while(1){

           if(duty_cycle < 0){
               duty_cycle *= -1;
           }

           frameHigh = (duty_cycle*PWM_FRAME_TICKS)/100;
           timeToGo = 0;

           oMotorPWM <: 1;
           tmr :> t;
           tmr1 :> t1;

           t += frameHigh;
           t1 += PWM_FRAME_TICKS;

           while(timeToGo == 0){

               select{
                   case tmr when timerafter(t) :> t:
                       oMotorPWM <: 0;
                       t += XS1_TIMER_HZ;
                       break;

                   case tmr1 when timerafter(t1) :> t1:
                       timeToGo = 1;

                       break;

                   case in_motor_cmd_chan :> holder:
                       if(holder < 0){
                           duty_cycle = holder;
                           oMotorControl <: ccw_mask;
                       }
                       else if(holder > 0){
                           duty_cycle = holder;
                           oMotorControl <: cw_mask;
                       }
                       break;
               }

           }

      }

}

/*int main(){

    par{
        motor_task_static(oMotorPWMA, oMotorControl, AIN1_ON, 50);
        toggle_port(oLED, 2);
    }
    return 0;
}
*/

int main(){
    chan motor_cmd_chan;
    oSTB <: 1;

    par{
        motor_task(oMotorPWMB, oMotorControl, BIN1_ON, BIN2_ON, motor_cmd_chan);
        driver_task(motor_cmd_chan, 5, TICKS_PER_SEC/8);
    }
    return 0;

}
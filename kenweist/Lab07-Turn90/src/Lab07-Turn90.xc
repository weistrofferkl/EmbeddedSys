/*
 * Lab07-Turn90.xc
 *
 *  Created on: Oct 26, 2017
 *      Author: kenda
 */

#include <xs1.h>
#include <stdio.h>
#include <print.h>
#include <string.h>
#include <platform.h>
#include <stdlib.h>
#include <math.h>

#include <mpu6050.h>

out port oWiFiRX = XS1_PORT_1F; //send data
in port iWiFiTX = XS1_PORT_1H; //receive data
out port oSTB = XS1_PORT_1O;
out port oMotorControl = XS1_PORT_4D;
out port oMotorPWMA = XS1_PORT_1P;
out port oMotorPWMB = XS1_PORT_1I;
in port iEncoder = XS1_PORT_4C;
out port oLED1 = XS1_PORT_1A;
out port oLED2 = XS1_PORT_1D;

in  port butP = XS1_PORT_32A;

int fuckWifi;


#define TICKS_PER_US (XS1_TIMER_HZ/1000000)
#define TICKS_PER_MS (XS1_TIMER_HZ/1000)
#define PWM_FRAME_TICKS TICKS_PER_MS
#define TICKS_PER_SEC XS1_TIMER_HZ

#define BAUDRATE 9600
#define BIT_TIME 100000000/BAUDRATE
#define BUFFER_LENGTH 128
#define LINE_DELAY XS1_TIMER_HZ/9
#define MESSAGE_SIZE 128
#define DOUBLE_MESSAGE_SIZE 128*2

#define RIGHT_CCW 0b0010
#define RIGHT_CW 0b1000

#define LEFT_CCW 0b0100
#define LEFT_CW 0b0001


#define DRIVER_HIGH 100
#define DRIVER_HALF_HIGH 50
#define DRIVER_LOW -100
#define DRIVER_HALF_LOW -50
#define MOTOR_HIGH 1
#define MOTOR_LOW 0
#define ENCODER_TWO 2
#define ENCODER_ONE 1
#define LED_HIGH 1
#define LED_LOW 0
#define ENCODER_BTWO 0b0010
#define ENCODER_BONE 0b0001

#define OPORT_LOW 0
#define OPORT_HIGH 1
#define BITS_PER_BYTE 8
#define GOOD_DELAY_MS 400
#define ZERO_DUTY_CYCLE 0
#define RIGHT_TURN_FLAG 0
#define GOOD_TURN_DUTY_CYCLE 35
#define GOOD_TURN_NUM_ROTES 10

#define WIFI_HIGH 1
#define OSTB_HIGH 1

#define TICKS_RESET 0
#define PI 3.14159
#define PI2 2*PI
#define HALFPI PI/2

#define RIGHT_TURN 1
#define LEFT_TURN 0
#define GOOD_ERROR_MARGIN .15


typedef struct{
    char data[MESSAGE_SIZE];
}message_t;

typedef struct{
    char data[DOUBLE_MESSAGE_SIZE];
}newMessage_t;

typedef struct{
    int left_duty_cycle;
    int right_duty_cycle;
}motor_cmd_t;

typedef struct{
    int left_ticks;
    int right_ticks;
}encode_ticks_t;

typedef struct {
    float yaw;
    float pitch;
    float roll;
}ypr_t;

struct IMU imu = {{
        on tile[0]:XS1_PORT_1L,                         //scl
        on tile[0]:XS1_PORT_4E,                         //sda
        400},};


void uart_transmit_byte(out port oPort, char value, unsigned int baudrate){
    timer tmr;
    unsigned t;
    tmr :> t;

    //output start-bit
    oPort <: OPORT_LOW;
    t+= BIT_TIME;
    tmr when timerafter(t) :> void;

    for(int i = 0; i < BITS_PER_BYTE; i++){
        oPort <: >> value;
        t += BIT_TIME;
        tmr when timerafter(t) :> void;
    }


    oPort <: OPORT_HIGH;
    t += BIT_TIME;
    tmr when timerafter(t) :> void;

}


char uart_receive_byte(in port iPort, unsigned int baudrate){
    timer tmr;
    unsigned t;
    char value;
    tmr :> t;

    iPort when pinseq(0) :> void;
    tmr :> t;
    t += BIT_TIME/2;

    for(int i = 0; i < BITS_PER_BYTE; i++){
        t += BIT_TIME;
        tmr when timerafter(t) :> void;
        iPort :> >>value;
    }

    t += BIT_TIME;
    tmr when timerafter(t) :> void;
    iPort :> void;
    return value;

}

void uart_transmit_bytes(out port oPort, const char values[], unsigned int baudrate){

    int i = 0;
    while(values[i] != '\0'){
        uart_transmit_byte(oPort,values[i],baudrate);
        i++;
    }

}

void toggle_port(out port oLED1, unsigned int hz){
    timer tmr;
    unsigned t;
    int periodLength = hz * XS1_TIMER_HZ; //hz = cycles per second

    oLED1 <: OPORT_LOW; //send 0
    while(1){
        oLED1 <: OPORT_HIGH; //send 1
        tmr :> t;
        t += (periodLength/2);
        tmr when timerafter(t):> void;
        oLED1 <: OPORT_LOW;

        tmr :> t;
        t+= (periodLength/2);
        tmr when timerafter(t) :> void;

    }

}

void line(const char buffer[]){
    delay_milliseconds(GOOD_DELAY_MS);
    char newBuffer[BUFFER_LENGTH+2] = {'\0'};
    newBuffer[BUFFER_LENGTH] = '\r';
    newBuffer[BUFFER_LENGTH+1] = '\n';
    timer tmr;
    int t;

    //Append terminating '\r\n' before sending over UART
    for(int i = 0; i<= BUFFER_LENGTH; i++){
        if(i == BUFFER_LENGTH){
            newBuffer[i] = '\r';
            newBuffer[i+1] = '\n';
          //  newBuffer[i+2] = '\0';
            break;

        }
        else if(buffer[i] == '\0'){
            newBuffer[i] = '\r';
            newBuffer[i+1] = '\n';
          //  newBuffer[i+2] = '\0';
            break;
        }
        else{
            newBuffer[i] = buffer[i];
        }
    }


    //Line waits a short delay of ~1/8 of a second before sending string
    tmr :> t;
    t+=LINE_DELAY;
    tmr when timerafter(t):> void;

    //Send the string over UART:
    uart_transmit_bytes(oWiFiRX, newBuffer, BAUDRATE);

}

void multi_motor_task(out port oLeftPWM, out port oRightPWM, out port oMotorControl, chanend in_motor_cmd_chan){
//Function prototype implemented as described^

    motor_cmd_t dutyCycle;
    timer tmrL, tmrL1, tmrR;
    unsigned tL,tL1, tR, timeToGo = 0;
    unsigned frameHighL, frameHighR;
    unsigned left = LEFT_CW , right = RIGHT_CW;
    dutyCycle.left_duty_cycle = ZERO_DUTY_CYCLE;
    dutyCycle.right_duty_cycle = ZERO_DUTY_CYCLE;

    oSTB <: 1;
    oMotorControl <: left|right;

    while(1){

        //Used to send correct duty cycles
        if(dutyCycle.left_duty_cycle < ZERO_DUTY_CYCLE){
            dutyCycle.left_duty_cycle  *= -1;
         }
        if(dutyCycle.right_duty_cycle < ZERO_DUTY_CYCLE){
            dutyCycle.right_duty_cycle *= -1;
         }

        frameHighL = (dutyCycle.left_duty_cycle*PWM_FRAME_TICKS)/100;
        frameHighR = (dutyCycle.right_duty_cycle*PWM_FRAME_TICKS)/100;
        timeToGo = 0;

        oLeftPWM <: MOTOR_HIGH;
        oRightPWM <: MOTOR_HIGH;

        tmrL :> tL;
        tmrL1 :> tL1;

        tmrR :> tR;


        //used for frames for left and right
        tL += frameHighL;
        tR += frameHighR;

        tL1 += PWM_FRAME_TICKS;


        while(timeToGo == 0){
            //Used to run both motors simulateously
            select{
                //Converts duty cycle percentages to timeouts
                case tmrL when timerafter(tL) :> tL:
                    oLeftPWM <: MOTOR_LOW;
                    tL += XS1_TIMER_HZ;
                    break;

                case tmrR when timerafter(tR) :> tR:
                    oRightPWM <: MOTOR_LOW;
                    tR += XS1_TIMER_HZ;
                    break;

                    //TimeOut case
                case tmrL1 when timerafter(tL1) :> tL1:
                    timeToGo = 1;
                    break;

                    //Reads motor_cmd_t commands from the channel w/o effecting duty cycle
                case in_motor_cmd_chan :> dutyCycle:
                    left = 0;
                    right = 0;

                    //Sets Motor Directions from duty cycle ercentages
                    if(dutyCycle.left_duty_cycle < ZERO_DUTY_CYCLE ){
                        left = LEFT_CCW;
                    }
                    else if(dutyCycle.left_duty_cycle > ZERO_DUTY_CYCLE){
                        left = LEFT_CW;
                    }
                    if (dutyCycle.right_duty_cycle < ZERO_DUTY_CYCLE){
                        right = RIGHT_CCW;
                    }
                    else if(dutyCycle.right_duty_cycle > ZERO_DUTY_CYCLE){
                        right = RIGHT_CW;
                    }
                    //Send correct motor directions
                    oMotorControl <: left | right;
                    break;
            }

        }

    }

}

void encoder_task(in port iEncoder, out port oLED1, out port oLED2, chanend outputChan, chanend tickSig){


    unsigned output = 0, prevOutput;
    encode_ticks_t tickCounter;
    tickCounter.right_ticks = TICKS_RESET;
    tickCounter.left_ticks = TICKS_RESET;

    iEncoder :> output;
    prevOutput = output;

    while(1){

        //Function listens for changes on given port

        select{
            case iEncoder when pinsneq(output) :> output:

                if((output & ENCODER_BTWO) != (prevOutput & ENCODER_BTWO)){
                    //Light up appropriate LED
                    oLED2 <: LED_HIGH;
                    prevOutput = output;

                    tickCounter.left_ticks++;
                }
                else {
                    oLED2 <: LED_LOW;
                }

                if((output & ENCODER_BONE) != (prevOutput & ENCODER_BONE)){
                    //Light up appropriate LED
                    oLED1 <: LED_HIGH;
                    prevOutput = output;
                    tickCounter.right_ticks++;
                }
                else{
                    oLED1 <: LED_LOW;
                }
                break;

        case tickSig :> unsigned holder:
            if(holder == 1){

                tickSig <: tickCounter;

                tickCounter.right_ticks = TICKS_RESET;
                tickCounter.left_ticks = TICKS_RESET;

            }
            break;
        }
    }
}

void goStraightNSigs_ticks(chanend out_motor_cmd_chan, chanend encoderChan, int n, int Lduty, int Rduty){

    motor_cmd_t motors;
    motors.left_duty_cycle = Lduty;
    motors.right_duty_cycle = Rduty;

    unsigned encodeVal = 0, numRotesL = 0,numRotesR = 0;

    while(1){
        out_motor_cmd_chan <: motors;
        encoderChan :> encodeVal;
        if(encodeVal == 1){
            numRotesL++;
        }
        if(encodeVal == 2){
            numRotesR++;
        }
        //Runs the servos for n/8 signals (so in this case we have 5 full rotations)
        if(numRotesL >= n || numRotesR >= n){
            motors.left_duty_cycle = ZERO_DUTY_CYCLE;
            motors.right_duty_cycle = ZERO_DUTY_CYCLE;
            out_motor_cmd_chan <: motors;
            break;
        }

    }
}

void turn_ticks(chanend out_motor_cmd_chan, chanend encoderChan, int direction){
    //0 = right
    //1 = left

    motor_cmd_t dutyCycle;
    unsigned encodeVal = 0, numRotes = 0;
    if(direction == RIGHT_TURN_FLAG){
        //stop right wheel
        dutyCycle.right_duty_cycle = ZERO_DUTY_CYCLE;
        dutyCycle.left_duty_cycle = GOOD_TURN_DUTY_CYCLE;

    }
    else{
        //stop left wheel
        dutyCycle.left_duty_cycle = ZERO_DUTY_CYCLE;
        dutyCycle.right_duty_cycle = GOOD_TURN_DUTY_CYCLE;
    }

    while(1){
    out_motor_cmd_chan <: dutyCycle;
    encoderChan :> encodeVal;

    if(encodeVal == 1 && direction ==1){
        //Left
        numRotes++;
    }
    if(encodeVal == 2 && direction ==0){
        //Right
        numRotes++;
    }
    if(numRotes > GOOD_TURN_NUM_ROTES){
        dutyCycle.left_duty_cycle = ZERO_DUTY_CYCLE;
        dutyCycle.right_duty_cycle = ZERO_DUTY_CYCLE;
        out_motor_cmd_chan <: dutyCycle;
        break;
    }

    }

}
void move_car(chanend out_motor_cmd_chan, int LDuty, int RDuty){
    motor_cmd_t dutyCycle;

    dutyCycle.left_duty_cycle = LDuty;
    dutyCycle.right_duty_cycle = RDuty;

    out_motor_cmd_chan <: dutyCycle;
}

void turn90Deg(chanend out_motor_cmd_chan, int rightTurnFlag, chanend YPR){
    //change yaw
    ypr_t YPRoll;
    motor_cmd_t dutyCycle;

    YPR <: 1;
    YPR :> YPRoll;

    float curYaw;
    float holderYaw;

    curYaw = YPRoll.yaw;
    float newYaw;

    //RIGHT TURN:
    if(rightTurnFlag == RIGHT_TURN){

        //Calculate our new ending Yaw-Value:
        newYaw = curYaw + (HALFPI);

        if(newYaw > (PI2)){
            holderYaw = newYaw - PI2;

            //Using Bang-Bang implementation discussed in class:
            while((curYaw < ((2*PI)-GOOD_ERROR_MARGIN)) && (curYaw > GOOD_ERROR_MARGIN)){
                dutyCycle.left_duty_cycle = ZERO_DUTY_CYCLE;
                dutyCycle.right_duty_cycle = GOOD_TURN_DUTY_CYCLE;
                out_motor_cmd_chan <: dutyCycle;

                //Resample to update the yaw for each iteration
                YPR <: 1;
                YPR :> YPRoll;
                curYaw = YPRoll.yaw;
            }
            curYaw = 0;

            //Turn the rest of the way:
            while(curYaw < (holderYaw+GOOD_ERROR_MARGIN)){

                dutyCycle.left_duty_cycle = ZERO_DUTY_CYCLE;
                dutyCycle.right_duty_cycle = GOOD_TURN_DUTY_CYCLE;
                out_motor_cmd_chan <: dutyCycle;

                YPR <: 1;
                YPR :> YPRoll;
                curYaw = YPRoll.yaw;
            }

            //stop the car after the turn:
            dutyCycle.left_duty_cycle = ZERO_DUTY_CYCLE;
            dutyCycle.right_duty_cycle = ZERO_DUTY_CYCLE;
            out_motor_cmd_chan <: dutyCycle;
        }

        //Normal Turn Case:
        else if (newYaw < (PI2)){

            while(curYaw < newYaw){

                dutyCycle.left_duty_cycle = ZERO_DUTY_CYCLE;
                dutyCycle.right_duty_cycle = GOOD_TURN_DUTY_CYCLE;
                out_motor_cmd_chan <: dutyCycle;

                YPR <: 1;
                YPR :> YPRoll;
                curYaw = YPRoll.yaw;
            }

            dutyCycle.left_duty_cycle = ZERO_DUTY_CYCLE;
            dutyCycle.right_duty_cycle = ZERO_DUTY_CYCLE;
            out_motor_cmd_chan <: dutyCycle;
        }
    }

    //LEFT TURN:
    else{

        //Calculate our new ending Yaw-Value:
        newYaw = curYaw - (HALFPI);


        if(newYaw < 0 ){
            char buffer[64];

            //mod for floating types x/y fmod(x, y) = x-n*y where n is an int
            newYaw = fmodf(newYaw+PI2, PI2);
            holderYaw = PI2-newYaw;

            //Using the Bang-Bang method here again:
            while((PI2-curYaw > 0) || (curYaw < GOOD_ERROR_MARGIN)){

                dutyCycle.left_duty_cycle = GOOD_TURN_DUTY_CYCLE;
                dutyCycle.right_duty_cycle = ZERO_DUTY_CYCLE;

                out_motor_cmd_chan <: dutyCycle;
                YPR <: 1;
                YPR :> YPRoll;
                curYaw = YPRoll.yaw;

                if(curYaw > PI2-GOOD_ERROR_MARGIN){
                    break;
                }
            }
          //  curYaw = 0;
            curYaw = fmodf(curYaw-holderYaw+PI2, PI2);


            //Turn the rest of the way:
            while(fmodf(curYaw-holderYaw+PI2, PI2) < GOOD_ERROR_MARGIN){

                dutyCycle.left_duty_cycle = GOOD_TURN_DUTY_CYCLE;
                dutyCycle.right_duty_cycle = ZERO_DUTY_CYCLE;
                out_motor_cmd_chan <: dutyCycle;

                YPR <: 1;
                YPR :> YPRoll;
                curYaw = YPRoll.yaw;

            }

            //Stop the motors after the turn:
            dutyCycle.left_duty_cycle = ZERO_DUTY_CYCLE;
            dutyCycle.right_duty_cycle = ZERO_DUTY_CYCLE;
            out_motor_cmd_chan <: dutyCycle;
        }

        else{
            //Normal Left-Turn Case:
            while(curYaw > newYaw){

                dutyCycle.left_duty_cycle = GOOD_TURN_DUTY_CYCLE;
                dutyCycle.right_duty_cycle = ZERO_DUTY_CYCLE;
                out_motor_cmd_chan <: dutyCycle;

                YPR <: 1;
                YPR :> YPRoll;
                curYaw = YPRoll.yaw;


            }
            dutyCycle.left_duty_cycle = ZERO_DUTY_CYCLE;
            dutyCycle.right_duty_cycle = ZERO_DUTY_CYCLE;
            out_motor_cmd_chan <: dutyCycle;
        }
    }
}
void formatCommand(char* charArray, chanend trigger_chan, chanend out_motor_cmd_chan, chanend encoderChan, chanend tickSig, chanend wifiV, chanend YPR){
    encode_ticks_t ticks;
    message_t message;
    ypr_t YPRoll;
    memset(message.data, '\0', MESSAGE_SIZE);


    //Sends "send_wifi_setup" across channel when the start-up message is received:
    if(strcmp(charArray, "lua: cannot open init.lua") == 0){

       sprintf(message.data, "send_wifi_setup");
       trigger_chan <: message;

       wifiV :> fuckWifi;
    }

    else if(fuckWifi != 0){


   //Moves Robot forward at 100 and 50 percent dutyCycle:
    if(strcmp(charArray, "F") == 0){

        move_car(out_motor_cmd_chan, DRIVER_HIGH, DRIVER_HIGH);
        sprintf(message.data, "Moving Forwards at Full Speed\n");
        trigger_chan <: message;
    }
    else if(strcmp(charArray, "f") == 0){

        move_car(out_motor_cmd_chan, DRIVER_HALF_HIGH, DRIVER_HALF_HIGH);
        sprintf(message.data, "Moving Forwards at Half Speed\n");
        trigger_chan <: message;
    }

    //Moves Robot backwards at 100 and 50 percent dutyCycle:
    else if(strcmp(charArray, "R") == 0){
        move_car(out_motor_cmd_chan, DRIVER_LOW, DRIVER_LOW);
        sprintf(message.data, "Moving Backwards at Full Speed\n");
        trigger_chan <: message;
     }
    else if(strcmp(charArray, "r") == 0){
        move_car(out_motor_cmd_chan, DRIVER_HALF_LOW, DRIVER_HALF_LOW);
        sprintf(message.data, "Moving Backwards at Half Speed\n");
        trigger_chan <: message;
     }

    //Turns Robot Left or Right Respectively:
    else if(strcmp(charArray, "<") == 0){
        move_car(out_motor_cmd_chan, ZERO_DUTY_CYCLE, GOOD_TURN_DUTY_CYCLE);
        sprintf(message.data, "Turning Left\n");
        trigger_chan <: message;
    }
    else if (strcmp(charArray, ">") == 0){
        move_car(out_motor_cmd_chan, GOOD_TURN_DUTY_CYCLE, ZERO_DUTY_CYCLE);
        sprintf(message.data, "Turning Right\n");
        trigger_chan <: message;
    }

    //Stops the robot
    else if(strcmp(charArray, "x") == 0){
        move_car(out_motor_cmd_chan, ZERO_DUTY_CYCLE, ZERO_DUTY_CYCLE);
        sprintf(message.data, "STOP DAT BITCH\n");
        trigger_chan <: message;

    }

    //Reports number of ticks since last '?'
    else if(strcmp(charArray, "?") == 0){
        tickSig <: 1;
        tickSig :> ticks;

        //"?" command changed to report YPR Values:
        YPR <: 1;
        YPR :> YPRoll;
        sprintf(message.data, "ENCODER TICKS L: %i, R: %i\n YPR Yaw: %0.2f Pitch: %0.2f Roll: %0.2f\n", ticks.left_ticks, ticks.right_ticks,
                YPRoll.yaw, YPRoll.pitch, YPRoll.roll);

        trigger_chan <: message;

    }

    //"." and "," commands use YPR values to turn left or right ~ 90 degrees:

    //Turn Right 90 Deg.
    else if(strcmp(charArray, ".") == 0){


        turn90Deg(out_motor_cmd_chan, RIGHT_TURN, YPR);
    }

    //Turn Left 90 Deg.
    else if(strcmp(charArray, ",") == 0){

        turn90Deg(out_motor_cmd_chan, LEFT_TURN, YPR);
    }

   //Reports unrecognized commands using WiFi
   else{
       char holder[MESSAGE_SIZE];
       memset(holder, '\0', MESSAGE_SIZE);

       sprintf(holder, "Invalid input: %s \n", charArray);
       strcpy(message.data, holder);
       trigger_chan <: message;

      }
    }

}
void uart_to_console_task(chanend trigger_chan, chanend out_motor_cmd_chan, chanend encoderChan, chanend encodeTicks, chanend wifiV, chanend YPR){
    char charArray[BUFFER_LENGTH+3];
    memset(charArray, '\0', BUFFER_LENGTH+3);

    message_t message;
    memset(message.data, '\0', MESSAGE_SIZE);
    char holder;

    motor_cmd_t motors;
    motors.left_duty_cycle = ZERO_DUTY_CYCLE;
    motors.right_duty_cycle = ZERO_DUTY_CYCLE;
    out_motor_cmd_chan <: motors;


    int i = 0;

    //Runs an Infinite Loop:
    while(1){

        //Each iteration, a single character is read into a buffer array
        holder  = uart_receive_byte(iWiFiTX, BAUDRATE);


        //If either a '\n' or '\r' is received...
        if(holder == '\n' || holder == '\r'){
            holder = '\0';

        }
        //Or the Buffer is full...
        if(holder == '\0' || i == BUFFER_LENGTH-1){

            //The String is null-terminated...
            charArray[i] == '\0';
            //And then processed
            formatCommand(charArray, trigger_chan, out_motor_cmd_chan, encoderChan, encodeTicks, wifiV, YPR );
            printstrln(charArray);

            memset(charArray, '\0', BUFFER_LENGTH);
            i = 0;

        }
        else{
            charArray[i] = holder;
            i++;
        }


    }
}


void send_hello_world_program(){
    line("gpio.mode(3,gpio.OUTPUT)");
    line("while 1 do");
    line("gpio.write(3,gpio.HIGH)");
    line("tmr.delay(1000000)");
    line("gpio.write(3,gpio.LOW)");
    line("tmr.delay(1000000)");
    line("end");
}

void send_wifi_setup() {
    line("wifi.setmode(wifi.SOFTAP)");
    line("");
    line("cfg={}");
    line("cfg.ssid=\"IAMSUDO\"");
    line("cfg.pwd=\"querty123\"");
    line("");
    line("cfg.ip=\"192.168.0.1\"");
    line("cfg.netmask=\"255.255.255.0\"");
    line("cfg.gateway=\"192.168.0.1\"");
    line("");
    line("port=9876");
    line("");
    line("wifi.ap.setip(cfg)");
    line("wifi.ap.config(cfg)");
    line("");
//  line("print(\"ESP8266 TCP to Serial Bridge v1.0 by RoboRemo\")");
//  line("print(\"SSID: \" .. cfg.ssid .. \"  PASS: \" .. cfg.pwd)");
//  line("print(\"RoboRemo app must connect to \" .. cfg.ip .. \":\" .. port)");
//  line("print(\"BaudRate will change now to 115200\")");
    line("");
    line("tmr.alarm(0,200,0,function() -- run after a delay");
    line("");
 //   line("    uart.setup(0, 9600, 8, 0, 1, 1)");
    line("");
    line("    srv=net.createServer(net.TCP, 28800)");
    line("    srv:listen(port,function(conn)");
    line("     ");
    line("        uart.on(\"data\", 0, function(data)");
    line("            conn:send(data)");
    line("        end, 0)");
    line("        ");
    line("        conn:on(\"receive\",function(conn,payload) ");
    line("            uart.write(0, payload)");
    line("        end)");
    line("        ");
    line("        conn:on(\"disconnection\",function(c)");
    line("            uart.on(\"data\")");
    line("        end)");
    line("        ");
    line("    end)");
    line("end)");

}
void output_task(chanend trigger_chan, chanend wifiV){
    message_t holder;
    memset(holder.data, '\0', MESSAGE_SIZE);

    while(1){
            //Reads message_t structs from the channel w/an infinite loop
            trigger_chan :> holder;

            //Call send_wifi_setup() when "send_wifi_setup" is received from channel
            if(strstr(holder.data, "send_wifi_setup")){
                send_wifi_setup();
                wifiV <: 1;
            }

            else{
                char data[MESSAGE_SIZE+2];
                for(int i = 0; i< MESSAGE_SIZE; i++){
                    if (i == MESSAGE_SIZE-1){
                        data[i] = '\r';
                        data[i+1] = '\n';

                        break;
                    }
                    else{
                        data[i] = holder.data[i];
                    }
                }
                //Echos any other data received across the Wifi
                uart_transmit_bytes(oWiFiRX,data, BAUDRATE);
            }
       // send_hello_world_program();
       //send_wifi_setup();

    }
}


void imu_task(chanend YPR){

    ypr_t YawPitchRoll;
    int packetsize,mpuIntStatus,fifoCount;
    int address;
    unsigned char result[64];                           //holds dmp packet of data
    float qtest;
    float q[4]={0,0,0,0},g[3]={0,0,0},euler[3]={0,0,0},ypr[3]={0,0,0};
    int but_state;
    int fifooverflowcount=0,fifocorrupt=0;
    int GO_FLAG=1;

   // printf("Starting MPU6050...\n");
    mpu_init_i2c(imu);
  //  printf("I2C Initialized...\n");
    address=mpu_read_byte(imu.i2c, MPU6050_RA_WHO_AM_I);
  //  printf("MPU6050 at i2c address: %.2x\n",address);
    mpu_dmpInitialize(imu);
    mpu_enableDMP(imu,1);   //enable DMP

    mpuIntStatus=mpu_read_byte(imu.i2c,MPU6050_RA_INT_STATUS);
  //  printf("MPU Interrupt Status:%d\n",mpuIntStatus);
    packetsize=42;                  //size of the fifo buffer
    delay_milliseconds(250);

    //The hardware interrupt line is not used, the FIFO buffer is polled
    while (GO_FLAG){
        mpuIntStatus=mpu_read_byte(imu.i2c,MPU6050_RA_INT_STATUS);
        if (mpuIntStatus >= 2) {
            fifoCount = mpu_read_short(imu.i2c,MPU6050_RA_FIFO_COUNTH);
            if (fifoCount>=1024) {              //fifo overflow
                mpu_resetFifo(imu);
                fifooverflowcount+=1;           //keep track of how often this happens to tweak parameters
                //printf("FIFO Overflow!\n");
            }
            while (fifoCount < packetsize) {    //wait for a full packet in FIFO buffer
                fifoCount = mpu_read_short(imu.i2c,MPU6050_RA_FIFO_COUNTH);
            }
            //printf("fifoCount:%d\n",fifoCount);
            mpu_getFIFOBytes(imu,packetsize,result);    //retrieve the packet from FIFO buffer

            mpu_getQuaternion(result,q);
            qtest=sqrt(q[0]*q[0]+q[1]*q[1]+q[2]*q[2]+q[3]*q[3]);

            if (fabs(qtest-1.0)<0.001){                             //check for fifo corruption - quat should be unit quat
            //    dmp_out <: q[0];
             //   dmp_out <: q[1];
            //    dmp_out <: q[2];
           //     dmp_out <: q[3];

                mpu_getGravity(q,g);
           //     dmp_out <: g[0];
           //     dmp_out <: g[1];
           //     dmp_out <: g[2];

                mpu_getEuler(euler,q);
            //    dmp_out <: euler[0];
            //    dmp_out <: euler[1];
            //    dmp_out <: euler[2];

                mpu_getYawPitchRoll(q,g,ypr);

                YawPitchRoll.yaw = ypr[0] + PI;
                YawPitchRoll.pitch = ypr[1];
                YawPitchRoll.roll = ypr[2];
                int holder = 0;
                select{
                    case YPR :> holder:
                        if(holder == 1){
                            YPR <: YawPitchRoll;
                        }
                        break;
                }
               // YPR <: YawPitchRoll;


            } else {
                mpu_resetFifo(imu);     //if a unit quat is not received, assume fifo corruption
                fifocorrupt+=1;
            }
       }
       butP :> but_state;               //check to see if button is pushed to end program, low means pushed
       but_state &=0x1;
       if (but_state==0){
           printf("Exiting...\n");
           GO_FLAG=0;
       }
    }
    mpu_Stop(imu);      //reset hardware gracefully and put into sleep mode
    printf("Fifo Overflows:%d Fifo Corruptions:%d\n",fifooverflowcount,fifocorrupt);
    exit(0);
}


int main(){

    chan connectorChan;
    chan motor_cmd_chan;
    chan encoderChan;
    chan encodeTicks;
    chan fuckWifi;
    chan YPR;

    oWiFiRX <: WIFI_HIGH; //set high for default state
    oSTB <: OSTB_HIGH;

    par{
        imu_task(YPR);
        uart_to_console_task(connectorChan, motor_cmd_chan, encoderChan, encodeTicks, fuckWifi, YPR);
        output_task(connectorChan, fuckWifi);
        multi_motor_task(oMotorPWMA, oMotorPWMB, oMotorControl, motor_cmd_chan);
        encoder_task(iEncoder, oLED1, oLED2, encoderChan, encodeTicks);
    }
    return 0;
}

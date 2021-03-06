/*
 * Lab06-HelloNodeMCU.xc
 *
 *  Created on: Oct 20, 2017
 *      Author: kenda
 */
#include <xs1.h>
#include <stdio.h>
#include <print.h>
#include <string.h>
out port oLED = XS1_PORT_1A;
out port oWiFiRX = XS1_PORT_1F; //send data
in port iWiFiTX = XS1_PORT_1H; //receive data

#define BAUDRATE 9600
#define BIT_TIME 100000000/BAUDRATE
#define BUFFER_LENGTH 100
#define LINE_DELAY XS1_TIMER_HZ/8


void uart_transmit_byte(out port oPort, char value, unsigned int baudrate){
    timer tmr;
    unsigned t;
    tmr :> t;

    //output start-bit
    oPort <: 0;
    t+= BIT_TIME;
    tmr when timerafter(t) :> void;

    for(int i = 0; i < 8; i++){
        oPort <: >> value;
        t += BIT_TIME;
        tmr when timerafter(t) :> void;
    }


    oPort <: 1;
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

    for(int i = 0; i < 8; i++){
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

void uart_to_console_task(chanend trigger_chan){
    char charArray[BUFFER_LENGTH];
    memset(charArray, '\0', BUFFER_LENGTH);
    char holder;

    int i = 0;

    //Runs an Infinite Loop
    while(1){
        //For each iteration, a single character is read into a buffer array
        holder  = uart_receive_byte(iWiFiTX, BAUDRATE);

        //When Either a '\n' or '\r' is received...
        if(holder == '\n' || holder == '\r'){
            holder = '\0';
        }
        if(strcmp(charArray, "lua: cannot open init.lua") == 0){
            trigger_chan <: 0;
        }

        if(i == BUFFER_LENGTH-1 || holder == '\0'){ // || holder == '\n' || holder == '\r'
            charArray[i] = '\0';

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

void line(const char buffer[]){
    delay_milliseconds(400);
    char newBuffer[BUFFER_LENGTH+2] = {'\0'};
    timer tmr;
    int t;

    for(int i = 0; i<= BUFFER_LENGTH; i++){
        if(i == BUFFER_LENGTH){
            newBuffer[i] = '\r';
            newBuffer[i+1] = '\n';
            break;

        }
        if(buffer[i] == '\0'){
            newBuffer[i] = '\r';
            newBuffer[i+1] = '\n';
            break;
        }
        else{
            newBuffer[i] = buffer[i];
        }
    }

    tmr :> t;
    t+=LINE_DELAY;

    tmr when timerafter(t):> void;
    uart_transmit_bytes(oWiFiRX,newBuffer, BAUDRATE);

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
    line("cfg.ssid=\"kendall\"");
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
void program_board_task(chanend trigger_chan){
    unsigned holder;
    while(1){
        trigger_chan :> holder;
       // send_hello_world_program();
        send_wifi_setup();

    }
}
int main(){

    chan connectorChan;
    oWiFiRX <: 1; //set high for default state
    par{
     //   toggle_port(oLED, 2);
        uart_to_console_task(connectorChan);
        program_board_task(connectorChan);
    }
    return 0;
}

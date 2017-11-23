/*
 * Lab03-UART.xc
 *
 *  Created on: Oct 2, 2017
 *      Author: kenda
 */
#include <xs1.h>
#include <stdio.h>
#include <print.h>
#include <string.h>
#define BAUDRATE 115200
#define BIT_TIME 100000000/BAUDRATE

out port oUartTx = XS1_PORT_1E;
in port iUartRx = XS1_PORT_1F;
//send 8 bits (plus start/stop but) according to protocol
//1 stop bit, 8 bits of data, no parity bit
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

//monitor input port and pack bits into local variable, return the character
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


void uart_transmit_bytes(out port oPort, const char values[], unsigned int n, unsigned int baudrate){

    for(int i = 0; i< n; i++){
        uart_transmit_byte(oPort,values[i],baudrate);

    }

}

void uart_receive_bytes(in port iPort, char values[], unsigned int n, unsigned int baudrate){

   char holder;

   for(int i = 0; i < n ;i++){

       holder = uart_receive_byte(iPort, baudrate);
       values[i] = holder;

   }

}

int main_single(){

    char value;
    char buffer [128];
    oUartTx <: 1; //idle line is high

    par{
        uart_transmit_byte(oUartTx, 'H', BAUDRATE);
        value = uart_receive_byte(iUartRx, BAUDRATE);
    }

    sprintf(buffer, "Value: %c", value);
    printstr(buffer);

    return 0;
}

int main_array(){
    const char message[] = "Hello, Cleveland.";
    char buffer[128];
    oUartTx <: 1;

    par{
        uart_transmit_bytes(oUartTx, message, (strlen(message)+1), BAUDRATE);
        uart_receive_bytes(iUartRx, buffer, (strlen(message)+1), BAUDRATE);

    }
    printstrln(buffer);
    return 0;

}

int main(){
    //return main_single();
    return main_array();

}

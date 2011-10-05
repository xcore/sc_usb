// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xs1.h>
#include <platform.h>
#include <print.h>

#include "xud.h"
#include "usb.h"

#define XUD_EP_COUNT_OUT   2
#define XUD_EP_COUNT_IN    3

#define USB_RST_PORT    XS1_PORT_32A
#define USB_CORE        0


/* Endpoint type tables */
XUD_EpType epTypeTableOut[XUD_EP_COUNT_OUT] = {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL};
XUD_EpType epTypeTableIn[XUD_EP_COUNT_IN] =   {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL, XUD_EPTYPE_INT};

/* USB Port declarations */
on stdcore[USB_CORE]: out port p_usb_rst = XS1_PORT_1I;
on stdcore[USB_CORE]: clock    clk       = XS1_CLKBLK_3;

on stdcore[0]: port ps2_clock = XS1_PORT_1A;
on stdcore[0]: port ps2_data = XS1_PORT_1L;

void Endpoint0( chanend c_ep0_out, chanend c_ep0_in);




inline void XUD_SetNotReady(XUD_ep e)
{
  int chan_array_ptr;
  asm ("ldw %0, %1[0]":"=r"(chan_array_ptr):"r"(e));
  asm ("stw %0, %1[0]"::"r"(0),"r"(chan_array_ptr));
}

extern void setINHandler(chanend s, XUD_ep y);
extern void setOUTHandler(chanend s, XUD_ep y);
extern void enableInterrupts(chanend serv);

void XUD_MYSetReady_Out(XUD_ep e, int x, unsigned bufferPtr)
{
    int chan_array_ptr;
    int xud_chan;
    int my_chan;
    asm ("ldw %0, %1[0]":"=r"(chan_array_ptr):"r"(e));
    asm ("ldw %0, %1[1]":"=r"(xud_chan):"r"(e));
    asm ("ldw %0, %1[2]":"=r"(my_chan):"r"(e));
    asm ("out res[%0], %1"::"r"(my_chan),"r"(1));  

    /* Store buffer pointer */
    asm ("stw %0, %1[5]"::"r"(bufferPtr),"r"(e));
    
    /* Mark EP as ready with ID */
    asm ("stw %0, %1[0]"::"r"(xud_chan),"r"(chan_array_ptr));
}

int XUD_MYGetReady_Out(XUD_ep e, unsigned bufferPtr) {
    int newPtr;
    int tail;
    asm ("ldw %0, %1[5]":"=r"(newPtr):"r"(e));
    asm ("ldw %0, %1[3]":"=r"(tail):"r"(e));
    
    return newPtr - bufferPtr + tail - 16;
}


void handleEndpoints(chanend chan_ep_in, chanend chan_ep_interrupt, chanend chan_ep_out, chanend vcomToDevice, chanend vcomToHost) {
    unsigned addrMyBuffer, addrNotBuffer;
    XUD_ep c_ep_in = XUD_Init_Ep(chan_ep_in);
    XUD_ep c_ep_out = XUD_Init_Ep(chan_ep_out);
    XUD_ep c_ep_interrupt = XUD_Init_Ep(chan_ep_interrupt);

    chan serv;

    unsigned char tmp;
    char myOut[1000];
    char notificationBuffer[7];

    int addrMyOut;
    char bufToDevice[2][256];
    char bufToHost[2][256];
    int hostLen = 0, devLen[2] = {0,0};
    int devRd = 0;
    int devCurrent = 0, hostCurrent = 0;
    int hostWaiting = 0;
    int devWaiting = 0;

    asm("add %0, %1, 0":"=r"(addrNotBuffer): "r" (notificationBuffer));

    setOUTHandler(chan_ep_out, c_ep_out);
    setINHandler(chan_ep_interrupt, c_ep_interrupt);
    setINHandler(chan_ep_in, c_ep_in);

    enableInterrupts(serv);

    outuchar(serv, c_ep_interrupt);
    outuchar(serv, c_ep_in);

//    asm("add %0, %1, 0":"=r"(addrMyOut): "r" (myOut));

//    XUD_MYSetReady_Out(c_ep_out, 0, addrMyOut);                

    asm("add %0, %1, 0":"=r"(addrMyOut): "r" (bufToDevice[!devCurrent]));
    XUD_MYSetReady_Out(c_ep_out, 0, addrMyOut);

    while(1) {
        select {
        case inuchar_byref(serv, tmp):
            if(tmp == (c_ep_interrupt & 0xff)) {
                XUD_SetReady_In(c_ep_interrupt, 0, addrNotBuffer, 0);
            } else if (tmp == (c_ep_in & 0xff)) {
                if (hostLen != 0) {
                    asm("add %0, %1, 0":"=r"(addrMyBuffer): "r" (bufToHost[hostCurrent]));
                    XUD_SetReady_In(c_ep_in, 0, addrMyBuffer, hostLen);
                    hostCurrent = !hostCurrent;
                    hostLen = 0;
                } else {
                    hostWaiting = 1;
                }
            } else if (tmp == (c_ep_out & 0xff)) {
                int l = XUD_MYGetReady_Out(c_ep_out, addrMyOut);
                devLen[!devCurrent] = l;
                if (devLen[devCurrent] == 0) {
                    devCurrent = !devCurrent;
                    devRd = 0;
                    asm("add %0, %1, 0":"=r"(addrMyOut): "r" (bufToDevice[!devCurrent]));
                    XUD_MYSetReady_Out(c_ep_out, 0, addrMyOut);
                } else {
                    devWaiting = 1;
                }
            }
            break;
        case hostLen != 255 => vcomToHost :> char x:
            bufToHost[hostCurrent][hostLen++] = x;
            if (hostWaiting) {
                asm("add %0, %1, 0":"=r"(addrMyBuffer): "r" (bufToHost[hostCurrent]));
                XUD_SetReady_In(c_ep_in, 0, addrMyBuffer, hostLen);
                hostCurrent = !hostCurrent;
                hostLen = 0;
                hostWaiting = 0;
            }
            break;
        case devLen[devCurrent] != 0 => vcomToDevice :> int _:
            vcomToDevice <: (char) bufToDevice[devCurrent][devRd++];
            devLen[devCurrent]--;
            if (devLen[devCurrent] == 0) {
                if (devWaiting) {
                    devCurrent = !devCurrent;
                    devRd = 0;
                    asm("add %0, %1, 0":"=r"(addrMyOut): "r" (bufToDevice[!devCurrent]));
                    XUD_MYSetReady_Out(c_ep_out, 0, addrMyOut);                    
                    devWaiting = 0;
                }
            }
            break;
        }
    }

}


void userThread(chanend vcomToDevice, chanend vcomToHost) {
    timer t;
    unsigned s;
    char a = 'a';
    while(1) {
        char x;
        vcomToDevice <: 0; // send request for char
        vcomToDevice :> x;
        if (x >= 'a' && x <= 'z') x = x - 'a' + 'A';
        vcomToHost <: x;
    }
}

/*
 * The main function fires of three processes: the XUD manager, Endpoint 0,
 * and hid. An array of channels is used for both in and out endpoints,
 * endpoint zero requires both.
 */
int main() 
{
    chan c_ep_out[2], c_ep_in[3], vcom, vcom2;
    par 
    {
        on stdcore[USB_CORE]: XUD_Manager( c_ep_out, XUD_EP_COUNT_OUT, c_ep_in, XUD_EP_COUNT_IN,
                                null, epTypeTableOut, epTypeTableIn,
                                p_usb_rst, clk, -1, XUD_SPEED_HS, null); 
        
        on stdcore[USB_CORE]: Endpoint0( c_ep_out[0], c_ep_in[0]);
        on stdcore[USB_CORE]: handleEndpoints(c_ep_in[1], c_ep_in[2], c_ep_out[1], vcom, vcom2);
        on stdcore[USB_CORE]: userThread(vcom, vcom2);
    }

    return 0;
}

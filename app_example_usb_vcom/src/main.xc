/**
 * Module:  app_l1_usb_hid
 * Version: 1v5
 * Build:   85182b6a76f9342326aad3e7c15c1d1a3111f60e
 * File:    main.xc
 *
 * The copyrights, all other intellectual and industrial 
 * property rights are retained by XMOS and/or its licensors. 
 * Terms and conditions covering the use of this code can
 * be found in the Xmos End User License Agreement.
 *
 * Copyright XMOS Ltd 2010
 *
 * In the case where this code is a modification of existing code
 * under a separate license, the separate license terms are shown
 * below. The modifications to the code are still covered by the 
 * copyright notice above.
 *
 **/                                   
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


char notificationBuffer[7];


inline void XUD_SetNotReady(XUD_ep e)
{
  int chan_array_ptr;
  asm ("ldw %0, %1[0]":"=r"(chan_array_ptr):"r"(e));
  asm ("stw %0, %1[0]"::"r"(0),"r"(chan_array_ptr));
}

#pragma unsafe arrays

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
    
    return newPtr - bufferPtr + tail - 12;
}


void handleEndpoints(chanend chan_ep_in, chanend chan_ep_interrupt, chanend chan_ep_out) {
    unsigned addrMyBuffer, addrNotBuffer;
    XUD_ep c_ep_in = XUD_Init_Ep(chan_ep_in);
    XUD_ep c_ep_out = XUD_Init_Ep(chan_ep_out);
    XUD_ep c_ep_interrupt = XUD_Init_Ep(chan_ep_interrupt);

    chan serv;

    unsigned char tmp;
    char string[] = "\nAaBbCcDdEeFfGgHhIiJj";
    int len = 1;
    char myOut[1000];
    int addrMyOut;
    char bufToDevice[2][256];
    char bufToHost[2][256];
    int hostLen = 0, devLen = 0;
    int hostWr = 0, devRd = 0;
    int devCurrent = 0, hostCurrent = 0;

    asm("add %0, %1, 0":"=r"(addrNotBuffer): "r" (notificationBuffer));

    setOUTHandler(chan_ep_out, c_ep_out);
    setINHandler(chan_ep_interrupt, c_ep_interrupt);
    setINHandler(chan_ep_in, c_ep_in);

    enableInterrupts(serv);

    outuchar(serv, c_ep_interrupt);
    outuchar(serv, c_ep_in);

    asm("add %0, %1, 0":"=r"(addrMyOut): "r" (myOut));

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
                }
            } else if (tmp == (c_ep_out & 0xff)) {
                int l = XUD_MYGetReady_Out(c_ep_out, addrMyOut);
                XUD_MYSetReady_Out(c_ep_out, 0, addrMyOut);
            }
            break;
        case devLen != 0 => vcomToDevice :> int _:
            vcomtToDevice <: bufToDevice[devCurrent][devRd++];
            devLen--;
            break;
        case hostLen != 255 => vcomToHost :> char x:
            bufToHost[hostCurrent][hostLen++] = x;
            break;
        }
    }

}


userThread(chanend vcom_in) {
    timer t;
    unsigned s;
    char a = 'a';
    while(1) {
        char x;
        t when timerafter(s+100000000) :> s;
//        vcom_in <: 0; // send request for char
//        vcom_in :> x;
//        if (x >= 'a' && x <= 'z') x = x - 'a' + 'A';
        vcom_out <: a;
        a++;
        if (a >= 'z') a = 'a';
    }
}

/*
 * The main function fires of three processes: the XUD manager, Endpoint 0,
 * and hid. An array of channels is used for both in and out endpoints,
 * endpoint zero requires both.
 */
int main() 
{
    chan c_ep_out[2], c_ep_in[3], vcom;
    par 
    {
        on stdcore[USB_CORE]: XUD_Manager( c_ep_out, XUD_EP_COUNT_OUT, c_ep_in, XUD_EP_COUNT_IN,
                                null, epTypeTableOut, epTypeTableIn,
                                p_usb_rst, clk, -1, XUD_SPEED_HS, null); 
        
        on stdcore[USB_CORE]: Endpoint0( c_ep_out[0], c_ep_in[0]);
        on stdcore[USB_CORE]: handleEndpoints(c_ep_in[1], c_ep_in[2], c_ep_out[1], vcom);
        on stdcore[USB_CORE]: userThread(vcom);
    }

    return 0;
}

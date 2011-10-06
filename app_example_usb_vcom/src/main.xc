// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xs1.h>
#include <platform.h>
#include <print.h>

#include "xud.h"
#include "usb.h"
#include "xud_interrupt_driven.h"

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

void Endpoint0( chanend c_ep0_out, chanend c_ep0_in);

#define MAX_BUF 512

void handleEndpoints(chanend chan_ep_in, chanend chan_ep_interrupt, chanend chan_ep_out, chanend vcomToDevice, chanend vcomToHost) {
    XUD_ep c_ep_in = XUD_Init_Ep(chan_ep_in);
    XUD_ep c_ep_out = XUD_Init_Ep(chan_ep_out);
    XUD_ep c_ep_interrupt = XUD_Init_Ep(chan_ep_interrupt);

    chan serv;

    unsigned char tmp;
    unsigned int notificationBuffer[2];

    unsigned int bufToDevice[2][MAX_BUF+8];
    unsigned int bufToHost[2][MAX_BUF/sizeof(int)+2];
    int hostLen = 0, devLen[2] = {0,0};
    int devRd = 0;
    int devCurrent = 0, hostCurrent = 0;
    int hostWaiting = 0;
    int devWaiting = 0;

    // First set handlers on each of the three XUD endpoints, then enable interrupts
    // and store the server channel
    XUD_interrupt_OUT(chan_ep_out, c_ep_out);
    XUD_interrupt_IN(chan_ep_interrupt, c_ep_interrupt);
    XUD_interrupt_IN(chan_ep_in, c_ep_in);
    XUD_interrupt_enable(serv);

    // Now state that we are ready to listen to both IN and interrupt requests.
    outuchar(serv, c_ep_interrupt);
    outuchar(serv, c_ep_in);

    // And make a buffer available for OUT requests.
    XUD_provide_OUT_buffer(c_ep_out, bufToDevice[!devCurrent]);

    while(1) {
        select {
        case inuchar_byref(serv, tmp):
            if(tmp == (c_ep_interrupt & 0xff)) {
                XUD_provide_IN_buffer(c_ep_interrupt, 0, notificationBuffer, 0);
            } else if (tmp == (c_ep_in & 0xff)) {
                if (hostLen != 0) {
                    XUD_provide_IN_buffer(c_ep_in, 0, bufToHost[hostCurrent], hostLen);
                    hostCurrent = !hostCurrent;
                    hostLen = 0;
                } else {
                    hostWaiting = 1;
                }
            } else if (tmp == (c_ep_out & 0xff)) {
                int l = XUD_compute_OUT_length(c_ep_out, bufToDevice[!devCurrent]);
                devLen[!devCurrent] = l;
                if (devLen[devCurrent] == 0) {
                    devCurrent = !devCurrent;
                    devRd = 0;
                    XUD_provide_OUT_buffer(c_ep_out, bufToDevice[!devCurrent]);
                } else {
                    devWaiting = 1;
                }
            }
            break;
        case hostLen != MAX_BUF => vcomToHost :> char x:
            (bufToHost[hostCurrent], unsigned char[])[hostLen++] = x;
            if (hostWaiting) {
                XUD_provide_IN_buffer(c_ep_in, 0, bufToHost[hostCurrent], hostLen);
                hostCurrent = !hostCurrent;
                hostLen = 0;
                hostWaiting = 0;
            }
            break;
        case devLen[devCurrent] != 0 => vcomToDevice :> int _:
            vcomToDevice <: (bufToDevice[devCurrent], unsigned char[])[devRd++];
            devLen[devCurrent]--;
            if (devLen[devCurrent] == 0) {
                if (devWaiting) {
                    devCurrent = !devCurrent;
                    devRd = 0;
                    XUD_provide_OUT_buffer(c_ep_out, bufToDevice[!devCurrent]);                    
                    devWaiting = 0;
                }
            }
            break;
        }
    }

}


/*
 * The user thread: request characters over one channel, supply characters over the other...
 */
void userThread(chanend vcomToDevice, chanend vcomToHost) {
    while(1) {
        char x;
        vcomToDevice <: 0; // send request for char
        vcomToDevice :> x;
        if (x >= 'a' && x <= 'z') x = x - 'a' + 'A';
        vcomToHost <: x;
    }
}

/*
 * The main function fires of four processes: the XUD manager, Endpoint 0, the
 * buffering thread, and the user thread.
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

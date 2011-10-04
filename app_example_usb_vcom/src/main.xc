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
extern void enableInterrupts();

void both(chanend chan_ep_in, chanend chan_ep_interrupt, chanend chan_ep_out) {
    unsigned addrMyBuffer, addrNotBuffer;
    int myBuffer[256];
    XUD_ep c_ep_in = XUD_Init_Ep(chan_ep_in);
    XUD_ep c_ep_out = XUD_Init_Ep(chan_ep_out);
    XUD_ep c_ep_interrupt = XUD_Init_Ep(chan_ep_interrupt);
    unsigned int tmp;
    unsigned int rp = 0, wp = 64, len = 1;

    asm("add %0, %1, 0":"=r"(addrMyBuffer): "r" (myBuffer));
    asm("add %0, %1, 0":"=r"(addrNotBuffer): "r" (notificationBuffer));
    XUD_SetReady_In(c_ep_in, PIDn_DATA0, addrMyBuffer, 25);
    XUD_SetReady_In(c_ep_interrupt, PIDn_DATA0, addrNotBuffer, 0);

    XUD_SetReady(c_ep_out, 0);

#define USEINT
#ifdef USEINT
    setINHandler(chan_ep_interrupt, c_ep_interrupt);
    enableInterrupts();
#endif

    while(1) {
        select {
        case inuint_byref(chan_ep_in, tmp):       // Only ready when data available
            XUD_SetData_Inline(c_ep_in, chan_ep_in);
            len--;
            rp = (rp + 64) & 255;
            if (len == 0) {
                XUD_SetNotReady(c_ep_in);
            } else {
                XUD_SetReady_In(c_ep_in, 0, addrMyBuffer + rp*4 + 4, myBuffer[rp]);
            }
            break;

#ifndef USEINT
        case inuint_byref(chan_ep_interrupt, tmp): // Interrupts - always ready.
            XUD_SetData_Inline(c_ep_interrupt, chan_ep_interrupt);
            XUD_SetReady_In(c_ep_interrupt, 0, addrNotBuffer, 0);
            break;
#endif

        case inuint_byref(chan_ep_out, tmp):
            {
                int p = wp, tail;
                int datalength;
                while (!testct(chan_ep_out)) {
                    unsigned int datum = inuint(chan_ep_out);
                    myBuffer[++p] = datum;
                }  
                tail = inct(chan_ep_out);
                datalength = (p-wp-1)<<2;
                datalength += tail - 12;
                myBuffer[wp] = datalength;
                if (len != 3) {
                    if (len == 0) {
                        XUD_SetReady_In(c_ep_in, 0, addrMyBuffer + wp*4 + 4, datalength);
                    }
                    wp = (wp + 64) & 255;
                    len++;
                }
                XUD_SetReady(c_ep_out, 0);
            }
            break;


        }
    }
}

/*
 * The main function fires of three processes: the XUD manager, Endpoint 0,
 * and hid. An array of channels is used for both in and out endpoints,
 * endpoint zero requires both, hid is just an IN endpoint.
 */
int main() 
{
    chan c_ep_out[2], c_ep_in[3], keys;
    par 
    {
        on stdcore[USB_CORE]: XUD_Manager( c_ep_out, XUD_EP_COUNT_OUT, c_ep_in, XUD_EP_COUNT_IN,
                                null, epTypeTableOut, epTypeTableIn,
                                p_usb_rst, clk, -1, XUD_SPEED_HS, null); 
        
        on stdcore[USB_CORE]: Endpoint0( c_ep_out[0], c_ep_in[0]);
        on stdcore[USB_CORE]: both(c_ep_in[1], c_ep_in[2], c_ep_out[1]);
    }

    return 0;
}

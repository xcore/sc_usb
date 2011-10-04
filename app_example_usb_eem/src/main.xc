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
#define XUD_EP_COUNT_IN    2

#define USB_RST_PORT    XS1_PORT_32A
#define USB_CORE        0


/* Endpoint type tables */
XUD_EpType epTypeTableOut[XUD_EP_COUNT_OUT] = {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL};
XUD_EpType epTypeTableIn[XUD_EP_COUNT_IN] =   {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL};

/* USB Port declarations */
on stdcore[USB_CORE]: out port p_usb_rst = XS1_PORT_1I;
on stdcore[USB_CORE]: clock    clk       = XS1_CLKBLK_3;

on stdcore[0]: port ps2_clock = XS1_PORT_1A;
on stdcore[0]: port ps2_data = XS1_PORT_1L;

void Endpoint0( chanend c_ep0_out, chanend c_ep0_in);



char reportBuffer[9];

/*
 * This function responds to the OUT requests, posting data from the servers.
 */
void consume(chanend chan_ep1, chanend c_in) 
{
    XUD_ep c_ep1 = XUD_Init_Ep(chan_ep1);
    char mybuffer[1024];
    timer t;
    unsigned s;

    t :> s;
    while(1) {
        t when timerafter(s+100000) :> s;
        if (XUD_GetBuffer(c_ep1, mybuffer) < 0) {
            XUD_ResetEndpoint(c_ep1, null);
        }
    }
}

/*
 * This function responds to IN requests - data for the Web/mDNS/DHCP server
 */
void produce(chanend chan_ep1, chanend c_in) 
{
    XUD_ep c_ep1 = XUD_Init_Ep(chan_ep1);
    char mybuffer[1024];

    while(1) {
        while(1);
        if (XUD_SetBuffer(c_ep1, mybuffer, 0) < 0) {
            XUD_ResetEndpoint(c_ep1, null);
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
    chan c_ep_out[2], c_ep_in[2], keys;
    par 
    {
        on stdcore[USB_CORE]: XUD_Manager( c_ep_out, XUD_EP_COUNT_OUT, c_ep_in, XUD_EP_COUNT_IN,
                                null, epTypeTableOut, epTypeTableIn,
                                p_usb_rst, clk, -1, XUD_SPEED_HS, null); 
        
        on stdcore[USB_CORE]: Endpoint0( c_ep_out[0], c_ep_in[0]);
        on stdcore[USB_CORE]: consume(c_ep_out[1], keys);
        on stdcore[USB_CORE]: produce(c_ep_in[1], keys);
    }

    return 0;
}

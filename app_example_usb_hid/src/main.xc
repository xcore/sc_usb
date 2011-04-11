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

#define XUD_EP_COUNT_OUT   1
#define XUD_EP_COUNT_IN    2

#ifdef XDK
#warning BUILDING FOR XDK
#define USB_RST_PORT    XS1_PORT_1B
#define USB_CORE        1
#else
/* L1 USB Audio Board */
#define USB_RST_PORT    XS1_PORT_32A
#define USB_CORE        0
#endif


/* Endpoint type tables */
XUD_EpType epTypeTableOut[XUD_EP_COUNT_OUT] = {XUD_EPTYPE_CTL};
XUD_EpType epTypeTableIn[XUD_EP_COUNT_IN] =   {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL};

/* USB Port declarations */
on stdcore[USB_CORE]: out port p_usb_rst = USB_RST_PORT;
on stdcore[USB_CORE]: clock    clk       = XS1_CLKBLK_3;

void Endpoint0( chanend c_ep0_out, chanend c_ep0_in);

char reportBuffer[] = {0, 0, 0, 0};

/*
 * This function responds to the HID requests - it draws a square using the mouse moving 40 pixels
 * in each direction in sequence every 100 requests.
 */
void hid(chanend chan_ep1) 
{
    int counter = 0;
    int state = 0;
    
    XUD_ep c_ep1 = XUD_Init_Ep(chan_ep1);
   
    counter = 0;
    while(1) 
    {
        counter++;
        if(counter == 400) 
        {
            if(state == 0) 
            {
                reportBuffer[1] = 40;
                reportBuffer[2] = 0; 
                state+=1;
            } 
            else if(state == 1) 
            {
                reportBuffer[1] = 0;
                reportBuffer[2] = 40;
                state+=1;
            } 
            else if(state == 2) 
            {
                reportBuffer[1] = -40;
                reportBuffer[2] = 0; 
                state+=1;
            } 
            else if(state == 3) 
            {
                reportBuffer[1] = 0;
                reportBuffer[2] = -40;
                state = 0;
            }
            counter = 0;
        } 
        else 
        {
            reportBuffer[1] = 0;
            reportBuffer[2] = 0; 
        }

        if (XUD_SetBuffer(c_ep1, reportBuffer, 4) < 0)
        {
            XUD_ResetEndpoint(c_ep1, null);
        }
    }
}

void busy()
{
    int a[2];
    int x = 0;

    set_thread_fast_mode_on();

    while(1)
    {
        x = x + 1;
        a[1] = x;
    }
}

/*
 * The main function fires of three processes: the XUD manager, Endpoint 0, and hid. An array of
 * channels is used for both in and out endpoints, endpoint zero requires both, hid is just an
 * IN endpoint.
 */
int main() 
{
    chan c_ep_out[1], c_ep_in[2];
    par 
    {
        
        on stdcore[USB_CORE]: XUD_Manager( c_ep_out, XUD_EP_COUNT_OUT, c_ep_in, XUD_EP_COUNT_IN,
                                null, epTypeTableOut, epTypeTableIn,
                                p_usb_rst, clk, -1, XUD_SPEED_HS, null); 
        
        on stdcore[USB_CORE]:
        {
            set_thread_fast_mode_on();
            Endpoint0( c_ep_out[0], c_ep_in[0]);
        }
       
        on stdcore[USB_CORE]:
        {
            set_thread_fast_mode_on();
            hid(c_ep_in[1]);
        }
    }

    return 0;
}

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
#include "xgc_keyboard.h"

#define XUD_EP_COUNT_OUT   1
#define XUD_EP_COUNT_IN    2

#define USB_RST_PORT    XS1_PORT_32A
#define USB_CORE        0


/* Endpoint type tables */
XUD_EpType epTypeTableOut[XUD_EP_COUNT_OUT] = {XUD_EPTYPE_CTL};
XUD_EpType epTypeTableIn[XUD_EP_COUNT_IN] =   {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL};

/* USB Port declarations */
on stdcore[USB_CORE]: out port p_usb_rst = XS1_PORT_1I;
on stdcore[USB_CORE]: clock    clk       = XS1_CLKBLK_3;

void Endpoint0( chanend c_ep0_out, chanend c_ep0_in);

char reportBuffer[] = {
                       0, 0,0,0,0,0,0,0,0};

/*
 * This function responds to the HID requests - it draws a square using the mouse moving 40 pixels
 * in each direction in sequence every 100 requests.
 */
void hid(chanend chan_ep1, chanend c_in) 
{
    int press;

    XUD_ep c_ep1 = XUD_Init_Ep(chan_ep1);
   
    while(1) {
        select {
        case c_in :> press:
            reportBuffer[0] = 2;
            reportBuffer[1] = press;
            c_in :> press;
            reportBuffer[3] = press; 
            break;
        default:
            reportBuffer[0] = 0;  // for mouse send data with reportbuffer[0] = 1.
            reportBuffer[1] = 0; 
            reportBuffer[3] = 0; 
            break;
        }
        if (XUD_SetBuffer(c_ep1, reportBuffer, sizeof(reportBuffer)) < 0) {
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
    chan c_ep_out[1], c_ep_in[2], keys;
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
            hid(c_ep_in[1], keys);
        }
        on stdcore[USB_CORE]:
        {
            keyboard_ps2_interface(keys);
        }
    }

    return 0;
}

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
#include "ps2.h"

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

on stdcore[0]: port ps2_clock = XS1_PORT_1A;
on stdcore[0]: port ps2_data = XS1_PORT_1L;

void Endpoint0( chanend c_ep0_out, chanend c_ep0_in);

void ps2Process(port ps2_clock, port ps2_data, chanend c) {
    unsigned action, key, modifier;
	// This process will maintain the state of shift and control
    int keys[6] = {0,0,0,0,0,0};

    struct ps2state state;

    ps2HandlerInit(state);

	// Loop
	while (1) {
        select {
        case ps2Handler(ps2_clock, ps2_data, state);
        case c :> int _:
            master {
                c <: (char) modifier;
#pragma loop unroll
                for(int i = 0; i < 6; i++) {
                    c <: (char) keys[i];
                }
            }
            break;
        }
        // This should only be after the ps2Handler!
        {action, modifier, key} = ps2Interpret(state);
        key = ps2USB(key);
        if (action == PS2_PRESS) {
            for(int i = 0; i < 6; i++) {
                if(keys[i] == 0) {
                    keys[i] = key;
                    break;
                }
            }
        } else if (action == PS2_RELEASE) {
            for(int i = 0; i < 6; i++) {
                if(keys[i] == key) {
                    keys[i] = 0;
                    break;
                }
            }
        }

	}
}


char reportBuffer[9];

/*
 * This function responds to the HID requests.
 */
void hid(chanend chan_ep1, chanend c_in) 
{
    XUD_ep c_ep1 = XUD_Init_Ep(chan_ep1);
   
// loop that alternates keyboard and mouse responses.
    while(1) {
        // First set up a keyboard response
        reportBuffer[0] = 2;
        c_in <: 0; // request data;
        slave {
            c_in :> reportBuffer[1];
#pragma loop unroll
            for(int i = 0; i < 6; i++) {
                c_in :> reportBuffer[i+3];
            }
        }
        if (XUD_SetBuffer(c_ep1, reportBuffer, 9) < 0) {
            XUD_ResetEndpoint(c_ep1, null);
        } 
        // Then set up a mouse response
        reportBuffer[0] = 1;
        reportBuffer[1] = 0; // buttons
        reportBuffer[2] = reportBuffer[4] != 0 ? 1 : 0; // X
        reportBuffer[3] = 0; // Y
        reportBuffer[4] = 0;
        // for mouse send data with reportbuffer[0] = 1.
        if (XUD_SetBuffer(c_ep1, reportBuffer, 5) < 0) {
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
    chan c_ep_out[1], c_ep_in[2], keys;
    par 
    {
        on stdcore[USB_CORE]: XUD_Manager( c_ep_out, XUD_EP_COUNT_OUT, c_ep_in, XUD_EP_COUNT_IN,
                                null, epTypeTableOut, epTypeTableIn,
                                p_usb_rst, clk, -1, XUD_SPEED_HS, null); 
        
        on stdcore[USB_CORE]: Endpoint0( c_ep_out[0], c_ep_in[0]);
        on stdcore[USB_CORE]: hid(c_ep_in[1], keys);
        on stdcore[USB_CORE]: ps2Process(ps2_clock, ps2_data, keys);
    }

    return 0;
}

// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xs1.h>
#include <platform.h>
#include <print.h>
#include <stdio.h>
#include <xclib.h>

#include "xud.h"
#include "usb.h"
#include "q.h"
#include "packetManager.h"
#include "ethernet.h"
#include "xud_interrupt_driven.h"

#define XUD_EP_COUNT_OUT   2
#define XUD_EP_COUNT_IN    2

#define USB_CORE        0


/* Endpoint type tables */
XUD_EpType epTypeTableOut[XUD_EP_COUNT_OUT] = {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL};
XUD_EpType epTypeTableIn[XUD_EP_COUNT_IN] =   {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL};

/* USB Port declarations */
on stdcore[USB_CORE]: out port p_usb_rst = XS1_PORT_32A;
on stdcore[USB_CORE]: clock    clk       = XS1_CLKBLK_3;

void Endpoint0( chanend c_ep0_out, chanend c_ep0_in);

#define WMAXPACKETSIZE 512
#define MAX_BUF 1516

static void transferPacketToIN(XUD_ep c_ep_in, struct queue &toHost, int head, int bytesToSend) {
    if (bytesToSend == 0) {                              // send empty packet
        XUD_provide_IN_buffer(c_ep_in, 0, packetBuffer[0], 0);
    } else if (bytesToSend >= WMAXPACKETSIZE) {          // send one WMAX
        XUD_provide_IN_buffer_i(c_ep_in, 0, packetBuffer[toHost.data[head].packet],
                                toHost.data[head].from, WMAXPACKETSIZE);
    } else if (bytesToSend > 0) {                        // send precise length
        XUD_provide_IN_buffer_i(c_ep_in, 0, packetBuffer[toHost.data[head].packet],
                                toHost.data[head].from, bytesToSend);
    }
    toHost.data[head].from += WMAXPACKETSIZE;
}

struct queue toHost;

void handleEndpoints(chanend chan_ep_in, chanend chan_ep_out) {
    XUD_ep c_ep_in = XUD_Init_Ep(chan_ep_in);
    XUD_ep c_ep_out = XUD_Init_Ep(chan_ep_out);
    unsigned char tmp;
    struct queue toDev;
    int hostWaiting = 1;
    int devWaiting = 0;
    int outPacket, outFrom;
    chan serv;

    packetBufferInit();
    qInit(toHost);
    qInit(toDev);
    // First set handlers on each of the three XUD endpoints, then enable interrupts
    // and store the server channel
    XUD_interrupt_OUT(chan_ep_out, c_ep_out);
    XUD_interrupt_IN(chan_ep_in, c_ep_in);
    XUD_interrupt_enable(serv);

    // And make a buffer available for OUT requests.
    outPacket = packetBufferAlloc();
    XUD_provide_OUT_buffer(c_ep_out, packetBuffer[outPacket]);
    outFrom = 0;


    while(1) {
        select {
        case inuchar_byref(serv, tmp):
            if (tmp == (c_ep_in & 0xff)) {
                int head = qPeek(toHost);
                int bytesToSend = toHost.data[head].len - toHost.data[head].from;
                if (bytesToSend < 0) {          // discard packet; transmitted completely
                    packetBufferFree(toHost.data[head].packet);
                    qGet(toHost);
                    if (qIsEmpty(toHost)) {
                        hostWaiting = 1;
                        break;
                    }
                    head = qPeek(toHost);
                    bytesToSend = toHost.data[head].len - toHost.data[head].from;
                }
                transferPacketToIN(c_ep_in, toHost, head, bytesToSend);
            } else if (tmp == (c_ep_out & 0xff)) {
                int l = XUD_compute_OUT_length(c_ep_out, packetBuffer[outPacket]) - outFrom;
                if (l == WMAXPACKETSIZE) {
                    outFrom += WMAXPACKETSIZE;
                    XUD_provide_OUT_buffer_i(c_ep_out, packetBuffer[outPacket], outFrom);
                } else {
                    l += outFrom;
                    qPut(toDev, outPacket, l);
                    if (qIsFull(toDev)) {
                        devWaiting = 1;
                    } else {
                        outPacket = packetBufferAlloc();
                        XUD_provide_OUT_buffer(c_ep_out, packetBuffer[outPacket]);
                        outFrom = 0;
                    }
                }
            }
            break;
        }
        if (!qIsEmpty(toDev)) {
            int index = qPeek(toDev);
            int packetNum = toDev.data[index].packet;
            int packetLen = toDev.data[index].len;
            handlePacket(packetNum, packetLen);
            packetBufferFree(packetNum);
            qGet(toDev);
        }
        if (!qIsEmpty(toHost) && hostWaiting) {
            int index = qPeek(toHost);
            int len = toHost.data[index].len;
            hostWaiting = 0;
            transferPacketToIN(c_ep_in, toHost, index, len > WMAXPACKETSIZE ? WMAXPACKETSIZE : len);
        }
    }

}


int main() 
{
    chan c_ep_out[2], c_ep_in[2];
    par 
    {
        on stdcore[USB_CORE]: {
            XUD_Manager( c_ep_out, XUD_EP_COUNT_OUT, c_ep_in, XUD_EP_COUNT_IN,
                         null, epTypeTableOut, epTypeTableIn,
                         p_usb_rst, clk, 1, XUD_SPEED_HS, null); 
        }
        on stdcore[USB_CORE]: Endpoint0( c_ep_out[0], c_ep_in[0]);
        on stdcore[USB_CORE]: handleEndpoints(c_ep_in[1], c_ep_out[1]);
    }

    return 0;
}

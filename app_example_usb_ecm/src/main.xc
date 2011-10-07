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
#include "sim.h"
#include "packetManager.h"
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


void handleEndpoints(chanend chan_ep_in, chanend chan_ep_out, chanend packetsToDevice, chanend packetsToHost) {
    XUD_ep c_ep_in = XUD_Init_Ep(chan_ep_in);
    XUD_ep c_ep_out = XUD_Init_Ep(chan_ep_out);
    unsigned char tmp;
    struct queue toHost, toDev;
    int hostWaiting = 1;
    int devWaiting = 0;
    int userToDeviceWaiting = 0;
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
                    if (userToDeviceWaiting) {
                        packetsToDevice <: outPacket; 
                        packetsToDevice <: l; 
                        userToDeviceWaiting = 0;
                    } else {
                        qPut(toDev, outPacket, l);
                    }
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
        case !qIsFull(toHost) => packetsToHost :> int bufNum:
            if (bufNum == NULL_PACKET) {
                packetsToHost <: packetBufferAlloc();
            } else {
                int len, element;
                packetsToHost :> len;
                element = qPut(toHost, bufNum, len);
                if (hostWaiting) {
                    hostWaiting = 0;
                    transferPacketToIN(c_ep_in, toHost, element, len > WMAXPACKETSIZE ? WMAXPACKETSIZE : len);
                }
            }
            break;
        case packetsToDevice :> int bufNum:
            if (bufNum != NULL_PACKET) {
                packetBufferFree(bufNum);
            } else if (qIsEmpty(toDev)) {
                userToDeviceWaiting = 1;
            } else {
                int index = qGet(toDev);
                packetsToDevice <: toDev.data[index].packet;
                packetsToDevice <: toDev.data[index].len;
                if (devWaiting)  {
                    // alloc out buffer.
                    devWaiting = 0;
                    outPacket = packetBufferAlloc();
                    XUD_provide_OUT_buffer(c_ep_out, packetBuffer[outPacket]);
                    outFrom = 0;
                }
            }
            break;
        }
    }

}

int ipAddressOurs;
int ipAddressTheirs;
char macAddressOurs[6];
char macAddressTheirs[6] = {0x00, 0x22, 0x97, 0x08, 0xA0, 0x03};

void handlePacket(unsigned int packet[], int len) {
    if ((packet, short[])[6] == 0x0608) {
        if ((packet, short[])[14] == (packet, short[])[19] &&
            (packet, short[])[15] == (packet, short[])[20]) {
            int ipAddressOurs, ipAddressTheirs = byterev(packet[7]);
            ipAddressOurs = (ipAddressTheirs & 0xffff0000) |
                (((ipAddressTheirs & 0xffff)-0x100 + 1) % 0xfe00+ 0x100);
            
        }
    }
}

void userThreadToDevice(chanend packetsToDevice) {
    int packetNum, len;
    while(1) {
        packetsToDevice <: NULL_PACKET; // send request for packet
        packetsToDevice :> packetNum;  // Gobble it up.
        packetsToDevice :> len;        // Gobble it up.
        handlePacket(packetBuffer_[packetNum], len);
        packetsToDevice <: packetNum;  // Return packet
    }
}


char arp[] = {
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x00, 0x20, 0x30, 0x11, 0x22, 0x32, 0x08, 0x06, 0x00, 0x01,
    0x08, 0x00, 0x06, 0x04, 0x00, 0x01, 0x00, 0x20, 0x30, 0x11, 0x22, 0x32, 0xa9, 0xfe, 0x1e, 0xc4,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xa9, 0xfe, 0xaf, 0xaf};

void userThreadToHost(chanend packetsToHost) {
    timer t; int s;
    int packetNum, len = 256;
//    while(1);
    while(1) {
        packetsToHost <: NULL_PACKET; // send request for packet
        packetsToHost :> packetNum;
        packetCopyInto(packetNum, arp, sizeof(arp));
        packetsToHost <: packetNum;
        packetsToHost <: sizeof(arp);
        len += 128;
        t :> s;
        t when timerafter(s+100000000) :> s;
    }
}

int main() 
{
    chan c_ep_out[2], c_ep_in[2], packets, packets2;
    par 
    {
        on stdcore[USB_CORE]: {
//#define SIM
//#ifdef SIM
//            XUD_Manager_SIM( c_ep_out[1], c_ep_in[1]); 
//#endif
            XUD_Manager( c_ep_out, XUD_EP_COUNT_OUT, c_ep_in, XUD_EP_COUNT_IN,
                         null, epTypeTableOut, epTypeTableIn,
                         p_usb_rst, clk, -1, XUD_SPEED_HS, null); 
        }
        on stdcore[USB_CORE]: Endpoint0( c_ep_out[0], c_ep_in[0]);
        on stdcore[USB_CORE]: handleEndpoints(c_ep_in[1], c_ep_out[1], packets, packets2);
        on stdcore[USB_CORE]: userThreadToHost(packets2);
        on stdcore[USB_CORE]: userThreadToDevice(packets);
    }

    return 0;
}

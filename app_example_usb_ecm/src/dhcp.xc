// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xclib.h>
#include <print.h>
#include "packetManager.h"
#include "ethernet.h"
#include "q.h"
#include "femtoIP.h"
#include "femtoUDP.h"
#include "femtoTCP.h"
#include "dhcp.h"

static void wordCopy(unsigned int to[], unsigned int from[], int nWords) {
    for(int i = 0; i < nWords; i++) {
        to[i] = from[i];
    }
}

#define OPTION_START  282

void processDHCPPacket(unsigned int packet, int len) {
    int index = OPTION_START;
    int request = -1;
    while (index < 1000) {
        int option = (packetBuffer[packet], unsigned char[])[index];
        if (option == 53) {
            request = (packetBuffer[packet], unsigned char[])[index+2];
            break;
        }
        if (option == 255) {
            break;
        }
        if (option == 0) {
            index++;
        } else {
            index = index + 1 + (packetBuffer[packet], unsigned char[])[index+1];
        }
    }
    if (request == 1 || request == 3) { // DISCOVER or REQUEST
        int t;
        int k;
        t = packetBufferAlloc();

        wordCopy(packetBuffer[t], packetBuffer[packet], 284/4); // include magic cookie

        (packetBuffer[t], unsigned short[])[25] = 0;

        (packetBuffer[t], unsigned short[])[30] = byterev(ipAddressTheirs)>>16;
        (packetBuffer[t], unsigned short[])[29] = byterev(ipAddressTheirs);
        (packetBuffer[t], unsigned short[])[32] = byterev(ipAddressOurs)>>16;
        (packetBuffer[t], unsigned short[])[31] = byterev(ipAddressOurs);
        (packetBuffer[t], unsigned char[])[42] = 2;

        k = OPTION_START;
        (packetBuffer[t], unsigned char[])[k++] = 53;
        (packetBuffer[t], unsigned char[])[k++] = 1;
        (packetBuffer[t], unsigned char[])[k++] = request == 1 ? 2 : 5; // OFFER or ACK

        (packetBuffer[t], unsigned char[])[k++] = 51;
        (packetBuffer[t], unsigned char[])[k++] = 4;
        (packetBuffer[t], unsigned char[])[k++] = 0;
        (packetBuffer[t], unsigned char[])[k++] = 0;
        (packetBuffer[t], unsigned char[])[k++] = 1;
        (packetBuffer[t], unsigned char[])[k++] = 0;

        (packetBuffer[t], unsigned char[])[k++] = 54;
        (packetBuffer[t], unsigned char[])[k++] = 4;
        (packetBuffer[t], unsigned char[])[k++] = ipAddressOurs >> 24;
        (packetBuffer[t], unsigned char[])[k++] = ipAddressOurs >> 16;
        (packetBuffer[t], unsigned char[])[k++] = ipAddressOurs >> 8;
        (packetBuffer[t], unsigned char[])[k++] = ipAddressOurs >> 0;

        (packetBuffer[t], unsigned char[])[k++] = 1;
        (packetBuffer[t], unsigned char[])[k++] = 4;
        (packetBuffer[t], unsigned char[])[k++] = 255;
        (packetBuffer[t], unsigned char[])[k++] = 255;
        (packetBuffer[t], unsigned char[])[k++] = 0;
        (packetBuffer[t], unsigned char[])[k++] = 0;

        (packetBuffer[t], unsigned char[])[k++] = 255;
        (packetBuffer[t], unsigned char[])[k] = 0;

        patchUDPHeader(packetBuffer[t], k, 0xffffffff, 0x4300, 0x4400);
        qPut(toHost, t, k);
        if (request == 3) {
            lightLed(3);
        }
    }
}

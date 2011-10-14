// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xclib.h>
#include <print.h>
#include "femtoTCP.h"
#include "femtoIP.h"
#include "string.h"
#include "http.h"
#include "ethernet.h"
#include "q.h"
#include "packetManager.h"

int streamSequenceNumber;
int streamAckNumber;
int streamDestPortRev;
int streamSourcePortRev;

#define FIN 0x01
#define SYN 0x02
#define PSH 0x08
#define ACK 0x10

#define HEADERS_LEN_TCP 54

void patchTCPHeader(unsigned int packet[], int len, int flags) {
    int totalShorts;
    patchIPHeader(packet, 20 + 20 + len, 0, 1);
    (packet, unsigned short[])[17] = streamDestPortRev;
    (packet, unsigned short[])[18] = streamSourcePortRev;
    (packet, unsigned short[])[20] = byterev(streamSequenceNumber) >> 16;
    (packet, unsigned short[])[19] = byterev(streamSequenceNumber);
    (packet, unsigned short[])[22] = byterev(streamAckNumber) >> 16;
    (packet, unsigned short[])[21] = byterev(streamAckNumber);
    (packet, unsigned short[])[23] = 0x0050 | flags << 8;
    (packet, unsigned short[])[24] = byterev(1500) >> 16;
    (packet, unsigned short[])[25] = 0;
    (packet, unsigned short[])[26] = 0;
    totalShorts = 27 + ((len+1)>>1);
    onesChecksum(0x0006 + 20 + len /* packetType + packetLength */,
                 (packet, unsigned short[]), 13, totalShorts - 1, 25);
}

void tcpString(char s[]) {
    int t;
    int len = strlen(s);
    t = packetBufferAlloc();

    for(int i = 0; i < len; i++) {
        (packetBuffer[t], unsigned char[])[HEADERS_LEN_TCP+i] = s[i];
    }
    (packetBuffer[t], unsigned char[])[HEADERS_LEN_TCP+len] = 0;

    patchTCPHeader(packetBuffer[t], len, ACK | PSH | FIN);
    
    qPut(toHost, t, HEADERS_LEN_TCP + len);
    streamSequenceNumber += len;
    return;
}

void processTCPPacket(unsigned int packet, int len) {
    int sourcePortRev = (packetBuffer[packet], unsigned short[])[17];
    int destPortRev = (packetBuffer[packet], unsigned short[])[18];
    int sequenceNumberRev = (packetBuffer[packet], unsigned short[])[20]<<16 |
                            (packetBuffer[packet], unsigned short[])[19];
    int ackNumberRev = (packetBuffer[packet], unsigned short[])[22]<<16 |
                       (packetBuffer[packet], unsigned short[])[21];
    int packetLength;
    int headerLength;

    streamSourcePortRev = sourcePortRev;
    streamDestPortRev = destPortRev;

    if (packetBuffer[packet][11] & 0x02000000) { // SYN
        int t;
        t = packetBufferAlloc();
        streamAckNumber = byterev(sequenceNumberRev) + 1;
        streamSequenceNumber = 0; // could be random

        patchTCPHeader(packetBuffer[t], 0, SYN | ACK);
        streamSequenceNumber++;
        qPut(toHost, t, HEADERS_LEN_TCP);
        return;
    }
    if (packetBuffer[packet][11] & 0x01000000) { // FIN, send an ACK.
        int t;
        t = packetBufferAlloc();
        streamSequenceNumber++;
        streamAckNumber++;

        patchTCPHeader(packetBuffer[t], 0, ACK);
        qPut(toHost, t, HEADERS_LEN_TCP);
        return;
    }
    if (packetBuffer[packet][11] & 0x10000000) { // ACK
        ; // required later to send long responses.
    }
    packetLength = byterev((packetBuffer[packet], unsigned short[])[8]) >> 16;
    headerLength = (packetBuffer[packet], unsigned char[])[46]>>2;

    packetLength -= headerLength + 20;

    streamAckNumber += packetLength;

    if (packetLength > 0) {
        if (destPortRev == 0x5000) { // HTTP
            httpProcess(packet, 34 + headerLength, packetLength);
        }
    }
    if (packetBuffer[packet][11] & 0x08000000) { // PSH
        ; // Can safely be ignored.
    }
}
